import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:kdbx/kdbx.dart';

class BrandIcon {
  const BrandIcon({required this.icon, required this.color});

  final FaIconData icon;
  final Color color;
}

final _domainBrandMap = <String, BrandIcon>{
  'github.com': const BrandIcon(icon: FontAwesomeIcons.github, color: Color(0xFF181717)),
  'gitlab.com': const BrandIcon(icon: FontAwesomeIcons.gitlab, color: Color(0xFFFC6D26)),
  'bitbucket.org': const BrandIcon(icon: FontAwesomeIcons.bitbucket, color: Color(0xFF2684FF)),
  'google.com': const BrandIcon(icon: FontAwesomeIcons.google, color: Color(0xFF4285F4)),
  'gmail.com': const BrandIcon(icon: FontAwesomeIcons.google, color: Color(0xFF4285F4)),
  'mail.google.com': const BrandIcon(icon: FontAwesomeIcons.google, color: Color(0xFF4285F4)),
  'youtube.com': const BrandIcon(icon: FontAwesomeIcons.youtube, color: Color(0xFFFF0000)),
  'facebook.com': const BrandIcon(icon: FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
  'instagram.com': const BrandIcon(icon: FontAwesomeIcons.instagram, color: Color(0xFFE4405F)),
  'twitter.com': const BrandIcon(icon: FontAwesomeIcons.twitter, color: Color(0xFF000000)),
  'x.com': const BrandIcon(icon: FontAwesomeIcons.xTwitter, color: Color(0xFF000000)),
  'linkedin.com': const BrandIcon(icon: FontAwesomeIcons.linkedin, color: Color(0xFF0A66C2)),
  'reddit.com': const BrandIcon(icon: FontAwesomeIcons.reddit, color: Color(0xFFFF4500)),
  'twitch.tv': const BrandIcon(icon: FontAwesomeIcons.twitch, color: Color(0xFF9146FF)),
  'spotify.com': const BrandIcon(icon: FontAwesomeIcons.spotify, color: Color(0xFF1DB954)),
  'apple.com': const BrandIcon(icon: FontAwesomeIcons.apple, color: Color(0xFF000000)),
  'icloud.com': const BrandIcon(icon: FontAwesomeIcons.apple, color: Color(0xFF000000)),
  'microsoft.com': const BrandIcon(icon: FontAwesomeIcons.microsoft, color: Color(0xFF00A4EF)),
  'outlook.com': const BrandIcon(icon: FontAwesomeIcons.microsoft, color: Color(0xFF00A4EF)),
  'live.com': const BrandIcon(icon: FontAwesomeIcons.microsoft, color: Color(0xFF00A4EF)),
  'amazon.com': const BrandIcon(icon: FontAwesomeIcons.amazon, color: Color(0xFFFF9900)),
  'amazon.cn': const BrandIcon(icon: FontAwesomeIcons.amazon, color: Color(0xFFFF9900)),
  'amazon.co.jp': const BrandIcon(icon: FontAwesomeIcons.amazon, color: Color(0xFFFF9900)),
  'paypal.com': const BrandIcon(icon: FontAwesomeIcons.paypal, color: Color(0xFF003087)),
  'stripe.com': const BrandIcon(icon: FontAwesomeIcons.stripe, color: Color(0xFF635BFF)),
  'slack.com': const BrandIcon(icon: FontAwesomeIcons.slack, color: Color(0xFF4A154B)),
  'discord.com': const BrandIcon(icon: FontAwesomeIcons.discord, color: Color(0xFF5865F2)),
  'telegram.org': const BrandIcon(icon: FontAwesomeIcons.telegram, color: Color(0xFF26A5E4)),
  'whatsapp.com': const BrandIcon(icon: FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
  'weibo.com': const BrandIcon(icon: FontAwesomeIcons.weibo, color: Color(0xFFE6162D)),
  'taobao.com': const BrandIcon(icon: FontAwesomeIcons.cartShopping, color: Color(0xFFFF5000)),
  'alipay.com': const BrandIcon(icon: FontAwesomeIcons.alipay, color: Color(0xFF1677FF)),
  'wechat.com': const BrandIcon(icon: FontAwesomeIcons.weixin, color: Color(0xFF07C160)),
  'qq.com': const BrandIcon(icon: FontAwesomeIcons.qq, color: Color(0xFF12B7F5)),
  'bilibili.com': const BrandIcon(icon: FontAwesomeIcons.play, color: Color(0xFFFB7299)),
  'tiktok.com': const BrandIcon(icon: FontAwesomeIcons.music, color: Color(0xFF000000)),
  'douyin.com': const BrandIcon(icon: FontAwesomeIcons.music, color: Color(0xFF000000)),
  'netflix.com': const BrandIcon(icon: FontAwesomeIcons.film, color: Color(0xFFE50914)),
  'dropbox.com': const BrandIcon(icon: FontAwesomeIcons.dropbox, color: Color(0xFF0061FF)),
  'stackoverflow.com': const BrandIcon(icon: FontAwesomeIcons.stackOverflow, color: Color(0xFFF48024)),
  'medium.com': const BrandIcon(icon: FontAwesomeIcons.medium, color: Color(0xFF000000)),
  'wordpress.com': const BrandIcon(icon: FontAwesomeIcons.wordpress, color: Color(0xFF21759B)),
  'wordpress.org': const BrandIcon(icon: FontAwesomeIcons.wordpress, color: Color(0xFF21759B)),
  'cloudflare.com': const BrandIcon(icon: FontAwesomeIcons.cloudflare, color: Color(0xFFF38020)),
  'digitalocean.com': const BrandIcon(icon: FontAwesomeIcons.digitalOcean, color: Color(0xFF0080FF)),
  'aws.amazon.com': const BrandIcon(icon: FontAwesomeIcons.aws, color: Color(0xFF232F3E)),
  'docker.com': const BrandIcon(icon: FontAwesomeIcons.docker, color: Color(0xFF2496ED)),
  'npmjs.com': const BrandIcon(icon: FontAwesomeIcons.npm, color: Color(0xFFCB3837)),
  'figma.com': const BrandIcon(icon: FontAwesomeIcons.figma, color: Color(0xFFF24E1E)),
  'dribbble.com': const BrandIcon(icon: FontAwesomeIcons.dribbble, color: Color(0xFFEA4C89)),
  'behance.net': const BrandIcon(icon: FontAwesomeIcons.behance, color: Color(0xFF1769FF)),
  'pinterest.com': const BrandIcon(icon: FontAwesomeIcons.pinterest, color: Color(0xFFE60023)),
  'snapchat.com': const BrandIcon(icon: FontAwesomeIcons.snapchat, color: Color(0xFFFFFC00)),
  'skype.com': const BrandIcon(icon: FontAwesomeIcons.skype, color: Color(0xFF00AFF0)),
  'zoom.us': const BrandIcon(icon: FontAwesomeIcons.video, color: Color(0xFF2D8CFF)),
  'wikipedia.org': const BrandIcon(icon: FontAwesomeIcons.wikipediaW, color: Color(0xFF000000)),
};

final _titleBrandMap = <String, BrandIcon>{
  'github': const BrandIcon(icon: FontAwesomeIcons.github, color: Color(0xFF181717)),
  'google': const BrandIcon(icon: FontAwesomeIcons.google, color: Color(0xFF4285F4)),
  'gmail': const BrandIcon(icon: FontAwesomeIcons.google, color: Color(0xFF4285F4)),
  'youtube': const BrandIcon(icon: FontAwesomeIcons.youtube, color: Color(0xFFFF0000)),
  'facebook': const BrandIcon(icon: FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
  'instagram': const BrandIcon(icon: FontAwesomeIcons.instagram, color: Color(0xFFE4405F)),
  'twitter': const BrandIcon(icon: FontAwesomeIcons.twitter, color: Color(0xFF000000)),
  'linkedin': const BrandIcon(icon: FontAwesomeIcons.linkedin, color: Color(0xFF0A66C2)),
  'reddit': const BrandIcon(icon: FontAwesomeIcons.reddit, color: Color(0xFFFF4500)),
  'spotify': const BrandIcon(icon: FontAwesomeIcons.spotify, color: Color(0xFF1DB954)),
  'apple': const BrandIcon(icon: FontAwesomeIcons.apple, color: Color(0xFF000000)),
  'microsoft': const BrandIcon(icon: FontAwesomeIcons.microsoft, color: Color(0xFF00A4EF)),
  'outlook': const BrandIcon(icon: FontAwesomeIcons.microsoft, color: Color(0xFF00A4EF)),
  'amazon': const BrandIcon(icon: FontAwesomeIcons.amazon, color: Color(0xFFFF9900)),
  'paypal': const BrandIcon(icon: FontAwesomeIcons.paypal, color: Color(0xFF003087)),
  'slack': const BrandIcon(icon: FontAwesomeIcons.slack, color: Color(0xFF4A154B)),
  'discord': const BrandIcon(icon: FontAwesomeIcons.discord, color: Color(0xFF5865F2)),
  'telegram': const BrandIcon(icon: FontAwesomeIcons.telegram, color: Color(0xFF26A5E4)),
  'whatsapp': const BrandIcon(icon: FontAwesomeIcons.whatsapp, color: Color(0xFF25D366)),
  'wechat': const BrandIcon(icon: FontAwesomeIcons.weixin, color: Color(0xFF07C160)),
  '微信': const BrandIcon(icon: FontAwesomeIcons.weixin, color: Color(0xFF07C160)),
  'alipay': const BrandIcon(icon: FontAwesomeIcons.alipay, color: Color(0xFF1677FF)),
  '支付宝': const BrandIcon(icon: FontAwesomeIcons.alipay, color: Color(0xFF1677FF)),
  'taobao': const BrandIcon(icon: FontAwesomeIcons.cartShopping, color: Color(0xFFFF5000)),
  '淘宝': const BrandIcon(icon: FontAwesomeIcons.cartShopping, color: Color(0xFFFF5000)),
  'qq': const BrandIcon(icon: FontAwesomeIcons.qq, color: Color(0xFF12B7F5)),
  'bilibili': const BrandIcon(icon: FontAwesomeIcons.play, color: Color(0xFFFB7299)),
  '哔哩哔哩': const BrandIcon(icon: FontAwesomeIcons.play, color: Color(0xFFFB7299)),
  'tiktok': const BrandIcon(icon: FontAwesomeIcons.music, color: Color(0xFF000000)),
  '抖音': const BrandIcon(icon: FontAwesomeIcons.music, color: Color(0xFF000000)),
  'netflix': const BrandIcon(icon: FontAwesomeIcons.film, color: Color(0xFFE50914)),
  'dropbox': const BrandIcon(icon: FontAwesomeIcons.dropbox, color: Color(0xFF0061FF)),
  'stackoverflow': const BrandIcon(icon: FontAwesomeIcons.stackOverflow, color: Color(0xFFF48024)),
  'cloudflare': const BrandIcon(icon: FontAwesomeIcons.cloudflare, color: Color(0xFFF38020)),
  'aws': const BrandIcon(icon: FontAwesomeIcons.aws, color: Color(0xFF232F3E)),
  'docker': const BrandIcon(icon: FontAwesomeIcons.docker, color: Color(0xFF2496ED)),
  'npm': const BrandIcon(icon: FontAwesomeIcons.npm, color: Color(0xFFCB3837)),
  'figma': const BrandIcon(icon: FontAwesomeIcons.figma, color: Color(0xFFF24E1E)),
  'dribbble': const BrandIcon(icon: FontAwesomeIcons.dribbble, color: Color(0xFFEA4C89)),
  'pinterest': const BrandIcon(icon: FontAwesomeIcons.pinterest, color: Color(0xFFE60023)),
  'zoom': const BrandIcon(icon: FontAwesomeIcons.video, color: Color(0xFF2D8CFF)),
  'wikipedia': const BrandIcon(icon: FontAwesomeIcons.wikipediaW, color: Color(0xFF000000)),
};

BrandIcon? brandIconForEntry(KdbxEntry entry) {
  final url = entry.getString(KdbxKeyCommon.URL)?.getText()?.toLowerCase() ?? '';
  final title = entry.getString(KdbxKeyCommon.TITLE)?.getText()?.toLowerCase() ?? '';

  // Try matching by domain first.
  for (final entry in _domainBrandMap.entries) {
    if (url.contains(entry.key)) {
      return entry.value;
    }
  }

  // Fall back to title keywords.
  for (final entry in _titleBrandMap.entries) {
    if (title.contains(entry.key)) {
      return entry.value;
    }
  }

  return null;
}
