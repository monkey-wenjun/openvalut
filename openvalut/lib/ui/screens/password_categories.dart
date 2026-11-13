import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kdbx/kdbx.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PasswordCategoryId {
  all,
  finance,
  bankCard,
  website,
  app,
  other,
}

class PasswordCategory {
  const PasswordCategory({
    required this.id,
    required this.defaultName,
    required this.icon,
  });

  final PasswordCategoryId id;
  final String defaultName;
  final FaIconData icon;

  String name(Map<PasswordCategoryId, String> overrides) {
    return overrides[id] ?? defaultName;
  }
}

const _categories = [
  PasswordCategory(
    id: PasswordCategoryId.all,
    defaultName: '全部',
    icon: FontAwesomeIcons.layerGroup,
  ),
  PasswordCategory(
    id: PasswordCategoryId.finance,
    defaultName: '金融',
    icon: FontAwesomeIcons.landmark,
  ),
  PasswordCategory(
    id: PasswordCategoryId.bankCard,
    defaultName: '银行卡',
    icon: FontAwesomeIcons.creditCard,
  ),
  PasswordCategory(
    id: PasswordCategoryId.website,
    defaultName: '网站',
    icon: FontAwesomeIcons.globe,
  ),
  PasswordCategory(
    id: PasswordCategoryId.app,
    defaultName: 'APP',
    icon: FontAwesomeIcons.mobileScreen,
  ),
  PasswordCategory(
    id: PasswordCategoryId.other,
    defaultName: '其他',
    icon: FontAwesomeIcons.boxArchive,
  ),
];

List<PasswordCategory> get passwordCategories => List.unmodifiable(_categories);

const _prefsKey = 'password_category_names';

class PasswordCategoryNames {
  PasswordCategoryNames._();

  static final Map<PasswordCategoryId, String> _cache = {};
  static bool _loaded = false;

  static Future<void> _ensureLoaded() async {
    if (_loaded) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_prefsKey);
    if (json != null && json.isNotEmpty) {
      for (final entry in _categories) {
        final custom = prefs.getString('${_prefsKey}_${entry.id.name}');
        if (custom != null && custom.isNotEmpty) {
          _cache[entry.id] = custom;
        }
      }
    }
    _loaded = true;
  }

  static Future<Map<PasswordCategoryId, String>> load() async {
    await _ensureLoaded();
    return Map.unmodifiable(_cache);
  }

  static Future<String> name(PasswordCategoryId id) async {
    await _ensureLoaded();
    return _cache[id] ?? _categories.firstWhere((c) => c.id == id).defaultName;
  }

  static Future<void> rename(PasswordCategoryId id, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    if (newName.isEmpty ||
        newName == _categories.firstWhere((c) => c.id == id).defaultName) {
      _cache.remove(id);
      await prefs.remove('${_prefsKey}_${id.name}');
    } else {
      _cache[id] = newName;
      await prefs.setString('${_prefsKey}_${id.name}', newName);
    }
  }
}

PasswordCategoryId classifyEntry(KdbxEntry entry) {
  final title = entry.getString(KdbxKeyCommon.TITLE)?.getText()?.toLowerCase() ?? '';
  final url = entry.getString(KdbxKeyCommon.URL)?.getText()?.toLowerCase() ?? '';
  final userName = entry.getString(KdbxKeyCommon.USER_NAME)?.getText()?.toLowerCase() ?? '';
  final combined = '$title $url $userName';

  final bankCardKeywords = [
    'card', 'credit', 'debit', 'visa', 'mastercard', 'paypal', 'stripe',
    '银行卡', '信用卡', '借记卡',
  ];
  final financeKeywords = [
    'bank', 'pay', 'payment', 'wallet',
    'alipay', 'wechat', '微信支付', '支付宝', '银行',
    '招商', '工商', '建设', '农业', '中国', '浦发', '中信', '民生',
    '金融', '证券', '股票',
  ];
  final appKeywords = [
    'app', 'ios', 'android', 'apk', 'application', 'client',
    'telegram', 'whatsapp', 'wechat', '微信', 'qq', '钉钉', '飞书',
    '抖音', 'tiktok', 'twitter', 'x', 'instagram', 'facebook',
    '美团', '饿了么', '淘宝', '京东', '拼多多', '小红书', '知乎',
  ];
  final websiteKeywords = [
    'web', 'site', 'online', 'portal', 'forum', 'blog', 'wiki',
    'github', 'gitlab', 'gmail', 'outlook', 'mail', 'email',
    'cloud', 'drive', '网盘', '邮箱', '论坛', '博客',
  ];

  if (bankCardKeywords.any(combined.contains)) {
    return PasswordCategoryId.bankCard;
  }
  if (financeKeywords.any(combined.contains)) {
    return PasswordCategoryId.finance;
  }
  if (url.startsWith('http://') ||
      url.startsWith('https://') ||
      websiteKeywords.any(combined.contains)) {
    return PasswordCategoryId.website;
  }
  if (appKeywords.any(combined.contains)) {
    return PasswordCategoryId.app;
  }
  return PasswordCategoryId.other;
}

/// Ensures the default category groups exist at the root of [file].
/// Existing groups with matching names (case-insensitive) are reused.
Map<PasswordCategoryId, KdbxGroup> ensureDefaultCategoryGroups(KdbxFile file) {
  final root = file.body.rootGroup;
  final groupsByLowerName = <String, KdbxGroup>{};
  for (final group in root.groups) {
    final name = group.name.get()?.toLowerCase();
    if (name != null && name.isNotEmpty) {
      groupsByLowerName[name] = group;
    }
  }

  final result = <PasswordCategoryId, KdbxGroup>{};
  for (final category in _categories) {
    if (category.id == PasswordCategoryId.all) {
      continue;
    }
    final lowerName = category.defaultName.toLowerCase();
    final existing = groupsByLowerName[lowerName];
    if (existing != null) {
      result[category.id] = existing;
    } else {
      final created = file.createGroup(
        parent: root,
        name: category.defaultName,
      );
      groupsByLowerName[lowerName] = created;
      result[category.id] = created;
    }
  }
  return result;
}

/// Organizes root-level entries of [file] into the default category groups.
/// Groups are created if they do not exist. Entries already in a category
/// group are left untouched.
int organizeRootEntriesByCategory(KdbxFile file) {
  final groups = ensureDefaultCategoryGroups(file);
  var moved = 0;
  for (final entry in file.body.rootGroup.entries.toList()) {
    if (entry.isInRecycleBin()) {
      continue;
    }
    final category = classifyEntry(entry);
    if (category == PasswordCategoryId.all) {
      continue;
    }
    final target = groups[category];
    if (target != null && entry.parent != target) {
      file.move(entry, target);
      moved++;
    }
  }
  return moved;
}

/// Classifies [entry] and moves it into the matching default category group
/// when its current parent is the root group or already a category group.
/// Custom groups are left untouched so the user can override classification.
void classifyEntryIntoCategoryGroup(KdbxEntry entry) {
  final file = entry.file;
  final groups = ensureDefaultCategoryGroups(file);
  final category = classifyEntry(entry);
  if (category == PasswordCategoryId.all) {
    return;
  }
  final target = groups[category];
  if (target == null || entry.parent == target) {
    return;
  }
  final parentName = entry.parent?.name.get()?.toLowerCase() ?? '';
  final isInCategoryGroup = _categories.any(
    (c) =>
        c.id != PasswordCategoryId.all &&
        c.defaultName.toLowerCase() == parentName,
  );
  if (entry.parent == file.body.rootGroup || isInCategoryGroup) {
    file.move(entry, target);
  }
}
