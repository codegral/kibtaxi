import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:kibtaxi/providers/bookmark.dart';
import 'package:kibtaxi/services/ad_service.dart';
import 'package:kibtaxi/utils/helpers.dart';
import 'package:kibtaxi/widgets/bars/appbar.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import "package:timeago/timeago.dart" as timeago;

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF030a0e)
          : Colors.white,
      child: _tabBar,
    );
  }

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return false;
  }
}

class _ProfileScreenState extends State<ProfileScreen> {
  final InterstitialAds _interstitialAds = InterstitialAds();

  @override
  Widget build(BuildContext context) {
    final bookmarkProvider = Provider.of<BookmarkProvider>(context);
    final String currentLanguage = Localizations.localeOf(context).languageCode;

    List<dynamic>? taxi_reviews = [];

    if (widget.taxi['taxi_reviews'] != null) {
      if (widget.taxi['taxi_reviews'].length >= 5) {
        taxi_reviews.addAll(widget.taxi['taxi_reviews']?.sublist(0, 5));
      } else if (widget.taxi['taxi_reviews']?.length >= 1) {
        taxi_reviews.addAll(widget.taxi['taxi_reviews']
            ?.sublist(0, widget.taxi['taxi_reviews'].length));
      } else {
        taxi_reviews = null;
      }
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: MyAppBar(
          title: Text(
            widget.taxi['taxi_name'],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            semanticsLabel: "Taxi Name",
          ),
        ),
        body: CustomScrollView(
          physics: const NeverScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  ListTile(
                    leading: widget.taxi['taxi_profile'] != null
                        ? ClipOval(
                            child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Image.network(
                                fit: BoxFit.cover,
                                widget.taxi['taxi_profile'],
                                semanticLabel: "Profile Image",
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
                      widget.taxi['taxi_name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      semanticsLabel: "Taxi Name",
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        bookmarkProvider.isBookmarked(widget.taxi)
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        semanticLabel: "Bookmark Icon",
                      ),
                      color: bookmarkProvider.isBookmarked(widget.taxi)
                          ? Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black
                          : Theme.of(context).brightness == Brightness.dark
                              ? Colors.white54
                              : Colors.black54,
                      onPressed: () async {
                        if (bookmarkProvider.isBookmarked(widget.taxi)) {
                          await bookmarkProvider.removeBookmark(widget.taxi);

                          Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)!
                                .translate("taxi_removed"),
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            textColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                            backgroundColor:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                          );
                        } else {
                          await bookmarkProvider.setBookmark(widget.taxi);

                          Fluttertoast.showToast(
                            msg: AppLocalizations.of(context)!
                                .translate("taxi_added"),
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            timeInSecForIosWeb: 1,
                            textColor:
                                Theme.of(context).brightness == Brightness.dark
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
                            const SizedBox(width: 1),
                            Flexible(
                              child: Text(
                                "${widget.taxi['taxi_address']}",
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
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            widget.taxi['taxi_popularity'] != null
                                ? Row(
                                    children: [
                                      Text(
                                        "${widget.taxi['taxi_popularity']['rating']}",
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                        semanticsLabel: "Taxi Rating Score",
                                      ),
                                      const SizedBox(width: 3),
                                      RatingBar.builder(
                                        updateOnDrag: false,
                                        itemCount: 5,
                                        itemSize: 16,
                                        allowHalfRating: true,
                                        ignoreGestures: true,
                                        initialRating: widget
                                            .taxi['taxi_popularity']['rating']
                                            .toDouble(),
                                        itemBuilder: (context, _) => Icon(
                                          Icons.star,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          semanticLabel: "Star Icon",
                                        ),
                                        unratedColor:
                                            Theme.of(context).brightness ==
                                                    Brightness.dark
                                                ? Colors.white24
                                                : Colors.black26,
                                        onRatingUpdate: (rating) {},
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        "(${widget.taxi['taxi_popularity']['voted']})",
                                        style: TextStyle(
                                          color: Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Colors.white24
                                              : Colors.black26,
                                        ),
                                        semanticsLabel: "Taxi Rating Voted",
                                      ),
                                    ],
                                  )
                                : Text(
                                    AppLocalizations.of(context)!
                                        .translate('not_yet_rated'),
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    semanticsLabel: "Not yet taxi rating score",
                                  ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, left: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _interstitialAds.showAd(onAdClosed: () {
                              makePhoneCall(context, widget.taxi['taxi_phone']);
                            });
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
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
                            _interstitialAds.showAd(onAdClosed: () async {
                              await launchUrl(
                                Uri(
                                  scheme: "https",
                                  host: "api.whatsapp.com",
                                  path: "send",
                                  queryParameters: {
                                    'phone': widget.taxi['taxi_phone']
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
                  )
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                const TabBar(
                  tabs: [
                    Tab(
                        icon: Icon(
                      Icons.photo,
                      semanticLabel: "Taxi Photos",
                    )),
                    Tab(
                        icon: Icon(
                      Icons.comment,
                      semanticLabel: "Taxi Comments",
                    )),
                  ],
                ),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                children: [
                  CustomScrollView(
                    shrinkWrap: true,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(
                            top: 24, bottom: 24, left: 16, right: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            childCount: widget.taxi['taxi_photos']?.length ?? 0,
                            (context, index) {
                              return SizedBox(
                                child: GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 6,
                                              sigmaY: 6,
                                            ),
                                            child: Hero(
                                              transitionOnUserGestures: true,
                                              tag: 'imageHero$index',
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  widget.taxi['taxi_photos']
                                                      [index],
                                                  fit: BoxFit.contain,
                                                  semanticLabel: "Taxi Photos",
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      widget.taxi['taxi_photos'][index],
                                      fit: BoxFit.cover,
                                      semanticLabel: "Taxi Photos",
                                      loadingBuilder:
                                          (context, child, progress) {
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
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    ],
                  ),
                  CustomScrollView(
                    shrinkWrap: true,
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.only(top: 24, bottom: 24),
                        sliver: taxi_reviews != null
                            ? SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  childCount: taxi_reviews.length,
                                  (context, index) {
                                    final taxi_review = taxi_reviews![index];

                                    return Column(
                                      children: [
                                        ListTile(
                                          leading: taxi_review[
                                                      'reviewer_photo'] !=
                                                  null
                                              ? ClipOval(
                                                  child: SizedBox(
                                                    width: 42,
                                                    height: 42,
                                                    child: Image.network(
                                                      fit: BoxFit.cover,
                                                      taxi_review[
                                                          'reviewer_photo'],
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
                                                  width: 42,
                                                  height: 42,
                                                  child: CircleAvatar(),
                                                ),
                                          title: Text(
                                            "${taxi_review['reviewer_name']}",
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                            semanticsLabel: "Reviewer Name",
                                          ),
                                          trailing: Text(
                                            timeago.format(
                                                DateTime.parse(taxi_review[
                                                    'reviewer_publishDate']),
                                                locale: currentLanguage),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
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
                                                    semanticsLabel:
                                                        "Reviewer Rating",
                                                  ),
                                                  const SizedBox(width: 3),
                                                  RatingBar.builder(
                                                    updateOnDrag: false,
                                                    itemCount: 5,
                                                    itemSize: 16,
                                                    allowHalfRating: true,
                                                    ignoreGestures: true,
                                                    initialRating: taxi_review[
                                                            'reviewer_rating']
                                                        .toDouble(),
                                                    itemBuilder: (context, _) =>
                                                        Icon(
                                                      Icons.star,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                      semanticLabel:
                                                          "Star Icon",
                                                    ),
                                                    unratedColor: Theme.of(
                                                                    context)
                                                                .brightness ==
                                                            Brightness.dark
                                                        ? Colors.white24
                                                        : Colors.black26,
                                                    onRatingUpdate: (rating) {},
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (taxi_review['reviewer_review']
                                                      ?['text'] !=
                                                  null)
                                                Text(
                                                  "${taxi_review['reviewer_review']['text']}",
                                                  semanticsLabel:
                                                      "Reviewer's Comment/Review",
                                                ),
                                            ],
                                          ),
                                          isThreeLine: true,
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Text(
                                    AppLocalizations.of(context)!
                                        .translate("not_yet_rated"),
                                    style: TextStyle(
                                      color: Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                    semanticsLabel: "Not yet taxi rating score",
                                  ),
                                ),
                              ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            await launchUrl(Uri.parse(widget.taxi['taxi_googleMaps']));
          },
          enableFeedback: true,
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF081017)
              : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(360),
          ),
          child: Image.asset(
            'assets/icons/brands/google_maps.png',
            width: 24,
            height: 24,
            semanticLabel: "Google Maps Icon",
          ),
        ),
        bottomNavigationBar: const BannerAdWidget(),
      ),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> taxi;
  const ProfileScreen({required this.taxi, super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
