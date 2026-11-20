import 'package:flutter/foundation.dart';
import 'navigation_model.dart';

/// Manages navigation state for Infinity Loop.
///
/// Features:
/// - Custom bottom navigation bar
/// - Drag-drop reordering
/// - Route management
/// - Navigation history
/// - Deep linking support
class NavigationManager extends ChangeNotifier {
  final List<NavItem> _items = NavItem.defaultItems();
  NavigationOrder _order = NavigationOrder();

  // Settings
  NavigationSettings _settings = NavigationSettings.defaults();

  // State
  int _currentIndex = 0;
  final List<String> _routeHistory = [];

  NavigationManager();

  // Getters
  List<NavItem> get items => _items;
  List<NavItem> get visibleItems => _items.where((i) => i.isVisible).toList();
  NavigationOrder get order => _order;
  NavigationSettings get settings => _settings;
  int get currentIndex => _currentIndex;
  List<String> get routeHistory => _routeHistory;

  /// Get nav item at index.
  NavItem? getItemAt(int index) {
    if (index < 0 || index >= _items.length) return null;
    return _items[index];
  }

  /// Get nav item by ID.
  NavItem? getItemById(String id) {
    try {
      return _items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get index of nav item by ID.
  int? getIndexById(String id) {
    try {
      return _items.indexWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Change current index with validation.
  void changeIndex(int newIndex) {
    if (newIndex < 0 || newIndex >= _items.length) return;
    if (_currentIndex == newIndex) return;

    _currentIndex = newIndex;
    notifyListeners();
  }

  /// Navigate to route.
  void navigateTo(String routeName, {Map<String, dynamic>? arguments}) {
    // Store in history
    _routeHistory.add(routeName);

    // If route is a nav item, update index
    final index = _items.indexWhere((item) => item.route == routeName);
    if (index != -1) {
      _currentIndex = index;
    }

    notifyListeners();
  }

  /// Go back in navigation history.
  void goBack() {
    if (_routeHistory.isEmpty) return;

    _routeHistory.removeLast();

    // Restore previous index if needed
    if (_routeHistory.isNotEmpty) {
      final previousRoute = _routeHistory.last;
      final index = _items.indexWhere((item) => item.route == previousRoute);
      if (index != -1) {
        _currentIndex = index;
      }
    }

    notifyListeners();
  }

  /// Reset navigation history.
  void resetHistory() {
    _routeHistory.clear();
    notifyListeners();
  }

  /// Reorder items by dragging.
  void reorderItems(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;
    if (fromIndex < 0 || fromIndex >= _items.length) return;
    if (toIndex < 0 || toIndex >= _items.length) return;

    // Reorder items
    final item = _items.removeAt(fromIndex);
    _items.insert(toIndex, item);

    // Update order
    _order = _order.copyWith(
      itemOrder: _items.map((i) => i.id).toList(),
      lastUpdated: DateTime.now(),
    );

    notifyListeners();
  }

  /// Update nav items.
  void updateItems(List<NavItem> newItems) {
    _items.clear();
    _items.addAll(newItems);

    // Update order
    _order = _order.copyWith(
      itemOrder: _items.map((i) => i.id).toList(),
      lastUpdated: DateTime.now(),
    );

    notifyListeners();
  }

  /// Update settings.
  void updateSettings(NavigationSettings newSettings) {
    _settings = newSettings;
    notifyListeners();
  }

  /// Load navigation data from storage.
  Future<void> loadNavigation() async {
    // TODO: Load from Hive storage
    notifyListeners();
  }

  /// Save navigation data to storage.
  Future<void> saveNavigation() async {
    // TODO: Save to Hive storage
  }

  /// Get current route.
  String? getCurrentRoute() {
    final item = getItemAt(_currentIndex);
    return item?.route;
  }

  /// Check if route is in history.
  bool hasRouteInHistory(String route) {
    return _routeHistory.contains(route);
  }

  /// Get previous route.
  String? getPreviousRoute() {
    if (_routeHistory.length < 2) return null;
    return _routeHistory[_routeHistory.length - 2];
  }

  /// Check if can go back.
  bool get canGoBack => _routeHistory.length > 1;

  @override
  void dispose() {
    // TODO: Save navigation on dispose
    super.dispose();
  }
}
