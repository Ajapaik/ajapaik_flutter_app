import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';

// could use something like Singleton<> ..
class AppLocator extends Geolocator  {
  // keep position along with rest of metadata
  // (timestamp, heading, altitude, accuracy..)
  Position? position;

  // did we get actual position
  // TODO: use accuracy instead..
  bool isRealPosition = false;

  bool isInitialized = false;

  bool isFixed = false; // user-selected position in use, don't overwrite

  AppLocator() {
    position = Position(longitude: 0, latitude: 0, timestamp: DateTime.now(),
        accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0);
  }


  /* TODO: check if this is still needed..
  updating position automatically would be nice but to conserve battery
  it would be better to trigger on/off at times?

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

  LatLng getLatLong() {
    if (isInitialized == false) {
      print("location isn't initialized");
    }
    return LatLng(position!.latitude, position!.longitude);
  }
  /*
  Position? getPosition() {
    if (position == null) {
      return Position.fromMap({'latitude': 0, 'longitude': 0, 'timestamp': DateTime.now()});
    }
    return position;
  }
  */

  // just make sure we hav other values apart from initial position?
  void init() async {
    if (isInitialized == false) {
      updatePosition();
      isInitialized = true;
    }
  }

  // in case user will force selected position:
  // when not available otherwise or there is significant error otherwise?
  // -> prevent overwriting by repeated calls later
  void setFixedPosition(double longitude, double latitude) {
    position = Position.fromMap({'latitude': latitude, 'longitude': longitude});
    isFixed = true;
  }


  // TODO: if we want to track position automatically, add something like timer
  // so that we don't flood everything with requests by mistake..

  Future<bool> updatePosition() async {
    if (isFixed == true) {
      return true; // user fixed -> no change
    }
    try {
      bool isEnabled = await verifyService();
      if (isEnabled == true) {
        position = await Geolocator.getCurrentPosition();

        isRealPosition = true; // TODO: use accuracry instead
        return true;
      }
    }
    on MissingPluginException catch (e) {
      // mac doesn't have plugin for geolocation
      print(e.toString());
    }
    // we should be called at least once in init(), which is called when app starts first..
    // but we could set defaults in constructor too
    print("location service not enabled");
    isRealPosition = false; // TODO: use accuracry instead
    position = Position.fromMap({'latitude': 60, 'longitude': 24});
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
}
