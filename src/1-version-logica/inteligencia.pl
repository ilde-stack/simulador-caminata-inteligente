:- module(inteligencia, [
    mover_borracho_inteligente/0,
    reiniciar_memoria/0
]).

:- use_module(entorno).
:- use_module(borracho).

:- dynamic memoria_mala/2.
:- dynamic pasos_sin_progreso/1.

umbral_desorientacion(10).
objetivo(0, 0).

reiniciar_memoria :-
    retractall(memoria_mala(_, _)),
    retractall(pasos_sin_progreso(_)),
    entorno:limpiar_visitas,
    assertz(pasos_sin_progreso(0)).

mover_borracho_inteligente :-
    borracho:posicion_actual(X, Y),
    entorno:registrar_visita(X, Y),
    opciones_validas(X, Y, Vecinos),
    (Vecinos \= [] ->
        priorizar(Vecinos, Ordenados),
        mover(X, Y, Ordenados)
    ;   borracho:mover_borracho
    ).

opciones_validas(X, Y, Vecinos) :-
    findall((NX, NY),
        (
            member((DX, DY), [(0,1), (1,0), (0,-1), (-1,0)]),
            NX is X + DX, NY is Y + DY,
            entorno:dentro_limites(NX, NY),
            \+ entorno:obstaculo(NX, NY),
            \+ memoria_mala(NX, NY)
        ), Vecinos).

priorizar(Lista, Ordenada) :-
    objetivo(OX, OY),
    map_list_to_pairs(
        Dist^(X,Y)^Dist is abs(OX - X) + abs(OY - Y),
        Lista,
        Pairs),
    keysort(Pairs, OrdenadaPairs),
    pairs_values(OrdenadaPairs, Ordenada).

mover(X, Y, [(NX, NY)|_]) :-
    (X = NX, Y = NY -> fallo ; exito(X, Y, NX, NY)).

fallo :-
    pasos_sin_progreso(N), N1 is N + 1,
    (N1 >= 10 -> reiniciar_memoria, borracho:mover_borracho
    ; retract(pasos_sin_progreso(N)), assertz(pasos_sin_progreso(N1))).

exito(X, Y, NX, NY) :-
    retract(borracho:posicion_actual(X, Y)),
    assertz(borracho:posicion_actual(NX, NY)),
    entorno:registrar_visita(NX, NY),
    retractall(pasos_sin_progreso(_)),
    assertz(pasos_sin_progreso(0)).
