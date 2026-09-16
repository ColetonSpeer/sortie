import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/services/sorter/text_cleaner.dart';

import '../../fixtures/corpus.dart';

void main() {
  test('html -> text drops script/style/head/pixels, keeps content, collapses URLs', () {
    final t = TextCleaner.clean(null, html: Corpus.htmlBody);
    expect(t, contains('Hi there,'));
    expect(t, contains('Your invoice #4890 is attached. Pay at the portal (https://pay.acme.com/…).'));
    expect(t, isNot(contains('alert')));
    expect(t, isNot(contains('.x{')));
    expect(t, isNot(contains('Hi\n')));
    expect(t, isNot(contains('pixel')));
    expect(t, isNot(contains('old stuff')));
    expect(t, isNot(contains('Acme Billing Team')));
  });

  test('quoted replies and signatures are removed', () {
    final t = TextCleaner.clean(Corpus.quotedReplyBody);
    expect(t, 'Thanks, that works for me.\n\nLet\'s meet at 10.');
  });

  test('outlook and forwarded markers cut the tail', () {
    expect(TextCleaner.stripQuotedReplies('Yes.\n\n-----Original Message-----\nFrom: x\nblah'), 'Yes.');
    expect(TextCleaner.stripQuotedReplies('See below\n\nBegin forwarded message:\nFrom: a\n'), 'See below');
    expect(TextCleaner.stripQuotedReplies('Ok\n\nFrom: Bob <b@x>\nSent: Monday\nTo: me\nSubject: hi\nbody'), 'Ok');
    expect(TextCleaner.stripQuotedReplies('Ok\n\n---------- Forwarded message ---------\nFrom: a'), 'Ok');
  });

  test('redaction', () {
    expect(TextCleaner.redactSecrets('Your OTP is 123456.'), 'Your OTP is [CODE].');
    expect(TextCleaner.redactSecrets('PIN: 4821'), 'PIN: [CODE]');
    expect(TextCleaner.redactSecrets('Order 12345 shipped'), 'Order 12345 shipped');
    expect(TextCleaner.redactSecrets('Account 123456789012'), 'Account [NUM]');
    expect(TextCleaner.redactSecrets('Card 4111 1111 1111 1111'), 'Card [NUM]');
    expect(TextCleaner.redactSecrets('Key abcdefghij1234567890XYZ here'), 'Key [TOKEN] here');
    expect(TextCleaner.redactSecrets('Word abcdefghijklmnopqrstuvwxyz'), 'Word abcdefghijklmnopqrstuvwxyz');
    expect(TextCleaner.redactSecrets('Copyright 2019 verification'), 'Copyright 2019 verification');
  });

  test('truncate keeps whole words', () {
    expect(TextCleaner.truncate('hello brave new world', 12), 'hello brave…');
    expect(TextCleaner.truncate('short', 12), 'short');
  });

  test('plain text that looks like html is converted', () {
    expect(TextCleaner.clean('<p>Hi</p><p>there</p>'), 'Hi\n\nthere');
  });
}
