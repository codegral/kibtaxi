import 'package:flutter/material.dart';

class CitiesBottomSheet extends StatelessWidget {
  final Function changePosition;
  const CitiesBottomSheet({required this.changePosition, super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height * 0.25,
      child: SingleChildScrollView(
        child: Column(
          children: [
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.2009463,
                  longitude: 33.334945,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("Lefkoşa (Nicosia)"),
            ),
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.095335,
                  longitude: 33.930475,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("Gazimağusa (Famagusta)"),
            ),
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.332305,
                  longitude: 33.319577,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("Girne (Kyrenia)"),
            ),
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.345549,
                  longitude: 33.161444,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("Lapta"),
            ),
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.198005,
                  longitude: 32.993815,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("Güzelyurt (Morphou)"),
            ),
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.113689,
                  longitude: 32.849653,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("Lefke"),
            ),
            TextButton(
              onPressed: () {
                changePosition(
                  latitude: 35.286091,
                  longitude: 33.892211,
                );
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
              ),
              child: const Text("İskele"),
            ),
            // TextButton(
            //   onPressed: () {
            //     changePosition(latitude: 35.6082335, longitude: 34.364829);
            //     Navigator.pop(context);
            //   },
            //   style: TextButton.styleFrom(
            //     foregroundColor: Theme.of(context).brightness == Brightness.dark
            //         ? Colors.white
            //         : Colors.black,
            //   ),
            //   child: const Text("Dipkarpaz"),
            // ),
          ],
        ),
      ),
    );
  }
}
