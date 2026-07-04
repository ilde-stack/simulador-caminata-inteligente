# Simulador de Caminata Aleatoria con Inteligencia Lógica (Python & Prolog)

Este proyecto consiste en una plataforma de simulación interactiva que modela y optimiza el problema clásico de la "Caminata del Borracho" sobre entornos bidimensionales con obstáculos dinámicos. El sistema cuenta con un proceso evolutivo de desarrollo, pasando de un núcleo de lógica pura en Prolog a una arquitectura híbrida acoplada a un controlador gráfico en tiempo real desarrollado en Python.

## Características Técnicas
* **Arquitectura Multilenguaje:** Integración nativa entre Python 3 y SWI-Prolog mediante la librería de puente conceptual `pyswip`.
* **Motor Lógico de Aprendizaje:** Implementación en Prolog de un sistema adaptativo que registra penalizaciones por ciclos/bucles y bonificaciones por progreso hacia el objetivo mediante la distancia de Manhattan.
* **Gestión de Memoria Dinámica:** Uso de predicados dinámicos (`assert`/`retract`) para el almacenamiento en tiempo real de obstáculos chocados, zonas problemáticas y optimización de rutas.
* **Interfaz Gráfica Interactiva:** Renderizado del mapa en tiempo real, mapas de calor de celdas visitadas, barras de energía y controladores de velocidad (FPS) utilizando `pygame`.

## Estructura del Proyecto

El repositorio está organizado cronológicamente según las etapas de la entrega:

```text
simulador-caminata-inteligente/
│
├── src/
│   ├── 1-version-logica/      # Primera etapa: Simulación base en entorno de 10x10 utilizando el paradigma lógico puro e interfaz nativa XPCE.
│   │   ├── entorno.pl
│   │   ├── borracho.pl
│   │   ├── inteligencia.pl
│   │   └── visualizacion.pl
│   │
│   └── 2-version-hibrida-python/   # Versión final optimizada: Grilla de 20x20 integrada con Pygame y sistema extendido de aprendizaje por refuerzo.
│       ├── controlador.py
│       ├── visualizacion.py
│       ├── main.pl
│       ├── entorno.pl
│       ├── estado.pl
│       ├── estrategia.pl
│       ├── memoria.pl
│       └── movimiento.pl
│
└── assets/                         # Recursos visuales e iconos de la interfaz
    └── borracho.png
