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
    "esquilo": 512, "comida_esquilo": 512, "pegada_esquilo": 256,
    "coruja": 512, "comida_coruja": 512, "pegada_coruja": 256,
    "gelo": 512, "nevao": 512, "numero_tapado": 256, "calendario": 256,
    "rocha": 512, "floco": 512, "vitoria": 512, "toca": 512,
    "pegada_ourico": 256, "pegada_coelho": 256, "pegada_raposa": 256,
    "voltar": 256, "ajuda": 256, "definicoes": 256, "desfazer": 256,
    "limpar": 256, "dica": 256, "relogio": 256, "cadeado": 256, "estrela": 256,
}
MARGIN = 0.04  # espaço livre à volta, em fração do lado

# Fundos da interface (opcionais). Os botões, cartões e pílulas esticam no meio
# (9-slice), por isso só se corta a margem vazia e se acerta a altura/lado menor.
UI_HEIGHT = {"ui_botao": 100, "ui_botao_claro": 100, "ui_pilula": 56}
UI_MIN_SIDE = {"ui_cartao": 160}
UI_SQUARE = {"ui_redondo": 256, "ui_redondo_escuro": 256,
             "ui_nivel": 128, "ui_nivel_feito": 128, "ui_nivel_fechado": 128}


def trim(im):
    box = im.getchannel("A").point(lambda a: 255 if a > 8 else 0).getbbox()
    return im.crop(box) if box else im


def square(im, side, margin=MARGIN):
    im = trim(im.convert("RGBA"))
    inner = side * (1 - 2 * margin)
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
    for f in sorted(os.listdir(IMG)):
        if f.startswith("logo") and f.endswith(".png"):
            p = os.path.join(IMG, f)
            im = trim(Image.open(p).convert("RGBA"))
            im.thumbnail((1024, 1024), Image.LANCZOS)
            im.save(p, optimize=True)
            print("ok", f, im.size)
    for name, h in UI_HEIGHT.items():
        p = os.path.join(IMG, name + ".png")
        if os.path.exists(p):
            im = trim(Image.open(p).convert("RGBA"))
            im.resize((round(im.width * h / im.height), h), Image.LANCZOS).save(p, optimize=True)
            print("ok", name)
    for name, side in UI_MIN_SIDE.items():
        p = os.path.join(IMG, name + ".png")
        if os.path.exists(p):
            im = trim(Image.open(p).convert("RGBA"))
            k = side / min(im.size)
            im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS).save(p, optimize=True)
            print("ok", name)
    for name, side in UI_SQUARE.items():
        p = os.path.join(IMG, name + ".png")
        if os.path.exists(p):
            square(Image.open(p), side, 0.0).save(p, optimize=True)
            print("ok", name)
    p = os.path.join(IMG, "fundo.png")
    if os.path.exists(p):
        cover(Image.open(p).convert("RGB"), 1080, 1920).save(p, optimize=True)
        print("ok fundo")
    # fundo e faixa de cada mundo
    for n in range(1, 7):
        for name, w, h in (("fundo_mundo%d" % n, 1080, 1920), ("mundo_%d" % n, 1200, 400)):
            p = os.path.join(IMG, name + ".png")
            if os.path.exists(p):
                im = Image.open(p).convert("RGB")
                if im.size != (w, h):
                    cover(im, w, h).save(p, optimize=True)
                    print("ok", name)
    p = os.path.join(ROOT, "icon.png")
    if os.path.exists(p):
        im = Image.open(p).convert("RGB")
        cover(im, 1024, 1024).save(p, optimize=True)
        print("ok icon")


if __name__ == "__main__":
    main()
