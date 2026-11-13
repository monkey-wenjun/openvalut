/// No-op [SessionStore] for platforms without the kernel keyring (web).
class SessionStore {
  /// The master password another process of this user saved, if any.
  static String? read() => null;

  /// Publishes the master password for other terminals / SSH logins.
  static void save(String masterPassword) {}

  /// Forgets the shared master password.
  static void clear() {}
}
