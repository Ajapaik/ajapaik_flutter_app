import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../getxnavigation.dart';
import '../rephoto.dart';

class MainPage extends StatefulWidget {

  final controller = Get.put(Controller());

  String pageTitle = "";
  String dataSourceUrl = "";

  MainPage({Key? key}) : super(key: key);

  MainPage.network(this.pageTitle, this.dataSourceUrl, {Key? key})
      : super(key: key);

  @override
  MainPageState createState() =>MainPageState();
}

class MainPageState extends State<MainPage> {

  String orderBy = "alpha";
  String orderDirection = "desc";
  int renderState = 1;
  bool nameVisibility = false;
  bool searchVisibility = false;
  final myController = TextEditingController();

  Future<List<Album>>? _albumData;

  Future<List<Album>> albumData(BuildContext context) {
    return _albumData!;
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
  Widget build(BuildContext context) {

    _saveBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('visibility', nameVisibility);
    }

    _searchBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('searchVisibility', searchVisibility);
    }

    return Scaffold(
      body: Column(children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () {  },
            child: const Text('Photos'),),
            ElevatedButton(onPressed: () {  },
              child: const Text('Map'),),
            ElevatedButton(onPressed: () {  },
              child: const Text('Albums'),),
          ],
        ),
        const SizedBox(height: 20),
        Flexible(
            child: FutureBuilder<List<Album>>(
              future: albumData(context),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) (snapshot.error);

                return (snapshot.hasData)
                    ? MainPageList(
                    albums: snapshot.data,
                    toggle: nameVisibility | searchVisibility,
                    renderState: renderState)
                    : const Center(child: CircularProgressIndicator());
              },
            )),
      ],
      ),
    );
  }
}

class MainPageList extends StatelessWidget {
  final List<Album>? albums;
  final bool toggle;
  final int renderState;

  const MainPageList({Key? key, this.albums, this.toggle = true, required this.renderState})
      : super(key: key);

  Future<void> _showphoto(context, index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => RephotoScreen(
            historicalPhotoId:
            albums!.first.features[index].properties.id.toString(),
            historicalPhotoUri: albums!
                .first.features[index].properties.thumbnail
                .toString(),
            historicalName:
            albums!.first.features[index].properties.name.toString(),
            historicalDate:
            albums!.first.features[index].properties.date.toString(),
            historicalAuthor:
            albums!.first.features[index].properties.author.toString(),
            historicalSurl: albums!
                .first.features[index].properties.sourceUrl
                .toString(),
            historicalLabel: albums!
                .first.features[index].properties.sourceLabel
                .toString(),
            historicalCoordinates: albums!.first.features[index].geometry,
          )),
    );
  }

  void _moveToGeoJson(context, index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MainPage.network(
              albums!.first.features[index].properties.name!,
              albums!.first.features[index].properties.geojson!)),
    );
  }

  @override
  Widget build(BuildContext context) {
      if(renderState == 1) {
        return photoView(context);
      }
      if (renderState == 2){

      }
      throw Exception('We couldnt find what you were looking for');
  }

  Widget photoView (context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    if (height > width) {
      return MasonryGridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        itemCount: albums!.first.features.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return headerTile(context, index);
          } else {
            return contentTile(context, index);
          }
        },
      );
    } else {
      return MasonryGridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        itemCount: albums!.first.features.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return headerTile(context, index);
          } else {
            return contentTile(context, index);
          }
        },
      );
    }
  }

  Widget headerTile(context, index) {
    StatelessWidget headerImage;

    if (albums!.first.image != "") {
      headerImage = CachedNetworkImage(imageUrl: albums!.first.image);
    } else {
      headerImage = Container();
    }

    return Center(
        child:
        Column(children: [headerImage, Text(albums!.first.description)]));
  }

  Widget contentTile(context, index) {
    // Remove header row from index
    index = index - 1;
    return GestureDetector(
      onTap: () {
        if (albums!.first.features[index].properties.geojson != null &&
            albums!.first.features[index].properties.geojson != "") {
          _moveToGeoJson(context, index);
        } else {
          _showphoto(context, index);
        }
      },
      child: Column(children: [
        CachedNetworkImage(
            imageUrl:
            albums!.first.features[index].properties.thumbnail.toString()),
        Visibility(
          child: Text(
            albums!.first.features[index].properties.name.toString(),
            textAlign: TextAlign.center,
          ),
          visible: toggle,
        ),
        // Favorites code snippet for icons to favorite pictures
        // GestureDetector(
        //   onTap: () {
        //
        //   },
        //   child: const Align(
        //     alignment: Alignment.topRight,
        //    child: Icon(Icons.favorite_outlined, color: Colors.white, size: 35),
        // ))
      ]),
    );
  }



}