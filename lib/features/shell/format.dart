import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/entities.dart';
import '../../domain/services/services.dart';

/// Small presentation helpers shared by the mail features.
abstract final class Fmt {
  static String relativeDate(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final local = d.toLocal();
    final diff = n.difference(local);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (local.year == n.year && local.month == n.month && local.day == n.day) return DateFormat.jm().format(local);
    if (diff.inDays < 7) return DateFormat.E().format(local);
    if (local.year == n.year) return DateFormat.MMMd().format(local);
    return DateFormat.yMd().format(local);
  }

  static String fullDate(DateTime d) => DateFormat.yMMMEd().add_jm().format(d.toLocal());

  static String dayHeading(DateTime d, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final l = d.toLocal();
    if (l.year == n.year && l.month == n.month && l.day == n.day) return 'Today';
    final y = n.subtract(const Duration(days: 1));
    if (l.year == y.year && l.month == y.month && l.day == y.day) return 'Yesterday';
    return DateFormat.yMMMEd().format(l);
  }

  static String bytes(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static String percent(double c) => '${(c * 100).round()}%';

  static String sender(MessageHeader h) => h.from?.name?.isNotEmpty == true ? h.from!.name! : (h.from?.email ?? '(unknown)');

  static String initials(String s) {
    final parts = s.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  static IconData folderIcon(Folder f) => switch (f.specialUse) {
        SpecialUse.inbox => Icons.inbox_outlined,
        SpecialUse.sent => Icons.send_outlined,
        SpecialUse.drafts => Icons.edit_note_outlined,
        SpecialUse.trash => Icons.delete_outline,
        SpecialUse.junk => Icons.report_gmailerrorred_outlined,
        SpecialUse.archive => Icons.archive_outlined,
        SpecialUse.all => Icons.all_inbox_outlined,
        SpecialUse.flagged => Icons.star_outline,
        SpecialUse.none => f.isInbox ? Icons.inbox_outlined : Icons.folder_outlined,
      };

  static String syncLabel(AccountSyncState s) => switch (s) {
        AccountSyncState.idle => 'Idle',
        AccountSyncState.connecting => 'Connecting…',
        AccountSyncState.syncing => 'Syncing…',
        AccountSyncState.idling => 'Up to date',
        AccountSyncState.backoff => 'Retrying…',
        AccountSyncState.offline => 'Offline',
        AccountSyncState.authFailed => 'Login failed',
        AccountSyncState.disabled => 'Disabled',
      };

  static IconData syncIcon(AccountSyncState s) => switch (s) {
        AccountSyncState.idling => Icons.cloud_done_outlined,
        AccountSyncState.connecting || AccountSyncState.syncing => Icons.cloud_sync_outlined,
        AccountSyncState.backoff => Icons.cloud_queue_outlined,
        AccountSyncState.offline => Icons.cloud_off_outlined,
        AccountSyncState.authFailed => Icons.lock_outline,
        AccountSyncState.disabled => Icons.pause_circle_outline,
        AccountSyncState.idle => Icons.cloud_outlined,
      };

  static IconData layerIcon(SortLayer? l) => switch (l) {
        SortLayer.rule => Icons.rule_outlined,
        SortLayer.learned => Icons.school_outlined,
        SortLayer.model => Icons.auto_awesome_outlined,
        null => Icons.help_outline,
      };

  static String layerLabel(SortLayer? l) => switch (l) {
        SortLayer.rule => 'Rule',
        SortLayer.learned => 'Learned from you',
        SortLayer.model => 'AI model',
        null => 'Unknown',
      };

  static IconData logTypeIcon(String type) => switch (type) {
        'moved' => Icons.drive_file_move_outlined,
        'decision' => Icons.schedule_outlined,
        'undo' => Icons.undo,
        'correction' => Icons.edit_outlined,
        'resolved' => Icons.check_circle_outline,
        _ => Icons.circle_outlined,
      };

  static String coordinationLabel(CoordinationState s) => switch (s) {
        CoordinationState.stopped => 'off',
        CoordinationState.connecting => 'connecting…',
        CoordinationState.syncing => 'syncing…',
        CoordinationState.follower => 'following',
        CoordinationState.candidate => 'electing…',
        CoordinationState.leader => 'this device',
        CoordinationState.yielding => 'handing off…',
      };
}
