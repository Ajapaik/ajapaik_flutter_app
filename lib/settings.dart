import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demolocalization.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

bool tooltip = true;

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {

    @override
    _saveBool() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tooltip', tooltip);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('settings-appbarTitle'),
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
              title: Text(AppLocalizations.of(context)!.translate('settings-cardItem1')),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.menu_book, color: Colors.white),
              title: Text(AppLocalizations.of(context)!.translate('settings-cardItem2')),
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            )
          ]),
        ),
        const SizedBox(height: 10.0),
                Text(AppLocalizations.of(context)!.translate('settings-helperText')),
        SwitchListTile(
          activeColor: Colors.blue,
          value: tooltip,
          title: Text(AppLocalizations.of(context)!.translate('settings-showMapTile')),
          onChanged: (bool newValue) {
            setState(() => tooltip = newValue);
            _saveBool();
          },
        )
      ])),
    );
  }
}
