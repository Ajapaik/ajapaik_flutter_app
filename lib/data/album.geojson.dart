import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class Album {
  String type = "";
  Geometry? geometry;
  late Properties properties;

  Album({required this.type, this.geometry, required this.properties});

  Album.fromJson(Map<String, dynamic> json) {
    type = json['type'];

    geometry = (json['geometry'] != null && json['geometry'].toString() != "[]")
        ? new Geometry.fromJson(json['geometry'])
        : null;
    properties = (json['properties'] != null)
        ? new Properties.fromJson(json['properties'])
        : new Properties.empty();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    if (this.geometry != null) {
      data['geometry'] = this.geometry!.toJson();
    }
    if (this.properties != null) {
      data['properties'] = this.properties.toJson();
    }

    return data;
  }
}

class Geometry {
  String type = "";
  List<String> coordinates = [];

  Geometry({required this.type, required this.coordinates});

  Geometry.fromJson(Map<String, dynamic> json) {
    type = (json['type'] != null) ? json['type'] : "";
    coordinates = json['coordinates'].cast<String>();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['type'] = this.type;
    data['coordinates'] = this.coordinates;
    return data;
  }
}

class Properties {
  String? id;
  String? name;
  String? description;
  String? date;
  String? author;
  String? sourceUrl;
  String? sourceLabel;
  String? favorites;
  int? rephotos;
  String? thumbnail;

  Properties(
      {required this.id,
      required this.name,
      required this.description,
      required this.date,
      required this.author,
      required this.sourceUrl,
      required this.sourceLabel,
      required this.favorites,
      required this.rephotos,
      required this.thumbnail});

  Properties.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
    description = json['description'];
    date = json['date'];
    author = json['author'];
    sourceUrl = json['source_url'];
    sourceLabel = json['source_label'];
    favorites = json['favorites'].toString();
    rephotos = json['rephotos'];
    thumbnail =
        json['thumbnail'].toString().replaceFirst("http://", "https://");
  }

  Properties.empty() {
    id = "";
    name = "";
    description = "";
    date = "";
    author = "";
    sourceUrl = "";
    sourceLabel = "";
    favorites = "";
    rephotos = 0;
    thumbnail = "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['description'] = this.description;
    data['date'] = this.date;
    data['author'] = this.author;
    data['source_url'] = this.sourceUrl;
    data['source_label'] = this.sourceLabel;
    data['favorites'] = this.favorites;
    data['rephotos'] = this.rephotos;
    // Only https is allowed
    data['thumbnail'] = this.thumbnail;
    return data;
  }
}

Future<List<Album>> fetchAlbum(http.Client client, String url) async {
  final response = await client.get(Uri.parse(url));
  print(url);
  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseAlbums, response.body);
}

List<Album> parseAlbums(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Album>((json) => Album.fromJson(json)).toList();
}
