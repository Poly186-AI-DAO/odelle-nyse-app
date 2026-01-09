enum SocialAuthProvider {
  google,
  facebook,
  windows,
  linkedin,
  shopify,
  tiktok,
  notion,
  slack,
  x,
}

extension SocialAuthProviderX on SocialAuthProvider {
  String get headerValue => name;

  String get displayLabel {
    switch (this) {
      case SocialAuthProvider.google:
        return 'Google';
      case SocialAuthProvider.facebook:
        return 'Facebook';
      case SocialAuthProvider.windows:
        return 'Windows';
      case SocialAuthProvider.linkedin:
        return 'LinkedIn';
      case SocialAuthProvider.shopify:
        return 'Shopify';
      case SocialAuthProvider.tiktok:
        return 'TikTok';
      case SocialAuthProvider.notion:
        return 'Notion';
      case SocialAuthProvider.slack:
        return 'Slack';
      case SocialAuthProvider.x:
        return 'X';
    }
  }
}
