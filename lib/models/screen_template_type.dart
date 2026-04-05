enum ScreenTemplateType {
  login,
  dashboard,
  profile,
  onboarding,
}

extension ScreenTemplateTypeX on ScreenTemplateType {
  String get label {
    switch (this) {
      case ScreenTemplateType.login:
        return 'Login';
      case ScreenTemplateType.dashboard:
        return 'Dashboard';
      case ScreenTemplateType.profile:
        return 'Profile';
      case ScreenTemplateType.onboarding:
        return 'Onboarding';
    }
  }
}
