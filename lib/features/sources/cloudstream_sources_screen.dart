import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/app_mode.dart';
import '../../core/ui/source_icon_tile.dart';
import '../../core/ui/source_switcher.dart' show cloudStreamIconUrls;
import '../../core/di/injector.dart';
import '../../core/provider/cloudstream_provider.dart';
import '../../core/state/active_source_cubit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/tv/tv_action_chip.dart';
import '../../core/tv/tv_back_button.dart';
import '../../core/tv/tv_focusable.dart';
import '../../core/tv/tv_list_focusable.dart';
import '../../core/tv/tv_text_field.dart';
import '../../core/ui/states.dart';
import 'source_settings_screen.dart';
import 'sources_search_field.dart';
import '../../core/ui/app_dialog.dart';
import '../../l10n/l10n.dart';
import 'auto_link_sources_screen.dart';

part 'cloudstream_sources_screen_phone.dart';
part 'cloudstream_sources_screen_tv.dart';

/// Dedicated CloudStream ecosystem screen — Installed + Repositories in one
/// scroll. Self-contained: [CloudStreamManager] is an `sl` singleton, so the
/// whole body is observed via a single [ListenableBuilder] (no BlocProvider
/// needed).
///
/// Phone and TV share this file (`if (sl<AppMode>().isTv)`); every lifted
/// widget below is copied byte-identical from `sources_screen.dart` /
/// `sources_screen_tv.dart` — only the host screen around them is new.
/// CloudStream itself is Android-only: off Android [CloudStreamManager]'s
/// `repoGroups` is always empty, so both views fall through to their normal
/// empty state ("No CloudStream repos added yet") — matching the old tab.
class CloudStreamSourcesScreen extends StatelessWidget {
  const CloudStreamSourcesScreen({super.key, this.adultOnly = false});

  final bool adultOnly;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: sl<CloudStreamManager>(),
      // NOT const: a const child is a canonicalized instance, so the
      // ListenableBuilder would hand Flutter the identical widget on every
      // notifyListeners() and updateChild would skip the whole subtree — the
      // install/enable state would then only refresh on an unrelated rebuild
      // (scroll / collapse-expand / re-open). A fresh instance lets the manager's
      // notifications actually reach the Install/Installed buttons + counts.
      builder: (context, _) {
        return sl<AppMode>().isTv
            ? _CsTvView(adultOnly: adultOnly)
            : _CsPhoneView(adultOnly: adultOnly);
      },
    );
  }
}

List<CsRepoGroup> _visibleCloudStreamGroups({required bool adultOnly}) {
  return sl<CloudStreamManager>().repoGroups.where((group) {
    final isAdult = isAdultCloudStreamRepoUrl(group.url);
    return adultOnly == isAdult;
  }).toList();
}

Future<void> _setCsDefaultRepo(BuildContext context, CsRepoGroup group) async {
  final manager = sl<CloudStreamManager>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    await manager.setDefaultRepo(group.url);
  } catch (e) {
    if (!context.mounted) return;
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text('Could not set the default repository: $e')),
      );
    return;
  }
  if (!context.mounted) return;
  final sources = manager.defaultRepoSources;
  if (sources.isNotEmpty) {
    context.read<ActiveSourceCubit>().setSource(sources.first.sourceId);
  }
  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(content: Text('${group.name} is now the default Home repo.')),
    );
}
