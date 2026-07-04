
from pyswip import Prolog
from visualizacion import VisualizadorBorracho
import time
import sys
import random
from typing import Dict, Any, Optional

class ControladorJuego:
    
    def __init__(self):
        # Inicializar Prolog
        self.prolog = Prolog()
        
        # Cargar archivos Prolog
        try:
            self.cargar_archivos_prolog()
        except Exception as e:
            print(f"Error cargando archivos Prolog: {e}")
            sys.exit(1)
        
        # Configuración del mapa y juego
        self.mapa_ancho = 20           # Ancho del mapa en celdas
        self.mapa_alto = 20            # Alto del mapa en celdas
        self.tamano_celda = 30         # Tamaño de cada celda en píxeles
        self.obstaculos_por_defecto = 50  # Número por defecto de obstáculos
        self.obstaculos_min = 30       # Mínimo de obstáculos
        self.obstaculos_max = 100      # Máximo de obstáculos
        
        # Estado de control del juego
        self.juego_pausado = False     # Control de pausa
        self.juego_terminado = False   # Indicador de fin de juego
        self.modo_automatico = True    # Reinicio automático entre juegos
        
        self.numero_partida = 0
        self.tiempo_inicio_partida = 0
        
        # Inicializar visualizador gráfico
        self.visualizador = VisualizadorBorracho(
            self.mapa_ancho, 
            self.mapa_alto, 
            self.tamano_celda
        )
        
        print("Controlador inicializado correctamente")
    
    def cargar_archivos_prolog(self):
        try:
            # main.pl debe incluir todos los demás archivos .pl
            self.prolog.consult("main.pl")
            print("Cargado: main.pl (con todos los módulos)")
        except Exception as e:
            print(f"Error cargando main.pl: {e}")
            raise
    
    def limpiar_memoria_completa(self):
        try:
            consulta = "resetear_memoria_completa"
            list(self.prolog.query(consulta))
            print("Memoria de aprendizaje completamente limpiada")
        except Exception as e:
            print(f"Error limpiando memoria: {e}")
    
    def inicializar_juego(self, pos_x: Optional[int] = None, pos_y: Optional[int] = None, 
                         num_obstaculos: Optional[int] = None) -> bool:
        try:
            # Incrementar contador de partidas
            self.numero_partida += 1
            print(f"\n=== INICIANDO PARTIDA #{self.numero_partida} ===")
            self.limpiar_memoria_completa()
            
            # Generar posición inicial válida si no se especifica
            if pos_x is None or pos_y is None:
                pos_x, pos_y = self.generar_posicion_inicial_valida()
            
            # Usar configuración por defecto si no se especifica
            if num_obstaculos is None:
                num_obstaculos = self.obstaculos_por_defecto
            
            # Validar que el número de obstáculos esté en rango válido
            num_obstaculos = max(self.obstaculos_min, min(self.obstaculos_max, num_obstaculos))
            
            # Llamar a Prolog para inicializar el estado del juego
            consulta = f"inicializar_juego({pos_x}, {pos_y}, {num_obstaculos})"
            resultado = list(self.prolog.query(consulta))
            
            if resultado:
                print(f"Juego inicializado: Borracho en ({pos_x}, {pos_y}), {num_obstaculos} obstáculos")
                print("Borracho inicia SIN conocimiento previo")
                self.juego_terminado = False
                self.visualizador.limpiar_rastro()  # Limpiar rastro visual previo
                
                # Registrar inicio de partida
                self.tiempo_inicio_partida = time.time()
                return True
            else:
                print("Error inicializando el juego en Prolog")
                return False
                
        except Exception as e:
            print(f"Error en inicializar_juego: {e}")
            return False
    
    def generar_posicion_inicial_valida(self) -> tuple[int, int]:
        max_intentos = 50
        intentos = 0
        
        while intentos < max_intentos:
            # Generar coordenadas aleatorias dentro del mapa
            x = random.randint(1, self.mapa_ancho - 2)
            y = random.randint(1, self.mapa_alto - 2)
            
            # Verificar que no esté muy cerca de la casa
            casa_x, casa_y = self.mapa_ancho // 2, self.mapa_alto // 2
            if abs(x - casa_x) > 3 or abs(y - casa_y) > 3:
                return x, y
            
            intentos += 1
        
        # Si no encuentra posición después de muchos intentos, usar esquina
        return 2, 2
    
    def ejecutar_paso(self):
        try:
            # Consultar a Prolog para ejecutar un paso
            consulta = "ejecutar_paso(Resultado)"
            resultados = list(self.prolog.query(consulta))
            
            if resultados:
                resultado = resultados[0]['Resultado']
                tipo_resultado = resultado[0]  # Tipo: 'victoria', 'fin_juego', 'exito', etc.
                
                # Verificar si el juego terminó
                if tipo_resultado in ['victoria', 'fin_juego']:
                    self.juego_terminado = True
                    
                    if tipo_resultado == 'victoria':
                        print("El borracho llego a casa!")
                    else:
                        razon = resultado[3] if len(resultado) > 3 else "Desconocida"
                        print(f"Juego terminado: {razon}")
                
                # Actualizar dirección en visualizador si hay movimiento
                if len(resultado) > 3 and resultado[3]:
                    self.visualizador.actualizar_direccion(resultado[3])
                
                # Retornar información estructurada del paso
                return {
                    'tipo': tipo_resultado,
                    'posicion': (resultado[1], resultado[2]) if len(resultado) > 2 else None,
                    'movimiento': resultado[3] if len(resultado) > 3 else None,
                    'estrategia': resultado[4] if len(resultado) > 4 else "Desconocida"
                }
            else:
                return {'tipo': 'error', 'mensaje': 'No se pudo ejecutar paso en Prolog'}
                
        except Exception as e:
            print(f"Error ejecutando paso: {e}")
            return {'tipo': 'error', 'mensaje': str(e)}
    
    def obtener_estado_completo(self):
        estado = {}
        
        try:
            # Obtener información del borracho (posición, pasos, estado)
            consulta_borracho = "consultar_borracho(X, Y, Pasos, Desorientado, Energia, Distancia)"
            resultado_borracho = list(self.prolog.query(consulta_borracho))
            
            if resultado_borracho:
                r = resultado_borracho[0]
                estado['borracho'] = {
                    'x': r['X'],
                    'y': r['Y'],
                    'pasos': r['Pasos'],
                    'desorientado': False,  # Siempre False - sin desorientación
                    'energia': r['Energia'],
                    'distancia': r['Distancia']
                }
            else:
                estado['borracho'] = self.estado_borracho_por_defecto()
            
            # Obtener obstáculos del mapa
            consulta_obs = "obtener_obstaculos(Obstaculos)"
            resultado_obs = list(self.prolog.query(consulta_obs))
            
            if resultado_obs:
                estado['obstaculos'] = resultado_obs[0]['Obstaculos']
            else:
                estado['obstaculos'] = []
            
            # Obtener memoria de obstáculos recordados
            try:
                consulta_mem = "obtener_obstaculos_recordados(Memoria)"
                resultado_mem = list(self.prolog.query(consulta_mem))
                if resultado_mem:
                    estado['memoria_obstaculos'] = resultado_mem[0]['Memoria']
                else:
                    estado['memoria_obstaculos'] = []
            except:
                estado['memoria_obstaculos'] = []
            
            # Obtener posiciones visitadas por el borracho
            try:
                consulta_pos = "obtener_posiciones_visitadas(Posiciones)"
                resultado_pos = list(self.prolog.query(consulta_pos))
                if resultado_pos:
                    estado['posiciones_visitadas'] = resultado_pos[0]['Posiciones']
                else:
                    estado['posiciones_visitadas'] = []
            except:
                estado['posiciones_visitadas'] = []
            
            # Obtener posición inicial 
            try:
                consulta_var = "consultar_posicion_inicial(X, Y)"
                resultado_var = list(self.prolog.query(consulta_var))
                if resultado_var and resultado_var[0]['X'] != -1:
                    estado['posicion_inicial'] = [resultado_var[0]['X'], resultado_var[0]['Y']]
                else:
                    estado['posicion_inicial'] = None
            except:
                estado['posicion_inicial'] = None
                
            # Configurar posición de la casa (centro del mapa)
            estado['casa'] = [self.mapa_ancho // 2, self.mapa_alto // 2]
            estado['valores_refuerzo'] = []  # No visualizar valores de refuerzo
            
        except Exception as e:
            print(f"Error obteniendo estado: {e}")
            return self.estado_por_defecto()
        
        return estado
    
    def estado_borracho_por_defecto(self):
        return {
            'x': 0, 'y': 0, 'pasos': 0,
            'desorientado': False, 'energia': 100, 'distancia': 0
        }
    
    def estado_por_defecto(self):
        return {
            'mapa': [self.mapa_ancho, self.mapa_alto],
            'casa': [self.mapa_ancho // 2, self.mapa_alto // 2],
            'borracho': self.estado_borracho_por_defecto(),
            'obstaculos': [],
            'memoria_obstaculos': [],
            'posiciones_visitadas': [],
            'valores_refuerzo': []
        }
    
    def obtener_estrategia_actual(self):
        try:
            consulta = "estrategia_actual(Descripcion)"
            resultados = list(self.prolog.query(consulta))
            
            if resultados:
                return resultados[0]['Descripcion']
            else:
                return "Estrategia no disponible"
                
        except Exception as e:
            return f"Error obteniendo estrategia: {e}"
    
    def reiniciar_juego_automatico(self):
        print(f"\nReiniciando automaticamente (la memoria se borrara)...")
        
        # Generar parámetros aleatorios para el nuevo juego
        pos_x, pos_y = self.generar_posicion_inicial_valida()
        num_obstaculos = random.randint(self.obstaculos_min, self.obstaculos_max)
        
        # Reinicializar el juego 
        if self.inicializar_juego(pos_x, pos_y, num_obstaculos):
            print(f"Nuevo juego iniciado en ({pos_x}, {pos_y}) con {num_obstaculos} obstaculos")
        else:
            print("Error reiniciando el juego")
    
    def bucle_principal(self):
        
        # Inicializar primer juego
        if not self.inicializar_juego():
            print("No se pudo inicializar el primer juego")
            return
        
        ejecutando = True
        tiempo_ultimo_reinicio = time.time()
        
        while ejecutando:
            # Manejar eventos de pygame 
            eventos = self.visualizador.manejar_eventos()
            
            # Verificar si el usuario quiere salir
            if eventos['salir']:
                ejecutando = False
                continue
            
            # Manejar pausa/reanudación del juego
            if eventos['pausa']:
                self.juego_pausado = not self.juego_pausado
                estado_pausa = "PAUSADO" if self.juego_pausado else "REANUDADO"
                print(f"{estado_pausa}")
            
            # Ejecutar lógica del juego si no está pausado
            if not self.juego_pausado and not self.juego_terminado:
                resultado_paso = self.ejecutar_paso()
                
                # Manejar fin del juego (victoria o condición de terminación)
                if resultado_paso['tipo'] in ['victoria', 'fin_juego']:
                    print("Reiniciando en 2 segundos...")
                    time.sleep(2)
                    self.reiniciar_juego_automatico()
                    tiempo_ultimo_reinicio = time.time()
            
            # Obtener estado actual del juego desde Prolog
            estado = self.obtener_estado_completo()
            
            # Agregar información adicional al estado para el visualizador
            if 'borracho' in estado:
                estado['pasos'] = estado['borracho'].get('pasos', 0)
                estado['estrategia'] = self.obtener_estrategia_actual()
            
            # Agregar información de partida actual
            estado['numero_partida'] = self.numero_partida
            
            # Actualizar pantalla con el estado actual
            self.visualizador.actualizar_pantalla(estado)
            
            # Control de FPS (frames por segundo)
            self.visualizador.esperar_frame()
            
            # Reinicio automático si el juego se cuelga (sin progreso por mucho tiempo)
            tiempo_actual = time.time()
            if tiempo_actual - tiempo_ultimo_reinicio > 120:  # 2 minutos sin reinicio
                print("Reinicio automatico por tiempo limite")
                self.reiniciar_juego_automatico()
                tiempo_ultimo_reinicio = tiempo_actual
        
        # Limpiar y cerrar el visualizador
        self.visualizador.cerrar()
        print("Gracias por usar el Simulador del Borracho Inteligente!")


def main():
    try:
        controlador = ControladorJuego()
        # Ejecutar el bucle principal del juego
        controlador.bucle_principal()
            
    except KeyboardInterrupt:
        print("Simulacion interrumpida por el usuario")
    except Exception as e:
        print(f"Error fatal: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()