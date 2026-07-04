:- module(entorno, [
    tamano/2,
    obstaculo/2,
    agregar_obstaculo/2,
    dentro_limites/2,
    visitado/2,
    registrar_visita/2,
    limpiar_visitas/0
]).

:- dynamic obstaculo/2.
:- dynamic visitado/2.

tamano(10, 10).

dentro_limites(X, Y) :-
    tamano(MaxX, MaxY),
    X >= 0, Y >= 0,
    X < MaxX, Y < MaxY.

agregar_obstaculo(X, Y) :-
    dentro_limites(X, Y),
    \+ obstaculo(X, Y),
    assertz(obstaculo(X, Y)).

registrar_visita(X, Y) :-
    \+ visitado(X, Y),
    assertz(visitado(X, Y)).

limpiar_visitas :- retractall(visitado(_, _)).
