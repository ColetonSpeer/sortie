import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sortie/platform/desktop/instance_requests.dart';

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('sortie-req'));
  tearDown(() async => dir.delete(recursive: true));

  test('a second launch hands its arguments to the running instance once', () async {
    final got = <List<String>>[];
    final server = InstanceRequests(dir)..watch(got.add);
    addTearDown(server.dispose);
    await InstanceRequests(dir).send(['--compose']);
    await Future<void>.delayed(const Duration(milliseconds: 300));
    expect(got, [
      ['--compose'],
    ]);
    expect(File('${dir.path}/${InstanceRequests.fileName}').existsSync(), isFalse, reason: 'consumed');
    await Future<void>.delayed(const Duration(seconds: 2, milliseconds: 200));
    expect(got.length, 1, reason: 'the poll does not deliver it again');
  });

  test('a request written before the watch started is delivered', () async {
    await InstanceRequests(dir).send([]);
    final got = <List<String>>[];
    final server = InstanceRequests(dir)..watch(got.add);
    addTearDown(server.dispose);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(got, [<String>[]]);
  });
}
