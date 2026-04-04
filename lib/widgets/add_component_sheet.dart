import 'package:flutter/material.dart';

import '../models/component_type.dart';

class AddComponentSheet extends StatelessWidget {
  const AddComponentSheet({super.key, required this.onSelected});

  final ValueChanged<ComponentType> onSelected;

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
                  children: entries
                      .map(
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
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
