
% SELECTOR PRINCIPAL DE ESTRATEGIA


% Este es el punto de entrada principal para decidir qué hacer
seleccionar_movimiento_principal(Movimiento) :-
    posicion_actual(X, Y),
    obtener_movimientos_validos(X, Y, MovimientosValidos),
    MovimientosValidos \= [],  % Verificar que hay movimientos válidos
    
    % Determinar qué estrategia usar según el estado
    determinar_estrategia(Estrategia),
    
    % Aplicar la estrategia seleccionada
    aplicar_estrategia(Estrategia, X, Y, MovimientosValidos, Movimiento).

% --------------------------------------------------------
% DETERMINACIÓN DE ESTRATEGIA

% Determinar qué estrategia usar según el estado actual del borracho
% Prioriza las situaciones más críticas primero
determinar_estrategia(Estrategia) :-
    (   esta_exhausto ->
        Estrategia = supervivencia  % Cuando la energia esta muy baja
    ;   detectar_ciclo ->
        Estrategia = anti_ciclo   % Si detectó que hubo un ciclo, básicamente para romper con ese patrón
    ;   tiene_experiencia ->
        Estrategia = inteligente_avanzada    % Cuando tiene más experiencia
    ;   Estrategia = inteligente_basica      % Cuando tiene poca experiencia
    ).

% --------------------------------------------------------
% APLICACIÓN DE ESTRATEGIAS

% Prioriza llegar a casa con la poca energía restante
aplicar_estrategia(supervivencia, X, Y, MovimientosValidos, Movimiento) :-
    % Intentar ir directamente hacia casa sin importar otros factores
    (   movimiento_hacia_casa(X, Y, MovimientoCasa),
        member(MovimientoCasa, MovimientosValidos) ->
        Movimiento = MovimientoCasa
    ;   % Si no puede ir hacia casa, movimiento aleatorio como último recurso
        seleccionar_de_lista(MovimientosValidos, Movimiento)
    ).

% Estrategia anti-ciclo (detectó que está en bucle)
% Prioriza romper el patrón repetitivo
aplicar_estrategia(anti_ciclo, X, Y, MovimientosValidos, Movimiento) :-
    % Buscar movimientos que no estén en el historial reciente
    filtrar_movimientos_anti_ciclo(X, Y, MovimientosValidos, MovimientosFiltrados),
    (   MovimientosFiltrados \= [] ->
        % Usar movimientos que rompen el ciclo
        (   random(1, 11, R), R =< 7 ->  % 70% aleatorio entre los que rompen ciclo
            seleccionar_de_lista(MovimientosFiltrados, Movimiento)
        ;   % 30% hacia casa entre los que rompen ciclo
            encontrar_mejor_hacia_casa(X, Y, MovimientosFiltrados, Movimiento)
        )
    ;   % Si no hay opciones anti-ciclo, forzar movimiento aleatorio
        seleccionar_de_lista(MovimientosValidos, Movimiento)
    ).

% Estrategia inteligente básica (sin mucha experiencia)
% Evita obstáculos conocidos y posiciones muy visitadas, con exploración
aplicar_estrategia(inteligente_basica, X, Y, MovimientosValidos, Movimiento) :-
    % 60% hacia casa evitando problemas, 40% exploración
    (   random(1, 11, R), R =< 6 ->
        movimiento_inteligente_basico(X, Y, MovimientosValidos, Movimiento)
    ;   movimiento_exploratorio(X, Y, MovimientosValidos, Movimiento)
    ).

% Estrategia inteligente avanzada 
% Usa valores de refuerzo y equilibra explotación/exploración
aplicar_estrategia(inteligente_avanzada, X, Y, MovimientosValidos, Movimiento) :-
    % Usar aprendizaje por refuerzo con exploración ocasional
    (   mejor_movimiento_refuerzo(X, Y, MejorMovimiento),
        member(MejorMovimiento, MovimientosValidos) ->
        % 70/30 
        (   random(1, 11, R), R =< 7 ->
            Movimiento = MejorMovimiento  
        ;   movimiento_exploratorio(X, Y, MovimientosValidos, Movimiento)  
        )
    ;   % Si no hay datos de refuerzo, usar estrategia básica
        aplicar_estrategia(inteligente_basica, X, Y, MovimientosValidos, Movimiento)
    ).

% --------------------------------------------------------
% MOVIMIENTOS ESPECIALIZADOS

% Movimiento inteligente básico
% Evita obstáculos conocidos y posiciones muy visitadas
movimiento_inteligente_basico(X, Y, MovimientosValidos, Movimiento) :-
    % Filtrar movimientos hacia obstáculos conocidos
    filtrar_obstaculos_conocidos(X, Y, MovimientosValidos, SinObstaculos),
    % Filtrar posiciones muy visitadas
    filtrar_posiciones_visitadas(X, Y, SinObstaculos, MovimientosFiltrados),
    
    % Usar movimientos filtrados si hay, sino usar todos
    (   MovimientosFiltrados \= [] ->
        MovimientosUsar = MovimientosFiltrados
    ;   SinObstaculos \= [] ->
        MovimientosUsar = SinObstaculos
    ;   MovimientosUsar = MovimientosValidos
    ),
    
    % Elegir el mejor movimiento hacia casa
    encontrar_mejor_hacia_casa(X, Y, MovimientosUsar, Movimiento).

% Movimiento exploratorio (busca posiciones menos visitadas)
movimiento_exploratorio(X, Y, MovimientosValidos, Movimiento) :-
    % Buscar movimientos hacia posiciones menos exploradas
    encontrar_movimientos_exploratorios(X, Y, MovimientosValidos, MovimientosExploratorios),
    (   MovimientosExploratorios \= [] ->
        seleccionar_de_lista(MovimientosExploratorios, Movimiento)
    ;   seleccionar_de_lista(MovimientosValidos, Movimiento)
    ).

% Encontrar movimientos hacia posiciones menos visitadas
encontrar_movimientos_exploratorios(X, Y, MovimientosValidos, MovimientosExploratorios) :-
    evaluar_exploracion_movimientos(X, Y, MovimientosValidos, MovimientosEvaluados),
    ordenar_por_exploracion(MovimientosEvaluados, MovimientosOrdenados),
    extraer_mejores_exploratorios(MovimientosOrdenados, MovimientosExploratorios).

% --------------------------------------------------------
% FILTROS ESPECIALIZADOS

% Filtrar movimientos que no chocan con obstáculos conocidos
filtrar_obstaculos_conocidos(_, _, [], []).
filtrar_obstaculos_conocidos(X, Y, [Mov|Resto], [Mov|Filtrados]) :-
    \+ se_recuerda_obstaculo(X, Y, Mov),
    !,
    filtrar_obstaculos_conocidos(X, Y, Resto, Filtrados).
filtrar_obstaculos_conocidos(X, Y, [_|Resto], Filtrados) :-
    filtrar_obstaculos_conocidos(X, Y, Resto, Filtrados).

% Filtrar movimientos que no van a posiciones muy visitadas
filtrar_posiciones_visitadas(_, _, [], []).
filtrar_posiciones_visitadas(X, Y, [Mov|Resto], [Mov|Filtrados]) :-
    calcular_nueva_posicion(X, Y, Mov, NuevoX, NuevoY),
    \+ posicion_muy_visitada(NuevoX, NuevoY),
    !,
    filtrar_posiciones_visitadas(X, Y, Resto, Filtrados).
filtrar_posiciones_visitadas(X, Y, [_|Resto], Filtrados) :-
    filtrar_posiciones_visitadas(X, Y, Resto, Filtrados).

% Filtrar movimientos para romper ciclos
filtrar_movimientos_anti_ciclo(X, Y, MovimientosValidos, MovimientosFiltrados) :-
    historial_posiciones(Historial),
    filtrar_anti_ciclo_recursivo(X, Y, MovimientosValidos, Historial, MovimientosFiltrados).

% Filtrar recursivamente movimientos que no están en el historial reciente
filtrar_anti_ciclo_recursivo(_, _, [], _, []).
filtrar_anti_ciclo_recursivo(X, Y, [Mov|Resto], Historial, [Mov|Filtrados]) :-
    calcular_nueva_posicion(X, Y, Mov, NuevoX, NuevoY),
    \+ member([NuevoX, NuevoY], Historial),  % No está en historial reciente
    !,
    filtrar_anti_ciclo_recursivo(X, Y, Resto, Historial, Filtrados).
filtrar_anti_ciclo_recursivo(X, Y, [_|Resto], Historial, Filtrados) :-
    filtrar_anti_ciclo_recursivo(X, Y, Resto, Historial, Filtrados).

% --------------------------------------------------------
% EVALUACIÓN Y SELECCIÓN

% Encontrar el mejor movimiento hacia casa entre opciones disponibles
encontrar_mejor_hacia_casa(X, Y, MovimientosDisponibles, MejorMovimiento) :-
    evaluar_movimientos_hacia_casa(X, Y, _, _, MovimientosDisponibles, MejorMovimiento).

% Evaluar potencial exploratorio de cada movimiento
evaluar_exploracion_movimientos(_, _, [], []).
evaluar_exploracion_movimientos(X, Y, [Mov|Resto], [[Mov, Valor]|EvaluadosResto]) :-
    calcular_nueva_posicion(X, Y, Mov, NuevoX, NuevoY),
    evaluar_calidad_exploracion(NuevoX, NuevoY, Valor),
    evaluar_exploracion_movimientos(X, Y, Resto, EvaluadosResto).

% Ordenar movimientos por valor exploratorio (mayor valor primero)
ordenar_por_exploracion(MovimientosEvaluados, MovimientosOrdenados) :-
    sort(2, @>=, MovimientosEvaluados, MovimientosOrdenados).

% Extraer los movimientos con mejor valor exploratorio
extraer_mejores_exploratorios([[Mov, Valor]|Resto], [Mov|MejoresResto]) :-
    Valor > 5,  % Umbral para considerar "bueno" para exploración
    !,
    extraer_mejores_exploratorios(Resto, MejoresResto).
extraer_mejores_exploratorios(_, []).

% --------------------------------------------------------
% ESTRATEGIAS ADAPTATIVAS

% Ajustar estrategia dinámicamente basado en rendimiento
ajustar_estrategia_dinamica :-
    pasos_totales(Pasos),
    % Evaluar cada 25 pasos si está funcionando bien
    (   Pasos > 0, Pasos mod 25 =:= 0 ->
        evaluar_rendimiento_reciente
    ;   true
    ).

% Evaluar si el rendimiento reciente es bueno
evaluar_rendimiento_reciente :-
    % Verificar si hay progreso hacia la casa
    posicion_actual(X, Y),
    distancia_a_casa(X, Y, DistanciaActual),
    pasos_totales(Pasos),
    (   Pasos > 50, DistanciaActual > 15 ->
        % Rendimiento malo, necesita cambio de estrategia
        forzar_exploracion_temporal
    ;   true
    ).

% Forzar exploración temporal cuando está muy estancado
forzar_exploracion_temporal :-
    % Reducir valores de refuerzo para forzar más exploración
    findall([X,Y,Dir,Valor], valor_refuerzo(X, Y, Dir, Valor), ValoresActuales),
    reducir_valores_refuerzo(ValoresActuales).

% Reducir valores de refuerzo para incentivar exploración
reducir_valores_refuerzo([]).
reducir_valores_refuerzo([[X,Y,Dir,Valor]|Resto]) :-
    NuevoValor is Valor * 0.7,  % Reducir 30%
    retract(valor_refuerzo(X, Y, Dir, Valor)),
    assert(valor_refuerzo(X, Y, Dir, NuevoValor)),
    reducir_valores_refuerzo(Resto).

% --------------------------------------------------------
% SELECTOR MEJORADO CON ANTI-CICLO

% Selector de movimiento mejorado que maneja mejor los ciclos
seleccionar_movimiento_mejorado(Movimiento) :-
    posicion_actual(X, Y),
    obtener_movimientos_validos(X, Y, MovimientosValidos),
    MovimientosValidos \= [],
    
    % Verificar si está estancado (sin mucho progreso)
    evaluar_nivel_estancamiento(NivelEstancamiento),
    
    % Aplicar estrategia según nivel de estancamiento
    (   NivelEstancamiento >= 3 ->
        % Muy estancado: 90% aleatorio
        (   random(1, 11, R), R =< 9 ->
            seleccionar_de_lista(MovimientosValidos, Movimiento)
        ;   seleccionar_movimiento_principal(Movimiento)
        )
    ;   NivelEstancamiento >= 2 ->
        % Bastante estancado: 70% aleatorio, 30% inteligente
        (   random(1, 11, R), R =< 7 ->
            seleccionar_de_lista(MovimientosValidos, Movimiento)
        ;   seleccionar_movimiento_principal(Movimiento)
        )
    ;   detectar_ciclo ->
        % Ciclo detectado: estrategia anti-ciclo
        aplicar_estrategia(anti_ciclo, X, Y, MovimientosValidos, Movimiento)
    ;   % Funcionamiento normal
        seleccionar_movimiento_principal(Movimiento)
    ).

% Evaluar nivel de estancamiento del borracho
evaluar_nivel_estancamiento(Nivel) :-
    pasos_totales(Pasos),
    posicion_actual(X, Y),
    distancia_a_casa(X, Y, Distancia),
    
    % Determinar nivel basado en pasos y distancia
    (   Pasos > 100, Distancia > 12 ->
        Nivel = 3  % Muy estancado
    ;   Pasos > 60, Distancia > 8 ->
        Nivel = 2  % Bastante estancado
    ;   Pasos > 30, Distancia > 6 ->
        Nivel = 1  % Ligeramente estancado
    ;   Nivel = 0  % Normal
    ).

% --------------------------------------------------------
% INFORMACIÓN DE ESTRATEGIA

% Obtener descripción de la estrategia actual
estrategia_actual(Descripcion) :-
    determinar_estrategia(Estrategia),
    descripcion_estrategia(Estrategia, Descripcion).

% Descripciones de las estrategias
descripcion_estrategia(supervivencia, 'Modo supervivencia - energia critica').
descripcion_estrategia(anti_ciclo, 'Rompiendo ciclo detectado').
descripcion_estrategia(inteligente_basica, 'Navegacion inteligente con exploracion').
descripcion_estrategia(inteligente_avanzada, 'Navegacion con aprendizaje avanzado').