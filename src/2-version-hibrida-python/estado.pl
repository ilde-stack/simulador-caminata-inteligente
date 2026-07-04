
% PREDICADOS DINÁMICOS

% Estado completo del borracho
% estado_borracho(PosX, PosY, PasosTotales, DistanciaAnterior, Energia)
:- dynamic(estado_borracho/5).

% Último movimiento realizado (para evitar oscilaciones)
:- dynamic(ultimo_movimiento/1).

% Posición inicial donde empezó el borracho (VAR)
:- dynamic(posicion_inicial/2).

% --------------------------------------------------------
% INICIALIZACIÓN DEL ESTADO

% Inicializar estado del borracho en posición específica
% También marca esta posición como la posición inicial 
inicializar_estado(X, Y) :-
    % Limpiar estado anterior
    retractall(estado_borracho(_, _, _, _, _)),
    retractall(ultimo_movimiento(_)),
    retractall(posicion_inicial(_, _)),
    
    % Limpiar memoria al inicializar estado
    limpiar_memoria_aprendizaje,
    
    % Marcar posición inicial como BAR
    assert(posicion_inicial(X, Y)),
    
    % Calcular distancia inicial a casa
    distancia_a_casa(X, Y, DistanciaInicial),
    
    % Establecer estado inicial
    % Parámetros: X, Y, Pasos=0, Distancia, Energía=100
    assert(estado_borracho(X, Y, 0, DistanciaInicial, 100)).

% --------------------------------------------------------
% CONSULTA DE ESTADO

% Obtener posición actual del borracho
posicion_actual(X, Y) :-
    estado_borracho(X, Y, _, _, _).

% Obtener número total de pasos dados
pasos_totales(Pasos) :-
    estado_borracho(_, _, Pasos, _, _).

% Obtener energía actual
energia_actual(Energia) :-
    estado_borracho(_, _, _, _, Energia).

% Verificar si ha llegado a casa (condición de victoria)
ha_llegado_a_casa :-
    estado_borracho(X, Y, _, _, _),
    posicion_casa(X, Y).

% Verificar si está en la posición inicial (VAR)
esta_en_posicion_inicial :-
    posicion_actual(X, Y),
    posicion_inicial(X, Y).

% --------------------------------------------------------
% ACTUALIZACIÓN DE ESTADO

% Realizar movimiento y actualizar estado completo
realizar_movimiento(Direccion, Resultado) :-
    estado_borracho(X, Y, Pasos, DistAnt, Energia),
    
    % Calcular nueva posición basada en la dirección
    calcular_nueva_posicion(X, Y, Direccion, NuevoX, NuevoY),
    
    % Verificar si el movimiento es válido (no hay obstáculo)
    (   movimiento_valido(X, Y, Direccion) ->
        % Movimiento exitoso - actualizar estado
        actualizar_estado_exitoso(X, Y, NuevoX, NuevoY, Direccion, Pasos, 
                                DistAnt, Energia),
        Resultado = exito
    ;   % Movimiento bloqueado por obstáculo
        actualizar_estado_fallido(X, Y, Pasos, Energia),
        Resultado = obstaculo
    ).

% Actualizar estado cuando el movimiento es exitoso
actualizar_estado_exitoso(X, Y, NuevoX, NuevoY, Direccion, Pasos, 
                        DistAnt, Energia) :-
    % Incrementar contador de pasos
    NuevosPasos is Pasos + 1,
    
    % Calcular nueva distancia a casa
    distancia_a_casa(NuevoX, NuevoY, NuevaDistancia),
    
    % Actualizar energía (cada movimiento cuesta energía)
    NuevaEnergia is max(0, Energia - 1),
    
    % Verificar si regresó a la posición inicial (condición especial)
    (   posicion_inicial(NuevoX, NuevoY), NuevosPasos > 0 ->
        % Reiniciar juego si vuelve a VAR
        reiniciar_por_retorno_a_inicio(NuevoX, NuevoY)
    ;   % Continuar normalmente
        % Actualizar estado en la base de datos
        retract(estado_borracho(X, Y, Pasos, DistAnt, Energia)),
        assert(estado_borracho(NuevoX, NuevoY, NuevosPasos, 
                              NuevaDistancia, NuevaEnergia)),
        
        % Recordar último movimiento para evitar oscilaciones
        retractall(ultimo_movimiento(_)),
        assert(ultimo_movimiento(Direccion))
    ).

% Actualizar estado cuando el movimiento falla (choca con obstáculo)
actualizar_estado_fallido(X, Y, Pasos, Energia) :-
    % Incrementar pasos (el intento cuenta)
    NuevosPasos is Pasos + 1,
    % Pérdida menor de energía por movimiento fallido
    NuevaEnergia is max(0, Energia - 0.5),
    
    % Actualizar estado (posición no cambia al chocar)
    retract(estado_borracho(X, Y, Pasos, _, Energia)),
    distancia_a_casa(X, Y, DistanciaActual),
    assert(estado_borracho(X, Y, NuevosPasos, DistanciaActual, NuevaEnergia)).

% Reiniciar cuando regresa a la posición inicial
reiniciar_por_retorno_a_inicio(X, Y) :-
    % Limpiar estado actual
    retractall(estado_borracho(_, _, _, _, _)),
    retractall(ultimo_movimiento(_)),
    
    % MODIFICACIÓN: También limpiar memoria al regresar al inicio
    limpiar_memoria_aprendizaje,
    
    % Reinicializar en la misma posición inicial
    distancia_a_casa(X, Y, DistanciaInicial),
    assert(estado_borracho(X, Y, 0, DistanciaInicial, 100)).

% --------------------------------------------------------
% PARÁMETROS DE CONFIGURACIÓN

% Energía inicial del borracho
energia_inicial(100).

% Energía mínima para funcionar normalmente
energia_minima(20).

% Límite máximo de pasos por partida
limite_maximo_pasos(1000).

% --------------------------------------------------------
% CONDICIONES DE ESTADO

% Verificar si el borracho está exhausto (sin energía)
esta_exhausto :-
    energia_actual(Energia),
    energia_minima(Minima),
    Energia < Minima.

% Verificar condiciones de fin del juego
juego_terminado(Razon) :-
    (   ha_llegado_a_casa ->
        Razon = victoria
    ;   pasos_totales(Pasos), limite_maximo_pasos(Limite), Pasos > Limite ->
        Razon = limite_pasos
    ;   esta_exhausto ->
        Razon = sin_energia
    ;   fail  % El juego continúa
    ).

% --------------------------------------------------------
% CONSULTAS PARA PYTHON

% Obtener información completa del estado actual
info_estado(Info) :-
    estado_borracho(X, Y, Pasos, Distancia, Energia),
    Info = [posicion(X, Y), pasos(Pasos), 
            distancia_casa(Distancia), energia(Energia)].

% Obtener información específica del borracho para PySwip
consultar_borracho(X, Y, Pasos, Desorientado, Energia, Distancia) :-
    (   estado_borracho(X, Y, Pasos, Distancia, Energia) -> 
        Desorientado = false  % Siempre false ya que no hay desorientación
    ;   % Valores por defecto si no hay estado
        X = 0, Y = 0, Pasos = 0, Desorientado = false, Energia = 100, Distancia = 0
    ).

% --------------------------------------------------------
% REINICIO Y LIMPIEZA

% Reiniciar estado para nuevo juego
reiniciar_estado :-
    retractall(estado_borracho(_, _, _, _, _)),
    retractall(ultimo_movimiento(_)),
    retractall(posicion_inicial(_, _)),
    % MODIFICACIÓN: Limpiar memoria al reiniciar
    limpiar_memoria_aprendizaje.

% Predicado auxiliar para limpiar memoria de aprendizaje
% MODIFICADO: Ahora siempre limpia la memoria
limpiar_memoria_aprendizaje :-
    % Limpiar memoria de obstáculos y aprendizaje
    (   current_predicate(limpiar_memoria/0) ->
        limpiar_memoria
    ;   true  % Si no está disponible, continúa sin error
    ).