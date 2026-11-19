// About: version, updates, support and the developer credits.
part of 'settings_screen.dart';

// ---------------------------------------------------------------------------
// About
// ---------------------------------------------------------------------------

class AboutSettingsScreen extends StatefulWidget {
  const AboutSettingsScreen({super.key});

  @override
  State<AboutSettingsScreen> createState() => _AboutSettingsScreenState();
}

class _AboutSettingsScreenState extends State<AboutSettingsScreen> {
  static const String _websiteUrl = 'https://motionwork-tali.top';
  static const String _githubUrl = 'https://github.com/shahinrezasifat1999';
  static const String _facebookUrl =
      'https://www.facebook.com/Shahin.Reza.Sifat1997/';
  static const String _youtubeUrl =
      'https://www.youtube.com/@SHAHINREZASIFAT2025';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _push(Widget screen) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: settingsAppBar(context.l10n.about),
      body: ListView(
        padding: const EdgeInsets.only(top: 24, bottom: 30),
        children: [
          const _ProfileCard(),
          const SizedBox(height: 24),
          // Developer card
          SettingsCard(
            children: [
              SettingsTile(
                autofocus: true,
                icon: Icons.person_rounded,
                title: 'Developer',
                subtitle: 'S. M. Shahin Reza Sifat · Motion Work',
                onTap: () => _push(const DeveloperScreen()),
              ),
            ],
          ),
          SettingsSectionLabel(context.l10n.social, muted: true),
          SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.language_rounded,
                title: context.l10n.website,
                subtitle: 'motionwork-tali.top',
                onTap: () => _open(_websiteUrl),
              ),
              SettingsTile(
                icon: Icons.code_rounded,
                title: context.l10n.github,
                subtitle: 'github.com/shahinrezasifat1999',
                onTap: () => _open(_githubUrl),
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
          SettingsSectionLabel(context.l10n.appSection, muted: true),
          SettingsCard(
            children: [
              SettingsTile(
                icon: Icons.help_outline_rounded,
                title: context.l10n.howItWorks,
                subtitle: context.l10n.howItWorksSubtitle,
                onTap: () => _push(const HowItWorksScreen()),
              ),
              SettingsTile(
                icon: Icons.favorite_border_rounded,
                title: context.l10n.supportTheApp,
                subtitle: context.l10n.buyMeACoffee,
                onTap: () => _push(const DonateScreen()),
              ),
              if (sl.isRegistered<AppMode>() &&
                  sl<AppMode>().isTv &&
                  kExoSpikeEnabled)
                SettingsTile(
                  icon: Icons.speed_rounded,
                  title: context.l10n.exoplayerSpikeDev,
                  subtitle: context.l10n.sp0TestSurfaceViewPlaybackSmoothness,
                  onTap: () => _push(const TvExoSpikeScreen()),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '© ${DateTime.now().year}  $kAppName',
              style: AppText.caption.copyWith(
                color: AppColors.textTertiary,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The app header: the clean logo mark, name and version floating on the page
/// (no grey box), then the lead-developer card.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Image.asset(
          'assets/icon/app_icon.png',
          height: 96,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
        Image.asset(
          'assets/icon/wordmark.png',
          height: 38,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 6),
        Text(
          'v$kAppVersion',
          style: AppText.caption.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 20),
        const _DeveloperRow(),
      ],
    );
  }
}

/// The "Developer" row inside the profile card.
class _DeveloperRow extends StatelessWidget {
  const _DeveloperRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const DeveloperScreen()),
          ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.settingsCard,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: 'https://github.com/shahinrezasifat1999.png',
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      width: 46,
                      height: 46,
                      color: AppColors.surface2,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    errorWidget: (_, _, _) => Container(
                      width: 46,
                      height: 46,
                      color: AppColors.surface2,
                      child: Icon(
                        Icons.person_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'S. M. Shahin Reza Sifat',
                        style: AppText.headline.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Software Developer & Founder of Motion Work',
                        style: AppText.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
