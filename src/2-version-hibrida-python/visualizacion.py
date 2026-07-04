
import pygame
import sys
from typing import Dict, List, Tuple, Optional

# Configuración de colores del sistema
class Colores:
    # Colores básicos
    NEGRO = (0, 0, 0)
    BLANCO = (255, 255, 255)
    GRIS = (128, 128, 128)
    GRIS_CLARO = (200, 200, 200)
    GRIS_OSCURO = (64, 64, 64)
    
    # Colores principales
    ROJO = (255, 0, 0)
    VERDE = (0, 255, 0)
    AZUL = (0, 0, 255)
    AMARILLO = (255, 255, 0)
    NARANJA = (255, 165, 0)
    VIOLETA = (128, 0, 128)
    CIAN = (0, 255, 255)
    ROSA = (255, 192, 203)
    MARRON = (139, 69, 19)
    
    # Colores específicos para elementos del juego
    CASA = (34, 139, 34)          # Verde bosque para la casa
    OBSTACULO = (105, 105, 105)   # Gris oscuro para obstáculos
    GRILLA = (220, 220, 220)      # Gris claro para grilla
    
    # Colores del borracho según su estado (sin desorientación)
    BORRACHO_NORMAL = (30, 144, 255)      # Azul para estado normal
    BORRACHO_CANSADO = (255, 215, 0)      # Dorado para cansado
    BORRACHO_CRITICO = (148, 0, 211)      # Violeta oscuro para crítico
    
    # Colores para memoria y aprendizaje
    MEMORIA_OBSTACULO = (220, 20, 60)     # Rojo para obstáculos recordados
    POSICION_VISITADA = (255, 255, 0, 80) # Amarillo transparente para posiciones visitadas
    ZONA_PROBLEMATICA = (255, 0, 0, 120)  # Rojo transparente para zonas problemáticas
    
    # Colores para rastro
    RASTRO_RECIENTE = (100, 149, 237)     # Azul acero
    RASTRO_ANTIGUO = (176, 196, 222)      # Azul claro

class VisualizadorBorracho:
    
    def __init__(self, ancho_mapa: int, alto_mapa: int, tamano_celda: int = 30):

        # Inicializar pygame
        pygame.init()
        
        # Configuración del mapa
        self.ancho_mapa = ancho_mapa
        self.alto_mapa = alto_mapa
        self.tamano_celda = tamano_celda
        
        # Configurar ventana principal
        self.ancho_juego = ancho_mapa * tamano_celda
        self.alto_juego = alto_mapa * tamano_celda
        self.ancho_panel = 300  # Panel lateral para información
        self.alto_controles = 80  # Área inferior para controles
        
        self.ancho_pantalla = self.ancho_juego + self.ancho_panel
        self.alto_pantalla = self.alto_juego + self.alto_controles
        
        # Crear ventana
        self.pantalla = pygame.display.set_mode((self.ancho_pantalla, self.alto_pantalla))
        pygame.display.set_caption("Caminata del borracho")
        
        # Configurar fuentes para texto
        self.fuente_pequena = pygame.font.Font(None, 16)
        self.fuente_normal = pygame.font.Font(None, 20)
        self.fuente_mediana = pygame.font.Font(None, 24)
        self.fuente_grande = pygame.font.Font(None, 32)
        self.fuente_titulo = pygame.font.Font(None, 28)
        
        # Estado de visualización 
        self.mostrar_rastro = True
        self.mostrar_memoria = True
        self.mostrar_posiciones_visitadas = True
        self.mostrar_numeros_visitas = False
        self.animacion_activa = True
        
        # Historia de posiciones para el rastro del borracho
        self.rastro_posiciones = []
        self.max_rastro = 40  # Máximo número de posiciones en el rastro
        
        # Control de animación y rendimiento
        self.reloj = pygame.time.Clock()
        self.fps = 2  # FPS inicial (frames por segundo)
        self.fps_min = 1
        self.fps_max = 60
        
        # Última dirección del borracho para mostrar flecha
        self._ultima_direccion = None
        
        print("Visualizador inicializado correctamente")
    
    def dibujar_grilla(self):

        # Líneas verticales de la grilla
        for x in range(0, self.ancho_juego + 1, self.tamano_celda):
            pygame.draw.line(self.pantalla, Colores.GRILLA,
                           (x, 0), (x, self.alto_juego))
        
        # Líneas horizontales de la grilla
        for y in range(0, self.alto_juego + 1, self.tamano_celda):
            pygame.draw.line(self.pantalla, Colores.GRILLA,
                           (0, y), (self.ancho_juego, y))
    
    def obtener_rect_celda(self, x: int, y: int) -> pygame.Rect:

        return pygame.Rect(
            x * self.tamano_celda,
            y * self.tamano_celda,
            self.tamano_celda,
            self.tamano_celda
        )
    
    def dibujar_casa(self, casa_x: int, casa_y: int):

        rect = self.obtener_rect_celda(casa_x, casa_y)
        
        # Fondo de la casa
        pygame.draw.rect(self.pantalla, Colores.CASA, rect)
        pygame.draw.rect(self.pantalla, Colores.NEGRO, rect, 2)
        
        # Dibujar símbolo de casa
        centro_x = rect.centerx
        centro_y = rect.centery
        
        # Techo (triángulo)
        puntos_techo = [
            (centro_x, centro_y - 10),
            (centro_x - 10, centro_y - 2),
            (centro_x + 10, centro_y - 2)
        ]
        pygame.draw.polygon(self.pantalla, Colores.ROJO, puntos_techo)
        
        # Pared (rectángulo)
        rect_pared = pygame.Rect(centro_x - 8, centro_y - 2, 16, 10)
        pygame.draw.rect(self.pantalla, Colores.MARRON, rect_pared)
        
        # Puerta
        rect_puerta = pygame.Rect(centro_x - 2, centro_y + 3, 4, 5)
        pygame.draw.rect(self.pantalla, Colores.GRIS_OSCURO, rect_puerta)
        
        # Texto "CASA" si la celda es lo suficientemente grande
        if self.tamano_celda >= 25:
            texto_casa = self.fuente_pequena.render("CASA", True, Colores.BLANCO)
            texto_rect = texto_casa.get_rect(center=(centro_x, rect.bottom - 8))
            self.pantalla.blit(texto_casa, texto_rect)
    
    def dibujar_obstaculos(self, obstaculos: List[List[int]]):

        for obs in obstaculos:
            if len(obs) >= 2:
                x, y = obs[0], obs[1]
                rect = self.obtener_rect_celda(x, y)
                
                # Dibujar obstáculo principal
                pygame.draw.rect(self.pantalla, Colores.OBSTACULO, rect)
                pygame.draw.rect(self.pantalla, Colores.NEGRO, rect, 2)
                
                
    
    def dibujar_posicion_inicial(self, estado_juego: Dict):

        if 'posicion_inicial' in estado_juego and estado_juego['posicion_inicial'] is not None:
            x, y = estado_juego['posicion_inicial']
            rect = self.obtener_rect_celda(x, y)
            
            # Dibujar fondo del marcador BAR con color distintivo
            pygame.draw.rect(self.pantalla, Colores.VIOLETA, rect, 4)
            
            # Crear superficie semi-transparente para el fondo del texto
            superficie_fondo = pygame.Surface((self.tamano_celda, self.tamano_celda))
            superficie_fondo.set_alpha(120)
            superficie_fondo.fill(Colores.VIOLETA)
            self.pantalla.blit(superficie_fondo, rect.topleft)
            
            # Dibujar texto "BAR" centrado
            texto_var = self.fuente_mediana.render("BAR", True, Colores.BLANCO)
            texto_rect = texto_var.get_rect(center=rect.center)
            
            # Fondo negro para el texto para mejor legibilidad
            pygame.draw.rect(self.pantalla, Colores.NEGRO, 
                           texto_rect.inflate(4, 2))
            
            # Texto principal
            self.pantalla.blit(texto_var, texto_rect)
            
            # Agregar pequeño indicador en la esquina
            esquina_rect = pygame.Rect(rect.right - 8, rect.top, 8, 8)
            pygame.draw.rect(self.pantalla, Colores.AMARILLO, esquina_rect)
            pygame.draw.rect(self.pantalla, Colores.NEGRO, esquina_rect, 1)
    
    def dibujar_rastro(self):
       
        if not self.mostrar_rastro or len(self.rastro_posiciones) < 2:
            return
        
        for i, pos in enumerate(self.rastro_posiciones[:-1]):  
            # Calcular intensidad del rastro (más reciente = más visible)
            factor_intensidad = (i + 1) / len(self.rastro_posiciones)
            
            # Interpolar color entre antiguo y reciente
            color_rastro = self.interpolar_color(
                Colores.RASTRO_ANTIGUO, 
                Colores.RASTRO_RECIENTE, 
                factor_intensidad
            )
            
            rect = self.obtener_rect_celda(pos[0], pos[1])
            
            # Crear superficie transparente para el rastro
            superficie_rastro = pygame.Surface((self.tamano_celda, self.tamano_celda))
            superficie_rastro.set_alpha(int(60 * factor_intensidad))
            superficie_rastro.fill(color_rastro)
            self.pantalla.blit(superficie_rastro, rect.topleft)
    
    def interpolar_color(self, color1: Tuple[int, int, int], color2: Tuple[int, int, int], 
                        factor: float) -> Tuple[int, int, int]:

        factor = max(0.0, min(1.0, factor))  # Asegurar que está en rango [0, 1]
        return (
            int(color1[0] + (color2[0] - color1[0]) * factor),
            int(color1[1] + (color2[1] - color1[1]) * factor),
            int(color1[2] + (color2[2] - color1[2]) * factor)
        )
    
    def obtener_color_borracho(self, energia: int) -> Tuple[int, int, int]:
        if energia < 20:
            return Colores.BORRACHO_CRITICO
        elif energia < 50:
            return Colores.BORRACHO_CANSADO
        else:
            return Colores.BORRACHO_NORMAL
    
    def dibujar_borracho(self, x: int, y: int, energia: int, distancia: int):

        rect = self.obtener_rect_celda(x, y)
        color = self.obtener_color_borracho(energia)
        
        # Dibujar círculo principal para el borracho
        centro = rect.center
        radio = min(self.tamano_celda // 3, 12)
        pygame.draw.circle(self.pantalla, color, centro, radio)
        pygame.draw.circle(self.pantalla, Colores.NEGRO, centro, radio, 2)
        
        # Dibujar indicador de dirección
        if self._ultima_direccion:
            self.dibujar_indicador_direccion(centro, self._ultima_direccion)
        
        # Dibujar barra de energía
        self.dibujar_barra_energia(rect, energia)
        
        # Agregar al rastro si es una nueva posición
        if not self.rastro_posiciones or self.rastro_posiciones[-1] != [x, y]:
            self.rastro_posiciones.append([x, y])
            if len(self.rastro_posiciones) > self.max_rastro:
                self.rastro_posiciones.pop(0)
    
    def dibujar_indicador_direccion(self, centro: Tuple[int, int], direccion: str):

        x, y = centro
        tamano = 8
        
        # Definir puntos de la flecha según la dirección
        if direccion == 'arriba':
            puntos = [(x, y-tamano), (x-4, y-2), (x+4, y-2)]
        elif direccion == 'abajo':
            puntos = [(x, y+tamano), (x-4, y+2), (x+4, y+2)]
        elif direccion == 'izquierda':
            puntos = [(x-tamano, y), (x-2, y-4), (x-2, y+4)]
        elif direccion == 'derecha':
            puntos = [(x+tamano, y), (x+2, y-4), (x+2, y+4)]
        else:
            return
        
        # Dibujar flecha
        pygame.draw.polygon(self.pantalla, Colores.BLANCO, puntos)
        pygame.draw.polygon(self.pantalla, Colores.NEGRO, puntos, 1)
    
    def dibujar_barra_energia(self, rect: pygame.Rect, energia: int):

        barra_ancho = rect.width - 6
        barra_alto = 4
        barra_x = rect.x + 3
        barra_y = rect.y - 8
        
        # Fondo de la barra
        pygame.draw.rect(self.pantalla, Colores.GRIS_OSCURO, 
                        (barra_x, barra_y, barra_ancho, barra_alto))
        
        # Calcular ancho de la barra de energía
        energia_normalizada = max(0, min(100, energia)) / 100
        ancho_energia = int(barra_ancho * energia_normalizada)
        
        # Color según nivel de energía
        if energia > 70:
            color_energia = Colores.VERDE
        elif energia > 40:
            color_energia = Colores.AMARILLO
        elif energia > 20:
            color_energia = Colores.NARANJA
        else:
            color_energia = Colores.ROJO
        
        # Dibujar barra de energía
        if ancho_energia > 0:
            pygame.draw.rect(self.pantalla, color_energia,
                           (barra_x, barra_y, ancho_energia, barra_alto))
    
    def dibujar_memoria_obstaculos(self, memoria_obstaculos: List[List]):
        if not self.mostrar_memoria or not memoria_obstaculos:
            return
        
        for mem in memoria_obstaculos:
            if len(mem) >= 2:
                x, y = mem[0], mem[1]
                rect = self.obtener_rect_celda(x, y)
                
                # Dibujar X roja para indicar obstáculo recordado
                pygame.draw.line(self.pantalla, Colores.MEMORIA_OBSTACULO,
                               (rect.left + 3, rect.top + 3), 
                               (rect.right - 3, rect.bottom - 3), 3)
                pygame.draw.line(self.pantalla, Colores.MEMORIA_OBSTACULO,
                               (rect.right - 3, rect.top + 3), 
                               (rect.left + 3, rect.bottom - 3), 3)
    
    def dibujar_posiciones_visitadas(self, posiciones_visitadas: List[List]):
        if not self.mostrar_posiciones_visitadas or not posiciones_visitadas:
            return
        
        # Encontrar máximo número de visitas para normalizar
        max_visitas = max([pos[2] for pos in posiciones_visitadas]) if posiciones_visitadas else 1
        
        for pos in posiciones_visitadas:
            if len(pos) >= 3:
                x, y, veces = pos[0], pos[1], pos[2]
                if veces > 1:  # Solo mostrar si visitó más de una vez
                    rect = self.obtener_rect_celda(x, y)
                    
                    # Calcular intensidad del color (más visitas = más intenso)
                    intensidad = min(veces / max_visitas, 1.0)
                    alpha = int(60 + 100 * intensidad)  # Transparencia variable
                    
                    # Crear superficie transparente
                    superficie_visita = pygame.Surface((self.tamano_celda, self.tamano_celda))
                    superficie_visita.set_alpha(alpha)
                    superficie_visita.fill(Colores.AMARILLO)
                    self.pantalla.blit(superficie_visita, rect.topleft)
                    
                    # Mostrar número de visitas si está habilitado
                    if self.mostrar_numeros_visitas and veces > 2:
                        texto = self.fuente_pequena.render(str(veces), True, Colores.NEGRO)
                        texto_rect = texto.get_rect(center=rect.center)
                        self.pantalla.blit(texto, texto_rect)
    
    def dibujar_panel_informacion(self, info_borracho: Dict, estrategia: str, pasos: int):
        panel_x = self.ancho_juego + 10
        panel_y = 10
        
        # Fondo del panel
        panel_rect = pygame.Rect(self.ancho_juego, 0, self.ancho_panel, self.alto_juego)
        pygame.draw.rect(self.pantalla, Colores.GRIS_CLARO, panel_rect)
        pygame.draw.rect(self.pantalla, Colores.GRIS, panel_rect, 2)
        
        # Título del panel
        titulo = self.fuente_titulo.render("INFORMACION", True, Colores.NEGRO)
        self.pantalla.blit(titulo, (panel_x, panel_y))
        
        y_actual = panel_y + 40
        
        # Información del borracho (sin desorientación)
        info_textos = [
            f"Posicion: ({info_borracho.get('x', 0)}, {info_borracho.get('y', 0)})",
            f"Pasos: {pasos}",
            f"Energia: {info_borracho.get('energia', 0)}%",
            f"Distancia: {info_borracho.get('distancia', 0)}",
            f"Estado: Normal",  # Siempre normal, sin desorientación
            f"Estrategia:",
            f"   {estrategia}",
        ]
        
        for texto in info_textos:
            if texto.startswith("   "):  # Estrategia (indentada)
                superficie_texto = self.fuente_pequena.render(texto, True, Colores.GRIS_OSCURO)
            else:
                superficie_texto = self.fuente_normal.render(texto, True, Colores.NEGRO)
            self.pantalla.blit(superficie_texto, (panel_x, y_actual))
            y_actual += 22
        
        # Leyenda de colores
        y_actual += 20
        leyenda_titulo = self.fuente_mediana.render("Datos", True, Colores.NEGRO)
        self.pantalla.blit(leyenda_titulo, (panel_x, y_actual))
        y_actual += 30
        
        leyenda_items = [
            (Colores.CASA, "Casa"),
            (Colores.OBSTACULO, "Obstaculo"),
            (Colores.VIOLETA, "BAR"),
            (Colores.BORRACHO_NORMAL, "Normal"),
            (Colores.BORRACHO_CANSADO, "Cansado"),
            (Colores.BORRACHO_CRITICO, "Critico"),
            (Colores.MEMORIA_OBSTACULO, "Recordado"),
            (Colores.AMARILLO, "Visitado"),
        ]
        
        for color, descripcion in leyenda_items:
            # Dibujar cuadrito de color
            pygame.draw.rect(self.pantalla, color, (panel_x, y_actual, 15, 15))
            pygame.draw.rect(self.pantalla, Colores.NEGRO, (panel_x, y_actual, 15, 15), 1)
            
            # Texto de descripción
            texto_leyenda = self.fuente_pequena.render(descripcion, True, Colores.NEGRO)
            self.pantalla.blit(texto_leyenda, (panel_x + 20, y_actual + 2))
            y_actual += 18
    
    def dibujar_controles(self):

        controles_y = self.alto_juego + 10
        
        # Fondo del área de controles
        controles_rect = pygame.Rect(0, self.alto_juego, self.ancho_pantalla, self.alto_controles)
        pygame.draw.rect(self.pantalla, Colores.GRIS_CLARO, controles_rect)
        pygame.draw.rect(self.pantalla, Colores.GRIS, controles_rect, 2)
        
        controles_texto = [
            "CONTROLES: ESPACIO = Pausa | Q = Salir",
            
            f"FPS: {self.fps}"
        ]
        
        for i, texto in enumerate(controles_texto):
            superficie = self.fuente_pequena.render(texto, True, Colores.NEGRO)
            self.pantalla.blit(superficie, (10, controles_y + i * 20))
    
    def actualizar_pantalla(self, estado_juego: Dict):
        # Limpiar pantalla
        self.pantalla.fill(Colores.BLANCO)
        
        # Dibujar grilla base
        self.dibujar_grilla()
        
        # Dibujar rastro si está habilitado
        self.dibujar_rastro()
        
        # Dibujar posiciones visitadas
        if 'posiciones_visitadas' in estado_juego:
            self.dibujar_posiciones_visitadas(estado_juego['posiciones_visitadas'])
        
        # Dibujar obstáculos del mapa
        if 'obstaculos' in estado_juego:
            self.dibujar_obstaculos(estado_juego['obstaculos'])
        
        # Dibujar memoria de obstáculos
        if 'memoria_obstaculos' in estado_juego:
            self.dibujar_memoria_obstaculos(estado_juego['memoria_obstaculos'])
        
        # Dibujar casa
        if 'casa' in estado_juego:
            casa_x, casa_y = estado_juego['casa']
            self.dibujar_casa(casa_x, casa_y)
        
        # Dibujar posición inicial (BAR) si está disponible
        self.dibujar_posicion_inicial(estado_juego)
        
        # Dibujar borracho (sin parámetro de desorientación)
        if 'borracho' in estado_juego:
            info = estado_juego['borracho']
            self.dibujar_borracho(
                info['x'], info['y'],
                info.get('energia', 100),
                info.get('distancia', 0)
            )
        
        # Dibujar panel de información
        self.dibujar_panel_informacion(
            estado_juego.get('borracho', {}),
            estado_juego.get('estrategia', 'Desconocida'),
            estado_juego.get('pasos', 0)
        )
        
        # Dibujar controles
        self.dibujar_controles()
        
        # Actualizar display
        pygame.display.flip()
    
    def manejar_eventos(self) -> Dict[str, bool]:
        eventos = {
            'salir': False,
            'pausa': False,
            'toggle_rastro': False,
            'toggle_memoria': False,
            'toggle_posiciones': False,
            'toggle_numeros': False,
            'acelerar': False,
            'desacelerar': False
        }
        
        for evento in pygame.event.get():
            if evento.type == pygame.QUIT:
                eventos['salir'] = True
            
            elif evento.type == pygame.KEYDOWN:
                if evento.key == pygame.K_q:
                    eventos['salir'] = True
                elif evento.key == pygame.K_SPACE:
                    eventos['pausa'] = True
                elif evento.key == pygame.K_r:
                    eventos['toggle_rastro'] = True
                    self.mostrar_rastro = not self.mostrar_rastro
                    print(f"Rastro: {'ON' if self.mostrar_rastro else 'OFF'}")
                elif evento.key == pygame.K_PLUS or evento.key == pygame.K_EQUALS:
                    eventos['acelerar'] = True
                    self.fps = min(self.fps_max, self.fps + 1)
                    print(f"FPS: {self.fps}")
                elif evento.key == pygame.K_MINUS:
                    eventos['desacelerar'] = True
                    self.fps = max(self.fps_min, self.fps - 1)
                    print(f"FPS: {self.fps}")
        
        return eventos
    
    def actualizar_direccion(self, direccion: str):
        self._ultima_direccion = direccion
    
    def limpiar_rastro(self):
        self.rastro_posiciones.clear()
        print("Rastro limpiado")
    
    def obtener_fps(self) -> int:
        return self.fps
    
    def ajustar_fps(self, nuevo_fps: int):
        self.fps = max(self.fps_min, min(self.fps_max, nuevo_fps))
    
    def esperar_frame(self):
        self.reloj.tick(self.fps)
    
    def cerrar(self):
        pygame.quit()