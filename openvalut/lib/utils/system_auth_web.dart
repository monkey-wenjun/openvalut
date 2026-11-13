/// Web build: there is no system password authentication.
Future<bool> authenticateWithSystemPassword() async => false;

/// Web build: there is no remembered-unlock gate.
Future<bool> authenticateForRememberedUnlock() async => true;

/// Web build: Windows Hello is not available.
Future<bool> verifyWindowsUserPresence() async => true;

/// Web build: there is no stable boot identifier.
Future<String?> currentBootId() async => null;
