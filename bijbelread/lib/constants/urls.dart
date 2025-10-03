class AppUrls {
  // API Endpoints
  static const String bibleApiBase = 'https://www.online-bijbel.nl/api.php';

  // Bible API endpoints
  static const String booksEndpoint = '$bibleApiBase?action=books';
  static String chaptersEndpoint(String bookId) => '$bibleApiBase?book=$bookId';
  static String versesEndpoint(String bookId, int chapter) => '$bibleApiBase?book=$bookId&chapter=$chapter';
  static String searchEndpoint(String query) => '$bibleApiBase?search=$query';

  // Social Media
  static const String contactEmail = 'thomasnowprod@proton.me';
  static const String mastodonUrl = 'https://toot.community/@bijbelread';
  static const String kweblerUrl = 'https://kwebler.com/profile/bijbelread';
  static const String discordUrl = 'https://discord.gg/ADbhWr4UnK';
  static const String signalUrl = 'https://signal.group/#CjQKILlX0njMt_UqlaFrlk_ePLdUkNel9p4w_CHvgkKbAoHYEhCZIoaUq_8G36p1w-Xpq1xq';
  static const String pixelfedUrl = 'https://pixelfed.social/@bijbelread';

  // App links
  static const String appWebsite = 'https://bijbelread.app';
  static const String privacyPolicy = 'https://bijbelread.app/privacy';
  static const String termsOfService = 'https://bijbelread.app/terms';
}