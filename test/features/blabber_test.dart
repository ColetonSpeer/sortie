import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/app/providers.dart';
import 'package:sortie/features/compose/compose_screen.dart';
import 'package:sortie/services/compose/blabber_composer.dart';

import '../fakes/fake_speech_input.dart';
import '../fakes/ui_fakes.dart';

const _sig = '\n\n-- \nDemo User (this is fake data)';

String _body(WidgetTester t) => t.widget<TextField>(find.byKey(const Key('composeBody'))).controller!.text;
String _subject(WidgetTester t) => t.widget<TextField>(find.byKey(const Key('composeSubject'))).controller!.text;
String _transcript(WidgetTester t) => t.widget<TextField>(find.byKey(const Key('blabberTranscript'))).controller!.text;

void main() {
  testWidgets('a reply: partial results replace rather than pile up, the thread rides along, the quote survives', (tester) async {
    final f = UiFakes();
    final h = DemoData.messages[0];
    final speech = FakeSpeechInput();
    f.speech = speech;
    BlabberRequest? got;
    final composer = _StubComposer((r) async {
      got = r;
      return BlabberResult(subject: r.currentSubject, body: 'Thanks, Thursday afternoon works for me.', notes: const ['Kept Thursday, dropped Wednesday.'], modelId: 'stub');
    });
    await tester.pumpWidget(f.app(
      ComposeScreen(accountId: h.accountId, replyUid: h.uid, sourceFolder: h.folderPath),
      extra: [blabberComposerProvider.overrideWithValue(composer)],
    ));
    await tester.pumpAndSettle();
    final before = _body(tester);
    expect(before, contains('wrote:'));

    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberSheet')), findsOneWidget);
    expect(speech.starts, 1, reason: 'a phone starts listening as soon as the sheet opens');
    expect(find.byKey(const Key('blabberStop')), findsOneWidget);

    speech.emit('thanks');
    await tester.pump();
    speech.emit('thanks wednesday');
    await tester.pump();
    speech.emit('thanks wednesday actually thursday works', done: true);
    await tester.pump();
    expect(_transcript(tester), 'thanks wednesday actually thursday works');
    expect(speech.starts, 2, reason: 'the platform ended the session after words were heard, so it restarts');

    speech.emit('afternoon');
    await tester.pump();
    expect(_transcript(tester), 'thanks wednesday actually thursday works afternoon');

    await tester.tap(find.byKey(const Key('blabberStop')));
    await tester.pump();
    expect(speech.stops, 1);
    speech.finish('afternoon please');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberMic')), findsOneWidget, reason: 'back to idle after the user stopped');
    expect(speech.starts, 2);
    expect(_transcript(tester), 'thanks wednesday actually thursday works afternoon please');

    await tester.enterText(find.byKey(const Key('blabberInstruction')), 'friendly');
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(got!.transcript, 'thanks wednesday actually thursday works afternoon please');
    expect(got!.instruction, 'friendly');
    expect(got!.isReply, isTrue);
    expect(got!.existingText.trim(), isEmpty);
    expect(got!.conversation.map((t) => t.text).join(' '), contains(h.snippet.split(' ').first), reason: 'the replied-to message rides along');
    expect(find.text('Kept Thursday, dropped Wednesday.'), findsOneWidget);
    expect(tester.widget<CheckboxListTile>(find.byKey(const Key('blabberApplySubject'))).value, isFalse, reason: 'a reply keeps its subject by default');

    await tester.tap(find.byKey(const Key('blabberUse')));
    await tester.pumpAndSettle();
    expect(_body(tester), startsWith('Thanks, Thursday afternoon works for me.'));
    expect(_body(tester), contains('wrote:'), reason: 'the quoted reply survives');
    expect(_subject(tester), 'Re: ${h.subject}');
    expect(speech.cancels + speech.stops, greaterThan(0));
  });

  testWidgets('a new mail on desktop: typed thoughts, no microphone, subject applied, signature kept', (tester) async {
    final f = UiFakes();
    final composer = _StubComposer((r) async => BlabberResult(subject: 'Fiber drop on Thursday', body: 'Hi Brian,\n\nI will come by Thursday.', modelId: 'stub'));
    await tester.pumpWidget(f.app(
      const ComposeScreen(accountId: DemoData.accountId),
      extra: [blabberComposerProvider.overrideWithValue(composer)],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberMic')), findsNothing);
    expect(find.byKey(const Key('blabberStop')), findsNothing);
    expect(find.textContaining('Type or paste your thoughts'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('blabberTranscript')), 'tell brian thursday');
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(tester.widget<CheckboxListTile>(find.byKey(const Key('blabberApplySubject'))).value, isTrue);
    expect(find.text('Use it'), findsOneWidget);
    await tester.tap(find.byKey(const Key('blabberUse')));
    await tester.pumpAndSettle();
    expect(_subject(tester), 'Fiber drop on Thursday');
    expect(_body(tester), 'Hi Brian,\n\nI will come by Thursday.$_sig');
  });

  testWidgets('startBlabber opens the sheet by itself; an existing draft is handed along and "Replace my text" is offered', (tester) async {
    final f = UiFakes();
    BlabberRequest? got;
    final composer = _StubComposer((r) async {
      got = r;
      return const BlabberResult(subject: 'S', body: 'New body.', modelId: 'stub');
    });
    await tester.pumpWidget(f.app(
      const ComposeScreen(accountId: DemoData.accountId, startBlabber: true),
      extra: [blabberComposerProvider.overrideWithValue(composer)],
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberSheet')), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberSheet')), findsNothing);

    tester.widget<TextField>(find.byKey(const Key('composeBody'))).controller!.text = 'Old text';
    await tester.pump();
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('blabberTranscript')), 'make it new');
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(got!.existingText, 'Old text');
    expect(find.text('Replace my text'), findsOneWidget);
    await tester.tap(find.byKey(const Key('blabberUse')));
    await tester.pumpAndSettle();
    expect(_body(tester), 'New body.');
  });

  testWidgets('no AI backend: the button explains; a failing model shows the error and lets you try again', (tester) async {
    final f = UiFakes();
    await tester.pumpWidget(f.app(
      const ComposeScreen(accountId: DemoData.accountId),
      extra: [blabberComposerProvider.overrideWithValue(_StubComposer((r) async => throw StateError('unreachable'), unavailable: 'No AI backend is configured.'))],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    expect(find.text('No AI backend is configured.'), findsOneWidget);
    expect(find.byKey(const Key('blabberSheet')), findsNothing);

    var calls = 0;
    final composer = _StubComposer((r) async {
      if (++calls == 1) throw const BlabberException('The model is down.');
      return const BlabberResult(subject: 'S', body: 'Second time lucky.', modelId: 'stub');
    });
    await tester.pumpWidget(f.app(const ComposeScreen(accountId: DemoData.accountId), extra: [blabberComposerProvider.overrideWithValue(composer)]));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Say or type something first'), findsOneWidget, reason: 'an empty transcript never goes to the model');
    expect(calls, 0);
    await tester.enterText(find.byKey(const Key('blabberTranscript')), 'hello');
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(find.text('The model is down.'), findsOneWidget);
    expect(_transcript(tester), 'hello', reason: 'the transcript is kept for another go');
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberBody')), findsOneWidget);
    await tester.tap(find.byKey(const Key('blabberAgain')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberBody')), findsNothing);
    expect(_transcript(tester), 'hello');
  });

  testWidgets('keep talking after a result restarts listening; a denied microphone leaves the text box', (tester) async {
    final f = UiFakes();
    final speech = FakeSpeechInput();
    f.speech = speech;
    final composer = _StubComposer((r) async => BlabberResult(subject: 'S', body: 'Body from ${r.transcript}.', modelId: 'stub'));
    await tester.pumpWidget(f.app(
      const ComposeScreen(accountId: DemoData.accountId),
      extra: [blabberComposerProvider.overrideWithValue(composer)],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    speech.emit('first part', done: true);
    await tester.pump();
    speech.finish();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberMic')), findsOneWidget, reason: 'an empty follow-up session ends listening quietly');
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(find.text('Body from first part.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('blabberMore')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberStop')), findsOneWidget);
    speech.emit('second part');
    await tester.pump();
    expect(_transcript(tester), 'first part second part');
    await tester.tap(find.byKey(const Key('blabberStop')));
    speech.finish('second part');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabberGo')));
    await tester.pumpAndSettle();
    expect(find.text('Body from first part second part.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    speech.availableResult = false;
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberMic')), findsNothing);
    expect(find.textContaining('not allowed'), findsOneWidget);
    expect(find.byKey(const Key('blabberTranscript')), findsOneWidget);
  });

  testWidgets('leaving the app while listening stops the recogniser', (tester) async {
    final f = UiFakes();
    final speech = FakeSpeechInput();
    f.speech = speech;
    await tester.pumpWidget(f.app(
      const ComposeScreen(accountId: DemoData.accountId),
      extra: [blabberComposerProvider.overrideWithValue(_StubComposer((r) async => throw StateError('unreachable')))],
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('blabber')));
    await tester.pumpAndSettle();
    expect(speech.starts, 1);
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
    expect(speech.stops, 1);
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    speech.finish('hi');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('blabberMic')), findsOneWidget);
    expect(_transcript(tester), 'hi');
  });
}

class _StubComposer implements BlabberComposer {
  _StubComposer(this.onCompose, {this.unavailable});
  final Future<BlabberResult> Function(BlabberRequest r) onCompose;
  final String? unavailable;
  @override
  Future<String?> unavailableReason() async => unavailable;
  @override
  Future<BlabberResult> compose(BlabberRequest request) => onCompose(request);
}
