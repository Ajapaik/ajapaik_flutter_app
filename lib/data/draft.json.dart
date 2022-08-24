class Draft {
  final String id; // freely defined id, usually INT or URI
  final String imagePath;
  final String historicalImagePath;
  final String historicalImageId; // freely defined id, usually INT or URI
  final bool historicalPhotoFlipped;
  final double latitude;
  final double longitude;
  final double accuracy;
  //final double age; // age? what format? seconds? counting from when? never used?
  //final String date;
  final DateTime timestamp; // use original until we need to convert
  final double scale;
  final bool rephotoIsFlipped;
  bool isUploaded = false; // track locally stored data: uploaded to server yet?

  Draft(
    this.id,
    this.imagePath,
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

  // ajapaik uses some this format for timestamp:
  // it isn't ISO-standard format but something specific to it
  // -> handle as special when needed unless server can be modified too?
  String dateForAjapaik() {
    String convertedDateTime =
        timestamp.day.toString().padLeft(2, '0') +
            "-" +
            timestamp.month.toString().padLeft(2, '0') +
            "-" +
            timestamp.year.toString();
    return convertedDateTime;
  }

  // FYI: if we need the age of this draft:
  // just calculate it when needed..
  getAge() {
    return DateTime.now().difference(timestamp);
  }

  /* currently this isn't even used? all fields are used directly when generating upload now
  -> modify more later
  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': imagePath,
        'historicalImagePath': historicalImagePath,
        'historicalImageId': historicalImageId,
        'historicalPhotoFlipped': historicalPhotoFlipped,
        'timestamp': timestamp.toIso8601String(), // keep it in standard format when saving normally
        'scale': scale,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'rephotoIsFlipped': rephotoIsFlipped,
        'isUploaded': isUploaded
      };

   */

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
