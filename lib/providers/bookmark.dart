import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkProvider with ChangeNotifier {
  List<Map<String, dynamic>> _bookmarks = [];

  List<Map<String, dynamic>> get bookmarks => _bookmarks;

  BookmarkProvider() {
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? bookmarks = prefs.getStringList("bookmarks");

    if (bookmarks != null) {
      _bookmarks = bookmarks
          .map((bookmark) => jsonDecode(bookmark) as Map<String, dynamic>)
          .toList();
    }

    notifyListeners();
  }

  Future<void> setBookmark(value) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? bookmarks = prefs.getStringList("bookmarks") ?? [];

    bookmarks.add(jsonEncode(value));
    await prefs.setStringList("bookmarks", bookmarks);

    _bookmarks.add(value);

    notifyListeners();
  }

  Future<void> removeBookmark(Map<String, dynamic> value) async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? bookmarks = prefs.getStringList('bookmarks') ?? [];

    bookmarks.removeWhere((bookmark) =>
        jsonDecode(bookmark)['taxi_placeId'] == value['taxi_placeId']);

    await prefs.setStringList('bookmarks', bookmarks);

    _bookmarks.removeWhere(
        (bookmark) => bookmark['taxi_placeId'] == value['taxi_placeId']);

    notifyListeners();
  }

  Future<void> removeAllBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? bookmarks = prefs.getStringList("bookmarks") ?? [];

    bookmarks = [];
    await prefs.setStringList("bookmarks", bookmarks);
    _bookmarks = [];

    notifyListeners();
  }

  bool isBookmarked(Map<String, dynamic> value) {
    return _bookmarks
        .any((bookmark) => bookmark['taxi_placeId'] == value['taxi_placeId']);
  }
}
