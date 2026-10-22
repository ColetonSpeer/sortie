import '../../domain/entities/entities.dart';
import '../../domain/repositories/repositories.dart';
import '../sorter/cost_meter.dart';

/// Why an explicit AI action (draft review, Blabber) cannot run right now,
/// or null when it can. Shared so every feature phrases it the same way.
Future<String?> aiUnavailableReason({required bool hasProvider, required SettingsRepository settings, CostMeter? costs}) async {
  final ai = await settings.ai();
  if (!hasProvider) {
    return ai.kind == AiProviderKind.none
        ? 'No AI backend is configured. Add one under Settings → AI backend.'
        : 'The API key for ${ai.kind.name} is not saved on this device. Enter it under Settings → AI backend.';
  }
  if (ai.paused) return 'AI use is paused in Settings → AI backend.';
  if (costs != null && await costs.capState(ai) == CapState.exceeded) return 'The AI spend cap for today or this month is reached.';
  return null;
}

/// Serialises earlier messages of a thread as data for the model.
String conversationBlock(Iterable<({String from, String text, DateTime? date})> turns) {
  final b = StringBuffer();
  b.writeln('<conversation>');
  for (final t in turns) {
    b.writeln('<message from="${t.from.replaceAll('"', "'")}"${t.date == null ? '' : ' date="${t.date!.toUtc().toIso8601String()}"'}>');
    b.writeln(t.text.length > 3000 ? '${t.text.substring(0, 3000)}\n[...]' : t.text);
    b.writeln('</message>');
  }
  b.writeln('</conversation>');
  return b.toString();
}
