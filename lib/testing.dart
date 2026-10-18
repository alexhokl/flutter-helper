/// Helpers for the apps' widget tests. Import from test code only.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Replaces both shared preferences APIs with empty in-memory stores, or
/// stores seeded with [values]. Call from `setUp`.
void setUpInMemoryPrefs([Map<String, Object> values = const {}]) {
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(values);
  SharedPreferencesAsyncPlatform.instance = values.isEmpty
      ? InMemorySharedPreferencesAsync.empty()
      : InMemorySharedPreferencesAsync.withData(values);
}

/// Wraps [child] in a [MaterialApp] so it can be pumped on its own.
///
/// Pass the app's generated `AppLocalizations.localizationsDelegates` and
/// `supportedLocales` when the widget looks up localised strings.
Widget wrapForTest(
  Widget child, {
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  Iterable<Locale> supportedLocales = const [Locale('en')],
  ThemeData? theme,
}) {
  return MaterialApp(
    localizationsDelegates: localizationsDelegates,
    supportedLocales: supportedLocales,
    theme: theme,
    home: child is Scaffold ? child : Scaffold(body: child),
  );
}
