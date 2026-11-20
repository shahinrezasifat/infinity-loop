/// Public Appwrite configuration. These are NOT secrets — the project id and
/// endpoint ship in every Appwrite client app. Auth uses email/password
/// sessions; the server API key is never embedded here.
class Environment {
  static const String appwriteProjectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
  );
  static const String appwriteProjectName = 'Infinity Loop';
  static const String appwritePublicEndpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
  );

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );
  static bool get cloudConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String siteBaseUrl = String.fromEnvironment(
    'INFINITY_LOOP_SITE_URL',
  );
  static const String passwordResetUrl = siteBaseUrl;

  /// Share links point here. The page opens the app if installed (via the
  /// [openLinkScheme] scheme below), otherwise offers the download. Its domain
  /// must be an Appwrite Web platform (already added for the reset page).
  static String get siteOpenUrl => siteBaseUrl.isEmpty
      ? '$openLinkScheme://$openLinkHost'
      : '$siteBaseUrl/open/';

  /// TV pairing page on the website. Used when someone opens a shared/https
  /// pair link in a browser; the page can hand off to the app via
  /// `infinityloop://pair`. App-facing TV QRs encode the deeplink directly.
  static String get sitePairUrl => siteBaseUrl.isEmpty
      ? '$openLinkScheme://$pairLinkHost'
      : '$siteBaseUrl/pair/';

  /// The "open" page redirects to `infinityloop://open?…`; an installed app catches
  /// it (see [OpenLinkService] + the Android manifest intent-filter).
  static const String openLinkScheme = trackerRedirectScheme; // 'infinityloop'
  static const String openLinkHost = 'open';
  static const String pairLinkHost = 'pair';

  // Provisioned backend ids (see docs / setup).
  static const String databaseId = 'main';
  static const String mylistCollectionId = 'mylist';
  static const String historyCollectionId = 'history';
  static const String watchRoomsCollectionId = 'watch_rooms';
  static const String roomParticipantsCollectionId = 'room_participants';
  static const String roomMessagesCollectionId = 'room_messages';
  static const String avatarsBucketId = 'avatars';
  static const String backupsCollectionId = 'backups';

  // ── Tracker OAuth ──────────────────────────────────────────────────────────
  // All redirects share the infinityloop:// scheme; each has its own host with a
  // matching Android intent-filter. Client secrets are embedded where the
  // provider's token exchange requires it (MAL = PKCE, no secret; Simkl needs
  // one) — standard for these APIs and low-risk.
  static const String trackerRedirectScheme = 'infinityloop';

  // AniList — implicit grant (token in URL fragment, 1-year, no secret).
  static const String anilistClientId = String.fromEnvironment(
    'ANILIST_CLIENT_ID',
  );
  static const String anilistRedirectHost = 'anilist-auth';
  static String get anilistRedirectUri =>
      '$trackerRedirectScheme://$anilistRedirectHost';

  // MyAnimeList — OAuth2 PKCE (plain), no client secret.
  static const String malClientId = String.fromEnvironment('MAL_CLIENT_ID');
  static const String malRedirectHost = 'mal-auth';
  static String get malRedirectUri =>
      '$trackerRedirectScheme://$malRedirectHost';

  // Simkl wants these on EVERY request (url params + a real User-Agent), or
  // the call is invisible in their debug log and they can't help when
  // something breaks. See https://api.simkl.org/conventions/headers.
  static const String simklAppName = 'infinityloop';
  static const String simklApiHost = 'api.simkl.com';
  static const String simklDataHost = 'data.simkl.in';

  // Simkl — OAuth2 authorization-code (needs the secret to exchange the code).
  static const String simklClientId = String.fromEnvironment('SIMKL_CLIENT_ID');
  static const String simklClientSecret = String.fromEnvironment(
    'SIMKL_CLIENT_SECRET',
  );
  static const String simklRedirectHost = 'simkl-auth';
  static String get simklRedirectUri =>
      '$trackerRedirectScheme://$simklRedirectHost';

  // Back-compat alias (older AniList code referenced this name).
  // ── MangaBaka ────────────────────────────────────────────────────────────
  //
  // Manga/manhwa/manhua only — no anime list, which is why `supportsReading`
  // is the one thing it answers true to.
  //
  // A PUBLIC OAuth client: no secret, PKCE (S256) instead, which is the right
  // shape for an installed app — anything shipped in the APK can be extracted.
  // Endpoints come from https://mangabaka.org/.well-known/openid-configuration
  // (the `.org` host; `api.mangabaka.org/.well-known/*` is 404). MangaBaka's
  // own API docs mention neither OAuth nor tokens, so prefer the discovery
  // document over the docs if they ever disagree.
  static const String mangabakaClientId = String.fromEnvironment(
    'MANGABAKA_CLIENT_ID',
  );
  static const String mangabakaRedirectHost = 'mangabaka-auth';
  static String get mangabakaRedirectUri =>
      '$trackerRedirectScheme://$mangabakaRedirectHost';
  static const String mangabakaAuthorizeUrl =
      'https://mangabaka.org/auth/oauth2/authorize';
  static const String mangabakaTokenUrl =
      'https://mangabaka.org/auth/oauth2/token';
  static const String mangabakaRevokeUrl =
      'https://mangabaka.org/auth/oauth2/revoke';
  static const String mangabakaApi = 'https://api.mangabaka.org';

  /// `library.write` is an official scope — third-party writes are supported,
  /// not a workaround. `offline_access` is what returns a refresh token.
  /// `openid` is required by `/v1/my/profile`: with the other four granted it
  /// still answered `BAD_REQUEST: Missing required scope`, which is the OIDC
  /// identity scope missing rather than any library permission.
  static const String mangabakaScopes =
      'openid profile library.read library.write offline_access';

  static const String anilistRedirectScheme = trackerRedirectScheme;
}
