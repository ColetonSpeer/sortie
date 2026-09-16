import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/entities/entities.dart';
import 'settings_common.dart';

class SortingPage extends StatelessWidget {
  const SortingPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Sorting')),
        body: AccountScope(builder: (_, id) => _SortingBody(accountId: id)),
      );
}

class _SortingBody extends ConsumerStatefulWidget {
  const _SortingBody({required this.accountId});
  final String accountId;

  @override
  ConsumerState<_SortingBody> createState() => _SortingBodyState();
}

class _SortingBodyState extends ConsumerState<_SortingBody> {
  String? _progress;
  double? _accuracy;
  bool _busy = false;

  Future<void> _save(SortConfig c) => saveSortConfig(ref, widget.accountId, c);

  Future<void> _bootstrap(SortConfig c) async {
    setState(() {
      _busy = true;
      _progress = 'Starting…';
    });
    try {
      await ref.read(messageClassifierProvider).bootstrap(widget.accountId, c, progress: (m) {
        if (mounted) setState(() => _progress = m);
      });
      if (mounted) setState(() => _progress = 'Bootstrap complete');
    } catch (e) {
      if (mounted) setState(() => _progress = 'Bootstrap failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _accuracyCheck(SortConfig c) async {
    setState(() {
      _busy = true;
      _accuracy = null;
    });
    try {
      final a = await ref.read(messageClassifierProvider).accuracyReplay(widget.accountId, c);
      if (mounted) setState(() => _accuracy = a);
    } catch (e) {
      if (mounted) ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text('Accuracy check failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(sortConfigProvider(widget.accountId));
    final theme = Theme.of(context);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (c) => ListView(padding: const EdgeInsets.only(bottom: 32), children: [
        ListTile(
          title: const Text('Mode'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: SegmentedButton<SortingMode>(
              segments: const [
                ButtonSegment(value: SortingMode.off, label: Text('Off'), icon: Icon(Icons.pause)),
                ButtonSegment(value: SortingMode.suggestOnly, label: Text('Suggest'), icon: Icon(Icons.lightbulb_outline)),
                ButtonSegment(value: SortingMode.auto, label: Text('Auto'), icon: Icon(Icons.auto_awesome)),
              ],
              selected: {c.mode},
              onSelectionChanged: (s) => _save(c.copyWith(
                mode: s.first,
                enabledAt: s.first == SortingMode.auto && c.mode != SortingMode.auto ? DateTime.now().toUtc() : null,
              )),
            ),
          ),
        ),
        if (c.mode == SortingMode.auto && c.inProbation)
          ListTile(
            leading: Icon(Icons.info_outline, color: theme.colorScheme.tertiary),
            title: Text('Probation: only very confident moves for the first ${c.probationDays} days'),
          ),
        const Divider(),
        ListTile(title: Text('Leave in inbox until read', style: theme.textTheme.titleSmall)),
        RadioGroup<LeaveUntilRead>(
          groupValue: c.leaveUntilRead,
          onChanged: (v) {
            if (v != null) _save(c.copyWith(leaveUntilRead: v));
          },
          child: const Column(children: [
            RadioListTile(value: LeaveUntilRead.all, title: Text('All messages'), subtitle: Text('Nothing moves until you have read it')),
            RadioListTile(value: LeaveUntilRead.personalOnly, title: Text('Personal mail only'), subtitle: Text('Newsletters and automated mail move right away')),
            RadioListTile(value: LeaveUntilRead.none, title: Text('Move as soon as classified')),
          ]),
        ),
        ListTile(
          title: Text('Grace period after reading: ${c.graceMinutes} min'),
          subtitle: Slider(
            value: c.graceMinutes.toDouble().clamp(1, 60),
            min: 1,
            max: 60,
            divisions: 59,
            label: '${c.graceMinutes} min',
            onChanged: (v) => _save(c.copyWith(graceMinutes: v.round())),
          ),
        ),
        const Divider(),
        ListTile(title: Text('Confidence thresholds', style: theme.textTheme.titleSmall)),
        ListTile(
          title: Text('Move automatically at ≥ ${(c.moveThreshold * 100).round()}%'),
          subtitle: Slider(
            value: c.moveThreshold.clamp(0.5, 1.0),
            min: 0.5,
            max: 1.0,
            divisions: 50,
            onChanged: (v) => _save(c.copyWith(moveThreshold: v, suggestThreshold: c.suggestThreshold > v ? v : null)),
          ),
        ),
        ListTile(
          title: Text('Suggest at ≥ ${(c.suggestThreshold * 100).round()}%'),
          subtitle: Slider(
            value: c.suggestThreshold.clamp(0.3, 1.0),
            min: 0.3,
            max: 1.0,
            divisions: 70,
            onChanged: (v) => _save(c.copyWith(suggestThreshold: v > c.moveThreshold ? c.moveThreshold : v)),
          ),
        ),
        const Divider(),
        ListTile(title: Text('Learning', style: theme.textTheme.titleSmall)),
        ListTile(
          leading: const Icon(Icons.school_outlined),
          title: const Text('Run bootstrap now'),
          subtitle: Text(_progress ?? 'Builds folder profiles from mail you have already filed'),
          trailing: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : null,
          onTap: _busy ? null : () => _bootstrap(c),
        ),
        ListTile(
          leading: const Icon(Icons.fact_check_outlined),
          title: const Text('Check accuracy'),
          subtitle: Text(_accuracy == null
              ? 'Replays your last 200 filings without moving anything'
              : 'Agreement with your filing: ${(_accuracy! * 100).round()}%'),
          onTap: _busy ? null : () => _accuracyCheck(c),
        ),
      ]),
    );
  }
}
