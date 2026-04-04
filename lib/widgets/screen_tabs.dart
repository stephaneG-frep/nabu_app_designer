import 'package:flutter/material.dart';

import '../models/screen_model.dart';

class ScreenTabs extends StatelessWidget {
  const ScreenTabs({
    super.key,
    required this.screens,
    required this.activeScreenId,
    required this.onSelect,
    required this.onAddScreen,
    required this.onDuplicateScreen,
    required this.onRenameScreen,
    required this.onMoveScreenLeft,
    required this.onMoveScreenRight,
    required this.onDeleteScreen,
  });

  final List<ScreenModel> screens;
  final String? activeScreenId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddScreen;
  final VoidCallback onDuplicateScreen;
  final VoidCallback onRenameScreen;
  final VoidCallback onMoveScreenLeft;
  final VoidCallback onMoveScreenRight;
  final VoidCallback onDeleteScreen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              scrollDirection: Axis.horizontal,
              itemCount: screens.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final screen = screens[index];
                final selected = screen.id == activeScreenId;
                return ChoiceChip(
                  selected: selected,
                  label: Text(screen.name),
                  onSelected: (_) => onSelect(screen.id),
                );
              },
            ),
          ),
          const SizedBox(width: 14),
          IconButton.filledTonal(
            tooltip: 'Ajouter un écran',
            onPressed: onAddScreen,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 6),
          PopupMenuButton<_ScreenTabAction>(
            tooltip: 'Actions écran',
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ScreenTabAction.duplicate,
                child: Text('Dupliquer écran'),
              ),
              PopupMenuItem(
                value: _ScreenTabAction.rename,
                child: Text('Renommer écran'),
              ),
              PopupMenuItem(
                value: _ScreenTabAction.moveLeft,
                child: Text('Déplacer à gauche'),
              ),
              PopupMenuItem(
                value: _ScreenTabAction.moveRight,
                child: Text('Déplacer à droite'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _ScreenTabAction.delete,
                child: Text('Supprimer écran'),
              ),
            ],
            onSelected: (action) {
              switch (action) {
                case _ScreenTabAction.duplicate:
                  onDuplicateScreen();
                case _ScreenTabAction.rename:
                  onRenameScreen();
                case _ScreenTabAction.moveLeft:
                  onMoveScreenLeft();
                case _ScreenTabAction.moveRight:
                  onMoveScreenRight();
                case _ScreenTabAction.delete:
                  onDeleteScreen();
              }
            },
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.more_horiz_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ScreenTabAction { duplicate, rename, moveLeft, moveRight, delete }
