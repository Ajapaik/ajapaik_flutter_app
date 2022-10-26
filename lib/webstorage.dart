import 'dart:html'; // window for localStorage, File conflicts with the one in dart:io

// note that apparently stored things are lost if Flutter web version starts in another port:
// so it is hit or miss if stored things are found or not..
class WebStorage {
  //final Storage weblocalStorage = window.localStorage;

  static void save(String key, String value) {
    window.localStorage[key] = value;
  }

  static String? load(String key) {
    return window.localStorage[key];
  }

  static void clear(String key)  {
    window.localStorage.remove(key);
  }
}
