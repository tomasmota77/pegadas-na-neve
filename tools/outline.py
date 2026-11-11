"""Engrossa o contorno escuro das figuras, para se lerem bem pequenas no tabuleiro.

Junta à volta da figura uma faixa azul-marinho (#34303C) com `px` píxeis.
Corre depois de tools/prep_images.py (as imagens já têm 512×512 com margem).

Uso:
    python tools/outline.py                   # figuras do tabuleiro, 10 px
    python tools/outline.py 8 ourico coelho   # só estas, 8 px
"""
import os
import sys

from PIL import Image, ImageFilter

IMG = os.path.join(os.path.dirname(__file__), "..", "assets", "images")
NAVY = (52, 48, 60, 255)
DEFAULT = ["ourico", "coelho", "raposa", "comida_ourico", "comida_coelho", "comida_raposa", "rocha", "toca"]


def thicken(path, px):
    im = Image.open(path).convert("RGBA")
    a = im.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    grown = a.filter(ImageFilter.MaxFilter(px * 2 + 1)).filter(ImageFilter.GaussianBlur(0.8))
    out = Image.new("RGBA", im.size, NAVY)
    out.putalpha(grown)
    out.alpha_composite(im)
    out.save(path, optimize=True)


if __name__ == "__main__":
    args = sys.argv[1:]
    px = int(args.pop(0)) if args and args[0].isdigit() else 10
    for name in args or DEFAULT:
        p = os.path.join(IMG, name + ".png")
        if os.path.exists(p):
            thicken(p, px)
            print("ok", name)
