:- module(visualizacion, [
    iniciar_grafico/2,
    dibujar_entorno/1
]).

:- use_module(entorno).
:- use_module(borracho).
:- use_module(library(pce)).

iniciar_grafico(Window, Grilla) :-
    tamano(Ancho, Alto),
    new(Window, picture('Caminata del Borracho')),
    send(Window, size, size(Ancho*20, Alto*20)),
    new(Grilla, bitmap(Ancho*20, Alto*20)),
    send(Window, display, Grilla),
    send(Window, open).

dibujar_entorno(Grilla) :-
    tamano(Ancho, Alto),
    send(Grilla, clear),
    forall(between(0, Ancho-1, X),
        forall(between(0, Alto-1, Y),
            dibujar_celda(Grilla, X, Y))).

dibujar_celda(Grilla, X, Y) :-
    CeldaX is X * 20,
    CeldaY is Y * 20,
    ( borracho:posicion_actual(X, Y) -> Color = red ;
      entorno:obstaculo(X, Y) -> Color = black ;
      entorno:visitado(X, Y) -> Color = grey ;
      (X = 0, Y = 0) -> Color = green ;
      Color = white ),
    send(Grilla, draw, box(20, 20), point(CeldaX, CeldaY)),
    send(Grilla, fill_pattern, colour(Color)),
    send(Grilla, flush).
