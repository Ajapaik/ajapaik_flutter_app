import 'package:flutter/material.dart';
import 'package:ajapaik_flutter_app/data/project.json.dart';
import 'package:ajapaik_flutter_app/albumlist.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'localization.dart';
import 'localfileselect.dart';
import 'login.dart';
import 'package:get/get.dart';
import 'sessioncontroller.dart';
import 'httpcontroller.dart';

class ProjectListPage extends StatefulWidget {
  final String? title;

  const ProjectListPage({Key? key, this.title}) : super(key: key);

  @override
  ProjectListPageState createState() => ProjectListPageState();
}

// try to get rid of copy-pasted urls everywhere
final String projectUri = 'https://ajapaik.toolforge.org/api/projects.php';

class ProjectListPageState extends State<ProjectListPage> {
  final sessionController = Get.put(SessionController());

  @override
  void initState() {
    // TODO: if there are no network permissions or no connectivity for another reason
    // -> working without connection

    /*
    sessionController.loadSession().then((_) => setState(() {
        }));
        */
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    bool loggedIn = !(sessionController.isExpired());
    String title = AppLocalizations.getText(context, 'projectList-rephotoProjects');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading:
          IconButton(icon: const Icon(Icons.home_rounded), onPressed: () async {
            /*await Navigator.push(
                context,
                MaterialPageRoute(
                builder: (context) => HomePage()));*/
          },
          )


      ),
      body: const ProjectListBuilder(),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          (index);
          if (index == 2) {
            Get.to(DisplayLoginScreen())?.then((_) => setState(() {
                }));
          } else {
            showPicker(context);
          }
        },
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon((loggedIn ? Icons.person : Icons.login)),
            label: (loggedIn ? AppLocalizations.getText(context, 'projectList-navItem4')
                : AppLocalizations.getText(context, 'projectList-navItem3')
            )),
          BottomNavigationBarItem(
            icon: const Icon(Icons.photo_library),
            label: AppLocalizations.getText(context, 'projectList-navItem1')
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
      future: fetchProjects(projectUri),
      builder: (context, snapshot) {
        if (snapshot.hasError) (snapshot.error);

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
                  (photos![index].name);
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
