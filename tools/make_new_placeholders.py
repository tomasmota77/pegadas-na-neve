"""Marcadores provisórios (sem emojis) para as imagens novas. Não toca em imagens que já existam."""
from PIL import Image, ImageDraw, ImageFont
import os
ROOT = os.path.join(os.path.dirname(__file__), "..")
OUT = os.path.join(ROOT, "assets", "images")
FONT = os.path.join(ROOT, "assets", "fonts", "Baloo2-Bold.ttf")
NAVY = (52, 48, 60, 255)
OWL = (61, 127, 193, 255)

def save(im, name):
    path = os.path.join(OUT, name + ".png")
    if os.path.exists(path):
        print("já existe:", name); return
    im.save(path); print("criado:", name)

def canvas(n=512):
    im = Image.new("RGBA", (n, n), (0, 0, 0, 0)); return im, ImageDraw.Draw(im)

def text(d, s, xy, size, fill):
    d.text(xy, s, font=ImageFont.truetype(FONT, size), fill=fill, anchor="mm")

# coruja: corpo oval azul com olhos grandes
im, d = canvas()
d.ellipse([96, 90, 416, 470], fill=OWL, outline=NAVY, width=18)
d.polygon([(150, 120), (190, 40), (230, 120)], fill=OWL, outline=NAVY)
d.polygon([(282, 120), (322, 40), (362, 120)], fill=OWL, outline=NAVY)
for cx in (200, 312):
    d.ellipse([cx - 62, 170, cx + 62, 294], fill=(255, 255, 255, 255), outline=NAVY, width=12)
    d.ellipse([cx - 26, 206, cx + 26, 258], fill=NAVY)
d.polygon([(236, 290), (276, 290), (256, 330)], fill=(242, 150, 44, 255), outline=NAVY)
save(im, "coruja")
# ninho
im, d = canvas()
d.ellipse([70, 220, 442, 440], fill=(150, 104, 66, 255), outline=NAVY, width=18)
for cx in (196, 256, 316):
    d.ellipse([cx - 46, 160, cx + 46, 290], fill=(236, 238, 245, 255), outline=NAVY, width=12)
d.ellipse([90, 250, 422, 330], fill=(175, 126, 84, 255))
save(im, "comida_coruja")
# pegada da coruja: 3 dedos à frente e 1 atrás, branca
im, d = canvas(256)
W = (255, 255, 255, 255)
c = (128, 150)
for end in [(128, 30), (55, 70), (201, 70), (128, 236)]:
    d.line([c, end], fill=W, width=26)
    d.ellipse([end[0] - 14, end[1] - 14, end[0] + 14, end[1] + 14], fill=W)
d.ellipse([c[0] - 26, c[1] - 26, c[0] + 26, c[1] + 26], fill=W)
save(im, "pegada_coruja")
# gelo: quadrado azul claro com brilhos
im, d = canvas()
d.rounded_rectangle([40, 40, 472, 472], radius=90, fill=(190, 228, 247, 255), outline=(120, 186, 222, 255), width=16)
d.line([(130, 200), (260, 120)], fill=W, width=34)
d.line([(160, 290), (230, 250)], fill=W, width=26)
save(im, "gelo")
# nevão: nuvem cinzenta com flocos
im, d = canvas()
G = (196, 206, 222, 255)
for box in [(80, 200, 260, 360), (180, 130, 380, 330), (300, 210, 450, 360), (120, 260, 420, 380)]:
    d.ellipse(box, fill=G)
for (x, y) in [(170, 430), (260, 450), (350, 425)]:
    d.ellipse([x - 16, y - 16, x + 16, y + 16], fill=W, outline=(160, 175, 196, 255), width=6)
save(im, "nevao")
# número tapado: monte de neve com "?"
im, d = canvas(256)
d.ellipse([24, 60, 232, 220], fill=W, outline=(170, 190, 212, 255), width=10)
text(d, "?", (128, 146), 120, (125, 142, 166, 255))
save(im, "numero_tapado")
