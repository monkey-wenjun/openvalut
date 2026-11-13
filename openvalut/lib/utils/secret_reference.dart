import 'package:kdbx/kdbx.dart';

/// A secret reference in the form `ov://<vault-id>/<entry-id>/<field>`.
///
/// Similar to 1Password's `op://` references, this URI identifies a single
/// field inside an unlocked vault without exposing the actual secret. The
/// running OpenValut app resolves the reference through the local credential
/// server.
class SecretReference {
  SecretReference({
    required this.vaultId,
    required this.entryId,
    required this.field,
  });

  /// The vault identifier, usually the file source's [displayName].
  final String vaultId;

  /// The entry identifier, usually the entry's UUID for stable lookup.
  final String entryId;

  /// The field name, e.g. `password`, `username`, `totp`, `url`, `notes` or a
  /// custom field key.
  final String field;

  static final _standardFields = <String, KdbxKey>{
    'title': KdbxKeyCommon.TITLE,
    'username': KdbxKeyCommon.USER_NAME,
    'password': KdbxKeyCommon.PASSWORD,
    'url': KdbxKeyCommon.URL,
    'notes': KdbxKey('Notes'),
    'totp': KdbxKeyCommon.OTP,
  };

  /// Parses a reference URI. Both `ov://` and `op://` schemes are accepted so
  /// that users can paste references from 1Password-compatible workflows, but
  /// OpenValut resolves them with its own vaults.
  static SecretReference? parse(String reference) {
    final uri = Uri.tryParse(reference.trim());
    if (uri == null) {
      return null;
    }
    if (uri.scheme != 'ov' && uri.scheme != 'op') {
      return null;
    }
    // `op://vault/item/field` puts the vault in the authority slot rather than
    // the path; fold it back in so both `op://` and `op:/` spellings work.
    final segments = <String>[
      if (uri.hasAuthority && uri.authority.isNotEmpty) uri.authority,
      ...uri.pathSegments.where((s) => s.isNotEmpty),
    ];
    if (segments.length < 3) {
      return null;
    }
    return SecretReference(
      vaultId: _decodeSegment(segments[0]),
      entryId: _decodeSegment(segments[1]),
      field: _decodeSegment(segments.sublist(2).join('/')),
    );
  }

  /// Builds a reference for the given vault, entry and field.
  ///
  /// [vaultId] is typically the opened file's display name. [entryId] is
  /// preferably the entry UUID so the reference stays valid even if the entry
  /// is renamed. [field] should be one of the standard field names or the raw
  /// custom field key. Slashes inside custom field keys are preserved.
  static String generate({
    required String vaultId,
    required String entryId,
    required String field,
  }) {
    return Uri(scheme: 'ov', pathSegments: [vaultId, entryId, field]).toString();
  }

  /// Returns the [KdbxKey] for this reference's field, or `null` if the field
  /// is not recognized as a standard field. Custom fields use their raw key
  /// and must be looked up separately.
  KdbxKey? get standardKey => _standardFields[field.toLowerCase()];

  /// Whether this reference points to the TOTP field.
  bool get isTotp => field.toLowerCase() == 'totp';

  static String _decodeSegment(String value) {
    // Uri already percent-decodes pathSegments / authority, so the value may
    // be raw text. Re-decode only the synthetic `%2F` that keeps slashes
    // inside custom field keys intact; already-decoded non-ASCII text would
    // make decodeComponent throw, so fall back to the value as-is.
    final input = value.replaceAll('/', '%2F');
    try {
      return Uri.decodeComponent(input);
    } on ArgumentError {
      return value;
    } on FormatException {
      return value;
    }
  }
}
