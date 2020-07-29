import 'package:flutter/foundation.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OrderItem {
  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;

  OrderItem({
    @required this.id,
    @required this.amount,
    @required this.products,
    @required this.dateTime,
  });
}

class Orders with ChangeNotifier {
  List<OrderItem> _orders = [];
  List<OrderItem> get orders {
    return _orders;
  }

  final String authToken;
  final String userId;

  Orders(this.authToken, this._orders, this.userId);

  Future<void> fetchAndSetOrders([bool filterByUser = false]) async {
     
    final url =
        'https://flutter-update-59d81.firebaseio.com/orders/$userId.json?auth=$authToken';
        
    final resp = await http.get(url);
    final List<OrderItem> loadedOrders = [];
    final extractedData = json.decode(resp.body) as Map<String, dynamic>;

    if (extractedData == null) {
      return;
    }
    extractedData.forEach((orderId, orderData) {
      loadedOrders.add(OrderItem(
          id: orderId,
          amount: orderData
          ['amount'],
          dateTime: DateTime.parse(orderData['dateTime']),
          products: (orderData['product'] as List<dynamic>)
              .map((item) => CartItem(
                  id: item['id'],
                  quatity: item['quantity'],
                  title: item['title'],
                  price: item['price']
                  ,))
              .toList()));
    });
    _orders = loadedOrders;
    notifyListeners();
  }

  Future<void> addOrder(List<CartItem> cartProduct, double total) async {
    const url = 'https://flutter-update-59d81.firebaseio.com/orders.json';
    final timestamp = DateTime.now();
    final resp = await http.post(url,
        body: json.encode({
          'amount': total,
          'dateTime': timestamp.toIso8601String(),
          'product': cartProduct
              .map((e) => {
                    "id": e.id,
                    "title": e.title,
                    "quantity": e.quatity,
                    "price": e.price
                  })
              .toList()
        }));
    _orders.insert(
        0,
        OrderItem(
            id: DateTime.now().toString(),
            amount: total,
            dateTime: timestamp,
            products: cartProduct));
    notifyListeners();
  }
}
