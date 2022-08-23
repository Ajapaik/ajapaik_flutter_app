import 'dart:io';
import 'data/draft.json.dart';

// keep track of what has been uploaded or not
class DraftStorage {
  List<Draft> draftlist = [];

  DraftStorage() {

  }

  // TODO: load un-uploaded on start (if any)
  bool load() {
    return false;
  }

  // for now, just keep list
  bool store(draft) {
    draftlist.add(draft);
    return true;
  }

}