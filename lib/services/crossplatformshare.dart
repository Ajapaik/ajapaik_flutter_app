import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../httpcontroller.dart';
import 'package:cross_file/cross_file.dart';

class CrossplatformShare {
  static void shareFiles(List<String> fileNames, String text) async {
    // If web platform then share only textlink
    if (kIsWeb) {
      for (var fileName in fileNames) {
        text = text + "\n" + fileName;
        await Share.share(text);
      }
    }
    else {
      List<XFile> files=[];
      for (var fileName in fileNames) {

        if ( File(fileName).existsSync() ) {
          // Local file

          XFile file = XFile(fileName);
          files.add(file);
        } else {
          // Network file

          final response = await fetchQuery(fileName);
          // TODO: this is a problem in web-version, also needs some special
          //  permissions on some platforms?
          // -> see comment above about using the picture that is already being shown
          // instead of all this
          //
          // get rid of this and remove path_provider after that
          final temp = await getTemporaryDirectory();
          final path = '${temp.path}/image.jpg';
          File(path).writeAsBytesSync(response.bodyBytes);

          //        XFile file = XFile.fromData(response.bodyBytes, name:'image.jpg', mimeType:'image/jpeg');
          XFile file = XFile(path);
          files.add(file);
        }
      }
      await Share.shareXFiles(files,text:text);
    }
  }

  static void shareFile(String fileName, String text) async {
    List<String> fileNames = [fileName];
    CrossplatformShare.shareFiles([fileName], text);
  }
}

