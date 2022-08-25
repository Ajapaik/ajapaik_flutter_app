// this should be called something like "albumcontroller" or "projectcontroller"
// but for now we want to consolidate http usage (permissions, connectivity)

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_flutter_app/data/album.geojson.dart';
import 'package:ajapaik_flutter_app/data/project.json.dart';

// TODO: permissions and connectivity checking

fetchQuery(String url) async {
  //print(url);
  return await http.get(Uri.parse(url));
}

Future<List<Album>> fetchAlbum(String url) async {
  print(url);
  final response = await http.get(Uri.parse(url));
  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseAlbums, response.body);
}

List<Album> parseAlbums(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Album>((json) => Album.fromJson(json)).toList();
}

Future<List<Project>> fetchProjects(String uri) async {
  final response = await http.get(Uri.parse(uri));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}

List<Project> parsePhotos(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Project>((json) => Project.fromJson(json)).toList();
}
