"""Medidor de dificuldade: resolve o nível como uma pessoa, por deduções.

Cada casa tem um conjunto de possibilidades: vazia ou um dos animais.
Regras simples (aplicadas até não mudarem nada):
  - contagens: se uma linha já tem todas as casas pisadas, as outras ficam vazias;
    se só sobram as casas que faltam, ficam todas pisadas
  - alcance: um animal só pode estar numa casa que consiga alcançar a partir da toca
    e de onde ainda consiga chegar à comida (com as regras do gelo)
  - ligações: a toca precisa de uma saída, a comida de uma entrada e cada casa do
    caminho de uma entrada e uma saída diferentes; se só houver uma hipótese, fica marcada
Quando as regras simples param, tenta "e se": supõe uma possibilidade e vê se dá
contradição (profundidade 1). Se nem assim chegar ao fim, o nível é "profundo".

nota(): 1 a 10, para ordenar e mostrar dificuldade.
"""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from rules import moves


class Contradiction(Exception):
    pass


class Rater:
    def __init__(self, level):
        self.W, self.H = W, H = level["w"], level["h"]
        self.level = level
        self.cells = [(r, c) for r in range(H) for c in range(W)]
        self.idx = {c: i for i, c in enumerate(self.cells)}
        n = len(self.cells)
        rocks = set(map(tuple, level["rocks"]))
        self.ice = [c in set(map(tuple, level.get("ice", []))) for c in self.cells]
        self.animals = [a["type"] for a in level["animals"]]
        self.den = [self.idx[tuple(a["den"])] for a in level["animals"]]
        self.food = [self.idx[tuple(a["food"])] for a in level["animals"]]
        k = len(self.animals)
        full = (1 << (k + 1)) - 1          # bit 0 = vazia, bit i+1 = animal i
        self.start = [full] * n
        for i, c in enumerate(self.cells):
            if c in rocks:
                self.start[i] = 1
        self.rock = [c in rocks for c in self.cells]
        for a in range(k):
            for j in (self.den[a], self.food[a]):
                self.start[j] = 1 << (a + 1)
        for g in level.get("givens", []):
            a = self.animals.index(g["type"])
            self.start[self.idx[tuple(g["cell"])]] = 1 << (a + 1)
        # tabelas de movimentos: succ[a][i] = [(j, vid)]
        self.succ, self.pred, self.vecs = [], [], []
        for t in self.animals:
            mv = moves(t, W, H)
            self.vecs.append(mv)
            s = [[] for _ in range(n)]
            p = [[] for _ in range(n)]
            for i, (r, c) in enumerate(self.cells):
                for vid, (dr, dc) in enumerate(mv):
                    q = (r + dr, c + dc)
                    if q in self.idx and not self.rock[self.idx[q]]:
                        j = self.idx[q]
                        s[i].append((j, vid))
                        p[j].append((i, vid))
            self.succ.append(s)
            self.pred.append(p)
        self.lines = []
        for r in range(H):
            if level["rows"][r] is not None:
                self.lines.append(([self.idx[(r, c)] for c in range(W) if not self.rock[self.idx[(r, c)]]], level["rows"][r]))
        for c in range(W):
            if level["cols"][c] is not None:
                self.lines.append(([self.idx[(r, c)] for r in range(H) if not self.rock[self.idx[(r, c)]]], level["cols"][c]))

    # ---------- regras simples ----------

    def propagate(self, poss):
        changed = True
        while changed:
            changed = False
            changed |= self._counts(poss)
            for a in range(len(self.animals)):
                changed |= self._reach(poss, a)
                changed |= self._links(poss, a)
        return poss

    def _set(self, poss, i, mask):
        new = poss[i] & mask
        if new == 0:
            raise Contradiction
        if new != poss[i]:
            poss[i] = new
            return True
        return False

    def _counts(self, poss):
        ch = False
        for cells, target in self.lines:
            sure = sum(1 for i in cells if not poss[i] & 1)
            maybe = [i for i in cells if poss[i] & 1 and poss[i] != 1]
            if sure > target or sure + len(maybe) < target:
                raise Contradiction
            if sure == target:
                for i in maybe:
                    ch |= self._set(poss, i, 1)
            elif sure + len(maybe) == target:
                for i in maybe:
                    ch |= self._set(poss, i, ~1)
        return ch

    def _reach(self, poss, a):
        bit = 1 << (a + 1)
        den, food = self.den[a], self.food[a]
        succ, ice = self.succ[a], self.ice
        start = (den, -1)
        seen = {start}
        stack = [start]
        edges = []
        while stack:
            i, vin = stack.pop()
            if i == food:
                continue
            forced = vin if (ice[i] and vin >= 0) else None
            for j, vid in succ[i]:
                if forced is not None and vid != forced:
                    continue
                if j == den or not poss[j] & bit:
                    continue
                st = (j, vid if ice[j] else -1)
                edges.append(((i, vin), st))
                if st not in seen:
                    seen.add(st)
                    stack.append(st)
        # para trás, a partir da comida
        back = {}
        for u, v in edges:
            back.setdefault(v, []).append(u)
        good = {s for s in seen if s[0] == food}
        if not good:
            raise Contradiction
        stack = list(good)
        while stack:
            v = stack.pop()
            for u in back.get(v, ()):
                if u not in good:
                    good.add(u)
                    stack.append(u)
        ok = {s[0] for s in good}
        ch = False
        for i in range(len(poss)):
            if poss[i] & bit and i not in ok:
                ch |= self._set(poss, i, ~bit)
        return ch

    def _links(self, poss, a):
        bit = 1 << (a + 1)
        den, food = self.den[a], self.food[a]
        ch = False
        for i in range(len(poss)):
            if poss[i] != bit:
                continue
            outs = [(j, v) for j, v in self.succ[a][i] if poss[j] & bit and j != den] if i != food else []
            ins = [(j, v) for j, v in self.pred[a][i] if poss[j] & bit and j != food] if i != den else []
            if i == den:
                if not outs:
                    raise Contradiction
                if len({j for j, _ in outs}) == 1:
                    ch |= self._set(poss, outs[0][0], bit)
                continue
            if i == food:
                if not ins:
                    raise Contradiction
                if len({j for j, _ in ins}) == 1:
                    ch |= self._set(poss, ins[0][0], bit)
                continue
            pairs = [(p, s) for p, vp in ins for s, vs in outs if p != s and (not self.ice[i] or vp == vs)]
            if not pairs:
                raise Contradiction
            ps = {p for p, _ in pairs}
            ss = {s for _, s in pairs}
            if len(ps) == 1:
                ch |= self._set(poss, next(iter(ps)), bit)
            if len(ss) == 1:
                ch |= self._set(poss, next(iter(ss)), bit)
        return ch

    # ---------- resolver ----------

    def solved(self, poss):
        return all(m & (m - 1) == 0 for m in poss)

    def _try(self, poss, i, b):
        """Supor que a casa i tem a possibilidade b: dá contradição?"""
        trial = poss[:]
        trial[i] = b
        try:
            self.propagate(trial)
        except Contradiction:
            return True
        return False

    def _try2(self, poss, i, b):
        """Supor b na casa i e, dentro dessa suposição, ainda tentar um nível de "e se"."""
        trial = poss[:]
        trial[i] = b
        try:
            self.propagate(trial)
            for _ in range(4):
                if self.solved(trial):
                    return False
                found = self._sweep(trial, limit=2)
                if not found:
                    return False
                for j, c in found:
                    trial[j] &= ~c
                    if trial[j] == 0:
                        return True
                self.propagate(trial)
        except Contradiction:
            return True
        return False

    def _sweep(self, poss, limit=3):
        found = []
        order = sorted((i for i, m in enumerate(poss) if m & (m - 1)), key=lambda i: bin(poss[i]).count("1"))
        for i in order:
            m = poss[i]
            b = 1
            while b <= m:
                if m & b and self._try(poss, i, b):
                    found.append((i, b))
                b <<= 1
            if len(found) >= limit:
                break
        return found

    def run(self, max_rounds=60, deep=True):
        poss = self.start[:]
        self.propagate(poss)
        rounds = elims = rounds2 = 0
        while not self.solved(poss) and rounds + rounds2 < max_rounds:
            found = []
            # casas por decidir, das mais "apertadas" primeiro
            order = sorted((i for i, m in enumerate(poss) if m & (m - 1)), key=lambda i: bin(poss[i]).count("1"))
            for i in order:
                m = poss[i]
                b = 1
                while b <= m:
                    if m & b and self._try(poss, i, b):
                        found.append((i, b))
                    b <<= 1
                if len(found) >= 3:
                    break
            if found:
                rounds += 1
            elif deep:
                order = sorted((i for i, m in enumerate(poss) if m & (m - 1)), key=lambda i: bin(poss[i]).count("1"))
                for i in order:
                    m = poss[i]
                    b = 1
                    while b <= m and not found:
                        if m & b and self._try2(poss, i, b):
                            found.append((i, b))
                        b <<= 1
                    if found:
                        break
                if not found:
                    break
                rounds2 += 1
            else:
                break
            for i, b in found:
                poss[i] &= ~b
                elims += 1
            self.propagate(poss)
        left = sum(1 for m in poss if m & (m - 1))
        return {"rounds": rounds, "rounds2": rounds2, "elims": elims, "left": left, "solved": left == 0}


def score(level):
    """Esforço numa escala contínua (maior = mais difícil)."""
    r = Rater(level).run()
    s = 2.0 * r["rounds"] + 0.3 * r["elims"] + 7.0 * r["rounds2"] + 0.04 * level["w"] * level["h"] \
        + 1.5 * len(level["animals"])
    if not r["solved"]:
        s += 30 + 40 * r["left"] / (level["w"] * level["h"])
    return round(s, 2), r


if __name__ == "__main__":
    import json
    levels = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "data/levels.json"))
    for i, lv in enumerate(levels):
        s, r = score(lv)
        print(i + 1, lv.get("id"), f'{lv["w"]}x{lv["h"]}', "+".join(a["type"][:3] for a in lv["animals"]),
              "nota", lv.get("diff"), "esforço", s, r)
