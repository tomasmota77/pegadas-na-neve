"""Corta uma imagem com várias figuras lado a lado em ficheiros separados.

Uso:
    python tools/split_sheet.py assets/images/animais.png ourico coelho raposa
    python tools/split_sheet.py assets/images/comidas.png comida_ourico comida_coelho comida_raposa

As figuras devem estar numa linha, da esquerda para a direita, com fundo
transparente (ou branco liso) e espaço vazio entre elas. Cada uma é gravada em
assets/images/<nome>.png; depois corre python tools/prep_images.py.
"""
import os
import sys

import numpy as np
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "images")


def mask_of(im):
    a = np.asarray(im.convert("RGBA")).astype(int)
    if a[..., 3].min() < 250:  # tem transparência
        return a[..., 3] > 16
    # fundo opaco: tudo o que não é quase branco
    return (a[..., :3] < 235).any(axis=2)


def split(path, names):
    im = Image.open(path).convert("RGBA")
    m = mask_of(im)
    cols = m.any(axis=0)
    # blocos de colunas ocupadas
    runs, start = [], None
    for x, on in enumerate(list(cols) + [False]):
        if on and start is None:
            start = x
        elif not on and start is not None:
            runs.append([start, x])
            start = None
    # junta pedacinhos soltos (flocos, brilhos) ao bloco mais perto até sobrarem len(names)
    while len(runs) > len(names):
        widths = [b - a for a, b in runs]
        i = int(np.argmin(widths))
        j = i - 1 if i == len(runs) - 1 or (i > 0 and runs[i][0] - runs[i - 1][1] < runs[i + 1][0] - runs[i][1]) else i + 1
        a, b = sorted([i, j])
        runs[a] = [runs[a][0], runs[b][1]]
        del runs[b]
    if len(runs) != len(names):
        # não deu para separar pelo espaço vazio: corta em partes iguais
        w = im.width / len(names)
        runs = [[int(i * w), int((i + 1) * w)] for i in range(len(names))]
    if m.shape[1] and not np.asarray(im)[..., 3].min() < 250:
        # fundo branco: torna-o transparente
        arr = np.asarray(im).copy()
        arr[..., 3] = np.where(m, 255, 0)
        im = Image.fromarray(arr)
    for (a, b), name in zip(runs, names):
        part = im.crop((a, 0, b, im.height))
        box = part.getchannel("A").point(lambda v: 255 if v > 16 else 0).getbbox()
        if box:
            part = part.crop(box)
        part.save(os.path.join(OUT, name + ".png"))
        print("ok", name, part.size)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)
    split(sys.argv[1], sys.argv[2:])
