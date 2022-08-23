import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class Album {
  List<Feature> features;
  String name = "";
  String description = "";
  String image = "";

  Album(
      {required this.name,
      required this.description,
      required this.image,
      required this.features});

  factory Album.fromJson(Map<String, dynamic> json) {
    String name = (json['name'] != null) ? json['name'].toString() : "";
    String description =
        (json['description'] != null) ? json['description'].toString() : "";
    String image = (json['image'] != null) ? json['image'].toString() : "";

    List<Feature> featureList = (json['features'] != null)
        ? json['features'].map<Feature>((i) => Feature.fromJson(i)).toList()
        : Feature.empty();
    return Album(
        name: name,
        description: description,
        image: image,
        features: featureList);
  }
}

class Feature {
  String type = "";
  Geometry geometry;
  Properties properties;

  Feature(
      {required this.type, required this.geometry, required this.properties});

  factory Feature.empty() {
    return Feature(
        type: "", geometry: Geometry.empty(), properties: Properties.empty());
  }

  factory Feature.fromJson2(Map<String, dynamic> json) {
    String type2 = json['type'];
    Properties properties2 = (json['properties'] != null)
        ? Properties.fromJson(json['properties'])
        : Properties.empty();

    (json["geometry"].toString());
    Geometry geometry2 =
        ((json['geometry'] != null) && (json['geometry'].toString() != "[]"))
            ? Geometry.fromJson(json['geometry'])
            : Geometry.empty();

    return Feature(
        type: type2, geometry: geometry2, properties: properties2);
  }

  factory Feature.fromJson(Map<String, dynamic> json) {
    String type2 = json['type'];

    Geometry geometry2 =
        ((json['geometry'] != null) && (json['geometry'].toString() != "[]"))
            ? Geometry.fromJson(json['geometry'])
            : Geometry.empty();

    Properties properties2 = (json['properties'] != null)
        ? Properties.fromJson(json['properties'])
        : Properties.empty();

    return Feature(type: type2, geometry: geometry2, properties: properties2);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['geometry'] = geometry.toJson();
    data['properties'] = properties.toJson();
    return data;
  }
}

class Geometry {
  String type;
  List<double> coordinates;

  Geometry({required this.type, required this.coordinates});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    String type = json['type'];

    List<double> coordinates = [
      json["coordinates"][1].toDouble() as double,
      json["coordinates"][0].toDouble() as double
    ];

    return Geometry(type: type, coordinates: coordinates);
  }

  factory Geometry.empty() {
    return Geometry(type: "", coordinates: []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['type'] = type;
    data['coordinates'] = coordinates;
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
  String? geojson;

  Properties({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.author,
    required this.sourceUrl,
    required this.sourceLabel,
    required this.favorites,
    required this.rephotos,
    required this.thumbnail,
    required this.geojson,
  });

  Properties.fromJson(Map<String, dynamic> json) {
    id = json['id'].toString();
    name = json['name'];
    description = json['description'];
    date = json['date'];
    author = json['author'];
    sourceUrl = json['source_url'];
    sourceLabel = json['source_label'];
    favorites = json['favorites'].toString();
    rephotos = (json['rephotos']=="") ? 0 : json['rephotos'];
    geojson = json['geojson'];
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
    geojson = "";
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['name'] = name;
    data['description'] = description;
    data['date'] = date;
    data['author'] = author;
    data['source_url'] = sourceUrl;
    data['source_label'] = sourceLabel;
    data['favorites'] = favorites;
    data['rephotos'] = rephotos;
    // Only https is allowed
    data['thumbnail'] = thumbnail;
    data['geojson'] = geojson;
    return data;
  }
}

String addLocationToUrl(String url, LatLng position) {
  if (url.contains("__LAT__")) {
    url = url.replaceFirst("__LAT__", position.latitude.toString());
  } else {
    url = url.replaceAll(RegExp(r'([?]latitude=)[0-9.]+'),'?');
    url = url.replaceAll(RegExp(r'([&]latitude=)[0-9.]+'),'');
    url += "&latitude=" + position.latitude.toString();
  }
  if (url.contains("__LON__")) {
    url = url.replaceFirst("__LON__", position.longitude.toString());
  } else {
    url = url.replaceAll(RegExp(r'([?]longitude=)[0-9.]+'),'?');
    url = url.replaceAll(RegExp(r'([&]longitude=)[0-9.]+'),'');
    url += "&longitude=" + position.longitude.toString();
  }
  return url;
}

Future<List<Album>> fetchAlbum(http.Client client, String url) async {
  print(url);
  final response = await client.get(Uri.parse(url));
  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parseAlbums, response.body);
}

List<Album> parseAlbums(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Album>((json) => Album.fromJson(json)).toList();
}
