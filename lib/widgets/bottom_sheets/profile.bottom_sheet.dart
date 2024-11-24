import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/screens/profile.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class ProfileBottomSheet extends StatelessWidget {
  final Map<String, dynamic> taxi;
  const ProfileBottomSheet({required this.taxi, super.key});

  @override
  Widget build(BuildContext context) {
    final String currentLanguage = Localizations.localeOf(context).languageCode;

    final InterstitialAds interstitialAds = InterstitialAds();
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);

    List<dynamic>? taxi_photos = [];
    List<dynamic>? taxi_reviews = [];

    if (taxi['taxi_photos'] != null) {
      if (taxi['taxi_photos'].length >= 3) {
        taxi_photos.addAll(taxi['taxi_photos']?.sublist(0, 3));
      } else if (taxi['taxi_photos'].length >= 1) {
        taxi_photos.addAll(
          taxi['taxi_photos']?.sublist(0, taxi['taxi_photos'].length),
        );
      } else {
        taxi_photos = null;
      }
    }

    if (taxi['taxi_reviews'] != null) {
      if (taxi['taxi_reviews'].length >= 5) {
        taxi_reviews.addAll(taxi['taxi_reviews']?.sublist(0, 5));
      } else if (taxi['taxi_reviews']?.length >= 1) {
        taxi_reviews.addAll(
            taxi['taxi_reviews']?.sublist(0, taxi['taxi_reviews'].length));
      } else {
        taxi_reviews = null;
      }
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * .75,
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
                        semanticLabel: "Kibtaxi Profile Image",
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          } else {
                            return Skeletonizer.zone(
                              child: Bone.square(
                                size: 56,
                                borderRadius: BorderRadius.circular(16),
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
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(bookmarkProvider.isBookmarked(taxi)
                  ? Icons.bookmark
                  : Icons.bookmark_outline),
              color: bookmarkProvider.isBookmarked(taxi)
                  ? Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black
                  : Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54
                      : Colors.black54,
              onPressed: () async {
                if (bookmarkProvider.isBookmarked(taxi)) {
                  await bookmarkProvider.removeBookmark(taxi);

                  Fluttertoast.showToast(
                    msg:
                        AppLocalizations.of(context)!.translate("taxi_removed"),
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    textColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                  );
                } else {
                  await bookmarkProvider.setBookmark(taxi);

                  Fluttertoast.showToast(
                    msg: AppLocalizations.of(context)!.translate("taxi_added"),
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.BOTTOM,
                    timeInSecForIosWeb: 1,
                    textColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                            ? Colors.black
                            : Colors.white,
                  );
                }
              },
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white54
                          : Colors.black54,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        "${taxi['taxi_address']}",
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black54,
                          fontSize: 12,
                          overflow: TextOverflow.ellipsis,
                        ),
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (taxi['taxi_popularity'] != null)
                  Row(children: [
                    Text(
                      "${taxi['taxi_popularity']['rating']}",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 3),
                    RatingBar.builder(
                      updateOnDrag: false,
                      itemCount: 5,
                      itemSize: 16,
                      allowHalfRating: true,
                      ignoreGestures: true,
                      initialRating:
                          taxi['taxi_popularity']['rating'].toDouble(),
                      itemBuilder: (context, _) => Icon(
                        Icons.star,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      unratedColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? Colors.white24
                              : Colors.black26,
                      onRatingUpdate: (rating) {},
                    ),
                    const SizedBox(width: 3),
                    Text(
                      "(${taxi['taxi_popularity']['voted']})",
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black26,
                      ),
                    ),
                  ])
              ],
            ),
            isThreeLine: true,
            onTap: () {
              interstitialAds.showAd(onAdClosed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(taxi: taxi),
                  ),
                );
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () {
                    interstitialAds.showAd(onAdClosed: () {
                      makePhoneCall(context, taxi['taxi_phone']);
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
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.translate('phone'),
                      )
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    interstitialAds.showAd(onAdClosed: () async {
                      await launchUrl(
                        Uri(
                          scheme: "https",
                          host: "api.whatsapp.com",
                          path: "send",
                          queryParameters: {'phone': taxi['taxi_phone']},
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
                      ),
                      SizedBox(width: 4),
                      Text("WhatsApp")
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 3),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (taxi_photos != null && taxi_photos.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        height: 150,
                        child: GridView.count(
                          scrollDirection: Axis.horizontal,
                          crossAxisCount: 1,
                          mainAxisSpacing: 12,
                          children: taxi_photos.map<Widget>((item) {
                            return GestureDetector(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) {
                                      return child;
                                    } else {
                                      return Skeletonizer.zone(
                                        child: Bone.square(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                              onTap: () {
                                interstitialAds.showAd(onAdClosed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(
                                        taxi: taxi,
                                      ),
                                    ),
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  if (taxi_reviews != null && taxi_reviews.isNotEmpty)
                    ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: taxi_reviews.length,
                      itemBuilder: (context, index) {
                        final taxi_review = taxi_reviews![index];

                        return InkWell(
                          onTap: () {
                            interstitialAds.showAd(
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
                          child: ListTile(
                            leading: taxi_review['reviewer_photo'] != null
                                ? ClipOval(
                                    child: SizedBox(
                                      width: 42,
                                      height: 42,
                                      child: Image.network(
                                        fit: BoxFit.cover,
                                        taxi_review['reviewer_photo'],
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
                                    width: 42,
                                    height: 42,
                                    child: CircleAvatar(),
                                  ),
                            title: Text(
                              "${taxi_review['reviewer_name']}",
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            trailing: Text(
                              timeago.format(
                                  DateTime.parse(
                                      taxi_review['reviewer_publishDate']),
                                  locale: currentLanguage),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${taxi_review['reviewer_rating']}",
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    const SizedBox(width: 3),
                                    RatingBar.builder(
                                      updateOnDrag: false,
                                      itemCount: 5,
                                      itemSize: 16,
                                      allowHalfRating: true,
                                      ignoreGestures: true,
                                      initialRating:
                                          taxi_review['reviewer_rating']
                                              .toDouble(),
                                      itemBuilder: (context, _) => Icon(
                                        Icons.star,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                      unratedColor:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white24
                                              : Colors.black26,
                                      onRatingUpdate: (rating) {},
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (taxi_review['reviewer_review']?['text'] !=
                                    null)
                                  Text(
                                      "${taxi_review['reviewer_review']['text']}"),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      interstitialAds.showAd(onAdClosed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              taxi: taxi,
                            ),
                          ),
                        );
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all(Colors.blueAccent),
                      foregroundColor: MaterialStateProperty.all(Colors.white),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.only(
                          top: 12,
                          bottom: 12,
                        ),
                      ),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!
                          .translate("view_full_profile"),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await launchUrl(Uri.parse(taxi['taxi_googleMaps']));
                  },
                  icon: Image.asset(
                    'assets/icons/brands/google_maps.png',
                    width: 26,
                    height: 26,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
