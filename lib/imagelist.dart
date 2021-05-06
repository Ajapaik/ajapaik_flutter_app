import 'dart:async';
import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:gallery_saver/gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'camera.dart';


Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client
//      .get(Uri.parse('https://jsonplaceholder.typicode.com/photos'));
      .get(Uri.parse('https://commons.wikimedia.org/wiki/User:Zache/test.json?action=raw&ctype=application/json'));
  // Use the compute function to run parsePhotos in a separate isolate.
   return compute(parsePhotos, response.body);
}
/*
Future<List<Photo>> fetchPhotos(http.Client client) async {
  final response = await client
      .get(Uri.parse('https://jsonplaceholder.typicode.com/photos'));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}
*/
// A function that converts a response body into a List<Photo>.
List<Photo> parsePhotos(String responseBody) {
  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();
  return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}
class Photo {
  final int? albumId;
  final int? id;
  final String? title;
  final String? url;
  final String? thumbnailUrl;

  Photo({this.albumId, this.id, this.title, this.url, this.thumbnailUrl});

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      albumId: json['albumId'] as int?,
      id: json['id'] as int?,
      title: json['title'] as String?,
      url: json['url'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

class ImageListPage extends StatelessWidget {
  final String? title;

  ImageListPage({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: FutureBuilder<List<Photo>>(
        future: fetchPhotos(http.Client()),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? PhotosList(photos: snapshot.data)
              : Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          _showPicker(context);
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

class PhotosList extends StatelessWidget {
  final List<Photo>? photos;

  PhotosList({Key? key, this.photos}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
      ),
      itemCount: photos!.length,
      itemBuilder: (context, index) {
        return new GestureDetector(
            onTap: () {
                availableCameras().then((availableCameras) {
                CameraDescription firstCamera = availableCameras.first;
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TakePictureScreen(camera: firstCamera, historicalPhotoInfo: photos![index] )),
                );
              });
            },
            child:Image.network(photos![index].thumbnailUrl!)
        );
      },
    );
  }
}

// https://medium.com/fabcoding/adding-an-image-picker-in-a-flutter-app-pick-images-using-camera-and-gallery-photos-7f016365d856
final picker = ImagePicker();

Future getImageFromGallery(context) async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      availableCameras().then((availableCameras) {
        final localphoto = Photo(
          albumId: 0,
          id: 0,
          title: "albumphoto",
          url: "url",
          thumbnailUrl: pickedFile.path.toString(),
        );

        CameraDescription firstCamera = availableCameras.first;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TakePictureScreen(camera: firstCamera, historicalPhotoInfo: localphoto  )),
        );
      });
    } else {
      print('No image selected 0.');
    }
}

Future saveImageFromCamera() async {
  final pickedImage = await picker.getImage(source: ImageSource.camera, imageQuality:100);
  if (pickedImage != null) {
    await GallerySaver.saveImage(pickedImage.path);
  } else {
    print('No image selected 1.');
  }
}


void _showPicker(context) {
  showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Container(
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.photo_library),
                    title: new Text('Photo Library'),
                    onTap: () {
                      getImageFromGallery(context);
                      Navigator.of(context).pop();
                    }),
                new ListTile(
                  leading: new Icon(Icons.photo_camera),
                  title: new Text('Camera'),
                  onTap: () {
                    saveImageFromCamera();
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      }
  );
}