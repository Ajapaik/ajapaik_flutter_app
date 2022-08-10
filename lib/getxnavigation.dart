import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data/user.json.dart';

// TOOD: cleaner handling of logins
enum LoginProviders { loginGoogle, loginFacebook, loginWikimedia }

enum ServerType { serverAjapaik, serverAjapaikStaging, serverWikimedia }

class Controller extends GetxController {
  String _session = "";
  String _username = "";
  bool _wiki = false;

  // TODO: we need to determine somehow where user wants to login & upload..
  //ServerType? server;

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
    } else if (isExpired() == false) {
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

  String getLoginUri(ServerType type) {
    if (type == ServerType.serverAjapaik) {
      return "https://ajapaik.ee/api/v1/login/";
    }
    else if (type == ServerType.serverAjapaikStaging) {
      return "https://staging.ajapaik.ee/api/v1/login/";
    }
    else if (type == ServerType.serverWikimedia) {
      return "https://commons.wikimedia..";
    }
    // or throw "not yet implemented"
    return "";
  }
  // we need to have session for the same place we are expected to be uploading to but uri can be different..
  String getUploadUri(ServerType type) {
    if (type == ServerType.serverAjapaik) {
      return "https://ajapaik.ee/api/v1/photo/upload/";
    }
    else if (type == ServerType.serverAjapaikStaging) {
      return "https://staging.ajapaik.ee/api/v1";
    }
    else if (type == ServerType.serverWikimedia) {
      return "https://commons.wikimedia..";
    }
    // or throw "not yet implemented"
    return "";
  }

  // TODO: handle different types in caller too somehow
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

    var url = Uri.parse(getLoginUri(ServerType.serverAjapaik));
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
