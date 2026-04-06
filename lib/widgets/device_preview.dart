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
    this.showGrid = false,
    this.dragEnabled = true,
    this.frameMaxWidth = 390,
    this.onNavigateToScreen,
    this.onMoveComponentBefore,
  });

  final ScreenModel? screen;
  final List<String> selectedComponentIds;
  final ValueChanged<String> onSelectComponent;
  final ValueChanged<String> onToggleComponentSelection;
  final VoidCallback onBackgroundTap;
  final bool showDeviceFrame;
  final bool selectionMode;
  final bool interactiveMode;
  final bool showGrid;
  final bool dragEnabled;
  final double frameMaxWidth;
  final ValueChanged<String>? onNavigateToScreen;
  final Future<void> Function(String draggedId, String targetId)?
  onMoveComponentBefore;

  @override
  Widget build(BuildContext context) {
    final bgColor = Color(screen?.backgroundColor ?? 0xFFFFFFFF);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    if (!showDeviceFrame) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: bgColor,
        child: _buildCanvas(context),
      );
    }

    final effectiveMaxWidth = isLandscape ? frameMaxWidth * 1.8 : frameMaxWidth;

    final shell = Container(
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
            Expanded(child: _buildCanvas(context)),
          ],
        ),
      ),
    );

    return Container(
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
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
      child: isLandscape
          ? AspectRatio(aspectRatio: 19.5 / 9, child: shell)
          : shell,
    );
  }

  Widget _buildCanvas(BuildContext context) {
    if (screen == null) {
      return const Center(child: Text('Aucun écran sélectionné'));
    }

    final components = screen!.components;
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

    final rows = <String>[];
    final grouped = <String, List<UIComponentModel>>{};

    for (var i = 0; i < roots.length; i++) {
      final component = roots[i];
      final row = ((component.properties['row'] as num?) ?? -1).round();
      final key = row >= 0 ? 'row_$row' : 'single_${component.id}_$i';
      if (!grouped.containsKey(key)) {
        rows.add(key);
        grouped[key] = <UIComponentModel>[];
      }
      grouped[key]!.add(component);
    }

    final list = Scrollbar(
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
              child: _buildTreeNode(
                component,
                childrenByParent: childrenByParent,
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
                          child: _buildTreeNode(
                            component,
                            childrenByParent: childrenByParent,
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

    if (!showGrid) {
      return list;
    }

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GridPainter(
                majorColor: Colors.black.withValues(alpha: 0.10),
                minorColor: Colors.black.withValues(alpha: 0.05),
                majorStep: 80,
                minorStep: 20,
              ),
            ),
          ),
        ),
        list,
      ],
    );
  }

  Widget _buildTreeNode(
    UIComponentModel component, {
    required Map<String, List<UIComponentModel>> childrenByParent,
    int depth = 0,
    Set<String>? ancestry,
  }) {
    final path = {...?ancestry, component.id};
    final children =
        childrenByParent[component.id] ?? const <UIComponentModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlot(component, allowDrag: depth == 0),
        if (children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children
                  .map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: path.contains(child.id)
                          ? const Text('Cycle parent/enfant détecté')
                          : _buildTreeNode(
                              child,
                              childrenByParent: childrenByParent,
                              depth: depth + 1,
                              ancestry: path,
                            ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSlot(UIComponentModel component, {required bool allowDrag}) {
    return _DraggableComponentSlot(
      componentId: component.id,
      enabled:
          allowDrag &&
          dragEnabled &&
          selectionMode &&
          onMoveComponentBefore != null,
      onDroppedBefore: (draggedId, targetId) async {
        await onMoveComponentBefore?.call(draggedId, targetId);
      },
      child: ComponentRenderer(
        component: component,
        isSelected: selectedComponentIds.contains(component.id),
        onTap: () => onSelectComponent(component.id),
        onLongPress: dragEnabled
            ? null
            : () => onToggleComponentSelection(component.id),
        selectionMode: selectionMode,
        onAction: _buildAction(component),
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

class _GridPainter extends CustomPainter {
  _GridPainter({
    required this.majorColor,
    required this.minorColor,
    required this.majorStep,
    required this.minorStep,
  });

  final Color majorColor;
  final Color minorColor;
  final double majorStep;
  final double minorStep;

  @override
  void paint(Canvas canvas, Size size) {
    final minorPaint = Paint()
      ..color = minorColor
      ..strokeWidth = 1;
    final majorPaint = Paint()
      ..color = majorColor
      ..strokeWidth = 1.2;

    for (double x = 0; x <= size.width; x += minorStep) {
      final isMajor = (x % majorStep).abs() < 0.01;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        isMajor ? majorPaint : minorPaint,
      );
    }

    for (double y = 0; y <= size.height; y += minorStep) {
      final isMajor = (y % majorStep).abs() < 0.01;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        isMajor ? majorPaint : minorPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) {
    return oldDelegate.majorColor != majorColor ||
        oldDelegate.minorColor != minorColor ||
        oldDelegate.majorStep != majorStep ||
        oldDelegate.minorStep != minorStep;
  }
}

class _DraggableComponentSlot extends StatelessWidget {
  const _DraggableComponentSlot({
    required this.componentId,
    required this.enabled,
    required this.child,
    required this.onDroppedBefore,
  });

  final String componentId;
  final bool enabled;
  final Widget child;
  final Future<void> Function(String draggedId, String targetId)?
  onDroppedBefore;

  @override
  Widget build(BuildContext context) {
    final target = DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          enabled && details.data != componentId,
      onAcceptWithDetails: (details) {
        onDroppedBefore?.call(details.data, componentId);
      },
      builder: (context, candidateData, _) {
        final isHovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isHovering
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: child,
        );
      },
    );

    if (!enabled) {
      return target;
    }

    return Draggable<String>(
      data: componentId,
      affinity: Axis.horizontal,
      dragAnchorStrategy: childDragAnchorStrategy,
      maxSimultaneousDrags: 1,
      feedback: Opacity(
        opacity: 0.88,
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280),
            child: child,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: target),
      child: target,
    );
  }
}
