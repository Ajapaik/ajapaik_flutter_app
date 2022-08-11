import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../getxnavigation.dart';

class User {
  String name = "anonymous";
  String state = "";
  bool wiki = false;

  User({
    required this.name,
    required this.state,
    required this.wiki,
  });

  User.fromJson(Map<String, dynamic> json) {
    name = (json['name'] != null) ? json['name'] : "anonymous";
    state = (json['state'] != null) ? json['state'].toString() : "";
    wiki = (json['wiki'] != null) ? true : false;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name.toString();
    data['state'] = state.toString();
    data['wiki'] = wiki.toString();
    return data;
  }
}

Future<User> fetchUser() async {
  http.Client client = http.Client();
  final controller = Get.put(SessionController());

  final response = await client.get(
      Uri.parse('https://ajapaik.ee/api/v1/user/me'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Cookie': 'sessionid=' + controller.getSession()
      });
  ("Session:" + controller.getSession());
  // Use the compute function to run parsePhotos in a separate isolate.
  print(response.body);
  Map<String, dynamic> json = jsonDecode(response.body);
  return User.fromJson(json);
}
