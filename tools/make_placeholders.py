"""Gera marcadores provisórios SEM emojis (formas simples com o nome).
Substitui cada ficheiro em assets/images/ pela imagem final com o MESMO nome.
Ícones de interface (voltar, ajuda, desfazer, limpar, dica, estrela, floco) não têm
marcador: enquanto não existirem, os botões mostram texto."""
from PIL import Image, ImageDraw, ImageFont
import os

ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "images")
os.makedirs(OUT, exist_ok=True)
FONT = os.path.join(ROOT, "assets", "fonts", "Baloo2-Bold.ttf")
COL = {"ourico": (46, 140, 126), "coelho": (194, 71, 122), "raposa": (227, 128, 31)}


def label(d, text, cx, cy, size, fill):
    f = ImageFont.truetype(FONT, size)
    d.text((cx, cy), text, font=f, fill=fill, anchor="mm")


def animal(t, name):
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([20, 20, 236, 236], fill=COL[t] + (255,))
    label(d, name, 128, 136, 46, (255, 255, 255, 255))
    im.save(os.path.join(OUT, t + ".png"))


def food(t):
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.ellipse([40, 40, 216, 216], outline=COL[t] + (255,), width=18)
    label(d, "comida", 128, 136, 40, COL[t] + (255,))
    im.save(os.path.join(OUT, "comida_" + t + ".png"))


def rock():
    im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([34, 58, 222, 210], radius=60, fill=(139, 151, 166, 255))
    label(d, "rocha", 128, 140, 44, (255, 255, 255, 255))
    im.save(os.path.join(OUT, "rocha.png"))


def paw(t, size=128):
    """Pegada branca a apontar para cima (o jogo pinta-a com a cor do animal)."""
    big = size * 4
    im = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    W = (255, 255, 255, 255)
    u = big / 16
    if t == "ourico":
        d.ellipse([5 * u, 7.5 * u, 11 * u, 13 * u], fill=W)
        for x, y in [(3.4, 6.2), (5.6, 4.2), (8, 3.4), (10.4, 4.2), (12.6, 6.2)]:
            d.ellipse([(x - 1.1) * u, (y - 1.1) * u, (x + 1.1) * u, (y + 1.1) * u], fill=W)
    elif t == "coelho":
        for x in (5.2, 10.8):
            d.ellipse([(x - 1.9) * u, 2 * u, (x + 1.9) * u, 9.5 * u], fill=W)
            d.ellipse([(x - 1.3) * u, 10.3 * u, (x + 1.3) * u, 14 * u], fill=W)
    else:
        d.ellipse([4.6 * u, 9.4 * u, 11.4 * u, 14 * u], fill=W)
        for x, y in [(4.6, 7), (6.8, 4.2), (9.2, 4.2), (11.4, 7)]:
            d.ellipse([(x - 1.25) * u, (y - 1.5) * u, (x + 1.25) * u, (y + 1.5) * u], fill=W)
    im.resize((size, size), Image.LANCZOS).save(os.path.join(OUT, "pegada_" + t + ".png"))


for t, n in [("ourico", "Ouriço"), ("coelho", "Coelho"), ("raposa", "Raposa")]:
    animal(t, n)
    food(t)
    paw(t)
rock()
print(sorted(os.listdir(OUT)))
