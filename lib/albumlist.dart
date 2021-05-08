import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_camera_test3/data/album.geojson.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'camera.dart';


class AlbumListPage extends StatelessWidget {
  String pageTitle = "Not set";
  String dataSourceUrl = "";

  AlbumListPage({Key? key}) : super(key: key);
  AlbumListPage.network(this.pageTitle, this.dataSourceUrl);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pageTitle),
      ),
      body: FutureBuilder<List<Album>>(
        future: fetchAlbum(http.Client(), dataSourceUrl),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? AlbumList(albums: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
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
        MaterialPageRoute(builder: (context) =>
            TakePictureScreen(
                camera: firstCamera, historicalPhotoUri: albums![index].properties.thumbnail.toString())),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.countBuilder(
      crossAxisCount: 4,
      itemCount: albums!.length,
      staggeredTileBuilder: (int index) => new StaggeredTile.fit(2),
      mainAxisSpacing: 4.0,
      crossAxisSpacing: 4.0,
      itemBuilder: (context, index) {
        return new GestureDetector(
            onTap: () {_take_rephoto(context, index); },
            child: Column(children: [
              CachedNetworkImage(
                  imageUrl: albums![index].properties.thumbnail.toString()),
              Text(
                albums![index].properties.name.toString(),
                textAlign: TextAlign.center,
              )
            ]));
      },
    );
  }
}
