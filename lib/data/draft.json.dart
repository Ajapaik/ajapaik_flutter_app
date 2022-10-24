import 'dart:convert';

class Draft {
  String? id; // freely defined id, usually INT or URI
  String? imagePath;
  String? historicalImageDescription; // some nice refence text for historical image
  String? historicalImagePath;
  String? historicalImageId; // freely defined id, usually INT or URI
  bool? historicalPhotoFlipped;
  DateTime? timestamp; // use original until we need to convert
  double? scale;
  double? latitude;
  double? longitude;
  double? accuracy;
  bool? rephotoIsFlipped;
  bool? isUploaded = false; // track locally stored data: uploaded to server yet?
  String? filename = ""; // temporary name when handling in app, no need to store

  Draft(
    this.id,
    this.imagePath,
    this.historicalImageDescription,
    this.historicalImagePath,
    this.historicalImageId,
    this.historicalPhotoFlipped,
    this.timestamp,
    this.scale,
    this.latitude,
    this.longitude,
    this.accuracy,
    this.rephotoIsFlipped,
  );

  // FYI: if we need the age of this draft:
  // just calculate it when needed..
  getAge() {
    return DateTime.now().difference(timestamp!);
  }

/* currently this isn't even used? all fields are used directly when generating upload now
  -> modify more later */
  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'historicalImagePath': historicalImagePath,
        'historicalImageId': historicalImageId,
        'historicalPhotoFlipped': historicalPhotoFlipped,
        'timestamp': timestamp!.toIso8601String(), // keep it in standard format when saving normally
        'scale': scale,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'rephotoIsFlipped': rephotoIsFlipped,
        'isUploaded': isUploaded
      };

  Draft.fromJson(Map<String, dynamic> json) {
       id = (json['id'] != null) ? json['id'] : "";
       imagePath = json['imagePath'];
       historicalImageDescription = json['historicalImageDescription'];
       historicalImagePath = json['historicalImagePath'];
       historicalImageId = json['historicalImageId'];
       historicalPhotoFlipped = json['historicalPhotoFlipped'];
       timestamp = json['timestamp'];
       scale = double.parse(json['scale']);
       latitude = double.parse(json['latitude']);
       longitude = double.parse(json['longitude']);
       accuracy = double.parse(json['accuracy']);
       rephotoIsFlipped = json['rephotoIsFlipped'];
  }

}
