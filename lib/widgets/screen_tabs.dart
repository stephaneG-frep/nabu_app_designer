import 'package:flutter/material.dart';

import '../models/screen_model.dart';

class ScreenTabs extends StatelessWidget {
  const ScreenTabs({
    super.key,
    required this.screens,
    required this.activeScreenId,
    required this.onSelect,
    required this.onAddScreen,
    required this.onDeleteScreen,
  });

  final List<ScreenModel> screens;
  final String? activeScreenId;
  final ValueChanged<String> onSelect;
  final VoidCallback onAddScreen;
  final VoidCallback onDeleteScreen;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
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
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Ajouter un écran',
            onPressed: onAddScreen,
            icon: const Icon(Icons.add_rounded),
          ),
          const SizedBox(width: 6),
          IconButton.filledTonal(
            tooltip: 'Supprimer écran actif',
            onPressed: onDeleteScreen,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
    );
  }
}
