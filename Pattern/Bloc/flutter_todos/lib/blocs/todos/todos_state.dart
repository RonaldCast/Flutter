import 'package:equatable/equatable.dart';
//los estados de componenten a tener en cuenta. 


import 'package:meta/meta.dart';
import '../../models/todo.dart';

@immutable
abstract class  TodosState extends Equatable{

  TodosState([List props = const[]]) : super(props);

}

//el estado mientras tu aplicación está recuperando
class TodosLoading extends TodosState {
  @override
  String toString() => 'TodosLoading';
}

//el estado de tu aplicación después de que ‘todos’ ha sido cargado exitosamente
class TodosLoaded extends TodosState {
  final List<Todo> todos;

  TodosLoaded([this.todos = const []]) : super([todos]);

  @override
  String toString() => 'TodosLoaded { todos: $todos }';
}

//el estado de tu aplicación si ‘todos’ no fue cargado exitosamente.
class TodosNotLoaded extends TodosState {
  @override
  String toString() => 'TodosNotLoaded';
}
