import 'package:flutter/material.dart';
import 'product.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/http_exception.dart';

//ChangeNotifier trabaja con provider esta utiliza VoidCallback para notificar
class Products with ChangeNotifier {
  // ignore: unused_field
  List<Product> _items = [];

  // var _showFavoritesOnly = false;
  List<Product> get items {
    return _items;
  }

  List<Product> get favoriteItems {
    return _items.where((item) => item.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((element) => element.id == id);
  }

  final String authToken;
  final String userId;
  Products(this.authToken, this._items, this.userId);

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);
    if (prodIndex >= 0) {
      final url =
          'https://flutter-update-59d81.firebaseio.com/products/$id.json?auth=$authToken';
      await http.patch(url,
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'imageUrl': newProduct.imageUrl,
            'price': newProduct.price
          }));
      _items[prodIndex] = newProduct;
      notifyListeners();
    } else {
      print("...");
    }

    notifyListeners();
  }

  Future<void> fetchAndSetProduct([bool filterByUser = false]) async {
    final filterString =
        filterByUser ? 'orderBy="creatorId"&equalTo="$userId"' : '';
    var url =
        'https://flutter-update-59d81.firebaseio.com/products.json?auth=$authToken&$filterString';
    try {
      final resp = await http.get(url);
      final extractedData = json.decode(resp.body) as Map<String, dynamic>;

      if (extractedData == null) {
        return;
      }
      url =
          'https://flutter-update-59d81.firebaseio.com/userFavorites/$userId.json?auth=$authToken';

      final favoriteResponse = await http.get(url);
      final favoriteData = json.decode(favoriteResponse.body);

      final List<Product> loadedProduct = [];
      extractedData.forEach((key, value) {
        loadedProduct.add(Product(
            id: key,
            title: value['title'],
            description: value['description'],
            price: value['price'],
            isFavorite:
                favoriteData == null ? false : favoriteData[key] ?? false,
            imageUrl: value['imageUrl']));
      });
      _items = loadedProduct;
      notifyListeners();
    } catch (e) {
      throw HttpException("Not load product");
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        'https://flutter-update-59d81.firebaseio.com/products.json?auth=$authToken';
    try {
      final resp = await http.post(url,
          body: json.encode({
            'title': product.title,
            'description': product.description,
            'imageUrl': product.imageUrl,
            'price': product.price,
            'creatorId': userId
          }));

      final newProduct = Product(
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl,
        id: json.decode(resp.body)['name'],
      );
      _items.add(newProduct);
      notifyListeners();
    } catch (e) {
      print("error");
      throw e;
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        'https://flutter-update-59d81.firebaseio.com/products/$id.json?auth=$authToken';
    final existingProductIndex = _items.indexWhere((prod) => prod.id == id);
    var existingProduct = _items[existingProductIndex];
    _items.removeAt(existingProductIndex);
    final resp = await http.delete(url);
    if (resp.statusCode >= 400) {
      _items.insert(existingProductIndex, existingProduct);
      notifyListeners();
      throw HttpException("Could not delete product");
    }
    existingProduct = null;

    _items.removeWhere((prop) => prop.id == id);
    notifyListeners();
  }
}
