import 'dart:async';

import 'package:logging/logging.dart';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/repositories.dart';
import '../compose/message_composer.dart';
import 'ics.dart';
import 'ics_events.dart';

/// iTIP method of a calendar part (RFC 5546).
enum InvitationMethod { request, cancel, reply, other }

/// A meeting invitation (or update / cancellation) found in a mail.
class MeetingInvitation {
  const MeetingInvitation({required this.method, required this.event, required this.rawIcs, this.sequence = 0, this.organizerName});

  final InvitationMethod method;

  /// Parsed VEVENT with `calendarId` empty; organizer/attendees filled.
  final CalendarEvent event;
  final String rawIcs;
  final int sequence;
  final String? organizerName;

  String? get organizer => event.organizer;

  /// The attendee entry addressed to one of [myAddresses], if any.
  Attendee? attendeeFor(Iterable<String> myAddresses) {
    final mine = {for (final a in myAddresses) a.toLowerCase()};
    for (final a in event.attendees) {
      if (mine.contains(a.email.toLowerCase())) return a;
    }
    return null;
  }

  /// Parses the first VEVENT of an iCalendar text; null when it is not an
  /// invitation-like object (no VEVENT, or a plain PUBLISH without organizer).
  static MeetingInvitation? parse(String ics, {DateTime? now}) {
    List<IcsComponent> comps;
    try {
      comps = parseIcs(ics);
    } catch (_) {
      return null;
    }
    final cal = comps.where((c) => c.name == 'VCALENDAR').firstOrNull ?? (comps.isEmpty ? null : comps.first);
    if (cal == null) return null;
    final method = switch (cal.prop('METHOD')?.value.toUpperCase()) {
      'REQUEST' => InvitationMethod.request,
      'CANCEL' => InvitationMethod.cancel,
      'REPLY' => InvitationMethod.reply,
      _ => InvitationMethod.other,
    };
    final events = eventsFromIcs(ics, calendarId: '', now: now);
    if (events.isEmpty) return null;
    // Prefer the master; a single detached occurrence is fine too.
    final event = events.firstWhere((e) => e.recurrenceId == null, orElse: () => events.first);
    final vevent = cal.childrenNamed('VEVENT').firstOrNull;
    final seq = int.tryParse(vevent?.prop('SEQUENCE')?.value ?? '') ?? 0;
    final organizerName = vevent?.prop('ORGANIZER')?.param('CN');
    return MeetingInvitation(method: method, event: event, rawIcs: ics, sequence: seq, organizerName: organizerName);
  }

  /// Subject prefix mail clients use for iTIP replies.
  static String responseWord(AttendeeStatus s) => switch (s) {
        AttendeeStatus.accepted => 'Accepted',
        AttendeeStatus.tentative => 'Tentative',
        AttendeeStatus.declined => 'Declined',
        _ => 'Reply',
      };

  /// The `METHOD:REPLY` object that tells the organizer how [me] answered.
  String replyIcs({required Identity me, required AttendeeStatus status, DateTime? now}) {
    final e = event;
    final w = IcsWriter();
    w.begin('VCALENDAR');
    w.prop('VERSION', '2.0');
    w.prop('PRODID', icsProdId);
    w.prop('METHOD', 'REPLY');
    w.begin('VEVENT');
    w.prop('UID', e.uid);
    w.prop('DTSTAMP', formatIcsDateTime((now ?? DateTime.now()).toUtc(), utc: true));
    w.prop('SEQUENCE', '$sequence');
    if (e.organizer != null) w.prop('ORGANIZER', 'mailto:${e.organizer}', params: {if (organizerName != null) 'CN': organizerName!});
    w.prop('ATTENDEE', 'mailto:${me.email}', params: {if (me.name.isNotEmpty) 'CN': me.name, 'PARTSTAT': _partstat(status)});
    _time(w, 'DTSTART', e.start, e);
    _time(w, 'DTEND', e.end, e);
    if (e.recurrenceId != null) _time(w, 'RECURRENCE-ID', e.recurrenceId!, e);
    w.text('SUMMARY', '${responseWord(status)}: ${e.summary}');
    w.end('VEVENT');
    w.end('VCALENDAR');
    return w.toString();
  }

  static void _time(IcsWriter w, String name, DateTime utc, CalendarEvent e) {
    if (e.isAllDay) {
      w.prop(name, formatIcsDate(utc), params: const {'VALUE': 'DATE'});
    } else {
      w.prop(name, formatIcsDateTime(utc.toUtc(), utc: true));
    }
  }

  static String _partstat(AttendeeStatus s) => switch (s) {
        AttendeeStatus.accepted => 'ACCEPTED',
        AttendeeStatus.tentative => 'TENTATIVE',
        AttendeeStatus.declined => 'DECLINED',
        AttendeeStatus.delegated => 'DELEGATED',
        AttendeeStatus.needsAction => 'NEEDS-ACTION',
      };
}

/// Answers invitations: mails an iTIP reply to the organizer, keeps the
/// event in the local calendar, and remembers the answer per message.
class InvitationService {
  InvitationService({
    required MessageComposer composer,
    required Future<void> Function(String accountId, String identityId, List<String> recipients, List<int> raw) send,
    required Future<List<Identity>> Function(String accountId) identities,
    required SettingsRepository settings,
    CalendarRepository? calendar,
    Future<CalendarEvent> Function(CalendarEvent draft)? createEvent,
    Future<void> Function(CalendarEvent event)? updateEvent,
    DateTime Function()? now,
  })  : _composer = composer,
        _send = send,
        _identities = identities,
        _settings = settings,
        _calendar = calendar,
        _createEvent = createEvent,
        _updateEvent = updateEvent,
        _now = now ?? DateTime.now;

  static final _log = Logger('invitations');
  static const localCalendarId = 'local-invitations';

  final MessageComposer _composer;
  final Future<void> Function(String accountId, String identityId, List<String> recipients, List<int> raw) _send;
  final Future<List<Identity>> Function(String accountId) _identities;
  final SettingsRepository _settings;
  final CalendarRepository? _calendar;

  /// The calendar service's create / update: they queue the CalDAV push so
  /// a Google or other remote calendar actually receives the event. Without
  /// them the event is written to the local store only.
  final Future<CalendarEvent> Function(CalendarEvent draft)? _createEvent;
  final Future<void> Function(CalendarEvent event)? _updateEvent;
  final DateTime Function() _now;

  /// One answer per occurrence: a recurring meeting's moved instances share
  /// the UID and differ only in RECURRENCE-ID, and each asks on its own.
  static String _key(String accountId, MeetingInvitation inv) {
    final r = inv.event.recurrenceId;
    return 'invite.$accountId.${inv.event.uid}${r == null ? '' : '|${r.millisecondsSinceEpoch}'}';
  }

  static const _preferredKey = 'invite.calendar';

  static final _googleSplit = RegExp(r'^(.+)_R\d{8}T\d{6}(@google\.com)$');

  /// Google's "this and following" edit gives the new series the UID
  /// `<base>_R<date>@google.com` and mails invitations under it, while the
  /// organizer's own calendar still serves those occurrences under `<base>`.
  /// Both UIDs are the same meeting here.
  static String? googleSplitBase(String uid) {
    final m = _googleSplit.firstMatch(uid);
    return m == null ? null : '${m[1]}${m[2]}';
  }

  /// Rows of [calendarId] that belong to the invitation's meeting.
  Future<List<CalendarEvent>> _siblings(CalendarRepository cal, String calendarId, String uid) async {
    final rows = await cal.eventsByUid(calendarId, uid);
    final base = googleSplitBase(uid);
    if (base != null) rows.addAll(await cal.eventsByUid(calendarId, base));
    return rows;
  }

  /// The calendar picked last time, if it still exists and is writable.
  Future<String?> preferredCalendar() async {
    final id = await _settings.getString(_preferredKey);
    final cal = _calendar;
    if (id == null || cal == null) return null;
    final src = await cal.source(id);
    return src != null && src.isWritable ? id : null;
  }

  Future<void> rememberCalendar(String calendarId) => _settings.setString(_preferredKey, calendarId);

  /// What was answered for this occurrence earlier on this device, if
  /// anything. An answer given to an older SEQUENCE does not count: the
  /// organizer changed the meeting since, so it has to be answered again.
  Future<AttendeeStatus?> responseOf(String accountId, MeetingInvitation inv) async {
    final v = await _settings.getString(_key(accountId, inv));
    if (v == null) return null;
    final at = v.indexOf('@');
    final name = at < 0 ? v : v.substring(0, at);
    // Answers stored before the sequence was kept ("accepted") stay valid.
    final seq = at < 0 ? inv.sequence : int.tryParse(v.substring(at + 1)) ?? 0;
    if (seq < inv.sequence) return null;
    for (final s in AttendeeStatus.values) {
      if (s.name == name) return s;
    }
    return null;
  }

  /// The identity the invitation was addressed to, else the default one.
  Future<Identity?> identityFor(String accountId, MeetingInvitation inv) async {
    final ids = await _identities(accountId);
    if (ids.isEmpty) return null;
    final mine = inv.attendeeFor(ids.map((i) => i.email));
    if (mine != null) {
      for (final i in ids) {
        if (i.email.toLowerCase() == mine.email.toLowerCase()) return i;
      }
    }
    return ids.firstWhere((i) => i.isDefault, orElse: () => ids.first);
  }

  /// [calendarId] is where the event goes; null means the local
  /// "Invitations" calendar (unless a synced calendar already has it).
  Future<void> respond({
    required String accountId,
    required MeetingInvitation invitation,
    required AttendeeStatus status,
    MessageHeader? original,
    String? calendarId,
  }) async {
    final me = await identityFor(accountId, invitation);
    if (me == null) throw StateError('No identity for this account');
    final organizer = invitation.organizer;
    if (organizer != null && organizer.isNotEmpty) {
      final e = invitation.event;
      final word = MeetingInvitation.responseWord(status);
      final lines = [
        '${me.name.isEmpty ? me.email : me.name} has ${word.toLowerCase() == 'tentative' ? 'tentatively accepted' : word.toLowerCase()} this invitation.',
        '',
        e.summary,
        if (e.location != null && e.location!.isNotEmpty) e.location!,
      ];
      final to = invitation.organizerName == null || invitation.organizerName!.isEmpty ? organizer : '${invitation.organizerName} <$organizer>';
      final composed = _composer.compose(ComposeRequest(
        identity: me,
        to: [to],
        subject: '$word: ${e.summary}',
        text: lines.join('\n'),
        includeSignature: false,
        inReplyTo: original?.messageId,
        references: [if (original?.messageId != null) original!.messageId!],
        calendarReply: invitation.replyIcs(me: me, status: status, now: _now()),
      ));
      await _send(accountId, me.id, [organizer], composed.raw);
    } else {
      _log.info('invitation without organizer: nothing to send');
    }
    await _settings.setString(_key(accountId, invitation), '${status.name}@${invitation.sequence}');
    await _recordInCalendar(invitation, me, status, calendarId);
  }

  /// Keeps the event without answering the organizer.
  Future<void> addToCalendar({required String accountId, required MeetingInvitation invitation, String? calendarId}) async {
    final me = await identityFor(accountId, invitation);
    await _recordInCalendar(invitation, me, AttendeeStatus.needsAction, calendarId);
  }

  /// True when some calendar already holds this occurrence.
  Future<bool> isInCalendar(MeetingInvitation invitation) async {
    final cal = _calendar;
    if (cal == null) return false;
    for (final src in await cal.sources()) {
      final rows = await _siblings(cal, src.id, invitation.event.uid);
      if (rows.any((e) => e.recurrenceId == invitation.event.recurrenceId)) return true;
    }
    return false;
  }

  /// The organizer cancelled: drop the local copy and forget the answer.
  Future<void> withdraw({required String accountId, required MeetingInvitation invitation}) async {
    await _settings.setString(_key(accountId, invitation), null);
    final cal = _calendar;
    if (cal == null) return;
    for (final src in await cal.sources()) {
      final existing = await cal.eventsByUid(src.id, invitation.event.uid);
      if (existing.isNotEmpty && src.kind == CalendarKind.local) await cal.deleteEvents([for (final e in existing) e.id]);
    }
  }

  Future<void> _recordInCalendar(MeetingInvitation inv, Identity? me, AttendeeStatus status, String? calendarId) async {
    final cal = _calendar;
    if (cal == null) return;
    try {
      final uid = inv.event.uid;
      if (status == AttendeeStatus.declined) {
        // Declined: make sure no local copy lingers.
        final existing = await cal.eventsByUid(localCalendarId, uid);
        if (existing.isNotEmpty) await cal.deleteEvents([for (final e in existing) e.id]);
        return;
      }
      var target = calendarId;
      if (target == null) {
        // No choice made: a synced calendar that already has it wins, else
        // the local Invitations calendar.
        for (final src in await cal.sources()) {
          if (src.id != localCalendarId && (await _siblings(cal, src.id, uid)).isNotEmpty) {
            target = src.id;
            break;
          }
        }
        target ??= localCalendarId;
      }
      if (target == localCalendarId && await cal.source(localCalendarId) == null) {
        await cal.upsertSource(const CalendarSource(id: localCalendarId, name: 'Invitations', kind: CalendarKind.local, color: 0xFF3F51B5, enabled: true));
      }
      final attendees = [
        for (final a in inv.event.attendees)
          me != null && a.email.toLowerCase() == me.email.toLowerCase() ? Attendee(email: a.email, name: a.name, status: status) : a,
      ];
      final siblings = await _siblings(cal, target, uid);
      final existing = siblings.where((e) => e.recurrenceId == inv.event.recurrenceId).firstOrNull;
      final now = _now().toUtc();
      if (existing != null) {
        // An update carries the organizer's latest time and details: a moved
        // meeting must move here too, not just record the new answer.
        final e = inv.event;
        final updated = existing.copyWith(
          summary: e.summary,
          description: e.description,
          location: e.location,
          start: e.start,
          end: e.end,
          isAllDay: e.isAllDay,
          floating: e.floating,
          tzid: e.tzid,
          rrule: e.rrule,
          exdates: e.exdates,
          status: e.status,
          organizer: e.organizer,
          attendees: attendees,
          updatedAt: now,
        );
        if (_updateEvent != null) {
          await _updateEvent(updated);
        } else {
          await cal.upsertEvents([updated]);
        }
        return;
      }
      final draft = inv.event.copyWith(
        id: calendarEventId(target, uid, inv.event.recurrenceId),
        calendarId: target,
        attendees: attendees,
        updatedAt: now,
      );
      // A moved occurrence of a series the calendar already syncs belongs in
      // the series' own resource; CalDAV servers refuse a RECURRENCE-ID on
      // its own (Google: 404). Join that resource and push it whole.
      final series = inv.event.recurrenceId == null ? null : siblings.where((e) => e.href != null).firstOrNull;
      if (series != null) {
        // Under the UID the resource already uses, so it stays one series.
        final joined = draft.copyWith(id: calendarEventId(target, series.uid, inv.event.recurrenceId), uid: series.uid, href: series.href, etag: series.etag);
        if (_updateEvent != null) {
          await _updateEvent(joined);
        } else {
          await cal.upsertEvents([joined]);
        }
        return;
      }
      if (_createEvent != null) {
        await _createEvent(draft);
      } else {
        await cal.upsertEvents([draft]);
      }
    } catch (e, st) {
      _log.warning('could not record the invitation in the calendar', e, st);
      rethrow;
    }
  }
}
