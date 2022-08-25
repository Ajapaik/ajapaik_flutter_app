import 'dart:convert';

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
    final Map<String, dynamic> data = <String, dynamic>{};
    data['projectId'] = projectId.toString();
    data['projectWikidataId'] = projectWikidataId;
    data['institutionWikidataId'] = institutionWikidataId;
    data['name'] = name;
    data['homepage'] = homepage;
    data['geojson'] = geojson;
    data['thumbnailUrl'] = thumbnailUrl;
    return data;
  }
}

