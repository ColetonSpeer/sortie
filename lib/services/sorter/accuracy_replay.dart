import 'dart:math';

import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../../domain/services/services.dart';
import 'folder_profiles.dart';

/// Dry run: re-classify recently filed mail as if it had just arrived in
/// INBOX and report the share the sorter would have filed the same way.
class AccuracyReplay {
  AccuracyReplay({required MessageRepository messages, required FolderProfileService profiles})
      : _messages = messages,
        _profiles = profiles;
  final MessageRepository _messages;
  final FolderProfileService _profiles;

  Future<double> run(
    String accountId,
    SortConfig config,
    Future<List<SortDecision>> Function(List<ClassificationInput> inputs) classify, {
    int sample = 200,
  }) async {
    final folders = await _profiles.sortable(accountId, config);
    if (folders.isEmpty || sample <= 0) return 0;
    final perFolder = max(5, (sample / folders.length).ceil());
    final pool = <MessageHeader>[];
    for (final f in folders) {
      pool.addAll(await _messages.sample(accountId, f.path, limit: perFolder));
    }
    if (pool.isEmpty) return 0;
    pool.sort((a, b) => b.date.compareTo(a.date));
    final chosen = pool.take(sample).toList();
    final inputs = [
      for (final h in chosen) ClassificationInput(header: h.copyWith(folderPath: 'INBOX', flags: const {})),
    ];
    final decisions = await classify(inputs);
    final expected = {for (final h in chosen) h.messageIdHash: h.folderPath};
    var agree = 0;
    for (final d in decisions) {
      final actual = expected[d.key.messageIdHash];
      if (actual != null && d.destination.toLowerCase() == actual.toLowerCase()) agree++;
    }
    return agree / chosen.length;
  }
}
