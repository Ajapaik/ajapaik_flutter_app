import 'dart:io';
import 'package:ajapaik_flutter_app/upload.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
//import 'package:gallery_saver/files.dart';
//import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
//import 'package:url_launcher/url_launcher.dart';
import 'camera.dart';
import 'data/draft.json.dart';
import 'photomanipulation.dart';
import 'package:share_plus/share_plus.dart';

class Rephotoscreen extends StatelessWidget {

  // final List<Album>? albums;

  Rephotoscreen({Key? key,
    required String this.historicalPhotoId,
    required String this.historicalPhotoUri,
    required String this.historicalName,
    required String this.historicalDate,
    required String this.historicalAuthor,
    //this.albums
    //required String this.historicalLatitude,
    //required String this.historicalLongitude
  })
      : super(key:key);

  final String historicalPhotoId;
  final String historicalPhotoUri;
  final String historicalName;
  final String historicalDate;
  final String historicalAuthor;

  //final String historicalLatitude;
  //final String historicalLongitude;

  //var lat = double.parse('historicalLatitude');
  //var long = double.parse('historicalLongitude');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rephoto application',
      style: TextStyle(
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      )), actions: [
        PopupMenuButton<int>(
            icon: const Icon(Icons.menu, color:Colors.white),
            onSelected: (result) async {
              if (result == 0) {
              final urlImage =
                  historicalPhotoUri;
              final url = Uri.parse(urlImage);
              final response = await http.get(url);
              final bytes = response.bodyBytes;

              final temp = await getTemporaryDirectory();
              final path = '${temp.path}/image.jpg';
              File(path).writeAsBytesSync(bytes);

              await Share.shareFiles([path], text: historicalName);
              }
            },
            itemBuilder: (context) => [
                  const PopupMenuItem(value: 0, child: ListTile(leading: Icon(Icons.share), title: Text('Jaa kuva',), )),
                  const PopupMenuItem(value: 1, child: ListTile(leading: Icon(Icons.info), title: Text('Lisätietoja kuvasta',),)),
                  const PopupMenuItem(value: 2, child: ListTile(leading: Icon(Icons.settings), title: Text('Asetukset',), )),
                ])
      ]),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child:
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => maniphoto(
                          historicalPhotoUri: historicalPhotoUri,
                        )));
                  },
                  child: Image.network(historicalPhotoUri),
                ),
              ),
              //ElevatedButton(onPressed: _launchURL, child: Text('TEST123')),

            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Expanded(
                child: Text(historicalName,
                maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                )
              )
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(historicalDate),
              )
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(historicalAuthor),
              )
            ]),
          ],
        ),
        //Ongelma koordinaattien tuomisen kanssa string to double
              //FlutterMap(
              //   options: MapOptions(
              //     center: LatLng(60.99596, -24.46434),
              //     zoom: 13.0,
              //   ),
              //   layers: [
              //     TileLayerOptions(
              //       urlTemplate:
              //           "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              //       subdomains: ['a', 'b', 'c'],
              //       attributionBuilder: (_) {
              //         return Text("© OpenStreetMap contributors");
              //       },
              //     ),
              //     MarkerLayerOptions(
              //       markers: [
              //         Marker(
              //           width: 80.0,
              //           height: 80.0,
              //           point: LatLng(60.99596, -24.46434),
              //           builder: (ctx) => Container(
              //             child: FlutterLogo(),
              //           ),
              //         ),
              //       ],
              //     ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FloatingActionButton(
        elevation: 50,
        child: const Icon(Icons.camera),
        onPressed: (){
          _takeRephoto(context);
        },
      ),
    ),
      //floatingActionButtonLocation:
      //FloatingActionButtonLocation.centerFloat,
    );
  }

  // Future<void> _photomani(context, index) async {
  //   var photomani = await Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //         builder: (context) => maniphoto(
  //               historicalPhotoUri: albums!
  //                   .first.features[index].properties.thumbnail
  //                   .toString(),
  //             )),
  //   );
  // }

  void _takeRephoto(context) {
    availableCameras().then((availableCameras) async {
      CameraDescription firstCamera = availableCameras.first;
      var rephoto = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => TakePictureScreen(
                camera: firstCamera,
                historicalPhotoId:
                historicalPhotoId,
                historicalPhotoUri:
                historicalPhotoUri,
      )));
      if (rephoto.runtimeType == Draft) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DisplayUploadScreen(draft: rephoto)));
      }
    });
  }

  // Future<File> _fileFromImageUrl() async {
  //
  //   final response = await http.get(Uri.parse(historicalPhotoUri));
  //
  //   final documentDirectory = await getApplicationDocumentsDirectory();
  //
  //   final file = File(join(documentDirectory.path, 'imagetest.png'));
  //
  //   file.writeAsBytesSync(response.bodyBytes);
  //
  //   return file;
  // }

        //Possibly required for deleting temp
  // void main() {
  //   final dir = Directory(path);
  //   dir.deleteSync(recursive: true);
  // }

//   _launchURL() async {
//     const url = 'https://demo.tify.rocks/demo.html?manifest=https://ajapaik.ee/photo/199152/v2/manifest.json&tify={%22panX%22:0.5,%22panY%22:0.375,%22view%22:%22info%22,%22zoom%22:0.001}';
//     if (await canLaunch(url)) {
//       await launch(url);
//     } else {
//       throw 'Could not launch $url';
//     }
//   }
 }

