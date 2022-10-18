import 'dart:io';
import 'dart:async';
import 'package:image/image.dart';

// reduce repeating same things

// should inherit from ImageCache ?
class ImageStorage {
  ImageStorage() {

  }

  /*
  Image getImage(String filename) {
    if (kIsWeb == false && File(filename).existsSync()) {
      return Image.file(File(filename));
    } else {
      return Image.network(filename);
    }
  }
  */

}