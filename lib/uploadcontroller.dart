import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sessioncontroller.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'data/draft.json.dart';

class UploadController  {
  final sessionController = Get.put(SessionController());
  //Draft draft;

  UploadController({Key? key});

  generateAjapaikUploadRequest(String sessionid, String uploadUri, Draft draft) {

    var postUri = Uri.parse(uploadUri);
    var request = http.MultipartRequest("POST", postUri);
    request.headers['Cookie'] = 'sessionid=' + sessionid;
    //    request.headers['Content-Type']="application/json; charset=UTF-8";
    request.fields['id'] =
        draft.historicalImageId; // Historical photo id in Ajapaik or Finna_url
    request.fields['latitude'] = draft.lat.toString(); // optional
    request.fields['longitude'] = draft.lon.toString(); // optional
    //    request.fields['accuracy'] = 'blah'; //optional
    //    request.fields['age'] = 'blah'; // optional, coordinates_age
    request.fields['date'] =
        draft.date; //'01-01-1999'; // optional, coordinate_accuracy
    request.fields['scale'] = draft.scale.toString();
    request.fields['yaw'] = '0'; // device_yaw
    request.fields['pitch'] = '0'; // device_pitch
    request.fields['roll'] = '0'; // device_roll
    request.fields['flip'] = '0';
    /* (draft.historicalPhotoFlipped == true)
          ? '1'
          : '0'; // is rephoto flipped, optional*/
    return request;
  }

  // TODO: must have proper login to commons so there is sensible session..
  generateCommonsUploadRequest(String sessionid, String uploadUri, Draft draft) {

    //
    var postUri = Uri.parse(uploadUri);
    var request = http.MultipartRequest("POST", postUri);
    request.headers['Cookie'] = 'sessionid=' + sessionid;
    /*
    // does not apply to commons?
    request.fields['id'] =
        draft.historicalImageId; // Historical photo id in Ajapaik or Finna_url

     */
    // TODO: does filename include path or just the name?
    File f = File(draft.imagePath);
    request.fields['filename'] = draft.imagePath;
    request.fields['filesize'] = f.length().toString();

    //comment, see also text
    //text
    //tags
    //watchlist
    //watchlistexpiry
    //ignorewarnings
    //filekey: previously stashed file
    //stash: set for temporary storage
    //file -> actual file data
    //offset
    //chunk
    //async
    //checkstatus
    //token

    // TODO: generate other metadata or description from other available information:
    // check how location and date could be added with the file

    return request;
  }

  generateUploadRequest(SessionController controller, Draft draft) {
    var request;
    if (controller.getServer() == ServerType.serverAjapaik) {
      request = generateAjapaikUploadRequest(sessionController.getSessionId(),
          sessionController.getUploadUri(),
          draft);
    }/*
    else if (controller.getServer() == ServerType.serverAjapaikStaging) {

    }*/
    else if (controller.getServer() == ServerType.serverWikimedia) {
      request = generateCommonsUploadRequest(sessionController.getSessionId(),
          sessionController.getUploadUri(),
          draft);
    }
    if (request == null) {
      return null;
    }
    var multipart = http.MultipartFile.fromPath(
        'original', File(draft.imagePath).path);
    request.files.add(multipart);
    return request;
  }

  // TODO: move actual upload here too, split it from the UI things..

}
