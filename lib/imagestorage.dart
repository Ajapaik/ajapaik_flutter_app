import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart'; // constants like kIsWeb
import 'package:flutter/material.dart'; // for Image
import 'package:cross_file/cross_file.dart'; // XFile needs some wrapper

//import 'package:image/image.dart' as img;

// reduce repeating same things

// should inherit from ImageCache ?
class ImageStorage {

  // keep track of images "in flight" if needed?
  // -> see if ImageCache can be used
  //List<Image> images;

  // when picture is taken, keep track of what and where it is
  XFile? currentImage;
  // for now, use just name
  String? currentImageName;

  ImageStorage() {

  }

  Image getImage(String filename) {
    if (kIsWeb == false && File(filename).existsSync()) {
      return Image.file(File(filename));
    }

    return Image.network(filename);
  }

  Image getImageBoxed(String filename, {double scale = 1}) {
    if (File(filename).existsSync()) {
      return Image.file(File(filename),
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
    }

    return Image.network(filename,
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
  }


  /*
  File getImageFile(String filename) {
    if (File(filename).existsSync()) {
      return File(filename);
    }
  }
  */

  XFile? getCurrent() {
    return currentImage;
  }

  void putCurrent(image) {
    currentImage = image;
  }

}