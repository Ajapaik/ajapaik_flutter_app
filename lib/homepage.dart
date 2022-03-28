import 'package:ajapaik_flutter_app/page/events_page.dart';
import 'package:ajapaik_flutter_app/page/liked_page.dart';
import 'package:ajapaik_flutter_app/page/main_page.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import 'data/album.geojson.dart';
import 'data/project.json.dart';
import 'demolocalization.dart';
import 'getxnavigation.dart';

class HomePage extends StatefulWidget {

  String dataSourceUrl = "https://fiwiki-tools.toolforge.org/api/ajapaiknearest.php?latitude=49.84189&longitude=24.0315&search=&limit=100&orderby=alpha&orderdirection=desc&search=Auroran&latitude=60.1952073&longitude=24.9252243";

  HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() =>HomePageState();
}

class HomePageState extends State<HomePage> {
  String orderBy = "alpha";
  String orderDirection = "desc";
  int _selectedIndex = 0;
  final controller = Get.put(Controller());
  final myController = TextEditingController();

  final screens = [
    MainPage.network("", "https://fiwiki-tools.toolforge.org/api/ajapaiknearest.php?latitude=49.84189&longitude=24.0315&search=&limit=100&orderby=alpha&orderdirection=desc&search=Auroran&latitude=60.1952073&longitude=24.9252243"),
    const LikedPage(),
    const Text(''),
    const EventsPage(),
    const Text(''),
  ];

  Future<List<Album>>? _albumData;

  Future<List<Album>> albumData(BuildContext context) {
    return _albumData!;
  }

  @override
  void initState() {
    controller.loadSession().then((_) => setState(() {
      ("Updating login status to screen. Session " +
          controller.getSession());
    }));
//    refresh();
    super.initState();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    (controller.getSession());
    bool loggedIn = !(controller.getSession() == "");

    return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: <BottomNavigationBarItem> [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home_rounded),
              label: (AppLocalizations.of(context)!.translate('homePage-NavItem1')
              )),
          BottomNavigationBarItem(
              icon: const Icon(Icons.favorite_border),
              label: (AppLocalizations.of(context)!.translate('homePage-NavItem2')
              )),
          BottomNavigationBarItem(
              icon: const Icon(Icons.camera),
              label: (AppLocalizations.of(context)!.translate('homePage-NavItem3')
              )),
          BottomNavigationBarItem(
              icon: const Icon(Icons.explore),
              label: (AppLocalizations.of(context)!.translate('homePage-NavItem4')
              )),
          BottomNavigationBarItem(
            icon: Icon((loggedIn ? Icons.person : Icons.login)),
            label: (loggedIn
                ? (AppLocalizations.of(context)!
                    .translate('homePage-NavItem6'))
                : (AppLocalizations.of(context)!
                    .translate('homePage-NavItem5'))),
          )
        ],
      ),
    );
  }
}

class PhotoList extends StatelessWidget {
  final List<Project>? photos;

  const PhotoList({Key? key, required this.photos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
}