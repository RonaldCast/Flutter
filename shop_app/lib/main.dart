import 'package:flutter/material.dart';
import 'package:shop_app/screens/product_detail_screen.dart';
import './screens/products_overview_screen.dart';
import './providers/products.dart';
import 'package:provider/provider.dart';
import './providers/cart.dart';
import './screens/cart_screen.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    //ChangeNotifierProvider ayuda a que el widget y sus
    // hijo que esten escuchen el cambio del state de products (provider)
    // solo lo widget que esten escuchando de modificaran.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => Products()),
        ChangeNotifierProvider(create: (ctx) => Cart())
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Myshop',
        theme: ThemeData(
            primarySwatch: Colors.purple, accentColor: Colors.deepOrange),
        home: ProductOverviewcSreen(),
        routes: {ProductDetailScreen.routeName: (ctx) => ProductDetailScreen(),
        CartScreen.routeName: (ctx) => CartScreen()},
      ),
    );
  }
}
