import 'dart:convert';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  Map<String, String> _localizationStrings = {}; //if this doesn't work, switch '= {}' with 'late Map<String, String> _localizedStrings;'

  Future<bool> load() async {
    // Load the language JSON file from the "lang" folder
    String jsonString =
    await rootBundle.loadString('lib/test123/${locale.languageCode}.json');

    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizationStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  Future<void> setLocale(Locale locale) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final _languageCode = locale.languageCode;
    await _prefs.setString('locale', _languageCode);
    print('locale saved!');
  }

  static Future<Locale?> getLocale() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final String? _languageCode = _prefs.getString('locale');
    if (_languageCode == null) return null;

    Locale _locale;
    _languageCode == 'fi'
        ? _locale = const Locale('fi', 'FI')
        : _locale = const Locale('en', 'US');
    return _locale;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    String defaultStringkey = "";
    return _localizationStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations>
  {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    // Include all of your supported language codes here
    return ['en', 'fi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();

    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}