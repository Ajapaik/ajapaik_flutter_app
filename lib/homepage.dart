import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

import 'data/album.geojson.dart';

class HomePage extends StatefulWidget {

  String dataSourceUrl = "";

  HomePage({Key? key}) : super(key: key);

  HomePage.network(this.dataSourceUrl, {Key? key}) : super(key: key);

  @override
  HomePageState createState() =>HomePageState();
}

class HomePageState extends State<HomePage> {
  String orderBy = "alpha";
  String orderDirection = "desc";
  final myController = TextEditingController();

  Future<List<Album>>? _albumData;

  Future<List<Album>> test(BuildContext context) {
    return _albumData!;
  }

  void sorting() async {
    setState(() {
      orderBy = (orderBy == "alpha") ? "distance" : "alpha";
      refresh();
    });
    Get.snackbar(
      "Sorting",
      "Order by " + orderBy,
      // duration: Duration(seconds: 3),
    );
  }

  String getDataSourceUrl() {
    String url = widget.dataSourceUrl;
    if (url.contains("?")) {
      url += "&orderby=" + orderBy + "&orderdirection=" + orderDirection;
    } else {
      url += "?orderby=" + orderBy + "&orderdirection=" + orderDirection;
    }
    String searchkey=myController.text;
    url += "&search=" + searchkey;
    return url;
  }

  onSearchTextChanged(String text) async {
    if (text.isEmpty) {
      setState(() {});
      return;
    }
  }

  void refresh() async {
    String url = getDataSourceUrl();
    await (_albumData = fetchAlbum(http.Client(), url));
  }

  @override
  void initState() {
    refresh();
    super.initState();
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Container(
                alignment: Alignment.center,
                width: 300,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                ),
                child: Center(
                    child: TextField(
                      controller: myController,
                      textInputAction: TextInputAction.go,
                      textAlign: TextAlign.start,
                      onSubmitted: (value) {
                        setState(() {
                          refresh();
                        });
                      },
                      onChanged: (value) => onSearchTextChanged(value),
                      decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Search for images',
                      prefixIcon: IconButton(
                          onPressed: () {
                              setState(() {
                                refresh();
                              });
                              onSearchTextChanged('');
                          }, icon: const Icon(Icons.search)),
                      suffixIcon: IconButton(
                          onPressed: () {
                            myController.clear();
                          }, icon: const Icon(Icons.clear))),
                )))));
  }
}