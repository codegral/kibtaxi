import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import "package:http/http.dart" as http;
import "package:geocoding/geocoding.dart";
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/screens/profile.dart';
import 'package:kibtaxi/screens/settings/settings.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:kibtaxi/widgets/bars/appbar.dart';
import 'package:kibtaxi/widgets/bottom_sheets/cities.bottom_sheet.dart';
import 'package:kibtaxi/widgets/bottom_sheets/profile.bottom_sheet.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import "package:fluttertoast/fluttertoast.dart";

Route _createSettingsRoute() {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) =>
        const SettingsScreen(),
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

class _HomeScreenState extends State<HomeScreen> {
  final InterstitialAds _interstitialAds = InterstitialAds();
  final ScrollController _scrollController = ScrollController();
  late Map<String, dynamic> position = {"latitude": null, "longitude": null};
  late Future<dynamic> _taxis;
  String? _city;

  Future<void> _getCity() async {
    try {
      List<Placemark> placemark = await placemarkFromCoordinates(
          position['latitude'], position['longitude']);

      String? city;

      if (placemark.first.locality!.isNotEmpty) {
        city = placemark.first.locality;
      } else if (placemark.first.locality!.isNotEmpty) {
        city = placemark.first.subLocality;
      } else if (placemark.first.subAdministrativeArea!.isNotEmpty) {
        city = placemark.first.subAdministrativeArea;
      } else if (placemark.first.administrativeArea!.isNotEmpty) {
        city = placemark.first.administrativeArea;
      } else {
        city = "your area";
      }

      setState(() {
        _city = city;
      });
    } catch (e) {
      throw Exception(e);
    }
  }

  Future<dynamic> _getTaxis() async {
    try {
      final response = await http.get(Uri.parse(
          "${dotenv.env['API_URL']}/taxis?lat=${position['latitude']}&long=${position['longitude']}&API_KEY=${dotenv.env['API_KEY']}"));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  void changePosition({required double latitude, required double longitude}) {
    setState(() {
      position = {
        "latitude": latitude,
        "longitude": longitude,
      };

      _getCity();
      _taxis = _getTaxis();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _interstitialAds.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    position = {
      "latitude": widget.position.latitude,
      "longitude": widget.position.longitude,
    };

    _getCity();
    _taxis = _getTaxis();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);

    return Scaffold(
      appBar: MyAppBar(
        title: GestureDetector(
          child: Image.asset(
            Theme.of(context).brightness == Brightness.dark
                ? 'assets/icons/brand.light.png'
                : 'assets/icons/brand.dark.png',
            height: 32,
            semanticLabel: "Brand Logo",
          ),
          onTap: () {
            _scrollController.animateTo(0.0,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                _createSettingsRoute(),
              );
            },
            icon: const Icon(
              Icons.menu,
              semanticLabel: "Menu Icon",
            ),
          ),
        ],
      ),
      body: FutureBuilder<dynamic>(
        future: _taxis,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                semanticsLabel: "Spinner",
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context)!
                                  .translate("getting_most_popular"),
                              style: TextStyle(
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.white54
                                    : Colors.black54,
                              ),
                              semanticsLabel: "Most Popular Taxis",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: 10,
                    (context, index) {
                      return const Padding(
                        padding: EdgeInsets.only(right: 16, left: 16),
                        child: Skeletonizer.zone(
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Bone.circle(size: 48),
                            title: Bone.text(words: 2),
                            subtitle: Bone.text(words: 1),
                            trailing: Bone.icon(),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
                )
              ],
            );
          }

          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  semanticsLabel: "API Failed Error Message",
                ),
              ); // Provide error details
            }

            if (!snapshot.hasData ||
                snapshot.data['data']['popular_taxis'].length == 0 ||
                snapshot.data['data']['taxis'] == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                        semanticLabel: "Location Icon",
                      ),
                      const SizedBox(height: 4),
                      Center(
                        child: Text(
                          AppLocalizations.of(context)!.translate("in_trnc"),
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                          semanticsLabel: "Question about are you in TRNC",
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          child: Text(
                            AppLocalizations.of(context)!
                                .translate("near_taxis_error"),
                            textAlign: TextAlign.center,
                            semanticsLabel: "Couldn't find taxis error message",
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () {
                          showModalBottomSheet(
                            showDragHandle: true,
                            enableDrag: true,
                            context: context,
                            builder: (context) {
                              return CitiesBottomSheet(
                                changePosition: changePosition,
                              );
                            },
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!
                              .translate("change_location"),
                          semanticsLabel: "Change Location",
                        ),
                      )
                    ],
                  )
                ],
              );
            }

            if (snapshot.hasData) {
              final data = snapshot.data as Map<String, dynamic>;
              final popular_taxis = data['data']['popular_taxis'];
              final taxis = data['data']['taxis'];

              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.rocket_launch,
                                    size: 18,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    semanticLabel: "Rocket Icon",
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.translate(
                                        'most_populars',
                                        params: {'city': "$_city"}),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    semanticsLabel: "Most Popular Taxis",
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    showDragHandle: true,
                                    enableDrag: true,
                                    context: context,
                                    builder: (context) {
                                      return CitiesBottomSheet(
                                        changePosition: changePosition,
                                      );
                                    },
                                  );
                                },
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .translate('change'),
                                  semanticsLabel: "Change Location Text Button",
                                ),
                              ),
                            ],
                          ),
                          CarouselSlider.builder(
                            itemCount: popular_taxis.length,
                            options: CarouselOptions(
                              height: MediaQuery.of(context).size.width > 360
                                  ? MediaQuery.of(context).size.height * .24
                                  : MediaQuery.of(context).size.height * .3,
                              autoPlay: true,
                              autoPlayInterval:
                                  const Duration(milliseconds: 3500),
                              enlargeCenterPage: true,
                              enableInfiniteScroll: false,
                              initialPage: 0,
                              viewportFraction: 1,
                            ),
                            itemBuilder: (context, index, realIndex) {
                              final taxi = popular_taxis[index];

                              return Card(
                                semanticContainer: true,
                                child: Stack(
                                  children: [
                                    ListTile(
                                      leading: GestureDetector(
                                        child: taxi['taxi_profile'] != null
                                            ? ClipOval(
                                                child: SizedBox(
                                                  width: 56,
                                                  height: 56,
                                                  child: Image.network(
                                                    fit: BoxFit.cover,
                                                    taxi['taxi_profile'],
                                                    semanticLabel:
                                                        "Profile Image",
                                                    loadingBuilder: (context,
                                                        child, progress) {
                                                      if (progress == null) {
                                                        return child;
                                                      } else {
                                                        return Skeletonizer
                                                            .zone(
                                                          child: Bone.square(
                                                            size: 56,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        16),
                                                          ),
                                                        );
                                                      }
                                                    },
                                                  ),
                                                ),
                                              )
                                            : const SizedBox(
                                                width: 56,
                                                height: 56,
                                                child: CircleAvatar(),
                                              ),
                                        onTap: () {
                                          _interstitialAds.showAd(
                                            onAdClosed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ProfileScreen(taxi: taxi),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                      title: Text(
                                        taxi['taxi_name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        semanticsLabel: "Taxi Name",
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          bookmarkProvider.isBookmarked(taxi)
                                              ? Icons.bookmark
                                              : Icons.bookmark_outline,
                                          semanticLabel: "Bookmark Icon",
                                        ),
                                        color: bookmarkProvider
                                                .isBookmarked(taxi)
                                            ? Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white
                                                : Colors.black
                                            : Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white54
                                                : Colors.black54,
                                        onPressed: () async {
                                          if (bookmarkProvider
                                              .isBookmarked(taxi)) {
                                            await bookmarkProvider
                                                .removeBookmark(taxi);

                                            Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!
                                                  .translate("taxi_removed"),
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              textColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                              backgroundColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.black
                                                  : Colors.white,
                                            );
                                          } else {
                                            await bookmarkProvider
                                                .setBookmark(taxi);

                                            Fluttertoast.showToast(
                                              msg: AppLocalizations.of(context)!
                                                  .translate("taxi_added"),
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.BOTTOM,
                                              timeInSecForIosWeb: 1,
                                              textColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white
                                                  : Colors.black,
                                              backgroundColor: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.black
                                                  : Colors.white,
                                            );
                                          }
                                        },
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 16,
                                                color: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white54
                                                    : Colors.black54,
                                                semanticLabel: "Location Icon",
                                              ),
                                              const SizedBox(width: 1),
                                              Flexible(
                                                child: Text(
                                                  "${taxi['taxi_address']}",
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white54
                                                        : Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                  semanticsLabel:
                                                      "Taxi Address",
                                                ),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              taxi['taxi_popularity'] != null
                                                  ? Row(
                                                      children: [
                                                        Text(
                                                          "${taxi['taxi_popularity']['rating']}",
                                                          style: TextStyle(
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                          semanticsLabel:
                                                              "Taxi Rating Score",
                                                        ),
                                                        const SizedBox(
                                                            width: 3),
                                                        RatingBar.builder(
                                                          updateOnDrag: false,
                                                          itemCount: 5,
                                                          itemSize: 16,
                                                          allowHalfRating: true,
                                                          ignoreGestures: true,
                                                          initialRating:
                                                              taxi['taxi_popularity']
                                                                      ['rating']
                                                                  .toDouble(),
                                                          itemBuilder:
                                                              (context, _) =>
                                                                  Icon(
                                                            Icons.star,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                            semanticLabel:
                                                                "Star Icon",
                                                          ),
                                                          unratedColor: Theme.of(
                                                                          context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white24
                                                              : Colors.black26,
                                                          onRatingUpdate:
                                                              (rating) {},
                                                        ),
                                                        const SizedBox(
                                                            width: 3),
                                                        Text(
                                                          "(${taxi['taxi_popularity']['voted']})",
                                                          style: TextStyle(
                                                            color: Theme.of(context)
                                                                        .brightness ==
                                                                    Brightness
                                                                        .dark
                                                                ? Colors.white24
                                                                : Colors
                                                                    .black26,
                                                          ),
                                                          semanticsLabel:
                                                              "Taxi Rating Voted",
                                                        ),
                                                      ],
                                                    )
                                                  : Text(
                                                      "Not yet rated.",
                                                      style: TextStyle(
                                                        color: Theme.of(context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white54
                                                            : Colors.black54,
                                                      ),
                                                      semanticsLabel:
                                                          "Not yet taxi rating",
                                                    ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      isThreeLine: true,
                                      onTap: () {
                                        showModalBottomSheet(
                                          showDragHandle: true,
                                          enableDrag: true,
                                          isScrollControlled: true,
                                          context: context,
                                          builder: (context) {
                                            return ProfileBottomSheet(
                                              taxi: taxi,
                                            );
                                          },
                                        );
                                      },
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                _interstitialAds.showAd(
                                                    onAdClosed: () {
                                                  makePhoneCall(context,
                                                      taxi['taxi_phone']);
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    Colors.blueAccent,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomLeft:
                                                        Radius.circular(16),
                                                  ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  const Icon(
                                                    Icons.phone,
                                                    size: 18,
                                                    semanticLabel: "Phone Icon",
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .translate('phone'),
                                                    semanticsLabel: "Phone",
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: TextButton(
                                              onPressed: () {
                                                _interstitialAds.showAd(
                                                    onAdClosed: () async {
                                                  await launchUrl(
                                                    Uri(
                                                      scheme: "https",
                                                      host: "api.whatsapp.com",
                                                      path: "send",
                                                      queryParameters: {
                                                        'phone':
                                                            taxi['taxi_phone']
                                                      },
                                                    ),
                                                  );
                                                });
                                              },
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.green,
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.only(
                                                    bottomRight:
                                                        Radius.circular(16),
                                                  ),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    MaterialCommunityIcons
                                                        .whatsapp,
                                                    size: 18,
                                                    semanticLabel:
                                                        "WhatsApp Icon",
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    "WhatsApp",
                                                    semanticsLabel: "WhatsApp",
                                                  )
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ],
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.only(top: 32, bottom: 32),
                      child: BannerAdWidget(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.my_location,
                                size: 18,
                                color: Theme.of(context).colorScheme.primary,
                                semanticLabel: "My Location Icon",
                              ),
                              const SizedBox(width: 6),
                              Text(
                                AppLocalizations.of(context)!
                                    .translate("others_around"),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                semanticsLabel: "Others Around You",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      childCount: taxis.length,
                      (context, index) {
                        final taxi = taxis[index];

                        return Column(
                          children: [
                            InkWell(
                              onTap: () {
                                showModalBottomSheet(
                                  showDragHandle: true,
                                  enableDrag: true,
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (context) {
                                    return ProfileBottomSheet(taxi: taxi);
                                  },
                                );
                              },
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: GestureDetector(
                                      child: taxi['taxi_profile'] != null
                                          ? ClipOval(
                                              child: SizedBox(
                                                width: 56,
                                                height: 56,
                                                child: Image.network(
                                                  fit: BoxFit.cover,
                                                  taxi['taxi_profile'],
                                                  semanticLabel:
                                                      "Profile Image",
                                                  loadingBuilder: (context,
                                                      child, progress) {
                                                    if (progress == null) {
                                                      return child;
                                                    } else {
                                                      return Skeletonizer.zone(
                                                        child: Bone.square(
                                                          size: 56,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            )
                                          : const SizedBox(
                                              width: 56,
                                              height: 56,
                                              child: CircleAvatar(),
                                            ),
                                      onTap: () {
                                        _interstitialAds.showAd(
                                          onAdClosed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfileScreen(taxi: taxi),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                    title: Text(
                                      taxi['taxi_name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      semanticsLabel: "Taxi Name",
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        bookmarkProvider.isBookmarked(taxi)
                                            ? Icons.bookmark
                                            : Icons.bookmark_outline,
                                        semanticLabel: "Bookmark Icon",
                                      ),
                                      color: bookmarkProvider.isBookmarked(taxi)
                                          ? Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white
                                              : Colors.black
                                          : Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white54
                                              : Colors.black54,
                                      onPressed: () async {
                                        if (bookmarkProvider
                                            .isBookmarked(taxi)) {
                                          await bookmarkProvider
                                              .removeBookmark(taxi);

                                          Fluttertoast.showToast(
                                            msg: AppLocalizations.of(context)!
                                                .translate("taxi_removed"),
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            timeInSecForIosWeb: 1,
                                            textColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                          );
                                        } else {
                                          await bookmarkProvider
                                              .setBookmark(taxi);

                                          Fluttertoast.showToast(
                                            msg: AppLocalizations.of(context)!
                                                .translate("taxi_added"),
                                            toastLength: Toast.LENGTH_SHORT,
                                            gravity: ToastGravity.BOTTOM,
                                            timeInSecForIosWeb: 1,
                                            textColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                            backgroundColor:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.black
                                                    : Colors.white,
                                          );
                                        }
                                      },
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                              semanticLabel: "Location Icon",
                                            ),
                                            const SizedBox(width: 2),
                                            Flexible(
                                              child: Text(
                                                "${taxi['taxi_address']}",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white54
                                                      : Colors.black54,
                                                  fontSize: 12,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                                semanticsLabel: "Taxi Address",
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            taxi['taxi_popularity'] != null
                                                ? Row(
                                                    children: [
                                                      Text(
                                                        "${taxi['taxi_popularity']['rating']}",
                                                        style: TextStyle(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                        semanticsLabel:
                                                            "Taxi Rating Score",
                                                      ),
                                                      const SizedBox(width: 3),
                                                      RatingBar.builder(
                                                        updateOnDrag: false,
                                                        itemCount: 5,
                                                        itemSize: 16,
                                                        allowHalfRating: true,
                                                        ignoreGestures: true,
                                                        initialRating:
                                                            taxi['taxi_popularity']
                                                                    ['rating']
                                                                .toDouble(),
                                                        itemBuilder:
                                                            (context, _) =>
                                                                Icon(
                                                          Icons.star,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                          semanticLabel:
                                                              "Start Icon",
                                                        ),
                                                        unratedColor: Theme.of(
                                                                        context)
                                                                    .brightness ==
                                                                Brightness.dark
                                                            ? Colors.white24
                                                            : Colors.black26,
                                                        onRatingUpdate:
                                                            (rating) {},
                                                      ),
                                                      const SizedBox(width: 3),
                                                      Text(
                                                        "(${taxi['taxi_popularity']['voted']})",
                                                        style: TextStyle(
                                                          color: Theme.of(context)
                                                                      .brightness ==
                                                                  Brightness
                                                                      .dark
                                                              ? Colors.white24
                                                              : Colors.black26,
                                                        ),
                                                        semanticsLabel:
                                                            "Taxi Rating Voted",
                                                      ),
                                                    ],
                                                  )
                                                : Text(
                                                    AppLocalizations.of(
                                                            context)!
                                                        .translate(
                                                            'not_yet_rated'),
                                                    style: TextStyle(
                                                      color: Theme.of(context)
                                                                  .brightness ==
                                                              Brightness.dark
                                                          ? Colors.white54
                                                          : Colors.black54,
                                                    ),
                                                    semanticsLabel:
                                                        "Not yet taxi rating",
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 16, right: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            _interstitialAds.showAd(
                                                onAdClosed: () {
                                              makePhoneCall(
                                                  context, taxi['taxi_phone']);
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blueAccent,
                                            elevation: 0,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                size: 18,
                                                semanticLabel: "Phone Icon",
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                AppLocalizations.of(context)!
                                                    .translate('phone'),
                                                semanticsLabel: "Phone",
                                              )
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _interstitialAds.showAd(
                                                onAdClosed: () async {
                                              await launchUrl(
                                                Uri(
                                                  scheme: "https",
                                                  host: "api.whatsapp.com",
                                                  path: "send",
                                                  queryParameters: {
                                                    'phone': taxi['taxi_phone']
                                                  },
                                                ),
                                              );
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            elevation: 0,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                MaterialCommunityIcons.whatsapp,
                                                size: 18,
                                                semanticLabel: "WhatsApp Icon",
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                "WhatsApp",
                                                semanticsLabel: "WhatsApp",
                                              )
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (index != taxis.length - 1)
                              const SizedBox(height: 24)
                          ],
                        );
                      },
                    ),
                  ),
                ],
              );
            }

            return const Center(
              child: Text(
                "Something went wrong.",
                semanticsLabel: "Error text: Something went wrong",
              ),
            );
          }

          return Center(
            child: SizedBox(
              width: 192,
              height: 192,
              child: Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? 'assets/icons/splash.light.png'
                    : 'assets/icons/splash.png',
                semanticLabel: "Splash Icon",
              ),
            ),
          );
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final dynamic position;

  const HomeScreen({required this.position, super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
