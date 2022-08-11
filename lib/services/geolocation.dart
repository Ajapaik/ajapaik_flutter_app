import 'package:geolocator/geolocator.dart';
import 'dart:async';

// could use something like Singleton<> ..
class AppLocator extends Geolocator  {
  // don't repeat same in every place..
  // note: should use Position directly instead of "unpacking" to separate variables..
  double latitudePos = 0;
  double longitudePos = 0;

  double getLatitude() {
    return latitudePos;
  }
  double getLongitude() {
    return longitudePos;
  }

  // TODO: if we want to track position automatically, add something like timer
  // so that we don't flood everything with requests by mistake..

  /*

  bool serviceEnabled = false;

  // if we decide to cache the result..
  bool isEnabled() {
    return serviceEnabled;
  }
   */

  Future<bool> verifyService() async {
    LocationPermission permission;

    // Test if location services are enabled.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      //return Future.error('Location services are disabled.');
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        //return Future.error('Location permissions are denied');
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      //return Future.error('Location permissions are permanently denied, we cannot request permissions.');
      return false;
    }

    // by this, it seems location should be available
    return true;
  }

  // get real position (if enabled) or fall back to alternate:
  // determine callers how situation really should be handled
  Future<Position> getPositionOrFallback() async {
    bool isEnabled = await verifyService();
    if (isEnabled == true) {
      return determinePosition();
    }
    return getFallbackPosition();
  }


  Future<Position> getFallbackPosition() async {
    Position position=Position.fromMap({'latitude': 60, 'longitude': 24});
    return Future.value(position);
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> determinePosition() async {

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  Future<LocationAccuracyStatus> determineAccuracy() async {
    var accuracy = await Geolocator.getLocationAccuracy();
    return accuracy;
  }

}

