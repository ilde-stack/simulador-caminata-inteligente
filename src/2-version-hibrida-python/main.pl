
% Módulos utilizados

% Cargar todos los módulos del sistema
:- include('entorno.pl').     % Gestión del mapa y obstáculos
:- include('movimiento.pl').  % Lógica de movimientos
:- include('estado.pl').      % Estado del borracho
:- include('memoria.pl').     % Sistema de memoria y aprendizaje
:- include('estrategia.pl').  % Estrategias de decisión

% --------------------------------------------------------
% interfaz para python

% Inicializar el juego completo
% Punto de entrada principal llamado desde Python
inicializar_juego(X, Y, NumObstaculos) :-
    % Validar parámetros de entrada
    posicion_valida(X, Y),
    \+ es_casa(X, Y),
    NumObstaculos >= 0,
    limpiar_juego_completo, % Limpiar completamente el estado anterior
    inicializar_estado(X, Y), % Inicializar estado del borracho en posición especificada
    generar_obstaculos_aleatorios(NumObstaculos), % Generar obstáculos aleatorios
    
    % Asegurar que la casa no tenga obstáculo
    posicion_casa(CasaX, CasaY),
    (retract(obstaculo(CasaX, CasaY)) ; true).

% Ejecutar un paso del juego
% Retorna el resultado del paso en formato [Tipo, X, Y, Movimiento, Estrategia]
ejecutar_paso(Resultado) :-
    % Verificar condiciones de victoria o fin de juego
    (   ha_llegado_a_casa ->
        posicion_actual(X, Y),
        Resultado = [victoria, X, Y, '', 'victoria']
    ;   juego_terminado(Razon) ->
        posicion_actual(X, Y),
        Resultado = [fin_juego, X, Y, Razon, 'fin']
    ;   % Continuar juego normal
        ejecutar_paso_normal(Resultado)
    ).

% Ejecutar paso normal del juego (cuando continúa la partida)
ejecutar_paso_normal(Resultado) :-
    % Obtener posición actual antes del movimiento
    posicion_actual(XAnterior, YAnterior),
    
    % Seleccionar movimiento usando estrategias mejoradas
    seleccionar_movimiento_mejorado(Movimiento),
    
    % Intentar realizar el movimiento
    realizar_movimiento(Movimiento, ResultadoMovimiento),
    
    % Obtener nueva posición después del movimiento
    posicion_actual(XNuevo, YNuevo),
    
    % Aprender del movimiento realizado
    (   ResultadoMovimiento = exito ->
        evaluar_y_aprender(XAnterior, YAnterior, Movimiento, XNuevo, YNuevo)
    ;   % También recordar obstáculos cuando chocan
        recordar_obstaculo(XAnterior, YAnterior, Movimiento)
    ),
    
    % Ajustar estrategia dinámicamente
    ajustar_estrategia_dinamica,
    
    % Obtener descripción de estrategia actual
    estrategia_actual(DescripcionEstrategia),
    
    % Preparar resultado para Python
    Resultado = [ResultadoMovimiento, XNuevo, YNuevo, Movimiento, DescripcionEstrategia].

% --------------------------------------------------------
% consultas que va a realizar python

% Obtener estado completo del juego para visualización
obtener_estado_completo(Estado) :-
    % Información del borracho
    info_estado(InfoBorracho),
    
    % Información del mapa
    tamanio_mapa(MaxX, MaxY),
    posicion_casa(CasaX, CasaY),
    obtener_obstaculos(Obstaculos),
    
    % Información de aprendizaje
    obtener_obstaculos_recordados(MemoriaObstaculos),
    obtener_posiciones_visitadas(PosicionesVisitadas),
    findall([X,Y,Dir,Valor], valor_refuerzo(X, Y, Dir, Valor), ValoresRefuerzo),
    
    % Combinar toda la información
    Estado = [
        mapa([MaxX, MaxY]),
        casa([CasaX, CasaY]),
        borracho(InfoBorracho),
        obstaculos(Obstaculos),
        memoria_obstaculos(MemoriaObstaculos),
        posiciones_visitadas(PosicionesVisitadas),
        valores_refuerzo(ValoresRefuerzo)
    ].

% Obtener información específica del borracho (para Python)
consultar_borracho(X, Y, Pasos, Desorientado, Energia, Distancia) :-
    (   estado_borracho(X, Y, Pasos, Distancia, Energia) -> 
        Desorientado = false  % Siempre false ya que no hay desorientación
    ;   % Valores por defecto si no hay estado
        X = 0, Y = 0, Pasos = 0, Desorientado = false, Energia = 100, Distancia = 0
    ).

% Obtener posición inicial del Bar para Python
consultar_posicion_inicial(X, Y) :-
    (   posicion_inicial(X, Y) -> 
        true
    ;   % Si no hay posición inicial definida, retornar -1, -1
        X = -1, Y = -1
    ).

% Verificar si posición específica tiene obstáculo, para python
consultar_obstaculo(X, Y, TieneObstaculo) :-
    (   hay_obstaculo(X, Y) -> TieneObstaculo = true
    ;   TieneObstaculo = false
    ).

% Obtener descripción de estrategia actual (para Python)
estrategia_actual(Descripcion) :-
    (   catch(determinar_estrategia(Estrategia), _, fail) ->
        descripcion_estrategia(Estrategia, Descripcion)
    ;   Descripcion = 'Estrategia no disponible'
    ).

% --------------------------------------------------------
% Limpiar memoria entre partidas

% Limpiar completamente el juego 
limpiar_juego_completo :-
    limpiar_obstaculos,      % Limpiar obstáculos del mapa
    reiniciar_estado,        % Reiniciar estado del borracho
    limpiar_memoria.         % Limpiar toda la memoria de aprendizaje

% Reiniciar solo el estado del borracho Y limpiar memoria
reiniciar_solo_borracho(X, Y) :-
    reiniciar_estado,
    limpiar_memoria,         % Cada partida empieza sin conocimiento
    inicializar_estado(X, Y).

% --------------------------------------------------------
% PREDICADOS ADICIONALES PARA CONTROL DE MEMORIA

% Limpiar solo la memoria (mantener mapa actual)
resetear_memoria_completa :-
    limpiar_memoria.

% Verificar si el borracho tiene algún conocimiento
tiene_conocimiento_previo :-
    (   memoria_obstaculo(_, _, _) ; 
        posicion_visitada(_, _, _) ; 
        valor_refuerzo(_, _, _, _) ; 
        zona_problematica(_, _, _)
    ).

% Mostrar estadísticas de memoria actual
estadisticas_memoria(Stats) :-
    findall(_, memoria_obstaculo(_, _, _), ObstaculosRecordados),
    findall(_, posicion_visitada(_, _, _), PosicionesVisitadas),
    findall(_, valor_refuerzo(_, _, _, _), ValoresRefuerzo),
    findall(_, zona_problematica(_, _, _), ZonasProblematicas),
    
    length(ObstaculosRecordados, NumObstaculos),
    length(PosicionesVisitadas, NumPosiciones),
    length(ValoresRefuerzo, NumValores),
    length(ZonasProblematicas, NumZonas),
    
    Stats = [
        obstaculos_recordados(NumObstaculos),
        posiciones_visitadas(NumPosiciones),
        valores_refuerzo(NumValores),
        zonas_problematicas(NumZonas)
    ].