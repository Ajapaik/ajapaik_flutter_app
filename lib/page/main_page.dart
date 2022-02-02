import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);
  @override
  MainPageState createState() =>MainPageState();
}

class MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(onPressed: () {  },
            child: const Text('Photos'),),
            ElevatedButton(onPressed: () {  },
              child: const Text('Map'),),
            ElevatedButton(onPressed: () {  },
              child: const Text('Albums'),),
          ],
        ),
      ],),
    );
  }
}