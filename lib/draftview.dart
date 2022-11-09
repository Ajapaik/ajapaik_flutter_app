import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'localization.dart';
import 'data/draft.json.dart';
import 'draftstorage.dart';
import 'imagestorage.dart';


// View of drafts (unuploaded images):
// if upload wasn't completed (outside of network area)
// user may have multiple unuploaded images to be uploaded.
//
// Let user check them before uploading,
// user also might wan't to discard (delete) some photos (not good enough/many alternatives).
//
class DraftView extends StatelessWidget {
  final draftStorage = Get.find<DraftStorage>();
  final imageStorage = Get.find<ImageStorage>();

  DraftView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Draft> drafts = draftStorage.draftlist;
    /*
    foreach (Draft d : drafts) {
      Image i = imageStorage.getImageBoxed(d.imagePath);
    }

     */

    /*
    Expanded e = Expanded(
        child: InteractiveViewer(
            child: image
        );

     */

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
                //children: [e]
            )));
    return s;
  }
}


