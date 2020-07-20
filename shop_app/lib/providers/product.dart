import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import "../models/http_exception.dart";

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  bool isFavorite;

  Product(
      {@required this.id,
      @required this.title,
      @required this.description,
      @required this.price,
      @required this.imageUrl,
      this.isFavorite = false});

  Future<void> toggleFavoriteStatus() async {
    final url =
        'https://flutter-update-59d81.firebaseio.com/products/${this.id}.json';
    final oldFavorite = isFavorite;
    isFavorite = !isFavorite;

    try {
      final resp =
          await http.patch(url, body: json.encode({'isFavorite': isFavorite}));
      if (resp.statusCode >= 400) {
        isFavorite = oldFavorite;
        notifyListeners();
        throw HttpException("Error update");
      }
      notifyListeners();
    } catch (e) {
      isFavorite = oldFavorite;

      notifyListeners();
      throw HttpException("Error update");
    }
  }
}
