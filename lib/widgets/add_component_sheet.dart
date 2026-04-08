import 'dart:async';

import 'package:flutter/material.dart';

import '../models/component_type.dart';
import '../models/component_template_model.dart';

class AddComponentSheet extends StatefulWidget {
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
  State<AddComponentSheet> createState() => _AddComponentSheetState();
}

class _AddComponentSheetState extends State<AddComponentSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  static const _entries = <(ComponentType, IconData)>[
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
    // nouveaux composants
    (ComponentType.carousel, Icons.view_carousel_outlined),
    (ComponentType.datePicker, Icons.calendar_today_outlined),
    (ComponentType.navigationDrawer, Icons.menu_rounded),
    (ComponentType.stepper, Icons.linear_scale_rounded),
    (ComponentType.bottomSheetPreview, Icons.vertical_align_bottom_rounded),
    (ComponentType.segmentedButton, Icons.splitscreen_rounded),
    (ComponentType.expansionTile, Icons.expand_rounded),
    (ComponentType.alertDialog, Icons.warning_amber_rounded),
    (ComponentType.snackbarPreview, Icons.sms_outlined),
    (ComponentType.dataTable, Icons.table_chart_outlined),
    (ComponentType.skeleton, Icons.blur_on_rounded),
    (ComponentType.annotation, Icons.sticky_note_2_outlined),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? _entries
        : _entries
              .where(
                (e) => e.$1.label.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
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
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Rechercher un composant…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    if (_query.isEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: Text(
                          'Mes templates',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (widget.templates.isEmpty)
                        const ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          leading: Icon(Icons.info_outline_rounded),
                          title: Text('Aucun template enregistré'),
                          subtitle: Text(
                            'Sélectionne des éléments puis menu > Enregistrer en template.',
                          ),
                        )
                      else
                        ...widget.templates.map(
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
                            trailing: widget.onDeleteTemplate == null
                                ? null
                                : IconButton(
                                    tooltip: 'Supprimer template',
                                    onPressed: () async {
                                      await widget.onDeleteTemplate!(template);
                                    },
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                            onTap: () {
                              widget.onSelectedTemplate?.call(template);
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      const Divider(height: 20),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                        child: Text(
                          'Composants standards',
                          style: Theme.of(
                            context,
                          ).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Aucun composant trouvé.'),
                      )
                    else
                      ...filtered.map(
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
                            widget.onSelected(item.$1);
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
