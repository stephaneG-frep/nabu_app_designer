import 'dart:async';

import 'package:flutter/material.dart';

import '../models/component_type.dart';
import '../models/component_template_model.dart';

class AddComponentSheet extends StatelessWidget {
  const AddComponentSheet({
    super.key,
    required this.onSelected,
    this.templates = const [],
    this.onSelectedTemplate,
    this.onDeleteTemplate,
  });

  final ValueChanged<ComponentType> onSelected;
  final List<ComponentTemplateModel> templates;
  final FutureOr<void> Function(ComponentTemplateModel template)?
  onSelectedTemplate;
  final FutureOr<void> Function(ComponentTemplateModel template)?
  onDeleteTemplate;

  @override
  Widget build(BuildContext context) {
    final entries = <(ComponentType, IconData)>[
      (ComponentType.text, Icons.text_fields_rounded),
      (ComponentType.button, Icons.smart_button_outlined),
      (ComponentType.card, Icons.credit_card_rounded),
      (ComponentType.imagePlaceholder, Icons.image_outlined),
      (ComponentType.textField, Icons.short_text_rounded),
      (ComponentType.chip, Icons.sell_outlined),
      (ComponentType.avatar, Icons.account_circle_outlined),
      (ComponentType.divider, Icons.horizontal_rule_rounded),
      (ComponentType.icon, Icons.star_outline_rounded),
      (ComponentType.appBar, Icons.view_headline_rounded),
      (ComponentType.switchTile, Icons.toggle_on_outlined),
      (ComponentType.checkboxTile, Icons.check_box_outlined),
      (ComponentType.progressBar, Icons.linear_scale_rounded),
      (ComponentType.badge, Icons.bookmark_border_rounded),
      (ComponentType.containerBox, Icons.crop_square_rounded),
      (ComponentType.iconButton, Icons.radio_button_checked_rounded),
      (ComponentType.floatingActionButton, Icons.add_circle_outline_rounded),
      (ComponentType.bottomNav, Icons.space_dashboard_outlined),
      (ComponentType.tabBar, Icons.tab_rounded),
      (ComponentType.banner, Icons.campaign_outlined),
      (ComponentType.statCard, Icons.stacked_line_chart_rounded),
      (ComponentType.circularProgress, Icons.donut_large_rounded),
      (ComponentType.sliderControl, Icons.tune_rounded),
      (ComponentType.radioGroup, Icons.radio_button_checked_rounded),
      (ComponentType.dropdownField, Icons.arrow_drop_down_circle_outlined),
      (ComponentType.listTile, Icons.view_list_rounded),
      (ComponentType.searchBar, Icons.search_rounded),
      (ComponentType.ratingStars, Icons.star_half_rounded),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ajouter un composant',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Text(
                        'Mes templates',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (templates.isEmpty)
                      const ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        leading: Icon(Icons.info_outline_rounded),
                        title: Text('Aucun template enregistré'),
                        subtitle: Text(
                          'Sélectionne des éléments puis menu > Enregistrer en template.',
                        ),
                      )
                    else
                      ...templates.map(
                        (template) => ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          leading: const Icon(Icons.bookmarks_outlined),
                          title: Text(template.name),
                          subtitle: Text(
                            '${template.components.length} élément(s)',
                          ),
                          trailing: onDeleteTemplate == null
                              ? null
                              : IconButton(
                                  tooltip: 'Supprimer template',
                                  onPressed: () async {
                                    await onDeleteTemplate!(template);
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                          onTap: () {
                            onSelectedTemplate?.call(template);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    const Divider(height: 20),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Text(
                        'Composants standards',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ...entries.map(
                      (item) => ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        leading: Icon(item.$2),
                        title: Text(item.$1.label),
                        onTap: () {
                          onSelected(item.$1);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
