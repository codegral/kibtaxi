import 'package:flutter/material.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/theme.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/widgets/bars/appbar.dart';
import 'package:provider/provider.dart';

class ThemeSettingsScreen extends StatelessWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          AppLocalizations.of(context)!.translate("theme_settings"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          semanticsLabel: "Theme Settings",
        ),
      ),
      body: Column(
        children: [
          RadioListTile(
            title: Text(
              AppLocalizations.of(context)!.translate("light_theme"),
              semanticsLabel: "Light Theme",
            ),
            value: ThemeMode.light,
            groupValue: Theme.of(context).brightness == Brightness.light
                ? ThemeMode.light
                : ThemeMode.dark,
            // groupValue: themeProvider.themeMode,
            selected: Theme.of(context).brightness == Brightness.light,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setTheme(value);
              }
            },
          ),
          RadioListTile(
            title: Text(
              AppLocalizations.of(context)!.translate("dark_theme"),
              semanticsLabel: "Dark Theme",
            ),
            value: ThemeMode.dark,
            groupValue: Theme.of(context).brightness == Brightness.dark
                ? ThemeMode.dark
                : ThemeMode.light,
            // groupValue: themeProvider.themeMode,
            selected: Theme.of(context).brightness == Brightness.dark,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) {
              if (value != null) {
                themeProvider.setTheme(value);
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
