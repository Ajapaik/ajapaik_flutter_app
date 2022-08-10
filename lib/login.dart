import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sign_in_button/sign_in_button.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';
import 'localization.dart';
import 'getxnavigation.dart';
import 'data/user.json.dart';

// TOOD: cleaner handling of logins
enum LoginProviders { loginGoogle, loginFacebook, loginWikimedia }

class DisplayLoginScreen extends StatelessWidget {
  final controller = Get.put(Controller());
  DisplayLoginScreen({Key? key}) : super(key: key);

  void _launchURL(_url) async => await canLaunchUrl(_url)
      ? await launchUrl(_url, mode: LaunchMode.externalApplication,)
      : throw 'Could not launch $_url';

  void doLogin(String provider) {
    // TODO: handle different logins without depending on ajapaik-server
    // when user wants to upload to commons and/or social media
    // -> don't depend on external server

    var nextParam =
        "/accounts/launcher/?token=token&route=route&provider=" + provider;
    var url = "https://ajapaik.ee/accounts/" +
        provider +
        "/login/?next=" +
        Uri.encodeComponent(nextParam);
    _launchURL(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('login-appBarTitle'))),
        body: controller.isExpired() == true ? loginButtons() : logoutButton());
  }

  Widget loginButtons() {
    // buttons could be constants built in constructor, there is nothing here that changes?
    // also OAuth and other options -> needs to handle more cases than just these
    List<Widget> buttons = [];
    buttons.add(SignInButton(
      Buttons.google,
      onPressed: () {
        doLogin("google");
      },
    ));
    buttons.add(SignInButton(
      Buttons.facebook,
      onPressed: () {
        doLogin("facebook");
      },
    ));
    buttons.add(SignInButtonBuilder(
      text: 'Sign in with Wikimedia',
      icon: FontAwesomeIcons.wikipediaW,
      onPressed: () {
        doLogin("wikimedia-commons");
      },
      backgroundColor: const Color(0xFF3366cc),
    ));
/*      SignInButton(
        Buttons.email,
        onPressed: () {},
      ),*/

    // TODO: if user wants to upload to social media, possibly other different auth methods as well?
    // -> not only different login provider, but also different server (commons, ajapaik)

    return Center(
        child: Wrap(spacing: 10, runSpacing: 10, children: buttons
    ));
  }

  Widget logoutButton() {
    return Center(
        child:  Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
      const UserInfoBuilder(),
      SignInButtonBuilder(
        innerPadding: EdgeInsets.all(11.0),
        fontSize:25,
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
