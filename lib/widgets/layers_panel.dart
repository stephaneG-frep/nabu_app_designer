import 'package:flutter/material.dart';

import '../models/ui_component_model.dart';

class LayersPanel extends StatefulWidget {
  const LayersPanel({
    super.key,
    required this.components,
    required this.selectedIds,
    required this.onSelect,
    required this.onToggleSelect,
    required this.onToggleLock,
    required this.onToggleVisible,
    required this.isLocked,
  });

  final List<UIComponentModel> components;
  final List<String> selectedIds;
  final ValueChanged<String> onSelect;
  final ValueChanged<String> onToggleSelect;
  final Future<void> Function(String componentId, bool locked) onToggleLock;
  final Future<void> Function(String componentId, bool visible) onToggleVisible;
  final bool Function(String componentId) isLocked;

  @override
  State<LayersPanel> createState() => _LayersPanelState();
}

class _LayersPanelState extends State<LayersPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _onlyVisible = false;
  bool _onlyLocked = false;
  bool _onlySelected = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final treeEntries = _buildTreeEntries(widget.components);
    final filtered = treeEntries.where((entry) {
      final component = entry.component;
      final label = ((component.properties['text'] as String?) ?? '')
          .trim()
          .toLowerCase();
      final type = component.type.name.toLowerCase();
      final visible = (component.properties['visible'] as bool?) ?? true;
      final locked = widget.isLocked(component.id);
      final selected = widget.selectedIds.contains(component.id);

      final q = _query.trim().toLowerCase();
      final matchesQuery = q.isEmpty || label.contains(q) || type.contains(q);

      if (!matchesQuery) {
        return false;
      }
      if (_onlyVisible && !visible) {
        return false;
      }
      if (_onlyLocked && !locked) {
        return false;
      }
      if (_onlySelected && !selected) {
        return false;
      }
      return true;
    }).toList();

    final reversedFiltered = filtered.reversed.toList();
    final hasActiveFilter =
        _query.trim().isNotEmpty ||
        _onlyVisible ||
        _onlyLocked ||
        _onlySelected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calques (${filtered.length}/${widget.components.length})',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Rechercher un calque...',
                prefixIcon: const Icon(Icons.search_rounded, size: 18),
                suffixIcon: _query.trim().isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Effacer',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.clear_rounded, size: 18),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Visibles'),
                  selected: _onlyVisible,
                  onSelected: (v) => setState(() => _onlyVisible = v),
                ),
                FilterChip(
                  label: const Text('Verrouillés'),
                  selected: _onlyLocked,
                  onSelected: (v) => setState(() => _onlyLocked = v),
                ),
                FilterChip(
                  label: const Text('Sélection'),
                  selected: _onlySelected,
                  onSelected: (v) => setState(() => _onlySelected = v),
                ),
                if (hasActiveFilter)
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _onlyVisible = false;
                        _onlyLocked = false;
                        _onlySelected = false;
                      });
                    },
                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                    label: const Text('Réinitialiser'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (widget.components.isEmpty)
              Text(
                'Aucun composant',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else if (filtered.isEmpty)
              Text(
                'Aucun résultat avec ces filtres.',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              SizedBox(
                height: 210,
                child: ListView.separated(
                  itemCount: reversedFiltered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final entry = reversedFiltered[index];
                    final component = entry.component;
                    final selected = widget.selectedIds.contains(component.id);
                    final locked = widget.isLocked(component.id);
                    final visible =
                        (component.properties['visible'] as bool?) ?? true;
                    final groupId =
                        (component.properties['groupId'] as String?) ?? '';
                    final label =
                        (component.properties['text'] as String?)?.trim() ?? '';
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => widget.onSelect(component.id),
                      onLongPress: () => widget.onToggleSelect(component.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(_iconForType(component.type.name), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: (entry.depth * 12).toDouble(),
                                ),
                                child: Text(
                                  label.isEmpty
                                      ? component.type.name
                                      : '${component.type.name}: $label',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ),
                            if (groupId.isNotEmpty)
                              const Padding(
                                padding: EdgeInsets.only(right: 2),
                                child: Icon(
                                  Icons.group_work_outlined,
                                  size: 16,
                                ),
                              ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: visible ? 'Masquer' : 'Afficher',
                              onPressed: () => widget.onToggleVisible(
                                component.id,
                                !visible,
                              ),
                              icon: Icon(
                                visible
                                    ? Icons.visibility_rounded
                                    : Icons.visibility_off_rounded,
                                size: 18,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: locked ? 'Déverrouiller' : 'Verrouiller',
                              onPressed: () =>
                                  widget.onToggleLock(component.id, !locked),
                              icon: Icon(
                                locked
                                    ? Icons.lock_rounded
                                    : Icons.lock_open_rounded,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_LayerEntry> _buildTreeEntries(List<UIComponentModel> components) {
    final byId = {for (final c in components) c.id: c};
    final childrenByParent = <String, List<UIComponentModel>>{};
    final roots = <UIComponentModel>[];

    for (final component in components) {
      final parentId = (component.properties['parentId'] as String?) ?? '';
      if (parentId.isEmpty || !byId.containsKey(parentId)) {
        roots.add(component);
      } else {
        childrenByParent
            .putIfAbsent(parentId, () => <UIComponentModel>[])
            .add(component);
      }
    }

    final entries = <_LayerEntry>[];

    void visit(UIComponentModel component, int depth, Set<String> ancestry) {
      entries.add(_LayerEntry(component: component, depth: depth));
      final nextAncestry = {...ancestry, component.id};
      for (final child
          in childrenByParent[component.id] ?? const <UIComponentModel>[]) {
        if (nextAncestry.contains(child.id)) {
          continue;
        }
        visit(child, depth + 1, nextAncestry);
      }
    }

    for (final root in roots) {
      visit(root, 0, const <String>{});
    }
    return entries;
  }

  IconData _iconForType(String typeName) {
    if (typeName.contains('button')) return Icons.smart_button_outlined;
    if (typeName.contains('text')) return Icons.text_fields_rounded;
    if (typeName.contains('image')) return Icons.image_outlined;
    if (typeName.contains('card')) return Icons.credit_card_rounded;
    if (typeName.contains('icon')) return Icons.star_outline_rounded;
    return Icons.widgets_outlined;
  }
}

class _LayerEntry {
  const _LayerEntry({required this.component, required this.depth});

  final UIComponentModel component;
  final int depth;
}
