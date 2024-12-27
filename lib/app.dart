import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:geolocator/geolocator.dart';
import "package:http/http.dart" as http;
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/theme.dart';
import 'package:kibtaxi/screens/bookmark.dart';
import 'package:kibtaxi/screens/home.dart';
import 'package:kibtaxi/themes/dark.dart';
import 'package:kibtaxi/themes/light.dart';
import 'package:kibtaxi/widgets/bars/bottom.navigation_bar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class _MyAppState extends State<MyApp>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  Locale? _locale;
  late Future<dynamic> _position;
  int _currentIndex = 0;
  bool _connectionStatus = true;
  late StreamSubscription<List<ConnectivityResult>> _streamSubscription;

  AnimationController? _animationController;
  Animation<double>? _animation;

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code');

    setState(() {
      if (languageCode != null && languageCode.isNotEmpty) {
        _locale = Locale(languageCode);
      } else {
        final systemLocale = WidgetsBinding.instance.window.locale;
        _locale = systemLocale.languageCode == 'tr'
            ? const Locale('tr')
            : const Locale('en');
      }
    });
  }

  Future<void> _checkApiHealth() async {
    try {
      final response = await http.get(
        Uri.parse("${dotenv.env['API_URL']}?API_KEY=${dotenv.env['API_KEY']}"),
      );

      if (response.statusCode == 200) {
        debugPrint("Connection to the server is successful.");
      }
    } catch (e) {
      throw Exception("Connection to the server is failed.");
    }
  }

  Future<dynamic> _getPosition() async {
    bool isLocationServiceEnabled;
    LocationPermission locationPermission;

    isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      return Future.error('Location services are disabled');
    }

    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();

      if (locationPermission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (locationPermission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied');
    }

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return position;
  }

  void _checkConnectivity() async {
    final List<ConnectivityResult> connectivityResult =
        await (Connectivity().checkConnectivity());

    if (connectivityResult.contains(ConnectivityResult.none)) {
      setState(() {
        _connectionStatus = false;
      });
    }
  }

  void _listenConnectivity() {
    _streamSubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> connectivityResult) {
      setState(() {
        _connectionStatus =
            !connectivityResult.contains(ConnectivityResult.none);
      });
    });
  }

  void setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void onTap(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void onUpdated() {
    setState(() {
      _position = _getPosition();
    });
  }

  void _handleLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission != LocationPermission.denied ||
        permission != LocationPermission.deniedForever) {
      setState(() {
        _position = _getPosition();
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      if (_position == null) {
        _handleLocationPermission();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_locale == null) {
      Locale locale = WidgetsBinding.instance.window.locale;
      _locale =
          locale.languageCode == 'tr' ? const Locale('tr') : const Locale('en');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _animationController!.dispose();
    _streamSubscription.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _checkConnectivity();
    _listenConnectivity();

    _loadLocale();

    _checkApiHealth();
    _position = _getPosition();

    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _animation = Tween<double>(begin: 0.25, end: .75).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );

    _animationController!.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: "Kıbtaxi",
      theme: LightThemeData.theme,
      darkTheme: DarkThemeData.theme,
      themeMode: themeProvider.themeMode,
      locale: _locale,
      supportedLocales: const [Locale('en', ''), Locale('tr', '')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate
      ],
      localeResolutionCallback: (locale, supportedLocales) {
        for (var supportedLocale in supportedLocales) {
          if (supportedLocale.languageCode == locale?.languageCode) {
            return supportedLocale;
          }
        }
        return supportedLocales.first;
      },
      home: Scaffold(
        body: FutureBuilder<dynamic>(
          future: _position,
          builder: (context, snapshot) {
            if (!_connectionStatus) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/icons/app.light.png'
                          : 'assets/icons/app.png',
                      semanticLabel: "App Logo",
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!
                              .translate('check_connection'),
                          textAlign: TextAlign.center,
                          semanticsLabel: "Internet Connection Error",
                        )
                      ],
                    ),
                  )
                ],
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Theme.of(context).colorScheme.primary,
                          size: 42,
                          semanticLabel: "Location Icon",
                        ),
                        const SizedBox(height: 8),
                        FadeTransition(
                          opacity: _animation!,
                          child: Text(
                            AppLocalizations.of(context)!
                                .translate("finding_location"),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            semanticsLabel: "Finding User's Location",
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * .4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SpinKitRipple(
                          size: MediaQuery.of(context).size.width * 0.5,
                          duration: const Duration(milliseconds: 2000),
                          itemBuilder: (context, index) {
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(360),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              if (snapshot.error.toString() ==
                  'Location services are disabled') {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * .8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Theme.of(context).colorScheme.primary,
                            size: 42,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate("location_services_disabled"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await Geolocator.openLocationSettings();

                              Geolocator.getServiceStatusStream()
                                  .listen((status) async {
                                if (status == ServiceStatus.enabled) {
                                  setState(() {
                                    _position = _getPosition();
                                  });
                                }
                              });
                            },
                            child: Text(
                                AppLocalizations.of(context)!
                                    .translate("enable_location_services"),
                                semanticsLabel: "Enable Location Services"),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .5,
                      height: MediaQuery.of(context).size.height * .2,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? "assets/icons/splash.light.png"
                            : "assets/icons/splash.png",
                        fit: BoxFit.contain,
                        semanticLabel: "Splash Icon",
                      ),
                    )
                  ],
                );
              } else if (snapshot.error.toString() ==
                  'Location permissions are denied') {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * .8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Theme.of(context).colorScheme.primary,
                            size: 42,
                            semanticLabel: "Location Off Icon",
                          ),
                          // SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate("location_permissions_denied"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              semanticsLabel: "Location Permissions Denied",
                            ),
                          ),
                          // SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                _position = _getPosition();
                              });
                            },
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate("allow_location_permissions"),
                              semanticsLabel: "Allow Location Permissions",
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .5,
                      height: MediaQuery.of(context).size.height * .2,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? "assets/icons/splash.light.png"
                            : "assets/icons/app.png",
                        fit: BoxFit.contain,
                        semanticLabel: "Splash Icon",
                      ),
                    )
                  ],
                );
              } else if (snapshot.error.toString() ==
                  "Location permissions are permanently denied") {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * .8,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off,
                            color: Theme.of(context).colorScheme.primary,
                            size: 42,
                            semanticLabel: "Location Off Icon",
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              AppLocalizations.of(context)!.translate(
                                  "location_permissions_permanently_denied"),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              semanticsLabel: "Location Permissions Denied",
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await Geolocator.openLocationSettings();

                              Geolocator.getServiceStatusStream()
                                  .listen((status) async {
                                if (status == ServiceStatus.enabled) {
                                  setState(() {
                                    _position = _getPosition();
                                  });
                                }
                              });
                            },
                            child: Text(
                              AppLocalizations.of(context)!
                                  .translate("open_location_settings"),
                              semanticsLabel: AppLocalizations.of(context)!
                                  .translate("open_location_settings"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * .5,
                      height: MediaQuery.of(context).size.height * .2,
                      child: Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? "assets/icons/splash.light.png"
                            : 'assets/icons/splash.png',
                        fit: BoxFit.contain,
                        semanticLabel: "Slash Icon",
                      ),
                    )
                  ],
                );
              }
            }

            if (snapshot.hasData) {
              final List<Widget> screens = [
                HomeScreen(
                  position: snapshot.data,
                ),
                const BookmarkScreen(),
              ];

              return Scaffold(
                body: IndexedStack(
                  index: _currentIndex,
                  children: screens,
                ),
                bottomNavigationBar: MyBottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: onTap,
                ),
              );
            }

            return const Center(
              child: Text(
                "Something went wrong.",
                semanticsLabel: "Error Message: Something went wrong",
              ),
            );
          },
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  static _MyAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>();

  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}
