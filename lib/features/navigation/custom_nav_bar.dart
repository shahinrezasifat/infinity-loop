import 'package:material_ui/material_ui.dart';
import '../../core/navigation/navigation_manager.dart';
import '../../core/navigation/navigation_model.dart';

/// Draggable bottom navigation bar with reordering support.
class CustomNavigationBar extends StatelessWidget {
  final NavigationManager manager;
  final Function(int)? onIndexChanged;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final double? itemHeight;
  final bool? showLabels;

  const CustomNavigationBar({
    super.key,
    required this.manager,
    this.onIndexChanged,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.itemHeight,
    this.showLabels,
  });

  @override
  Widget build(BuildContext context) {
    final items = manager.visibleItems;
    final currentIndex = manager.currentIndex;
    final settings = manager.settings;

    final bg =
        backgroundColor ??
        Theme.of(context).bottomAppBarTheme.color ??
        Theme.of(context).colorScheme.surface;

    return Container(
      height: itemHeight ?? settings.itemHeight,
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          ...List.generate(
            items.length,
            (index) => _NavItemItem(
              item: items[index],
              currentIndex: currentIndex,
              index: index,
              manager: manager,
              showLabels:
                  showLabels ??
                  (settings.showLabels && !settings.showIconsOnly),
              selectedItemColor: selectedItemColor ?? settings.selectedColor,
              unselectedItemColor:
                  unselectedItemColor ?? settings.unselectedColor,
              enableDragDrop: settings.enableDragDrop,
              onIndexChanged: onIndexChanged ?? (i) => manager.changeIndex(i),
              onDragEnd: (from, to) => manager.reorderItems(from, to),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual navigation item with drag support.
class _NavItemItem extends StatefulWidget {
  final NavItem item;
  final int currentIndex;
  final int index;
  final NavigationManager manager;
  final bool showLabels;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final bool enableDragDrop;
  final Function(int) onIndexChanged;
  final Function(int, int) onDragEnd;

  const _NavItemItem({
    required this.item,
    required this.currentIndex,
    required this.index,
    required this.manager,
    required this.showLabels,
    required this.selectedItemColor,
    required this.unselectedItemColor,
    required this.enableDragDrop,
    required this.onIndexChanged,
    required this.onDragEnd,
  });

  @override
  State<_NavItemItem> createState() => __NavItemItemState();
}

class __NavItemItemState extends State<_NavItemItem> {
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.index == widget.currentIndex;
    final canDrag =
        widget.enableDragDrop && widget.manager.visibleItems.length > 1;

    return Listener(
      onPointerDown: (details) {
        if (canDrag) {
          // Start drag
          setState(() => _isDragging = true);
        }
      },
      onPointerUp: (details) {
        if (_isDragging) {
          setState(() => _isDragging = false);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onIndexChanged(widget.index),
        onPanEnd: (details) {
          if (canDrag && _isDragging) {
            // Calculate drop position based on drag delta
            final xPos = details.globalPosition.dx;
            final itemWidth =
                MediaQuery.of(context).size.width /
                widget.manager.visibleItems.length;
            final dropIndex = (xPos / itemWidth).toInt().clamp(
              0,
              widget.manager.visibleItems.length - 1,
            );

            if (dropIndex != widget.index) {
              widget.onDragEnd(widget.index, dropIndex);
            }
            setState(() => _isDragging = false);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.selectedItemColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getIcon(isSelected),
                color: isSelected
                    ? widget.selectedItemColor
                    : widget.unselectedItemColor,
                size: 24,
              ),
              if (widget.showLabels)
                Text(
                  widget.item.label,
                  style: TextStyle(
                    color: isSelected
                        ? widget.selectedItemColor
                        : widget.unselectedItemColor,
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              if (widget.item.badge != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      widget.item.badge!,
                      style: const TextStyle(color: Colors.white, fontSize: 8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon(bool isSelected) {
    final name = isSelected ? widget.item.selectedIcon : widget.item.icon;
    return _navigationIcon(name);
  }
}

/// Navigation destination widget with custom styling.
class NavDestination extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final bool showLabels;

  const NavDestination({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.selectedItemColor,
    required this.unselectedItemColor,
    required this.showLabels,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIcon(),
              color: isSelected ? selectedItemColor : unselectedItemColor,
              size: 24,
            ),
            if (showLabels)
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected ? selectedItemColor : unselectedItemColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            if (item.badge != null)
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  item.badge!,
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getIcon() {
    final name = isSelected ? item.selectedIcon : item.icon;
    return _navigationIcon(name);
  }
}

IconData _navigationIcon(String name) {
  switch (name) {
    case 'home':
      return Icons.home_outlined;
    case 'home_filled':
      return Icons.home;
    case 'search':
      return Icons.search;
    case 'search_filled':
      return Icons.search;
    case 'schedule':
      return Icons.schedule_outlined;
    case 'schedule_filled':
      return Icons.schedule;
    case 'bookmark':
      return Icons.bookmark_border;
    case 'bookmark_filled':
      return Icons.bookmark;
    case 'person':
      return Icons.person_outline;
    case 'person_filled':
      return Icons.person;
    default:
      return Icons.circle_outlined;
  }
}
