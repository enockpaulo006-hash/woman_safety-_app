import 'package:flutter/material.dart';

import '../localization/app_strings.dart';
import 'app_settings_controller.dart';

class AppSettingsScope extends InheritedNotifier<AppSettingsController> {
  const AppSettingsScope({
    required AppSettingsController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppSettingsController controllerOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    assert(scope != null, 'AppSettingsScope is missing in the widget tree.');
    return scope!.notifier!;
  }

  static AppSettingsController readControllerOf(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppSettingsScope>();
    final scope = element?.widget as AppSettingsScope?;
    assert(scope != null, 'AppSettingsScope is missing in the widget tree.');
    return scope!.notifier!;
  }

  static AppStrings stringsOf(BuildContext context) {
    return AppStrings(controllerOf(context).language);
  }

  static AppStrings readStringsOf(BuildContext context) {
    return AppStrings(readControllerOf(context).language);
  }
}
