class Draft {
  final String id; // freely defined id, usually INT or URI
  final String imagePath;
  final String historicalImagePath;
  final String historicalImageId; // freely defined id, usually INT or URI
  final bool historicalPhotoFlipped;
  final double lat;
  final double lon;
  final double accuracy;
  //final double age; // age? what format? seconds? counting from when? never used?
  final String date;
  final double scale;
  final bool rephotoIsFlipped;
  bool isUploaded = false;

  Draft(
    this.id,
    this.imagePath,
    this.historicalImagePath,
    this.historicalImageId,
    this.historicalPhotoFlipped,
    this.date,
    this.scale,
    this.lat,
    this.lon,
    this.accuracy,
    this.rephotoIsFlipped,
  );

  Map<String, dynamic> toJson() => {
        'id': id,
        'historicalImageId': historicalImageId,
        'historicalPhotoFlipped': historicalPhotoFlipped,
        'lat': lat,
        'lon': lon,
        'accuracy': accuracy,
        'date': date,
        'scale': scale,
        'rephotoIsFlipped': rephotoIsFlipped,
        'filename': imagePath,
        'historicalImagePath': historicalImagePath,
        'isUploaded': isUploaded
      };

/*  Draft.fromJson(Map json)
      : id = json['id'],
        rephotoOfId = json['rephotoOfId'],
        filename = json['filename'],
        historicalImagePath = json['historicalImagePath'],
        date = json['date'],
        scale = json['scale'],
        lat = json['scale'],
        lon = json['scale'],
        age = json['scale'],
        accuracy = json['scale'],
        rephotoIsFlipped = json['scale']
*/

}
