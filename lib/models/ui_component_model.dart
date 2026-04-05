import 'component_type.dart';

class UIComponentModel {
  UIComponentModel({
    required this.id,
    required this.type,
    required this.properties,
  });

  final String id;
  final ComponentType type;
  final Map<String, dynamic> properties;

  factory UIComponentModel.createDefault({
    required String id,
    required ComponentType type,
  }) {
    switch (type) {
      case ComponentType.text:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Nouveau texte',
            width: 220,
            height: 60,
          ),
        );
      case ComponentType.button:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'Bouton', width: 180, height: 52),
        );
      case ComponentType.card:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Card title',
            width: 240,
            height: 96,
          ),
        );
      case ComponentType.imagePlaceholder:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'Image', width: 220, height: 140),
        );
      case ComponentType.textField:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Votre texte',
            width: 240,
            height: 62,
          ),
        );
      case ComponentType.chip:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'Tag', width: 140, height: 44),
        );
      case ComponentType.avatar:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'A', width: 90, height: 90),
        );
      case ComponentType.divider:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: '', width: 240, height: 24),
        );
      case ComponentType.icon:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'Icon', width: 90, height: 84),
        );
      case ComponentType.appBar:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Mon écran',
            width: 320,
            height: 64,
          ),
        );
      case ComponentType.switchTile:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Activer option',
            width: 240,
            height: 56,
          ),
        );
      case ComponentType.checkboxTile:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'J’accepte',
            width: 240,
            height: 56,
          ),
        );
      case ComponentType.progressBar:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: '60%', width: 240, height: 28)
            ..['progress'] = 0.6,
        );
      case ComponentType.badge:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'NOUVEAU', width: 120, height: 34),
        );
      case ComponentType.containerBox:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Container',
            width: 220,
            height: 110,
          ),
        );
      case ComponentType.iconButton:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'Action', width: 56, height: 56),
        );
      case ComponentType.floatingActionButton:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: '+', width: 62, height: 62),
        );
      case ComponentType.bottomNav:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Accueil,Recherche,Profil',
            width: 320,
            height: 62,
          ),
        );
      case ComponentType.tabBar:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Tab 1,Tab 2,Tab 3',
            width: 300,
            height: 46,
          ),
        );
      case ComponentType.banner:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Promotion spéciale',
            width: 300,
            height: 90,
          ),
        );
      case ComponentType.statCard:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: '12 480', width: 180, height: 108)
            ..['subtitle'] = 'Utilisateurs',
        );
      case ComponentType.circularProgress:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: '68%', width: 110, height: 110)
            ..['progress'] = 0.68,
        );
      case ComponentType.sliderControl:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: 'Volume', width: 260, height: 56)
            ..['progress'] = 0.4,
        );
      case ComponentType.radioGroup:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Option A,Option B,Option C',
            width: 280,
            height: 120,
          ),
        );
      case ComponentType.dropdownField:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Choix 1,Choix 2,Choix 3',
            width: 240,
            height: 56,
          )..['subtitle'] = 'Sélectionner',
        );
      case ComponentType.listTile:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Titre élément',
            width: 300,
            height: 76,
          )..['subtitle'] = 'Sous-titre',
        );
      case ComponentType.searchBar:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(
            text: 'Rechercher...',
            width: 300,
            height: 52,
          ),
        );
      case ComponentType.ratingStars:
        return UIComponentModel(
          id: id,
          type: type,
          properties: _baseProperties(text: '4/5', width: 180, height: 50)
            ..['progress'] = 0.8,
        );
    }
  }

  static Map<String, dynamic> _baseProperties({
    required String text,
    required double width,
    required double height,
  }) {
    return {
      'text': text,
      'color': 0xFF2A9D8F,
      'backgroundColor': 0xFFE8F4F2,
      'gradientEndColor': 0xFFD5E9E6,
      'useGradient': false,
      'fontSize': 16.0,
      'fontWeight': 600.0,
      'letterSpacing': 0.0,
      'lineHeight': 1.2,
      'padding': 12.0,
      'borderRadius': 12.0,
      'width': width,
      'height': height,
      'margin': 0.0,
      'visible': true,
      'opacity': 1.0,
      'borderColor': 0xFF2A9D8F,
      'borderWidth': 0.0,
      'elevation': 2.0,
      'rotation': 0.0,
      'scale': 100.0,
      'shadowBlur': 0.0,
      'shadowOpacity': 0.0,
      'shadowOffsetY': 0.0,
      'progress': 0.6,
      'alignment': 'center',
      'row': -1,
      'locked': false,
      'actionType': 'none',
      'targetScreenId': '',
      'imagePath': '',
    };
  }

  UIComponentModel copyWith({
    String? id,
    ComponentType? type,
    Map<String, dynamic>? properties,
  }) {
    return UIComponentModel(
      id: id ?? this.id,
      type: type ?? this.type,
      properties: properties ?? Map<String, dynamic>.from(this.properties),
    );
  }

  UIComponentModel updateProperty(String key, dynamic value) {
    final updated = Map<String, dynamic>.from(properties)..[key] = value;
    return copyWith(properties: updated);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type.value, 'properties': properties};
  }

  factory UIComponentModel.fromJson(Map<String, dynamic> json) {
    return UIComponentModel(
      id: json['id'] as String,
      type: ComponentTypeX.fromValue(json['type'] as String? ?? ''),
      properties: Map<String, dynamic>.from(
        (json['properties'] as Map?) ?? <String, dynamic>{},
      ),
    );
  }
}
