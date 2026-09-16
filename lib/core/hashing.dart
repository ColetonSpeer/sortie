import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Stable identity for a message across UIDs and devices.
String messageIdHash({String? messageId, String? from, DateTime? date, String? subject}) {
  final mid = messageId?.trim();
  final input = (mid != null && mid.isNotEmpty)
      ? 'mid:${mid.toLowerCase()}'
      : 'fp:${(from ?? '').toLowerCase()}|${date?.toUtc().toIso8601String() ?? ''}|${subject ?? ''}';
  return sha256.convert(utf8.encode(input)).toString();
}

String sha256Hex(String s) => sha256.convert(utf8.encode(s)).toString();
