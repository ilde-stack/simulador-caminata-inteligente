:- module(borracho, [
    iniciar_borracho/2,
    posicion_actual/2,
    mover_borracho/0
]).

:- dynamic posicion_actual/2.

:- use_module(entorno).

iniciar_borracho(X, Y) :-
    retractall(posicion_actual(_, _)),
    assertz(posicion_actual(X, Y)),
    entorno:registrar_visita(X, Y).

% Movimiento aleatorio
mover_borracho :-
    posicion_actual(X, Y),
    member((DX, DY), [(0,1), (1,0), (0,-1), (-1,0)]),
    NX is X + DX, NY is Y + DY,
    entorno:dentro_limites(NX, NY),
    \+ entorno:obstaculo(NX, NY),
    retract(posicion_actual(X, Y)),
    assertz(posicion_actual(NX, NY)),
    entorno:registrar_visita(NX, NY),
    !.
mover_borracho.  % Falla = no se mueve
