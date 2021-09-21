import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class maniphoto extends StatelessWidget {

  maniphoto({
    Key? key,
    required String this.historicalPhotoUri,
  })
      :
        super(key: key);

  final String historicalPhotoUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Rephoto'),
        ),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      child: Container(
                        // margin: const EdgeInsets.all(10.0),
                        // decoration:
                        // BoxDecoration(border: Border.all(color: Colors.blueAccent)),
                          child: InAppWebView(initialUrlRequest: URLRequest
                            (url:
                          Uri.parse(historicalPhotoUri)))
                      )
                  ),
                ]
            )
        )
    );
  }
}