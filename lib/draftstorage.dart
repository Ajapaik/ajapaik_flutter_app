import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'data/draft.json.dart';

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
  bool load() {
    /*
    var tempDir = Directory.systemTemp;
    var list = tempDir.list();
    for (int i = 0; i < list.length; i++) {
      list[i].
    }
    */
    //Directory dir = FileSystem.currentDirectory();
    String filename = "draft"; // TODO: generate name, get path
    File f = File(filename);
    if (f.existsSync()) {
      String jsonString = f.readAsBytesSync().toString();
      Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      Draft d = Draft.fromJson(jsonMap);
    }

    return false;
  }

  // for now, just keep list
  bool store(draft) {
    draftlist.add(draft);
    //String jsonString = json.encode();

    String filename = "draft"; // TODO: generate name, get path
    draft.filename = filename;
    File f = File(filename);
    if (!f.existsSync()) {
      Map<String, dynamic> jsonMap = draft.toJson();
      String jsonString = jsonEncode(jsonMap);
      f.writeAsStringSync(jsonString);
    }
    return true;
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
  bool remove(draft) {
    if (draft.filename.isEmpty) {
      // never stored
      return true;
    }
    File f = File(draft.filename);
    if (f.existsSync()) {
      f.deleteSync();
    }
    return true;
  }

}