import '../../data/coordination/control_folder.dart';
import '../../domain/entities/entities.dart';

/// Message-ID templates and JSON helpers for control-folder records
/// (docs/coordination-protocol.md, "Control message envelope").
abstract final class ControlMessageIds {
  static const domain = 'sortie.invalid';

  static String shortId(String deviceId) {
    final s = deviceId.replaceAll('-', '');
    return s.length <= 12 ? s : s.substring(0, 12);
  }

  static String leaseClaim(String deviceId, int epoch) => '<lease-${shortId(deviceId)}-$epoch@$domain>';
  static String leaseBeat(String deviceId, int epoch, int n) => '<beat-${shortId(deviceId)}-$epoch-$n@$domain>';
  static String leaseRelease(String deviceId, int epoch) => '<release-${shortId(deviceId)}-$epoch@$domain>';
  static String presence(String deviceId, int n) => '<presence-${shortId(deviceId)}-$n@$domain>';
  static String journal(String deviceId, int seq) => '<j-${shortId(deviceId)}-$seq@$domain>';

  /// `upto` is the highest journal UID folded into the snapshot. A re-seed
  /// after the control folder was deleted has nothing applied yet; `seq`
  /// disambiguates those (`upto == 0`) so repeated re-seeds stay unique.
  static String snapshot(String deviceId, int upto, int seq) =>
      upto > 0 ? '<snap-${shortId(deviceId)}-$upto@$domain>' : '<snap-${shortId(deviceId)}-0-$seq@$domain>';
}

/// Control-message types.
abstract final class ControlTypes {
  static const leaseClaim = 'lease-claim';
  static const leaseBeat = 'lease-beat';
  static const leaseRelease = 'lease-release';
  static const presence = 'presence';
  static const decision = 'decision';
  static const moved = 'moved';
  static const undo = 'undo';
  static const correction = 'correction';
  static const resolved = 'resolved';
  static const config = 'config';
  static const identities = 'identities';
  static const rules = 'rules';
  static const calendars = 'calendars';
  static const prefs = 'prefs';
  static const snapshot = 'snapshot';
}

/// `{mid, uid, uv, subject?, from?}` encoding of a user-mail key.
Map<String, dynamic> messageKeyToJson(MessageKey k, {String? subject, String? from}) => {
      'mid': k.messageIdHash,
      if (k.uid != null) 'uid': k.uid,
      if (k.uidValidity != null) 'uv': k.uidValidity,
      if (subject != null) 'subject': subject,
      if (from != null) 'from': from,
    };

MessageKey messageKeyFromJson(String accountId, Map<String, dynamic> j) => MessageKey(
      accountId: accountId,
      messageIdHash: j['mid'] as String,
      uid: j['uid'] as int?,
      uidValidity: j['uv'] as int?,
    );

/// Leadership-relevant view of a device from its presence or claim body.
class DeviceInfo {
  const DeviceInfo({required this.deviceId, required this.name, required this.platform, required this.priority});
  final String deviceId;
  final String name;
  final String platform;
  final int priority;

  static DeviceInfo fromBody(String deviceId, Map<String, dynamic>? body, {int? headerPriority}) => DeviceInfo(
        deviceId: deviceId,
        name: (body?['deviceName'] as String?) ?? deviceId,
        platform: (body?['platform'] as String?) ?? 'other',
        priority: headerPriority ?? (body?['priority'] as int?) ?? 0,
      );
}

/// Convenience filters over a header fetch.
extension ControlMessageLists on Iterable<ControlMessage> {
  Iterable<ControlMessage> ofType(String type) => where((m) => m.type == type);
  int get maxUid => fold(0, (a, m) => m.uid > a ? m.uid : a);
}
