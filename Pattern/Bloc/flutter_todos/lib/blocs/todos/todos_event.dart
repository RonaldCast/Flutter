import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../../models/todo.dart';

@immutable
abstract class TodosEvent extends Equatable {
  TodosEvent([List props = const []]) : super(props);
}

//le dice al bloc que necesita cargar el ‘todo’ desde el TodosRepository
class LoadTodos extends TodosEvent {
  @override
  String toString() => 'LoadTodos';
}

//le dice al bloc que necesita agregar un nuevo ‘todo’ a la lista de 'todos'.
class AddTodo extends TodosEvent {
  final Todo todo;

  AddTodo(this.todo) : super([todo]);

  @override
  String toString() => 'AddTodo { todo: $todo }';
}

//le dice al bloc que necesita actualizar un ‘todo’ existente.
class UpdateTodo extends TodosEvent {
  final Todo updatedTodo;

  UpdateTodo(this.updatedTodo) : super([updatedTodo]);

  @override
  String toString() => 'UpdateTodo { updatedTodo: $updatedTodo }';
}


// le dice al bloc que necesita remover un ‘todo’ existente.
class DeleteTodo extends TodosEvent {
  final Todo todo;

  DeleteTodo(this.todo) : super([todo]);

  @override
  String toString() => 'DeleteTodo { todo: $todo }';
}


//le dice al bloc que necesita remover todos los ‘todo’ completados.
class ClearCompleted extends TodosEvent {
  @override
  String toString() => 'ClearCompleted';
}

// le dice al bloc que necesita alternar el estado completado de todos los ‘todo’.
class ToggleAll extends TodosEvent {
  @override
  String toString() => 'ToggleAll';
}