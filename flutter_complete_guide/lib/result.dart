import 'package:flutter/material.dart';

class Result extends StatelessWidget {
  final int totalScore;
  final Function resetQuiz;

  Result(this.totalScore, this.resetQuiz);

  String get resultPhrase {
    var resultText = 'You did it';
    if (totalScore <= 8) {
      resultText = 'You are awesome!';
    } else if (totalScore <= 12) {
      resultText = 'Pretty likeable!';
    } else {
      resultText = 'You are so bad';
    }
    return resultText;
  }

  @override
  Widget build(BuildContext context) {
    return 
    Center(
      
      child:Column(
    
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          resultPhrase,
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
        ),
        FlatButton(
          textColor: Colors.blue,
          child: Text('Restart Quiz'),
          onPressed: resetQuiz,
        )
      ],
    ));
    
  }
}
