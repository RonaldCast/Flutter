import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String title;
  final int quatity;
  final double price;

  CartItem(
      {@required this.id,
      @required this.title,
      @required this.quatity,
      @required this.price});
}

class Cart with ChangeNotifier {
  Map<String, CartItem> _items;

  Map<String, CartItem> get items {
    return _items;
  }

  void addItem(String productId, double price, String title) {
    if (_items.containsKey(productId)) {
      _items.update(
          productId,
          (value) => CartItem(
              id: value.id,
              title: value.title,
              price: value.price,
              quatity: value.quatity + 1));
    } else {
      _items.putIfAbsent(
          productId,
          () => CartItem(
              id: DateTime.now().toString(),
              price: price,
              title: title,
              quatity: 1));
    }
  }
}
