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
    this.isDefault = false,
  });

  final String id;
  final String accountId;
  final String name;
  final String email;
  final String? replyTo;
  final String signature;
  final bool isDefault;
}
