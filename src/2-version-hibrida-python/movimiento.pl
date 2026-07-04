
% DEFINICIÓN DE MOVIMIENTOS

% Los 4 movimientos posibles con sus desplazamientos (DeltaX, DeltaY)
% Sistema de coordenadas: (0,0) = esquina superior izquierda
movimiento_delta(arriba, 0, -1).      % Moverse hacia arriba (Y decrece)
movimiento_delta(abajo, 0, 1).        % Moverse hacia abajo (Y aumenta)
movimiento_delta(izquierda, -1, 0).   % Moverse hacia la izquierda (X decrece)
movimiento_delta(derecha, 1, 0).      % Moverse hacia la derecha (X aumenta)

% Lista de todos los movimientos disponibles
movimientos_disponibles([arriba, abajo, izquierda, derecha]).

% --------------------------------------------------------
% CÁLCULO DE NUEVAS POSICIONES

% Calcular nueva posición después de aplicar un movimiento
% Toma posición actual (X, Y) y dirección, retorna nueva posición
calcular_nueva_posicion(X, Y, Direccion, NuevoX, NuevoY) :-
    movimiento_delta(Direccion, DeltaX, DeltaY),
    NuevoX is X + DeltaX,
    NuevoY is Y + DeltaY.

% --------------------------------------------------------
% VALIDACIÓN DE MOVIMIENTOS

% Verificar si un movimiento es válido desde la posición actual
% Un movimiento es válido si la nueva posición es transitable
movimiento_valido(X, Y, Direccion) :-
    calcular_nueva_posicion(X, Y, Direccion, NuevoX, NuevoY),
    posicion_transitable(NuevoX, NuevoY).

% Obtener todos los movimientos válidos desde una posición
% Filtra solo los movimientos que no chocan con obstáculos o límites
obtener_movimientos_validos(X, Y, MovimientosValidos) :-
    movimientos_disponibles(TodosMovimientos),
    findall(Mov, 
           (member(Mov, TodosMovimientos), movimiento_valido(X, Y, Mov)), 
           MovimientosValidos).

% --------------------------------------------------------
% MOVIMIENTOS ESTRATÉGICOS BÁSICOS

% Obtener movimiento que más se acerca a la casa
% Evalúa todos los movimientos válidos y elige el que minimiza la distancia
movimiento_hacia_casa(X, Y, MejorMovimiento) :-
    posicion_casa(CasaX, CasaY),
    obtener_movimientos_validos(X, Y, MovimientosValidos),
    MovimientosValidos \= [],  % Asegurar que hay movimientos válidos
    evaluar_movimientos_hacia_casa(X, Y, CasaX, CasaY, MovimientosValidos, MejorMovimiento).

% Evaluar qué movimiento reduce más la distancia a casa
% Caso base: solo un movimiento disponible
evaluar_movimientos_hacia_casa(X, Y, CasaX, CasaY, [Mov], Mov) :- !.

% Caso recursivo: comparar movimientos y elegir el mejor
evaluar_movimientos_hacia_casa(X, Y, CasaX, CasaY, [Mov1|Resto], MejorMovimiento) :-
    % Calcular distancia para el primer movimiento
    calcular_nueva_posicion(X, Y, Mov1, X1, Y1),
    distancia_a_casa(X1, Y1, Dist1),
    % Evaluar el resto de movimientos
    evaluar_movimientos_hacia_casa(X, Y, CasaX, CasaY, Resto, MejorResto),
    calcular_nueva_posicion(X, Y, MejorResto, X2, Y2),
    distancia_a_casa(X2, Y2, Dist2),
    % Elegir el que tenga menor distancia (con preferencia por el primero en caso de empate)
    (   Dist1 =< Dist2 -> MejorMovimiento = Mov1
    ;   MejorMovimiento = MejorResto
    ).

% Seleccionar movimiento aleatorio entre los válidos
% Útil para exploración y cuando el borracho está desorientado
movimiento_aleatorio(X, Y, MovimientoElegido) :-
    obtener_movimientos_validos(X, Y, MovimientosValidos),
    MovimientosValidos \= [],
    length(MovimientosValidos, Cantidad),
    random(0, Cantidad, Indice),
    nth0(Indice, MovimientosValidos, MovimientoElegido).

% --------------------------------------------------------
% MOVIMIENTOS ANTI-CICLO

% Definir movimientos opuestos (para evitar oscilaciones)
movimiento_opuesto(arriba, abajo).  
movimiento_opuesto(abajo, arriba).
movimiento_opuesto(izquierda, derecha).
movimiento_opuesto(derecha, izquierda).

% Evitar hacer el movimiento exactamente opuesto al anterior
% Ayuda a prevenir oscilaciones simples entre dos posiciones
evitar_movimiento_opuesto(MovimientoDeseado, MovimientoFinal) :-
    (   ultimo_movimiento(UltimoMov),
        movimiento_opuesto(UltimoMov, MovimientoDeseado) ->
        % Si el movimiento deseado es opuesto al último, buscar alternativa
        posicion_actual(X, Y),
        obtener_movimientos_validos(X, Y, MovimientosValidos),
        seleccionar_movimiento_alternativo(MovimientosValidos, UltimoMov, MovimientoFinal)
    ;   % Si no hay conflicto, usar el movimiento deseado
        MovimientoFinal = MovimientoDeseado
    ).

% Seleccionar movimiento alternativo que no sea el opuesto al último
seleccionar_movimiento_alternativo([Mov|_], MovimientoEvitar, Mov) :-
    \+ movimiento_opuesto(MovimientoEvitar, Mov), !.

seleccionar_movimiento_alternativo([_|Resto], MovimientoEvitar, MovimientoFinal) :-
    seleccionar_movimiento_alternativo(Resto, MovimientoEvitar, MovimientoFinal).

% --------------------------------------------------------
% UTILIDADES DE SELECCIÓN

% Seleccionar elemento aleatorio de una lista
% Útil para decisiones aleatorias entre opciones válidas
seleccionar_de_lista(Lista, Elemento) :-
    length(Lista, Longitud),
    Longitud > 0,  % Verificar que la lista no esté vacía
    random(0, Longitud, Indice),
    nth0(Indice, Lista, Elemento).

% Filtrar movimientos según criterio personalizado
% Permite aplicar filtros específicos a los movimientos válidos
filtrar_movimientos(_, _, [], []).

filtrar_movimientos(X, Y, [Mov|Resto], [Mov|Filtrados]) :-
    % Aplicar criterio de filtrado (debe ser definido por el predicado que llama)
    criterio_filtrado(X, Y, Mov),
    !,
    filtrar_movimientos(X, Y, Resto, Filtrados).

filtrar_movimientos(X, Y, [_|Resto], Filtrados) :-
    filtrar_movimientos(X, Y, Resto, Filtrados).