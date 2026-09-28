import 'dart:collection';
import 'dart:io';

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
    sink?.call('${r.level.name} ${r.loggerName}: ${r.message}${r.error != null ? ' | ${r.error}' : ''}');
  });
}

/// Appends log lines to a file (rotated at ~2 MB) so release builds can be
/// diagnosed from Settings > Diagnostics or the file itself.
class FileLogSink {
  FileLogSink(this.path);
  final String path;
  IOSink? _sink;
  int _bytes = 0;

  void call(String line) {
    try {
      if (_sink == null) {
        final f = File(path);
        _bytes = f.existsSync() ? f.lengthSync() : 0;
        if (_bytes > 2 * 1024 * 1024) {
          final old = File('$path.1');
          if (old.existsSync()) old.deleteSync();
          f.renameSync(old.path);
          _bytes = 0;
        }
        _sink = File(path).openWrite(mode: FileMode.append);
      }
      final out = '${DateTime.now().toIso8601String()} $line\n';
      _bytes += out.length;
      _sink!.write(out);
    } catch (_) {
      // Logging must never take the app down.
    }
  }

  Future<void> close() async => _sink?.close();
}
