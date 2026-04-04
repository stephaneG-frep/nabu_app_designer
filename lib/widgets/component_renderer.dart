import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/component_type.dart';
import '../models/ui_component_model.dart';

class ComponentRenderer extends StatelessWidget {
  const ComponentRenderer({
    super.key,
    required this.component,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
    this.selectionMode = true,
    this.onAction,
  });

  final UIComponentModel component;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool selectionMode;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final props = component.properties;
    final text = (props['text'] as String?) ?? '';
    final subtitle = (props['subtitle'] as String?) ?? 'Valeur';
    final color = Color((props['color'] as int?) ?? 0xFF2A9D8F);
    final backgroundColor = Color(
      (props['backgroundColor'] as int?) ?? 0xFFE8F4F2,
    );
    final gradientEndColor = Color(
      (props['gradientEndColor'] as int?) ?? 0xFFD5E9E6,
    );
    final useGradient = (props['useGradient'] as bool?) ?? false;
    final progress = ((props['progress'] as num?) ?? 0.6).toDouble().clamp(
      0.0,
      1.0,
    );
    final fontSize = ((props['fontSize'] as num?) ?? 16).toDouble();
    final fontWeight = ((props['fontWeight'] as num?) ?? 600).toDouble();
    final letterSpacing = ((props['letterSpacing'] as num?) ?? 0).toDouble();
    final lineHeight = ((props['lineHeight'] as num?) ?? 1.2).toDouble();
    final padding = ((props['padding'] as num?) ?? 12).toDouble();
    final borderRadius = ((props['borderRadius'] as num?) ?? 12).toDouble();
    final width = ((props['width'] as num?) ?? 220).toDouble();
    final height = ((props['height'] as num?) ?? 60).toDouble();
    final margin = ((props['margin'] as num?) ?? 0).toDouble();
    final visible = (props['visible'] as bool?) ?? true;
    final opacity = ((props['opacity'] as num?) ?? 1).toDouble();
    final borderColor = Color((props['borderColor'] as int?) ?? 0xFF2A9D8F);
    final borderWidth = ((props['borderWidth'] as num?) ?? 0).toDouble();
    final elevation = ((props['elevation'] as num?) ?? 2).toDouble();
    final rotation = ((props['rotation'] as num?) ?? 0).toDouble();
    final scale = ((props['scale'] as num?) ?? 100).toDouble();
    final shadowBlur = ((props['shadowBlur'] as num?) ?? 0).toDouble();
    final shadowOpacity = ((props['shadowOpacity'] as num?) ?? 0).toDouble();
    final shadowOffsetY = ((props['shadowOffsetY'] as num?) ?? 0).toDouble();
    final alignment = _parseAlignment(
      (props['alignment'] as String?) ?? 'center',
    );
    final imagePath = (props['imagePath'] as String?) ?? '';

    if (!visible) {
      return const SizedBox.shrink();
    }

    final commonTextStyle = TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: _fontWeightFromValue(fontWeight),
      letterSpacing: letterSpacing,
      height: lineHeight,
    );
    final borderSide = borderWidth > 0
        ? BorderSide(color: borderColor, width: borderWidth)
        : BorderSide.none;

    final child = _buildByType(
      type: component.type,
      text: text,
      subtitle: subtitle,
      color: color,
      backgroundColor: backgroundColor,
      gradientEndColor: gradientEndColor,
      useGradient: useGradient,
      commonTextStyle: commonTextStyle,
      padding: padding,
      borderRadius: borderRadius,
      width: width,
      height: height,
      progress: progress,
      borderSide: borderSide,
      elevation: elevation,
      imagePath: imagePath,
    );

    final visual = Align(
      alignment: alignment,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: opacity.clamp(0.2, 1.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.all(margin),
          padding: EdgeInsets.all(isSelected && selectionMode ? 4 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: shadowBlur > 0
                ? [
                    BoxShadow(
                      color: color.withValues(
                        alpha: shadowOpacity.clamp(0.0, 1.0),
                      ),
                      blurRadius: shadowBlur,
                      offset: Offset(0, shadowOffsetY),
                    ),
                  ]
                : null,
            border: isSelected && selectionMode
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  )
                : null,
          ),
          child: Transform.rotate(
            angle: (rotation * math.pi) / 180,
            child: Transform.scale(
              scale: (scale / 100).clamp(0.2, 3.0),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (!selectionMode) {
      return visual;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onLongPress: onLongPress,
      child: visual,
    );
  }

  Widget _buildByType({
    required ComponentType type,
    required String text,
    required String subtitle,
    required Color color,
    required Color backgroundColor,
    required Color gradientEndColor,
    required bool useGradient,
    required TextStyle commonTextStyle,
    required double padding,
    required double borderRadius,
    required double width,
    required double height,
    required double progress,
    required BorderSide borderSide,
    required double elevation,
    required String imagePath,
  }) {
    final border = borderSide == BorderSide.none
        ? null
        : Border.fromBorderSide(borderSide);

    switch (type) {
      case ComponentType.text:
        return SizedBox(
          width: width,
          height: height,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: _tileDecoration(
              backgroundColor: backgroundColor,
              gradientEndColor: gradientEndColor,
              useGradient: useGradient,
              borderRadius: borderRadius,
              border: border,
            ),
            child: Text(
              text,
              style: commonTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case ComponentType.button:
        final buttonContent = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: useGradient ? Colors.transparent : backgroundColor,
            shadowColor: useGradient ? Colors.transparent : null,
            surfaceTintColor: Colors.transparent,
            elevation: useGradient ? 0 : elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: borderSide,
            ),
            padding: EdgeInsets.all(padding),
          ),
          onPressed: onAction ?? () {},
          child: Text(text, style: commonTextStyle),
        );

        if (useGradient) {
          return SizedBox(
            width: width,
            height: height,
            child: DecoratedBox(
              decoration: _tileDecoration(
                backgroundColor: backgroundColor,
                gradientEndColor: gradientEndColor,
                useGradient: true,
                borderRadius: borderRadius,
                border: border,
              ),
              child: buttonContent,
            ),
          );
        }

        return SizedBox(width: width, height: height, child: buttonContent);
      case ComponentType.card:
        final cardContent = Padding(
          padding: EdgeInsets.all(padding),
          child: Text(text, style: commonTextStyle),
        );

        if (useGradient) {
          return SizedBox(
            width: width,
            height: height,
            child: Container(
              decoration: _tileDecoration(
                backgroundColor: backgroundColor,
                gradientEndColor: gradientEndColor,
                useGradient: true,
                borderRadius: borderRadius,
                border: border,
              ),
              child: cardContent,
            ),
          );
        }

        return SizedBox(
          width: width,
          height: height,
          child: Card(
            color: backgroundColor,
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: borderSide,
            ),
            child: cardContent,
          ),
        );
      case ComponentType.imagePlaceholder:
        final file = imagePath.isNotEmpty ? File(imagePath) : null;
        final hasImage = file != null && file.existsSync();
        final imageFile = hasImage ? file : null;
        return SizedBox(
          width: width,
          height: height,
          child: Container(
            padding: EdgeInsets.all(padding),
            decoration: _tileDecoration(
              backgroundColor: backgroundColor,
              gradientEndColor: gradientEndColor,
              useGradient: useGradient,
              borderRadius: borderRadius,
              border: Border.all(
                color: color.withValues(alpha: 0.45),
                width: borderSide == BorderSide.none ? 1 : borderSide.width,
              ),
            ),
            child: imageFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(
                      (borderRadius - 2).clamp(0, 50),
                    ),
                    child: Image.file(imageFile, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_rounded,
                        color: color,
                        size: commonTextStyle.fontSize! + 18,
                      ),
                      const SizedBox(height: 8),
                      Text(text, style: commonTextStyle),
                    ],
                  ),
          ),
        );
      case ComponentType.textField:
        return SizedBox(
          width: width,
          height: height,
          child: TextField(
            enabled: false,
            style: commonTextStyle,
            decoration: InputDecoration(
              labelText: text,
              labelStyle: commonTextStyle,
              contentPadding: EdgeInsets.all(padding),
              filled: true,
              fillColor: backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: BorderSide(
                  color: color.withValues(alpha: 0.7),
                  width: borderSide == BorderSide.none ? 1 : borderSide.width,
                ),
              ),
            ),
          ),
        );
      case ComponentType.chip:
        return SizedBox(
          width: width,
          height: height,
          child: Align(
            child: Chip(
              backgroundColor: backgroundColor,
              side: BorderSide(
                color: color.withValues(alpha: 0.45),
                width: borderSide == BorderSide.none ? 1 : borderSide.width,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              label: Padding(
                padding: EdgeInsets.symmetric(horizontal: padding * 0.4),
                child: Text(text, style: commonTextStyle),
              ),
            ),
          ),
        );
      case ComponentType.avatar:
        return SizedBox(
          width: width,
          height: height,
          child: Center(
            child: CircleAvatar(
              radius: (height * 0.40).clamp(8, 52).toDouble(),
              backgroundColor: backgroundColor,
              child: Text(
                text.isEmpty ? 'A' : text.substring(0, 1).toUpperCase(),
                style: commonTextStyle.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        );
      case ComponentType.divider:
        return SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: padding * 0.35),
            child: Divider(
              thickness: (commonTextStyle.fontSize! / 8).clamp(1, 8).toDouble(),
              color: color,
            ),
          ),
        );
      case ComponentType.icon:
        return SizedBox(
          width: width,
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(padding * 0.8),
                decoration: _tileDecoration(
                  backgroundColor: backgroundColor,
                  gradientEndColor: gradientEndColor,
                  useGradient: useGradient,
                  borderRadius: borderRadius,
                  border: border,
                ),
                child: Icon(
                  Icons.star_rounded,
                  size: commonTextStyle.fontSize! + 20,
                  color: color,
                ),
              ),
              if (text.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  text,
                  style: commonTextStyle.copyWith(
                    fontSize: commonTextStyle.fontSize! * 0.85,
                  ),
                ),
              ],
            ],
          ),
        );
      case ComponentType.appBar:
        return SizedBox(
          width: width,
          height: height,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: padding,
              vertical: (padding * 0.75).clamp(6, 24).toDouble(),
            ),
            decoration:
                _tileDecoration(
                  backgroundColor: backgroundColor,
                  gradientEndColor: gradientEndColor,
                  useGradient: useGradient,
                  borderRadius: borderRadius,
                  border: border,
                ).copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: backgroundColor.withValues(alpha: 0.38),
                      blurRadius: 6 + elevation * 2,
                      offset: Offset(0, 2 + elevation),
                    ),
                  ],
                ),
            child: Row(
              children: [
                Icon(Icons.arrow_back_rounded, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: commonTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(Icons.more_vert_rounded, color: color),
              ],
            ),
          ),
        );
      case ComponentType.switchTile:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: commonTextStyle,
                ),
              ),
              Switch(value: true, onChanged: (_) {}),
            ],
          ),
        );
      case ComponentType.checkboxTile:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding,
          child: Row(
            children: [
              Checkbox(value: true, onChanged: (_) {}),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: commonTextStyle,
                ),
              ),
            ],
          ),
        );
      case ComponentType.progressBar:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.6,
          child: Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: color.withValues(alpha: 0.2),
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                  minHeight: (height * 0.25).clamp(4, 16),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(progress * 100).round()}%',
                style: commonTextStyle.copyWith(
                  fontSize: commonTextStyle.fontSize! * 0.8,
                ),
              ),
            ],
          ),
        );
      case ComponentType.badge:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.75,
          child: Center(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: commonTextStyle.copyWith(
                letterSpacing: (commonTextStyle.letterSpacing ?? 0) + 0.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      case ComponentType.containerBox:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding,
          child: Center(
            child: Text(
              text,
              style: commonTextStyle,
              textAlign: TextAlign.center,
            ),
          ),
        );
      case ComponentType.iconButton:
        return SizedBox(
          width: width,
          height: height,
          child: IconButton.filledTonal(
            style: IconButton.styleFrom(
              backgroundColor: backgroundColor,
              side: borderSide == BorderSide.none ? null : borderSide,
            ),
            onPressed: onAction ?? () {},
            icon: Icon(Icons.favorite_border_rounded, color: color),
            tooltip: text,
          ),
        );
      case ComponentType.floatingActionButton:
        return SizedBox(
          width: width,
          height: height,
          child: FloatingActionButton(
            onPressed: onAction ?? () {},
            backgroundColor: backgroundColor,
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: borderSide,
            ),
            child: Text(text, style: commonTextStyle),
          ),
        );
      case ComponentType.bottomNav:
        final items = _splitCsv(
          text,
          fallback: const ['Accueil', 'Recherche', 'Profil'],
        );
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.4,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: items
                .take(4)
                .map(
                  (item) => Text(
                    item,
                    style: commonTextStyle.copyWith(
                      fontSize: commonTextStyle.fontSize! * 0.8,
                    ),
                  ),
                )
                .toList(),
          ),
        );
      case ComponentType.tabBar:
        final tabs = _splitCsv(
          text,
          fallback: const ['Tab 1', 'Tab 2', 'Tab 3'],
        );
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.3,
          child: Row(
            children: tabs
                .map(
                  (tab) => Expanded(
                    child: Center(
                      child: Text(
                        tab,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: commonTextStyle.copyWith(
                          fontSize: commonTextStyle.fontSize! * 0.85,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        );
      case ComponentType.banner:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding,
          child: Row(
            children: [
              Icon(Icons.campaign_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(text, style: commonTextStyle)),
            ],
          ),
        );
      case ComponentType.statCard:
        return SizedBox(
          width: width,
          height: height,
          child: Card(
            color: backgroundColor,
            elevation: elevation,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
              side: borderSide,
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subtitle,
                    style: commonTextStyle.copyWith(
                      fontSize: commonTextStyle.fontSize! * 0.75,
                      color: color.withValues(alpha: 0.8),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    text,
                    style: commonTextStyle.copyWith(
                      fontSize: commonTextStyle.fontSize! * 1.25,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case ComponentType.circularProgress:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: (height * 0.74).clamp(24, 140).toDouble(),
                  height: (height * 0.74).clamp(24, 140).toDouble(),
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth:
                        (borderSide == BorderSide.none ? 4 : borderSide.width)
                            .clamp(2, 12)
                            .toDouble(),
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: commonTextStyle.copyWith(
                    fontSize: commonTextStyle.fontSize! * 0.8,
                  ),
                ),
              ],
            ),
          ),
        );
      case ComponentType.sliderControl:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.6,
          child: Row(
            children: [
              if (text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    text,
                    style: commonTextStyle.copyWith(
                      fontSize: commonTextStyle.fontSize! * 0.85,
                    ),
                  ),
                ),
              Expanded(
                child: Slider(value: progress, onChanged: (_) {}),
              ),
            ],
          ),
        );
      case ComponentType.radioGroup:
        final options = _splitCsv(
          text,
          fallback: const ['Option A', 'Option B', 'Option C'],
        );
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.5,
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: options
                .take(4)
                .map(
                  (option) => Row(
                    children: [
                      Icon(
                        option == options.first
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        color: color,
                      ),
                      Expanded(
                        child: Text(
                          option,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: commonTextStyle.copyWith(
                            fontSize: commonTextStyle.fontSize! * 0.85,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
          ),
        );
      case ComponentType.dropdownField:
        final items = _splitCsv(
          text,
          fallback: const ['Choix 1', 'Choix 2', 'Choix 3'],
        );
        final label = subtitle.isEmpty ? 'Sélectionner' : subtitle;
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.6,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label (${items.first})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: commonTextStyle.copyWith(
                    fontSize: commonTextStyle.fontSize! * 0.85,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, color: color),
            ],
          ),
        );
      case ComponentType.listTile:
        final tile = Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.2),
              child: Icon(Icons.person_rounded, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: commonTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: commonTextStyle.copyWith(
                        fontSize: commonTextStyle.fontSize! * 0.8,
                        color: color.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        );
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.5,
          child: onAction == null
              ? tile
              : InkWell(onTap: onAction, child: tile),
        );
      case ComponentType.searchBar:
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.5,
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.isEmpty ? 'Rechercher...' : text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: commonTextStyle.copyWith(
                    fontSize: commonTextStyle.fontSize! * 0.9,
                  ),
                ),
              ),
              Icon(Icons.mic_none_rounded, color: color.withValues(alpha: 0.7)),
            ],
          ),
        );
      case ComponentType.ratingStars:
        final stars = ((progress * 5).round()).clamp(0, 5);
        return _tileContainer(
          width: width,
          height: height,
          borderRadius: borderRadius,
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          border: border,
          padding: padding * 0.5,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Icon(
                index < stars ? Icons.star_rounded : Icons.star_border_rounded,
                color: color,
                size: commonTextStyle.fontSize! + 6,
              ),
            ),
          ),
        );
    }
  }

  Widget _tileContainer({
    required double width,
    required double height,
    required double borderRadius,
    required Color backgroundColor,
    required Color gradientEndColor,
    required bool useGradient,
    required BoxBorder? border,
    required double padding,
    required Widget child,
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: _tileDecoration(
          backgroundColor: backgroundColor,
          gradientEndColor: gradientEndColor,
          useGradient: useGradient,
          borderRadius: borderRadius,
          border: border,
        ),
        child: child,
      ),
    );
  }

  BoxDecoration _tileDecoration({
    required Color backgroundColor,
    required Color gradientEndColor,
    required bool useGradient,
    required double borderRadius,
    required BoxBorder? border,
  }) {
    return BoxDecoration(
      color: useGradient ? null : backgroundColor,
      gradient: useGradient
          ? LinearGradient(
              colors: [backgroundColor, gradientEndColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: border,
    );
  }

  List<String> _splitCsv(String raw, {required List<String> fallback}) {
    final values = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return values.isEmpty ? fallback : values;
  }

  FontWeight _fontWeightFromValue(double value) {
    if (value < 200) return FontWeight.w100;
    if (value < 300) return FontWeight.w200;
    if (value < 400) return FontWeight.w300;
    if (value < 500) return FontWeight.w400;
    if (value < 600) return FontWeight.w500;
    if (value < 700) return FontWeight.w600;
    if (value < 800) return FontWeight.w700;
    if (value < 900) return FontWeight.w800;
    return FontWeight.w900;
  }

  Alignment _parseAlignment(String alignment) {
    switch (alignment) {
      case 'start':
        return Alignment.centerLeft;
      case 'end':
        return Alignment.centerRight;
      case 'center':
      default:
        return Alignment.center;
    }
  }
}
