import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'photomanipulation.dart';
import 'package:share_plus/share_plus.dart';

class Rephotoscreen extends StatelessWidget {

  //final List<Album>? albums;

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
      appBar: AppBar(
        title: Text('Rephoto'),
        actions:[
          PopupMenuButton<int>(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Asetukset')
              ),
              PopupMenuItem(
                child: Text('Jaa kuva')
              ),
              PopupMenuItem(
                child: Text('Lisätietoja kuvasta')
              )
            ]
          )
        ]
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(onPressed: _launchURL, child: Text('TEST123')),
              ElevatedButton(onPressed: () {}, child: Text('Rephoto')),
              Expanded(
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
              Text(historicalName),
              Text(historicalDate),
              Text(historicalAuthor),
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
            ],
          )),
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

  _launchURL() async {
    const url = 'https://demo.tify.rocks/demo.html?manifest=https://ajapaik.ee/photo/199152/v2/manifest.json&tify={%22panX%22:0.5,%22panY%22:0.375,%22view%22:%22info%22,%22zoom%22:0.001}';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}

