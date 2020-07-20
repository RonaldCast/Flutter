import 'package:flutter/material.dart';
import 'package:shop_app/providers/cart.dart';
import 'package:shop_app/providers/product.dart';
import '../screens/product_detail_screen.dart';
import 'package:provider/provider.dart';

class ProductItem extends StatelessWidget {

  
  @override
  Widget build(BuildContext context) {
    final product = Provider.of<Product>(context, listen: false);
    final cart = Provider.of<Cart>(context, listen:false);
    print("build");
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: GridTile(
        child: GestureDetector(
          onTap: () {
            Navigator.of(context).pushNamed(ProductDetailScreen.routeName,
                arguments: product.id);
          },
          child: Image.network(
            product.imageUrl,
            fit: BoxFit.cover,
          ),
        ),
        footer: GridTileBar(
          backgroundColor: Colors.black87,
          leading: Consumer<Product>(
            builder: (cxt, product, _) => IconButton(
              color: Theme.of(context).accentColor,
              icon: Icon(
                  product.isFavorite ? Icons.favorite : Icons.favorite_border),
              onPressed: () async {
                try {
                  await product.toggleFavoriteStatus();
                } catch (e) {
                  Scaffold.of(context).showSnackBar(SnackBar(content: Text("Favotite faile"),));
                }
               
              },
            ),
          ),
          title: Text(product.title, textAlign: TextAlign.center),
          trailing: IconButton(
            color: Theme.of(context).accentColor,
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Scaffold.of(context).hideCurrentSnackBar();
              cart.addItem(product.id, product.price,product.title);
              //nos ayuda controlar los widget y las acciones
              Scaffold.of(context).showSnackBar(SnackBar(content: 
               Text("Added item to cart!"),
              duration: Duration(seconds: 2),
              action:  SnackBarAction(label: 'UNDO', onPressed: (){
                cart.removeSingleItem(product.id);
              },),
            ));
            },
          ),
        ),
      ),
    );
  }
}
