import 'package:flutter/material.dart';

import '../models/screen_model.dart';
import '../models/ui_component_model.dart';

class PropertyPanel extends StatelessWidget {
  const PropertyPanel({
    super.key,
    required this.component,
    required this.onUpdateProperty,
    required this.onDelete,
    required this.onBackToScreenSettings,
    required this.screenBackgroundColor,
    required this.onUpdateScreenBackgroundColor,
    required this.screens,
    required this.activeScreenId,
    required this.onPickImage,
    required this.selectedCount,
  });

  final UIComponentModel? component;
  final Future<void> Function(String key, dynamic value) onUpdateProperty;
  final Future<void> Function() onDelete;
  final VoidCallback onBackToScreenSettings;
  final int screenBackgroundColor;
  final Future<void> Function(int color) onUpdateScreenBackgroundColor;
  final List<ScreenModel> screens;
  final String? activeScreenId;
  final Future<void> Function() onPickImage;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    if (component == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramètres écran',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              _ColorPickerField(
                label: 'Background de l’écran',
                color: Color(screenBackgroundColor),
                onChanged: (color) =>
                    onUpdateScreenBackgroundColor(color.toARGB32()),
              ),
              const SizedBox(height: 16),
              Text(
                'Sélectionne un composant dans la preview pour éditer ses propriétés.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    final props = component!.properties;
    final text = (props['text'] as String?) ?? '';
    final subtitle = (props['subtitle'] as String?) ?? '';
    final colorValue = (props['color'] as int?) ?? 0xFF2A9D8F;
    final backgroundColorValue =
        (props['backgroundColor'] as int?) ?? 0xFFE8F4F2;
    final gradientEndColor = (props['gradientEndColor'] as int?) ?? 0xFFD5E9E6;
    final useGradient = (props['useGradient'] as bool?) ?? false;
    final progress = ((props['progress'] as num?) ?? 0.6).toDouble();
    final fontSize = ((props['fontSize'] as num?) ?? 16).toDouble();
    final fontWeight = ((props['fontWeight'] as num?) ?? 600).toDouble();
    final letterSpacing = ((props['letterSpacing'] as num?) ?? 0).toDouble();
    final lineHeight = ((props['lineHeight'] as num?) ?? 1.2).toDouble();
    final width = ((props['width'] as num?) ?? 220).toDouble();
    final height = ((props['height'] as num?) ?? 60).toDouble();
    final padding = ((props['padding'] as num?) ?? 12).toDouble();
    final margin = ((props['margin'] as num?) ?? 0).toDouble();
    final radius = ((props['borderRadius'] as num?) ?? 12).toDouble();
    final row = ((props['row'] as num?) ?? -1).toInt();
    final visible = (props['visible'] as bool?) ?? true;
    final locked = (props['locked'] as bool?) ?? false;
    final borderColor = (props['borderColor'] as int?) ?? colorValue;
    final borderWidth = ((props['borderWidth'] as num?) ?? 0).toDouble();
    final elevation = ((props['elevation'] as num?) ?? 2).toDouble();
    final opacity = ((props['opacity'] as num?) ?? 1).toDouble();
    final rotation = ((props['rotation'] as num?) ?? 0).toDouble();
    final scale = ((props['scale'] as num?) ?? 100).toDouble();
    final shadowBlur = ((props['shadowBlur'] as num?) ?? 0).toDouble();
    final shadowOpacity = ((props['shadowOpacity'] as num?) ?? 0).toDouble();
    final shadowOffsetY = ((props['shadowOffsetY'] as num?) ?? 0).toDouble();
    final alignment = (props['alignment'] as String?) ?? 'center';
    final actionType = (props['actionType'] as String?) ?? 'none';
    final targetScreenId = (props['targetScreenId'] as String?) ?? '';
    final imagePath = (props['imagePath'] as String?) ?? '';

    final screensWithoutActive = screens
        .where((screen) => screen.id != activeScreenId)
        .toList(growable: false);

    return Card(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCount > 1
                        ? 'Propriétés ($selectedCount sélectionnés)'
                        : 'Propriétés',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Paramètres écran',
                  onPressed: onBackToScreenSettings,
                  icon: const Icon(Icons.wallpaper_rounded),
                ),
                IconButton(
                  tooltip: 'Supprimer composant',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            const _SectionTitle(title: 'Contenu'),
            TextFormField(
              key: ValueKey(component!.id),
              initialValue: text,
              decoration: const InputDecoration(labelText: 'Texte'),
              onChanged: (value) => onUpdateProperty('text', value),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: subtitle,
              decoration: const InputDecoration(labelText: 'Sous-texte'),
              onChanged: (value) => onUpdateProperty('subtitle', value),
            ),
            const SizedBox(height: 12),
            _BooleanField(
              label: 'Visible',
              value: visible,
              onChanged: (value) => onUpdateProperty('visible', value),
            ),
            _BooleanField(
              label: 'Verrouillé',
              value: locked,
              onChanged: (value) => onUpdateProperty('locked', value),
            ),
            const SizedBox(height: 8),
            _SliderField(
              label: 'Progress (%)',
              value: progress * 100,
              min: 0,
              max: 100,
              onChanged: (value) => onUpdateProperty('progress', value / 100),
            ),
            const _SectionTitle(title: 'Couleurs'),
            _ColorPickerField(
              label: 'Couleur principale',
              color: Color(colorValue),
              onChanged: (color) => onUpdateProperty('color', color.toARGB32()),
            ),
            const SizedBox(height: 12),
            _ColorPickerField(
              label: 'Background',
              color: Color(backgroundColorValue),
              onChanged: (color) =>
                  onUpdateProperty('backgroundColor', color.toARGB32()),
            ),
            const SizedBox(height: 12),
            _BooleanField(
              label: 'Activer gradient',
              value: useGradient,
              onChanged: (value) => onUpdateProperty('useGradient', value),
            ),
            if (useGradient) ...[
              const SizedBox(height: 12),
              _ColorPickerField(
                label: 'Gradient fin',
                color: Color(gradientEndColor),
                onChanged: (color) =>
                    onUpdateProperty('gradientEndColor', color.toARGB32()),
              ),
            ],
            const SizedBox(height: 12),
            _ColorPickerField(
              label: 'Couleur bordure',
              color: Color(borderColor),
              onChanged: (color) =>
                  onUpdateProperty('borderColor', color.toARGB32()),
            ),
            const _SectionTitle(title: 'Typographie'),
            _SliderField(
              label: 'Taille police',
              value: fontSize,
              min: 6,
              max: 36,
              onChanged: (value) => onUpdateProperty('fontSize', value),
            ),
            _SliderField(
              label: 'Poids typo',
              value: fontWeight,
              min: 100,
              max: 900,
              divisions: 8,
              onChanged: (value) => onUpdateProperty('fontWeight', value),
            ),
            _SliderField(
              label: 'Espacement lettres',
              value: letterSpacing,
              min: -1,
              max: 8,
              onChanged: (value) => onUpdateProperty('letterSpacing', value),
            ),
            _SliderField(
              label: 'Hauteur de ligne',
              value: lineHeight,
              min: 0.8,
              max: 2.4,
              onChanged: (value) => onUpdateProperty('lineHeight', value),
            ),
            const _SectionTitle(title: 'Layout'),
            _SliderField(
              label: 'Largeur',
              value: width,
              min: 16,
              max: 360,
              onChanged: (value) => onUpdateProperty('width', value),
            ),
            _SliderField(
              label: 'Hauteur',
              value: height,
              min: 12,
              max: 320,
              onChanged: (value) => onUpdateProperty('height', value),
            ),
            _SliderField(
              label: 'Padding',
              value: padding,
              min: 0,
              max: 40,
              onChanged: (value) => onUpdateProperty('padding', value),
            ),
            _SliderField(
              label: 'Marge',
              value: margin,
              min: 0,
              max: 40,
              onChanged: (value) => onUpdateProperty('margin', value),
            ),
            _SliderField(
              label: 'Rayon bordure',
              value: radius,
              min: 0,
              max: 40,
              onChanged: (value) => onUpdateProperty('borderRadius', value),
            ),
            _SliderField(
              label: 'Groupe de ligne',
              value: row.toDouble(),
              min: -1,
              max: 8,
              divisions: 9,
              onChanged: (value) => onUpdateProperty('row', value.round()),
            ),
            Text(
              'Aide: -1 = seul sur sa ligne. Même valeur (0,1,2...) = même ligne.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
            const SizedBox(height: 8),
            Text('Alignement', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'start',
                  icon: Icon(Icons.format_align_left),
                ),
                ButtonSegment<String>(
                  value: 'center',
                  icon: Icon(Icons.format_align_center),
                ),
                ButtonSegment<String>(
                  value: 'end',
                  icon: Icon(Icons.format_align_right),
                ),
              ],
              selected: {alignment},
              onSelectionChanged: (selection) {
                onUpdateProperty('alignment', selection.first);
              },
            ),
            const _SectionTitle(title: 'Effets'),
            _SliderField(
              label: 'Bordure',
              value: borderWidth,
              min: 0,
              max: 10,
              onChanged: (value) => onUpdateProperty('borderWidth', value),
            ),
            _SliderField(
              label: 'Elevation',
              value: elevation,
              min: 0,
              max: 20,
              onChanged: (value) => onUpdateProperty('elevation', value),
            ),
            _SliderField(
              label: 'Opacité (%)',
              value: opacity * 100,
              min: 10,
              max: 100,
              onChanged: (value) => onUpdateProperty('opacity', value / 100),
            ),
            _SliderField(
              label: 'Rotation (°)',
              value: rotation,
              min: -180,
              max: 180,
              onChanged: (value) => onUpdateProperty('rotation', value),
            ),
            _SliderField(
              label: 'Scale (%)',
              value: scale,
              min: 20,
              max: 300,
              onChanged: (value) => onUpdateProperty('scale', value),
            ),
            _SliderField(
              label: 'Ombre flou',
              value: shadowBlur,
              min: 0,
              max: 30,
              onChanged: (value) => onUpdateProperty('shadowBlur', value),
            ),
            _SliderField(
              label: 'Ombre opacité',
              value: shadowOpacity * 100,
              min: 0,
              max: 100,
              onChanged: (value) =>
                  onUpdateProperty('shadowOpacity', value / 100),
            ),
            _SliderField(
              label: 'Ombre Y',
              value: shadowOffsetY,
              min: -20,
              max: 40,
              onChanged: (value) => onUpdateProperty('shadowOffsetY', value),
            ),
            const _SectionTitle(title: 'Actions'),
            DropdownButtonFormField<String>(
              initialValue: actionType,
              decoration: const InputDecoration(labelText: 'Action au tap'),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Aucune')),
                DropdownMenuItem(
                  value: 'navigate',
                  child: Text('Naviguer écran'),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                onUpdateProperty('actionType', value);
                if (value != 'navigate') {
                  onUpdateProperty('targetScreenId', '');
                }
              },
            ),
            if (actionType == 'navigate') ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue:
                    screensWithoutActive.any((s) => s.id == targetScreenId)
                    ? targetScreenId
                    : null,
                decoration: const InputDecoration(labelText: 'Écran cible'),
                items: screensWithoutActive
                    .map(
                      (screen) => DropdownMenuItem<String>(
                        value: screen.id,
                        child: Text(screen.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  onUpdateProperty('targetScreenId', value ?? '');
                },
              ),
            ],
            const _SectionTitle(title: 'Image locale'),
            if (imagePath.isNotEmpty)
              Text(
                imagePath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onPickImage,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Choisir image'),
                ),
                OutlinedButton(
                  onPressed: () => onUpdateProperty('imagePath', ''),
                  child: const Text('Retirer image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF3A4A5B),
        ),
      ),
    );
  }
}

class _BooleanField extends StatelessWidget {
  const _BooleanField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _ColorPickerField extends StatelessWidget {
  const _ColorPickerField({
    required this.label,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final picked = await _showColorPickerDialog(context, color);
            if (picked != null) {
              onChanged(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD9E1EC)),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickPalette
              .map(
                (preset) => InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(preset),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: preset,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: preset.toARGB32() == color.toARGB32()
                            ? Colors.black87
                            : Colors.black12,
                        width: preset.toARGB32() == color.toARGB32() ? 2 : 1,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  static const List<Color> _quickPalette = [
    Color(0xFF1D3557),
    Color(0xFF2A9D8F),
    Color(0xFF52B788),
    Color(0xFFF4A261),
    Color(0xFFE76F51),
    Color(0xFF8338EC),
    Color(0xFF3A86FF),
    Color(0xFFFF006E),
    Color(0xFFF1FAEE),
    Color(0xFFFFFFFF),
    Color(0xFF212529),
    Color(0xFF6C757D),
  ];

  Future<Color?> _showColorPickerDialog(
    BuildContext context,
    Color initialColor,
  ) async {
    double red = initialColor.r.toDouble();
    double green = initialColor.g.toDouble();
    double blue = initialColor.b.toDouble();

    return showDialog<Color>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final current = Color.fromARGB(
              255,
              red.round(),
              green.round(),
              blue.round(),
            );

            return AlertDialog(
              title: const Text('Choisir une couleur'),
              content: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: current,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ColorSlider(
                      label: 'R',
                      value: red,
                      activeColor: Colors.red,
                      onChanged: (value) => setState(() => red = value),
                    ),
                    _ColorSlider(
                      label: 'G',
                      value: green,
                      activeColor: Colors.green,
                      onChanged: (value) => setState(() => green = value),
                    ),
                    _ColorSlider(
                      label: 'B',
                      value: blue,
                      activeColor: Colors.blue,
                      onChanged: (value) => setState(() => blue = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(current),
                  child: const Text('Appliquer'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ColorSlider extends StatelessWidget {
  const _ColorSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color activeColor;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 18,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Slider(
            min: 0,
            max: 255,
            value: value.clamp(0, 255),
            activeColor: activeColor,
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 34,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ${value.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
