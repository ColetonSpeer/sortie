import 'dart:collection';

import 'package:logging/logging.dart';

/// Ring buffer of recent log lines, exported from Settings > Diagnostics.
class LogBuffer {
  LogBuffer({this.capacity = 5000});
  final int capacity;
  final _lines = ListQueue<String>();

  void add(LogRecord r) {
    final line = '${r.time.toIso8601String()} ${r.level.name.padRight(7)} '
        '${r.loggerName}: ${r.message}'
        '${r.error != null ? ' | ${r.error}' : ''}';
    _lines.addLast(line);
    while (_lines.length > capacity) {
      _lines.removeFirst();
    }
  }

  List<String> snapshot() => _lines.toList(growable: false);
}

final logBuffer = LogBuffer();

/// Call once at startup. Secrets must never be logged by callers.
void initLogging({Level level = Level.INFO, void Function(String)? sink}) {
  Logger.root.level = level;
  Logger.root.onRecord.listen((r) {
    logBuffer.add(r);
    sink?.call('${r.level.name} ${r.loggerName}: ${r.message}');
  });
}
