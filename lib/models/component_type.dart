enum ComponentType {
  text,
  button,
  card,
  imagePlaceholder,
  textField,
  chip,
  avatar,
  divider,
  icon,
  appBar,
  switchTile,
  checkboxTile,
  progressBar,
  badge,
  containerBox,
  iconButton,
  floatingActionButton,
  bottomNav,
  tabBar,
  banner,
  statCard,
  circularProgress,
  sliderControl,
  radioGroup,
  dropdownField,
  listTile,
  searchBar,
  ratingStars,
}

extension ComponentTypeX on ComponentType {
  String get label {
    switch (this) {
      case ComponentType.text:
        return 'Text';
      case ComponentType.button:
        return 'Button';
      case ComponentType.card:
        return 'Card';
      case ComponentType.imagePlaceholder:
        return 'Image Placeholder';
      case ComponentType.textField:
        return 'TextField';
      case ComponentType.chip:
        return 'Chip';
      case ComponentType.avatar:
        return 'Avatar';
      case ComponentType.divider:
        return 'Divider';
      case ComponentType.icon:
        return 'Icon';
      case ComponentType.appBar:
        return 'AppBar';
      case ComponentType.switchTile:
        return 'Switch';
      case ComponentType.checkboxTile:
        return 'Checkbox';
      case ComponentType.progressBar:
        return 'Progress Bar';
      case ComponentType.badge:
        return 'Badge';
      case ComponentType.containerBox:
        return 'Container';
      case ComponentType.iconButton:
        return 'Icon Button';
      case ComponentType.floatingActionButton:
        return 'FAB';
      case ComponentType.bottomNav:
        return 'Bottom Nav';
      case ComponentType.tabBar:
        return 'Tab Bar';
      case ComponentType.banner:
        return 'Banner';
      case ComponentType.statCard:
        return 'Stat Card';
      case ComponentType.circularProgress:
        return 'Circular Progress';
      case ComponentType.sliderControl:
        return 'Slider';
      case ComponentType.radioGroup:
        return 'Radio Group';
      case ComponentType.dropdownField:
        return 'Dropdown';
      case ComponentType.listTile:
        return 'List Tile';
      case ComponentType.searchBar:
        return 'Search Bar';
      case ComponentType.ratingStars:
        return 'Rating Stars';
    }
  }

  String get value => name;

  static ComponentType fromValue(String value) {
    return ComponentType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => ComponentType.text,
    );
  }
}
