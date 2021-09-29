import 'dart:io';
import 'package:ajapaik_flutter_app/settings.dart';
import 'package:ajapaik_flutter_app/upload.dart';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'camera.dart';
import 'data/draft.json.dart';
import 'photomanipulation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:latlong2/latlong.dart';

class RephotoScreen extends StatelessWidget {

    RephotoScreen({Key? key,
    required this.historicalPhotoId,
    required this.historicalPhotoUri,
    required this.historicalName,
    required this.historicalDate,
    required this.historicalAuthor,
    required this.historicalLabel,
    required this.historicalSurl,
    required this.historicalCoordinates,
  })
      : super(key:key);

  final String historicalPhotoId;
  final String historicalPhotoUri;
  final String historicalName;
  final String historicalDate;
  final String historicalAuthor;
  final String historicalLabel;
  final String historicalSurl;

  final String historicalCoordinates;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset : false,
      appBar: AppBar(
          title: const Text('Rephoto application',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              )),

          actions: [
            PopupMenuButton<int>(
                icon: const Icon(Icons.menu, color: Colors.white),
                onSelected: (result) async {
                  if (result == 0) {
                    final urlImage = historicalPhotoUri;
                    final url = Uri.parse(urlImage);
                    final response = await http.get(url);
                    final bytes = response.bodyBytes;

                    final temp = await getTemporaryDirectory();
                    final path = '${temp.path}/image.jpg';
                    File(path).writeAsBytesSync(bytes);

                    await Share.shareFiles([path], text: historicalName);
                    void _main() {
                      final dir = Directory(path);
                      dir.deleteSync(recursive: true);
                    }
                    _main();
                  }
                  if (result == 1) {
                    _launchInfo();
                  }
                  if (result == 2) {
                    _launchTIFY();
                  }
                  if (result == 3) {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (context) => SettingsScreen()));
                  }
                },
                itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 0,
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text(
                              'Jaa kuva',
                            ),
                          )),
                      const PopupMenuItem(
                          value: 1,
                          child: ListTile(
                            leading: Icon(Icons.info),
                            title: Text(
                              'Lisätietoja kuvasta',
                            ),
                          )),
                      const PopupMenuItem(
                        value: 2,
                        child: ListTile(
                          leading: Icon(Icons.enhance_photo_translate),
                          title: Text(
                            'TIFY-demo',
                          ),
                        ),
                      ),
                      const PopupMenuItem(
                          value: 3,
                          child: ListTile(
                            leading: Icon(Icons.settings),
                            title: Text(
                              'Asetukset',
                            ),
                          )),
                    ])
          ]),
        body: Column(children: [
          Flexible(child: getImageComparison(context)),
        ]),

      floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 25.0, right: 25.0),
          child: FloatingActionButton(
            child: const Icon(Icons.camera),
            onPressed: () {
              _takeRephoto(context);
            },
          )),
    );
  }

  void _takeRephoto(context) {
    availableCameras().then((availableCameras) async {
      CameraDescription firstCamera = availableCameras.first;
      var rephoto = await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => TakePictureScreen(
                    camera: firstCamera,
                    historicalPhotoId: historicalPhotoId,
                    historicalPhotoUri: historicalPhotoUri,
                  )));
      if (rephoto.runtimeType == Draft) {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => DisplayUploadScreen(draft: rephoto)));
      }
    });
  }

  Widget getImageComparison(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return verticalPreview(context);
      } else {
        return horizontalPreview(context);
      }
    });
  }

  Widget verticalPreview(BuildContext context) {

    double latitude = double.parse(historicalCoordinates.split(",")[0]);
    double longitude = double.parse(historicalCoordinates.split(",")[1]);

    return Column(children: [
      Flexible(
          child: GestureDetector(
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => maniphoto(
                        historicalPhotoUri: historicalPhotoUri,
                      )));
        },
        child: Image.network(historicalPhotoUri),
      )),
      Expanded(
        child: Padding(
            padding: const EdgeInsets.all(5),
            child: Column(
                // mainAxisSize: MainAxisSize.min,
                // crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(historicalAuthor + ', ' + historicalDate, maxLines: 2),
                  const SizedBox(height: 10),
                  Text(
                    historicalName,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                          text: historicalLabel,
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              if (await canLaunch(historicalSurl)) {
                                await launch(historicalSurl);
                              } else {
                                throw 'Could not launch $historicalSurl';
                              }
                            }),
                    ),
                  ),
                  Flexible(
                    child: FlutterMap(
                        options: MapOptions(
                          center: LatLng(latitude, longitude),
                          zoom: 2.0,
                        ),
                        layers: [
                          TileLayerOptions(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: ['a', 'b', 'c'],
                            attributionBuilder: (_) {
                              return Text("© OpenStreetMap contributors");
                            },
                          ),
                          MarkerLayerOptions(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: LatLng(latitude, longitude),
                                builder: (ctx) => Container(
                                  child: FlutterLogo(),
                                ),
                              ),
                            ],
                          ),
                        ]),
                  )
                ])),
      ),
    ]);
  }

  Widget horizontalPreview(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => maniphoto(
                            historicalPhotoUri: historicalPhotoUri,
                          )));
            },
            child: Image.network(historicalPhotoUri),
          ),
        ),
        Expanded(
          child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      historicalAuthor + ', ' + historicalDate,
                      maxLines: 9,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      historicalName,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      historicalLabel,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      historicalSurl,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    )
                  ])),
        )
      ],
    );
  }

  _launchTIFY() async {
    const url = 'https://demo.tify.rocks/demo.html?manifest=https://ajapaik.ee/photo/199152/v2/manifest.json&tify={%22panX%22:0.5,%22panY%22:0.375,%22view%22:%22info%22,%22zoom%22:0.001}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

    _launchInfo() async {
      if (await canLaunch(historicalSurl)) {
        await launch(historicalSurl);
      } else {
        throw 'Could not launch $historicalSurl';
      }
    }

}


