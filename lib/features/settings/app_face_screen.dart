import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart' show HapticFeedback;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/app_icon/app_icon_service.dart';
import '../../core/app_mode.dart';
import '../../core/di/injector.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui/app_dialog.dart';
import '../../core/ui/app_toast.dart';
import '../../core/ui/banner_style.dart';
import '../../core/ui/settings_widgets.dart';
import '../../core/ui/splash_style.dart';
import '../../l10n/l10n.dart';

/// The three pickers that decide what the app LOOKS like before you are even
/// in it: the launcher icon, the splash, and the Home banner.
class AppFaceScreen extends StatefulWidget {
  const AppFaceScreen({super.key});

  @override
  State<AppFaceScreen> createState() => _AppFaceScreenState();
}

class _AppFaceScreenState extends State<AppFaceScreen> {
  final _icons = AppIconService();

  late String _stagedIconId;
  String? _stagedCustomIconPath;

  late String _stagedSplashId;
  String? _stagedCustomSplashPath;

  late String _stagedBannerId;
  bool _saving = false;
  bool _saved = false;

  /// What PackageManager actually has enabled, once [_reconcileIcon] has asked.
  String? _iconActual;

  @override
  void initState() {
    super.initState();
    _stagedIconId = _icons.selectedId;
    _stagedCustomIconPath = _icons.customIconPath;

    _stagedSplashId = SplashStyle.selectedId;
    _stagedCustomSplashPath = SplashStyle.customImagePath;

    _stagedBannerId = BannerStyle.current.value;

    _reconcileIcon();
  }

  Future<void> _reconcileIcon() async {
    final id = await _icons.reconciledId();
    if (mounted && id != _iconActual) {
      setState(() {
        _iconActual = id;
        if (_stagedIconId != 'custom') {
          _stagedIconId = id;
        }
      });
    }
  }

  Future<void> _pickCustomImage({required bool forSplash}) async {
    try {
      final picker = ImagePicker();
      final x = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 90,
      );
      if (x == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final prefix = forSplash ? 'splash' : 'app_icon';
      final ext = x.path.contains('.') ? x.path.split('.').last : 'png';
      final targetPath =
          '${appDir.path}/${prefix}_custom_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final savedFile = await File(x.path).copy(targetPath);

      if (mounted) {
        setState(() {
          if (forSplash) {
            _stagedCustomSplashPath = savedFile.path;
            _stagedSplashId = 'custom';
          } else {
            _stagedCustomIconPath = savedFile.path;
            _stagedIconId = 'custom';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _saveAll() async {
    // If an icon change needs confirmation, ask before starting the save animation
    bool noticePrompted = false;
    if (_icons.supported && _stagedIconId != 'custom') {
      final current = _iconActual ?? _icons.selectedId;
      if (_stagedIconId != current) {
        if (!mounted) return;
        final ok = await AppDialog.confirm(
          context,
          title: 'Change App Icon?',
          message:
              'Switching launcher icon requires updating Android launcher settings. The app may reload.',
          confirmLabel: 'Apply Icon',
        );
        if (ok != true) return;
        noticePrompted = true;
      }
    }

    setState(() {
      _saving = true;
      _saved = false;
    });

    try {
      // 1. Home banner
      await BannerStyle.select(_stagedBannerId);

      // 2. Splash
      if (_stagedSplashId == 'custom') {
        if (_stagedCustomSplashPath != null) {
          await SplashStyle.setCustomImagePath(_stagedCustomSplashPath);
          await SplashStyle.select('custom');
        }
      } else {
        await SplashStyle.select(_stagedSplashId);
      }

      // 3. App icon
      if (_icons.supported) {
        if (_stagedIconId == 'custom') {
          if (_stagedCustomIconPath != null) {
            await _icons.setCustomIconPath(_stagedCustomIconPath);
            await _icons.selectCustom();
            await _icons.pinCustomShortcut(_stagedCustomIconPath!);
          }
        } else if (noticePrompted) {
          await _icons.select(_stagedIconId);
        }
      }

      // Small natural pause so the user clearly sees the saving in progress
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        HapticFeedback.mediumImpact();
        showAppToast(
          context,
          noticePrompted
              ? 'Settings saved! Launcher icon updated.'
              : 'Settings saved successfully!',
        );
        setState(() {
          _saving = false;
          _saved = true;
        });

        // Revert success label after 1.8s
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) {
            setState(() => _saved = false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, 'Error saving: $e');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: settingsAppBar('Icon, splash & banner'),
      body: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 24),
        children: [
          // ── App icon ──────────────────────────────────────────────────────
          if (_icons.supported) ...[
            SettingsSectionLabel(context.l10n.appIcon),
            _blurb(context.l10n.appIconBlurb),
            const SizedBox(height: 10),
            _iconPicker(),
          ],

          // ── Splash ────────────────────────────────────────────────────────
          SettingsSectionLabel(context.l10n.splashStyle),
          _blurb(context.l10n.splashStyleBlurb),
          const SizedBox(height: 10),
          _splashPicker(),

          // ── Home banner ───────────────────────────────────────────────────
          if (!sl<AppMode>().isTv) ...[
            SettingsSectionLabel('Home banner'),
            _blurb('How the featured title shows on Home.'),
            const SizedBox(height: 10),
            _bannerPicker(),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_saved
                            ? const Color(0xFF10B981)
                            : AppColors.accent)
                        .withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: (_saving || _saved) ? null : _saveAll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _saved
                      ? const Color(0xFF10B981)
                      : AppColors.accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _saved
                      ? const Color(0xFF10B981)
                      : AppColors.accent.withValues(alpha: 0.85),
                  disabledForegroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _saving
                      ? const Row(
                          key: ValueKey('saving'),
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Saving changes...',
                              style: TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        )
                      : _saved
                          ? const Row(
                              key: ValueKey('saved'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 22,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Settings Saved!',
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              key: ValueKey('idle'),
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Save Changes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _blurb(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
    child: Text(text, style: AppText.caption.copyWith(height: 1.35)),
  );

  Widget _iconPicker() {
    return SizedBox(
      height: 124,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        children: [
          // Presets
          for (final o in AppIconService.options) ...[
            _AppIconCard(
              label: o.label,
              assetPath: o.asset,
              selected: _stagedIconId == o.id,
              onTap: () => setState(() => _stagedIconId = o.id),
            ),
            const SizedBox(width: 10),
          ],

          // Custom uploaded icon if exists
          if (_stagedCustomIconPath != null) ...[
            _AppIconCard(
              label: 'Custom',
              filePath: _stagedCustomIconPath,
              selected: _stagedIconId == 'custom',
              onTap: () => setState(() => _stagedIconId = 'custom'),
              onDelete: () {
                setState(() {
                  _stagedCustomIconPath = null;
                  if (_stagedIconId == 'custom') {
                    _stagedIconId = AppIconService.defaultId;
                  }
                });
              },
            ),
            const SizedBox(width: 10),
          ],

          // Upload card
          _UploadCard(
            label: 'Upload Icon',
            onTap: () => _pickCustomImage(forSplash: false),
          ),
        ],
      ),
    );
  }

  Widget _splashPicker() {
    return SizedBox(
      height: 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        children: [
          // Presets
          for (final o in SplashStyle.options) ...[
            _SplashCard(
              id: o.id,
              label: o.label,
              selected: _stagedSplashId == o.id,
              onTap: () => setState(() => _stagedSplashId = o.id),
            ),
            const SizedBox(width: 10),
          ],

          // Custom uploaded splash if exists
          if (_stagedCustomSplashPath != null) ...[
            _SplashCard(
              id: 'custom',
              label: 'Custom',
              customPath: _stagedCustomSplashPath,
              selected: _stagedSplashId == 'custom',
              onTap: () => setState(() => _stagedSplashId = 'custom'),
              onDelete: () {
                setState(() {
                  _stagedCustomSplashPath = null;
                  if (_stagedSplashId == 'custom') {
                    _stagedSplashId = SplashStyle.defaultId;
                  }
                });
              },
            ),
            const SizedBox(width: 10),
          ],

          // Upload card
          _UploadCard(
            label: 'Upload Splash',
            onTap: () => _pickCustomImage(forSplash: true),
          ),
        ],
      ),
    );
  }

  Widget _bannerPicker() {
    return SizedBox(
      height: 146,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        clipBehavior: Clip.none,
        itemCount: BannerStyle.options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final o = BannerStyle.options[i];
          return _BannerStyleCard(
            option: o,
            selected: o.id == _stagedBannerId,
            onTap: () => setState(() => _stagedBannerId = o.id),
          );
        },
      ),
    );
  }
}

/// A launcher-icon choice: preview, name, and a tick when it's the active one.
class _AppIconCard extends StatelessWidget {
  const _AppIconCard({
    required this.label,
    required this.selected,
    required this.onTap,
    this.assetPath,
    this.filePath,
    this.onDelete,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? assetPath;
  final String? filePath;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (filePath != null) {
      final f = File(filePath!);
      imageWidget = f.existsSync()
          ? Image.file(f, fit: BoxFit.cover)
          : const Icon(Icons.broken_image_outlined, color: AppColors.textTertiary);
    } else if (assetPath != null) {
      imageWidget = Image.asset(assetPath!, fit: BoxFit.cover);
    } else {
      imageWidget = const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 92,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: selected ? AppColors.accent : AppColors.hairline,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: imageWidget,
                  ),
                ),
                if (onDelete != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One splash choice, previewing itself on a loop.
class _SplashCard extends StatefulWidget {
  const _SplashCard({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
    this.customPath,
    this.onDelete,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? customPath;
  final VoidCallback? onDelete;

  @override
  State<_SplashCard> createState() => _SplashCardState();
}

class _SplashCardState extends State<_SplashCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sel = widget.selected;
    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: 100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.bg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: sel ? AppColors.accent : AppColors.hairline,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) {
                      Widget img;
                      if (widget.id == 'bankai') {
                        img = Image.asset(
                          'assets/icon/app_icon.png',
                          width: 64,
                          height: 64,
                          fit: BoxFit.contain,
                        );
                      } else if (widget.id == 'custom' && widget.customPath != null) {
                        final f = File(widget.customPath!);
                        img = f.existsSync()
                            ? Image.file(f, width: 64, height: 64, fit: BoxFit.contain)
                            : const Icon(
                                Icons.broken_image_outlined,
                                color: AppColors.textTertiary,
                              );
                      } else {
                        img = Image.asset(
                          'assets/icon/wordmark.png',
                          width: 64,
                          fit: BoxFit.contain,
                        );
                      }
                      return Center(
                        child: Opacity(
                          opacity:
                              0.6 + 0.4 * math.sin(_c.value * 2 * math.pi).abs(),
                          child: img,
                        ),
                      );
                    },
                  ),
                ),
                if (widget.onDelete != null)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black87,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(3),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: sel ? AppColors.accent : AppColors.textSecondary,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An upload card that lets users pick an image from device gallery.
class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.hairline,
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.accent,
                    size: 26,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload',
                    style: AppText.caption.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One Home-banner option, drawn as a miniature of the layout it picks.
class _BannerStyleCard extends StatelessWidget {
  const _BannerStyleCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final BannerStyleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColors.bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.hairline,
                  width: selected ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Center(child: _preview()),
            ),
            const SizedBox(height: 5),
            Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                color: selected ? AppColors.accent : AppColors.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            Text(
              option.blurb,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                fontSize: 9.5,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _art = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF4A3A60), Color(0xFF1E2030)],
  );

  Widget _preview() {
    switch (option.id) {
      case BannerStyle.panelsId:
        return Transform.rotate(
          angle: -0.05,
          child: SizedBox(
            width: 56,
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 17, child: _pane()),
                const SizedBox(width: 3),
                Expanded(
                  flex: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _pane()),
                      const SizedBox(height: 3),
                      Expanded(child: _pane()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case BannerStyle.spotlightId:
        return SizedBox(
          width: 58,
          height: 44,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 30,
                decoration: BoxDecoration(
                  gradient: _art,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                  border: Border.all(color: Colors.white24, width: 0.7),
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: _art,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white54, width: 0.9),
                  ),
                  alignment: Alignment.bottomCenter,
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Container(
                    width: 14,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 7,
                height: 30,
                decoration: BoxDecoration(
                  gradient: _art,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                  border: Border.all(color: Colors.white24, width: 0.7),
                ),
              ),
            ],
          ),
        );
      case BannerStyle.showcaseId:
        return SizedBox(
          width: 56,
          height: 44,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 36,
                decoration: BoxDecoration(
                  gradient: _art,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.white60, width: 0.9),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 24,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 16,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case BannerStyle.compactId:
        return Container(
          width: 56,
          height: 24,
          decoration: BoxDecoration(
            gradient: _art,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.white38, width: 0.8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 20,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      width: 12,
                      height: 2.5,
                      decoration: BoxDecoration(
                        color: Colors.white38,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, size: 7, color: Colors.white),
              ),
            ],
          ),
        );
      case BannerStyle.cinemaId:
        return Container(
          width: 58,
          height: 46,
          decoration: const BoxDecoration(
            gradient: _art,
          ),
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white38,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        );
      case BannerStyle.glassId:
        return Container(
          width: 56,
          height: 44,
          decoration: BoxDecoration(
            gradient: _art,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24, width: 0.8),
          ),
          padding: const EdgeInsets.all(4),
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 16,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(5),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        );
      case BannerStyle.editorialId:
        return SizedBox(
          width: 56,
          height: 44,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 16,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white38,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 3),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: _art,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  alignment: Alignment.bottomLeft,
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      default:
        return Container(
          width: 56,
          height: 44,
          decoration: BoxDecoration(
            gradient: _art,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.only(bottom: 6),
          child: Container(
            width: 22,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
    }
  }

  Widget _pane() => Container(
    decoration: const BoxDecoration(gradient: _art),
    foregroundDecoration: BoxDecoration(
      border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 1),
    ),
  );
}
