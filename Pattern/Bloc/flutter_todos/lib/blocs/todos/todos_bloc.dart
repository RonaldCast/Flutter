import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_todos/blocs/todos/todos_event.dart';
import 'package:meta/meta.dart';
import './todos_state.dart';
import '../../models/todo.dart';
import 'package:todos_repository_simple/todos_repository_simple.dart';

// en este se toma initialState y mapEventToState

class TodosBloc extends Bloc<TodosEvent ,TodosState>{
  final TodosRepositoryFlutter todosRepository;

  TodosBloc({@required this.todosRepository});

  @override
  TodosState get initialState => TodosLoading();
}
