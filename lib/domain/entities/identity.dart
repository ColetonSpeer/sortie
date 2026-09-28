/// A sending identity. Several identities may share one account's SMTP
/// (e.g. an alias like coleton.speer@prizmfiber.com on the hky.com account).
class Identity {
  const Identity({
    required this.id,
    required this.accountId,
    required this.name,
    required this.email,
    this.replyTo,
    this.signature = '',
    this.signatureHtml,
    this.isDefault = false,
  });

  final String id;
  final String accountId;
  final String name;
  final String email;
  final String? replyTo;

  /// Plain-text signature (what the composer appends).
  final String signature;

  /// Optional HTML version of the signature (e.g. imported from Thunderbird).
  /// Kept for a future HTML composer; [signature] is always the text form.
  final String? signatureHtml;
  final bool isDefault;

  /// Stable keys: this record travels between devices through the journal.
  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'name': name,
        'email': email,
        if (replyTo != null) 'replyTo': replyTo,
        'signature': signature,
        if (signatureHtml != null) 'signatureHtml': signatureHtml,
        'isDefault': isDefault,
      };

  static Identity fromJson(Map<String, dynamic> j) => Identity(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        name: (j['name'] as String?) ?? '',
        email: (j['email'] as String?) ?? '',
        replyTo: j['replyTo'] as String?,
        signature: (j['signature'] as String?) ?? '',
        signatureHtml: j['signatureHtml'] as String?,
        isDefault: (j['isDefault'] as bool?) ?? false,
      );
}
