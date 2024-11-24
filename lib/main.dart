import "package:flutter/material.dart";
import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:google_mobile_ads/google_mobile_ads.dart";
import "package:provider/provider.dart";
import "app.dart";
import "providers/bookmark.dart";
import "providers/theme.dart";
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await MobileAds.instance.initialize();

  timeago.setLocaleMessages('tr', timeago.TrMessages());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => BookmarkProvider())
      ],
      child: const MyApp(),
    ),
  );
}
