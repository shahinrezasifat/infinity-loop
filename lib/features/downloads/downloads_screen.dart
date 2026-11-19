import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:hive/hive.dart';
import '../../core/ui/app_dialog.dart';
import '../../core/ui/settings_widgets.dart';

import '../../core/app_mode.dart';
import '../../core/di/injector.dart';
import '../../core/download/chapter_download_store.dart';
import '../../core/download/download_manager.dart';
import '../../core/download/download_prefs.dart';
import '../../core/download/download_record.dart';
import '../../core/mode/content_mode.dart';
import '../../core/models/episode.dart';
import '../../core/models/video_source.dart';
import '../../core/playback/resume_store.dart';
import '../../core/torrent/torrent_download_service.dart';
import '../../core/playback/watch_history.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/ui/states.dart';
import '../../l10n/l10n.dart';
import '../settings/download_location_screen.dart';
import '../player/player_screen.dart';
import '../player/tv_playback_launch.dart';
import 'chapter_downloads_screen.dart';
import 'downloads_screen_tv.dart';

/// Offline library — downloads grouped by show, with per-episode progress and
/// actions (play / pause / resume / cancel / delete). Shows collapse by default
/// into a scannable list; a search box filters by show or episode title, and a
/// summary strip shows the total downloaded count + storage used.
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key, this.showBack = true});

  /// False when shown as a dock tab — see [settingsAppBar].
  final bool showBack;

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen>
    with WidgetsBindingObserver {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  /// Show ids the user has expanded. Empty = all collapsed (the default).
  final Set<String> _expanded = <String>{};

  /// Record ids selected for batch actions (e.g. deletion).
  final Set<String> _selectedIds = <String>{};
  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected(DownloadManager manager) async {
    final count = _selectedIds.length;
    if (count == 0) return;
    final l10n = context.l10n;
    final ok = await AppDialog.confirm(
      context,
      title: l10n.delete,
      message: 'Delete $count selected download${count > 1 ? 's' : ''}?',
      confirmLabel: l10n.delete,
      destructive: true,
    );
    if (ok == true) {
      final toDelete = manager.all
          .where((r) => _selectedIds.contains(r.id))
          .toList();
      await manager.deleteAll(toDelete);
      setState(() {
        _selectedIds.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prune();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Coming back from a file manager (where a file may have been deleted) →
    // reconcile the list with disk. This is the case initState alone missed.
    if (state == AppLifecycleState.resumed) _prune();
  }

  /// Drop downloads whose file was deleted outside the app. Non-blocking.
  void _prune() => unawaited(sl<DownloadManager>().pruneMissing());

  void _toggle(String showId) => setState(() {
    if (!_expanded.remove(showId)) _expanded.add(showId);
  });

  /// "Saving to: `folder` · Change" — surfaces the download location right here
  /// (opens the existing picker) instead of only burying it in Settings.
  Widget _locationHeader() {
    final l10n = context.l10n;
    final prefs = sl<DownloadPrefs>();
    final label = downloadDestinationLabel(
      keepPrivate: prefs.keepPrivate,
      locationLabel: prefs.locationLabel,
      publicFallback: l10n.downloadsZangetsu,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open_rounded,
                size: 18,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.savingTo,
                    style: AppText.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    style: AppText.body.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const DownloadLocationScreen(),
                  ),
                );
                if (mounted) setState(() {}); // refresh the shown folder
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.change,
                      style: AppText.caption.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: AppColors.accent,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom sheet with the CloudStream-style download concurrency sliders.
  /// Applies to the NEXT downloads started (running HLS jobs aren't retimed).
  void _openDownloadSettings() {
    final l10n = context.l10n;
    final prefs = sl<DownloadPrefs>();
    // Hold the live drag value in local state so the sliders move smoothly —
    // each tick isn't an async Hive write/read round-trip. Persist + apply on
    // release (onCommit).
    int parallel = prefs.parallelDownloads;
    int connections = prefs.connectionsPerDownload;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget slider({
            required String title,
            required String subtitle,
            required int value,
            required int min,
            required int max,
            required ValueChanged<int> onChanged,
            ValueChanged<int>? onCommit,
          }) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                  child: Row(
                    children: [
                      Expanded(child: Text(title, style: AppText.headline)),
                      Text(
                        '$value',
                        style: AppText.headline.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                  child: Text(subtitle, style: AppText.caption),
                ),
                Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  activeColor: AppColors.accent,
                  label: '$value',
                  onChanged: (v) => setSheet(() => onChanged(v.round())),
                  onChangeEnd: onCommit == null
                      ? null
                      : (v) => onCommit(v.round()),
                ),
              ],
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l10n.downloadSettings, style: AppText.title),
                  ),
                ),
                slider(
                  title: l10n.parallelDownloads,
                  subtitle: l10n.parallelDownloadsSubtitle,
                  value: parallel,
                  min: DownloadPrefs.parallelMin,
                  max: DownloadPrefs.parallelMax,
                  onChanged: (n) => parallel = n,
                  // On release: persist + apply live to both paths (MP4 queue +
                  // HLS service). Raising it starts queued episodes immediately;
                  // lowering it just stops new ones spawning.
                  onCommit: (n) => sl<DownloadManager>().setParallel(n),
                ),
                const SizedBox(height: 8),
                slider(
                  title: l10n.connectionsPerDownload,
                  subtitle: l10n.connectionsPerDownloadSubtitle,
                  value: connections,
                  min: DownloadPrefs.connectionsMin,
                  max: DownloadPrefs.connectionsMax,
                  onChanged: (n) => connections = n,
                  onCommit: (n) => prefs.setConnectionsPerDownload(n),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (sl<AppMode>().isTv) return const DownloadsScreenTv();
    final manager = sl<DownloadManager>();
    final store = sl<ChapterDownloadStore>();
    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          setState(() => _selectedIds.clear());
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        appBar: _isSelectionMode
            ? AppBar(
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _selectedIds.clear()),
                ),
                title: Text(
                  '${_selectedIds.length} selected',
                  style: AppText.headline.copyWith(fontSize: 18),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.select_all_rounded),
                    tooltip: 'Select all',
                    onPressed: () {
                      setState(() {
                        _selectedIds.addAll(manager.all.map((r) => r.id));
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent),
                    tooltip: 'Delete',
                    onPressed: () => _deleteSelected(manager),
                  ),
                ],
              )
            : settingsAppBar(
                showBack: widget.showBack,
                context.l10n.downloads,
                actions: [
                  IconButton(
                    tooltip: context.l10n.downloadSettings,
                    icon: const Icon(Icons.tune_rounded),
                    onPressed: _openDownloadSettings,
                  ),
                ],
              ),
        body: ListenableBuilder(
          listenable: manager,
          builder: (context, _) {
            final groups = manager.byShow;
            return Column(
              children: [
                _locationHeader(),
                _chapterLinks(store),
                if (groups.isEmpty)
                  Expanded(
                    child: _DownloadsEmptyState(
                      message: context.l10n.episodesYouDownloadAppearHere,
                    ),
                  )
                else ...[
                  _searchField(),
                  Expanded(child: _list(groups, manager)),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Manga and novel downloads get their own screens — they're chapters, not
  /// episodes, and listing them here made this screen a dumping ground. These
  /// two rows are just the way in, with a count so you can see there's
  /// something there without opening it.
  ///
  /// Only these rows watch the chapter box. It's written twice a second while
  /// a chapter downloads, and the video list below has no reason to rebuild
  /// for that.
  Widget _chapterLinks(ChapterDownloadStore store) {
    return ValueListenableBuilder<Box<Map>>(
      valueListenable: store.listenable(),
      builder: (context, box, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(
          children: [
            for (final m in const [ContentMode.manga, ContentMode.novel]) ...[
              Expanded(child: _chapterCard(m, store.countDone(m))),
              if (m == ContentMode.manga) const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }

  /// Side by side rather than two full-width rows: they're a way into the other
  /// two screens, not content, and stacked they pushed the episode list most of
  /// a screen down.
  Widget _chapterCard(ContentMode mode, int count) {
    final novel = mode == ContentMode.novel;
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ChapterDownloadsScreen(mode: mode),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  chapterIcon(mode),
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      novel ? l10n.novels : l10n.modeManga,
                      style: AppText.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      l10n.chapterCount(count),
                      style: AppText.caption.copyWith(
                        color: count > 0
                            ? AppColors.accent
                            : AppColors.textTertiary,
                        fontWeight:
                            count > 0 ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textTertiary,
                size: 13,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: AppText.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isDense: true,
            hintText: context.l10n.searchDownloads,
            hintStyle: AppText.body.copyWith(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textTertiary,
              size: 22,
            ),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.textTertiary,
                      size: 18,
                    ),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  ),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.accent.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _list(
    Map<String, List<DownloadRecord>> groups,
    DownloadManager manager,
  ) {
    final q = _query.trim().toLowerCase();
    final all = manager.all;
    final done = all.where((r) => r.status == DownloadStatus.done).toList();
    final totalBytes = done.fold<int>(0, (s, r) => s + r.bytesTotal);

    final showIds = groups.keys.toList();
    final rows = <Widget>[];
    for (final id in showIds) {
      final recs = [
        ...groups[id]!,
      ]..sort((a, b) => (a.episodeNumber ?? 0).compareTo(b.episodeNumber ?? 0));
      final head = recs.first;

      List<DownloadRecord> episodes = recs;
      var forceExpand = false;
      if (q.isNotEmpty) {
        final showMatch = head.showTitle.toLowerCase().contains(q);
        if (!showMatch) {
          episodes = recs
              .where((r) => _episodeSearchText(r).contains(q))
              .toList();
          if (episodes.isEmpty) continue; // this show has no match — hide it
        }
        forceExpand = true; // reveal matches while searching
      }

      final isMovie = recs.length == 1 &&
          (head.isMovie ||
              head.episodeNumber == null ||
              head.episodeNumber == 1);
      if (isMovie) {
        rows.add(
          _MovieDownloadTile(
            record: head,
            manager: manager,
            isSelected: _selectedIds.contains(head.id),
            isSelectionMode: _isSelectionMode,
            onSelect: () => _toggleSelection(head.id),
          ),
        );
      } else {
        rows.add(
          _ShowGroup(
            records: recs,
            episodes: episodes,
            manager: manager,
            expanded: forceExpand || _expanded.contains(id),
            onToggle: () => _toggle(id),
            selectedIds: _selectedIds,
            isSelectionMode: _isSelectionMode,
            onToggleSelect: _toggleSelection,
          ),
        );
      }
    }

    if (rows.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        message: context.l10n.noDownloadsMatchYourSearch,
      );
    }

    final anyExpanded = showIds.any(_expanded.contains);
    return ListView(
      // Clear the floating dock, which overlays content (this tab has no
      // reserved space of its own for it).
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      children: [
        _summaryStrip(
          count: done.length,
          bytes: totalBytes,
          anyExpanded: anyExpanded,
          onToggleAll: () => setState(() {
            if (anyExpanded) {
              _expanded.clear();
            } else {
              _expanded.addAll(showIds);
            }
          }),
        ),
        ...rows,
      ],
    );
  }

  Widget _summaryStrip({
    required int count,
    required int bytes,
    required bool anyExpanded,
    required VoidCallback onToggleAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.offline_pin_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  context.l10n.downloadedSummary(count, fmtDownloadSize(bytes)),
                  style: AppText.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: onToggleAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    anyExpanded
                        ? Icons.unfold_less_rounded
                        : Icons.unfold_more_rounded,
                    size: 14,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    anyExpanded
                        ? context.l10n.collapseAll
                        : context.l10n.expandAll,
                    style: AppText.caption.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatDownloadSpeed(double bps) {
  if (bps <= 0) return '';
  final mbps = bps / (1024 * 1024);
  if (mbps >= 1.0) {
    return '${mbps.toStringAsFixed(1)} MB/s';
  }
  final kbps = bps / 1024;
  if (kbps >= 1.0) {
    return '${kbps.toStringAsFixed(0)} KB/s';
  }
  return '${bps.round()} B/s';
}

String formatEta(Duration? d) {
  if (d == null || d.inSeconds <= 0) return '';
  final hours = d.inHours;
  final minutes = d.inMinutes.remainder(60);
  final seconds = d.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours}h ${minutes}m left';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds}s left';
  }
  return '${seconds}s left';
}

/// Lowercased text a download is matched against when searching.
String _episodeSearchText(DownloadRecord r) {
  final n = r.episodeNumber?.toInt();
  return 'e${n ?? ''} ${r.episodeTitle}'.toLowerCase();
}

/// Tactile, modern circular action button with subtle borders and shadows.
class _CircularActionButton extends StatelessWidget {
  const _CircularActionButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.borderColor,
    this.size = 38,
    this.iconSize = 20,
    this.glow = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surface2;
    final effectiveColor = color ?? AppColors.textPrimary;
    Widget btn = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: effectiveBg,
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
            boxShadow: glow
                ? [
                    BoxShadow(
                      color:
                          (color ?? AppColors.accent).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Icon(
              icon,
              size: iconSize,
              color: effectiveColor,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: btn);
    }
    return btn;
  }
}

class _ShowGroup extends StatelessWidget {
  const _ShowGroup({
    required this.records,
    required this.episodes,
    required this.manager,
    required this.expanded,
    required this.onToggle,
    this.selectedIds = const {},
    this.isSelectionMode = false,
    this.onToggleSelect,
  });

  /// The full group — drives the "done of total" count and the group size.
  final List<DownloadRecord> records;

  /// The episodes to render when expanded (a filtered subset while searching).
  final List<DownloadRecord> episodes;

  final DownloadManager manager;
  final bool expanded;
  final VoidCallback onToggle;
  final Set<String> selectedIds;
  final bool isSelectionMode;
  final ValueChanged<String>? onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final head = records.first;
    final doneRecs = records
        .where((r) => r.status == DownloadStatus.done)
        .toList();
    final groupBytes = doneRecs.fold<int>(0, (s, r) => s + r.bytesTotal);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 68,
                      child: (head.cover != null && head.cover!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: head.cover!,
                              httpHeaders: head.coverHeaders,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  ColoredBox(color: AppColors.surface2),
                            )
                          : ColoredBox(color: AppColors.surface2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          head.showTitle,
                          style: AppText.headline.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surface2,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${doneRecs.length}/${records.length} ep',
                                style: AppText.caption.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            if (groupBytes > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  fmtDownloadSize(groupBytes),
                                  style: AppText.caption.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  _CircularActionButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: l10n.deleteAllEpisodesTooltip,
                    color: AppColors.textTertiary,
                    size: 34,
                    iconSize: 18,
                    onTap: () => _confirmDeleteAll(context),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Center(
                      child: AnimatedRotation(
                        turns: expanded ? 0.25 : 0.0,
                        duration: const Duration(milliseconds: 180),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.05),
            ),
            for (final r in episodes)
              DownloadTile(
                record: r,
                manager: manager,
                isSelected: selectedIds.contains(r.id),
                isSelectionMode: isSelectionMode,
                onSelect: () => onToggleSelect?.call(r.id),
              ),
          ],
        ],
      ),
    );
  }

  /// Confirm, then wipe every episode of this show in one go.
  Future<void> _confirmDeleteAll(BuildContext context) async {
    final l10n = context.l10n;
    final n = records.length;
    final ok = await AppDialog.confirm(
      context,
      title: l10n.deleteAllDownloads,
      message: l10n.removeAllEpisodesOfShow(n, records.first.showTitle),
      confirmLabel: l10n.deleteAll,
      destructive: true,
    );
    if (ok == true) await manager.deleteAll(records);
  }
}

/// Launches playback of a completed [DownloadRecord].
/// Called by both [DownloadTile] (phone touch path) and [DownloadsScreenTv]
/// (TV D-pad OK path) so the play logic lives in one place.
///
/// Phone plays through [PlayerScreen] (media_kit); TV routes to the same two
/// ExoPlayer paths streaming already uses, so nothing on TV touches media_kit.
Future<void> launchDownloadedEpisode(
  BuildContext context,
  DownloadRecord record,
) async {
  final path = record.filePath;
  if (path == null) return;
  final ep = Episode(
    id: record.episodeId,
    title: record.episodeTitle,
    number: record.episodeNumber,
    url: record.episodeUrl,
  );
  // The file is already on disk, so "resolving" is just handing back a source
  // pointing at it — same shape both players expect from a network resolve.
  Future<List<VideoSource>> resolveSources(String _) async => [
    VideoSource(
      url: path,
      container: SourceContainer.mp4,
      // Soft subs saved next to the video (e.g. HiAnime) → load from disk.
      subtitles: [
        for (final s in record.subtitles)
          Subtitle(
            url: s.path,
            lang: s.lang,
            label: s.label,
            isDefault: s.isDefault,
          ),
      ],
    ),
  ];
  final scrobbleTitle = record.malId != null ? record.showTitle : null;

  if (sl<AppMode>().isTv) {
    await launchTvPlayback(
      context: context,
      sourceId: record.sourceId,
      episodes: [ep],
      startIndex: 0,
      resume: sl<ResumeStore>(),
      resolveSources: resolveSources,
      showUrl: record.showUrl,
      showTitle: record.showTitle,
      cover: record.cover,
      coverHeaders: record.coverHeaders,
      category: record.category,
      malId: record.malId,
      scrobbleTitle: scrobbleTitle,
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PlayerScreen(
        sourceId: record.sourceId,
        episodes: [ep],
        startIndex: 0,
        resume: sl<ResumeStore>(),
        resolveSources: resolveSources,
        history: sl<WatchHistory>(),
        showTitle: record.showTitle,
        cover: record.cover,
        coverHeaders: record.coverHeaders,
        showUrl: record.showUrl,
        category: record.category,
        malId: record.malId,
        scrobbleTitle: scrobbleTitle,
      ),
    ),
  );
}

class DownloadTile extends StatelessWidget {
  const DownloadTile({
    super.key,
    required this.record,
    required this.manager,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelect,
  });

  final DownloadRecord record;
  final DownloadManager manager;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelect;

  String _epLabel(AppLocalizations l10n) {
    if (record.isMovie) return '';
    final n = record.episodeNumber?.toInt();
    final t = record.episodeTitle.trim();
    if (n != null) {
      final short = l10n.episodeNumberShort(n);
      if (t.isEmpty || t == short || t == l10n.episodeLabel(n)) return short;
      return l10n.episodeWithTitleDot(n, t);
    }
    final generic = l10n
        .episodeSemantic(1)
        .replaceFirst(' 1', '')
        .replaceFirst('1', '');
    return (t.isEmpty || t == generic) ? generic : '$generic · $t';
  }

  String _subtitle(AppLocalizations l10n) {
    // A finished torrent is streamed into the user's folder — surface that phase.
    if (record.isTorrent &&
        manager.torrentProgress[record.id]?.status == 'copying') {
      return l10n.savingToYourFolder;
    }
    final pct = (record.progress * 100).round();
    final stats = manager.liveStats[record.id];
    final speedStr = stats != null && stats.speedBps > 0
        ? formatDownloadSpeed(stats.speedBps)
        : '';
    final etaStr = stats?.timeRemaining != null
        ? formatEta(stats!.timeRemaining)
        : '';
    var totalBytes = stats != null && stats.bytesTotal > 0
        ? stats.bytesTotal
        : record.bytesTotal;
    var dlBytes = stats != null && stats.bytesDownloaded > 0
        ? stats.bytesDownloaded
        : (totalBytes > 0 ? (totalBytes * record.progress).round() : 0);

    if (totalBytes <= 0 && record.progress > 0) {
      totalBytes = record.isMovie ? 1200 * 1024 * 1024 : 350 * 1024 * 1024;
      dlBytes = (totalBytes * record.progress).round();
    }

    return switch (record.status) {
      DownloadStatus.done =>
        record.bytesTotal > 0
            ? fmtDownloadSize(record.bytesTotal)
            : l10n.downloaded,
      DownloadStatus.downloading => [
          if (totalBytes > 0)
            '$pct% · ${fmtDownloadSize(dlBytes)} of ${fmtDownloadSize(totalBytes)}'
          else if (dlBytes > 0)
            '$pct% · ${fmtDownloadSize(dlBytes)}'
          else
            l10n.downloadProgressPercent(pct),
          if (speedStr.isNotEmpty)
            speedStr
          else
            'Measuring speed...',
          if (etaStr.isNotEmpty) etaStr,
        ].join(' · ') + _torrentSuffix(l10n),
      DownloadStatus.paused => l10n.downloadPausedProgress(pct),
      DownloadStatus.finalizing => l10n.downloadFinalizing,
      DownloadStatus.queued => l10n.downloadQueued,
      DownloadStatus.resolving => l10n.downloadPreparing,
      DownloadStatus.unsupported => record.error ?? l10n.notAvailableOfflineYet,
      DownloadStatus.failed => record.error ?? l10n.downloadFailedStatus,
      DownloadStatus.canceled => l10n.downloadCanceled,
    };
  }

  /// " · N peers · X MB/s" for an active torrent download (empty otherwise).
  String _torrentSuffix(AppLocalizations l10n) {
    if (!record.isTorrent) return '';
    final TorrentDownloadProgress? p = manager.torrentProgress[record.id];
    if (p == null) return '';
    final parts = <String>[];
    if (p.peers > 0) parts.add(l10n.peerCount(p.peers));
    if (p.downSpeedBps > 0) {
      final mb = p.downSpeedBps / (1024 * 1024);
      parts.add(
        mb >= 1
            ? l10n.downloadSpeedMbps(mb.toStringAsFixed(1))
            : l10n.downloadSpeedKbps((p.downSpeedBps / 1024).round()),
      );
    }
    return parts.isEmpty ? '' : ' · ${parts.join(' · ')}';
  }

  Future<void> _play(BuildContext context) =>
      launchDownloadedEpisode(context, record);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDone = record.status == DownloadStatus.done;
    final isDownloading = record.status == DownloadStatus.downloading;
    final isPaused = record.status == DownloadStatus.paused;
    final isFailed = record.status == DownloadStatus.failed;

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 4, 12, 4),
      selected: isSelected,
      selectedTileColor: AppColors.accent.withValues(alpha: 0.1),
      onTap: isSelectionMode
          ? onSelect
          : (isDone
              ? () => _play(context)
              : (isFailed ? () => unawaited(manager.retry(record)) : null)),
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onSelect?.call();
      },
      leading: isSelectionMode
          ? Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.accent : AppColors.textTertiary,
              size: 24,
            )
          : _StatusGlyph(record: record),
      title: record.isMovie
          ? null
          : Text(
              _epLabel(l10n),
              style: AppText.body.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 2),
          Text(_subtitle(l10n), style: AppText.caption.copyWith(fontSize: 11.5)),
          if (record.status == DownloadStatus.downloading ||
              record.status == DownloadStatus.paused) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: record.progress > 0 ? record.progress : null,
                minHeight: 3.5,
                color: isPaused ? AppColors.textTertiary : AppColors.accent,
                backgroundColor: AppColors.surface2,
              ),
            ),
          ],
        ],
      ),
      trailing: isSelectionMode
          ? null
          : (isDownloading
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularActionButton(
                      icon: Icons.pause_rounded,
                      tooltip: l10n.pause,
                      size: 34,
                      iconSize: 18,
                      color: AppColors.textPrimary,
                      onTap: () => unawaited(manager.pause(record)),
                    ),
                    const SizedBox(width: 6),
                    _CircularActionButton(
                      icon: Icons.close_rounded,
                      tooltip: l10n.cancel,
                      size: 34,
                      iconSize: 18,
                      color: AppColors.textTertiary,
                      onTap: () => unawaited(manager.cancel(record)),
                    ),
                  ],
                )
              : (isPaused
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _CircularActionButton(
                          icon: Icons.play_arrow_rounded,
                          tooltip: l10n.resume,
                          size: 34,
                          iconSize: 20,
                          color: AppColors.accent,
                          backgroundColor:
                              AppColors.accent.withValues(alpha: 0.15),
                          borderColor:
                              AppColors.accent.withValues(alpha: 0.3),
                          onTap: () => unawaited(manager.resume(record)),
                        ),
                        const SizedBox(width: 6),
                        _CircularActionButton(
                          icon: Icons.close_rounded,
                          tooltip: l10n.cancel,
                          size: 34,
                          iconSize: 18,
                          color: AppColors.textTertiary,
                          onTap: () => unawaited(manager.cancel(record)),
                        ),
                      ],
                    )
                  : (isDone
                      ? _CircularActionButton(
                          icon: Icons.play_arrow_rounded,
                          tooltip: 'Play',
                          size: 36,
                          iconSize: 22,
                          color: Colors.white,
                          backgroundColor: AppColors.accent,
                          glow: true,
                          onTap: () => _play(context),
                        )
                      : (isFailed
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _CircularActionButton(
                                  icon: Icons.refresh_rounded,
                                  tooltip: 'Retry',
                                  size: 34,
                                  iconSize: 18,
                                  color: Colors.redAccent,
                                  backgroundColor:
                                      Colors.redAccent.withValues(alpha: 0.15),
                                  onTap: () =>
                                      unawaited(manager.retry(record)),
                                ),
                                const SizedBox(width: 6),
                                _CircularActionButton(
                                  icon: Icons.close_rounded,
                                  tooltip: l10n.cancel,
                                  size: 34,
                                  iconSize: 18,
                                  color: AppColors.textTertiary,
                                  onTap: () =>
                                      unawaited(manager.cancel(record)),
                                ),
                              ],
                            )
                          : _CircularActionButton(
                              icon: Icons.close_rounded,
                              tooltip: l10n.cancel,
                              size: 34,
                              iconSize: 18,
                              color: AppColors.textTertiary,
                              onTap: () =>
                                  unawaited(manager.cancel(record)),
                            ))))),
    );
  }
}

class _StatusGlyph extends StatelessWidget {
  const _StatusGlyph({required this.record});
  final DownloadRecord record;

  @override
  Widget build(BuildContext context) {
    return switch (record.status) {
      DownloadStatus.done => Icon(
        Icons.play_circle_fill_rounded,
        color: AppColors.accent,
        size: 32,
      ),
      DownloadStatus.downloading => SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          value: record.progress > 0 ? record.progress : null,
          strokeWidth: 2.4,
          color: AppColors.accent,
          backgroundColor: AppColors.surface2,
        ),
      ),
      // Indeterminate on purpose: joining and remuxing report nothing, so a
      // bar frozen at 100% is exactly the lie this state exists to stop.
      DownloadStatus.finalizing => SizedBox(
        width: 26,
        height: 26,
        child: CircularProgressIndicator(
          strokeWidth: 2.4,
          color: AppColors.accent,
        ),
      ),
      DownloadStatus.paused => const Icon(
        Icons.pause_circle_outline_rounded,
        color: AppColors.textSecondary,
        size: 30,
      ),
      DownloadStatus.unsupported => const Icon(
        Icons.cloud_off_outlined,
        color: AppColors.textTertiary,
        size: 26,
      ),
      DownloadStatus.failed => Icon(
        Icons.error_outline_rounded,
        color: AppColors.accent,
        size: 28,
      ),
      DownloadStatus.canceled => const Icon(
        Icons.cancel_outlined,
        color: AppColors.textTertiary,
        size: 26,
      ),
      // queued / resolving — genuinely loading.
      _ => const SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    };
  }
}

/// A direct single-card presentation for a downloaded/downloading movie.
/// Shows the movie poster directly on the left and title, live speed,
/// downloaded/total size, and ETA beside it — with no expandable episode list!
class _MovieDownloadTile extends StatelessWidget {
  const _MovieDownloadTile({
    required this.record,
    required this.manager,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onSelect,
  });

  final DownloadRecord record;
  final DownloadManager manager;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDone = record.status == DownloadStatus.done;
    final isDownloading = record.status == DownloadStatus.downloading;
    final isPaused = record.status == DownloadStatus.paused;
    final isFailed = record.status == DownloadStatus.failed;
    final stats = manager.liveStats[record.id];

    final pct = (record.progress * 100).round();
    var totalBytes = stats != null && stats.bytesTotal > 0
        ? stats.bytesTotal
        : record.bytesTotal;
    var dlBytes = stats != null && stats.bytesDownloaded > 0
        ? stats.bytesDownloaded
        : (totalBytes > 0 ? (totalBytes * record.progress).round() : 0);

    if (totalBytes <= 0 && record.progress > 0) {
      totalBytes = 1200 * 1024 * 1024;
      dlBytes = (totalBytes * record.progress).round();
    }

    final speedStr = stats != null && stats.speedBps > 0
        ? formatDownloadSpeed(stats.speedBps)
        : '';
    final etaStr = stats?.timeRemaining != null
        ? formatEta(stats!.timeRemaining)
        : '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.accent
              : Colors.white.withValues(alpha: 0.06),
          width: isSelected ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSelectionMode
            ? onSelect
            : (isDone
                ? () => launchDownloadedEpisode(context, record)
                : (isFailed ? () => unawaited(manager.retry(record)) : null)),
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onSelect?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Movie poster / thumbnail
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 92,
                      child: (record.cover != null && record.cover!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: record.cover!,
                              httpHeaders: record.coverHeaders,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  ColoredBox(color: AppColors.surface2),
                            )
                          : ColoredBox(color: AppColors.surface2),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 64,
                      height: 92,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    )
                  else if (isDone)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  else if (isDownloading)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value:
                                  record.progress > 0 ? record.progress : null,
                              strokeWidth: 2.5,
                              color: AppColors.accent,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isPaused)
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.amberAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.pause_rounded,
                          color: Colors.amberAccent,
                          size: 22,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // Details column beside thumbnail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      record.showTitle,
                      style: AppText.headline.copyWith(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),

                    // Badges row: "Movie" · "1080p" · "DOWNLOADING"
                    Wrap(
                      spacing: 5,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            'Movie',
                            style: AppText.caption.copyWith(
                              color: AppColors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (record.quality.isNotEmpty &&
                            record.quality != 'auto')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: AppColors.surface2,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              record.quality,
                              style: AppText.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (isDownloading)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0284C7)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 4.5,
                                  height: 4.5,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF38BDF8),
                                  ),
                                ),
                                const SizedBox(width: 3.5),
                                const Text(
                                  'DOWNLOADING',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Color(0xFF38BDF8),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (isPaused)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'PAUSED',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.amberAccent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else if (isDone)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: const Text(
                              'READY',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF34D399),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 7),

                    if (isDownloading) ...[
                      // Size & progress
                      Row(
                        children: [
                          Text(
                            '$pct%',
                            style: AppText.caption.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              totalBytes > 0
                                  ? '· ${fmtDownloadSize(dlBytes)} of ${fmtDownloadSize(totalBytes)}'
                                  : (dlBytes > 0
                                      ? '· ${fmtDownloadSize(dlBytes)}'
                                      : '· downloading'),
                              style: AppText.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      // Speed & ETA
                      Row(
                        children: [
                          Icon(
                            Icons.speed_rounded,
                            size: 13,
                            color: AppColors.accent,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              speedStr.isNotEmpty
                                  ? speedStr
                                  : 'Measuring speed...',
                              style: AppText.caption.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (etaStr.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text(
                              '·',
                              style: AppText.caption.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.timer_outlined,
                              size: 12,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              etaStr,
                              style: AppText.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: record.progress > 0 ? record.progress : null,
                          minHeight: 4,
                          color: AppColors.accent,
                          backgroundColor: AppColors.surface2,
                        ),
                      ),
                    ] else if (isDone) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 14,
                            color: Color(0xFF10B981),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            record.bytesTotal > 0
                                ? '${fmtDownloadSize(record.bytesTotal)} · Ready to watch'
                                : 'Ready to watch',
                            style: AppText.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ] else if (isPaused) ...[
                      Text(
                        'Paused at ${fmtDownloadSize(dlBytes)} ($pct%)',
                        style: AppText.caption.copyWith(
                          color: Colors.amberAccent.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: record.progress > 0 ? record.progress : null,
                          minHeight: 3.5,
                          color: AppColors.textTertiary,
                          backgroundColor: AppColors.surface2,
                        ),
                      ),
                    ] else if (isFailed) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              record.error ?? 'Download failed · Tap to retry',
                              style: AppText.caption.copyWith(
                                color: Colors.redAccent,
                                fontSize: 11.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Text(
                        switch (record.status) {
                          DownloadStatus.queued => 'Queued...',
                          DownloadStatus.resolving => 'Preparing stream...',
                          DownloadStatus.finalizing =>
                            'Finalizing video file...',
                          DownloadStatus.unsupported => 'Not supported',
                          DownloadStatus.canceled => 'Canceled',
                          _ => 'Loading...',
                        },
                        style: AppText.caption.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Action buttons
              if (isSelectionMode) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.accent : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
              ] else if (isDownloading) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularActionButton(
                      icon: Icons.pause_rounded,
                      tooltip: l10n.pause,
                      size: 36,
                      iconSize: 18,
                      color: AppColors.textPrimary,
                      onTap: () => unawaited(manager.pause(record)),
                    ),
                    const SizedBox(width: 8),
                    _CircularActionButton(
                      icon: Icons.close_rounded,
                      tooltip: l10n.cancel,
                      size: 36,
                      iconSize: 18,
                      color: AppColors.textTertiary,
                      onTap: () => unawaited(manager.cancel(record)),
                    ),
                  ],
                ),
              ] else if (isPaused) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularActionButton(
                      icon: Icons.play_arrow_rounded,
                      tooltip: l10n.resume,
                      size: 36,
                      iconSize: 22,
                      color: AppColors.accent,
                      backgroundColor:
                          AppColors.accent.withValues(alpha: 0.15),
                      borderColor: AppColors.accent.withValues(alpha: 0.3),
                      onTap: () => unawaited(manager.resume(record)),
                    ),
                    const SizedBox(width: 8),
                    _CircularActionButton(
                      icon: Icons.close_rounded,
                      tooltip: l10n.cancel,
                      size: 36,
                      iconSize: 18,
                      color: AppColors.textTertiary,
                      onTap: () => unawaited(manager.cancel(record)),
                    ),
                  ],
                ),
              ] else if (isDone) ...[
                _CircularActionButton(
                  icon: Icons.play_arrow_rounded,
                  tooltip: 'Play',
                  size: 40,
                  iconSize: 24,
                  color: Colors.white,
                  backgroundColor: AppColors.accent,
                  glow: true,
                  onTap: () => launchDownloadedEpisode(context, record),
                ),
              ] else if (isFailed) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _CircularActionButton(
                      icon: Icons.refresh_rounded,
                      tooltip: 'Retry',
                      size: 36,
                      iconSize: 18,
                      color: Colors.redAccent,
                      backgroundColor:
                          Colors.redAccent.withValues(alpha: 0.15),
                      onTap: () => unawaited(manager.retry(record)),
                    ),
                    const SizedBox(width: 8),
                    _CircularActionButton(
                      icon: Icons.close_rounded,
                      tooltip: l10n.cancel,
                      size: 36,
                      iconSize: 18,
                      color: AppColors.textTertiary,
                      onTap: () => unawaited(manager.cancel(record)),
                    ),
                  ],
                ),
              ] else ...[
                _CircularActionButton(
                  icon: Icons.close_rounded,
                  tooltip: l10n.cancel,
                  size: 36,
                  iconSize: 18,
                  color: AppColors.textTertiary,
                  onTap: () => unawaited(manager.cancel(record)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DownloadsEmptyState extends StatelessWidget {
  const _DownloadsEmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.cloud_download_outlined,
                size: 40,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Downloads Yet',
              style: AppText.headline.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(
                fontSize: 13,
                color: AppColors.textTertiary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
