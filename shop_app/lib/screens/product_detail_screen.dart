import 'package:flutter/material.dart';
import '../providers/products.dart';
import 'package:provider/provider.dart';

class ProductDetailScreen extends StatelessWidget {
  static const routeName = "product-detail";

  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context).settings.arguments as String;
    final loadProduct =
        Provider.of<Products>(context, listen: false).findById(productId);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
             SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(loadProduct.title),
              background: Hero(
                tag: loadProduct.id,
                child: Image.network(
                  loadProduct.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
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
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              width: double.infinity,
              child: Text(
                loadProduct.description,
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            ),
            SizedBox(
              height: 800,
            ),
          ])),
        ]),
      ),
      // ])
    );
  }
}
