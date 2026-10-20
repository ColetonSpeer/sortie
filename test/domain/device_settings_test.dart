import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/domain/entities/entities.dart';

void main() {
  test('background sorting is on by default on phones and round-trips', () {
    const d = DeviceSettings();
    expect(d.androidForegroundService, isTrue);
    expect(d.backgroundKeepAlive, isTrue);
    expect(DeviceSettings.fromJson(const {}).androidForegroundService, isTrue, reason: 'older installs that never set it');
    expect(DeviceSettings.fromJson(const {'fgService': false, 'keepAlive': false}).backgroundKeepAlive, isFalse);
    final back = DeviceSettings.fromJson(d.copyWith(backgroundKeepAlive: false).toJson());
    expect(back.backgroundKeepAlive, isFalse);
    expect(back.androidForegroundService, isTrue);
  });
}
