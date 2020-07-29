import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/products.dart';
import '../widgets/user_product_item.dart';
import '../widgets/app_drawer.dart';
import '../screens/edit_product_screen.dart';

import 'package:provider/provider.dart';

class UserProductScreen extends StatelessWidget {
  static const routeName = '/user-product';

  Future<void> _refreshProducts(BuildContext context) async {
    try {
      await Provider.of<Products>(context,listen: false).fetchAndSetProduct(true);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    // final productsData = Provider.of<Products>(context);
    return Scaffold(
        drawer: AppDrawer(),
        appBar: AppBar(
          title: const Text("Your Products"),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                Navigator.of(context).pushNamed(EditProductScreen.routeName);
              },
            )
          ],
        ),
        body: FutureBuilder(
          future: _refreshProducts(context),
          builder: (ctx, snap) =>
              snap.connectionState == ConnectionState.waiting
                  ? Center(
                      child: CircularProgressIndicator(),
                    )
                  : RefreshIndicator(
                      onRefresh: () => _refreshProducts(context),
                      child: Consumer<Products>(
                        builder: (ctx, productsData, _) => Padding(
                          padding: EdgeInsets.all(8),
                          child: ListView.builder(
                            itemCount: productsData.items.length,
                            itemBuilder: (_, i) => Column(
                              children: <Widget>[
                                UserProductItem(
                                    productsData.items[i].id,
                                    productsData.items[i].title,
                                    productsData.items[i].imageUrl),
                                Divider()
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
        ));
  }
}
