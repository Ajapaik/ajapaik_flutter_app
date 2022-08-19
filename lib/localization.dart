import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

// these should be loaded as what are actually supported (files that exist),
// but maybe some human check can be useful..
// note: each supported asset should be in pubspec.yaml as well as stated in asset_bundle.dart
// -> needs human intervention in any case..
List<Locale> appSupportedLocales = [
  const Locale('en', 'US'),
  const Locale('fi'),
  const Locale('it'),
  const Locale('pt', 'BR'),
  const Locale('sv'),
];
Locale? getLocale(String? languageCode) {
  if (languageCode == null) {
    return null;
  }

  for (int i = 0; i < appSupportedLocales.length; i++) {
    if (appSupportedLocales[i].languageCode == languageCode) {
      return appSupportedLocales[i];
    }
  }
  return null;
}

class AppLocalizations {
  final Locale currentLocale;

  AppLocalizations(this.currentLocale);

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // Static member to have a simple access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate =
  AppLocalizationsDelegate();

  Map<String, String> localizationStrings = {};
  Map<String, String> defaultLocalizationStrings = {};

  Future<bool> loadStrings(String languageCode, { bool isDefaults = false }) async {
    // Load the language JSON file from the "lang" folder
    String jsonString = await rootBundle.loadString('i18n/$languageCode.json');

    Map<String, dynamic> jsonMap = json.decode(jsonString);
    Map<String, String> strings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    if (isDefaults == false) {
      localizationStrings = strings;
    } else {
      defaultLocalizationStrings = strings;
    }
    return true;
  }

  // this is stored for later, not just set:
  // what is the point of this? user can change language of the OS
  // or it could be selected from menu -> no need for persistent storage
  Future<void> storeLanguageCode(Locale locale) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', locale.languageCode);
  }

  Future<String?> loadLanguageCode() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('locale');
  }

  static List<Locale> getSupportedLocales() {
    return appSupportedLocales;
  }

  // This method will be called from every widget which needs a localized text
  String translate(String key) {
    String? translation = localizationStrings[key] ?? defaultLocalizationStrings[key];
    return translation ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations>
  {
  // This delegate instance will never change (it doesn't even have fields!)
  // It can provide a constant constructor.
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    if (getLocale(locale.languageCode) != null) {
      return true;
    }
    return false;
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // AppLocalizations class is where the JSON loading actually runs
    AppLocalizations localizations = AppLocalizations(locale);

    // note: loading can throw exceptions,
    // at least try to catch and handle if language isn't supported
    try {
      await localizations.loadStrings(locale.languageCode);
    }
    catch (e) {
      print("failed loading localizations for ${locale.languageCode}");
      //rethrow;
    }

    await localizations.loadStrings('en', isDefaults: true);
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
