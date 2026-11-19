import 'package:material_ui/material_ui.dart';
import 'navigation_model.dart';

/// Custom route observer for tracking navigation.
class CustomRouteObserver extends RouteObserver<PageRoute> {
  final List<String> _history = [];

  List<String> get history => List.unmodifiable(_history);

  void push(String routeName, BuildContext context) {
    _history.add(routeName);
    Navigator.of(context).pushNamed(routeName);
  }

  void pop(BuildContext context) {
    if (_history.isNotEmpty) {
      _history.removeLast();
      Navigator.of(context).pop();
    }
  }

  void clear() => _history.clear();

  int get historyLength => _history.length;

  bool get canPop => _history.length > 1;
}

/// Custom route guard for route validation.
class RouteGuard {
  final String routeName;
  final bool Function(BuildContext context) condition;
  final String redirectRoute;

  const RouteGuard({
    required this.routeName,
    required this.condition,
    required this.redirectRoute,
  });

  /// Check if route is accessible.
  static RouteGuard authenticated(String routeName, String redirectRoute) {
    return RouteGuard(
      routeName: routeName,
      condition: (context) => true, // Replace with auth check
      redirectRoute: redirectRoute,
    );
  }

  /// Check if route requires content ID.
  static RouteGuard requiresContentId(String routeName, String redirectRoute) {
    return RouteGuard(
      routeName: routeName,
      condition: (context) {
        final args = ModalRoute.of(context)?.settings.arguments
            as Map<String, dynamic>?;
        return args != null && args.containsKey('contentId');
      },
      redirectRoute: redirectRoute,
    );
  }
}

/// Deep link parser for handling deep links.
class DeepLinkParser {
  final Map<String, DeepLinkConfig> _configs = {};

  DeepLinkParser() {
    _registerDefaultConfigs();
  }

  void _registerDefaultConfigs() {
    _configs['/content/:id'] = DeepLinkConfig.content(':id');
    _configs['/content/:id/episode/:episodeId'] =
        DeepLinkConfig.episode(':id', ':episodeId');
  }

  /// Register deep link config.
  void registerConfig(DeepLinkConfig config) {
    _configs[config.pattern] = config;
  }

  /// Parse deep link and return route info.
  Map<String, dynamic>? parse(String deepLink) {
    for (final entry in _configs.entries) {
      final pattern = entry.key;
      final config = entry.value;

      if (_matchPattern(pattern, deepLink)) {
        return _extractParameters(pattern, deepLink, config);
      }
    }

    return null;
  }

  /// Check if pattern matches deep link.
  bool _matchPattern(String pattern, String deepLink) {
    final patternParts = pattern.split('/');
    final deepLinkParts = deepLink.split('/');

    if (patternParts.length != deepLinkParts.length) return false;

    for (var i = 0; i < patternParts.length; i++) {
      if (patternParts[i].startsWith(':')) continue;
      if (patternParts[i] != deepLinkParts[i]) return false;
    }

    return true;
  }

  /// Extract parameters from deep link.
  Map<String, dynamic>? _extractParameters(
    String pattern,
    String deepLink,
    DeepLinkConfig config,
  ) {
    final patternParts = pattern.split('/');
    final deepLinkParts = deepLink.split('/');

    final params = <String, dynamic>{};

    for (var i = 0; i < patternParts.length; i++) {
      if (patternParts[i].startsWith(':')) {
        final paramName = patternParts[i].substring(1);
        params[paramName] = deepLinkParts[i];
      }
    }

    return {
      'routeName': config.routeName,
      'parameters': params,
    };
  }
}

/// Custom route builder.
class CustomRouteBuilder {
  static Route<void> build(RouteSettings settings) {
    final name = settings.name ?? '/';

    switch (name) {
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Container(
            // HomeScreen placeholder
          ),
        );

      case '/search':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Container(
            // SearchScreen placeholder
          ),
        );

      case '/schedule':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Container(
            // ScheduleScreen placeholder
          ),
        );

      case '/favorites':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Container(
            // FavoritesScreen placeholder
          ),
        );

      case '/profile':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Container(
            // ProfileScreen placeholder
          ),
        );

      case '/player':
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Container(
            // PlayerScreen placeholder
          ),
        );

      default:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) => Scaffold(
            body: Center(
              child: Text('Unknown route: $name'),
            ),
          ),
        );
    }
  }
}

/// Route argument parser.
class RouteArgs {
  final Map<String, dynamic>? args;

  const RouteArgs([this.args]);

  T? get<T>(String key) {
    if (args == null) return null;
    return args![key] as T?;
  }

  String? getString(String key) => get<String>(key);

  int? getInt(String key) => get<int>(key);

  bool? getBool(String key) => get<bool>(key);

  Map<String, dynamic>? getMap(String key) => get<Map<String, dynamic>>(key);

  /// Get content ID.
  String? get contentId => getString('contentId');

  /// Get episode ID.
  String? get episodeId => getString('episodeId');

  /// Get repository ID.
  String? get repositoryId => getString('repositoryId');
}

/// Route settings extension.
extension RouteSettingsExt on RouteSettings {
  RouteArgs get args => RouteArgs(arguments as Map<String, dynamic>?);
}
