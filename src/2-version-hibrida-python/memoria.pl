
% PREDICADOS DINÁMICOS PARA MEMORIA

% Memoria de obstáculos encontrados
:- dynamic(memoria_obstaculo/3).  % memoria_obstaculo(X, Y, Direccion)

% Manejo de posiciones visitadas con contador
:- dynamic(posicion_visitada/3).  % posicion_visitada(X, Y, Veces)

% Zonas problemáticas (donde se detectan ciclos frecuentes)
:- dynamic(zona_problematica/3).  % zona_problematica(X, Y, Tiempo)

% Historial de movimientos recientes para detectar ciclos
:- dynamic(historial_posiciones/1).  % historial_posiciones(ListaPosiciones)

% Valores de refuerzo para aprendizaje
:- dynamic(valor_refuerzo/4).  % valor_refuerzo(X, Y, Direccion, Valor)

% --------------------------------------------------------
% MEMORIA DE OBSTÁCULOS

% Recordar un obstáculo encontrado para evitarlo en el futuro
% Se llama cuando el borracho intenta moverse y encuentra un obstáculo
recordar_obstaculo(X, Y, Direccion) :-
    calcular_nueva_posicion(X, Y, Direccion, ObstaculoX, ObstaculoY),
    % Solo recordar si no está ya en memoria
    \+ memoria_obstaculo(ObstaculoX, ObstaculoY, Direccion),
    assert(memoria_obstaculo(ObstaculoX, ObstaculoY, Direccion)).

% Verificar si se recuerda un obstáculo en cierta dirección
se_recuerda_obstaculo(X, Y, Direccion) :-
    calcular_nueva_posicion(X, Y, Direccion, ObstaculoX, ObstaculoY),
    memoria_obstaculo(ObstaculoX, ObstaculoY, Direccion).

% Obtener todos los obstáculos recordados
obtener_obstaculos_recordados(ObstaculosRecordados) :-
    findall([X,Y,Dir], memoria_obstaculo(X, Y, Dir), ObstaculosRecordados).

% --------------------------------------------------------
%  POSICIONES VISITADAS

% Registrar visita a una posición y contar las veces que se visitó
% Se llama cada vez que el borracho se mueve a una nueva posición
registrar_visita(X, Y) :-
    (   posicion_visitada(X, Y, Veces) ->
        % Ya visitada - incrementar contador
        retract(posicion_visitada(X, Y, Veces)),
        NuevasVeces is Veces + 1,
        assert(posicion_visitada(X, Y, NuevasVeces)),
        % Marcar como zona problemática si se visita demasiado
        (   NuevasVeces >= 4 ->
            marcar_zona_problematica(X, Y)
        ;   true
        )
    ;   % Primera visita
        assert(posicion_visitada(X, Y, 1))
    ).

% Verificar si una posición ha sido muy visitada (umbral: 3 veces)
posicion_muy_visitada(X, Y) :-
    posicion_visitada(X, Y, Veces),
    Veces >= 3.

% Obtener número de veces que se visitó una posición (0 si nunca)
veces_visitada(X, Y, Veces) :-
    (   posicion_visitada(X, Y, Veces) -> true
    ;   Veces = 0
    ).

% Obtener todas las posiciones visitadas con sus contadores
obtener_posiciones_visitadas(PosicionesVisitadas) :-
    findall([X,Y,Veces], posicion_visitada(X, Y, Veces), PosicionesVisitadas).

% --------------------------------------------------------
% GESTIÓN DE ZONAS PROBLEMÁTICAS

% Marcar una zona como problemática (donde ocurren ciclos)
marcar_zona_problematica(X, Y) :-
    pasos_totales(Tiempo),  % Usar pasos como timestamp
    (   zona_problematica(X, Y, _) -> 
        true  % Ya está marcada
    ;   assert(zona_problematica(X, Y, Tiempo))
    ).

% Verificar si una zona es problemática
es_zona_problematica(X, Y) :-
    zona_problematica(X, Y, _).

% Verificar si una posición está cerca de zona problemática (radio 1)
posicion_en_area_problematica(X, Y) :-
    zona_problematica(ZX, ZY, _),
    abs(X - ZX) =< 1,
    abs(Y - ZY) =< 1.

% Obtener distancia a la zona problemática más cercana
distancia_a_zona_problematica_mas_cercana(X, Y, DistanciaMinima) :-
    findall(Dist, 
            (zona_problematica(ZX, ZY, _), 
             calcular_distancia_manhattan(X, Y, ZX, ZY, Dist)), 
            Distancias),
    (   Distancias \= [] ->
        min_list(Distancias, DistanciaMinima)
    ;   DistanciaMinima = 100  % Si no hay zonas problemáticas
    ).

% --------------------------------------------------------
% HISTORIAL DE POSICIONES PARA DETECCIÓN DE CICLOS

% Actualizar historial de posiciones (mantener últimas 8)
actualizar_historial_posicion(X, Y) :-
    (   historial_posiciones(Historial) ->
        retract(historial_posiciones(Historial))
    ;   Historial = []
    ),
    % Agregar nueva posición al inicio
    append([[X, Y]], Historial, HistorialTemp),
    % Mantener solo las últimas 8 posiciones
    (   length(HistorialTemp, Longitud), Longitud > 8 ->
        length(HistorialNuevo, 8),
        append(HistorialNuevo, _, HistorialTemp),
        assert(historial_posiciones(HistorialNuevo))
    ;   assert(historial_posiciones(HistorialTemp))
    ).

% Verificar si una posición fue visitada recientemente
posicion_visitada_recientemente(X, Y) :-
    historial_posiciones(Historial),
    member([X, Y], Historial).

% --------------------------------------------------------
% DETECCIÓN DE CICLOS MEJORADA

% Detectar si está oscilando entre dos posiciones
detectar_oscilacion :-
    historial_posiciones(Historial),
    length(Historial, Longitud),
    Longitud >= 4,
    Historial = [Pos1, Pos2, Pos1, Pos2|_].

% Detectar ciclo triangular (A->B->C->A)
detectar_ciclo_triangular :-
    historial_posiciones(Historial),
    length(Historial, Longitud),
    Longitud >= 6,
    Historial = [Pos1, Pos2, Pos3, Pos1, Pos2, Pos3|_].

% Detectar estancamiento en área pequeña
detectar_estancamiento :-
    historial_posiciones(Historial),
    length(Historial, Longitud),
    Longitud >= 6,
    posiciones_unicas(Historial, PosicionesUnicas),
    length(PosicionesUnicas, NumUnicas),
    NumUnicas =< 3.  % Solo 3 posiciones únicas o menos

% Contar posiciones únicas en historial
posiciones_unicas([], []).
posiciones_unicas([Pos|Resto], [Pos|Unicas]) :-
    \+ member(Pos, Resto),
    !,
    posiciones_unicas(Resto, Unicas).
posiciones_unicas([_|Resto], Unicas) :-
    posiciones_unicas(Resto, Unicas).

% Detectar cualquier tipo de ciclo
detectar_ciclo :-
    (   detectar_oscilacion ;
        detectar_ciclo_triangular ;
        detectar_estancamiento
    ).

% --------------------------------------------------------
% SISTEMA DE VALORES DE REFUERZO

% Actualizar valor de refuerzo basado en resultado del movimiento
actualizar_refuerzo(X, Y, Direccion, Resultado) :-
    % Obtener valor actual o 0 si no existe
    (   valor_refuerzo(X, Y, Direccion, ValorActual) ->
        retract(valor_refuerzo(X, Y, Direccion, ValorActual))
    ;   ValorActual = 0
    ),
    
    % Verificar si el movimiento lleva a zona problemática
    calcular_nueva_posicion(X, Y, Direccion, NuevoX, NuevoY),
    (   posicion_en_area_problematica(NuevoX, NuevoY) ->
        ResultadoModificado = fallo  % Penalizar zonas problemáticas
    ;   ResultadoModificado = Resultado
    ),
    
    % Calcular nuevo valor
    calcular_nuevo_valor(ValorActual, ResultadoModificado, NuevoValor),
    assert(valor_refuerzo(X, Y, Direccion, NuevoValor)).

% Calcular nuevo valor de refuerzo según el resultado
calcular_nuevo_valor(ValorActual, exito, NuevoValor) :-
    NuevoValor is ValorActual + 3.  % Gran recompensa por éxito

calcular_nuevo_valor(ValorActual, progreso, NuevoValor) :-
    NuevoValor is ValorActual + 1.  % Recompensa por progreso

calcular_nuevo_valor(ValorActual, fallo, NuevoValor) :-
    NuevoValor is ValorActual - 2.  % Penalización por fallo

calcular_nuevo_valor(ValorActual, ciclo_detectado, NuevoValor) :-
    NuevoValor is ValorActual - 5.  % Fuerte penalización por ciclos

% Obtener valor de refuerzo de un movimiento (0 si no existe)
obtener_valor_refuerzo(X, Y, Direccion, Valor) :-
    (   valor_refuerzo(X, Y, Direccion, ValorBase) ->
        ValorInicial = ValorBase
    ;   ValorInicial = 0
    ),
    
    % Aplicar penalización adicional si lleva a zona problemática
    calcular_nueva_posicion(X, Y, Direccion, NuevoX, NuevoY),
    (   posicion_en_area_problematica(NuevoX, NuevoY) ->
        Valor is ValorInicial - 10
    ;   Valor = ValorInicial
    ).

% Obtener mejor movimiento según valores de refuerzo
mejor_movimiento_refuerzo(X, Y, MejorMovimiento) :-
    obtener_movimientos_validos(X, Y, MovimientosValidos),
    MovimientosValidos \= [],
    % Filtrar movimientos problemáticos primero
    filtrar_movimientos_problematicos(X, Y, MovimientosValidos, MovimientosSeguros),
    (   MovimientosSeguros \= [] ->
        evaluar_movimientos_refuerzo(X, Y, MovimientosSeguros, MejorMovimiento, _)
    ;   % Si no hay seguros, usar todos
        evaluar_movimientos_refuerzo(X, Y, MovimientosValidos, MejorMovimiento, _)
    ).

% Filtrar movimientos que no llevan a zonas problemáticas
filtrar_movimientos_problematicos(_, _, [], []).
filtrar_movimientos_problematicos(X, Y, [Mov|Resto], [Mov|Filtrados]) :-
    calcular_nueva_posicion(X, Y, Mov, NuevoX, NuevoY),
    \+ posicion_en_area_problematica(NuevoX, NuevoY),
    !,
    filtrar_movimientos_problematicos(X, Y, Resto, Filtrados).
filtrar_movimientos_problematicos(X, Y, [_|Resto], Filtrados) :-
    filtrar_movimientos_problematicos(X, Y, Resto, Filtrados).

% Evaluar movimientos y encontrar el de mayor valor de refuerzo
evaluar_movimientos_refuerzo(X, Y, [Mov], Mov, Valor) :-
    obtener_valor_refuerzo(X, Y, Mov, Valor).

evaluar_movimientos_refuerzo(X, Y, [Mov1|Resto], MejorMovimiento, MejorValor) :-
    obtener_valor_refuerzo(X, Y, Mov1, Valor1),
    evaluar_movimientos_refuerzo(X, Y, Resto, MejorResto, ValorResto),
    (   Valor1 > ValorResto ->
        MejorMovimiento = Mov1, MejorValor = Valor1
    ;   MejorMovimiento = MejorResto, MejorValor = ValorResto
    ).

% --------------------------------------------------------
% APRENDIZAJE ADAPTATIVO

% Evaluar resultado de un movimiento y aprender
evaluar_y_aprender(XViejo, YViejo, Direccion, XNuevo, YNuevo) :-
    % Calcular si hubo progreso hacia la casa
    distancia_a_casa(XViejo, YViejo, DistanciaVieja),
    distancia_a_casa(XNuevo, YNuevo, DistanciaNueva),
    
    % Determinar resultado del movimiento
    (   detectar_ciclo ->
        Resultado = ciclo_detectado
    ;   DistanciaNueva =:= 0 ->
        Resultado = exito
    ;   DistanciaNueva < DistanciaVieja ->
        Resultado = progreso
    ;   Resultado = fallo
    ),
    
    % Actualizar aprendizaje
    actualizar_refuerzo(XViejo, YViejo, Direccion, Resultado),
    
    % Registrar visita a nueva posición
    registrar_visita(XNuevo, YNuevo),
    
    % Actualizar historial para detección de ciclos
    actualizar_historial_posicion(XNuevo, YNuevo).

% --------------------------------------------------------
% ESTRATEGIAS BASADAS EN MEMORIA

% Sugerir dirección de exploración hacia zonas menos visitadas
sugerir_exploracion(X, Y, DireccionSugerida) :-
    obtener_movimientos_validos(X, Y, MovimientosValidos),
    evaluar_direcciones_exploracion(X, Y, MovimientosValidos, DireccionSugerida).

% Evaluar direcciones para exploración
evaluar_direcciones_exploracion(X, Y, [Mov], Mov) :- !.
evaluar_direcciones_exploracion(X, Y, [Mov1|Resto], MejorDireccion) :-
    calcular_nueva_posicion(X, Y, Mov1, X1, Y1),
    evaluar_calidad_exploracion(X1, Y1, Calidad1),
    evaluar_direcciones_exploracion(X, Y, Resto, MejorResto),
    calcular_nueva_posicion(X, Y, MejorResto, X2, Y2),
    evaluar_calidad_exploracion(X2, Y2, Calidad2),
    (   Calidad1 > Calidad2 ->
        MejorDireccion = Mov1
    ;   MejorDireccion = MejorResto
    ).

% Evaluar calidad de una posición para exploración
evaluar_calidad_exploracion(X, Y, Calidad) :-
    veces_visitada(X, Y, Veces),
    (   es_zona_problematica(X, Y) ->
        Calidad is -100  % Muy malo
    ;   posicion_en_area_problematica(X, Y) ->
        Calidad is -50   % Malo
    ;   Calidad is 20 - (Veces * 3)  % Mejor si menos visitada
    ).

% --------------------------------------------------------
% VERIFICACIONES DE EXPERIENCIA

% Verificar si el borracho tiene experiencia suficiente
tiene_experiencia :-
    findall(_, memoria_obstaculo(_, _, _), Obstaculos),  % Cuenta los obstáculos recordados
    findall(_, zona_problematica(_, _, _), Zonas),  % Cuenta las zonas problematicas
    findall(_, valor_refuerzo(_, _, _, _), Valores),  % Cuenta los valores de refuerzo, 
    length(Obstaculos, NumObstaculos),
    length(Zonas, NumZonas),
    length(Valores, NumValores),
    TotalExperiencia is NumObstaculos + NumZonas + NumValores,
    TotalExperiencia >= 5.

% --------------------------------------------------------
% LIMPIEZA DE MEMORIA

% Limpiar toda la memoria de aprendizaje
limpiar_memoria :-
    retractall(memoria_obstaculo(_, _, _)),
    retractall(posicion_visitada(_, _, _)),
    retractall(zona_problematica(_, _, _)),
    retractall(historial_posiciones(_)),
    retractall(valor_refuerzo(_, _, _, _)).