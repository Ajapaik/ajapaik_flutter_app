import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'localization.dart';
import 'preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  SettingsScreenState createState() => SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  final prefs = Get.find<Preferences>();

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.getText(context, 'settings-appbarTitle'),
            style: const TextStyle(
              fontWeight: FontWeight.w400,
              fontFamily: 'Roboto',
            )),
      ),
      body: SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          child: Column(children: [
            ListTile(
              leading: const Icon(Icons.public, color: Colors.white),
              title: Text(AppLocalizations.getText(context, 'settings-cardItem1')),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.white),
              title: Text(AppLocalizations.getText(context, 'settings-cardItem2')),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            )
          ]),
        ),
        const SizedBox(height: 10.0),
                Text(AppLocalizations.getText(context, 'settings-helperText')),
        SwitchListTile(
          activeColor: Colors.blue,
          value: prefs.tooltip,
          title: Text(AppLocalizations.getText(context, 'settings-showMapTile')),
          onChanged: (bool newValue) {
            setState(() => prefs.tooltip = newValue);
            prefs.saveTooltipPrefs();
          },
        )
      ])),
    );
  }
}
