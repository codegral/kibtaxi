import 'package:flutter/material.dart';
import 'package:kibtaxi/app_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> makePhoneCall(BuildContext context, String phoneNumber) async {
  final status = await Permission.phone.status;

  if (status.isGranted) {
    await launchUrl(
      Uri(
        scheme: "tel",
        path: phoneNumber,
      ),
    );
  } else if (status.isDenied) {
    if (await Permission.phone.request().isGranted) {
      await launchUrl(Uri(scheme: 'tel', path: phoneNumber));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.translate("phone_denied"),
          ),
        ),
      );
    }
  } else if (status.isPermanentlyDenied) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!
            .translate("phone_permanently_denied")),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () {
            openAppSettings();
          },
        ),
      ),
    );
  }
}
