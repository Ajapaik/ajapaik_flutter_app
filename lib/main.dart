import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ajapaik_camera_test3/projectlist.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  //final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  //final firstCamera = cameras.first;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appTitle = 'Test app';

    return MaterialApp(
      theme: ThemeData.dark(),
      title: appTitle,
      home: ProjectListPage(title: appTitle),
    );
  }
}
