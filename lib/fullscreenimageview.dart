import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'localization.dart';
import 'imagestorage.dart';

class FullScreenImageView extends StatelessWidget {
  final imageStorage = Get.put(ImageStorage());

  FullScreenImageView({
    Key? key,
    required this.historicalPhotoUri,
  }) : super(key: key);

  final String historicalPhotoUri;

  @override
  Widget build(BuildContext context) {
    Expanded e = Expanded(
                    child: InteractiveViewer(
                        child: imageStorage.getImage(historicalPhotoUri)));

    Scaffold s = Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.getText(context, 'photoManipulation-appbarTitle'),
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


