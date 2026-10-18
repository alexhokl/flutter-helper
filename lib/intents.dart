/// Android intents forwarded by `MainActivity` over a method channel.
///
/// `MainActivity` sends each intent as a `Map<String, String?>` with an
/// `action` key (`send`, `process_text` or `view`) plus `text`, `subject` or
/// `uri`. It answers `getInitialIntent` with the intent that launched the
/// app and calls `onIntent` for every later one. Each app turns the map into
/// its own intent type with the parser it passes to [IntentChannel].
library;

import 'package:flutter/services.dart';

/// Turns the map sent by `MainActivity` into an app intent, or null to
/// ignore it.
typedef IntentParser<T> = T? Function(Map<String, String?> raw);

/// Receives intents from `MainActivity` and parses them with [parse].
class IntentChannel<T> {
  IntentChannel(String name, this.parse) : _channel = MethodChannel(name);

  final MethodChannel _channel;
  final IntentParser<T> parse;

  /// Returns the intent that launched the app, if any.
  Future<T?> getInitialIntent() async {
    try {
      final raw = await _channel.invokeMapMethod<String, String?>(
        'getInitialIntent',
      );
      return raw == null ? null : parse(raw);
    } on MissingPluginException {
      // Not running on Android
      return null;
    }
  }

  /// Calls [onIntent] for every intent received while the app is running.
  void listen(void Function(T) onIntent) {
    _channel.setMethodCallHandler((call) async {
      if (call.method != 'onIntent' || call.arguments is! Map) return;
      final raw = Map<String, String?>.from(call.arguments as Map);
      final intent = parse(raw);
      if (intent != null) onIntent(intent);
    });
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}

/// Trims [value], returning null when nothing is left.
String? nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Collapses runs of whitespace, including newlines, into single spaces.
String squashWhitespace(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Splits a comma-separated list, trimming each value and dropping blanks
/// and duplicates while keeping the first occurrence's order. [normalise]
/// is applied to each value first, e.g. to lowercase tags.
List<String> splitList(String? value, {String Function(String)? normalise}) {
  if (value == null) return const [];
  final seen = <String>{};
  return [
    for (final part in value.split(','))
      if ((normalise ?? _identity)(part.trim()) case final v
          when v.isNotEmpty && seen.add(v))
        v,
  ];
}

String _identity(String value) => value;
