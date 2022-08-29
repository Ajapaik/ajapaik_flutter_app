import 'dart:convert';
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
  //bool isLoaded = false; // localizations loaded yet?

  AppLocalizations(this.currentLocale);

  // Helper method to keep the code in the widgets concise
  // Localizations are accessed using an InheritedWidget "of" syntax
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  // reduce calls to something sensible
  static String getText(BuildContext context, String key) {
    return AppLocalizations.of(context)!.translate(key);
  }

  // Static instance for access to the delegate from the MaterialApp
  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();

  Map<String, String> localizationStrings = {};
  Map<String, String> defaultLocalizationStrings = {};

  Future<bool> loadStrings(String languageCode, { bool isDefaults = false }) async {
    // Load the language JSON file
    //
    // Note: flutter documentation claims that part of path is implied
    // but this isn't true, at least on Android emulator.
    // So regardless what documentation says, use full path to make it work.
    //
    String file = 'assets/i18n/$languageCode.json';
    String jsonString = await rootBundle.loadString(file);

    Map<String, dynamic> jsonMap = json.decode(jsonString);
    Map<String, String> strings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    if (isDefaults == false) {
      localizationStrings = strings;
    } else {
      defaultLocalizationStrings = strings;
    }
    //isLoaded = true;
    return true;
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
      print("failed loading localizations for ${locale.languageCode}: ${e.toString()}");
      //rethrow;
    }
    try {
      await localizations.loadStrings('en', isDefaults: true);
    }
    catch (e) {
      print("failed loading localizations for ${locale.languageCode}: ${e.toString()}");
      //rethrow;
    }
    return localizations;
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
