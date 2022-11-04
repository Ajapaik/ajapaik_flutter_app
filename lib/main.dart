import 'dart:async';
import 'package:ajapaik_flutter_app/localization.dart';
import 'package:ajapaik_flutter_app/services/geolocation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'albumlist.dart';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'sessioncontroller.dart';
import 'uploadcontroller.dart';
import 'localization.dart';
import 'preferences.dart';
import 'draftstorage.dart';
import 'imagestorage.dart';

void main()  {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final sessionController = Get.put(SessionController());
  final uploadController = Get.put(UploadController());
  final locator = Get.put(AppLocator());
  final prefs = Get.put(Preferences());
  final draftStorage = Get.put(DraftStorage());
  final imageStorage = Get.put(ImageStorage());

  @override
  void initState() {
    // TODO: should load localizations before starting to build the UI
    // so that localized strings are actually available
    //AppLocalizations.load()

    initDeepLinks();
    prefs.loadPrefs();
    locator.init();
    super.initState();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> openAppLink(Uri uri) async {
    String provider = uri.queryParameters["provider"].toString();
    String username = "false";
    String token = uri.queryParameters["token"].toString();

    // TODO: determine from user somehow what is wanted..
    // we may need different instances at same time if user wants
    // to upload to social media and commons at same time
    // -> need to improve handling of sessions for that
    //
    // for now, expect this: change later
    sessionController.setServer(ServerType.serverAjapaik);
    await sessionController.doApiLogin(provider, username, token);
    await closeInAppWebView();
    Get.back();
  }

  void initDeepLinks() async {
    _appLinks = AppLinks();
    // Handle link when app is in warm state (front or background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('onAppLink: $uri');
      openAppLink(uri);
    });
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Note: later parts want to use localized string instead,
    // but here we haven't loaded localized strings yet..
    //
    // -> should load localizations first before starting to build UI
    //
    const String appTitle = "Ajapaik nearest";

    GetMaterialApp gma = GetMaterialApp(
        supportedLocales: AppLocalizations.getSupportedLocales(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],

      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocaleLanguage in supportedLocales) {
          if (supportedLocaleLanguage.languageCode == locale?.languageCode &&
              supportedLocaleLanguage.countryCode == locale?.countryCode) {
            return supportedLocaleLanguage;
          }
        }

        // If device not support with locale to get language code then default get first on from the list
        return supportedLocales.first;
      },

      title: appTitle,
      theme: ThemeData.dark(),
      home: AlbumListPage(appTitle),
    );
    return gma;
  }
}
