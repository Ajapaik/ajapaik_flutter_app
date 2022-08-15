import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import '../sessioncontroller.dart';

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
  final sessionController = Get.put(SessionController());

  return sessionController.fetchUser();
}
