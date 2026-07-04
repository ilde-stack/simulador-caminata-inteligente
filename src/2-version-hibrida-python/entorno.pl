
% CONFIGURACIÓN DEL MAPA

% Definir tamaño del mapa (20x20 celdas)
tamanio_mapa(20, 20).

% Definir posición de la casa (centro del mapa)
posicion_casa(10, 10).

% --------------------------------------------------------
% GESTIÓN DE OBSTÁCULOS

% Predicado dinámico para almacenar obstáculos en memoria
:- dynamic(obstaculo/2).  % obstaculo(X, Y)

% Agregar un obstáculo en posición (X, Y)
% Solo se agrega si la posición es válida y no existe ya
agregar_obstaculo(X, Y) :-
    posicion_valida(X, Y),   % Verificar que está dentro del mapa
    \+ obstaculo(X, Y),      % Verificar que no existe ya un obstáculo
    \+ es_casa(X, Y),        % Verificar que no es la casa
    assert(obstaculo(X, Y)). % Crear el obstáculo en memoria

% Remover un obstáculo del mapa
remover_obstaculo(X, Y) :-      
    retract(obstaculo(X, Y)).

% Verificar si hay obstáculo en una posición específica
hay_obstaculo(X, Y) :-
    obstaculo(X, Y).

% Verificar si una posición es la casa del borracho
es_casa(X, Y) :-
    posicion_casa(X, Y).

% --------------------------------------------------------
% VALIDACIÓN DE POSICIONES

% Verificar si una posición está dentro de los límites del mapa
posicion_valida(X, Y) :-
    tamanio_mapa(MaxX, MaxY),
    X >= 0, X < MaxX,
    Y >= 0, Y < MaxY.

% Verificar si una posición es transitable (sin obstáculos y dentro del mapa)
posicion_transitable(X, Y) :-
    posicion_valida(X, Y),
    \+ hay_obstaculo(X, Y).

% --------------------------------------------------------
% GENERACIÓN DE OBSTÁCULOS ALEATORIOS

% Generar obstáculos aleatorios en el mapa
% Llama al predicado recursivo con contador inicializado en 0
generar_obstaculos_aleatorios(NumObstaculos) :-
    generar_obstaculos_aleatorios(NumObstaculos, 0).

% Caso base: cuando se han generado todos los obstáculos solicitados
generar_obstaculos_aleatorios(NumObstaculos, NumObstaculos) :- !.

% Caso recursivo: generar obstáculos uno por uno
generar_obstaculos_aleatorios(NumObstaculos, Actual) :-
    Actual < NumObstaculos,
    tamanio_mapa(MaxX, MaxY),
    % Generar coordenadas aleatorias dentro del mapa
    random(0, MaxX, X),
    random(0, MaxY, Y),
    % Intentar agregar obstáculo (solo incrementa contador si tiene éxito)
    (   agregar_obstaculo(X, Y) ->
        Siguiente is Actual + 1
    ;   Siguiente = Actual
    ),
    generar_obstaculos_aleatorios(NumObstaculos, Siguiente).

% --------------------------------------------------------
% INFORMACIÓN DEL ENTORNO

% Obtener lista de todas las posiciones con obstáculos
% Retorna una lista de pares [X, Y]
obtener_obstaculos(Obstaculos) :-
    findall([X, Y], obstaculo(X, Y), Obstaculos).

% Contar número total de obstáculos en el mapa
contar_obstaculos(Cantidad) :-
    obtener_obstaculos(Obstaculos),
    length(Obstaculos, Cantidad).

% Limpiar todos los obstáculos del mapa
limpiar_obstaculos :-
    retractall(obstaculo(_, _)).

% --------------------------------------------------------
% UTILIDADES DE DISTANCIA

% Calcular distancia Manhattan entre dos puntos
% Es la suma de las diferencias absolutas en cada coordenada
calcular_distancia_manhattan(X1, Y1, X2, Y2, Distancia) :-
    Distancia is abs(X1 - X2) + abs(Y1 - Y2).

% Calcular distancia euclidiana entre dos puntos
% Es la distancia en línea recta usando el teorema de Pitágoras
calcular_distancia_euclidiana(X1, Y1, X2, Y2, Distancia) :-
    DeltaX is X1 - X2,
    DeltaY is Y1 - Y2,
    Distancia is sqrt(DeltaX * DeltaX + DeltaY * DeltaY).

% Obtener distancia Manhattan desde una posición hasta la casa
distancia_a_casa(X, Y, Distancia) :-
    posicion_casa(CasaX, CasaY),
    calcular_distancia_manhattan(X, Y, CasaX, CasaY, Distancia).

% Función de distancia genérica (usa Manhattan por defecto)
calcular_distancia(X1, Y1, X2, Y2, Distancia) :-
    calcular_distancia_manhattan(X1, Y1, X2, Y2, Distancia).

% --------------------------------------------------------
% VERIFICACIÓN DEL MAPA

% Verificar si el mapa está correctamente configurado
mapa_valido :-
    tamanio_mapa(X, Y),
    X > 0, Y > 0,
    posicion_casa(CasaX, CasaY),
    posicion_valida(CasaX, CasaY),
    \+ hay_obstaculo(CasaX, CasaY).