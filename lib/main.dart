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

  // TODO: first url would be different when using commons?
  // -> what is the default in future versions?
  var firstUrl="https://ajapaik.toolforge.org/api/ajapaiknearest.php?search=&limit=100&orderby=alpha&orderdirection=desc";

  @override
  void initState() {
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

    // TODO: determine from user somehow what is wanted..
    // we may need different instances at same time if user wants
    // to upload to social media and commons at same time
    // -> need to improve handling of sessions for that
    //
    // for now, expect this: change later
    controller.setServer(ServerType.serverAjapaik);
    await controller.doApiLogin(provider, username, token);
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
