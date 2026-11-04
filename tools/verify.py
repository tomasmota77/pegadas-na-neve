"""Verificador independente (força bruta) — conta soluções até 2."""
import json, sys
import os, sys; sys.path.insert(0, os.path.dirname(__file__)); from gen import MOVES

def count(level, cap=2):
    W, H = level["w"], level["h"]
    rocks = set(map(tuple, level["rocks"]))
    animals = level["animals"]
    givens = {tuple(g["cell"]): g["type"] for g in level["givens"]}
    special = {}
    for a in animals:
        special[tuple(a["den"])] = a["type"]; special[tuple(a["food"])] = a["type"]
    rows, cols = level["rows"], level["cols"]
    rc, cc = [0]*H, [0]*W
    used = set()
    diags = set()
    found = []

    def can(cell, t):
        r, c = cell
        if not (0 <= r < H and 0 <= c < W): return False
        if cell in rocks or cell in used: return False
        if cell in special and special[cell] != t: return False
        if cell in givens and givens[cell] != t: return False
        if rc[r] + 1 > rows[r] or cc[c] + 1 > cols[c]: return False
        return True

    def put(cell, d):
        used.add(cell) if d > 0 else used.discard(cell)
        rc[cell[0]] += d; cc[cell[1]] += d

    def go(i, path):
        if len(found) >= cap: return
        if i == len(animals):
            if rc == rows and cc == cols:
                found.append(1)
            return
        a = animals[i]; t = a["type"]; food = tuple(a["food"])
        cur = path[-1]
        if cur == food:
            # givens of t covered?
            for g, gt in givens.items():
                if gt == t and g not in path: return
            if i + 1 < len(animals):
                nxt = animals[i+1]; d = tuple(nxt["den"])
                if not can(d, nxt["type"]): return
                put(d, 1); go(i+1, [d]); put(d, -1)
            else:
                go(i+1, None)
            return
        for dr, dc in MOVES[t]:
            n = (cur[0]+dr, cur[1]+dc)
            if not can(n, t): continue
            if n == tuple(a["den"]): continue
            key = None
            if t == "raposa":
                key = (min(cur[0], n[0]), min(cur[1], n[1]))
                if key in diags: continue  # any diagonal in same 2x2 = crossing (same one impossible since cells used)
            put(n, 1)
            if key: diags.add(key)
            go(i, path + [n])
            if key: diags.discard(key)
            put(n, -1)

    d = tuple(animals[0]["den"])
    put(d, 1); go(0, [d])
    return len(found)

def draw(lv):
    H, W = lv["h"], lv["w"]
    g = [["." for _ in range(W)] for _ in range(H)]
    for r, c in lv["rocks"]: g[r][c] = "#"
    sym = {"ourico": "o", "coelho": "c", "raposa": "r"}
    for t, p in lv["solution"].items():
        for (r, c) in p: g[r][c] = sym[t]
        g[p[0][0]][p[0][1]] = sym[t].upper()
        g[p[-1][0]][p[-1][1]] = "*"
    for gv in lv["givens"]:
        r, c = gv["cell"]; g[r][c] = "+"
    print("   " + " ".join(map(str, lv["cols"])))
    for r in range(H):
        print(f"{lv['rows'][r]:2} " + " ".join(g[r]))

if __name__ == "__main__":
    levels = json.load(open(sys.argv[1] if len(sys.argv) > 1 else "data/levels.json"))
    for i, lv in enumerate(levels):
        n = count(lv)
        print(f"--- {i+1} {lv.get('id', lv.get('name'))} soluções={n} pistas={len(lv['givens'])}")
        draw(lv)
