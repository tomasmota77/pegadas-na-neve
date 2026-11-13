"""Transforma um vídeo de um animal (fundo verde liso) numa animação para o jogo.

Tira o fundo frame a frame, corta à volta do animal e junta tudo numa folha de frames:
    assets/anim/<nome>.png   (grelha de frames, com transparência)
    assets/anim/<nome>.json  ({"frames", "cols", "size", "fps"})

O jogo usa assets/anim/festa_<animal>.png no ecrã de vitória (ver Game.festa()).

Uso:
    python tools/video_anim.py video.mp4 festa_ourico
    python tools/video_anim.py video.mp4 festa_ourico --fps 12 --size 320 --start 0.2 --end 4.5
    python tools/video_anim.py video.mp4 festa_raposa --outline 7   # se o vídeo perdeu o contorno grosso

Também prepara as imagens de partida para gerar os vídeos (animal no meio, fundo verde):
    python tools/video_anim.py --start-frames
"""
import argparse
import glob
import json
import os
import subprocess
import tempfile

import numpy as np
from PIL import Image, ImageFilter

ROOT = os.path.join(os.path.dirname(__file__), "..")
IMG = os.path.join(ROOT, "assets", "images")
OUT = os.path.join(ROOT, "assets", "anim")
GREEN = (0, 255, 0)
ANIMALS = ["ourico", "coelho", "raposa", "esquilo", "coruja"]


def start_frames(dest):
    """Animal no meio de um quadrado 1024×1024 verde, com espaço por cima para saltar."""
    os.makedirs(dest, exist_ok=True)
    for a in ANIMALS:
        im = Image.open(os.path.join(IMG, a + ".png")).convert("RGBA")
        im = im.crop(im.getchannel("A").getbbox())
        k = 560 / max(im.size)
        im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
        bg = Image.new("RGBA", (1024, 1024), GREEN + (255,))
        bg.alpha_composite(im, ((1024 - im.width) // 2, 1024 - 120 - im.height))
        path = os.path.join(dest, f"partida_{a}.png")
        bg.convert("RGB").save(path)
        print("ok", path)


def key(frame, bg):
    """Alfa pela distância à cor do fundo; tira o reflexo verde das bordas."""
    f = frame.astype(np.float32)
    ch = int(np.argmax(bg))
    others = [c for c in range(3) if c != ch]
    cap = f[..., others].max(axis=2)
    # quanto o canal do fundo (verde) sobressai: alto no fundo e nas sombras verdes escuras,
    # perto de zero no animal (até no cachecol verde-azulado do ouriço)
    dom = f[..., ch] - cap
    alpha = np.clip((90.0 - dom) / 50.0, 0.0, 1.0)
    # despill: onde o canal dominante do fundo sobressai, baixa-o para o nível dos outros
    spill = f[..., ch] > cap
    edge = alpha < 0.999
    f[..., ch] = np.where(spill & edge, cap, f[..., ch])
    alpha[alpha < 0.08] = 0.0
    rgba = np.dstack([f, alpha * 255.0]).clip(0, 255).astype(np.uint8)
    return Image.fromarray(rgba, "RGBA")


def outline(tile, px):
    """Contorno azul-marinho à volta do animal (como tools/outline.py), para vídeos que o perdem."""
    a = tile.getchannel("A").point(lambda v: 255 if v > 40 else 0)
    grown = a.filter(ImageFilter.MaxFilter(px * 2 + 1)).filter(ImageFilter.GaussianBlur(0.7))
    out = Image.new("RGBA", tile.size, (52, 48, 60, 255))
    out.putalpha(grown)
    out.alpha_composite(tile)
    return out


def convert(video, name, fps, size, start, end, cols, thick=0):
    with tempfile.TemporaryDirectory() as tmp:
        cmd = ["ffmpeg", "-v", "error", "-y"]
        if start:
            cmd += ["-ss", str(start)]
        if end:
            cmd += ["-to", str(end)]
        cmd += ["-i", video, "-vf", f"fps={fps}", os.path.join(tmp, "f%04d.png")]
        subprocess.run(cmd, check=True)
        files = sorted(glob.glob(os.path.join(tmp, "f*.png")))
        if not files:
            raise SystemExit("o vídeo não deu frames")
        frames = [np.array(Image.open(p).convert("RGB")) for p in files]
    # cor do fundo: mediana da moldura do primeiro frame
    f0 = frames[0]
    border = np.concatenate([f0[:8].reshape(-1, 3), f0[-8:].reshape(-1, 3),
                             f0[:, :8].reshape(-1, 3), f0[:, -8:].reshape(-1, 3)])
    bg = np.median(border, axis=0).astype(np.float32)
    keyed = [key(f, bg) for f in frames]
    # um corte igual para todos os frames (o animal não "salta" de sítio)
    # (inclui as bordas suaves do contorno, para não cortar pontas de orelhas)
    boxes = [k.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox() for k in keyed]
    boxes = [b for b in boxes if b]
    x0 = min(b[0] for b in boxes); y0 = min(b[1] for b in boxes)
    x1 = max(b[2] for b in boxes); y1 = max(b[3] for b in boxes)
    # margem à volta: 6% de cada lado, mais o contorno que se acrescente
    side = int(max(x1 - x0, y1 - y0) * 1.12)
    if thick:
        side += int(2 * thick * side / size) + 4
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    box = (cx - side // 2, cy - side // 2, cx - side // 2 + side, cy - side // 2 + side)
    tiles = [k.crop(box).resize((size, size), Image.LANCZOS) for k in keyed]
    if thick:
        tiles = [outline(t, thick) for t in tiles]
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * size, rows * size), (0, 0, 0, 0))
    for i, t in enumerate(tiles):
        sheet.alpha_composite(t, ((i % cols) * size, (i // cols) * size))
    os.makedirs(OUT, exist_ok=True)
    sheet.save(os.path.join(OUT, name + ".png"), optimize=True)
    json.dump({"frames": len(tiles), "cols": cols, "size": size, "fps": fps},
              open(os.path.join(OUT, name + ".json"), "w"))
    print(f"ok {name}: {len(tiles)} frames, fundo {bg.astype(int).tolist()}")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("video", nargs="?")
    ap.add_argument("name", nargs="?")
    ap.add_argument("--fps", type=int, default=12)
    ap.add_argument("--size", type=int, default=320)
    ap.add_argument("--start", type=float, default=0.0)
    ap.add_argument("--end", type=float, default=0.0)
    ap.add_argument("--cols", type=int, default=8)
    ap.add_argument("--outline", type=int, default=0, help="engrossa o contorno (píxeis)")
    ap.add_argument("--start-frames", action="store_true")
    a = ap.parse_args()
    if a.start_frames:
        start_frames(os.path.join(ROOT, "assets", "images", "fontes", "videos"))
    else:
        convert(a.video, a.name, a.fps, a.size, a.start, a.end, a.cols, a.outline)
