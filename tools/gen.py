"""Gerador de níveis para Pegadas na Neve.

Regras:
- Cada animal vai da toca até à comida, movendo-se à sua maneira:
  ourico: 1 casa ortogonal | coelho: salta exatamente 2 casas ortogonal (por cima de tudo)
  raposa: 1 casa na diagonal
- Nenhuma casa é pisada duas vezes (por ninguém). Rochas não se pisam.
- Dois movimentos diagonais não se podem cruzar em X.
- Números nas bordas = casas pisadas (inclui toca e comida) em cada linha/coluna.
- Pegadas visíveis (pistas) indicam uma casa por onde passa aquela espécie.
"""
import json, random, sys
from ortools.sat.python import cp_model

MOVES = {
    "ourico": [(0, 1), (0, -1), (1, 0), (-1, 0)],
    "coelho": [(0, 2), (0, -2), (2, 0), (-2, 0)],
    "raposa": [(1, 1), (1, -1), (-1, 1), (-1, -1)],
}


def solve(level, limit=2, exclude_edges=None):
    """Devolve lista de soluções (até `limit`). Solução = {animal: [células em ordem]}."""
    W, H = level["w"], level["h"]
    rocks = set(map(tuple, level["rocks"]))
    animals = level["animals"]
    cells = [(r, c) for r in range(H) for c in range(W)]
    idx = {cell: i for i, cell in enumerate(cells)}
    m = cp_model.CpModel()
    x, edges, diag = {}, {}, []
    special = {}
    for a in animals:
        special[tuple(a["den"])] = a["type"]
        special[tuple(a["food"])] = a["type"]
    givens = {tuple(g["cell"]): g["type"] for g in level.get("givens", [])}

    for a in animals:
        t = a["type"]
        den, food = tuple(a["den"]), tuple(a["food"])
        arcs = []
        for cell in cells:
            ok = cell not in rocks and (cell not in special or special[cell] == t) and (cell not in givens or givens[cell] == t)
            v = m.NewBoolVar(f"x_{t}_{cell}")
            x[t, cell] = v
            if not ok:
                m.Add(v == 0)
            if cell in (den, food):
                m.Add(v == 1)
            # self loop when not visited
            arcs.append((idx[cell], idx[cell], v.Not()))
        for (r, c) in cells:
            for dr, dc in MOVES[t]:
                n = (r + dr, c + dc)
                if n not in idx:
                    continue
                if (r, c) == food or n == den:
                    continue
                e = m.NewBoolVar(f"e_{t}_{r}_{c}_{n}")
                edges[t, (r, c), n] = e
                m.AddImplication(e, x[t, (r, c)])
                m.AddImplication(e, x[t, n])
                arcs.append((idx[(r, c)], idx[n], e))
                if t == "raposa":
                    diag.append(((r, c), n, e))
        # closing arc food -> den
        one = m.NewBoolVar("one"); m.Add(one == 1); arcs.append((idx[food], idx[den], one))
        m.AddCircuit(arcs)
        if t in givens.values():
            for cell, gt in givens.items():
                if gt == t:
                    m.Add(x[t, cell] == 1)

    for cell in cells:
        m.Add(sum(x[a["type"], cell] for a in animals) <= 1)
    # diagonal crossings
    seg = {}
    for (u, v, e) in diag:
        key = (min(u[0], v[0]), min(u[1], v[1]), (u[0] - v[0]) * (u[1] - v[1]) > 0)
        seg.setdefault(key, []).append(e)
    for (r, c, main), es in list(seg.items()):
        other = seg.get((r, c, not main), [])
        if other:
            a_ = m.NewBoolVar("")
            m.AddMaxEquality(a_, es)
            b_ = m.NewBoolVar("")
            m.AddMaxEquality(b_, other)
            m.AddBoolOr([a_.Not(), b_.Not()])
    # counts
    for r in range(H):
        m.Add(sum(x[a["type"], (r, c)] for a in animals for c in range(W)) == level["rows"][r])
    for c in range(W):
        m.Add(sum(x[a["type"], (r, c)] for a in animals for r in range(H)) == level["cols"][c])

    sols = []
    solver = cp_model.CpSolver()
    solver.parameters.num_workers = 8
    solver.parameters.max_time_in_seconds = 20
    while len(sols) < limit:
        st = solver.Solve(m)
        if st not in (cp_model.OPTIMAL, cp_model.FEASIBLE):
            break
        used = [e for e in edges.values() if solver.Value(e)]
        sol = {}
        for a in animals:
            t = a["type"]
            nxt = {u: v for (tt, u, v), e in edges.items() if tt == t and solver.Value(e)}
            p = [tuple(a["den"])]
            while p[-1] != tuple(a["food"]):
                p.append(nxt[p[-1]])
            sol[t] = p
        sols.append(sol)
        m.AddBoolOr([e.Not() for e in used])
    return sols


def random_path(t, start, W, H, blocked, length, rng):
    """Caminho aleatório auto-evitante de `length` casas."""
    for _ in range(400):
        p = [start]
        used = set(blocked) | {start}
        ok = True
        while len(p) < length:
            r, c = p[-1]
            opts = []
            for dr, dc in MOVES[t]:
                n = (r + dr, c + dc)
                if 0 <= n[0] < H and 0 <= n[1] < W and n not in used:
                    if t == "raposa" and crosses(p, (r, c), n):
                        continue
                    opts.append(n)
            if not opts:
                ok = False
                break
            n = rng.choice(opts)
            p.append(n)
            used.add(n)
        if ok:
            return p
    return None


_diag_segments = []


def crosses(p, u, v):
    for s in _diag_segments + list(zip(p, p[1:])):
        a, b = s
        if abs(a[0] - b[0]) == 1 and abs(a[1] - b[1]) == 1:
            if {a, b} == {(u[0], v[1]), (v[0], u[1])}:
                return True
    return False


def make_level(spec, rng):
    W, H = spec["size"]
    for attempt in range(300):
        _diag_segments.clear()
        rocks = set()
        while len(rocks) < spec.get("rocks", 0):
            rocks.add((rng.randrange(H), rng.randrange(W)))
        occupied = set(rocks)
        paths = {}
        fail = False
        for t, (lo, hi) in spec["animals"]:
            free = [(r, c) for r in range(H) for c in range(W) if (r, c) not in occupied]
            rng.shuffle(free)
            path = None
            for s in free[:20]:
                path = random_path(t, s, W, H, occupied, rng.randint(lo, hi), rng)
                if path:
                    break
            if not path:
                fail = True
                break
            # comida não pode estar à distância de um só movimento da toca (fica trivial)
            paths[t] = path
            occupied |= set(path)
            if t == "raposa":
                _diag_segments.extend(zip(path, path[1:]))
        if fail:
            continue
        # rochas inúteis fora? ok
        rows = [0] * H
        cols = [0] * W
        for p in paths.values():
            for (r, c) in p:
                rows[r] += 1
                cols[c] += 1
        level = {
            "w": W, "h": H, "rocks": sorted(map(list, rocks)),
            "animals": [{"type": t, "den": list(p[0]), "food": list(p[-1])} for t, p in paths.items()],
            "rows": rows, "cols": cols, "givens": [],
        }
        # tornar único adicionando pistas
        ok = True
        for _ in range(40):
            sols = solve(level, 2)
            if not sols:
                ok = False
                break
            if len(sols) == 1:
                break
            # escolher a solução que não é a nossa; adicionar pista que a elimina
            alt = sols[0] if sols[0] != paths else sols[1]
            cand = []
            for t, p in paths.items():
                alt_cells = set(alt[t])
                for cell in p[1:-1]:
                    if cell not in alt_cells:
                        cand.append((t, cell))
            if not cand:
                ok = False
                break
            t, cell = rng.choice(cand)
            level["givens"].append({"type": t, "cell": list(cell)})
        else:
            ok = False
        if not ok or len(solve(level, 2)) != 1:
            continue
        # minimizar pistas
        gs = level["givens"][:]
        rng.shuffle(gs)
        for g in gs:
            trial = dict(level)
            trial["givens"] = [h for h in level["givens"] if h is not g]
            if len(solve(trial, 2)) == 1:
                level = trial
        # pistas extra para níveis fáceis
        extra = spec.get("extra", 0)
        pool = [(t, c) for t, p in paths.items() for c in p[1:-1]
                if {"type": t, "cell": list(c)} not in level["givens"]]
        rng.shuffle(pool)
        for t, c in pool[:extra]:
            level["givens"].append({"type": t, "cell": list(c)})
        mn, mx = spec.get("givens_range", (0, 99))
        if not (mn <= len(level["givens"]) <= mx):
            continue
        level["solution"] = {t: [list(c) for c in p] for t, p in paths.items()}
        return level
    raise RuntimeError(f"falhou {spec}")


SPECS = [
    # Mundo 1 — Clareira
    {"name": "Primeiros passos", "size": (4, 4), "animals": [("ourico", (7, 9))], "extra": 2},
    {"name": "Caracol", "size": (5, 5), "animals": [("ourico", (10, 13))], "extra": 1},
    {"name": "Salto a salto", "size": (5, 5), "animals": [("coelho", (5, 6))], "extra": 1},
    {"name": "Vizinhos", "size": (5, 5), "animals": [("ourico", (7, 9)), ("coelho", (4, 5))], "extra": 1},
    {"name": "Trilhos cruzados", "size": (6, 6), "animals": [("ourico", (10, 13)), ("coelho", (5, 6))]},
    {"name": "Neve funda", "size": (6, 6), "animals": [("ourico", (12, 15)), ("coelho", (6, 7))], "givens_range": (0, 2)},
    # Mundo 2 — Bosque
    {"name": "Passo de raposa", "size": (5, 5), "animals": [("raposa", (6, 8))], "rocks": 3, "extra": 1},
    {"name": "Entre rochas", "size": (5, 5), "animals": [("ourico", (7, 9)), ("raposa", (5, 6))], "rocks": 3, "extra": 1},
    {"name": "Por cima das pedras", "size": (6, 6), "animals": [("coelho", (5, 7)), ("raposa", (6, 8))], "rocks": 4},
    {"name": "Três trilhos", "size": (6, 6), "animals": [("ourico", (8, 11)), ("coelho", (4, 6)), ("raposa", (5, 7))], "rocks": 3},
    {"name": "Bosque cerrado", "size": (7, 7), "animals": [("ourico", (11, 15)), ("coelho", (5, 7)), ("raposa", (7, 9))], "rocks": 5},
    {"name": "Tempestade", "size": (7, 7), "animals": [("ourico", (13, 17)), ("coelho", (6, 8)), ("raposa", (7, 10))], "rocks": 4, "givens_range": (0, 3)},
]

if __name__ == "__main__":
    seed = int(sys.argv[1]) if len(sys.argv) > 1 else 7
    rng = random.Random(seed)
    out = []
    for i, spec in enumerate(SPECS):
        lv = make_level(spec, rng)
        lv["name"] = spec["name"]
        lv["world"] = 1 if i < 6 else 2
        out.append(lv)
        print(i + 1, spec["name"], f'{lv["w"]}x{lv["h"]}', "pistas:", len(lv["givens"]), file=sys.stderr)
    json.dump(out, open("data/levels.json", "w"))
