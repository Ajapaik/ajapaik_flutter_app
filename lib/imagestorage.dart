import 'dart:io';
import 'dart:async';

import 'package:flutter/foundation.dart'; // constants like kIsWeb
import 'package:flutter/material.dart'; // for Image
import 'package:cross_file/cross_file.dart'; // XFile needs some wrapper

//import 'package:image/image.dart' as img;

//
import 'package:cached_network_image/cached_network_image.dart';


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

  // if given name has uri -> not local
  bool isNetworkFile(String name) {
    if (name.contains("://")) {
      return true;
    }
    return false;
  }

  // get domain from name: if cross-domain expect problems,
  // compare to current session
  String getDomain(String name) {
    int start = name.indexOf("://");
    if (start == -1) {
      return "";
    }
    start += 3; // skip
    int end = name.indexOf('/', start);
    if (end == -1) {
      end = name.length;
    }
    return name.substring(start, end);
  }

  Image getImage(String filename) {
    if (kIsWeb == false && File(filename).existsSync()) {
      // not supported on flutter web-version
      return Image.file(File(filename));
    }
    return Image.network(filename);
  }

  Widget getImageBoxed(String filename, {double scale = 1}) {
    if (isNetworkFile(filename) == false && kIsWeb == false) {
      File file = File(filename);
      if (file.existsSync()) {
        // not supported on flutter web-version
        return Image.file(file,
            fit: BoxFit.contain, height: 8000 * scale, width: 8000);
      }
    }
    if (getDomain(filename) == "ajapaik.ee") {
      return CachedNetworkImage(imageUrl: filename);
    }
    return Image.network(filename,
          fit: BoxFit.contain, height: 8000 * scale, width: 8000);
  }

  // TODO: check if caching is allowed, if there are cross-domain issues
  // and select cached/non-cached if it is not allowed
  Widget getCachedNetworkImage(String url) {
    if (isNetworkFile(url) == false) {
      // should not be here..
      // -> load local file instead
      return getImage(url);
    }
    // if we can use cached image or not:
    // this domain should be found according to session, this is a hack!
    // ! TODO: should check which domain we currently are using instead of hard-coding !
    // -> ask session controller which domain is used
    if (getDomain(url) == "ajapaik.ee") {
      return CachedNetworkImage(imageUrl: url);
    }
    // another domain -> can't use cache
    return Image.network(url);
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