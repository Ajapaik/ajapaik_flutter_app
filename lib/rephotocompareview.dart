import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'data/album.geojson.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'imagestorage.dart';

class RephotoCompareView extends StatelessWidget {
  final imageStorage = Get.find<ImageStorage>();
  late List<Album> album;
  String historicalImageUrl = "";

  RephotoCompareView({Key? key, required List<Album> album}) : super(key: key) {
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
              child: getCarouselSlider(context)))
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
              child: getCarouselSlider(context)))
    ]);
  }

  Widget getImageWithText(String filename, BuildContext context) {
    var feature = album.first.features[0];
    List<String> labels = [];
    labels.add("");
    if (feature.properties.hasAuthor()) {
      labels.add(feature.properties.author!);
    }
    if (feature.properties.hasDate()) {
      labels.add(feature.properties.date!);
    }

    // so.. image can be local or from network?
    Image image = imageStorage.getImageBoxed(filename);
    return Stack(children:[image,
      Align(alignment: Alignment.bottomCenter,
          child:Text(labels.join(" "),
              style: TextStyle(fontSize: 16,height:7, color:Colors.white, decoration: TextDecoration.none, fontWeight: FontWeight.normal)))
    ]);
  }

  getCarouselSlider(context) {
    if (album.first.features.length == 1) {
      return Text("");
    }
    List<Widget> items = [];
    for (var i = 1; i < album.first.features.length; i++) {
      var feature = album.first.features[i];
      List<String> labels = [];
      if (feature.properties.hasAuthor()) {
        labels.add(feature.properties.author!);
      }
      if (feature.properties.hasDate()) {
        labels.add(feature.properties.date!);
      }

      // only images from network in this case?
      Image image = imageStorage.getImageBoxed(feature.properties.thumbnail!);
      Stack imagestack = Stack(children: [
      image,
      Align(alignment: Alignment.bottomCenter,
        child:Text(labels.join(" "),
            style: TextStyle(fontSize: 16,height:7, color:Colors.white, decoration: TextDecoration.none, fontWeight: FontWeight.normal)))
      ]);
      items.add(imagestack);
    }
    return CarouselSlider(
        items: items,
        options: CarouselOptions(
            initialPage: 0,
            height: MediaQuery.of(context).size.height,
            viewportFraction: 1,
            enableInfiniteScroll: false));
  }
}
