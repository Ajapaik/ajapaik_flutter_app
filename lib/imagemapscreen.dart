import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'data/album.geojson.dart';

class ImageMapScreen extends StatefulWidget {

  final double imageLatitude;
  final double imageLongitude;

  const ImageMapScreen({Key? key,
      required this.imageLatitude,
      required this.imageLongitude,
  })
      :super(key: key);



  @override
  ImageMapState createState() => ImageMapState();
}

class ImageMapState extends State<ImageMapScreen> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }

}