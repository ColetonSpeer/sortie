import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/data/coordination/control_folder.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/services/coordination/coordination_service.dart';
import 'package:sortie/services/sorter/user_rules.dart';

import 'harness.dart';

Identity ident(String id, {String sig = 'Cheers', String? html, bool isDefault = true}) =>
    Identity(id: id, accountId: accountId, name: 'Me', email: 'me@example.test', signature: sig, signatureHtml: html, isDefault: isDefault);

SortRule rule(String id, {int priority = 10, String domain = 'example.test', String folder = 'Finance'}) => SortRule(
      id: id,
      accountId: accountId,
      priority: priority,
      match: RuleMatch(fromDomain: domain),
      action: RuleAction.moveTo,
      folderPath: folder,
      hits: 7,
    );

const calendar = CalendarSource(
  id: 'cal-1',
  name: 'Work',
  kind: CalendarKind.caldav,
  url: 'https://dav.example.test/cal/',
  username: 'me',
  authKind: CalendarAuthKind.basic,
  syncToken: 'tok-secret',
  ctag: 'ctag-secret',
  etag: 'etag-secret',
  lastError: 'err-local',
);

int sectionRecords(Harness h) => h.controlMessages().where((m) => ControlMessage.sharedSectionTypes.contains(m.type)).length;

void main() {
  coordinationTest('identity signature edited on A reaches B within one journal round; B never echoes', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    expect(sectionRecords(h), 0, reason: 'nothing to seed: both devices are empty');
    h.wait(a.accounts.upsertIdentity(ident('id-1', sig: 'v1', html: '<b>v1</b>')));
    h.elapse(const Duration(seconds: 4));
    final onB = h.wait(b.accounts.identities(accountId));
    expect(onB.single.id, 'id-1');
    expect(onB.single.signature, 'v1');
    expect(onB.single.signatureHtml, '<b>v1</b>');
    expect(onB.single.accountId, accountId);
    expect(h.ofType('identities').length, 1);
    final total = h.controlMessages().length;
    h.elapse(const Duration(seconds: 10));
    expect(h.controlMessages().length, total, reason: 'the receiver must not append an echo');
    expect(h.ofType('identities').length, 1);
    // A second edit is one more record; B follows.
    h.wait(a.accounts.upsertIdentity(ident('id-1', sig: 'v2', html: '<b>v2</b>')));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(b.accounts.identities(accountId)).single.signature, 'v2');
    expect(h.ofType('identities').length, 2);
    // Deleting on B removes on A (id diff).
    h.wait(b.accounts.deleteIdentity('id-1'));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(a.accounts.identities(accountId)), isEmpty);
    expect(h.ofType('identities').length, 3);
  });

  coordinationTest('rules imported on B replace A\'s rules with the same ids; hits stay out of the journal', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    h.wait(a.rules.upsert(rule('r-old', domain: 'old.test'), a.clock.now()));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(b.rules.load(accountId)).map((r) => r.id), ['r-old']);
    h.wait(b.rules.replaceAll(accountId, [rule('r-1', priority: 5, domain: 'one.test'), rule('r-2', priority: 20, domain: 'two.test', folder: 'Newsletters')]));
    h.elapse(const Duration(seconds: 4));
    final onA = h.wait(a.rules.load(accountId));
    expect(onA.map((r) => r.id).toList(), ['r-1', 'r-2']);
    expect(onA.first.match.fromDomain, 'one.test');
    expect(onA.last.folderPath, 'Newsletters');
    expect(onA.every((r) => r.accountId == accountId), isTrue);
    expect(onA.every((r) => r.hits == 0), isTrue, reason: 'hits are device-local');
    expect(h.ofType('rules').length, 2);
    expect(h.bodyText(h.ofType('rules').last.uid), isNot(contains('hits')));
  });

  coordinationTest('calendar added on A appears on B with no secret or sync-state field in the journal', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    h.wait(a.calendars.upsertSource(calendar));
    h.elapse(const Duration(seconds: 4));
    final onB = h.wait(b.calendars.sources());
    expect(onB.single.id, 'cal-1');
    expect(onB.single.url, calendar.url);
    expect(onB.single.authKind, CalendarAuthKind.basic, reason: 'needs sign-in on B until a password is entered there');
    expect(onB.single.syncToken, isNull);
    expect(onB.single.ctag, isNull);
    expect(onB.single.etag, isNull);
    expect(onB.single.lastError, isNull);
    final raw = h.bodyText(h.ofType('calendars').single.uid);
    for (final secret in ['refresh', 'password', 'syncToken', 'ctag', 'apiKey', 'etag', 'tok-secret', 'ctag-secret', 'err-local']) {
      expect(raw, isNot(contains(secret)), reason: '$secret must never reach the journal');
    }
    // A's own sync state survives the echo-free round trip.
    expect(h.wait(a.calendars.sources()).single.syncToken, 'tok-secret');
    h.elapse(const Duration(seconds: 10));
    expect(h.ofType('calendars').length, 1);
  });

  coordinationTest('prefs: threadedView toggled on A appears on B while B\'s mayLead is untouched; defaults are never seeded', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    h.wait(b.settings.saveDevice(const DeviceSettings(mayLead: false)));
    h.elapse(const Duration(seconds: 4));
    expect(h.ofType('prefs'), isEmpty, reason: 'per-device fields are not shared and defaults are not seeded');
    h.wait(a.settings.saveDevice(const DeviceSettings(threadedView: false, preferThisDevice: true)));
    h.elapse(const Duration(seconds: 4));
    final onB = h.wait(b.settings.device());
    expect(onB.threadedView, isFalse);
    expect(onB.mayLead, isFalse);
    expect(onB.preferThisDevice, isFalse, reason: 'per-device');
    expect(h.ofType('prefs').length, 1);
    h.wait(a.settings.saveAi(const AiSettings(kind: AiProviderKind.anthropic, model: 'claude-x')));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(b.settings.ai()).model, 'claude-x');
    expect(h.ofType('prefs').length, 2);
    expect(h.bodyText(h.ofType('prefs').last.uid), isNot(contains('apiKey')));
    expect(h.bodyText(h.ofType('prefs').last.uid), isNot(contains('mayLead')));
    h.elapse(const Duration(seconds: 10));
    expect(h.ofType('prefs').length, 2, reason: 'no echo');
  });

  coordinationTest('conflicting edits: the later UID wins on both devices', (h) {
    final a = h.lead('aaa');
    final b = h.follow('bbb');
    h.wait(a.accounts.upsertIdentity(ident('id-1', sig: 'from-a')));
    h.wait(b.accounts.upsertIdentity(ident('id-1', sig: 'from-b')));
    h.elapse(const Duration(seconds: 6));
    final recs = h.ofType('identities');
    expect(recs.length, 2);
    final winner = h.bodyJson(recs.last.uid)['items'][0]['signature'] as String;
    expect(h.wait(a.accounts.identities(accountId)).single.signature, winner);
    expect(h.wait(b.accounts.identities(accountId)).single.signature, winner);
    h.elapse(const Duration(seconds: 10));
    expect(h.ofType('identities').length, 2, reason: 'converged without further records');
  });

  coordinationTest('snapshot carries all four sections and a late joiner reconstructs them without republishing', (h) {
    final a = h.lead('aaa');
    h.wait(a.accounts.upsertIdentity(ident('id-1', sig: 'snap')));
    h.wait(a.rules.upsert(rule('r-1'), a.clock.now()));
    h.wait(a.calendars.upsertSource(calendar));
    h.wait(a.settings.saveDevice(const DeviceSettings(threadedView: false)));
    h.elapse(const Duration(seconds: 4));
    expect(sectionRecords(h), 4);
    h.wait(a.service.runMaintenance());
    h.settle();
    final snap = h.ofType('snapshot').single;
    final body = h.bodyJson(snap.uid);
    expect(body.keys, containsAll(['identities', 'rules', 'calendars', 'prefs']));
    expect(h.controlMessages().where((m) => m.isJournal), isEmpty);
    expect(h.bodyText(snap.uid), isNot(contains('tok-secret')));
    final z = h.follow('zzz');
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(z.accounts.identities(accountId)).single.signature, 'snap');
    expect(h.wait(z.rules.load(accountId)).single.id, 'r-1');
    expect(h.wait(z.calendars.sources()).single.id, 'cal-1');
    expect(h.wait(z.settings.device()).threadedView, isFalse);
    expect(sectionRecords(h), 0, reason: 'the late joiner adopted the snapshot silently');
  }, timers: const LeaseTimers(compactionMaxJournal: 3));

  coordinationTest('a device with local content seeds an empty journal; one with none adopts the journal', (h) {
    final a = h.addDevice('aaa');
    h.wait(a.accounts.upsertIdentity(ident('id-1', sig: 'seed')));
    a.service.start();
    h.elapse(const Duration(seconds: 40));
    // The first leader re-seeds a snapshot from its local view, which folds
    // the record it just published into the snapshot's `identities` section.
    final inSnapshot = h.ofType('snapshot').any((s) => h.bodyJson(s.uid).containsKey('identities'));
    expect(h.ofType('identities').isNotEmpty || inSnapshot, isTrue, reason: 'published on connect without any local change');
    final b = h.follow('bbb');
    h.elapse(const Duration(seconds: 3));
    expect(h.wait(b.accounts.identities(accountId)).single.signature, 'seed');
    expect(h.ofType('identities').length, lessThanOrEqualTo(1), reason: 'B adopts silently');
  });

  coordinationTest('records from an older app version lacking a section are ignored gracefully', (h) {
    final a = h.lead('aaa');
    h.wait(a.accounts.upsertIdentity(ident('id-1', sig: 'keep')));
    h.elapse(const Duration(seconds: 4));
    final raw = h.wait(h.rawControl(a.clock));
    final old = Harness.idOf('old');
    h.wait(raw.append(ControlMessageDraft(type: 'identities', deviceId: old, messageId: '<j-old-1@sortie.invalid>', seq: 1, body: const {'version': 0})));
    h.wait(raw.append(ControlMessageDraft(type: 'prefs', deviceId: old, messageId: '<j-old-2@sortie.invalid>', seq: 2, body: const {'ai': {'model': 'old-model'}})));
    h.wait(raw.append(ControlMessageDraft(type: 'rules', deviceId: old, messageId: '<j-old-3@sortie.invalid>', seq: 3, body: const {'items': 'not-a-list'})));
    h.elapse(const Duration(seconds: 4));
    expect(h.wait(a.accounts.identities(accountId)).single.signature, 'keep');
    expect(h.wait(a.settings.ai()).model, 'old-model', reason: 'the part that is present still applies');
    expect(h.wait(a.settings.device()).threadedView, isTrue);
    expect(h.ofType('identities').length, 2, reason: 'ignoring must not trigger a republish');
    expect(a.isLeader, isTrue);
    h.wait(raw.dispose());
  });
}
