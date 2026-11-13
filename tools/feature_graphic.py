"""Gráfico de destaque do Google Play (1024×500): a ilustração com o logótipo em cima, à esquerda.

Uso: python tools/feature_graphic.py   → store/android/grafico_destaque_<língua>.png
"""
import os

from PIL import Image, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(ROOT, "assets", "images", "fontes", "caminhada_destaque.png")
OUT = os.path.join(ROOT, "store", "android")
W, H = 1024, 500
BOX = (28, 26, 470, 240)  # onde cabe o logótipo: o céu vazio à esquerda, sem tapar os animais


def make(lang):
    bg = Image.open(ART).convert("RGBA").resize((W, H), Image.LANCZOS)
    logo = Image.open(os.path.join(ROOT, "assets", "images", f"logo_{lang}.png")).convert("RGBA")
    bw, bh = BOX[2] - BOX[0], BOX[3] - BOX[1]
    k = min(bw / logo.width, bh / logo.height)
    logo = logo.resize((round(logo.width * k), round(logo.height * k)), Image.LANCZOS)
    x = BOX[0] + (bw - logo.width) // 2
    y = BOX[1] + (bh - logo.height) // 2
    # halo branco suave atrás do logótipo, para se ler bem sobre o céu
    a = Image.new("L", (W, H), 0)
    a.paste(logo.getchannel("A"), (x, y))
    a = a.filter(ImageFilter.MaxFilter(15)).filter(ImageFilter.GaussianBlur(14)).point(lambda v: int(v * 0.85))
    halo = Image.new("RGBA", (W, H), (255, 255, 255, 255))
    halo.putalpha(a)
    bg.alpha_composite(halo)
    bg.alpha_composite(logo, (x, y))
    path = os.path.join(OUT, f"grafico_destaque_{lang}.png")
    bg.convert("RGB").save(path, optimize=True)
    print("ok", path)


if __name__ == "__main__":
    for lang in ["pt", "en", "es", "fr", "de"]:
        make(lang)
