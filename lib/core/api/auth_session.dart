/// Lets the API layer tell auth state when a stored session is no longer valid.
class AuthSession {
  static void Function()? onUnauthorized;

  static void notifyUnauthorized() {
    onUnauthorized?.call();
  }
}
