import 'package:geolocator/geolocator.dart';
import 'dart:async';

// could use something like Singleton<> ..
class AppLocator extends Geolocator  {
  // don't repeat same in every place..
  // note: should use Position directly instead of "unpacking" to separate variables..
  double latitudePos = 0;
  double longitudePos = 0;
  bool isInitialized = false;
  bool isFixed = false; // user-selected position in use, don't overwrite

  //TODO: also keep accuracy
  //LocationAccuracyStatus accuracy;

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
      isInitialized = true;
    }
  }

  // in case user will force selected position:
  // when not available otherwise or there is significant error otherwise?
  // -> prevent overwriting by repeated calls later
  void setFixedPosition(double longitude, double latitude) {
    longitudePos = longitude;
    latitudePos = latitude;
    isFixed = true;
  }


  // TODO: if we want to track position automatically, add something like timer
  // so that we don't flood everything with requests by mistake..

  Future<bool> updatePosition() async {
    bool isEnabled = await verifyService();
    if (isEnabled == true) {
      Position pos = await Geolocator.getCurrentPosition();
      latitudePos = pos.latitude;
      longitudePos = pos.longitude;

      // also keep accuracy
      //LocationAccuracyStatus las = await determineAccuracy();
      return true;
    }
    // we should be called at least once in init(), which is called when app starts first..
    // but we could set defaults in constructor too
    print("location service not enabled");
    latitudePos = 60;
    longitudePos = 24;
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

  getPosition() {
    return Position.fromMap({'latitude': latitudePos, 'longitude': longitudePos});
  }

  Future<LocationAccuracyStatus> determineAccuracy() async {
    var accuracy = await Geolocator.getLocationAccuracy();
    return accuracy;
  }

}

