import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ajapaik_flutter_app/data/project.json.dart';
import 'package:ajapaik_flutter_app/albumlist.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'localfileselect.dart';
import 'login.dart';
import 'package:get/get.dart';
import 'getxnavigation.dart';

class ProjectListPage extends StatelessWidget {
  final String? title;

  ProjectListPage({Key? key, this.title}) : super(key: key);
  final controller = Get.put(Controller());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: FutureBuilder<List<Project>>(
        future: fetchProjects(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? ProjectList(photos: snapshot.data)
              : const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          print(index);
          if (index == 2) {
            Get.to( DisplayLoginScreen());
          } else {
            showPicker(context);
          }
        },
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Take photo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
        ],
      ),
    );
  }
}

class ProjectList extends StatelessWidget {
  final List<Project>? photos;

  const ProjectList({Key? key, required this.photos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: photos!.length,
        itemBuilder: (context, index) {
          return GestureDetector(
              onTap: () {
                if (photos![index].geojson != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AlbumListPage.network(
                            photos![index].name, photos![index].geojson!)),
                  );
                }
              },
              child: Column(children: [
                CachedNetworkImage(
                  imageUrl: photos![index].thumbnailUrl!.toString(),
                ),
                Text(
                  photos![index].name,
                  textAlign: TextAlign.center,
                )
              ]));
        });
  }
}
