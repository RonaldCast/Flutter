//este pack posee los diferentes widget
import 'package:flutter/material.dart';
import './quiz.dart';
import './result.dart';
//principal funcion
/*void main(){

   //para correr la 
   runApp(MyApp());
}*/

void main() => runApp(MyApp());
//Widget: es un objeto especial

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:
          Home(), // es a core widget cuale flutter mostrara en la pantalla, cuando la aplicacion se monta en la pantalla
    );
  }
}

class Home extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

class _HomeState extends State<Home> {
  var _questionIndex = 0;
  var _totalScore = 0; 
  final _questions = const [
    {
      'questionText': 'What\'s your favorite color?',
      'answer': [
        {"text": "Black", "score": 10},
        {'text': 'Red', 'score': 5},
        {'text': 'Greed', 'score': 3}
      ]
    },
    {
      'questionText': 'What\'s your favorite animal?',
      'answer': [
        {"text": "Rabbit", "score": 1},
        {'text': 'Snake', 'score': 5},
        {'text': 'Elephant', 'score': 3}
      ]
    },
    {
      'questionText': 'What\'s your favorite instructor?',
      'answer':[
        {"text": "Max", "score":10},
        {'text': 'Max', 'score':2},
        {'text': 'Max', 'score':3}
      ] 
    }
  ];

  void _answerQuestion(int score) {
    if (_questionIndex < _questions.length) {
      _totalScore += score;
      setState(() {
        _questionIndex = _questionIndex + 1;
      });
    }
  }
  void _resetQuiz(){
    setState(() {
      _totalScore = 0;
      _questionIndex =0;

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My First App'),
      ),
      body: _questionIndex < _questions.length
          ? Quiz(
              answaerQuestion: _answerQuestion,
              questionIndex: _questionIndex,
              questions: _questions,
            )
          : Result(_totalScore, _resetQuiz),
    );
  }
}

//anotaciones

/**
 * 
 * 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('My First App'),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
          Question(questions[_questionIndex]),
          Container(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                RaisedButton(
                  onPressed: () => _answaerQuestion(0),
                  child: Text('Answer 1'),
                ),
                RaisedButton(
                  onPressed: () => _answaerQuestion(1),
                  child: Text('Answer 2'),
                ),
                RaisedButton(
                  onPressed: () => _answaerQuestion(2),
                  child: Text('Answer 3'),
                ),
                
              ],
            
            ),
          ),
        ]));
  }
 */

/**
 * 
 * 
  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: 2,
      children: <Widget>[
      Container(
        width: double.infinity,
        color: Colors.pink,
      ),
      Container(
        width: 300,
        height: 300,
        color: Colors.purple,
        ),
      Container(
        height: 200, 
        width: 200,
        color: Colors.red,)

    ],);
  }
 */

/**  Answer(() => _answaerQuestion(0), text:'Answer 1'),
                    Answer(() => _answaerQuestion(1), text:'Answer 2'),
                    Answer(() => _answaerQuestion(2), text:'Answer 3'), */
