import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';
import 'package:sortie/features/compose/compose_screen.dart';
import 'package:sortie/services/compose/draft_reviewer.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/features/compose/quote.dart';

import '../fakes/ui_fakes.dart';

void main() {
  testWidgets('reply to mail addressed to an alias picks the alias identity', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[7]; // To: alias@example.invalid
    expect(h.to.single.email, 'alias@example.invalid');

    await tester.pumpWidget(f.app(ComposeScreen(accountId: h.accountId, replyUid: h.uid, sourceFolder: h.folderPath)));
    await tester.pumpAndSettle();

    expect(find.text('Demo Alias <alias@example.invalid>'), findsOneWidget);
    expect(find.text('Re: ${h.subject}'), findsOneWidget);
    expect(find.textContaining('wrote:'), findsOneWidget);
  });

  testWidgets('new message uses the default identity and Send calls sync.send', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();

    expect(find.text('Demo User <demo@example.invalid>'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'name@example.com').first, 'pat@example.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Subject'), 'Hello');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(f.sync.sent, hasLength(1));
    expect(f.sync.sent.single.$2, 'id-main');
    expect(f.sync.sent.single.$3, ['pat@example.invalid']);
  });

  testWidgets('new message pre-fills the signature with the cursor at the top', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();

    final body = tester.widget<TextField>(find.byWidgetPredicate((w) => w is TextField && w.expands));
    expect(body.controller!.text, '\n\n-- \nDemo User (this is fake data)');
    expect(body.controller!.selection, const TextSelection.collapsed(offset: 0));
  });

  testWidgets('reply puts the cursor above the signature, and the signature above the quote', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    await tester.pumpWidget(f.app(ComposeScreen(accountId: h.accountId, replyUid: h.uid, sourceFolder: h.folderPath)));
    await tester.pumpAndSettle();

    final body = tester.widget<TextField>(find.byWidgetPredicate((w) => w is TextField && w.expands));
    final text = body.controller!.text;
    expect(text, startsWith('\n\n-- \nDemo User (this is fake data)\n\nOn '));
    expect(text, contains('wrote:'));
    expect(body.controller!.selection, const TextSelection.collapsed(offset: 0));
    expect(tester.widget<EditableText>(find.byType(EditableText).last).focusNode.hasFocus, isTrue);
  });

  testWidgets('right-clicking a recipient chip can move it to Cc/Bcc or remove it', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'name@example.com').first, 'pat@example.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    Finder chipIn(String line) => find.descendant(of: find.byKey(ValueKey('recipients-$line')), matching: find.byType(InputChip));
    expect(chipIn('To'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipients-Cc')), findsNothing);

    await tester.tapAt(tester.getCenter(chipIn('To')), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    expect(find.text('Move to To'), findsNothing);
    await tester.tap(find.text('Move to Cc'));
    await tester.pumpAndSettle();
    expect(chipIn('To'), findsNothing);
    expect(chipIn('Cc'), findsOneWidget);

    await tester.tapAt(tester.getCenter(chipIn('Cc')), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Move to Bcc'));
    await tester.pumpAndSettle();
    expect(chipIn('Cc'), findsNothing);
    expect(chipIn('Bcc'), findsOneWidget);

    await tester.longPress(chipIn('Bcc'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove'));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNothing);
  });

  Finder bodyField() => find.byWidgetPredicate((w) => w is TextField && w.expands);

  testWidgets('autosave stores a draft after the delay and replaces the previous copy', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();

    // Untouched new message: nothing is saved.
    await tester.pump(ComposeScreen.autosaveDelay + const Duration(seconds: 1));
    expect(f.sync.drafts, isEmpty);

    await tester.enterText(bodyField(), 'first words');
    await tester.pump(ComposeScreen.autosaveDelay - const Duration(seconds: 1));
    expect(f.sync.drafts, isEmpty, reason: 'not yet');
    await tester.pump(const Duration(seconds: 2));
    expect(f.sync.drafts.length, 1);
    expect(f.sync.drafts.single.$3, isNull);
    expect(find.byKey(const Key('draftSavedAt')), findsOneWidget);

    // Unchanged content: no second save.
    await tester.pump(ComposeScreen.autosaveDelay + const Duration(seconds: 1));
    expect(f.sync.drafts.length, 1);

    await tester.enterText(bodyField(), 'first words and more');
    await tester.pump(ComposeScreen.autosaveDelay + const Duration(seconds: 1));
    expect(f.sync.drafts.length, 2);
    expect(f.sync.drafts.last.$3, '<d1@test>', reason: 'second copy supersedes the first');
  });

  testWidgets('send passes the autosaved draft id so it is removed after sending', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId)));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'name@example.com').first, 'pat@example.invalid');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Subject'), 'Hello');
    await tester.pump(ComposeScreen.autosaveDelay + const Duration(seconds: 1));
    expect(f.sync.drafts.length, 1);

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(f.sync.sent, hasLength(1));
    expect(f.sync.sentDraftIds.single, '<d1@test>');
  });

  testWidgets('closing with unsaved changes asks; Discard removes the autosaved copy', (tester) async {
    final f = UiFakes();
    var closed = 0;
    await tester.pumpWidget(f.app(ComposeScreen(accountId: DemoData.accountId, onClose: () => closed++)));
    await tester.pumpAndSettle();

    // Nothing typed: closes straight away.
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(find.text('Save as draft?'), findsNothing);

    await tester.enterText(bodyField(), 'draft text');
    await tester.pump(ComposeScreen.autosaveDelay + const Duration(seconds: 1));
    expect(f.sync.drafts.length, 1);
    await tester.enterText(bodyField(), 'draft text, edited');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Save as draft?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(closed, 1);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(closed, 2);
    expect(f.sync.discarded, ['<d1@test>']);
  });

  testWidgets('closing with unsaved changes: Save stores the draft and closes', (tester) async {
    final f = UiFakes();
    var closed = 0;
    await tester.pumpWidget(f.app(ComposeScreen(accountId: DemoData.accountId, onClose: () => closed++)));
    await tester.pumpAndSettle();
    await tester.enterText(bodyField(), 'keep me');
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(f.sync.drafts.length, 1);
    expect(closed, 1);
  });

  test('Quote.pickIdentity falls back to the default identity', () {
    final h = DemoData.messages[0];
    expect(Quote.pickIdentity(DemoData.identities, h)!.id, 'id-main');
    expect(Quote.pickIdentity(DemoData.identities, DemoData.messages[7])!.id, 'id-alias');
  });

  testWidgets('Review with AI replaces only what I wrote and can update the subject', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    var asked = '';
    var conversation = const <ConversationTurn>[];
    ReviewDepth? depth;
    final reviewer = _StubReviewer((r) async {
      asked = '${r.instruction}|${r.body}';
      conversation = r.conversation;
      depth = r.depth;
      return const DraftReview(revisedBody: 'Thanks, that works for me.', revisedSubject: 'Re: Invoice confirmed', notes: ['Tightened wording.'], modelId: 'stub');
    });
    await tester.pumpWidget(f.app(
      ComposeScreen(accountId: h.accountId, replyUid: h.uid, sourceFolder: h.folderPath),
      extra: [draftReviewerProvider.overrideWithValue(reviewer)],
    ));
    await tester.pumpAndSettle();
    final bodyField = find.byKey(const Key('composeBody'));
    final before = tester.widget<TextField>(bodyField).controller!.text;
    expect(before, contains('wrote:'));
    final typed = 'thanks that werks for me';
    tester.widget<TextField>(bodyField).controller!.text = '$typed$before';
    await tester.pump();

    await tester.tap(find.byKey(const Key('reviewDraft')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rewrite'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('reviewInstruction')), 'friendlier');
    await tester.tap(find.byKey(const Key('runReview')));
    await tester.pumpAndSettle();
    expect(asked, 'friendlier|$typed');
    expect(depth, ReviewDepth.rewrite);
    expect(conversation.map((t) => t.text).join(' '), contains(h.snippet.split(' ').first), reason: 'the replied-to message rides along for context');
    expect(find.text('Tightened wording.'), findsOneWidget);
    expect(find.byKey(const Key('revisedBody')), findsOneWidget);

    await tester.tap(find.byKey(const Key('applyReview')));
    await tester.pumpAndSettle();
    final after = tester.widget<TextField>(bodyField).controller!.text;
    expect(after, startsWith('Thanks, that works for me.'));
    expect(after, contains('wrote:'), reason: 'the quoted reply survives');
    expect(after, isNot(contains('werks')));
    expect(tester.widget<TextField>(find.byKey(const Key('composeSubject'))).controller!.text, 'Re: Invoice confirmed');
  });

  testWidgets('the review can be corrected back and forth before it is applied', (tester) async {
    final f = UiFakes();
    final seen = <List<ReviewTurn>>[];
    var round = 0;
    final reviewer = _StubReviewer((r) async {
      seen.add(r.history);
      round++;
      return DraftReview(revisedBody: round == 1 ? 'Before our call I will fix it.' : 'As we discussed on the call, I will fix it by Monday.', notes: ['Round $round'], modelId: 'stub');
    });
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId), extra: [draftReviewerProvider.overrideWithValue(reviewer)]));
    await tester.pumpAndSettle();
    tester.widget<TextField>(find.byKey(const Key('composeBody'))).controller!.text = 'will fix it before call';
    await tester.pump();
    await tester.tap(find.byKey(const Key('reviewDraft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('runReview')));
    await tester.pumpAndSettle();
    expect(find.text('Before our call I will fix it.'), findsOneWidget);
    expect(seen.single, isEmpty);

    await tester.enterText(find.byKey(const Key('reviewCorrection')), 'The call already happened.');
    await tester.tap(find.byKey(const Key('reviseReview')));
    await tester.pumpAndSettle();
    expect(seen, hasLength(2));
    expect(seen.last.single.revisedBody, 'Before our call I will fix it.');
    expect(seen.last.single.correction, 'The call already happened.');
    expect(find.text('Revision 2'), findsOneWidget);
    expect(find.text('As we discussed on the call, I will fix it by Monday.'), findsOneWidget);
    expect(find.text('The call already happened.'), findsOneWidget, reason: 'the exchange stays visible');

    await tester.tap(find.byKey(const Key('applyReview')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const Key('composeBody'))).controller!.text, startsWith('As we discussed on the call'));
  });

  testWidgets('reviewing a reopened draft (CRLF from the cache) keeps the signature and the quoted replies', (tester) async {
    final f = UiFakes();
    final draft = DemoData.messages.singleWhere((m) => m.folderPath == 'Drafts');
    f.sync.bodiesByHash[draft.messageIdHash] = const MessageBody(
        text: 'hello aaron after the meeting is fine\r\n\r\n-- \r\nDemo User (this is fake data)\r\n\r\nOn Oct 22, 2026 12:25\u202fPM, "SDP Support" <sdp@innovsys.test> wrote:\r\n> are you available?\r\n');
    String? reviewed;
    final reviewer = _StubReviewer((r) async {
      reviewed = r.body;
      return const DraftReview(revisedBody: 'Hello Aaron,\n\nAfter the meeting is fine.', modelId: 'stub');
    });
    await tester.pumpWidget(f.app(
      ComposeScreen(accountId: draft.accountId, draftUid: draft.uid, sourceFolder: draft.folderPath),
      extra: [draftReviewerProvider.overrideWithValue(reviewer)],
    ));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('composeBody'));
    expect(tester.widget<TextField>(field).controller!.text, isNot(contains('\r')), reason: 'the editor works in LF');
    await tester.tap(find.byKey(const Key('reviewDraft')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('runReview')));
    await tester.pumpAndSettle();
    expect(reviewed, 'hello aaron after the meeting is fine', reason: 'signature and quote never reach the model');
    await tester.tap(find.byKey(const Key('applyReview')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(field).controller!.text,
        'Hello Aaron,\n\nAfter the meeting is fine.\n\n-- \nDemo User (this is fake data)\n\nOn Oct 22, 2026 12:25\u202fPM, "SDP Support" <sdp@innovsys.test> wrote:\n> are you available?\n');
  });

  testWidgets('re-saving or sending an edited draft keeps the In-Reply-To and References it was saved with', (tester) async {
    final f = UiFakes();
    const irt = '<orig@example.invalid>';
    await f.messages.upsertHeaders([
      MessageHeader(
        accountId: DemoData.accountId,
        folderPath: 'Drafts',
        uid: 9001,
        uidValidity: 1,
        messageIdHash: 'draft-9001',
        messageId: '<draft-9001@example.invalid>',
        subject: 'Re: Threaded',
        from: const MailAddress('demo@example.invalid', 'Demo User'),
        to: const [MailAddress('bob@example.invalid', 'Bob')],
        date: DateTime(2026, 10, 24, 9),
        inReplyTo: irt,
        references: const ['<older@example.invalid>', irt],
        flags: const {r'\Draft'},
        size: 10,
      ),
    ]);
    f.sync.bodiesByHash['draft-9001'] = const MessageBody(text: 'Hi Bob\r\n');
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId, draftUid: 9001, sourceFolder: 'Drafts')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(f.composedDrafts, isNotEmpty);
    expect(f.composedDrafts.last.inReplyTo, irt);
    expect(f.composedDrafts.last.references, ['<older@example.invalid>', irt]);
  });

  testWidgets('without an AI backend the review button explains instead of failing', (tester) async {
    final f = UiFakes();
    final reviewer = _StubReviewer((r) async => throw StateError('unreachable'), unavailable: 'No AI backend is configured.');
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId), extra: [draftReviewerProvider.overrideWithValue(reviewer)]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reviewDraft')));
    await tester.pumpAndSettle();
    expect(find.text('No AI backend is configured.'), findsOneWidget);
  });

  testWidgets('forwarding carries the original attachments into the draft and the sent message', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    expect(h.attachments.single.fileName, 'demo-invoice.pdf');
    f.sync.attachmentBytes['2'] = List<int>.generate(1000, (i) => i % 251);
    await tester.pumpWidget(f.app(ComposeScreen(accountId: h.accountId, forwardUid: h.uid, sourceFolder: h.folderPath)));
    await tester.pumpAndSettle();
    expect(find.text('Fwd: ${h.subject}'), findsOneWidget);
    expect(find.textContaining('demo-invoice.pdf'), findsOneWidget, reason: 'listed in the attachment strip');

    await tester.enterText(find.byKey(const Key('recipients-To')), 'bob@example.test');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();
    expect(f.sync.sent, hasLength(1));
    expect(f.composedDrafts.single.attachments.single.fileName, 'demo-invoice.pdf');
    expect(f.composedDrafts.single.attachments.single.size, 1000);
  });
}

class _StubReviewer implements DraftReviewer {
  _StubReviewer(this.onReview, {this.unavailable});
  final Future<DraftReview> Function(DraftReviewRequest r) onReview;
  final String? unavailable;
  @override
  Future<String?> unavailableReason() async => unavailable;
  @override
  Future<DraftReview> review(DraftReviewRequest request) => onReview(request);
}
