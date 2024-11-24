import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  // DEVELOPMENT
  // final String adUnitId = Platform.isAndroid
  //     ? dotenv.env["ANDROID_CA_APP_PUB_BANNER_TEST"].toString()
  //     : dotenv.env["IOS_CA_APP_PUB_BANNER_TEST"].toString();

  // PRODUCTION
  final String adUnitId = dotenv.env['CA_APP_PUB_BANNER_PRODUCTION'].toString();

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoaded
        ? Container(
            alignment: Alignment.center,
            // width: _bannerAd!.size.width.toDouble(),
            width: MediaQuery.of(context).size.width,
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          )
        : const SizedBox.shrink();
  }
}

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class InterstitialAds {
  InterstitialAd? _interstitialAd;
  bool _isAdReady = false;
  Function? _onAdClosedCallback;

  static final InterstitialAds _instance = InterstitialAds._internal();
  factory InterstitialAds() => _instance;

  // DEVELOPMENT
  // final String adUnitId = Platform.isAndroid
  //     ? dotenv.env["ANDROID_CA_APP_PUB_INTERSTITIAL_TEST"].toString()
  //     : dotenv.env["IOS_CA_APP_PUB_INTERSTITIAL_TEST"].toString();

  // PRODUCTION
  final String adUnitId =
      dotenv.env['CA_APP_PUB_INTERSTITIAL_PRODUCTION'].toString();

  InterstitialAds._internal() {
    _loadAd();
  }

  void _loadAd() {
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isAdReady = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {},
            onAdImpression: (ad) {},
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _isAdReady = false;
            },
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _isAdReady = false;
              _onAdClosedCallback?.call();
              _scheduleAdLoad();
            },
            onAdClicked: (ad) {},
          );

          debugPrint('$ad loaded.');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
          _isAdReady = false;
          _scheduleAdLoad();
        },
      ),
    );
  }

  void _scheduleAdLoad() {
    Future.delayed(const Duration(milliseconds: 60000), () {
      _loadAd();
    });
  }

  void showAd({required Function onAdClosed}) {
    if (_interstitialAd != null && _isAdReady) {
      _onAdClosedCallback = onAdClosed;
      _interstitialAd!.show();
      _interstitialAd = null; // Reset the ad after showing it
    } else {
      debugPrint('InterstitialAd is not ready yet or already disposed.');
      onAdClosed();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}
