import 'dart:async';
import 'dart:io';
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
    return false;
  }

  // for now, just keep list
  bool store(draft) {
    draftlist.add(draft);
    File f = File("draft"); // TODO: generate name
    if (!f.existsSync()) {
      f.writeAsStringSync(draft.toString()); // should probably use tojson here
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
    /* TODO: delete draft from local storage after uploading
    var tempDir = Directory.systemTemp;
    var list = tempDir.list(name);
    Directory.delete()
     */
    File f = File("draft"); // TODO: get generated name
    if (f.existsSync()) {
      f.deleteSync();
    }
    return true;
  }

}