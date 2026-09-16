import 'dart:convert';

import '../../../domain/entities/entities.dart';

/// PendingOp <-> `pending_ops.type` + `payload_json`.
abstract final class PendingOpCodec {
  static String typeOf(PendingOp op) => switch (op) {
        SetFlagsOp() => 'setFlags',
        MoveOp() => 'move',
        DeleteOp() => 'delete',
        AppendOp() => 'append',
        SendOp() => 'send',
      };

  static Map<String, dynamic> payload(PendingOp op) => switch (op) {
        final SetFlagsOp o => {
            'folder': o.folderPath,
            'uv': o.uidValidity,
            'hashes': o.messageIdHashes,
            'uids': o.uids,
            'add': o.add.toList()..sort(),
            'remove': o.remove.toList()..sort(),
          },
        final MoveOp o => {
            'from': o.fromFolder,
            'to': o.toFolder,
            'uv': o.uidValidity,
            'hashes': o.messageIdHashes,
            'uids': o.uids,
            'cause': o.cause,
          },
        final DeleteOp o => {
            'folder': o.folderPath,
            'uv': o.uidValidity,
            'hashes': o.messageIdHashes,
            'uids': o.uids,
            'permanent': o.permanent,
          },
        final AppendOp o => {
            'folder': o.folderPath,
            'raw': o.rawMessagePath,
            'flags': o.flags.toList()..sort(),
          },
        final SendOp o => {
            'identity': o.identityId,
            'raw': o.rawMessagePath,
            'recipients': o.recipients,
            'smtpAccepted': o.smtpAccepted,
          },
      };

  static String encode(PendingOp op) => jsonEncode(payload(op));

  static PendingOp decode({required String id, required String accountId, required DateTime createdAt, required String type, required String payloadJson}) {
    final j = jsonDecode(payloadJson) as Map<String, dynamic>;
    List<String> strs(String k) => ((j[k] as List?) ?? const []).cast<String>();
    List<int> ints(String k) => ((j[k] as List?) ?? const []).map((e) => (e as num).toInt()).toList();
    switch (type) {
      case 'setFlags':
        return SetFlagsOp(
          id: id,
          accountId: accountId,
          createdAt: createdAt,
          folderPath: j['folder'] as String,
          uidValidity: (j['uv'] as num).toInt(),
          messageIdHashes: strs('hashes'),
          uids: ints('uids'),
          add: strs('add').toSet(),
          remove: strs('remove').toSet(),
        );
      case 'move':
        return MoveOp(
          id: id,
          accountId: accountId,
          createdAt: createdAt,
          fromFolder: j['from'] as String,
          toFolder: j['to'] as String,
          uidValidity: (j['uv'] as num).toInt(),
          messageIdHashes: strs('hashes'),
          uids: ints('uids'),
          cause: (j['cause'] as String?) ?? 'manual',
        );
      case 'delete':
        return DeleteOp(
          id: id,
          accountId: accountId,
          createdAt: createdAt,
          folderPath: j['folder'] as String,
          uidValidity: (j['uv'] as num).toInt(),
          messageIdHashes: strs('hashes'),
          uids: ints('uids'),
          permanent: (j['permanent'] as bool?) ?? false,
        );
      case 'append':
        return AppendOp(
          id: id,
          accountId: accountId,
          createdAt: createdAt,
          folderPath: j['folder'] as String,
          rawMessagePath: j['raw'] as String,
          flags: strs('flags').toSet(),
        );
      case 'send':
        return SendOp(
          id: id,
          accountId: accountId,
          createdAt: createdAt,
          identityId: j['identity'] as String,
          rawMessagePath: j['raw'] as String,
          recipients: strs('recipients'),
          smtpAccepted: (j['smtpAccepted'] as bool?) ?? false,
        );
      default:
        throw FormatException('unknown pending op type $type');
    }
  }
}
