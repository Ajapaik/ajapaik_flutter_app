import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'camera.dart';

class AlbumListPage extends StatefulWidget {
  String pageTitle = "Not set";
  String dataSourceUrl = "";

  AlbumListPage({Key? key}) : super(key: key);

  AlbumListPage.network(this.pageTitle, this.dataSourceUrl);

  @override
  AlbumListPageState createState() => AlbumListPageState();
}

class AlbumListPageState extends State<AlbumListPage> {
  String orderBy = "distance";
  String orderDirection = "desc";
  bool searchDialogVisible = false;

  Future<List<Album>>? _albumData;

  void sorting() {
    setState(() {
      this.orderBy = (this.orderBy == "distance") ? "alpha" : "distance";
      refresh();
    });
  }

  void refresh() async {
    await (this._albumData = fetchAlbum(http.Client(), getDataSourceUrl()));
  }

  void toggleSearchDialog() {
    this.searchDialogVisible = searchDialogVisible ? false : true;
  }

  String getDataSourceUrl() {
    String url = widget.dataSourceUrl;
    if (url.contains("?")) {
      url +=
          "&orderby=" + this.orderBy + "&orderdirection=" + this.orderDirection;
    } else {
      url +=
          "?orderby=" + this.orderBy + "&orderdirection=" + this.orderDirection;
    }
    return url;
  }

  @override
  void initState() {
    refresh();

    super.initState();
  }

  Future<List<Album>> test(BuildContext context) {
    return this._albumData!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pageTitle),
        actions: <Widget>[
/*          IconButton(
              icon: Icon(Icons.search),
              tooltip: "Search",
              onPressed: toggleSearchDialog),*/
          IconButton(
              icon: Icon(((this.orderBy == "distance")
                  ? Icons.sort_sharp
                  : Icons.sort_by_alpha)),
              tooltip: "Sort",
              onPressed: sorting),
        ],
      ),
      body: Column(children: [
        Flexible(
            child: FutureBuilder<List<Album>>(
          future: test(context),
          builder: (context, snapshot) {
            if (snapshot.hasError) print(snapshot.error);

            return (snapshot.hasData)
                ? AlbumList(albums: snapshot.data)
                : Center(child: CircularProgressIndicator());
          },
        )),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {},
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Nearest',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_a_photo),
            label: 'Add a photo',
          ),
        ],
      ),
    );
  }
}

class AlbumList extends StatelessWidget {
  final List<Album>? albums;

  AlbumList({Key? key, this.albums}) : super(key: key);

  void _take_rephoto(context, index) {
    availableCameras().then((availableCameras) {
      CameraDescription firstCamera = availableCameras.first;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePictureScreen(
                camera: firstCamera,
                historicalPhotoUri: albums!
                    .first.features[index].properties.thumbnail
                    .toString())),
      );
    });
  }

  void _move_to_geojson(context, index) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => AlbumListPage.network(
              albums!.first.features[index].properties.name!,
              albums!.first.features[index].properties.geojson!)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
        crossAxisCount: 4,
        staggeredTileBuilder: (int index) =>
            new StaggeredTile.fit(index == 0 ? 4 : 2),
        mainAxisSpacing: 4.0,
        crossAxisSpacing: 4.0,
        itemCount: albums!.first.features.length + 1,
        // Number of items + header row
        itemBuilder: (context, index) {
          if (index == 0) {
            return headerTile(context, index);
          } else {
            return contentTile(context, index);
          }
        });
  }

  Widget headerTile(context, index) {
    var headerImage;

    if (albums!.first.image != null && albums!.first.image != "") {
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
    return new GestureDetector(
        onTap: () {
          if (albums!.first.features[index].properties.geojson != null &&
              albums!.first.features[index].properties.geojson != "") {
            _move_to_geojson(context, index);
          } else {
            _take_rephoto(context, index);
          }
        },
        child: Column(children: [
          CachedNetworkImage(
              imageUrl: albums!.first.features[index].properties.thumbnail
                  .toString()),
          Text(
            albums!.first.features[index].properties.name.toString(),
            textAlign: TextAlign.center,
          )
        ]));
  }
}
