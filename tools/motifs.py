"""Melodia curta de cada animal (som de apresentação), feita com a nota de celesta do jogo.

Usa assets/sounds/nota.ogg (a mesma nota dos passos) e toca-a a várias alturas, para que
os sons dos animais combinem com o resto do jogo. Escreve assets/sounds/animal_<animal>.ogg.

Uso: python tools/motifs.py
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

ROOT = os.path.join(os.path.dirname(__file__), "..")
SND = os.path.join(ROOT, "assets", "sounds")
SR = 44100

# (semitons em relação ao Dó da nota, segundos até à nota seguinte)
MOTIFS = {
    "ourico": [(0, 0.17), (4, 0.17), (7, 0.0)],                         # sobe devagar, aconchegado
    "coelho": [(7, 0.09), (12, 0.09), (7, 0.09), (12, 0.0)],             # pulinhos
    "raposa": [(4, 0.12), (7, 0.12), (9, 0.12), (7, 0.0)],               # brincalhona
    "esquilo": [(9, 0.065), (7, 0.065), (9, 0.065), (12, 0.1), (12, 0.0)],  # rápido, tagarela
    "coruja": [(-5, 0.26), (-8, 0.0)],                                   # "uu-uu" grave e suave
}


def load_note():
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "n.wav")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", os.path.join(SND, "nota.ogg"),
                        "-ac", "1", "-ar", str(SR), wav], check=True)
        w = wave.open(wav)
        return np.frombuffer(w.readframes(w.getnframes()), np.int16).astype(np.float32) / 32768


def pitched(x, semis):
    """Muda a altura como uma caixa de música: mais aguda = mais curta."""
    k = 2 ** (semis / 12)
    idx = np.arange(0, len(x) - 1, k)
    return np.interp(idx, np.arange(len(x)), x)


def build(note, motif):
    t, parts = 0.0, []
    for semis, gap in motif:
        parts.append((t, pitched(note, semis)))
        t += gap
    n = int((t + 0.1) * SR) + max(len(p) for _, p in parts)
    out = np.zeros(n, np.float32)
    for k, (start, p) in enumerate(parts):
        s = int(start * SR)
        # a última nota soa um pouco mais forte, para fechar a frase
        out[s:s + len(p)] += p * (1.0 if k == len(parts) - 1 else 0.8)
    out /= max(1e-6, np.abs(out).max())
    return out * 0.8


def save(x, path):
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "m.wav")
        w = wave.open(wav, "wb")
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
        w.close()
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-af",
                        "silenceremove=stop_periods=1:stop_threshold=-55dB,loudnorm=I=-18:TP=-2",
                        "-ar", str(SR), "-c:a", "libvorbis", "-q:a", "5", path], check=True)


if __name__ == "__main__":
    note = load_note()
    for animal, motif in MOTIFS.items():
        save(build(note, motif), os.path.join(SND, f"animal_{animal}.ogg"))
        print("ok", animal)
