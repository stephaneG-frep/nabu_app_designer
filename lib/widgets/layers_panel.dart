import 'package:flutter/material.dart';

import '../models/ui_component_model.dart';

class LayersPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calques (${components.length})',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (components.isEmpty)
              Text(
                'Aucun composant',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              SizedBox(
                height: 170,
                child: ListView.separated(
                  itemCount: components.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final component = components[components.length - 1 - index];
                    final selected = selectedIds.contains(component.id);
                    final locked = isLocked(component.id);
                    final visible =
                        (component.properties['visible'] as bool?) ?? true;
                    final label =
                        (component.properties['text'] as String?)?.trim() ?? '';
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => onSelect(component.id),
                      onLongPress: () => onToggleSelect(component.id),
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
                              child: Text(
                                label.isEmpty
                                    ? component.type.name
                                    : '${component.type.name}: $label',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: visible ? 'Masquer' : 'Afficher',
                              onPressed: () =>
                                  onToggleVisible(component.id, !visible),
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
                                  onToggleLock(component.id, !locked),
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

  IconData _iconForType(String typeName) {
    if (typeName.contains('button')) return Icons.smart_button_outlined;
    if (typeName.contains('text')) return Icons.text_fields_rounded;
    if (typeName.contains('image')) return Icons.image_outlined;
    if (typeName.contains('card')) return Icons.credit_card_rounded;
    if (typeName.contains('icon')) return Icons.star_outline_rounded;
    return Icons.widgets_outlined;
  }
}
