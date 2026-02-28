import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wispar/services/zotero_api.dart';
import 'package:wispar/models/zotero_models.dart';
import 'package:wispar/generated_l10n/app_localizations.dart';

Future<ZoteroCollection?> selectZoteroCollection(
  BuildContext context, {
  bool isSelectionMode = false,
}) {
  return showModalBottomSheet<ZoteroCollection?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _ZoteroCollectionSheet(
      isSelectionMode: isSelectionMode,
    ),
  );
}

List<Widget> _buildTree(
  BuildContext context,
  Map<String?, List<ZoteroCollection>> tree,
  String? parentKey,
  ZoteroCollection? selectedCollection,
  ValueChanged<ZoteroCollection?> onSelect,
) {
  final children = tree[parentKey] ?? [];

  return children.map((collection) {
    final hasChildren = tree.containsKey(collection.key);

    return _ExpandableCollectionTile(
      collection: collection,
      hasChildren: hasChildren,
      selectedCollection: selectedCollection,
      onSelect: onSelect,
      childrenBuilder: hasChildren
          ? () => _buildTree(
                context,
                tree,
                collection.key,
                selectedCollection,
                onSelect,
              )
          : null,
    );
  }).toList();
}

class _ExpandableCollectionTile extends StatefulWidget {
  final ZoteroCollection collection;
  final bool hasChildren;
  final ZoteroCollection? selectedCollection;
  final ValueChanged<ZoteroCollection?> onSelect;
  final List<Widget> Function()? childrenBuilder;

  const _ExpandableCollectionTile({
    required this.collection,
    required this.hasChildren,
    required this.selectedCollection,
    required this.onSelect,
    this.childrenBuilder,
  });

  @override
  State<_ExpandableCollectionTile> createState() =>
      _ExpandableCollectionTileState();
}

class _ExpandableCollectionTileState extends State<_ExpandableCollectionTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedCollection?.key == widget.collection.key;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: Icon(
            widget.collection.isGroupLibrary
                ? Icons.people
                : (widget.hasChildren ? Icons.folder : Icons.folder_outlined),
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(widget.collection.name),
          trailing: widget.hasChildren
              ? Icon(_expanded ? Icons.expand_more : Icons.chevron_right)
              : null,
          selected: isSelected,
          selectedTileColor:
              Theme.of(context).colorScheme.primary.withAlpha(50),
          onTap: () {
            final alreadySelected = isSelected;

            if (alreadySelected) {
              widget.onSelect(null);
            } else {
              widget.onSelect(widget.collection);
            }

            if (widget.hasChildren) {
              setState(() {
                _expanded = !_expanded;
              });
            }
          },
        ),
        if (_expanded && widget.hasChildren)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              children: widget.childrenBuilder!(),
            ),
          ),
      ],
    );
  }
}

class _ZoteroCollectionSheet extends StatefulWidget {
  final bool isSelectionMode;

  const _ZoteroCollectionSheet({
    required this.isSelectionMode,
  });

  @override
  State<_ZoteroCollectionSheet> createState() => _ZoteroCollectionSheetState();
}

class _ZoteroCollectionSheetState extends State<_ZoteroCollectionSheet> {
  bool alwaysSend = false;
  String? defaultCollectionKey;
  String? defaultCollectionName;
  List<ZoteroCollection> collections = [];
  final Map<String?, List<ZoteroCollection>> tree = {};
  ZoteroCollection? selectedCollection;

  String? apiKey;
  String? userId;

  bool isLoading = true;

  late final bool isSelectionMode;

  @override
  void initState() {
    super.initState();
    isSelectionMode = widget.isSelectionMode;
    _initialize();
  }

  Future<void> _initialize() async {
    apiKey = await ZoteroService.loadApiKey();
    userId = await ZoteroService.loadUserId();

    if (apiKey == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          AppLocalizations.of(context)!.zoteroApiKeyEmpty,
        ),
        duration: const Duration(seconds: 3),
      ));
      if (mounted) Navigator.pop(context);
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    alwaysSend = prefs.getBool('zoteroAlwaysSend') ?? false;

    final raw = prefs.getString('zoteroDefaultCollection');
    if (raw != null) {
      try {
        final col = ZoteroCollection.fromJson(jsonDecode(raw));
        defaultCollectionKey = col.key;
        defaultCollectionName = col.name;
      } catch (_) {}
    }

    await _loadCollections();
  }

  Future<void> _loadCollections() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    final loaded = await ZoteroService.getAllCollections(apiKey!, userId!);

    if (!mounted) return;

    final rebuiltTree = <String?, List<ZoteroCollection>>{};

    for (var c in loaded) {
      rebuiltTree.putIfAbsent(c.parentKey, () => []).add(c);
    }

    for (var list in rebuiltTree.values) {
      list.sort((a, b) => a.name.compareTo(b.name));
    }

    setState(() {
      collections = loaded;
      tree
        ..clear()
        ..addAll(rebuiltTree);
      isLoading = false;
    });
  }

  Future<void> _showCreateDialog() async {
    final controller = TextEditingController();

    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.zoteroNewCollection),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.zoteroCollectionName,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(AppLocalizations.of(context)!.create),
          ),
        ],
      ),
    );

    if (name == null || name.isEmpty) return;

    await ZoteroService.createZoteroCollection(
      apiKey!,
      userId!,
      name,
      parentCollection: selectedCollection,
    );

    await _loadCollections();

    final created = collections.firstWhere(
      (c) => c.name == name,
      orElse: () => collections.last,
    );

    if (!mounted) return;

    setState(() {
      selectedCollection = created;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header of the sheet
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.zoteroSelectCollection,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.create_new_folder_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _showCreateDialog,
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () async {
                    ZoteroService.clearCollectionsCache();
                    await _loadCollections();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(),

          // The tiles of collections
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                    ),
                    children: _buildTree(
                      context,
                      tree,
                      null,
                      selectedCollection,
                      (collection) {
                        setState(() {
                          selectedCollection = collection;
                        });
                      },
                    ),
                  ),
          ),

          // Buttons located at the bottom of the sheet
          if (!widget.isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(AppLocalizations.of(context)!
                        .zoteroSpecificCollection2),
                    value: alwaysSend,
                    onChanged: (value) async {
                      final prefs = await SharedPreferences.getInstance();

                      await prefs.setBool('zoteroAlwaysSend', value);

                      if (value && selectedCollection != null) {
                        await prefs.setString(
                          'zoteroDefaultCollection',
                          jsonEncode(selectedCollection!.toJson()),
                        );

                        defaultCollectionKey = selectedCollection!.key;
                        defaultCollectionName = selectedCollection!.name;
                      }

                      setState(() {
                        alwaysSend = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: selectedCollection == null
                    ? null
                    : () => Navigator.pop(context, selectedCollection),
                child: Text(
                  widget.isSelectionMode
                      ? AppLocalizations.of(context)!.select
                      : AppLocalizations.of(context)!.send,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
