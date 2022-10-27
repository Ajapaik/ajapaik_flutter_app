import 'dart:convert';

class Draft {
  String? imagePath; // path and name of image saved from camera
  String? historicalImageDescription; // some nice refence text for historical image
  String? historicalImagePath;
  String? historicalImageId; // freely defined id, usually INT or URI
  bool? historicalPhotoFlipped;
  bool? historicalPhotoRotation;
  bool? historicalPortrait; // true: portrait, false: landscape
  DateTime? timestamp;      // timestamp when associated image was taken
  double? scale;      // scaling factor of image
  double? latitude;   // location coordinates
  double? longitude;  // location coordinates
  double? accuracy;   // accuracy or location
  bool? rephotoIsFlipped;
  bool? isInGallery = false;  // track locally: image stored to gallery?
                              // gallery is second step after saving image from camera (but user may cancel)
  bool? isUploaded = false; // track locally stored data: uploaded to server yet?
                            // user might want to cancel upload or delay until later
  String? filename = ""; // temporary name when handling in app, no need to store

  Draft(
    this.imagePath,
    this.historicalImageDescription,
    this.historicalImagePath,
    this.historicalImageId,
    this.historicalPhotoFlipped,
    this.historicalPhotoRotation,
    this.historicalPortrait,
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
        'imagePath': imagePath,
        'historicalImagePath': historicalImagePath,
        'historicalImageId': historicalImageId,
        'historicalPhotoFlipped': historicalPhotoFlipped,
        'historicalPhotoRotation': historicalPhotoRotation,
        'historicalPortrait': historicalPortrait,
        'timestamp': timestamp!.toIso8601String(), // keep it in standard format when saving normally
        'scale': scale,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'rephotoIsFlipped': rephotoIsFlipped,
        'isUploaded': isUploaded
      };

  // note that format may potentially be different if application is upgraded between saving and loading
  Draft.fromJson(Map<String, dynamic> json) {
       imagePath = json['imagePath'];
       historicalImageDescription = json['historicalImageDescription'];
       historicalImagePath = json['historicalImagePath'];
       historicalImageId = json['historicalImageId'];
       historicalPhotoFlipped = json['historicalPhotoFlipped'];
       historicalPhotoRotation = json['historicalPhotoRotation'];
       historicalPortrait = json['historicalPortrait'];
       timestamp = DateTime.parse(json['timestamp']);
       scale = json['scale'];
       latitude = json['latitude'];
       longitude = json['longitude'];
       accuracy = json['accuracy'];
       rephotoIsFlipped = json['rephotoIsFlipped'];
  }
}
