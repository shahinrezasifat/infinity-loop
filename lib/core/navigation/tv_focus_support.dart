import 'package:material_ui/material_ui.dart';

/// TV-specific focus traversal group.
class TVFocusTraversalGroup extends StatelessWidget {
  final Widget child;
  final FocusNode? rootNode;
  final TraversalDirection? initialFocus;

  const TVFocusTraversalGroup({
    super.key,
    required this.child,
    this.rootNode,
    this.initialFocus,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: child,
    );
  }
}

/// TV-specific focus node with direction support.
class TVFocusNode extends FocusNode {
  final TraversalDirection? up;
  final TraversalDirection? down;
  final TraversalDirection? left;
  final TraversalDirection? right;

  TVFocusNode({
    this.up,
    this.down,
    this.left,
    this.right,
  });

  /// Create focus node with all directions.
  static TVFocusNode create({
    FocusNode? up,
    FocusNode? down,
    FocusNode? left,
    FocusNode? right,
  }) {
    return TVFocusNode(
      up: up != null ? TraversalDirection.up : null,
      down: down != null ? TraversalDirection.down : null,
      left: left != null ? TraversalDirection.left : null,
      right: right != null ? TraversalDirection.right : null,
    );
  }
}

/// TV-specific focus widget.
class TVFocusWidget extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final FocusNode? up;
  final FocusNode? down;
  final FocusNode? left;
  final FocusNode? right;
  final bool? autofocus;

  const TVFocusWidget({
    super.key,
    required this.child,
    this.focusNode,
    this.up,
    this.down,
    this.left,
    this.right,
    this.autofocus,
  });

  @override
  State<TVFocusWidget> createState() => _TVFocusWidgetState();
}

class _TVFocusWidgetState extends State<TVFocusWidget> {
  late FocusNode _focusNode;
  late TVFocusNode _tvFocusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _tvFocusNode = TVFocusNode.create(
      up: widget.up,
      down: widget.down,
      left: widget.left,
      right: widget.right,
    );
    // _focusNode.context!.focusScope = _tvFocusNode;
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus ?? false,
      child: widget.child,
    );
  }
}

/// TV focus traversal policy.
class TVFocusTraversalPolicy extends WidgetOrderTraversalPolicy {
  final List<FocusNode> nodes;

  TVFocusTraversalPolicy({
    required this.nodes,
  });

  // @override
  // FocusNode? firstFocus(BuildContext context) {
  //   return nodes.isNotEmpty ? nodes.first : null;
  // }

  // @override
  // FocusNode? lastFocus(BuildContext context) {
  //   return nodes.isNotEmpty ? nodes.last : null;
  // }

  // @override
  // FocusNode? focusOrder({
  //   required FocusNode origin,
  //   required TraversalDirection direction,
  // }) {
  //   final index = nodes.indexOf(origin);
  //   if (index == -1) return null;

  //   switch (direction) {
  //     case TraversalDirection.up:
  //       return index > 0 ? nodes[index - 1] : null;
  //     case TraversalDirection.down:
  //       return index < nodes.length - 1 ? nodes[index + 1] : null;
  //     case TraversalDirection.left:
  //       return index > 0 ? nodes[index - 1] : null;
  //     case TraversalDirection.right:
  //       return index < nodes.length - 1 ? nodes[index + 1] : null;
  //   }
  // }
}

/// TV-focused container widget.
class TVFocusedContainer extends StatelessWidget {
  final Widget child;
  final Color focusColor;
  final double focusElevation;
  final double blurRadius;
  final double spreadRadius;

  const TVFocusedContainer({
    super.key,
    required this.child,
    this.focusColor = Colors.blue,
    this.focusElevation = 4,
    this.blurRadius = 10,
    this.spreadRadius = 2,
  });

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        // Handle focus state
      },
      child: Builder(
        builder: (context) {
          final focusNode = Focus.of(context);
          final hasFocus = focusNode.hasFocus;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: hasFocus
                  ? Border.all(
                      color: focusColor,
                      width: 2,
                    )
                  : null,
              boxShadow: hasFocus
                  ? [
                      BoxShadow(
                        color: focusColor.withValues(alpha: 0.3),
                        blurRadius: blurRadius,
                        spreadRadius: spreadRadius,
                        offset: Offset(0, focusElevation),
                      ),
                    ]
                  : null,
            ),
            child: child,
          );
        },
      ),
    );
  }
}

/// TV-focused button widget.
class TVFocusedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final Color focusColor;

  const TVFocusedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.focusColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return TVFocusedContainer(focusColor: focusColor, child: child);
  }
}

/// TV-focused list view.
class TVFocusListView extends StatelessWidget {
  final List<Widget> items;
  final FocusNode? rootNode;
  final Axis scrollDirection;

  const TVFocusListView({
    super.key,
    required this.items,
    this.rootNode,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: ListView.builder(
        scrollDirection: scrollDirection,
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TVFocusedContainer(child: items[index]);
        },
      ),
    );
  }
}
