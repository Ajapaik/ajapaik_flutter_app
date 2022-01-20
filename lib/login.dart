import 'package:flutter/material.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'demolocalization.dart';
import 'getxnavigation.dart';
import 'data/user.json.dart';

class DisplayLoginScreen extends StatelessWidget {
  final controller = Get.put(Controller());

  DisplayLoginScreen({Key? key}) : super(key: key);

  void _launchURL(_url) async => await canLaunch(_url)
      ? await launch(_url)
      : throw 'Could not launch $_url';

  void doLogin(String provider) {
    var nextParam =
        "/accounts/launcher/?token=token&route=route&provider=" + provider;
    var url = "https://staging.ajapaik.ee/accounts/" +
        provider +
        "/login/?next=" +
        Uri.encodeComponent(nextParam);
    _launchURL(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('login-appBarTitle'))),
        body: controller.getSession() == "" ? loginButtons() : logoutButton());
  }

  Widget loginButtons() {
    return Center(
        child: Wrap(spacing: 10, runSpacing: 10, children: <Widget>[
      SignInButton(
        Buttons.Google,
        onPressed: () {
          doLogin("google");
        },
      ),
      SignInButton(
        Buttons.Facebook,
        onPressed: () {
          doLogin("facebook");
        },
      ),
      SignInButtonBuilder(
        text: 'Sign in with Wikimedia',
        icon: FontAwesomeIcons.wikipediaW,
        onPressed: () {
          doLogin("wikimedia-commons");
        },
        backgroundColor: const Color(0xFF3366cc),
      ),
      SignInButton(
        Buttons.Email,
        onPressed: () {},
      ),
    ]));
  }

  Widget logoutButton() {
    return Center(
        child: Column(children: <Widget>[
      const UserInfoBuilder(),
      SignInButtonBuilder(
        text: 'Sign out',
        icon: Icons.logout,
        onPressed: () async {
          await controller.logout();
          Get.back();
        },
        backgroundColor: const Color(0xFF3366cc),
      )
    ]));
  }
}

class UserInfoBuilder extends StatelessWidget {
  const UserInfoBuilder({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User>(
      future: fetchUser(),
      builder: (context, snapshot) {
        if (snapshot.hasError) (snapshot.error);

        return snapshot.hasData
            ? UserInfoView(user: snapshot.data)
            : const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class UserInfoView extends StatelessWidget {
  final User? user;

  const UserInfoView({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(user!.name);
  }
}
