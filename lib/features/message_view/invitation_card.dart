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
      final a = await ref.read(invitationServiceProvider).responseOf(widget.header.accountId, widget.invitation);
      if (mounted) setState(() => _answer = a);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _respond(AttendeeStatus status) async {
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
          );
      if (mounted) setState(() => _answer = status);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not send the reply: $e');
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
          if (inv.method == InvitationMethod.request) _answerRow(theme),
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
    return Row(children: [
      if (a != null) ...[
        Icon(Icons.check_circle_outline, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text('You ${a == AttendeeStatus.tentative ? 'answered tentative' : a.name}', key: const Key('invitationAnswer')),
        const SizedBox(width: 12),
      ],
      if (_busy) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
      if (!_busy && _loaded)
        Wrap(spacing: 8, children: [
          if (a != AttendeeStatus.accepted) FilledButton(onPressed: () => _respond(AttendeeStatus.accepted), child: const Text('Accept')),
          if (a != AttendeeStatus.tentative) OutlinedButton(onPressed: () => _respond(AttendeeStatus.tentative), child: const Text('Tentative')),
          if (a != AttendeeStatus.declined) OutlinedButton(onPressed: () => _respond(AttendeeStatus.declined), child: const Text('Decline')),
        ]),
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
