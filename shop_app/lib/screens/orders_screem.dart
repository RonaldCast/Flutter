import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/orders.dart' show  Orders;
import '../widgets/order_item.dart' ;
import '../widgets/app_drawer.dart';

class OrdersScreen extends StatelessWidget{
static const routeName = "/order";
  
  @override
  Widget build(BuildContext context) {
   final orderData = Provider.of<Orders>(context);
    return Scaffold(

      drawer: AppDrawer(),
      appBar: AppBar(
        title: Text('Your Ordes'),
      ),
      body: ListView.builder(itemCount: orderData.orders.length,
       itemBuilder: (ctx, i)=> OrderItem(orderData.orders[i]) ),
 
    );
  }
}