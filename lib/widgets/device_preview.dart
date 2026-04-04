import 'package:flutter/material.dart';

import '../models/screen_model.dart';
import '../models/ui_component_model.dart';
import 'component_renderer.dart';

class DevicePreview extends StatelessWidget {
  const DevicePreview({
    super.key,
    required this.screen,
    required this.selectedComponentIds,
    required this.onSelectComponent,
    required this.onToggleComponentSelection,
    required this.onBackgroundTap,
    this.showDeviceFrame = true,
    this.selectionMode = true,
    this.interactiveMode = false,
    this.onNavigateToScreen,
  });

  final ScreenModel? screen;
  final List<String> selectedComponentIds;
  final ValueChanged<String> onSelectComponent;
  final ValueChanged<String> onToggleComponentSelection;
  final VoidCallback onBackgroundTap;
  final bool showDeviceFrame;
  final bool selectionMode;
  final bool interactiveMode;
  final ValueChanged<String>? onNavigateToScreen;

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(screen?.backgroundColor ?? 0xFFFFFFFF);

    if (!showDeviceFrame) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: _buildCanvas(bgColor),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 390),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Container(
                height: 30,
                width: double.infinity,
                color: const Color(0xFFF2F5FA),
                alignment: Alignment.center,
                child: Container(
                  width: 90,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCD6E0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Expanded(child: _buildCanvas(bgColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCanvas(Color backgroundColor) {
    if (screen == null) {
      return const Center(child: Text('Aucun écran sélectionné'));
    }

    final rows = <String>[];
    final grouped = <String, List<UIComponentModel>>{};

    for (var i = 0; i < screen!.components.length; i++) {
      final component = screen!.components[i];
      final row = ((component.properties['row'] as num?) ?? -1).round();
      final key = row >= 0 ? 'row_$row' : 'single_${component.id}_$i';
      if (!grouped.containsKey(key)) {
        rows.add(key);
        grouped[key] = <UIComponentModel>[];
      }
      grouped[key]!.add(component);
    }

    return Scrollbar(
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final key = rows[index];
          final rowComponents = grouped[key]!;

          if (rowComponents.length == 1) {
            final component = rowComponents.first;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ComponentRenderer(
                component: component,
                isSelected: selectedComponentIds.contains(component.id),
                onTap: () => onSelectComponent(component.id),
                onLongPress: () => onToggleComponentSelection(component.id),
                selectionMode: selectionMode,
                onAction: _buildAction(component),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Scrollbar(
              notificationPredicate: (notification) => notification.depth == 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: rowComponents
                      .map(
                        (component) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ComponentRenderer(
                            component: component,
                            isSelected: selectedComponentIds.contains(
                              component.id,
                            ),
                            onTap: () => onSelectComponent(component.id),
                            onLongPress: () =>
                                onToggleComponentSelection(component.id),
                            selectionMode: selectionMode,
                            onAction: _buildAction(component),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  VoidCallback? _buildAction(UIComponentModel component) {
    if (!interactiveMode || onNavigateToScreen == null) {
      return null;
    }

    final actionType =
        (component.properties['actionType'] as String?) ?? 'none';
    final target = (component.properties['targetScreenId'] as String?) ?? '';
    if (actionType != 'navigate' || target.isEmpty) {
      return null;
    }

    return () => onNavigateToScreen!(target);
  }
}
