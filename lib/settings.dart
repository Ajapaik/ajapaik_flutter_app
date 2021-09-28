import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  static const keyLanguage = 'key-language';
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}


class _SettingsScreenState extends State<SettingsScreen> {

  bool _tooltip = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Settings',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                fontFamily: 'Roboto',
              )),
        ),
            body: SingleChildScrollView(
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.public, color: Colors.white),
                        title: const Text('Vaihda kieli'),
                        trailing: const Icon(Icons.keyboard_arrow_right),
                        onTap:(){

                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.menu_book, color: Colors.white),
                        title: const Text('Vaihda ympäristö'),
                        trailing: const Icon(Icons.keyboard_arrow_right),
                        onTap:(){

                        },
                      )
                    ]
                  ),
                ),
                const SizedBox(height: 10.0),
                Text('Tooltip settings'),
                SwitchListTile(
                  activeColor: Colors.blue,
                  value: _tooltip,
                  title: Text('Show tooltip'),
                  onChanged: (bool newValue){
                    setState(() => _tooltip = newValue);
                  } ,
                )
              ]
            )
            ),
    );
  }

}