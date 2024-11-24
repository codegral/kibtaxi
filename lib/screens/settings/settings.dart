import 'package:flutter/material.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/screens/settings/language.dart';
import 'package:kibtaxi/screens/settings/theme.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/widgets/bars/appbar.dart';

Route _createThemeSettingsRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const ThemeSettingsScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      // Apply the animation using SlideTransition
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

Route _createLanguageSettings() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const LanguageSettingsScreen(),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
      var offsetAnimation = animation.drive(tween);

      // Apply the animation using SlideTransition
      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          AppLocalizations.of(context)!.translate("settings"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          semanticsLabel: "Settings",
        ),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.translate("theme"),
              semanticsLabel: "Theme",
            ),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
              semanticLabel: "Arrow Right Icon",
            ),
            onTap: () {
              Navigator.of(context).push(_createThemeSettingsRoute());
            },
          ),
          ListTile(
            title: Text(
              AppLocalizations.of(context)!.translate("language"),
              semanticsLabel: "Language",
            ),
            trailing: const Icon(
              Icons.keyboard_arrow_right,
              semanticLabel: "Arrow Right Icon",
            ),
            onTap: () {
              Navigator.of(context).push(_createLanguageSettings());
            },
          )
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
