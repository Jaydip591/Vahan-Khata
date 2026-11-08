import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

const _kLocale = 'locale';

/// Gujarati by default; English is the other option. Saved on the device.
final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final saved = ref.read(sharedPreferencesProvider).getString(_kLocale);
    return Locale(saved == 'en' ? 'en' : 'gu');
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(sharedPreferencesProvider).setString(_kLocale, locale.languageCode);
  }
}
