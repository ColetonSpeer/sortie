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
    DateTime Function()? now,
  })  : _composer = composer,
        _send = send,
        _identities = identities,
        _settings = settings,
        _calendar = calendar,
        _now = now ?? DateTime.now;

  static final _log = Logger('invitations');
  static const localCalendarId = 'local-invitations';

  final MessageComposer _composer;
  final Future<void> Function(String accountId, String identityId, List<String> recipients, List<int> raw) _send;
  final Future<List<Identity>> Function(String accountId) _identities;
  final SettingsRepository _settings;
  final CalendarRepository? _calendar;
  final DateTime Function() _now;

  static String _key(String accountId, String uid) => 'invite.$accountId.$uid';

  /// What was answered for this event earlier on this device, if anything.
  Future<AttendeeStatus?> responseOf(String accountId, MeetingInvitation inv) async {
    final v = await _settings.getString(_key(accountId, inv.event.uid));
    if (v == null) return null;
    for (final s in AttendeeStatus.values) {
      if (s.name == v) return s;
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

  Future<void> respond({
    required String accountId,
    required MeetingInvitation invitation,
    required AttendeeStatus status,
    MessageHeader? original,
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
    await _settings.setString(_key(accountId, invitation.event.uid), status.name);
    await _recordInCalendar(invitation, me, status);
  }

  /// Keeps the event without answering the organizer.
  Future<void> addToCalendar({required String accountId, required MeetingInvitation invitation}) async {
    final me = await identityFor(accountId, invitation);
    await _recordInCalendar(invitation, me, AttendeeStatus.needsAction);
  }

  /// True when some calendar already holds this event.
  Future<bool> isInCalendar(MeetingInvitation invitation) async {
    final cal = _calendar;
    if (cal == null) return false;
    for (final src in await cal.sources()) {
      if ((await cal.eventsByUid(src.id, invitation.event.uid)).isNotEmpty) return true;
    }
    return false;
  }

  /// The organizer cancelled: drop the local copy and forget the answer.
  Future<void> withdraw({required String accountId, required MeetingInvitation invitation}) async {
    await _settings.setString(_key(accountId, invitation.event.uid), null);
    final cal = _calendar;
    if (cal == null) return;
    for (final src in await cal.sources()) {
      final existing = await cal.eventsByUid(src.id, invitation.event.uid);
      if (existing.isNotEmpty && src.kind == CalendarKind.local) await cal.deleteEvents([for (final e in existing) e.id]);
    }
  }

  Future<void> _recordInCalendar(MeetingInvitation inv, Identity? me, AttendeeStatus status) async {
    final cal = _calendar;
    if (cal == null) return;
    try {
      final uid = inv.event.uid;
      // Declined: make sure no local copy lingers.
      if (status == AttendeeStatus.declined) {
        final existing = await cal.eventsByUid(localCalendarId, uid);
        if (existing.isNotEmpty) await cal.deleteEvents([for (final e in existing) e.id]);
        return;
      }
      // Already in a synced calendar (the invite landed there too)? Leave it.
      for (final src in await cal.sources()) {
        if (src.id == localCalendarId) continue;
        if ((await cal.eventsByUid(src.id, uid)).isNotEmpty) return;
      }
      if (await cal.source(localCalendarId) == null) {
        await cal.upsertSource(const CalendarSource(id: localCalendarId, name: 'Invitations', kind: CalendarKind.local, color: 0xFF3F51B5, enabled: true));
      }
      final attendees = [
        for (final a in inv.event.attendees)
          me != null && a.email.toLowerCase() == me.email.toLowerCase() ? Attendee(email: a.email, name: a.name, status: status) : a,
      ];
      final e = inv.event.copyWith(
        id: calendarEventId(localCalendarId, uid, inv.event.recurrenceId),
        calendarId: localCalendarId,
        attendees: attendees,
        updatedAt: _now().toUtc(),
      );
      await cal.upsertEvents([e]);
    } catch (e, st) {
      _log.warning('could not record the invitation in the calendar', e, st);
    }
  }
}
