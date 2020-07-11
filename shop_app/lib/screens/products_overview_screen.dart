import 'package:flutter/material.dart';
import 'package:shop_app/providers/products.dart';
import '../widgets/product_grid.dart';
import 'package:provider/provider.dart';

enum FilterOption { Favorites, All }

class ProductOverviewcSreen extends StatefulWidget {
  @override
  _ProductOverviewcSreenState createState() => _ProductOverviewcSreenState();
}

class _ProductOverviewcSreenState extends State<ProductOverviewcSreen> {
  bool _showOnlyFavotite = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MyShop"),
        actions: <Widget>[
          Consumer<Products>(
            builder: (cxt, products, _) => PopupMenuButton(
              icon: Icon(Icons.more_vert),
              onSelected: (FilterOption selectIndex) {
                setState(() {
                  if (selectIndex == FilterOption.Favorites) {
                    _showOnlyFavotite = true;
                  } else {
                    _showOnlyFavotite = false;
                  }
                });
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                    child: Text("Ony favorite"), value: FilterOption.Favorites),
                PopupMenuItem(child: Text("Show All"), value: FilterOption.All)
              ],
            ),
          )
        ],
      ),
      body: ProductGrid(_showOnlyFavotite),
    );
  }
}
