# 11 — Historia, niveles y jefe final ("Operación Mazorca")

> Parodia inspirada en casos reales de la guerra contra el narco (p.ej. Operación Leyenda).
> Nombres 100% ficticios, sin gore: el chiste va contra los villanos y la corrupción.

## Premisa

El agente encubierto **Kiko Cacareña** descubrió el **Rancho Maizal**, la plantación secreta de maíz
de los **Gallos Negros**, y desapareció. El detective (pollo jugable) sigue las pistas hasta su capo,
**Don Crestón**, protegido por policías del corral comprados.

## Niveles (`resources/niveles/*.tres`, orden en `CaseManager.NIVELES`)

| # | Título | zona_id | Escena | Pistas para pasar |
|---|---|---|---|---|
| 1 | El Pollo Desaparecido | el_centro | `scenes/main/escena_principal.tscn` | pluma_dorada, ticket_maiz, foto_kiko |
| 2 | La Fiesta del Gallo | las_lomas | `scenes/world/las_lomas/LasLomas.tscn` | invitacion_fiesta, grabacion_microfono |
| 3 | Rancho Maizal | granja_industrial | `scenes/world/granja_industrial/RanchoMaizal.tscn` | mapa_rancho, foto_plantio, escape_rancho |
| 4 | El Soplón | la_federal | `scenes/world/la_federal/LaFederal.tscn` | placa_policia, libreta_pagos, soplon_acusado |
| 5 | Don Crestón | arena_jefe | `scenes/world/arena_jefe/ArenaJefe.tscn` | (vencer al jefe) |

## Cómo se usa

- **Poner una pista**: instancia `scenes/pickups/clue_pickup.tscn` y cambia `pista_id`.
  Los textos de las pistas están en `CaseManager.TEXTO_PISTAS`.
- **Pasar de nivel**: automático al juntar todas las `pistas_requeridas`, o con `CaseManager.completar_nivel()`.
- **Nueva escena de nivel**: en su `_ready()` llama `CaseManager.sincronizar_con_zona("<zona_id>")`
  para que funcione al abrirla con F6.
- **Señales para el HUD**: `pista_obtenida(id, texto)`, `nivel_iniciado`, `nivel_completado`, `caso_resuelto`.

## Nivel 2: La Fiesta del Gallo (`scripts/world/las_lomas/las_lomas.gd`)

1. **Invitación**: está afuera, junto al invitado borracho (oeste). Sin ella, el portero no abre la reja.
2. **Sigilo**: 3 guardias Gallos Negros (`scenes/characters/npc/guardia_gallo_negro.tscn`) con cono de visión.
   Si te ven 0.6 s seguidos (o les pegas o disparas), te sacan a la puerta. Paredes y muebles tapan la vista.
3. **El micrófono (el "bug")**: en la maceta del despacho, mantén **E** 2 s. Luego entran Don Crestón y el
   comandante y hablan 6 líneas. Quédate a menos de 260 px del micrófono y sin que te vean; si te alejas, la
   grabación se pausa, y si te atrapan se pierde el micrófono.
   - Escondites probados: al oeste de la planta grande del salón (160, -185) y detrás del escritorio (300, -250).
   - El guardia del despacho ve la maceta cuando sube: hay que esperar a que baje.
- Para cambiar la dificultad, ajusta `alcance_vision`, `velocidad` y `patrulla` en cada guardia del inspector.

## Nivel 3: Rancho Maizal (`scripts/world/granja_industrial/rancho_maizal.gd`)

1. **Mapa**: dentro de la OFICINA de la granja (puerta sur). Hay 2 guardias en el patio (sigilo: si te ven, te sacan a la entrada).
   Al tomarlo se abre la **tabla suelta** de la cerca este: es la única entrada al maizal.
2. **Foto**: cruza el maizal (2 columnas; el hueco sur está alineado con la tabla para salir casi recto) y mantén **E** 1.5 s en la bodega.
   Ahí está el maíz ilegal y la placa del agente Kiko.
3. **¡Alarma!**: los guardias a pie huyen y a los 6.5 s arrancan 3 camionetas (la de la granja, 3 s después) negras de los Gallos Negros (`scripts/characters/npc/chaser_driver.gd`).
   Sube a la camioneta junto a la bodega (o a tu sedán, si lo trajiste) y sal por la carretera del oeste (x < -660).
   - Si una camioneta te toca 1.5 s, o te quedas a pie sin coches sanos, te atrapan: la escena se recarga y
     empiezas en la bodega con la alarma sonando (no repites el mapa ni la foto).
   - Los perseguidores no tienen navmesh: siguen el **rastro** del jugador cuando no lo ven directo.
- Dificultad: `RETRASO_PERSEGUIDORES` y `TIEMPO_CAPTURA` en `rancho_maizal.gd`; `radio_captura` en cada perseguidor;
  velocidad en `resources/vehicles/camioneta.tres`.

## Nivel 4: El Soplón (`scripts/world/la_federal/la_federal.gd`)

Deducción en la comisaría. Culpable: **Comandante Espolón** (`CULPABLE` en el script).
- Interrogatorios (E, `scripts/characters/npc/npc_charla.gd`): Doña Clueca (Espolón se va temprano los viernes
  "al dentista"... ¡los gallos no tienen dientes!), Pico y Plumas (tienen placa y juegan dominó los viernes),
  Espolón (nervioso: "mandé a pulir mi placa"), y la Jefa Cacaraca (explica las reglas).
- Pruebas: placa en el estacionamiento (junto a la camioneta negra) y libreta en el bote de los vestidores,
  vigilados por un policía (sigilo).
- Tablero: mantén E 1.5 s en un retrato. Sin las 2 pruebas no cuenta; un inocente = te echan a la calle.
  Con Espolón: confesión y se pasa al jefe final.

## Jefe final: Don Crestón (`scripts/characters/boss/don_creston.gd`)

**Debilidad:** su armadura de plumas de oro lo hace inmune ("¡TINK!"). Pero es orgulloso y embiste
a lo loco: si se estrella contra una pared o pilar queda **ATURDIDO** (rojo) y recibe **x2 de daño**.

| Estado | Qué hace | ¿Vulnerable? |
|---|---|---|
| PERSEGUIR | Camina hacia el jugador | No |
| AVISO | Parpadea y fija la dirección (señal para esquivar) | No |
| EMBESTIDA | Carga a 240 px/s; si te pega, 20 de daño | No |
| ATURDIDO | 2.5 s mareado tras chocar | **Sí (x2)** |
| CACAREO (fase 2) | Lanza maíz en 8/12 direcciones | **Sí (x2)** |

- La fase 2 empieza al ≤50% de vida: embiste más rápido y avisa menos tiempo.
- Al morir, la arena registra la pista `confesion_creston` y llama `completar_nivel()`.
- Visual temporal: los sprites del pollo del jugador ×2 teñidos de dorado. Hay que cambiarlo por arte propio.

## Pendiente

- `player.gd: take_damage()` sigue siendo un stub (carril D, Salud): el jefe ya llama `take_damage`,
  pero el jugador todavía no pierde vida.
- Mecánica del micrófono espía (nivel 2) con el `DialogueSystem`.
