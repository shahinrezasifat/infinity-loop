import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui/settings_widgets.dart';

/// Developer profile and contact screen for S. M. Shahin Reza Sifat.
class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  static const String _avatarUrl =
      'https://github.com/shahinrezasifat1999.png';
  static const String _websiteUrl = 'https://motionwork-tali.top';
  static const String _githubUrl = 'https://github.com/shahinrezasifat1999';
  static const String _emailUrl = 'mailto:motionworkofficial@gmail.com';
  static const String _whatsappUrl = 'https://wa.me/8801766522499';
  static const String _facebookUrl =
      'https://www.facebook.com/Shahin.Reza.Sifat1997/';
  static const String _youtubeUrl =
      'https://www.youtube.com/@SHAHINREZASIFAT2025';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: settingsAppBar('Developer'),
      body: ListView(
        padding: const EdgeInsets.only(top: 16, bottom: 40),
        children: [
          // ── Developer Profile Card ───────────────────────────────────────
          Center(
            child: Column(
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: _avatarUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        color: AppColors.surface2,
                        child: const Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        color: AppColors.surface2,
                        child: Center(
                          child: Icon(
                            Icons.person_rounded,
                            size: 50,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'S. M. Shahin Reza Sifat',
                  style: AppText.headline.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Text(
                    'Software Developer & Founder of Motion Work',
                    style: AppText.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                subtitle: 'motionwork-tali.top',
                onTap: () => _open(_websiteUrl),
              ),
              SettingsTile(
                icon: Icons.code_rounded,
                title: 'GitHub',
                subtitle: 'github.com/shahinrezasifat1999',
                onTap: () => _open(_githubUrl),
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
    );
  }
}
