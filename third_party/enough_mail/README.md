# enough_mail 2.1.7 (vendored)

Unmodified copy of [enough_mail 2.1.7](https://pub.dev/packages/enough_mail/versions/2.1.7)
except for one fix in `lib/src/private/util/client_base.dart`:

When the server closes an IMAP or SMTP connection, the socket's `onDone`
(and `onError`) only flipped `isConnected` to false. The half-closed socket
was never closed on our side, and `disconnect()` skipped the close because
the client no longer counted as connected. Every reconnect and every SMTP
QUIT left a socket in `CLOSE_WAIT` for the life of the process (Sortie's
desktop had ten of them after three days).

The patch destroys the socket as soon as the connection is reported lost,
and makes `disconnect()` destroy it when called on an already-dead client.
Search for `Sortie patch` in that file.

Wired in through `dependency_overrides` in the root `pubspec.yaml`.
