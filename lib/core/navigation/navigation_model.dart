import 'package:material_ui/material_ui.dart';
import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'navigation_model.g.dart';

/// Represents a navigation item in the bottom navigation bar.
@JsonSerializable()
class NavItem extends Equatable {
  /// Unique identifier for the navigation item.
  final String id;

  /// Display label for the navigation item.
  final String label;

  /// Icon to display (unselected state).
  final String icon;

  /// Icon to display (selected state).
  final String selectedIcon;

  /// Route name to navigate to.
  final String route;

  /// Route arguments (optional).
  final Map<String, dynamic>? arguments;

  /// Order index for sorting.
  final int sortOrder;

  /// Whether the item is visible.
  final bool isVisible;

  /// Custom badge text (optional).
  final String? badge;

  const NavItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.arguments,
    this.sortOrder = 0,
    this.isVisible = true,
    this.badge,
  });

  /// Create a copy with updated fields.
  NavItem copyWith({
    String? id,
    String? label,
    String? icon,
    String? selectedIcon,
    String? route,
    Map<String, dynamic>? arguments,
    int? sortOrder,
    bool? isVisible,
    String? badge,
  }) {
    return NavItem(
      id: id ?? this.id,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      selectedIcon: selectedIcon ?? this.selectedIcon,
      route: route ?? this.route,
      arguments: arguments ?? this.arguments,
      sortOrder: sortOrder ?? this.sortOrder,
      isVisible: isVisible ?? this.isVisible,
      badge: badge ?? this.badge,
    );
  }

  /// Create default navigation items.
  static List<NavItem> defaultItems() {
    return [
      NavItem(
        id: 'home',
        label: 'Home',
        icon: 'home',
        selectedIcon: 'home_filled',
        route: '/home',
        sortOrder: 0,
      ),
      NavItem(
        id: 'search',
        label: 'Search',
        icon: 'search',
        selectedIcon: 'search_filled',
        route: '/search',
        sortOrder: 1,
      ),
      NavItem(
        id: 'schedule',
        label: 'Schedule',
        icon: 'schedule',
        selectedIcon: 'schedule_filled',
        route: '/schedule',
        sortOrder: 2,
      ),
      NavItem(
        id: 'favorites',
        label: 'My List',
        icon: 'bookmark',
        selectedIcon: 'bookmark_filled',
        route: '/favorites',
        sortOrder: 3,
      ),
      NavItem(
        id: 'profile',
        label: 'Profile',
        icon: 'person',
        selectedIcon: 'person_filled',
        route: '/profile',
        sortOrder: 4,
      ),
    ];
  }

  factory NavItem.fromJson(Map<String, dynamic> json) =>
      _$NavItemFromJson(json);

  Map<String, dynamic> toJson() => _$NavItemToJson(this);

  @override
  List<Object?> get props => [
    id,
    label,
    icon,
    selectedIcon,
    route,
    arguments,
    sortOrder,
    isVisible,
    badge,
  ];
}

/// Configuration for route navigation.
class RouteConfig {
  final String name;
  final String routeName;
  final Function builder;
  final Map<String, dynamic>? arguments;

  const RouteConfig({
    required this.name,
    required this.routeName,
    required this.builder,
    this.arguments,
  });

  /// Create route configuration from route name.
  static RouteConfig fromRoute(String routeName) {
    return RouteConfig(
      name: routeName,
      routeName: routeName,
      builder: (context) => Container(),
    );
  }

  /// Check if route matches.
  bool matches(String routeName) => this.routeName == routeName;
}

/// Navigation order settings.
@JsonSerializable()
class NavigationOrder extends Equatable {
  /// List of nav item IDs in order.
  final List<String> itemOrder;

  /// Current selected index.
  final int selectedIndex;

  /// When order was last updated.
  final DateTime? lastUpdated;

  NavigationOrder({
    this.itemOrder = const [],
    this.selectedIndex = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Create a copy with updated fields.
  NavigationOrder copyWith({
    List<String>? itemOrder,
    int? selectedIndex,
    DateTime? lastUpdated,
  }) {
    return NavigationOrder(
      itemOrder: itemOrder ?? this.itemOrder,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get nav item order map (id -> index).
  Map<String, int> get orderMap {
    final map = <String, int>{};
    for (var i = 0; i < itemOrder.length; i++) {
      map[itemOrder[i]] = i;
    }
    return map;
  }

  /// Check if item is at position.
  bool isItemAtPosition(String itemId, int position) {
    if (position < 0 || position >= itemOrder.length) return false;
    return itemOrder[position] == itemId;
  }

  /// Move item from one position to another.
  NavigationOrder moveItem(String fromId, String toId) {
    final newList = List<String>.from(itemOrder);
    final fromIndex = newList.indexOf(fromId);
    final toIndex = newList.indexOf(toId);

    if (fromIndex == -1 || toIndex == -1) return this;

    // Remove from old position
    newList.removeAt(fromIndex);

    // Adjust toIndex if from was before to
    if (fromIndex < toIndex) {
      newList.insert(toIndex - 1, fromId);
    } else {
      newList.insert(toIndex, fromId);
    }

    return copyWith(itemOrder: newList, lastUpdated: DateTime.now());
  }

  factory NavigationOrder.fromJson(Map<String, dynamic> json) =>
      _$NavigationOrderFromJson(json);

  Map<String, dynamic> toJson() => _$NavigationOrderToJson(this);

  @override
  List<Object?> get props => [itemOrder, selectedIndex, lastUpdated];
}

/// Deep link configuration.
class DeepLinkConfig {
  final String pattern;
  final String routeName;
  final List<String> parameters;

  const DeepLinkConfig({
    required this.pattern,
    required this.routeName,
    this.parameters = const [],
  });

  /// Create deep link config for content.
  static DeepLinkConfig content(String id) {
    return DeepLinkConfig(
      pattern: '/content/$id',
      routeName: '/content',
      parameters: ['id'],
    );
  }

  /// Create deep link config for episode.
  static DeepLinkConfig episode(String contentId, String episodeId) {
    return DeepLinkConfig(
      pattern: '/content/$contentId/episode/$episodeId',
      routeName: '/player',
      parameters: ['contentId', 'episodeId'],
    );
  }
}

/// Navigation settings for the app.
class NavigationSettings extends Equatable {
  final bool showLabels;
  final bool showIconsOnly;
  final double itemHeight;
  final Color selectedColor;
  final Color unselectedColor;
  final bool enableDragDrop;
  final bool enableAnimations;
  final int animationDurationMs;

  const NavigationSettings({
    this.showLabels = true,
    this.showIconsOnly = false,
    this.itemHeight = 56,
    this.selectedColor = Colors.blue,
    this.unselectedColor = Colors.grey,
    this.enableDragDrop = true,
    this.enableAnimations = true,
    this.animationDurationMs = 300,
  });

  factory NavigationSettings.defaults() => const NavigationSettings();

  NavigationSettings copyWith({
    bool? showLabels,
    bool? showIconsOnly,
    double? itemHeight,
    Color? selectedColor,
    Color? unselectedColor,
    bool? enableDragDrop,
    bool? enableAnimations,
    int? animationDurationMs,
  }) {
    return NavigationSettings(
      showLabels: showLabels ?? this.showLabels,
      showIconsOnly: showIconsOnly ?? this.showIconsOnly,
      itemHeight: itemHeight ?? this.itemHeight,
      selectedColor: selectedColor ?? this.selectedColor,
      unselectedColor: unselectedColor ?? this.unselectedColor,
      enableDragDrop: enableDragDrop ?? this.enableDragDrop,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      animationDurationMs: animationDurationMs ?? this.animationDurationMs,
    );
  }

  @override
  List<Object?> get props => [
    showLabels,
    showIconsOnly,
    itemHeight,
    selectedColor,
    unselectedColor,
    enableDragDrop,
    enableAnimations,
    animationDurationMs,
  ];
}
