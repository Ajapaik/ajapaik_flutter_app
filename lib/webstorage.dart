import 'dart:html'; // localStorage, already through dart:io

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
