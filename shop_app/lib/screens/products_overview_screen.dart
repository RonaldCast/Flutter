import 'package:flutter/material.dart';
import 'package:shop_app/providers/products.dart';
import '../widgets/product_grid.dart';
import 'package:provider/provider.dart';
import '../providers/cart.dart';
import '../screens/cart_screen.dart';
import '../providers/products.dart';

import '../widgets/badge.dart';
import '../widgets/app_drawer.dart';

enum FilterOption { Favorites, All }

class ProductOverviewcSreen extends StatefulWidget {
  @override
  _ProductOverviewcSreenState createState() => _ProductOverviewcSreenState();
}

class _ProductOverviewcSreenState extends State<ProductOverviewcSreen> {
  bool _showOnlyFavotite = false;
  bool _isLoading = false;
  bool _isInit = true;
  @override
  void initState() {
    //  Provider.of<Products>(context, listen: false).fetchAndSetProduct(); work
    //  Provider.of<Products>(context).fetchAndSetProduct(); don't work
    // Future.delayed( Duration.zero).then((value){
    //    Provider.of<Products>(context).fetchAndSetProduct();
    // });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      setState(() {
        _isLoading = true;
      });

      Provider.of<Products>(context).fetchAndSetProduct().then((_) {
        setState(() {
          _isLoading = false;
        });
      });
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("MyShop"),
        actions: <Widget>[
          PopupMenuButton(
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
          Consumer<Cart>(
              builder: (ctx, cartData, ch) => Badge(
                    child: ch, //como esta construido afuera no se reconstruira
                    value: cartData.itemCount.toString(),
                  ),
              child: IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).pushNamed(CartScreen.routeName);
                },
              ))
        ],
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator(),) : ProductGrid(_showOnlyFavotite),
      drawer: AppDrawer(),
    );
  }
}
