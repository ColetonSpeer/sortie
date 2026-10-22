import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:sortie/core/clock.dart';
import 'package:sortie/data/ai/ai_provider.dart';
import 'package:sortie/data/ai/fake_ai_provider.dart';
import 'package:sortie/data/local/database.dart' as db;
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/domain/repositories/repositories.dart';
import 'package:sortie/services/sorter/sorter_pipeline.dart';

import '../../fixtures/corpus.dart';

db.SortieDatabase openTestDb() => db.SortieDatabase(NativeDatabase.memory());

/// In-memory MessageRepository: only what the sorter uses is implemented.
class FakeMessageRepository implements MessageRepository {
  final List<MessageHeader> headers = [];
  final Map<String, MessageBody> bodies = {};

  @override
  Future<List<MessageHeader>> sample(String accountId, String folderPath, {int limit = 200}) async {
    final rows = headers.where((h) => h.accountId == accountId && h.folderPath == folderPath).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return rows.take(limit).toList();
  }

  @override
  Future<MessageHeader?> byMessageIdHash(String accountId, String messageIdHash) async =>
      headers.where((h) => h.accountId == accountId && h.messageIdHash == messageIdHash).firstOrNull;

  @override
  Future<MessageBody?> cachedBody(String accountId, String messageIdHash) async => bodies[messageIdHash];

  @override
  Future<List<MessageHeader>> list(MessageQuery q) async =>
      headers.where((h) => h.accountId == q.accountId && (q.folderPath == null || h.folderPath == q.folderPath)).toList();

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('FakeMessageRepository.${i.memberName}');
}

class FakeSettingsRepository implements SettingsRepository {
  FakeSettingsRepository({this.aiSettings = const AiSettings(), SortConfig? config}) : config = config ?? const SortConfig();
  AiSettings aiSettings;
  SortConfig config;

  @override
  Future<AiSettings> ai() async => aiSettings;
  @override
  Future<SortConfig> sortConfig(String accountId) async => config;
  @override
  Future<void> saveAi(AiSettings s) async => aiSettings = s;
  @override
  Future<void> saveSortConfig(String accountId, SortConfig c) async => config = c;

  final strings = <String, String?>{};
  @override
  Future<String?> getString(String key) async => strings[key];
  @override
  Future<void> setString(String key, String? value) async => strings[key] = value;

  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('FakeSettingsRepository.${i.memberName}');
}

/// Everything a sorter test needs, bootstrapped from the corpus.
class Harness {
  Harness._(this.database, this.messages, this.settings, this.clock, this.fake, this.sorter);
  final db.SortieDatabase database;
  final FakeMessageRepository messages;
  final FakeSettingsRepository settings;
  final FakeClock clock;
  final FakeAiProvider fake;
  final SorterService sorter;

  /// Set to null to simulate "no provider configured".
  AiProvider? provider;

  static Future<Harness> create({
    AiSettings ai = const AiSettings(usage: AiUsageMode.perMessage, kind: AiProviderKind.openAiCompat, baseUrl: 'http://10.0.0.5:11434/v1', model: 'llama3'),
    SortConfig config = const SortConfig(mode: SortingMode.auto, leaveUntilRead: LeaveUntilRead.none),
    bool bootstrap = true,
    bool withProvider = true,
    int contextWindowTokens = 8192,
    Future<void> Function(String accountId, String path)? createFolder,
  }) async {
    final database = openTestDb();
    final messages = FakeMessageRepository()..headers.addAll(Corpus.history());
    final settings = FakeSettingsRepository(aiSettings: ai, config: config);
    final clock = FakeClock(Corpus.today);
    final fake = FakeAiProvider(contextWindowTokens: contextWindowTokens);
    late Harness h;
    final sorter = SorterService(
      database: database,
      messages: messages,
      settings: settings,
      provider: () => h.provider,
      clock: clock,
      deviceId: 'dev-test',
      createFolder: createFolder,
    );
    h = Harness._(database, messages, settings, clock, fake, sorter);
    h.provider = withProvider ? fake : null;
    await database.into(database.accounts).insert(db.AccountsCompanion.insert(
          id: Corpus.account,
          displayName: 'Test',
          email: 'me@example.com',
          username: 'me',
          imapHost: 'imap.example',
          imapPort: 993,
          imapSecurity: 'ssl',
          smtpHost: 'smtp.example',
          smtpPort: 587,
          smtpSecurity: 'starttls',
        ));
    for (final (path, name, special, count) in Corpus.folders) {
      await database.into(database.folders).insert(db.FoldersCompanion.insert(
            accountId: Corpus.account,
            path: path,
            name: name,
            delimiter: '/',
            specialUse: Value(special),
            messageCount: Value(count),
          ));
    }
    if (bootstrap) {
      // Bootstrap without a provider so descriptions do not consume the fake's script.
      final saved = h.provider;
      h.provider = null;
      await sorter.bootstrap(Corpus.account, config);
      h.provider = saved;
    }
    return h;
  }

  Future<void> close() async {
    await sorter.dispose();
    await database.close();
  }
}
