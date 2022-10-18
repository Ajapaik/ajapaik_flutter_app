import 'package:shared_preferences/shared_preferences.dart';

// TODO: keep state, not just static calls
class Preferences {
  late SharedPreferences prefs;
  Preferences() {

  }

  // load preferences once per starting,
  // no need to reload while app is running (state should be known)
  loadPrefs() async {
    prefs = await SharedPreferences.getInstance();
  }

  bool tooltip = true;
  bool? getTooltipPrefs() {
    //final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool("tooltip");
  }

  void saveTooltipPrefs() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tooltip', tooltip);
  }

  //bool visibility = false;
  void saveNameVisibility(bool visibility) async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('visibility', visibility);
  }

  /*
  // this is stored for later, not just set:
  // what is the point of this? user can change language of the OS
  // or it could be selected from menu -> no need for persistent storage
  Future<void> storeLanguageCode(String languageCode) async {
    //final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
  }

  String languageCode = 'en';
  Future<String?> loadLanguageCode() async {
    //final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('locale');
  }
  */


  /*
  bool searchVisibility = false;
  void setSearchVisibility(bool searchVisibility) async {
      //SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('searchVisibility', searchVisibility);
  }
  */

}
