import 'package:material_ui/material_ui.dart';
import '../navigation/tv_focus_support.dart';
import '../navigation/navigation_model.dart';
import 'package:flutter/services.dart';

/// TV-focused focusable container with haptic feedback.
class TVFocusableContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onFocus;
  final VoidCallback? onBlur;
  final Color? focusColor;
  final double? focusElevation;
  final double? blurRadius;
  final double? spreadRadius;
  final VoidCallback? onFocusedPressed;

  const TVFocusableContainer({
    super.key,
    required this.child,
    this.onFocus,
    this.onBlur,
    this.focusColor,
    this.focusElevation = 8,
    this.blurRadius = 16,
    this.spreadRadius = 4,
    this.onFocusedPressed,
  });

  @override
  State<TVFocusableContainer> createState() => _TVFocusableContainerState();
}

class _TVFocusableContainerState extends State<TVFocusableContainer> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final focusColor = widget.focusColor ?? Theme.of(context).colorScheme.primary;

    return Focus(
      onFocusChange: (hasFocus) {
        setState(() => _hasFocus = hasFocus);
        if (hasFocus) {
          widget.onFocus?.call();
          // Haptic feedback on focus
          HapticFeedback.heavyImpact();
        } else {
          widget.onBlur?.call();
        }
      },
      child: Listener(
        onPointerDown: (details) {
          if (_hasFocus && widget.onFocusedPressed != null) {
            widget.onFocusedPressed!();
            HapticFeedback.mediumImpact();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: _hasFocus
                ? Border.all(
                    color: focusColor,
                    width: 2,
                  )
                : null,
            boxShadow: _hasFocus
                ? [
                    BoxShadow(
                      color: focusColor.withValues(alpha: 0.3),
                      blurRadius: widget.blurRadius ?? 16,
                      spreadRadius: widget.spreadRadius ?? 4,
                      offset: Offset(0, widget.focusElevation ?? 8),
                    ),
                  ]
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// TV-focused button with haptic feedback.
class TVButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color? focusColor;
  final double? focusElevation;

  const TVButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.focusColor,
    this.focusElevation = 8,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusableContainer(
      focusColor: focusColor,
      focusElevation: focusElevation,
      onFocusedPressed: onPressed,
      child: child,
    );
  }
}

/// TV-focused grid layout with focus management.
class TVGrid extends StatelessWidget {
  final List<Widget> items;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final Axis scrollDirection;
  final FocusNode? focusNode;

  const TVGrid({
    super.key,
    required this.items,
    this.crossAxisCount = 4,
    this.crossAxisSpacing = 16,
    this.mainAxisSpacing = 16,
    this.scrollDirection = Axis.vertical,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusTraversalGroup(
      child: ListView.builder(
        scrollDirection: scrollDirection,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TVFocusableContainer(
            child: items[index],
          );
        },
      ),
    );
  }
}

/// TV-focused list layout with focus management.
class TVList extends StatelessWidget {
  final List<Widget> items;
  final Axis scrollDirection;
  final FocusNode? focusNode;

  const TVList({
    super.key,
    required this.items,
    this.scrollDirection = Axis.vertical,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusTraversalGroup(
      child: ListView.builder(
        scrollDirection: scrollDirection,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TVFocusableContainer(
            child: items[index],
          );
        },
      ),
    );
  }
}

/// TV-focused category row (Leanback style).
class TVCategoryRow extends StatelessWidget {
  final String title;
  final List<Widget> items;
  final VoidCallback? onRowSelected;
  final FocusNode? focusNode;

  const TVCategoryRow({
    super.key,
    required this.title,
    required this.items,
    this.onRowSelected,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
        // Items Row
        TVGrid(
          items: items,
          crossAxisCount: 6,
          scrollDirection: Axis.horizontal,
        ),
      ],
    );
  }
}

/// TV-focused media card (Leanback style).
class TVMediaCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? imageUrl;
  final VoidCallback? onPressed;
  final Color? focusColor;

  const TVMediaCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.onPressed,
    this.focusColor,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusableContainer(
      focusColor: focusColor,
      onFocusedPressed: onPressed,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              // Image placeholder
              if (imageUrl != null)
                Positioned.fill(
                  child: Image.network(
                    imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.movie, size: 64),
                  ),
                ),
              if (imageUrl == null)
                const Icon(Icons.movie, size: 64, color: Colors.grey),

              // Content overlay
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black87,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TV-focused search bar.
class TVSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onSearch;
  final VoidCallback? onCancel;

  const TVSearchBar({
    super.key,
    required this.controller,
    this.onSearch,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusableContainer(
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 20),
        onSubmitted: (value) => onSearch?.call(),
      ),
    );
  }
}

/// TV-focused navigation bar.
class TVNavigationBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final Function(int) onIndexChanged;
  final Color? focusColor;

  const TVNavigationBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onIndexChanged,
    this.focusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ...List.generate(items.length, (index) => TVFocusableContainer(
            focusColor: focusColor,
            focusElevation: currentIndex == index ? 8 : 2,
            onFocusedPressed: () => onIndexChanged(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getIcon(index),
                    color: currentIndex == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    items[index].label,
                    style: TextStyle(
                      color: currentIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      fontSize: 14,
                      fontWeight: currentIndex == index
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'home':
        return Icons.home;
      case 'home_filled':
        return Icons.home_filled;
      case 'search':
        return Icons.search;
      case 'search_filled':
        return Icons.search; // There is no search_filled typically
      case 'schedule':
        return Icons.schedule;
      case 'schedule_filled':
        return Icons.schedule; // or another icon
      case 'bookmark':
        return Icons.bookmark;
      case 'bookmark_filled':
        return Icons.bookmark;
      case 'person':
        return Icons.person;
      case 'person_filled':
        return Icons.person;
      default:
        return Icons.circle;
    }
  }

  IconData _getIcon(int index) {
    final iconName = currentIndex == index
        ? items[index].selectedIcon
        : items[index].icon;
    return _getIconData(iconName);
  }
}

/// TV-focused page view with swipe navigation.
class TVPageView extends StatelessWidget {
  final List<Widget> pages;
  final int currentIndex;
  final Function(int) onPageChanged;

  const TVPageView({
    super.key,
    required this.pages,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (details) {
        // Handle pointer down
      },
      child: PageView.builder(
        controller: PageController(initialPage: currentIndex),
        itemCount: pages.length,
        itemBuilder: (context, index) => pages[index],
        onPageChanged: onPageChanged,
      ),
    );
  }
}

/// TV-focused bottom sheet.
class TVBottomSheet extends StatelessWidget {
  final Widget child;
  final VoidCallback? onClose;

  const TVBottomSheet({
    super.key,
    required this.child,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: TVFocusableContainer(
                onFocusedPressed: onClose,
                child: const Icon(Icons.close, size: 32),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

/// TV-focused dialog.
class TVDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final VoidCallback? onClose;

  const TVDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height / 4,
      left: MediaQuery.of(context).size.width / 4,
      right: MediaQuery.of(context).size.width / 4,
      child: TVFocusableContainer(
        focusColor: Theme.of(context).colorScheme.primary,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              content,
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
