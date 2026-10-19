import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

/// Hands a second launch's arguments to the running instance through a file
/// in the app support directory, so a launcher or shortcut raises the window
/// that is hidden in the tray instead of silently exiting.
class InstanceRequests {
  InstanceRequests(this.dir);

  static final _log = Logger('instance');
  static const fileName = 'sortie.request';

  final Directory dir;
  StreamSubscription<FileSystemEvent>? _sub;
  Timer? _poll;

  File get _file => File('${dir.path}${Platform.pathSeparator}$fileName');

  /// Called by the losing instance: writes [args] and returns.
  Future<void> send(List<String> args) async {
    try {
      await _file.writeAsString(jsonEncode(args), flush: true);
    } catch (e) {
      _log.warning('could not hand off to the running instance', e);
    }
  }

  /// Called by the running instance. Delivers each request's arguments once;
  /// a request written before the watch started is delivered too.
  void watch(void Function(List<String> args) onRequest) {
    unawaited(_deliver(onRequest));
    try {
      _sub = dir.watch(events: FileSystemEvent.create | FileSystemEvent.modify | FileSystemEvent.move).listen((e) {
        if (e.path.endsWith(fileName)) unawaited(_deliver(onRequest));
      }, onError: (Object e) => _log.fine('watch error: $e'));
    } catch (e) {
      _log.fine('directory watch unavailable, polling: $e');
    }
    // Belt and braces: some filesystems never raise events.
    _poll = Timer.periodic(const Duration(seconds: 2), (_) => unawaited(_deliver(onRequest)));
  }

  Future<void> _deliver(void Function(List<String> args) onRequest) async {
    final f = _file;
    try {
      if (!await f.exists()) return;
      final raw = await f.readAsString();
      await f.delete();
      if (raw.trim().isEmpty) {
        onRequest(const []);
        return;
      }
      final decoded = jsonDecode(raw);
      onRequest(decoded is List ? decoded.cast<String>() : const []);
    } on FileSystemException {
      // Already consumed, or mid-write: the next event or poll picks it up.
    } catch (e) {
      _log.warning('bad instance request ignored', e);
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    _poll?.cancel();
    await _sub?.cancel();
  }
}
