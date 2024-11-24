import 'package:flutter/material.dart';
import 'package:kibtaxi/app.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/widgets/bars/appbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String? _currentLanguage;

  @override
  Widget build(BuildContext context) {
    _currentLanguage ??= Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: MyAppBar(
        title: Text(
          AppLocalizations.of(context)!.translate("language_settings"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          semanticsLabel: "Language Settings",
        ),
      ),
      body: Column(
        children: [
          RadioListTile(
            title: Text(
              AppLocalizations.of(context)!.translate("english"),
              semanticsLabel: "English",
            ),
            value: 'en',
            groupValue: _currentLanguage,
            selected: _currentLanguage == 'en',
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) async {
              Locale locale = const Locale('en');
              MyApp.of(context)?.setLocale(locale);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language_code', locale.languageCode);

              _currentLanguage = value;
            },
          ),
          RadioListTile(
            title: Text(
              AppLocalizations.of(context)!.translate("turkish"),
              semanticsLabel: "Turkish",
            ),
            value: 'tr',
            groupValue: _currentLanguage,
            selected: _currentLanguage == 'tr',
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (value) async {
              Locale locale = const Locale('tr');
              MyApp.of(context)?.setLocale(locale);

              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('language_code', locale.languageCode);

              _currentLanguage = value;
            },
          ),
        ],
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}
