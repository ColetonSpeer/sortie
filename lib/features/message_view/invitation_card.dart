import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import '../../services/calendar/invitations.dart';
import '../calendar/calendar_providers.dart';

/// Meeting invitation found in a mail: what, when, where, who, and the
/// Accept / Tentative / Decline answer (an iTIP reply to the organizer).
class InvitationCard extends ConsumerStatefulWidget {
  const InvitationCard({super.key, required this.header, required this.invitation});

  final MessageHeader header;
  final MeetingInvitation invitation;

  @override
  ConsumerState<InvitationCard> createState() => _InvitationCardState();
}

class _InvitationCardState extends ConsumerState<InvitationCard> {
  AttendeeStatus? _answer;
  bool _inCalendar = false;
  bool _busy = false;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final svc = ref.read(invitationServiceProvider);
      final a = await svc.responseOf(widget.header.accountId, widget.invitation);
      final present = await svc.isInCalendar(widget.invitation);
      if (mounted) {
        setState(() {
          _answer = a;
          _inCalendar = present;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  /// Which calendar the event goes to: the only writable one, or the one the
  /// user picks from a dialog (last choice first). Null when cancelled.
  Future<String?> _pickCalendar() async {
    final svc = ref.read(invitationServiceProvider);
    // Kept alive by the watch in build(); fall back to the first stream value.
    var all = ref.read(calendarSourcesProvider).asData?.value;
    if (all == null) {
      try {
        all = await ref.read(calendarSourcesProvider.future).timeout(const Duration(seconds: 3));
      } catch (_) {
        all = const [];
      }
    }
    if (!mounted) return null;
    final sources = all.where((s) => s.isWritable).toList();
    if (sources.isEmpty) return InvitationService.localCalendarId;
    if (sources.length == 1) return sources.single.id;
    final preferred = await svc.preferredCalendar();
    if (!mounted) return null;
    sources.sort((a, b) => (a.id == preferred ? 0 : 1).compareTo(b.id == preferred ? 0 : 1));
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Add to which calendar?'),
        children: [
          for (final s in sources)
            SimpleDialogOption(
              key: Key('calendarChoice:${s.id}'),
              onPressed: () => Navigator.of(ctx).pop(s.id),
              child: Row(children: [
                Container(width: 12, height: 12, decoration: BoxDecoration(color: Color(s.color), shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(s.name)),
                if (s.id == preferred) const Icon(Icons.history, size: 16),
              ]),
            ),
        ],
      ),
    );
    if (picked != null) await svc.rememberCalendar(picked);
    return picked;
  }

  Future<void> _respond(AttendeeStatus status) async {
    final calendarId = status == AttendeeStatus.declined ? null : await _pickCalendar();
    if (status != AttendeeStatus.declined && calendarId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(invitationServiceProvider).respond(
            accountId: widget.header.accountId,
            invitation: widget.invitation,
            status: status,
            original: widget.header,
            calendarId: calendarId,
          );
      if (mounted) {
        setState(() {
          _answer = status;
          _inCalendar = status != AttendeeStatus.declined;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send the reply: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _add() async {
    final calendarId = await _pickCalendar();
    if (calendarId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(invitationServiceProvider).addToCalendar(accountId: widget.header.accountId, invitation: widget.invitation, calendarId: calendarId);
      if (mounted) setState(() => _inCalendar = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not add it: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _withdraw() async {
    setState(() => _busy = true);
    try {
      await ref.read(invitationServiceProvider).withdraw(accountId: widget.header.accountId, invitation: widget.invitation);
      if (mounted) setState(() => _answer = null);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(calendarSourcesProvider);
    final inv = widget.invitation;
    final e = inv.event;
    final theme = Theme.of(context);
    final cancelled = inv.method == InvitationMethod.cancel;
    final when = CalFmt.span(EventOccurrence(event: e, start: e.start, end: e.end));
    final who = inv.organizerName?.isNotEmpty == true ? '${inv.organizerName} <${inv.organizer}>' : (inv.organizer ?? '');
    return Card(
      key: const Key('invitationCard'),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(cancelled ? Icons.event_busy_outlined : Icons.event_available_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              switch (inv.method) {
                InvitationMethod.cancel => 'Meeting cancelled',
                InvitationMethod.reply => 'Reply to your invitation',
                InvitationMethod.other => 'Calendar event',
                _ => 'Meeting invitation',
              },
              style: theme.textTheme.titleSmall,
            ),
          ]),
          const SizedBox(height: 10),
          Text(e.summary.isEmpty ? '(no title)' : e.summary, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          _line(Icons.schedule_outlined, when),
          if (e.location != null && e.location!.isNotEmpty) _line(Icons.place_outlined, e.location!),
          if (who.isNotEmpty) _line(Icons.person_outline, who),
          if (e.attendees.isNotEmpty) _line(Icons.group_outlined, '${e.attendees.length} invited'),
          const SizedBox(height: 12),
          if (inv.method == InvitationMethod.request || inv.method == InvitationMethod.other) _answerRow(theme),
          if (cancelled)
            Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('The organizer cancelled this meeting.'),
              TextButton(onPressed: _busy ? null : _withdraw, child: const Text('Remove from calendar')),
            ]),
          if (inv.method == InvitationMethod.reply)
            Text(_replySummary(e), style: theme.textTheme.bodyMedium),
          if (_error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_error!, style: TextStyle(color: theme.colorScheme.error))),
        ]),
      ),
    );
  }

  Widget _answerRow(ThemeData theme) {
    final a = _answer;
    final canReply = widget.invitation.method == InvitationMethod.request && (widget.invitation.organizer ?? '').isNotEmpty;
    return Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
      if (a != null)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('You ${a == AttendeeStatus.tentative ? 'answered tentative' : a.name}', key: const Key('invitationAnswer')),
        ])
      else if (_inCalendar)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.event_available, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          const Text('In your calendar', key: Key('invitationInCalendar')),
        ]),
      if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      if (!_busy && _loaded) ...[
        if (canReply && a != AttendeeStatus.accepted) FilledButton(onPressed: () => _respond(AttendeeStatus.accepted), child: const Text('Accept')),
        if (canReply && a != AttendeeStatus.tentative) OutlinedButton(onPressed: () => _respond(AttendeeStatus.tentative), child: const Text('Tentative')),
        if (canReply && a != AttendeeStatus.declined) OutlinedButton(onPressed: () => _respond(AttendeeStatus.declined), child: const Text('Decline')),
        if (!_inCalendar)
          TextButton.icon(
            key: const Key('addToCalendar'),
            onPressed: _add,
            icon: const Icon(Icons.event_outlined, size: 18),
            label: Text(canReply ? 'Add without replying' : 'Add to calendar'),
          ),
      ],
    ]);
  }

  static String _replySummary(CalendarEvent e) {
    final parts = <String>[];
    for (final a in e.attendees) {
      if (a.status == AttendeeStatus.needsAction) continue;
      parts.add('${a.name ?? a.email}: ${a.status.name}');
    }
    return parts.isEmpty ? 'No answer in this reply.' : parts.join(', ');
  }

  Widget _line(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ]),
      );
}
