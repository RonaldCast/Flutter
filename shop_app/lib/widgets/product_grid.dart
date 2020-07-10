import 'package:flutter/material.dart';
import '../providers/product.dart';
import '../widgets/product_Item.dart';

import "package:provider/provider.dart";
import '../providers/products.dart';

class ProductGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //connection con provider
    final productData = Provider.of<Products>(context);
    final products = productData.items;
    var scaffold = Scaffold(
      appBar: AppBar(title: Text("MyShop")),
      body: GridView.builder(
        padding: const EdgeInsets.all(10.0),
        itemCount: products.length,
        itemBuilder: (ctx, i) => ChangeNotifierProvider.value(
          //create: (c) => products[i],
          value: products[i],
          child: ProductItem(),
          // child: ProductItem(
          //     products[i].id, products[i].title, products[i].imageUrl),
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 3 / 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
      ),
    );
    return scaffold;
  }
}
