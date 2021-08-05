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

class ProjectListPage extends StatefulWidget {
  final String? title;

  const ProjectListPage({Key? key, this.title}) : super(key: key);

  @override
  ProjectListPageState createState() => ProjectListPageState();
}

class ProjectListPageState extends State<ProjectListPage> {
  final String? title = "Rephoto projects";
  final controller = Get.put(Controller());

  @override
  void initState() {
    controller.loadSession().then((_) => setState(() {
          print("Updating login status to screen. Session " +
              controller.getSession());
        }));
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print(controller.getSession());
    bool loggedIn = !(controller.getSession() == "");

    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: const ProjectListBuilder(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          print(index);
          if (index == 2) {
            Get.to(DisplayLoginScreen())?.then((_) => setState(() {
                  print("foo" + controller.getSession());
                }));
          } else {
            showPicker(context);
          }
        },
        items: <BottomNavigationBarItem>[
          const BottomNavigationBarItem(
            icon: Icon(Icons.photo_library),
            label: 'Library',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.camera),
            label: 'Take photo',
          ),
          BottomNavigationBarItem(
            icon: Icon((loggedIn ? Icons.person : Icons.login)),
            label: (loggedIn ? "Logout" : "Login"),
          ),
        ],
      ),
    );
  }
}

class ProjectListBuilder extends StatelessWidget {
  const ProjectListBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: fetchProjects(http.Client()),
      builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error);

        return snapshot.hasData
            ? ProjectList(photos: snapshot.data)
            : const Center(child: CircularProgressIndicator());
      },
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
              onTap: () async {
                if (photos![index].geojson != null) {
                  print(photos![index].name);
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
