import 'package:flutter/material.dart';
import 'package:wispar/widgets/publication_card/publication_card.dart';

class CardSwipeBackground extends StatelessWidget {
  final TextDirection direction;
  final SwipeAction action;
  final SwipeAction oppositeAction;
  final double dragExtent;
  final double dismissThreshold;
  final bool isLiked;
  final bool? isHidden;
  final bool showHideBtn;

  const CardSwipeBackground({
    super.key,
    required this.direction,
    required this.action,
    required this.oppositeAction,
    required this.dragExtent,
    required this.dismissThreshold,
    required this.isLiked,
    this.isHidden,
    this.showHideBtn = false,
  });

  double _getIconOpacity() {
    const double maxOpacityAt = 0.2;
    return (dragExtent.abs() / maxOpacityAt).clamp(0.0, 1.0);
  }

  double _getIconSize() {
    const double baseSize = 30.0;
    const double maxSize = 48.0;
    final scaleFactor = (dragExtent.abs() / dismissThreshold).clamp(0.0, 1.0);
    return baseSize + (maxSize - baseSize) * scaleFactor;
  }

  IconData _getIconForAction(SwipeAction action) {
    switch (action) {
      case SwipeAction.hide:
        return isHidden == true
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined;
      case SwipeAction.favorite:
        return isLiked ? Icons.favorite : Icons.favorite_border;
      case SwipeAction.sendToZotero:
        return Icons.book_outlined;
      case SwipeAction.share:
        return Icons.share_outlined;
      case SwipeAction.none:
    }
    return Icons.do_not_disturb_on_outlined;
  }

  Color _getColorForAction(BuildContext context, SwipeAction action) {
    final theme = Theme.of(context);
    switch (action) {
      case SwipeAction.hide:
        return Colors.grey;
      case SwipeAction.favorite:
      case SwipeAction.sendToZotero:
      case SwipeAction.share:
        return theme.colorScheme.primary;
      case SwipeAction.none:
    }
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    if (action == SwipeAction.none) return const SizedBox.shrink();
    if (action == SwipeAction.hide && showHideBtn == false) {
      return const SizedBox.shrink();
    }
    final bool isOppositeVisible =
        direction == TextDirection.rtl ? dragExtent < 0 : dragExtent > 0;

    if (isOppositeVisible) return const SizedBox.shrink();

    final alignment = direction == TextDirection.rtl
        ? Alignment.centerLeft
        : Alignment.centerRight;

    final iconPadding = direction == TextDirection.rtl
        ? const EdgeInsets.only(left: 24.0)
        : const EdgeInsets.only(right: 24.0);

    final iconOpacity = _getIconOpacity();
    final int iconAlpha = (iconOpacity * 255).round();
    final iconColor = _getColorForAction(context, action).withAlpha(iconAlpha);
    final iconSize = _getIconSize();

    return Positioned.fill(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Align(
          alignment: alignment,
          child: Padding(
            padding: iconPadding,
            child: Icon(
              _getIconForAction(action),
              color: iconColor,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
