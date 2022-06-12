import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'data/album.geojson.dart';
import 'getxnavigation.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';

class RephotoCompare extends StatelessWidget {
  final controller = Get.put(Controller());
  late List<Album> album;
  String historicalImageUrl = "";

  RephotoCompare({Key? key, required List<Album> album}) : super(key: key) {
    this.album = album;
    this.historicalImageUrl = album.first.features[0].properties.thumbnail!;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build

    return getImageComparison(context);

//    throw UnimplementedError();
  }

  Widget getImageComparison(BuildContext context) {
    return OrientationBuilder(builder: (context, orientation) {
      if (orientation == Orientation.portrait) {
        return getVerticalImageComparison(context);
      } else {
        return getHorizontalImageComparison(context);
      }
    });
  }

  Widget getHorizontalImageComparison(BuildContext context) {
    return Row(children: [
      Expanded(child: getImageWithText(historicalImageUrl, context)),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
                //color: Colors.pink[600]!,
                width: 0,
              )),
              child: _getCarouselSlider(context)))
    ]);
  }

  Widget getVerticalImageComparison(BuildContext context) {
    return Column(children: [
      Expanded(child: getImageWithText(historicalImageUrl, context)),
      Expanded(
          child: Container(
              decoration: BoxDecoration(
                  border: Border.all(
//                color: Colors.pink[600]!,
                width: 0,
              )),
              child: _getCarouselSlider(context)))
    ]);
  }

  Image getImage(String filename, BuildContext context, {double scale = 1}) {
    if (File(filename).existsSync()) {
      return Image.file(File(filename),
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    } else {
      return Image.network(filename,
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    }
  }
  Widget getImageWithText(String filename, BuildContext context) {
    var feature = album.first.features[0];
    List<String> labels = [];
    labels.add("");
    if (feature.properties.author != null &&
        feature.properties.author != "") {
      labels.add(feature.properties.author!);
    }
    if (feature.properties.date != null && feature.properties.date != "") {
      labels.add(feature.properties.date!);
    }
    return Stack(children:[getImage(filename, context),
      Align(alignment: Alignment.bottomCenter, child:Text(labels.join(" "),style: TextStyle(fontSize: 20,height:7, color:Colors.white, decoration: TextDecoration.none, fontWeight: FontWeight.normal)))
    ]);
  }
  _getCarouselSlider(context) {
    print("getCarouselSlider");
    print(album.first.features.length);
    if (album.first.features.length == 1) {
      return Text("");
    }
    List<Widget> items = [];
    for (var i = 1; i < album.first.features.length; i++) {
      print(i);
      var feature = album.first.features[i];
      List<String> labels = [];
      if (feature.properties.author != null &&
          feature.properties.author != "") {
        labels.add(feature.properties.author!);
      }
      if (feature.properties.date != null && feature.properties.date != "") {
        labels.add(feature.properties.date!);
      }
      var image = Stack(children: [
      Image.network(feature.properties.thumbnail!,
            fit: BoxFit.contain, height: 8000, width: 8000),
    Align(alignment: Alignment.bottomCenter, child:Text(labels.join(" "),style: TextStyle(fontSize: 20,height:7, color:Colors.white, decoration: TextDecoration.none, fontWeight: FontWeight.normal)))
      ]);
      items.add(image);
    }
    print(MediaQuery.of(context).size.height);
    return CarouselSlider(
        items: items,
        options: CarouselOptions(
            initialPage: 0,
            height: MediaQuery.of(context).size.height,
            viewportFraction: 1,
            enableInfiniteScroll: false));
  }
}
