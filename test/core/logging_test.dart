import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:sortie/core/logging.dart';

void main() {
  test('severe records reach the file sink with their stack trace, others without', () {
    final lines = <String>[];
    initLogging(level: Level.INFO, sink: lines.add);
    Logger('t').info('plain');
    Logger('t').severe('boom', StateError('bad'), StackTrace.fromString('#0 main (file.dart:1)\n#1 run (file.dart:2)'));
    expect(lines.first, 'INFO t: plain');
    expect(lines.last, 'SEVERE t: boom | Bad state: bad\n    #0 main (file.dart:1)\n    #1 run (file.dart:2)');
    expect(logBuffer.snapshot().last, contains('boom'));
  });
}
