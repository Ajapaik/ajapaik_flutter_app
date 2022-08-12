import 'package:geolocator/geolocator.dart';
import 'dart:async';

// could use something like Singleton<> ..
class AppLocator extends Geolocator  {
  // don't repeat same in every place..
  // note: should use Position directly instead of "unpacking" to separate variables..
  double latitudePos = 0;
  double longitudePos = 0;
  bool isInitialized = false;

  //TODO: also keep accuracy
  //LocationAccuracyStatus accuracy;

  // TODO: force user-selected position when not available otherwise?
  // -> prevent overwriting by repeated calls later

  /* TODO: check if this is still needed..
  StreamSubscription<Position>? _positionStream;
  void listenCurrentLocation() {
    LocationSettings locationSettings = const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 10,
        timeLimit: Duration(seconds: 5)
    );
    _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings).listen((Position geoPosition)
    {
      if (geoPosition.latitude != getLatitude() &&
          geoPosition.longitude != getLongitude()) {
        updatePosition();
      }
    });
  }
  @override
  void initState() {
    listenCurrentLocation();
    //super.initState();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    //super.dispose();
  }
  */

  double getLatitude() {
    return latitudePos;
  }
  double getLongitude() {
    return longitudePos;
  }

  // just make sure we hav other values apart from initial position?
  void init() {
    if (isInitialized == false) {
      updatePosition();
    }
    isInitialized = true;
  }


  // TODO: if we want to track position automatically, add something like timer
  // so that we don't flood everything with requests by mistake..

  Future<bool> updatePosition() async {
    bool isEnabled = await verifyService();
    if (isEnabled == true) {
      Position pos = await determinePosition();
      latitudePos = pos.latitude;
      longitudePos = pos.longitude;

      // also keep accuracy
      //LocationAccuracyStatus las = await determineAccuracy();
      return true;
    }
    print("location service not enabled");
    return false;
  }

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

