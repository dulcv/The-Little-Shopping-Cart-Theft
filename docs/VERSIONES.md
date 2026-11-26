# Tabla de versionamiento — The Little Shopping Cart Theft

Formato de versión: **MAYOR.MENOR.PARCHE**

- **MAYOR**: el juego cambia por completo o sale una versión final (1.0.0 = juego completo jugable).
- **MENOR**: se agrega una función o sistema nuevo.
- **PARCHE**: correcciones, ajustes o limpieza sin funciones nuevas.

| Versión | Fecha | Autor(es) | Rama | Cambios | Commits |
|---|---|---|---|---|---|
| 0.1.0 | 2026-09-06 | dulcv | main | Creación del proyecto en Godot y del repositorio. | `ee912a9`, `f387e4a`, `c016dec` |
| 0.1.1 | 2026-09-07 | EdgarCray | develop | Limpieza del caché de Godot, `.gitignore` en UTF-8 y estructura de carpetas del proyecto. | `4025733`, `ab2ac6a` |
| 0.2.0 | 2026-09-14 | EdgarCray | develop | Jugador: animaciones de caminar, correr en varias direcciones, ataque y cámara que lo sigue. | `82a48c1` |
| 0.3.0 | 2026-09-17 | EdgarCray | develop | Sistema de armas: agarre por tamaño, animación, sonidos de disparo y golpe, movimiento en 4 direcciones. | `553d1a8` |
| 0.4.0 | 2026-09-28 | EdgarCray | develop | Vehículos: coche azul animado, sonidos de auto, radio de 4 estaciones y balas sobre el mapa. | `98f4d76` |
| 0.5.0 | 2026-09-28 | dulcv | feature | Ciudad del Centro: escena principal, edificios, flores, césped y arbustos. | `21e0931`, `24f40ea`, `c9fa34d` |
| 0.5.1 | 2026-09-30 | EdgarCray | develop | Pintura de coches por shader, sprites de patrulla, sirena con la tecla G y limpieza de warnings. | `40784bf` |
| 0.5.2 | 2026-10-05 | dulcv, EdgarCray | feature → develop | Cambio de capa de los edificios e integración con el Pull Request #1. | `1aa2a39`, `18c8538` |
| 0.5.3 | 2026-10-06 | EdgarCray | develop | Animaciones verticales del pollo, arma detrás al moverse en vertical y arreglo del sonido de encendido. | `82a266e` |
| 0.6.0 | 2026-10-12 | dulcv, EdgarCray | develop | Actualización del Centro, consolidación de develop (planes 00-10, sprites de Edgar y Dulce) e integración del Centro. | `d3c8baa`, `3bf8e26`, `54f3e78` |
| 0.6.1 | 2026-10-14 | dulcv | feature | Colisiones de los edificios. | `ee28979` |
| 0.7.0 | 2026-11-11 | dulcv | feature | Historia "Operación Mazorca" con 5 niveles y jefe final (incluye merge de develop). | `e0e50fa`, `b0a7fad` |
| 0.8.0 | 2026-11-18 | dulcv | feature | Vida del jugador, menú principal, pausa, game over, guardado de partida y créditos. | `ef3d22d` |
| 0.9.0 | 2026-11-18 | dulcv | feature | Arte de los niveles 2-5, accesorios, música CC0 por nivel, exportación a Windows y arreglo de transiciones. | `c150d61`, `ed4c99e` |
| 0.9.1 | 2026-11-18 | dulcv | feature | Centro: vecinos, peatones y decoración. | `3015884` |
| 1.0.0 | 2026-11-18 | dulcv | feature | Juego completo: selección de personaje, La Cochera, Lanzahuevos, radio en el HUD y diálogos para todos. | `cc81ed2` |
| 1.0.1 | 2026-11-25 | dulcv | feature | Posición inicial del Centro, limpieza de `sedan.tres` y nuevos créditos (Chicken Estudios y agradecimientos). | `9f836b1` y el commit de esta versión |

## Cómo agregar una versión nueva

1. Agrega una fila al final de la tabla con el número siguiente.
2. Escribe la fecha, quién hizo el cambio, la rama y un resumen corto.
3. Pon el código del commit (lo ves con `git log --oneline`).
