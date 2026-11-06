import 'dart:async';
import 'dart:io';
import 'dart:ui' show DisplayFeature, DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';

/// One fold of a folding display (iPhone Duo), in the window's logical
/// coordinates. The bounds already include the margins the system wants
/// kept clear of the crease.
@immutable
class FoldRegion {
  const FoldRegion(this.bounds, {required this.active});

  final Rect bounds;

  /// True while the device is partially folded, when content that crosses
  /// the fold is hard to read; false when it lies flat and the crease is
  /// only a seam.
  final bool active;

  /// A vertical fold (book pose) splits the window into a left and a right
  /// half; a horizontal one (laptop pose) into a top and a bottom half.
  bool get isVertical => bounds.height >= bounds.width;

  /// Whether the fold runs across the whole window of [size].
  bool spans(Size size) => isVertical ? bounds.top <= 1 && bounds.bottom >= size.height - 1 : bounds.left <= 1 && bounds.right >= size.width - 1;

  @override
  bool operator ==(Object other) => other is FoldRegion && other.bounds == bounds && other.active == active;

  @override
  int get hashCode => Object.hash(bounds, active);

  @override
  String toString() =>
      'FoldRegion(${bounds.left.toStringAsFixed(1)},${bounds.top.toStringAsFixed(1)} ${bounds.width.toStringAsFixed(1)}x${bounds.height.toStringAsFixed(1)}, active: $active)';
}

/// Everything the platform told us about folds; empty on ordinary screens.
@immutable
class FoldGeometry {
  const FoldGeometry(this.folds);

  static const none = FoldGeometry([]);

  final List<FoldRegion> folds;

  /// The fold that splits the window of [size] left/right, flat or not.
  FoldRegion? verticalFoldIn(Size size) => folds.where((f) => f.isVertical && f.spans(size)).firstOrNull;

  /// The fold that splits the window of [size] top/bottom while the device
  /// is partially folded (laptop pose). A flat horizontal seam is ignored:
  /// columns read fine across it.
  FoldRegion? activeHorizontalFoldIn(Size size) => folds.where((f) => f.active && !f.isVertical && f.spans(size)).firstOrNull;

  /// The active folds as Flutter display features, so dialogs, menus and
  /// sheets (which lay out inside [DisplayFeatureSubScreen]) stay on one
  /// side of the crease.
  List<DisplayFeature> get displayFeatures => [
    for (final f in folds)
      if (f.active) DisplayFeature(bounds: f.bounds, type: DisplayFeatureType.fold, state: DisplayFeatureState.postureHalfOpened),
  ];

  /// Decodes the map the native side sends: `{folds: [{x, y, w, h, active}]}`.
  static FoldGeometry parse(Object? event) {
    if (event is! Map) return none;
    final raw = event['folds'];
    if (raw is! List) return none;
    final folds = <FoldRegion>[];
    for (final e in raw) {
      if (e is! Map) continue;
      double d(String k) => (e[k] as num?)?.toDouble() ?? 0;
      folds.add(FoldRegion(Rect.fromLTWH(d('x'), d('y'), d('w'), d('h')), active: e['active'] == true));
    }
    return FoldGeometry(List.unmodifiable(folds));
  }

  @override
  bool operator ==(Object other) => other is FoldGeometry && listEquals(other.folds, folds);

  @override
  int get hashCode => Object.hashAll(folds);

  @override
  String toString() => 'FoldGeometry($folds)';
}

/// iOS only: the stream of fold geometry from `FoldReporter` in
/// ios/Runner/AppDelegate.swift (iOS 27.1 reserved regions). Flutter itself
/// leaves `MediaQuery.displayFeatures` empty on iOS, so the app bridges it.
abstract final class FoldReporter {
  static final log = Logger('fold');
  static const _channel = EventChannel('com.sortie.sortie/fold');

  static bool get supported => !kIsWeb && Platform.isIOS;

  static Stream<FoldGeometry> stream() {
    if (!supported) return const Stream.empty();
    return _channel.receiveBroadcastStream().map(FoldGeometry.parse).handleError((Object e) {
      // An older iOS without the bridge: nothing to report.
      log.fine('fold channel unavailable: $e');
    });
  }
}

/// Makes the fold known below it: active folds become display features in
/// [MediaQuery] (so dialogs avoid the crease) and the full geometry is
/// available through [FoldScope.of] for layouts that align to it.
class FoldAware extends StatefulWidget {
  const FoldAware({super.key, required this.child, this.folds});

  final Widget child;

  /// Test hook: where the geometry comes from instead of the platform.
  final Stream<FoldGeometry>? folds;

  @override
  State<FoldAware> createState() => _FoldAwareState();
}

class _FoldAwareState extends State<FoldAware> with WidgetsBindingObserver {
  static const _display = MethodChannel('com.sortie.sortie/display');
  StreamSubscription<FoldGeometry>? _sub;
  FoldGeometry _geometry = FoldGeometry.none;
  String _metrics = '';
  Timer? _watchdog;
  int _watchdogRounds = 0;
  bool _frameSeen = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sub = (widget.folds ?? FoldReporter.stream()).listen((g) {
      if (g == _geometry || !mounted) return;
      // One line per change: the proof, in sortie.log, that the phone
      // reports its fold (fold, unfold, rotate, Split View).
      FoldReporter.log.info('fold geometry: ${g.folds.isEmpty ? 'none' : g.folds.join(', ')}');
      setState(() => _geometry = g);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _watchdog?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  /// Folding, unfolding, rotating and Split View all arrive here as a new
  /// window size. Logged once per change, with the first frame drawn at it,
  /// so a display that stays black can be told apart from a layout that
  /// never ran (iPhone Duo, Flutter engine issue 195401). The keyboard only
  /// moves the bottom inset and is not a screen change, so it is ignored.
  @override
  void didChangeMetrics() {
    if (!FoldReporter.supported) return;
    final v = WidgetsBinding.instance.platformDispatcher.implicitView;
    if (v == null) return;
    final dpr = v.devicePixelRatio;
    final size = v.physicalSize / dpr;
    final pad = v.padding;
    final m = '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)} inset l${pad.left / dpr} t${pad.top / dpr} r${pad.right / dpr}';
    if (m == _metrics) return;
    _metrics = m;
    FoldReporter.log.info('window $m');
    _frameSeen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameSeen = true;
      FoldReporter.log.info('frame built for $m');
    });
    WidgetsBinding.instance.scheduleFrame();
    _watchdogRounds = 0;
    _armWatchdog();
  }

  /// On the iPhone Duo the engine's frame timer can be left on the display
  /// that just switched off, after which frames are requested but never
  /// drawn (black screen). When no frame has followed a screen change, the
  /// native side is asked to recreate the timer on the display that is on;
  /// a few rounds, since the change may still be settling.
  void _armWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(milliseconds: 700), () async {
      if (_frameSeen || !mounted) return;
      _watchdogRounds++;
      bool ok = false;
      try {
        ok = await _display.invokeMethod<bool>('recreateDisplayLink') ?? false;
      } catch (e) {
        FoldReporter.log.fine('display channel: $e');
      }
      FoldReporter.log.warning('no frame after the window changed (round $_watchdogRounds); frame timer recreated: $ok');
      WidgetsBinding.instance.scheduleFrame();
      if (_watchdogRounds < 6 && mounted) _armWatchdog();
    });
  }

  @override
  Widget build(BuildContext context) {
    final features = _geometry.displayFeatures;
    Widget child = widget.child;
    if (features.isNotEmpty) {
      final mq = MediaQuery.of(context);
      child = MediaQuery(
        data: mq.copyWith(displayFeatures: [...mq.displayFeatures, ...features]),
        child: child,
      );
    }
    return FoldScope(geometry: _geometry, child: child);
  }
}

/// The current [FoldGeometry]; [FoldGeometry.none] when nothing provides one.
class FoldScope extends InheritedWidget {
  const FoldScope({super.key, required this.geometry, required super.child});

  final FoldGeometry geometry;

  static FoldGeometry of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FoldScope>()?.geometry ?? FoldGeometry.none;

  @override
  bool updateShouldNotify(FoldScope old) => old.geometry != geometry;
}
