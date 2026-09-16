import '../../domain/entities/entities.dart';

class SmtpSendResult {
  const SmtpSendResult({required this.accepted, this.response});
  final bool accepted;
  final String? response;
}

abstract class SmtpGateway {
  /// Sends [raw] (RFC 5322 bytes) from [identity] to [recipients].
  Future<SmtpSendResult> send(
    Account account,
    String password,
    Identity identity,
    List<String> recipients,
    List<int> raw,
  );

  /// Login-only probe used by onboarding.
  Future<void> testLogin(Account account, String password);
}

class SmtpGatewayException implements Exception {
  const SmtpGatewayException(this.message, {this.isAuthFailure = false, this.cause});
  final String message;
  final bool isAuthFailure;
  final Object? cause;
  @override
  String toString() => 'SmtpGatewayException: $message';
}
