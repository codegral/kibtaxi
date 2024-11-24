import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/screens/profile.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:kibtaxi/widgets/bars/appbar.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';

class _BookmarkScreenState extends State<BookmarkScreen> {
  final InterstitialAds _interstitialAds = InterstitialAds();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final taxis = bookmarkProvider.bookmarks;

    return Scaffold(
      appBar: MyAppBar(
        leading: Icon(
          Icons.bookmark,
          color: Theme.of(context).colorScheme.primary,
          semanticLabel: "Bookmark Icon",
        ),
        title: Text(
          AppLocalizations.of(context)!.translate("my_taxis"),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          semanticsLabel: "My Saved Taxis",
        ),
        actions: taxis.isNotEmpty
            ? [
                IconButton(
                    onPressed: () {
                      showModalBottomSheet(
                        showDragHandle: true,
                        context: context,
                        builder: (context) {
                          return SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.height * .1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);

                                    showDialog(
                                      context: context,
                                      builder: (context) {
                                        return AlertDialog(
                                          insetPadding:
                                              const EdgeInsets.all(16),
                                          title: Row(
                                            children: [
                                              const Icon(
                                                Icons.bookmark,
                                                size: 14,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(AppLocalizations.of(context)!
                                                  .translate("remove_all"))
                                            ],
                                          ),
                                          titleTextStyle: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          content: Text(
                                            AppLocalizations.of(context)!
                                                .translate(
                                                    "want_to_remove_all"),
                                            semanticsLabel:
                                                "Remove All Question",
                                          ),
                                          contentTextStyle: TextStyle(
                                            fontSize: 14,
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.dark
                                                    ? Colors.white
                                                    : Colors.black,
                                          ),
                                          semanticLabel:
                                              "Remove Taxis Saved Dialog",
                                          actions: [
                                            TextButton(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                                await bookmarkProvider
                                                    .removeAllBookmarks();
                                              },
                                              child: Text(
                                                AppLocalizations.of(context)!
                                                    .translate("yes"),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red,
                                                ),
                                                semanticsLabel: "Yes",
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .translate("remove_all"),
                                    style: const TextStyle(color: Colors.red),
                                    semanticsLabel: "Remove All",
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.menu,
                      semanticLabel: "Menu Icon",
                    ))
              ]
            : null,
      ),
      body: taxis.isNotEmpty
          ? ListView.builder(
              itemCount: taxis.length,
              itemBuilder: (context, index) {
                final taxi = taxis[index];

                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(taxi: taxi),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          ListTile(
                            leading: taxi['taxi_profile'] != null
                                ? ClipOval(
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: Image.network(
                                        fit: BoxFit.cover,
                                        taxi['taxi_profile'],
                                        semanticLabel: "Profile Image",
                                        loadingBuilder:
                                            (context, child, progress) {
                                          if (progress == null) {
                                            return child;
                                          } else {
                                            return Skeletonizer.zone(
                                              child: Bone.square(
                                                size: 56,
                                                borderRadius:
                                                    BorderRadius.circular(16),
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
                                if (bookmarkProvider.isBookmarked(taxi)) {
                                  await bookmarkProvider.removeBookmark(taxi);

                                  Fluttertoast.showToast(
                                    msg: AppLocalizations.of(context)!
                                        .translate("taxi_removed"),
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    textColor: Theme.of(context).brightness ==
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
                                  await bookmarkProvider.setBookmark(taxi);

                                  Fluttertoast.showToast(
                                    msg: AppLocalizations.of(context)!
                                        .translate("taxi_added"),
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    timeInSecForIosWeb: 1,
                                    textColor: Theme.of(context).brightness ==
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: Theme.of(context).brightness ==
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
                                          color: Theme.of(context).brightness ==
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
                                                  color: Theme.of(context)
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
                                                itemBuilder: (context, _) =>
                                                    Icon(
                                                  Icons.star,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  semanticLabel: "Star Icon",
                                                ),
                                                unratedColor: Theme.of(context)
                                                            .brightness ==
                                                        Brightness.dark
                                                    ? Colors.white24
                                                    : Colors.black26,
                                                onRatingUpdate: (rating) {},
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                "(${taxi['taxi_popularity']['voted']})",
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? Colors.white24
                                                      : Colors.black26,
                                                ),
                                                semanticsLabel:
                                                    "Taxi Rating Voted",
                                              ),
                                            ],
                                          )
                                        : Text(
                                            AppLocalizations.of(context)!
                                                .translate('not_yet_rated'),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? Colors.white54
                                                  : Colors.black54,
                                            ),
                                            semanticsLabel:
                                                "Not yet rated taxi score",
                                          ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    _interstitialAds.showAd(onAdClosed: () {
                                      makePhoneCall(
                                          context, taxi['taxi_phone']);
                                    });
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blueAccent,
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                    if (index < 1)
                      const Padding(
                        padding: EdgeInsets.only(top: 16, bottom: 16),
                        child: BannerAdWidget(),
                      ),
                    if (index != taxis.length - 1) const SizedBox(height: 24)
                  ],
                );
              },
            )
          : Stack(
              children: [
                Center(
                  child: Text(
                    AppLocalizations.of(context)!.translate("nothing_to_show"),
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                    semanticsLabel: "Nothing to show",
                  ),
                ),
                const Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: BannerAdWidget(),
                )
              ],
            ),
    );
  }
}

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}
