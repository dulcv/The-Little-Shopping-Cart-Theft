"""Genera el arte faltante de los niveles 2-5 imitando el estilo del Centro.

Uso:  python tools/generar_arte.py   (desde la raíz del proyecto, requiere Pillow)

- Recorta tiles "lisos" de los atlas que ya existen (pasto, tierra, asfalto, piedra...).
- Dibuja pixel art nuevo con la paleta del juego y contorno oscuro: pisos de interior,
  muebles, maíz, granero, accesorios de los personajes, etc.
Todo sale en assets/sprites/generado/ (tiles/, props/, accesorios/).
"""
from pathlib import Path
from PIL import Image, ImageDraw
import random

RAIZ = Path(__file__).resolve().parent.parent
TILES_CENTRO = RAIZ / "assets/sprites/tiles/el_centro"
SALIDA = RAIZ / "assets/sprites/generado"

# Paleta tomada de edificios.png, el pollo y arbustos.png
OUT = (47, 43, 42, 255)        # contorno
OUT2 = (33, 26, 20, 255)
CAFE = (129, 80, 65, 255)
CAFE_OSC = (103, 59, 45, 255)
CAFE_CLARO = (171, 81, 48, 255)
MADERA = (143, 86, 59, 255)
MADERA_CLARA = (176, 116, 74, 255)
GRIS = (118, 109, 110, 255)
GRIS_CLARO = (177, 173, 170, 255)
GRIS_MUY_CLARO = (213, 204, 205, 255)
MORADO = (89, 78, 107, 255)
MORADO_OSC = (69, 60, 84, 255)
AZUL = (72, 112, 149, 255)
AZUL_CLARO = (120, 174, 202, 255)
ROJO = (172, 50, 50, 255)
ROJO_OSC = (125, 56, 51, 255)
NARANJA = (223, 113, 38, 255)
VERDE = (59, 125, 79, 255)
VERDE_CLARO = (99, 171, 63, 255)
VERDE_OSC = (47, 87, 83, 255)
AMARILLO = (240, 200, 70, 255)
ORO = (232, 182, 52, 255)
ORO_OSC = (176, 122, 30, 255)
BLANCO = (255, 255, 255, 255)
NEGRO = (30, 28, 32, 255)
T = (0, 0, 0, 0)

random.seed(7)


def nuevo(w, h, color=T):
    return Image.new("RGBA", (w, h), color)


def rect(im, x, y, w, h, c):
    ImageDraw.Draw(im).rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def contorno(im, c=OUT):
    """Borde de 1 px hacia adentro en el límite de la silueta (estilo del Centro)."""
    a = im.copy()
    for y in range(im.height):
        for x in range(im.width):
            if a.getpixel((x, y))[3] == 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if not (0 <= nx < im.width and 0 <= ny < im.height) or a.getpixel((nx, ny))[3] == 0:
                    im.putpixel((x, y), c)
                    break
    return im


def ruido(im, colores, n, area=None):
    x0, y0, w, h = area or (0, 0, im.width, im.height)
    for _ in range(n):
        px(im, x0 + random.randrange(w), y0 + random.randrange(h), random.choice(colores))


def recorte(archivo, x, y, w=16, h=16):
    return Image.open(TILES_CENTRO / archivo).convert("RGBA").crop((x, y, x + w, y + h))


def guardar(im, carpeta, nombre):
    d = SALIDA / carpeta
    d.mkdir(parents=True, exist_ok=True)
    im.save(d / f"{nombre}.png")


# ----------------------------------------------------------------- TILES 16x16
def tiles():
    # Recortes de tu arte
    guardar(recorte("césped.png", 96, 32), "tiles", "pasto")
    guardar(recorte("césped.png", 0, 0), "tiles", "pasto_jardin")
    guardar(recorte("piedra.png", 32, 32), "tiles", "piedra")
    guardar(recorte("carretera.png", 288, 64), "tiles", "asfalto")
    guardar(recorte("carretera.png", 384, 0), "tiles", "banqueta")
    guardar(recorte("tierra.png", 200, 72), "tiles", "tierra")

    # Madera (salón, oficinas): tablones verticales largos, 32x32 para que no parezca ladrillo
    for nombre, base, veta, junta in (("madera", MADERA_CLARA, (190, 132, 88, 255), MADERA),
                                      ("madera_oscura", MADERA, MADERA_CLARA, CAFE_OSC)):
        im = nuevo(32, 32, base)
        for col in range(4):
            x = col * 8
            rect(im, x + 7, 0, 1, 32, junta)
            corte = (col * 13 + 5) % 32
            rect(im, x, corte, 7, 1, junta)
            for _ in range(3):
                vy = random.randrange(32)
                rect(im, x + 2 + random.randrange(3), vy, 1, 3, veta)
        guardar(im, "tiles", nombre)

    # Mosaico de la comisaría (ajedrez)
    im = nuevo(16, 16)
    for by in range(2):
        for bx in range(2):
            c = GRIS_MUY_CLARO if (bx + by) % 2 == 0 else GRIS_CLARO
            rect(im, bx * 8, by * 8, 8, 8, c)
    for i in range(16):
        px(im, i, 15, (196, 188, 189, 255)); px(im, 15, i, (196, 188, 189, 255))
    guardar(im, "tiles", "mosaico")

    # Alfombras con borde decorado
    for nombre, base, deco in (("alfombra_roja", ROJO, ORO), ("alfombra_azul", AZUL, AZUL_CLARO)):
        im = nuevo(16, 16, base)
        sombra = tuple(max(0, c - 25) for c in base[:3]) + (255,)
        ruido(im, [sombra], 14)
        px(im, 8, 8, deco)
        guardar(im, "tiles", nombre)

    # Concreto (bodega)
    im = nuevo(16, 16, GRIS)
    ruido(im, [GRIS_CLARO, (100, 92, 93, 255)], 18)
    guardar(im, "tiles", "concreto")

    # Ladrillo (mansión)
    im = nuevo(16, 16, CAFE)
    for fila in range(4):
        y = fila * 4
        rect(im, 0, y + 3, 16, 1, CAFE_OSC)
        off = 0 if fila % 2 == 0 else 4
        for x in range(off, 16, 8):
            px(im, x, y, CAFE_OSC); px(im, x, y + 1, CAFE_OSC); px(im, x, y + 2, CAFE_OSC)
        ruido(im, [CAFE_CLARO], 2, (0, y, 16, 3))
    guardar(im, "tiles", "ladrillo")

    # Muro aplanado (comisaría, oficina de la granja)
    for nombre, base, sombra in (("muro_azul", MORADO, MORADO_OSC), ("muro_crema", GRIS_MUY_CLARO, GRIS_CLARO)):
        im = nuevo(16, 16, base)
        ruido(im, [sombra], 10)
        guardar(im, "tiles", nombre)

    # Lámina (bodega)
    im = nuevo(16, 16, GRIS)
    for x in range(0, 16, 4):
        rect(im, x, 0, 1, 16, (95, 88, 90, 255)); rect(im, x + 1, 0, 1, 16, GRIS_CLARO)
    guardar(im, "tiles", "lamina")

    # Maíz: tallos verdes con mazorcas
    im = nuevo(16, 16, VERDE_OSC)
    for x in (2, 7, 12):
        rect(im, x, 0, 2, 16, VERDE)
        px(im, x - 1, 4, VERDE_CLARO); px(im, x + 2, 9, VERDE_CLARO); px(im, x - 1, 13, VERDE_CLARO)
        rect(im, x + 2, 5, 2, 3, AMARILLO); px(im, x + 2, 5, ORO)
    guardar(im, "tiles", "maiz")

    # Cerca de madera (vertical y horizontal)
    im = nuevo(6, 16)
    rect(im, 1, 0, 4, 16, MADERA); rect(im, 1, 0, 1, 16, MADERA_CLARA)
    rect(im, 0, 2, 6, 3, CAFE_OSC); rect(im, 0, 10, 6, 3, CAFE_OSC)
    guardar(im, "tiles", "cerca_v")
    guardar(im.rotate(90, expand=True), "tiles", "cerca_h")

    # Surcos del plantío: tierra con hileras de brotes de maíz (piso decorativo)
    im = recorte("tierra.png", 200, 72)
    for y in (3, 11):
        rect(im, 0, y + 2, 16, 1, (95, 66, 40, 255))
        for x in (2, 8, 13):
            px(im, x, y, VERDE_CLARO); px(im, x, y + 1, VERDE); px(im, x - 1, y, VERDE)
    guardar(im, "tiles", "surcos")

    # Arena del jefe
    im = nuevo(16, 16, (176, 140, 90, 255))
    ruido(im, [(150, 115, 72, 255), (196, 164, 110, 255)], 22)
    guardar(im, "tiles", "arena")

    # Pasto del campo (más seco)
    im = recorte("césped.png", 96, 32)
    seco = nuevo(16, 16, (120, 140, 60, 90))
    guardar(Image.alpha_composite(im, seco), "tiles", "pasto_seco")


# ----------------------------------------------------------------- PROPS
def mesa():
    im = nuevo(30, 16)
    rect(im, 1, 1, 28, 12, BLANCO)
    rect(im, 1, 11, 28, 3, GRIS_MUY_CLARO)            # caída del mantel
    for x in range(2, 28, 4):
        px(im, x, 13, GRIS_CLARO)
    rect(im, 6, 4, 3, 3, ROJO); px(im, 7, 3, VERDE)  # florero
    rect(im, 15, 5, 2, 2, AMARILLO); rect(im, 21, 4, 2, 3, AZUL_CLARO)
    return contorno(im)


def escritorio():
    im = nuevo(40, 16)
    rect(im, 0, 0, 40, 13, MADERA); rect(im, 0, 13, 40, 3, CAFE_OSC)
    rect(im, 1, 1, 38, 1, MADERA_CLARA)
    rect(im, 5, 3, 8, 6, BLANCO); rect(im, 6, 4, 6, 1, GRIS); rect(im, 6, 6, 5, 1, GRIS)  # papeles
    rect(im, 26, 3, 7, 5, NEGRO); rect(im, 27, 4, 5, 3, AZUL)                            # monitor
    px(im, 18, 5, ROJO); px(im, 19, 5, ROJO)                                             # sello
    return contorno(im)


def planta(w=16, h=16):
    im = nuevo(w, h)
    cx = w // 2
    rect(im, cx - 4, h - 6, 8, 6, NARANJA); rect(im, cx - 4, h - 6, 8, 1, CAFE_CLARO)
    for (dx, dy, r) in ((-3, -9, 3), (3, -9, 3), (0, -11, 3), (0, -7, 3)):
        ImageDraw.Draw(im).ellipse([cx + dx - r, h + dy - r - 2, cx + dx + r, h + dy + r - 2],
                                   fill=VERDE if dy != -11 else VERDE_CLARO)
    return contorno(im)


def arbusto(w=24, h=16):
    im = nuevo(w, h)
    d = ImageDraw.Draw(im)
    d.ellipse([0, 2, w // 2 + 2, h - 1], fill=VERDE)
    d.ellipse([w // 2 - 2, 2, w - 1, h - 1], fill=VERDE)
    d.ellipse([w // 4, 0, 3 * w // 4, h - 4], fill=VERDE_CLARO)
    ruido(im, [VERDE_OSC], 6, (2, 4, w - 4, h - 6))
    return contorno(im)


def reja(w=40, h=8):
    im = nuevo(w, h, NEGRO)
    for x in range(2, w, 4):
        rect(im, x, 1, 1, h - 2, GRIS)
    rect(im, 0, 0, w, 1, GRIS_CLARO)
    return contorno(im)


def casillero():
    im = nuevo(16, 16, AZUL)
    rect(im, 0, 0, 1, 16, OUT); rect(im, 15, 0, 1, 16, OUT)
    for y in (3, 5, 7):
        rect(im, 4, y, 8, 1, MORADO_OSC)
    px(im, 12, 10, ORO)
    rect(im, 0, 15, 16, 1, OUT); rect(im, 0, 0, 16, 1, OUT)
    return im


def banca(w=110, h=10):
    im = nuevo(w, h, MADERA)
    for y in range(0, h, 3):
        rect(im, 0, y, w, 1, MADERA_CLARA)
    return contorno(im)


def costal():
    im = nuevo(16, 13)
    ImageDraw.Draw(im).ellipse([0, 2, 15, 12], fill=(214, 196, 140, 255))
    rect(im, 5, 0, 6, 4, (190, 170, 115, 255))
    rect(im, 6, 6, 4, 3, AMARILLO); px(im, 7, 5, VERDE)
    return contorno(im)


def caja(w=40, h=30):
    im = nuevo(w, h, MADERA)
    for y in range(0, h, 5):
        rect(im, 0, y, w, 1, CAFE_OSC)
    ImageDraw.Draw(im).line([(1, 1), (w - 2, h - 2)], fill=MADERA_CLARA, width=2)
    return contorno(im)


def granero(w=140, h=150):
    im = nuevo(w, h, ROJO)
    for x in range(0, w, 6):  # tejas del techo
        rect(im, x, 0, 1, h, ROJO_OSC)
    rect(im, w // 2 - 2, 0, 4, h, BLANCO)                # cumbrera
    rect(im, 0, 0, w, 3, BLANCO); rect(im, 0, h - 3, w, 3, BLANCO)
    for y in range(8, h, 10):  # hileras de tejas
        rect(im, 0, y, w, 1, ROJO_OSC)
    rect(im, 10, 10, 12, 8, GRIS_MUY_CLARO)              # tragaluz
    return contorno(im)


def silo(s=40):
    im = nuevo(s, s)
    d = ImageDraw.Draw(im)
    d.ellipse([0, 0, s - 1, s - 1], fill=GRIS_CLARO)
    for r in (s // 2 - 5, s // 2 - 11):
        d.ellipse([s // 2 - r, s // 2 - r, s // 2 + r, s // 2 + r], outline=GRIS)
    d.ellipse([s // 2 - 3, s // 2 - 3, s // 2 + 3, s // 2 + 3], fill=GRIS)
    return contorno(im)


def tractor(w=40, h=30):
    im = nuevo(w, h)
    rect(im, 0, 0, 12, 8, NEGRO); rect(im, 0, h - 8, 12, 8, NEGRO)          # llantas traseras
    rect(im, w - 9, 2, 8, 5, NEGRO); rect(im, w - 9, h - 7, 8, 5, NEGRO)    # delanteras
    rect(im, 4, 6, w - 8, h - 12, VERDE_CLARO); rect(im, 4, 6, w - 8, 2, VERDE)
    rect(im, 8, 10, 10, 10, VERDE); rect(im, 10, 12, 6, 6, AMARILLO)        # asiento
    return contorno(im)


def bote():
    im = nuevo(14, 18)
    rect(im, 1, 3, 12, 15, VERDE_OSC); rect(im, 0, 1, 14, 3, GRIS)
    for x in (4, 7, 10):
        rect(im, x, 6, 1, 10, (36, 64, 61, 255))
    px(im, 6, 0, BLANCO); px(im, 7, 0, BLANCO)   # papel asomando
    return contorno(im)


def cafetera():
    im = nuevo(20, 20)
    rect(im, 2, 2, 16, 16, GRIS)
    rect(im, 5, 6, 10, 9, NEGRO); rect(im, 6, 10, 8, 4, CAFE)
    px(im, 15, 4, ROJO)
    return contorno(im)


def tablero(w=200, h=28):
    im = nuevo(w, h, (190, 140, 80, 255))
    ruido(im, [(170, 120, 65, 255)], 120)
    rect(im, 0, 0, w, 2, MADERA); rect(im, 0, h - 2, w, 2, MADERA)
    for x in range(14, w - 10, 34):
        rect(im, x, 6, 12, 10, BLANCO); px(im, x + 5, 6, ROJO)
    d = ImageDraw.Draw(im)
    d.line([(20, 8), (54, 12), (88, 8), (122, 13), (156, 9)], fill=ROJO)
    return contorno(im)


def sirena():
    im = nuevo(12, 8)
    rect(im, 0, 3, 12, 5, GRIS)
    ImageDraw.Draw(im).ellipse([2, 0, 9, 6], fill=BLANCO)
    return contorno(im)


def pilar(s=24):
    im = nuevo(s, s, GRIS_CLARO)
    rect(im, 3, 3, s - 6, s - 6, GRIS)
    rect(im, 6, 6, s - 12, s - 12, GRIS_CLARO)
    rect(im, s // 2 - 2, s // 2 - 2, 4, 4, ORO)
    return contorno(im)


def maceta_micro():
    im = planta(14, 16)
    return im


def placa():
    im = nuevo(9, 9)
    d = ImageDraw.Draw(im)
    d.polygon([(4, 0), (6, 3), (8, 4), (6, 6), (6, 8), (4, 7), (2, 8), (2, 6), (0, 4), (2, 3)], fill=ORO)
    px(im, 4, 4, ORO_OSC)
    return contorno(im, OUT2)


def letrero(w=40, h=14):
    im = nuevo(w, h, MADERA)
    rect(im, 1, 1, w - 2, 1, MADERA_CLARA)
    return contorno(im)


def lupa():
    im = nuevo(14, 14)
    d = ImageDraw.Draw(im)
    d.line([(9, 9), (12, 12)], fill=CAFE_OSC, width=3)       # mango
    d.ellipse([0, 0, 10, 10], fill=GRIS_CLARO)                 # aro
    d.ellipse([2, 2, 8, 8], fill=AZUL_CLARO)                   # cristal
    px(im, 3, 3, BLANCO); px(im, 4, 3, BLANCO); px(im, 3, 4, BLANCO)
    return contorno(im, OUT2)


def puesto_elotes():
    im = nuevo(30, 26)
    rect(im, 3, 12, 24, 10, MADERA); rect(im, 3, 12, 24, 2, MADERA_CLARA)
    rect(im, 6, 15, 18, 5, AMARILLO)                          # elotes
    for x in range(7, 24, 3):
        px(im, x, 15, VERDE_CLARO)
    rect(im, 4, 22, 4, 4, NEGRO); rect(im, 22, 22, 4, 4, NEGRO)  # ruedas
    d = ImageDraw.Draw(im)
    d.pieslice([0, 0, 29, 18], 180, 360, fill=ROJO)            # sombrilla
    for x in range(3, 28, 6):
        d.line([(15, 1), (x, 9)], fill=BLANCO)
    rect(im, 14, 9, 2, 4, GRIS)
    return contorno(im)


def banca_corta():
    im = nuevo(30, 10, MADERA)
    for y in range(0, 10, 3):
        rect(im, 0, y, 30, 1, MADERA_CLARA)
    rect(im, 2, 8, 2, 2, NEGRO); rect(im, 26, 8, 2, 2, NEGRO)
    return contorno(im)


def lanzahuevos():
    im = nuevo(16, 8)
    rect(im, 0, 3, 4, 4, CAFE)                     # culata
    rect(im, 3, 2, 10, 4, GRIS_CLARO)              # cuerpo
    rect(im, 12, 1, 4, 6, AMARILLO)                # boca de la canasta
    rect(im, 5, 0, 5, 2, (240, 235, 220, 255))     # huevo en la recámara
    rect(im, 5, 6, 2, 2, NEGRO)                    # gatillo
    return contorno(im, OUT2)


def huevo():
    im = nuevo(6, 5)
    ImageDraw.Draw(im).ellipse([0, 0, 5, 4], fill=(245, 240, 225, 255))
    px(im, 1, 1, BLANCO)
    return contorno(im, (150, 130, 100, 255))


def tablero_grande(w=230, h=76):
    im = nuevo(w, h, (190, 140, 80, 255))
    ruido(im, [(170, 120, 65, 255), (205, 155, 95, 255)], 500)
    rect(im, 0, 0, w, 3, MADERA); rect(im, 0, h - 3, w, 3, MADERA)
    rect(im, 0, 0, 3, h, MADERA); rect(im, w - 3, 0, 3, h, MADERA)
    # foto de Kiko (pollo con gorra) a la izquierda y mapa a la derecha
    rect(im, 8, 8, 26, 30, BLANCO); rect(im, 10, 10, 22, 20, AZUL_CLARO)
    ImageDraw.Draw(im).ellipse([15, 15, 27, 27], fill=BLANCO); rect(im, 17, 13, 8, 3, AZUL)
    px(im, 20, 9, ROJO)
    rect(im, w - 40, 8, 32, 24, (230, 220, 180, 255))
    ImageDraw.Draw(im).line([(w - 36, 26), (w - 26, 14), (w - 16, 22)], fill=VERDE, width=2)
    px(im, w - 16, 22, ROJO); px(im, w - 15, 22, ROJO)
    d = ImageDraw.Draw(im)
    d.line([(21, 38), (40, h - 8), (w - 40, h - 8), (w - 24, 32)], fill=ROJO)   # estambre rojo (abajo)
    return contorno(im)


def props():
    guardar(tablero_grande(), "props", "tablero_grande")
    guardar(lanzahuevos(), "armas", "lanzahuevos")
    guardar(huevo(), "armas", "huevo")
    guardar(puesto_elotes(), "props", "puesto_elotes")
    guardar(banca_corta(), "props", "banca_corta")
    guardar(lupa(), "props", "lupa")
    guardar(casillero(), "tiles", "casillero")  # se usa repetido como fila de casilleros
    for nombre, im in (("mesa", mesa()), ("escritorio", escritorio()), ("planta", planta()),
                       ("arbusto", arbusto()), ("reja", reja()), ("casillero", casillero()),
                       ("banca", banca()), ("costal", costal()), ("caja", caja()), ("caja_chica", caja(50, 30)),
                       ("granero", granero()), ("silo", silo()), ("tractor", tractor()), ("bote", bote()),
                       ("cafetera", cafetera()), ("tablero", tablero()), ("sirena", sirena()), ("pilar", pilar()),
                       ("maceta_micro", maceta_micro()), ("placa", placa()), ("letrero", letrero()),
                       ("recepcion", escritorio().resize((80, 12), Image.NEAREST)),
                       ("escritorio_grande", escritorio().resize((80, 16), Image.NEAREST))):
        guardar(im, "props", nombre)


# ----------------------------------------------------------------- ACCESORIOS
# Se dibujan sobre el pollo mirando a la derecha (cresta en x 10-16, ojo en (14,7)).
def sombrero_detective():
    im = nuevo(14, 7)
    rect(im, 0, 5, 14, 2, CAFE_OSC)             # ala
    rect(im, 3, 1, 8, 5, CAFE)                  # copa
    rect(im, 3, 4, 8, 1, NEGRO)                 # cinta
    rect(im, 5, 0, 4, 1, CAFE)
    return contorno(im, OUT2)


def gorra(color, visera, insignia):
    im = nuevo(12, 6)
    rect(im, 1, 1, 8, 5, color)
    rect(im, 8, 4, 4, 2, visera)                # visera hacia el pico
    px(im, 4, 2, insignia); px(im, 5, 2, insignia)
    return contorno(im, OUT2)


def panuelo():
    im = nuevo(12, 5)
    rect(im, 1, 1, 9, 4, NEGRO)
    px(im, 0, 3, NEGRO); px(im, 0, 4, NEGRO)    # nudo atrás
    px(im, 4, 2, GRIS_CLARO); px(im, 7, 3, GRIS_CLARO)
    return contorno(im, OUT2)


def lentes():
    im = nuevo(6, 3)
    rect(im, 0, 0, 6, 3, NEGRO)
    px(im, 1, 0, GRIS_CLARO); px(im, 4, 0, GRIS_CLARO)
    return im


def sombrero_oro():
    im = nuevo(18, 8)
    rect(im, 0, 5, 18, 2, ORO_OSC); px(im, 0, 4, ORO_OSC); px(im, 17, 4, ORO_OSC)
    rect(im, 4, 1, 10, 5, ORO); rect(im, 4, 4, 10, 1, ROJO)
    rect(im, 6, 0, 6, 1, ORO)
    return contorno(im, OUT2)


def cadena():
    im = nuevo(8, 4)
    for x in range(8):
        px(im, x, 1 if x in (0, 7) else 2, ORO if x % 2 == 0 else ORO_OSC)
    rect(im, 3, 2, 2, 2, ORO)
    return im


def mono():
    im = nuevo(8, 5)
    rect(im, 0, 0, 3, 5, (230, 110, 160, 255)); rect(im, 5, 0, 3, 5, (230, 110, 160, 255))
    rect(im, 3, 1, 2, 3, (200, 80, 130, 255))
    return contorno(im, OUT2)


def gorrito_fiesta(c1, c2):
    im = nuevo(7, 9)
    for y in range(9):
        a = y // 2
        rect(im, 3 - a, y, 1 + 2 * a, 1, c1 if y % 3 else c2)
    px(im, 3, 0, AMARILLO)
    return contorno(im, OUT2)


def gorro_chef():
    im = nuevo(10, 9)
    ImageDraw.Draw(im).ellipse([0, 0, 9, 6], fill=BLANCO)
    rect(im, 2, 4, 6, 5, BLANCO); rect(im, 2, 7, 6, 1, GRIS_MUY_CLARO)
    return contorno(im, OUT2)


def sombrero_paja():
    im = nuevo(16, 7)
    rect(im, 0, 5, 16, 2, (214, 180, 100, 255))
    rect(im, 4, 1, 8, 5, (230, 200, 120, 255)); rect(im, 4, 4, 8, 1, ROJO)
    for x in range(1, 15, 3):
        px(im, x, 5, (190, 155, 80, 255))
    return contorno(im, OUT2)


def gorra_roja():
    im = gorra(ROJO, ROJO_OSC, BLANCO)
    return im


def boina():
    im = nuevo(11, 5)
    ImageDraw.Draw(im).ellipse([0, 0, 10, 5], fill=MORADO)
    px(im, 5, 0, MORADO_OSC)
    return contorno(im, OUT2)


def accesorios():
    guardar(gorro_chef(), "accesorios", "gorro_chef")
    guardar(sombrero_paja(), "accesorios", "sombrero_paja")
    guardar(gorra_roja(), "accesorios", "gorra_roja")
    guardar(boina(), "accesorios", "boina")
    guardar(sombrero_detective(), "accesorios", "sombrero_detective")
    guardar(gorra(AZUL, NEGRO, ORO), "accesorios", "gorra_policia")
    guardar(gorra(BLANCO, NEGRO, ORO), "accesorios", "gorra_jefa")
    guardar(panuelo(), "accesorios", "panuelo_negro")
    guardar(lentes(), "accesorios", "lentes_oscuros")
    guardar(sombrero_oro(), "accesorios", "sombrero_oro")
    guardar(cadena(), "accesorios", "cadena_oro")
    guardar(mono(), "accesorios", "mono_rosa")
    guardar(gorrito_fiesta(AZUL_CLARO, ROJO), "accesorios", "gorrito_fiesta_1")
    guardar(gorrito_fiesta(AMARILLO, VERDE), "accesorios", "gorrito_fiesta_2")
    guardar(gorrito_fiesta((230, 110, 160, 255), AZUL), "accesorios", "gorrito_fiesta_3")


if __name__ == "__main__":
    tiles()
    props()
    accesorios()
    n = len(list(SALIDA.rglob("*.png")))
    print(f"ok: {n} imágenes en {SALIDA.relative_to(RAIZ)}")
