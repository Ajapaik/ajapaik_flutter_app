import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'demolocalization.dart';

class ManiPhoto extends StatelessWidget {
  const ManiPhoto({
    Key? key,
    required this.historicalPhotoUri,
  }) : super(key: key);

  final String historicalPhotoUri;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.translate('photoManipulation-appbarTitle'),
                style: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Roboto',
                ))),
        body: Center(
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              Expanded(
                  child: InAppWebView(
                      initialUrlRequest:
                          URLRequest(url: Uri.parse(historicalPhotoUri)))),
            ])));
  }
}
