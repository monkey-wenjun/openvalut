import 'package:zxcvbn/zxcvbn.dart';

final _zxcvbn = Zxcvbn();

// Weakness is a property of the password itself, so the result can be cached
// across vaults and rebuilds. Bounded so a huge vault cannot grow it forever.
final _weakCache = <String, bool>{};
const _maxCacheEntries = 2048;

/// Whether [password] counts as weak.
///
/// Uses zxcvbn's score (0 = too guessable … 4 = very unguessable); anything
/// scoring 2 or below ("somewhat guessable" or worse) is offered as weak.
/// Empty / missing passwords are never reported as weak.
bool isWeakPassword(String? password) {
  if (password == null || password.isEmpty) {
    return false;
  }
  final cached = _weakCache[password];
  if (cached != null) {
    return cached;
  }
  var weak = false;
  try {
    weak = (_zxcvbn.evaluate(password).score ?? 0) <= 2;
  } catch (_) {
    // A malformed password must not take the whole vault down.
    weak = false;
  }
  if (_weakCache.length >= _maxCacheEntries) {
    _weakCache.clear();
  }
  _weakCache[password] = weak;
  return weak;
}
