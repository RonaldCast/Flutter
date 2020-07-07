# flutter_todos Bloc (Business Logic Component)

Bloc es aquel que se va a encargar de la gestion del estado. Por acada pantalla se debe de crear un Bloc.

Las cosas que se debe de saber para su implementacion

* Primero: conocer cuales pantalla lo requieren
* Segundo: Saber que eventos estan sucediento en la pantalla que amerite el cambio de estado.
* Tercero: Se deben de enumeral los estado.

## Contruir un Bloc

1 - Este debe de tener la logica de insercion de datos en la DB.

2 - Buscar los datos

3 - Realizar los calculos.

En conclusion Event-in Event-out

Para su emplementacion se utiliza en package **flutter_block** .

## Uso de Bloc

### BlocProvider

Este proporciona un Bloc a aus hijos, todos los widget dentro del Bloc pueden acceder al estado a travez de BlocProvider.

````
  ConvoBloc _convoBloc;

  @override
  void initState() {
    _convoBloc = ConvoBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      bloc: _convoBloc,
      child: Container(),
    );
  }

````

### BlocProviderTree

Es lo mismo que BlocProvider, pero puede proporcionar multiples Blocs a la vez

````
 @override
  Widget build(BuildContext context) {
    return BlocProviderTree(
      blocProviders: [
        BlocProvider<Bloc1>(bloc: _bloc1),
        BlocProvider<Bloc2>(bloc: _bloc2),
      ],
      child: Container();
  }
````

### BlocBuilder

Este es un widget que se reconstruye automaticamente cada vez que el Bloc proporcionado realiza un cambio de estado.

```
  @override
  Widget build(BuildContext context) {
    return BlocBuilder(
      bloc: BlocProvider.of<ConvoBloc>(context),
      builder: (BuildContext context, ConvoState state) {
        if (state is ConvosLoaded) {
          return Container();
        }
      },
    );
  }

```

ddd
