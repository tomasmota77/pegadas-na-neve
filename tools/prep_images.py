"""Prepara as imagens de assets/images/ para o jogo.

Corta as margens transparentes, centra cada imagem num quadrado (para não
aparecer esticada) e reduz para o tamanho que o jogo usa. Também prepara o
fundo (1080×1920) e o ícone da app (icon.png, 1024×1024, sem transparência).

Pode correr-se outra vez depois de juntar ou trocar imagens:
    python tools/prep_images.py
"""
import os

from PIL import Image

ROOT = os.path.join(os.path.dirname(__file__), "..")
IMG = os.path.join(ROOT, "assets", "images")

# nome -> lado do quadrado final
SQUARE = {
    "ourico": 512, "coelho": 512, "raposa": 512,
    "comida_ourico": 512, "comida_coelho": 512, "comida_raposa": 512,
    "rocha": 512, "floco": 512, "vitoria": 512,
    "pegada_ourico": 256, "pegada_coelho": 256, "pegada_raposa": 256,
    "voltar": 256, "ajuda": 256, "definicoes": 256, "desfazer": 256,
    "limpar": 256, "dica": 256, "relogio": 256, "cadeado": 256, "estrela": 256,
}
MARGIN = 0.04  # espaço livre à volta, em fração do lado


def trim(im):
    box = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    return im.crop(box) if box else im


def square(im, side):
    im = trim(im.convert("RGBA"))
    inner = side * (1 - 2 * MARGIN)
    k = inner / max(im.size)
    im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    out = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    out.alpha_composite(im, ((side - im.width) // 2, (side - im.height) // 2))
    return out


def cover(im, w, h):
    k = max(w / im.width, h / im.height)
    im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    x, y = (im.width - w) // 2, (im.height - h) // 2
    return im.crop((x, y, x + w, y + h))


def main():
    for name, side in SQUARE.items():
        p = os.path.join(IMG, name + ".png")
        if os.path.exists(p):
            square(Image.open(p), side).save(p, optimize=True)
            print("ok", name)
        else:
            print("FALTA", name)
    p = os.path.join(IMG, "logo.png")
    if os.path.exists(p):
        im = trim(Image.open(p).convert("RGBA"))
        im.thumbnail((1024, 1024), Image.LANCZOS)
        im.save(p, optimize=True)
        print("ok logo", im.size)
    p = os.path.join(IMG, "fundo.png")
    if os.path.exists(p):
        cover(Image.open(p).convert("RGB"), 1080, 1920).save(p, optimize=True)
        print("ok fundo")
    p = os.path.join(ROOT, "icon.png")
    if os.path.exists(p):
        im = Image.open(p).convert("RGB")
        cover(im, 1024, 1024).save(p, optimize=True)
        print("ok icon")


if __name__ == "__main__":
    main()
