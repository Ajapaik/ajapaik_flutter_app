import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class Controller extends GetxController {
  String _session="";

  var count = 0;
  void increment() {
    count++;
    update();
  }

  void setSession(String session) {
    _session=session;
  }
  String getSession() {
    return _session;
  }
  void logout() {
    _session="";
  }

  void doApiLogin(String type, String username, String password) async {
    if (type=='facebook') {
      type='fb';
    }
    else if (type=='google') {
      type='google2';
    }

    var body=jsonEncode(<String, String>{
      'type': type,
      'username': username,
      'password': password,
    });
    print(body);

    var url = Uri.parse("https://staging.ajapaik.ee/api/v1/login/");
    final http.Response response = await http.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );

    if (response.statusCode == 200) {
      print(response.body.toString());
      Map<String, dynamic> json = jsonDecode(response.body);
      setSession(json["session"]);
    } else {
      print(response.body.toString());
      throw Exception('Failed to create album.');
    }
  }



}