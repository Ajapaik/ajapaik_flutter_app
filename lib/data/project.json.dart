import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class Project {
  int? projectId;
  String? projectWikidataId;
  String? institutionWikidataId;
  String name = "Undefined";
  String? homepage;
  String? geojson;
  String? thumbnailUrl;

  Project(
      {required this.projectId,
      required this.projectWikidataId,
      required this.institutionWikidataId,
      required this.name,
      required this.homepage,
      required this.geojson,
      required this.thumbnailUrl});

  Project.fromJson(Map<String, dynamic> json) {
    projectId = (json['projectId'] != null) ? json['projectId'] : "";
    projectWikidataId = (json['projectWikidataId'] != null)
        ? json['projectWikidataId'].toString()
        : "";
    institutionWikidataId = (json['institutionWikidataId'] != null)
        ? json['institutionWikidataId']
        : "";
    name = (json['name'] != null) ? json['name'] : "";
    homepage = (json['homepage'] != null) ? json['homepage'] : "";
    geojson = (json['geojson'] != null) ? json['geojson'] : "";
    thumbnailUrl = (json['thumbnailUrl'] != null) ? json['thumbnailUrl'] : "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['projectId'] = this.projectId.toString();
    data['projectWikidataId'] = this.projectWikidataId;
    data['institutionWikidataId'] = this.institutionWikidataId;
    data['name'] = this.name;
    data['homepage'] = this.homepage;
    data['geojson'] = this.geojson;
    data['thumbnailUrl'] = this.thumbnailUrl;
    return data;
  }
}

Future<List<Project>> fetchProjects(http.Client client) async {
  final response = await client
      .get(Uri.parse('https://fiwiki-tools.toolforge.org/api/projects.php'));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}

List<Project> parsePhotos(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Project>((json) => Project.fromJson(json)).toList();
}
