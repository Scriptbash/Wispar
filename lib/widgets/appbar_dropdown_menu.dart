import 'package:flutter/material.dart';
import '../generated_l10n/app_localizations.dart';

class AppBarDropdownMenu {
  static OverlayEntry? _overlayEntry;

  static void show({
    required BuildContext context,
    required void Function(int) onSelected,
  }) {
    hide();

    final overlay = Overlay.of(context);
    final double topOffset =
        MediaQuery.of(context).padding.top + kToolbarHeight;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bottomInset = MediaQuery.of(context).padding.bottom;

    // Prepare all items as ListTiles
    final List<Widget> items = [
      _buildItem(
        context,
        Icons.swap_vert,
        AppLocalizations.of(context)!.sort,
        0,
        onSelected,
      ),
      _buildItem(
        context,
        Icons.tune,
        AppLocalizations.of(context)!.createCustomFeed,
        1,
        onSelected,
      ),
      _buildItem(
        context,
        Icons.layers_clear_outlined,
        AppLocalizations.of(context)!.viewHiddenArticles,
        2,
        onSelected,
      ),
      _buildItem(
        context,
        Icons.settings_outlined,
        AppLocalizations.of(context)!.settings,
        3,
        onSelected,
      ),
    ];

    final bool useGrid = screenWidth > 600;

    Widget content;

    if (useGrid) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: items.map((item) {
            return SizedBox(
              width: (screenWidth / 2) - 24,
              child: item,
            );
          }).toList(),
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: items,
      );
    }

    final double maxHeight = 300;
    final Widget scrollableContent = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: content,
      ),
    );

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return GestureDetector(
          onTap: hide,
          behavior: HitTestBehavior.translucent,
          child: Material(
            color: Colors.transparent,
            child: Stack(
              children: [
                Positioned(
                  top: topOffset,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    top: false,
                    child: Material(
                      elevation: 8,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                      child: Container(
                        width: screenWidth,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(16),
                          ),
                        ),
                        child: scrollableContent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  static Widget _buildItem(
    BuildContext context,
    IconData icon,
    String label,
    int value,
    void Function(int) onSelected,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          onSelected(value);
          hide();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon),
              const SizedBox(width: 16),
              Expanded(child: Text(label)),
            ],
          ),
        ),
      ),
    );
  }

  static void hide() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
