:- use_module(entorno).
:- use_module(borracho).
:- use_module(inteligencia).
:- use_module(visualizacion).

main :-
    retractall(entorno:obstaculo(_, _)),
    agregar_obstaculo(1, 1),
    agregar_obstaculo(2, 2),
    agregar_obstaculo(3, 3),
    iniciar_borracho(5, 5),
    reiniciar_memoria,
    iniciar_grafico(Window, Grilla),
    loop_grafico(Window, Grilla, 50),
    writeln("Fin de la simulación.").

loop_grafico(_, _, 0).
loop_grafico(Window, Grilla, N) :-
    dibujar_entorno(Grilla),
    sleep(0.2),
    mover_borracho_inteligente,
    N1 is N - 1,
    loop_grafico(Window, Grilla, N1).
