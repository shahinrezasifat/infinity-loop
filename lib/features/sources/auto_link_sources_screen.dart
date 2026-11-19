import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/di/injector.dart';
import '../../core/models/episode.dart';
import '../../core/models/video_source.dart';
import '../../core/playback/resume_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../services/auto_link_provider.dart';
import '../../services/auto_repo_service.dart';
import '../player/player_screen.dart';

class AutoLinkSourcesScreen extends StatefulWidget {
  const AutoLinkSourcesScreen({super.key});

  @override
  State<AutoLinkSourcesScreen> createState() => _AutoLinkSourcesScreenState();
}

Future<void> showAutoRepoDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _AutoRepoDialog());

void openAutoLinkUrl(
  BuildContext context, {
  required String title,
  required String url,
}) {
  final service = AutoRepoService();
  final type = AutoRepoService.detectType(url);
  final source = AutoLinkSource(
    id: url,
    repoId: AutoRepoService.repoId,
    title: title,
    url: url,
    type: type,
    createdAt: DateTime.now(),
  );
  switch (type) {
    case AutoLinkType.directVideo:
      _play(context, title, url);
    case AutoLinkType.m3u:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _AutoPlaylistScreen(source: source, service: service),
        ),
      );
    case AutoLinkType.bdixDir:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              _AutoDirectoryScreen(title: title, url: url, service: service),
        ),
      );
    case AutoLinkType.webSniffer:
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _AutoWebSnifferScreen(source: source),
        ),
      );
  }
}

class AutoRepoButton extends StatelessWidget {
  const AutoRepoButton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      ),
      onPressed: () => showAutoRepoDialog(context),
      icon: const Icon(Icons.add_link_rounded),
      label: const Text('Add to Link Repo'),
    ),
  );
}

class _AutoRepoDialog extends StatefulWidget {
  const _AutoRepoDialog();

  @override
  State<_AutoRepoDialog> createState() => _AutoRepoDialogState();
}

class _AutoRepoDialogState extends State<_AutoRepoDialog> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _nameController = TextEditingController();
  final _service = AutoRepoService();
  bool _saving = false;

  @override
  void dispose() {
    _urlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await _service.addAutoLink(
        url: _urlController.text,
        name: _nameController.text,
      );
      if (sl.isRegistered<AutoLinkProvider>()) {
        await sl<AutoLinkProvider>().refresh();
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Link added to Link Repo.')));
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not add link: $error')));
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add to Link Repo'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _urlController,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL',
                hintText: 'Paste a website, stream, or playlist link',
              ),
              validator: (value) {
                try {
                  AutoRepoService.validateUrl(value ?? '');
                  return null;
                } on FormatException catch (error) {
                  return error.message.toString();
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Custom name (optional)',
                hintText: 'Uses the page title or domain if blank',
              ),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.of(context).pop(),
        child: const Text('Cancel'),
      ),
      ElevatedButton(
        onPressed: _saving ? null : _save,
        child: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );
}

class AutoLinkRepoSection extends StatefulWidget {
  const AutoLinkRepoSection({super.key});

  @override
  State<AutoLinkRepoSection> createState() => _AutoLinkRepoSectionState();
}

class _AutoLinkRepoSectionState extends State<AutoLinkRepoSection> {
  final _service = AutoRepoService();
  late Future<bool> _exists;

  @override
  void initState() {
    super.initState();
    _exists = _service.hasLinkRepo();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _exists,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Card(
          color: AppColors.surface,
          child: ListTile(
            leading: Icon(Icons.link_rounded, color: AppColors.accent),
            title: const Text('Link Repo'),
            subtitle: const Text('Your saved streams and websites'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AutoLinkSourcesScreen(),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AutoLinkSourcesScreenState extends State<AutoLinkSourcesScreen> {
  final _service = AutoRepoService();
  late Future<List<AutoLinkSource>> _links;
  late Future<bool> _enabled;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _links = _service.getAutoLinks();
    _enabled = _service.isEnabled();
  }

  Future<void> _delete(AutoLinkSource link) async {
    try {
      await _service.deleteAutoLink(link.id);
      if (sl.isRegistered<AutoLinkProvider>()) {
        await sl<AutoLinkProvider>().refresh();
      }
      if (!mounted) return;
      setState(_reload);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete link: $error')));
    }
  }

  void _openLink(AutoLinkSource link) {
    switch (link.type) {
      case AutoLinkType.directVideo:
        _play(link.title, link.url);
      case AutoLinkType.m3u:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                _AutoPlaylistScreen(source: link, service: _service),
          ),
        );
      case AutoLinkType.bdixDir:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _AutoDirectoryScreen(
              title: link.title,
              url: link.url,
              service: _service,
            ),
          ),
        );
      case AutoLinkType.webSniffer:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _AutoWebSnifferScreen(source: link),
          ),
        );
    }
  }

  void _play(String title, String url) {
    final episode = Episode(id: url, title: title, url: url, number: 1);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlayerScreen(
          sourceId: 'auto_link:repo',
          showTitle: title,
          episodes: [episode],
          resume: sl<ResumeStore>(),
          resolveSources: (_) async => [VideoSource(url: url, label: title)],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(
      title: const Text('Link Repo'),
      actions: [
        IconButton(
          tooltip: 'Add Link',
          icon: const Icon(Icons.add_link_rounded),
          onPressed: () async {
            await showAutoRepoDialog(context);
            if (mounted) setState(_reload);
          },
        ),
        FutureBuilder<bool>(
          future: _enabled,
          builder: (context, snapshot) => Switch(
            value: snapshot.data ?? true,
            onChanged: snapshot.hasData
                ? (enabled) async {
                    await _service.setEnabled(enabled);
                    if (sl.isRegistered<AutoLinkProvider>()) {
                      await sl<AutoLinkProvider>().refresh();
                    }
                    if (mounted) setState(_reload);
                  }
                : null,
          ),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      onPressed: () async {
        await showAutoRepoDialog(context);
        if (mounted) setState(_reload);
      },
      icon: const Icon(Icons.add_link_rounded),
      label: const Text('Add Link'),
    ),
    body: FutureBuilder<List<AutoLinkSource>>(
      future: _links,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not load links: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final links = snapshot.data!;
        if (links.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.link_off_rounded, size: 64, color: AppColors.textTertiary),
                  const SizedBox(height: 16),
                  Text('No links in Link Repo yet', style: AppText.headline),
                  const SizedBox(height: 8),
                  Text(
                    'Add a website, stream, M3U playlist, or BDIX directory link to start streaming.',
                    textAlign: TextAlign.center,
                    style: AppText.body.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      await showAutoRepoDialog(context);
                      if (mounted) setState(_reload);
                    },
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Add Link to Link Repo'),
                  ),
                ],
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: links.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final link = links[index];
            return Card(
              color: AppColors.surface,
              child: ListTile(
                leading: Icon(_iconFor(link.type), color: AppColors.accent),
                title: Text(
                  link.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  link.url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
                onTap: () => _openLink(link),
                trailing: IconButton(
                  tooltip: 'Delete link',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(link),
                ),
              ),
            );
          },
        );
      },
    ),
  );

  Future<void> _confirmDelete(AutoLinkSource link) async {
    final remove = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete saved link?'),
        content: Text('Remove "${link.title}" from Link Repo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (remove == true) await _delete(link);
  }
}

IconData _iconFor(AutoLinkType type) => switch (type) {
  AutoLinkType.m3u => Icons.playlist_play_rounded,
  AutoLinkType.bdixDir => Icons.folder_open_rounded,
  AutoLinkType.directVideo => Icons.movie_outlined,
  AutoLinkType.webSniffer => Icons.language_rounded,
};

class _AutoPlaylistScreen extends StatefulWidget {
  const _AutoPlaylistScreen({required this.source, required this.service});

  final AutoLinkSource source;
  final AutoRepoService service;

  @override
  State<_AutoPlaylistScreen> createState() => _AutoPlaylistScreenState();
}

class _AutoPlaylistScreenState extends State<_AutoPlaylistScreen> {
  late final Future<List<AutoPlayableLink>> _entries = widget.service.loadM3u(
    widget.source.url,
  );

  @override
  Widget build(BuildContext context) =>
      _PlayableListScreen(title: widget.source.title, entries: _entries);
}

class _AutoDirectoryScreen extends StatefulWidget {
  const _AutoDirectoryScreen({
    required this.title,
    required this.url,
    required this.service,
  });

  final String title;
  final String url;
  final AutoRepoService service;

  @override
  State<_AutoDirectoryScreen> createState() => _AutoDirectoryScreenState();
}

class _AutoDirectoryScreenState extends State<_AutoDirectoryScreen> {
  late final Future<List<AutoPlayableLink>> _entries = widget.service
      .loadDirectory(widget.url);

  void _open(AutoPlayableLink entry) {
    if (AutoRepoService.detectType(entry.url) == AutoLinkType.directVideo) {
      _play(context, entry.title, entry.url);
      return;
    }
    if (AutoRepoService.detectType(entry.url) == AutoLinkType.bdixDir) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => _AutoDirectoryScreen(
            title: entry.title,
            url: entry.url,
            service: widget.service,
          ),
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _AutoWebSnifferScreen(
          source: AutoLinkSource(
            id: entry.url,
            repoId: AutoRepoService.repoId,
            title: entry.title,
            url: entry.url,
            type: AutoLinkType.webSniffer,
            createdAt: DateTime.now(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _PlayableListScreen(
    title: widget.title,
    entries: _entries,
    onOpen: _open,
  );
}

class _PlayableListScreen extends StatelessWidget {
  const _PlayableListScreen({
    required this.title,
    required this.entries,
    this.onOpen,
  });

  final String title;
  final Future<List<AutoPlayableLink>> entries;
  final void Function(AutoPlayableLink entry)? onOpen;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: Text(title)),
    body: FutureBuilder<List<AutoPlayableLink>>(
      future: entries,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Could not open link: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(child: Text('No playable items found.'));
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: const Icon(Icons.play_circle_outline),
              title: Text(item.title),
              subtitle: Text(
                item.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: onOpen == null
                  ? () => _play(context, item.title, item.url)
                  : () => onOpen!(item),
            );
          },
        );
      },
    ),
  );
}

void _play(BuildContext context, String title, String url) {
  final episode = Episode(id: url, title: title, number: 1, url: url);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => PlayerScreen(
        sourceId: 'auto_link:repo',
        showTitle: title,
        episodes: [episode],
        resume: sl<ResumeStore>(),
        resolveSources: (_) async => [VideoSource(url: url, label: title)],
      ),
    ),
  );
}

class _AutoWebSnifferScreen extends StatefulWidget {
  const _AutoWebSnifferScreen({required this.source});

  final AutoLinkSource source;

  @override
  State<_AutoWebSnifferScreen> createState() => _AutoWebSnifferScreenState();
}

class _AutoWebSnifferScreenState extends State<_AutoWebSnifferScreen> {
  late final WebViewController _controller;
  final Set<String> _streams = {};
  String? _selected;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('AutoLinkSniffer', onMessageReceived: _onSniffed)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => _installSniffer(),
          onNavigationRequest: (request) {
            if (_isStream(request.url)) {
              _addStream(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.source.url));
  }

  void _installSniffer() {
    _controller.runJavaScript(r'''
      (() => {
        if (window.__autoLinkSnifferInstalled) return;
        window.__autoLinkSnifferInstalled = true;
        const scan = () => {
          const urls = performance.getEntriesByType('resource')
            .map(entry => entry.name)
            .filter(url => /\.(m3u8?|mp4|mkv|webm|mov)(\?|#|$)/i.test(url));
          if (urls.length) AutoLinkSniffer.postMessage(JSON.stringify(urls));
        };
        new MutationObserver(scan).observe(document.documentElement,
          {childList: true, subtree: true, attributes: true});
        setInterval(scan, 1500);
      })();
    ''');
  }

  void _onSniffed(JavaScriptMessage message) {
    try {
      final parsed = jsonDecode(message.message);
      if (parsed is! List) return;
      for (final value in parsed) {
        if (value is String && _isStream(value)) _addStream(value);
      }
    } on FormatException {
      // Ignore malformed page messages; keep the WebView usable.
    }
  }

  bool _isStream(String url) => RegExp(
    r'\.(m3u8?|mp4|mkv|webm|mov)(\?|#|$)',
    caseSensitive: false,
  ).hasMatch(url);

  void _addStream(String url) {
    if (!_streams.add(url)) return;
    setState(() => _selected = url);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.source.title)),
    body: WebViewWidget(controller: _controller),
    floatingActionButton: _selected == null
        ? null
        : FloatingActionButton.extended(
            backgroundColor: AppColors.accent,
            onPressed: () => _play(context, widget.source.title, _selected!),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
          ),
  );
}
