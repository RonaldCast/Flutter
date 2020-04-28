import 'package:flutter/material.dart';
import './question.dart';
import './answer.dart';

class Quiz extends StatelessWidget {
  final List<Map<String, Object>> questions;
  final Function answaerQuestion;
  final int questionIndex;

  Quiz({@required this.questions, @required this.questionIndex, @required this.answaerQuestion});

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Question(questions[questionIndex]['questionText']),
      Container(
        child: Column(
          children: <Widget>[
            ...(questions[questionIndex]['answer'] as List<Map<String, Object>>)
                .map((answer) {
              return Answer(() => answaerQuestion( answer['score']), text: answer['text']);
            }).toList()
          ],
        ),
      ),
    ]);
  }
}
