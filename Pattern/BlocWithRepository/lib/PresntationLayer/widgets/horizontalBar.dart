import 'package:BlocWithRepository/Bloc/Player/exportPlayerBloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:BlocWithRepository/DataLayer/Models/Nations.dart';

class HorizontalBar extends StatelessWidget{
  
  @override
  Widget build(BuildContext context) {
    return  Container(

      height: 80.0,
      child: ListView.builder(
        itemBuilder: buildItem,
        itemCount: nations.length,
        scrollDirection: Axis.horizontal,

      ),
    );
  }

  
}


 Widget buildItem(context, index) {
   return InkWell(onTap: (){
   BlocProvider.of<PlayerListingBloc>(context)
            .add(CountrySelectedEvent(model: nations[index]));
   },
    child: Container(
      width: 80.0,
      height: 80.0,
      decoration: BoxDecoration(
        image: DecorationImage(image: AssetImage(nations[index].imagePath))
      ),
      margin: EdgeInsets.symmetric(horizontal:16),
    ),
   );
 }

Widget buildSeparator(context, index) {
  return VerticalDivider(
      width: 32.0,
      color: Colors.transparent,
    );
}