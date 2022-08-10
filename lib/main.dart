import 'dart:async';
import 'package:ajapaik_flutter_app/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'albumlist.dart';
import 'package:app_links/app_links.dart';
import 'package:get/get.dart';
import 'getxnavigation.dart';
import 'localization.dart';

void main()  {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final controller = Get.put(Controller());

  MyApp({Key? key}) : super(key: key);

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final controller = Get.put(Controller());

  @override
  void initState() {
    print("initstate");
    initDeepLinks();
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
    await controller.doApiLogin(provider, username, token);
    print("onAppLink");
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
    const appTitle = 'Nearest';
    var firstUrl="https://ajapaik.toolforge.org/api/ajapaiknearest.php?search=&limit=100&orderby=alpha&orderdirection=desc";

    GetMaterialApp gma = GetMaterialApp(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('fi', 'FI'),
      ],
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
      home: AlbumListPage.network(appTitle, firstUrl),
    );
    return gma;
  }
}
