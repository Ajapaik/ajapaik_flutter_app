import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'data/draft.json.dart';
//import 'webstorage.dart'; // can't build non-web versions due to dart:html

// this might be useful but since app is using newer path_provider this can't be used
//
// import 'package:localstorage/localstorage.dart';

// TOOD: dart:io doesn't work web-browser apps so look for alternative
// in the meanwhile, make something for testing

// keep track of what has been uploaded or not
class DraftStorage {
  List<Draft> draftlist = [];

  DraftStorage() {

  }

  // TODO: load un-uploaded on start (if any)
  Future<bool> load() async {
    if (kIsWeb == true) {
      // no support in the web-version for paths: just ignored
      /*
      String? jsonString = WebStorage.load('draft');
      if (jsonString != null) {
        Map<String, dynamic> jsonMap = jsonDecode(jsonString);
        Draft d = Draft.fromJson(jsonMap);
        draftlist.add(d);
      }
      */
      return true;
    }

    final Directory tempPath = await getTemporaryDirectory();

    String filename = tempPath.path;
    filename += "/draft.json"; // TODO: generate name, get path
    File f = File(filename);
    if (f.existsSync()) {
      String jsonString = f.readAsStringSync().toString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      Draft d = Draft.fromJson(jsonMap);
      draftlist.add(d);
    }

    return false;
  }

  // for now, just keep list
  Future<bool> store(Draft draft) async {
    draftlist.add(draft);
    Map<String, dynamic> jsonMap = draft.toJson();
    String jsonString = jsonEncode(jsonMap);

    if (kIsWeb == true) {
      // no support in the web-version for paths: just ignored
      //WebStorage.save('draft', jsonString);
      return true;
    }

    final Directory tempPath = await getTemporaryDirectory();
    String filename = tempPath.path;
    filename += "/draft.json"; // TODO: generate name, get path
    draft.filename = filename;
    File f = File(filename);
    if (!f.existsSync()) {
      f.writeAsStringSync(jsonString);
    }
    return true;
  }

  Draft getLast() {
    return draftlist.last;
  }

  /*
  bool isExisting(String name) {
    var tempDir = Directory.systemTemp;
    var list = tempDir.list(name);
    if (list != null) {
      return true;
    }
    return false;
  }
  */

  // remove from tracking
  void remove(draft) {
    draftlist.remove(draft);
    if (kIsWeb == true) {
      // no support in the web-version for paths: just ignored
      //WebStorage.clear('draft');
      return;
    }

    if (draft.filename.isEmpty) {
      // never stored
      return;
    }
    File f = File(draft.filename);
    if (f.existsSync()) {
      f.deleteSync();
    }
    return;
  }

}