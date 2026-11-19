import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui/app_toast.dart';
import '../../core/ui/settings_widgets.dart';
import 'developer_service.dart';

/// Developer profile and contact screen for S. M. Shahin Reza Sifat.
/// Connected live to GitHub API for real-time profile and avatar updates.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({super.key});

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  late GitHubDevProfile _profile;
  bool _isRefreshing = false;

  static const String _defaultWebsiteUrl = 'https://motionwork-tali.top';
  static const String _emailUrl = 'mailto:motionworkofficial@gmail.com';
  static const String _whatsappUrl = 'https://wa.me/8801766522499';
  static const String _facebookUrl =
      'https://www.facebook.com/Shahin.Reza.Sifat1997/';
  static const String _youtubeUrl =
      'https://www.youtube.com/@SHAHINREZASIFAT2025';

  @override
  void initState() {
    super.initState();
    // Instantly display cached profile with zero latency
    _profile = DeveloperProfileService.current.value;
    // Immediately fetch fresh profile from GitHub API
    _syncGitHubProfile();
  }

  Future<void> _syncGitHubProfile({bool userInitiated = false}) async {
    if (!mounted) return;
    setState(() => _isRefreshing = true);
    final fresh = await DeveloperProfileService.fetchProfile(
      forceEvict: userInitiated,
    );
    if (!mounted) return;
    setState(() {
      _profile = fresh;
      _isRefreshing = false;
    });
    if (userInitiated) {
      showAppToast(context, '✓ GitHub profile synced');
    }
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppText.headline.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppText.caption.copyWith(
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final website = _profile.blog.isNotEmpty ? _profile.blog : _defaultWebsiteUrl;
    final websiteDisplay = website.replaceFirst(RegExp(r'^https?://'), '').replaceAll(RegExp(r'/+$'), '');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: settingsAppBar(
        'Developer',
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white70),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            tooltip: 'Sync with GitHub',
            onPressed:
                _isRefreshing ? null : () => _syncGitHubProfile(userInitiated: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _syncGitHubProfile(userInitiated: true),
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        child: ListView(
          padding: const EdgeInsets.only(top: 16, bottom: 40),
          children: [
            // ── Developer Profile Card ───────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 108,
                        height: 108,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.accent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: _profile.dynamicAvatarUrl,
                            cacheKey: _profile.cacheKey,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Container(
                              color: AppColors.surface2,
                              child: const Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                            errorWidget: (_, _, _) => Container(
                              color: AppColors.surface2,
                              child: Center(
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 52,
                                  color: AppColors.accent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // GitHub indicator icon badge
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF181717),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.code_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _profile.name,
                    style: AppText.headline.copyWith(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _open(_profile.htmlUrl),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '@${_profile.username}',
                          style: AppText.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.open_in_new_rounded,
                          size: 12,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _profile.bio,
                        style: AppText.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Live GitHub Stats Row ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _statCard(
                          label: 'Repositories',
                          value: '${_profile.publicRepos}',
                          icon: Icons.folder_outlined,
                          onTap: () =>
                              _open('${_profile.htmlUrl}?tab=repositories'),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          label: 'Followers',
                          value: '${_profile.followers}',
                          icon: Icons.people_outline_rounded,
                          onTap: () =>
                              _open('${_profile.htmlUrl}?tab=followers'),
                        ),
                        const SizedBox(width: 10),
                        _statCard(
                          label: 'Following',
                          value: '${_profile.following}',
                          icon: Icons.person_add_alt_1_outlined,
                          onTap: () =>
                              _open('${_profile.htmlUrl}?tab=following'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),
                  // Live status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Live connected with GitHub',
                        style: AppText.caption.copyWith(
                          color: const Color(0xFF10B981),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Connect & Social Section ─────────────────────────────────────
            SettingsSectionLabel('Contact & Social', muted: true),
            SettingsCard(
              children: [
                SettingsTile(
                  icon: Icons.language_rounded,
                  title: 'Website',
                  subtitle: websiteDisplay,
                  onTap: () => _open(website),
                ),
                SettingsTile(
                  icon: Icons.code_rounded,
                  title: 'GitHub',
                  subtitle: 'github.com/${_profile.username}',
                  onTap: () => _open(_profile.htmlUrl),
                ),
                SettingsTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Email',
                  subtitle: 'motionworkofficial@gmail.com',
                  onTap: () => _open(_emailUrl),
                ),
                SettingsTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'WhatsApp',
                  subtitle: '+8801766522499',
                  onTap: () => _open(_whatsappUrl),
                ),
                SettingsTile(
                  icon: Icons.facebook_rounded,
                  title: 'Facebook',
                  subtitle: 'Shahin.Reza.Sifat1997',
                  onTap: () => _open(_facebookUrl),
                ),
                SettingsTile(
                  icon: Icons.play_circle_outline_rounded,
                  title: 'YouTube',
                  subtitle: '@SHAHINREZASIFAT2025',
                  onTap: () => _open(_youtubeUrl),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Center(
              child: Text(
                'Motion Work · All Rights Reserved',
                style: AppText.caption.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
