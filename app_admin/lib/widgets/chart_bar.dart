import 'package:flutter/material.dart';

class ChartBar extends StatelessWidget {
  final String label;
  final double spendingAmount;
  final double spendingPcOfTotal;

  ChartBar(this.label, this.spendingAmount, this.spendingPcOfTotal);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      return Column(
        children: <Widget>[
          Container(
            height: constraint.maxHeight * 0.15,
            child: FittedBox(
              child: Text(
                'RD\$${spendingAmount.toStringAsFixed(0)}',
                style: TextStyle(fontSize: 1),
              ),
            ),
          ), // para adaptar en contenido al container y no sobre salga

          SizedBox(height: constraint.maxHeight * 0.05),
          Container(
            width: 10,
            height: constraint.maxHeight * 0.6,
            child: Stack(
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey,
                        width: 1.0,
                      ),
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20)),
                ),
                FractionallySizedBox(
                  heightFactor: spendingPcOfTotal,
                  child: Container(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).primaryColor),
                  ),
                )
              ],
            ),
          ),
          SizedBox(
            height: constraint.maxHeight * 0.05,
          ),
          Container( height: constraint.maxHeight * 0.15 ,
            child: Container(
              height: constraint.maxHeight * 0.05,
              child: FittedBox(child: Text(label))))
        ],
      );
    });
  }
}
