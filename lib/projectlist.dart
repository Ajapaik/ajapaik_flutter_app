import 'package:flutter/material.dart';
import 'package:ajapaik_flutter_app/data/project.json.dart';
import 'package:ajapaik_flutter_app/albumlist.dart';
import 'package:get/get.dart';
import 'localization.dart';
import 'localfileselect.dart';
import 'login.dart';
import 'sessioncontroller.dart';
import 'httpcontroller.dart';
import 'imagestorage.dart';

class ProjectListPage extends StatefulWidget {
  final String? title;

  const ProjectListPage({Key? key, this.title}) : super(key: key);

  @override
  ProjectListPageState createState() => ProjectListPageState();
}

class ProjectListPageState extends State<ProjectListPage> {
  final sessionController = Get.find<SessionController>();

  String getProjectUrl() {
    String url = sessionController.getDatasourceUri();
    url += "/projects.php";
    return url;
  }

  @override
  void initState() {
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
      body: ProjectListBuilder(getProjectUrl()),
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
  final String projectUrl;
  const ProjectListBuilder(this.projectUrl, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Project>>(
      future: fetchProjects(projectUrl),
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
  final imageStorage = Get.find<ImageStorage>();

  ProjectList({Key? key, required this.photos}) : super(key: key);

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
                imageStorage.getCachedNetworkImage(photos![index].thumbnailUrl!),
                Text(
                  photos![index].name,
                  textAlign: TextAlign.center,
                )
              ]));
        });
  }
}
