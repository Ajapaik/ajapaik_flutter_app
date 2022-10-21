import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'data/user.json.dart';

// TOOD: cleaner handling of logins
enum LoginProviders { loginGoogle, loginFacebook, loginWikimedia }

// note: may work in standalone until user decides to login -> keep none until known
enum ServerType { serverNone, serverAjapaik, serverAjapaikStaging, serverWikimedia }

class SessionController extends GetxController {
  String currentSessionId = "";
  User currentUser = User();

  // TODO: we need to determine somehow where user wants to login & upload..
  // default to a sensible value so data can be used without login (anonymously)
  ServerType server = ServerType.serverAjapaik;

  String getSessionId() {
    return currentSessionId;
  }

  // is the session active or not?
  // TODO: timeout check
  bool isExpired() {
    if (getSessionId() == "") {
      return true;
    }
    return false;
  }

  // if oauth key was stored -> destroy it
  Future<void> clearSessionKey() async {
    FlutterSecureStorage storage = const FlutterSecureStorage();
    await storage.delete(key: 'session');
  }

  // oauth key needs to be stored for flutter?
  // -> check this
  Future<void> storeSessionKey(String session) async {
    currentSessionId = session;
    FlutterSecureStorage storage = const FlutterSecureStorage();
    await storage.write(key: 'session', value: session);
  }

  // so apparently flutter does not understand oauth properly
  // without some extra steps in between?
  // -> recheck this logic
  Future<String> loadSessionKey() async {
    FlutterSecureStorage storage = const FlutterSecureStorage();
    String? s = await storage.read(key: 'session');
    if (s != null) {
      currentSessionId = s;

      var user = await fetchUser();
      if (user.isAnon()) {
        clearSessionKey(); // anon should not have bogus key, right? -> destroy
        //storeSessionKey("");
      }

      currentUser = user;
    } else if (isExpired() == false) {
      await logout();
    }
    return currentSessionId;
  }

  Future<void> logout() async {
    clearSessionKey();
    currentSessionId = "";
    currentUser.resetUser();
  }

  User getUser() {
    return currentUser;
  }

  void setWiki(bool wiki) {
    currentUser.wiki = wiki;
  }

  // TODO: determine where user wants to login or upload first
  //
  void setServer(ServerType type) {
    server = type;
  }
  ServerType getServer() {
    return server;
  }

  // ..or whatever method it is currently using..
  String getLoginOauthUri() {
    if (server == ServerType.serverAjapaik) {
      return "https://ajapaik.ee/accounts/";
    }
    // or throw "not yet implemented"
    return "";
  }

  String getLoginUri() {
    if (server == ServerType.serverAjapaik) {
      return "https://ajapaik.ee/api/v1/login/";
    }
    else if (server == ServerType.serverAjapaikStaging) {
      return "https://staging.ajapaik.ee/api/v1/login/";
    }
    else if (server == ServerType.serverWikimedia) {
      // TODO: get right url for login (also see provider handling)
      return "https://commons.wikimedia.beta.wmflabs.org";
    }
    // or throw "not yet implemented"
    return "";
  }
  // we need to have session for the same place we are expected to be uploading to but uri can be different..
  String getUploadUri() {
    if (server == ServerType.serverAjapaik) {
      return "https://ajapaik.ee/api/v1/photo/upload/";
    }
    else if (server == ServerType.serverAjapaikStaging) {
      return "https://staging.ajapaik.ee/api/v1";
    }
    else if (server == ServerType.serverWikimedia) {
      // TODO: get right url for upload
      return "https://commons.wikimedia.beta.wmflabs.org";
    }
    // or throw "not yet implemented"
    return "";
  }
  // data source for photos etc.
  // nearest/imageinfo/projects
  String getDatasourceUri() {
    if (server == ServerType.serverAjapaik) {
      return "https://ajapaik.toolforge.org/api";
    }
    // or throw "not yet implemented"
    return "";
  }

  String getFetchUserUri() {
    if (server == ServerType.serverAjapaik) {
      return "https://ajapaik.ee/api/v1/user/me";
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

    var url = Uri.parse(getLoginUri());
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
      await storeSessionKey(json["session"]);

      var user = await fetchUser();
      if (user.isValid() == true) {
        // should have something sensible now so keep user information
        currentUser = user;
      }
      update();
      return true;
    } else {
      (response.body.toString());
      throw Exception('Failed to create album.');
    }
  }

  // TODO: other server possibilities,
  // commons etc.
  Future<User> fetchUser() async {
    http.Client client = http.Client();
    String serverUri = getFetchUserUri();

    final response = await client.get(
        Uri.parse(serverUri),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Cookie': 'sessionid=' + getSessionId()
        });
    print(response.body);
    Map<String, dynamic> json = jsonDecode(response.body);
    return User.fromJson(json);
  }

}
