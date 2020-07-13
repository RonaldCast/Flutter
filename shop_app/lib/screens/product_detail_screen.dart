import 'package:flutter/material.dart';
import '../providers/products.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatelessWidget {
  static const routeName = "product-detail";

  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context).settings.arguments as String;
    //listen: false para que no se resconstruya el widget
    final loadProduct =
        Provider.of<Products>(context, listen: false).findById(productId);

    return Scaffold(
      appBar: AppBar(title: Text(loadProduct.title)),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 300,
              child: Image.network(loadProduct.imageUrl, fit: BoxFit.cover),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              '\$${loadProduct.price}',
              style: TextStyle(color: Colors.grey, fontSize: 20),
            ),
              SizedBox(
              height: 10,
            ),
            Text(loadProduct.description,  textAlign: TextAlign.center,)
          ],
        ),
      ),
    );
  }
}
