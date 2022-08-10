import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data/user.json.dart';

class Controller extends GetxController {
  String _session = "";
  String _username = "";
  bool _wiki = false;

  var count = 0;

  void increment() {
    count++;
    update();
  }

  Future<void> setSession(String session) async {
    _session = session;
    FlutterSecureStorage storage = const FlutterSecureStorage();
    await storage.write(key: 'session', value: session);
  }

  String getSession() {
    return _session;
  }

  // is the session active or not?
  // TODO: timeout check
  bool isExpired() {
    if (getSession() == "") {
      return true;
    }
    return false;
  }

  Future<String> loadSession() async {
    FlutterSecureStorage storage = const FlutterSecureStorage();
    String? s = await storage.read(key: 'session');
    if (s != null) {
      _session = s;
      var user=await fetchUser();
      print("LoadSession");
      print(user.name);
      if (user.name=="anonymous") {
        _session="";
        setSession(_session);
      }
    } else if (_session != "") {
      await logout();
    }
    ("session: " + _session);
    return _session;
  }

  Future<void> logout() async {
    FlutterSecureStorage storage = const FlutterSecureStorage();
    await storage.delete(key: 'session');
    _session = "";
    _username = "anonymous";
    _wiki = false;
  }

  void setUsername(String username) {
    _username = username;
  }

  String getUsername() {
    return _username;
  }

  void setWiki(bool wiki) {
    _wiki = wiki;
  }

  bool getWiki() {
    return _wiki;
  }

  // note: there is another doLogin() in DisplayLoginScreen,
  // sort these out in a single sensible way so there aren't multiple locations of handling same thing
  Future<bool> doApiLogin(String type, String username, String password) async {
    if (type == 'facebook') {
      type = 'fb';
    } else if (type == 'google') {
      type = 'google2';
    }

    var body = jsonEncode(<String, String>{
      'type': type,
      'username': username,
      'password': password,
    });
    (body);

    var url = Uri.parse("https://ajapaik.ee/api/v1/login/");
    final http.Response response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      (response.body.toString());
      Map<String, dynamic> json = jsonDecode(response.body);
      await setSession(json["session"]);
      await fetchUser();
      update();
      return true;
    } else {
      (response.body.toString());
      throw Exception('Failed to create album.');
    }
  }

}
