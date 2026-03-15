import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:flutter/services.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

class PdfControlOverlay extends StatefulWidget {
  final PdfViewerController controller;
  final PdfTextSearcher? textSearcher;
  final bool overlayVisible;

  const PdfControlOverlay({
    super.key,
    required this.controller,
    required this.textSearcher,
    required this.overlayVisible,
  });

  @override
  State<PdfControlOverlay> createState() => _PdfControlOverlayState();
}

class _PdfControlOverlayState extends State<PdfControlOverlay> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 28,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        opacity: widget.overlayVisible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !widget.overlayVisible,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isSearching && widget.textSearcher != null)
                    _buildSearchBar(),
                  _buildBottomBar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.enter, shift: true):
                      () {
                    widget.textSearcher?.goToPrevMatch();
                  },
                  const SingleActivator(LogicalKeyboardKey.enter): () {
                    widget.textSearcher?.goToNextMatch();
                  },
                },
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) {
                    if (widget.textSearcher?.matches.isNotEmpty ?? false) {
                      widget.textSearcher?.goToNextMatch();
                      _searchFocusNode.requestFocus();
                    }
                  },
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.searchPlaceholder,
                    hintStyle:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                    border: InputBorder.none,
                  ),
                  onChanged: (v) => v.isEmpty
                      ? widget.textSearcher?.resetTextSearch()
                      : widget.textSearcher
                          ?.startTextSearch(v, caseInsensitive: true),
                ),
              ),
            ),
            if (widget.textSearcher?.matches.isNotEmpty ?? false) ...[
              Text(
                '${(widget.textSearcher!.currentIndex ?? 0) + 1}/${widget.textSearcher!.matches.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context)!.previousMatch,
                icon: const Icon(Icons.keyboard_arrow_up, color: Colors.white),
                onPressed: () => widget.textSearcher?.goToPrevMatch(),
              ),
              IconButton(
                icon:
                    const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                tooltip: AppLocalizations.of(context)!.nextMatch,
                onPressed: () => widget.textSearcher?.goToNextMatch(),
              ),
            ],
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              tooltip: AppLocalizations.of(context)!.cancel,
              onPressed: () {
                setState(() => _isSearching = false);
                widget.textSearcher?.resetTextSearch();
                _searchController.clear();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.zoomOut,
            onPressed: () => widget.controller.zoomDown(),
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.zoomIn,
            onPressed: () => widget.controller.zoomUp(),
          ),
          const VerticalDivider(color: Colors.white54, indent: 8, endIndent: 8),
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.goToFirstPage,
            onPressed: () => widget.controller.goToPage(pageNumber: 1),
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white),
            tooltip: AppLocalizations.of(context)!.goToLastPage,
            onPressed: () => widget.controller.goToPage(
              pageNumber: widget.controller.document.pages.length,
            ),
          ),
          const VerticalDivider(color: Colors.white54, indent: 8, endIndent: 8),
          IconButton(
            icon: Icon(_isSearching ? Icons.search_off : Icons.search,
                color: Colors.white),
            tooltip: AppLocalizations.of(context)!.search,
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                widget.textSearcher?.resetTextSearch();
                _searchController.clear();
              }
              if (_isSearching) {
                Future.delayed(Duration.zero, () {
                  _searchFocusNode.requestFocus();
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
