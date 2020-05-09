import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart';
import './chart_bar.dart';

class Chart extends StatelessWidget{
  final List<Transaction> recentTransactions;

  Chart(this.recentTransactions);
  List<Map<String, Object>> get grounpedTransactionValues{
    return List.generate(7, (index){
      final weekDay = DateTime.now().subtract(Duration(days: index,));
      double totalSum = 0;

      for (var i = 0 ; i < recentTransactions.length; i++ ) {
        if(recentTransactions[i].date.day == weekDay.day &&
         recentTransactions[i].date.month == weekDay.month
         && recentTransactions[i].date.year == weekDay.year){
            totalSum += recentTransactions[i].amount;
        }
      }

      return {'day':DateFormat.E().format(weekDay).substring(0,1) , 'amount': totalSum};
    }).reversed.toList();
  }

  double get _maxSpending{
    return grounpedTransactionValues.fold(0.0, (sum, item){
      return sum + item['amount'];
    });
  }

 @override
  Widget build(BuildContext context){
    return 
    Container(
      height: MediaQuery.of(context).size.height * 0.4,
      child: Card(
       
        elevation: 6,
        margin: EdgeInsets.all(20), 
        child: Container(
          padding: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: grounpedTransactionValues.map((data){
              return Flexible(
                fit: FlexFit.loose,
                child:ChartBar(data['day'],data['amount'], _maxSpending == 0.0 ? 0.0: (data['amount'] as double) / _maxSpending  ));
            }).toList()
          ),
        ),
      ),
    );
  }
}