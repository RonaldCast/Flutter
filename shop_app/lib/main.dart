import 'package:flutter/material.dart';
import 'package:shop_app/screens/product_detail_screen.dart';
import './screens/products_overview_screen.dart';
import './providers/products.dart';
import 'package:provider/provider.dart';
import './providers/cart.dart';
import './screens/cart_screen.dart';
import './providers/orders.dart';
import './screens/orders_screem.dart';
import './screens/user_product_screen.dart';
import './screens/edit_product_screen.dart';
import './screens/auth_screen.dart';
import "./providers/auth.dart";
import './screens/splash_screen.dart';
import './helpers/custom_route.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    //ChangeNotifierProvider ayuda a que el widget y sus
    // hijo que esten escuchen el cambio del state de products (provider)
    // solo lo widget que esten escuchando de modificaran.
    return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: Auth()),
          ChangeNotifierProxyProvider<Auth, Products>(
              update: (ctx, auth, previoudProduct) => Products(
                  auth.token,
                  previoudProduct == null ? [] : previoudProduct.items,
                  auth.userId)),
          ChangeNotifierProvider(create: (ctx) => Cart()),
          ChangeNotifierProxyProvider<Auth, Orders>(
              update: (ctx, auth, preOrders) => Orders(auth.token,
                  preOrders == null ? [] : preOrders.orders, auth.userId)),
        ],
        child: Consumer<Auth>(
          builder: (ctx, auth, _) => MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Myshop',
            theme: ThemeData(
                primarySwatch: Colors.purple, 
                accentColor: Colors.deepOrange,
                fontFamily: 'Lato',
                
                pageTransitionsTheme:  PageTransitionsTheme(builders:  {
                  TargetPlatform.android: CustomePageTransitionBuilder(),
                  TargetPlatform.iOS: CustomePageTransitionBuilder()
                })),
            home: auth.isAuth
                ? ProductOverviewScreen()
                : FutureBuilder(
                    future: auth.tryAutoLogin(),
                    builder: (ctx, snap) {
                      //snap.connectionState == ConnectionState.waiting
                            // ? SplashScreen()
                            // : 
                      print( snap.connectionState);
                        return AuthScreen();}),
            routes: {
              ProductDetailScreen.routeName: (ctx) => ProductDetailScreen(),
              CartScreen.routeName: (ctx) => CartScreen(),
              OrdersScreen.routeName: (ctx) => OrdersScreen(),
              UserProductScreen.routeName: (ctx) => UserProductScreen(),
              EditProductScreen.routeName: (ctx) => EditProductScreen()
            },
          ),
        ));
  }
}
