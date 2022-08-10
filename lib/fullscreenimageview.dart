import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'localization.dart';

class FullScreenImageView extends StatelessWidget {
  const FullScreenImageView({
    Key? key,
    required this.historicalPhotoUri,
  }) : super(key: key);

  final String historicalPhotoUri;

  Image getImage(String filename) {
    Image image;
    if (kIsWeb == false && File(filename).existsSync()) {
      image = Image.file(File(filename));
    } else {
      image = Image.network(filename);
    }
    return image;
  }

  @override
  Widget build(BuildContext context) {
    Expanded e = Expanded(
                      child: InteractiveViewer(
                          child: getImage(historicalPhotoUri)));

    Scaffold s = Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.translate(
                'photoManipulation-appbarTitle'),
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto',
                ))),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [e]
            )));
    return s;
  }
}


