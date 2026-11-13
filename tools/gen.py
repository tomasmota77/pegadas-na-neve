"""Gerador de níveis para Pegadas na Neve.

Regras: ver tools/rules.py. Cada nível tem uma única solução (confirmada com CP-SAT)
e uma nota de dificuldade (tools/rate.py, que resolve como uma pessoa).

Uso:
    python tools/gen.py            # gera data/levels.json (6 mundos x 12 níveis)
    python tools/gen.py daily 120  # gera data/daily.json (puzzles do dia)
"""
import json, os, random, sys
from multiprocessing import Pool
from ortools.sat.python import cp_model

sys.path.insert(0, os.path.dirname(__file__))
from rules import moves, diag_cross, check_solution
import rate


# ---------------------------------------------------------------- solucionador

def solve(level, limit=2):
    """Devolve até `limit` soluções ({tipo: [células]})."""
    W, H = level["w"], level["h"]
    rocks = set(map(tuple, level["rocks"]))
    ice = set(map(tuple, level.get("ice", [])))
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
        ins, outs = {}, {}
        for cell in cells:
            ok = cell not in rocks and (cell not in special or special[cell] == t) and \
                (cell not in givens or givens[cell] == t)
            v = m.NewBoolVar("")
            x[t, cell] = v
            if not ok:
                m.Add(v == 0)
            if cell in (den, food) or givens.get(cell) == t:
                m.Add(v == 1)
            arcs.append((idx[cell], idx[cell], v.Not()))
        for (r, c) in cells:
            if (r, c) in rocks or (r, c) == food:
                continue
            for dr, dc in moves(t, W, H):
                n = (r + dr, c + dc)
                if n not in idx or n in rocks or n == den:
                    continue
                e = m.NewBoolVar("")
                edges[t, (r, c), n] = e
                m.AddImplication(e, x[t, (r, c)])
                m.AddImplication(e, x[t, n])
                arcs.append((idx[(r, c)], idx[n], e))
                outs.setdefault((r, c), []).append(((dr, dc), e))
                ins.setdefault(n, []).append(((dr, dc), e))
                if t == "raposa":
                    diag.append(((r, c), n, e))
        one = m.NewBoolVar("")
        m.Add(one == 1)
        arcs.append((idx[food], idx[den], one))
        m.AddCircuit(arcs)
        # gelo: o movimento que sai tem de ser igual ao que entrou
        for cell in ice:
            for vi, ei in ins.get(cell, []):
                for vo, eo in outs.get(cell, []):
                    if vi != vo:
                        m.AddBoolOr([ei.Not(), eo.Not()])

    for cell in cells:
        m.Add(sum(x[a["type"], cell] for a in animals) <= 1)
    seg = {}
    for (u, v, e) in diag:
        key = (min(u[0], v[0]), min(u[1], v[1]), (u[0] - v[0]) * (u[1] - v[1]) > 0)
        seg.setdefault(key, []).append(e)
    for (r, c, main), es in list(seg.items()):
        other = seg.get((r, c, not main), [])
        if other and main:
            for a_ in es:
                for b_ in other:
                    m.AddBoolOr([a_.Not(), b_.Not()])
    for r in range(H):
        if level["rows"][r] is not None:
            m.Add(sum(x[a["type"], (r, c)] for a in animals for c in range(W)) == level["rows"][r])
    for c in range(W):
        if level["cols"][c] is not None:
            m.Add(sum(x[a["type"], (r, c)] for a in animals for r in range(H)) == level["cols"][c])

    sols = []
    solver = cp_model.CpSolver()
    solver.parameters.num_workers = 1
    solver.parameters.max_time_in_seconds = 30
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


# ---------------------------------------------------------------- construção

def random_path(t, start, W, H, blocked, ice, length, rng, diag_segs):
    mv = moves(t, W, H)
    for _ in range(300):
        p = [start]
        used = set(blocked) | {start}
        ok = True
        while len(p) < length:
            r, c = p[-1]
            if p[-1] in ice and len(p) >= 2:
                opts_mv = [(r - p[-2][0], c - p[-2][1])]
            else:
                opts_mv = mv
            opts = []
            for dr, dc in opts_mv:
                n = (r + dr, c + dc)
                if 0 <= n[0] < H and 0 <= n[1] < W and n not in used:
                    if t == "raposa" and any(diag_cross((r, c), n, a, b) for a, b in diag_segs + list(zip(p, p[1:]))):
                        continue
                    opts.append(n)
            if not opts:
                ok = False
                break
            # o ouriço prefere seguir em frente às vezes (caminhos menos enrolados)
            n = rng.choice(opts)
            p.append(n)
            used.add(n)
        if ok and p[-1] not in ice:
            return p
    return None


def grow_ice(W, H, n, rocks, rng):
    ice = set()
    tries = 0
    while len(ice) < n and tries < 500:
        tries += 1
        if not ice or rng.random() < 0.25:
            c = (rng.randrange(H), rng.randrange(W))
        else:
            r, cc = rng.choice(sorted(ice))
            dr, dc = rng.choice([(0, 1), (0, -1), (1, 0), (-1, 0)])
            c = (r + dr, cc + dc)
        if 0 <= c[0] < H and 0 <= c[1] < W and c not in rocks:
            ice.add(c)
    return ice


def counts_of(paths, W, H):
    rows, cols = [0] * H, [0] * W
    for p in paths.values():
        for (r, c) in p:
            rows[r] += 1
            cols[c] += 1
    return rows, cols


def make_level(spec, rng, attempts=60):
    W, H = spec["size"]
    for attempt in range(attempts):
        rocks = set()
        while len(rocks) < spec.get("rocks", 0):
            rocks.add((rng.randrange(H), rng.randrange(W)))
        ice = grow_ice(W, H, spec.get("ice", 0), rocks, rng) if spec.get("ice") else set()
        occupied = set(rocks)
        paths = {}
        diag_segs = []
        fail = False
        for t, (lo, hi) in spec["animals"]:
            free = [(r, c) for r in range(H) for c in range(W) if (r, c) not in occupied and (r, c) not in ice]
            rng.shuffle(free)
            path = None
            for s in free[:25]:
                path = random_path(t, s, W, H, occupied, ice, rng.randint(lo, hi), rng, diag_segs)
                if path:
                    break
            if not path:
                fail = True
                break
            paths[t] = path
            occupied |= set(path)
            if t == "raposa":
                diag_segs.extend(zip(path, path[1:]))
        if fail:
            continue
        # o gelo tem de contar: casas de gelo a meio de caminhos
        if spec.get("ice_used", 0):
            used_ice = sum(1 for p in paths.values() for c in p[1:-1] if c in ice)
            if used_ice < spec["ice_used"]:
                continue
        rows, cols = counts_of(paths, W, H)
        level = {
            "w": W, "h": H, "rocks": sorted(map(list, rocks)), "ice": sorted(map(list, ice)),
            "animals": [{"type": t, "den": list(p[0]), "food": list(p[-1])} for t, p in paths.items()],
            "rows": rows, "cols": cols, "givens": [],
        }
        if not ice:
            level.pop("ice")
        ok = True
        for _ in range(30):
            sols = solve(level, 2)
            if not sols:
                ok = False
                break
            if len(sols) == 1:
                break
            alt = sols[0] if sols[0] != paths else sols[1]
            cand = [(t, cell) for t, p in paths.items() for cell in p[1:-1] if cell not in set(alt[t])]
            if not cand:
                ok = False
                break
            t, cell = rng.choice(cand)
            level["givens"].append({"type": t, "cell": list(cell)})
        else:
            ok = False
        if not ok or len(solve(level, 2)) != 1:
            continue
        gs = level["givens"][:]
        rng.shuffle(gs)
        for g in gs:
            trial = dict(level)
            trial["givens"] = [h for h in level["givens"] if h is not g]
            if len(solve(trial, 2)) == 1:
                level = trial
        if len(level["givens"]) > spec.get("max_givens", 3):
            continue
        # nevão: tapar números enquanto a solução continuar única
        hide = spec.get("hidden", 0)
        if hide:
            lines = [("rows", i) for i in range(H)] + [("cols", i) for i in range(W)]
            rng.shuffle(lines)
            hidden = 0
            for k, i in lines:
                if hidden >= hide:
                    break
                trial = json.loads(json.dumps(level))
                trial[k][i] = None
                if len(solve(trial, 2)) == 1:
                    level = trial
                    hidden += 1
            if hidden < hide:
                continue
        extra = spec.get("extra", 0)
        pool = [(t, c) for t, p in paths.items() for c in p[1:-1]
                if {"type": t, "cell": list(c)} not in level["givens"]]
        rng.shuffle(pool)
        for t, c in pool[:extra]:
            level["givens"].append({"type": t, "cell": list(c)})
        level["solution"] = {t: [list(c) for c in p] for t, p in paths.items()}
        assert check_solution(level, level["solution"])
        s, r = rate.score(level)
        if not r["solved"] and r["left"] > 6:
            continue  # precisa de adivinhar: injusto para uma pessoa
        level["score"] = s
        return level
    return None


# ---------------------------------------------------------------- mundos

def L(t, W, scale=1.0):
    """Comprimento do caminho (número de casas) por animal e tamanho."""
    base = {
        "ourico": (int(W * W * 0.26), int(W * W * 0.38)),
        "coelho": (W - 1, W + 2),
        "raposa": (W - 1, W + 2),
        "esquilo": (W - 2, W + 1),
        "coruja": (W - 2, W + 1),
    }[t]
    return (max(3, int(base[0] * scale)), max(4, int(base[1] * scale)))


def S(size, animals, **kw):
    W = size
    return {"size": (W, W), "animals": [(t, L(t, W, kw.pop("scale", 1.0))) for t in animals], **kw}


# Cada mundo: níveis de introdução (por esta ordem) e modelos para os restantes 9.
# Dos candidatos gerados com os modelos, escolhem-se 9 do mais fácil ao mais difícil;
# o 2.º mais difícil fica em 6.º lugar (Difícil) e o mais difícil fecha o mundo (Super difícil).
WORLDS = [
    ("Clareira", [
        S(4, ["ourico"], extra=2, scale=0.6),
        S(4, ["ourico"], extra=1),
        S(4, ["coelho"], extra=1),
    ], [
        S(5, ["coelho"]), S(5, ["ourico"]), S(5, ["ourico", "coelho"]),
        S(6, ["ourico", "coelho"]), S(6, ["coelho", "ourico"], max_givens=2),
    ]),
    ("Bosque", [
        S(4, ["raposa"], rocks=1, extra=2),
        S(5, ["raposa"], rocks=2, extra=1),
        S(5, ["raposa", "ourico"], rocks=2, extra=1),
    ], [
        S(5, ["raposa", "ourico"], rocks=3), S(6, ["raposa", "coelho"], rocks=3),
        S(6, ["raposa", "ourico"], rocks=4), S(6, ["ourico", "coelho", "raposa"], rocks=3),
        S(7, ["raposa", "ourico", "coelho"], rocks=5, max_givens=2),
    ]),
    ("Lago gelado", [
        S(4, ["ourico"], ice=4, ice_used=1, extra=1),
        S(5, ["ourico"], ice=6, ice_used=2, extra=1),
        S(5, ["coelho", "ourico"], ice=6, ice_used=2, extra=1, scale=0.8),
    ], [
        S(6, ["ourico", "coelho"], ice=8, ice_used=2, rocks=2),
        S(6, ["raposa", "ourico"], ice=8, ice_used=2, rocks=2),
        S(6, ["ourico", "coelho", "raposa"], ice=7, ice_used=2, rocks=2),
        S(7, ["ourico", "raposa", "coelho"], ice=10, ice_used=3, rocks=3, max_givens=2),
    ]),
    ("Pinhal", [
        S(4, ["esquilo"], extra=1),
        S(5, ["esquilo"], rocks=2, extra=1),
        S(5, ["esquilo", "ourico"], rocks=2, extra=1, scale=0.8),
    ], [
        S(6, ["esquilo", "ourico"], rocks=3), S(6, ["esquilo", "coelho"], rocks=3),
        S(6, ["esquilo", "raposa"], rocks=3), S(6, ["esquilo", "ourico"], ice=6, ice_used=1, rocks=2),
        S(7, ["esquilo", "ourico", "raposa"], rocks=4, max_givens=2),
        S(7, ["esquilo", "coelho", "ourico"], rocks=4, ice=6, ice_used=1, max_givens=2),
    ]),
    ("Montanha", [
        S(5, ["coruja"], rocks=3, extra=1),
        S(5, ["coruja"], rocks=4, extra=1),
        S(6, ["coruja", "ourico"], rocks=4, extra=1, scale=0.8),
    ], [
        S(6, ["coruja", "ourico"], rocks=5), S(6, ["coruja", "raposa"], rocks=5),
        S(7, ["coruja", "esquilo"], rocks=5), S(7, ["coruja", "coelho", "ourico"], rocks=6),
        S(7, ["coruja", "ourico", "raposa"], rocks=6, ice=6, ice_used=1, max_givens=2),
        S(8, ["coruja", "esquilo", "ourico"], rocks=7, max_givens=2),
    ]),
    ("Nevão", [
        S(5, ["ourico", "coelho"], hidden=1, extra=1),
        S(6, ["raposa", "ourico"], rocks=3, hidden=2, extra=1),
        S(6, ["esquilo", "coruja"], rocks=3, hidden=2),
    ], [
        S(6, ["ourico", "coelho", "raposa"], rocks=3, hidden=2),
        S(6, ["esquilo", "ourico"], rocks=3, hidden=2),
        S(7, ["raposa", "coruja", "coelho"], rocks=4, ice=5, ice_used=1, hidden=2),
        S(7, ["ourico", "esquilo", "raposa"], rocks=5, hidden=3),
        S(7, ["coruja", "ourico", "coelho"], rocks=5, ice=5, ice_used=1, hidden=3),
        S(8, ["ourico", "esquilo", "coruja"], rocks=6, hidden=3, max_givens=2),
    ]),
    # ---- mundos 7-12: sem regras novas, misturam tudo o que já se aprendeu ----
    ("Aurora", [
        S(6, ["esquilo", "coelho"], rocks=3, extra=1),
        S(6, ["coruja", "raposa"], rocks=3, extra=1),
        S(6, ["ourico", "esquilo", "coruja"], rocks=3, extra=1, scale=0.8),
    ], [
        S(7, ["ourico", "coelho", "raposa"], rocks=4), S(7, ["esquilo", "coruja", "ourico"], rocks=4),
        S(7, ["raposa", "esquilo", "coelho"], rocks=4), S(7, ["coruja", "coelho", "raposa"], rocks=5),
        S(7, ["ourico", "raposa", "esquilo", "coelho"], rocks=4, scale=0.8, max_givens=2),
    ]),
    ("Gruta de gelo", [
        S(6, ["ourico", "coelho"], ice=8, ice_used=2, rocks=2, extra=1),
        S(6, ["esquilo", "raposa"], ice=8, ice_used=2, rocks=2, extra=1),
        S(6, ["coruja", "ourico"], ice=8, ice_used=2, rocks=3, extra=1),
    ], [
        S(7, ["ourico", "coelho", "raposa"], ice=10, ice_used=3, rocks=3),
        S(7, ["esquilo", "ourico", "coelho"], ice=10, ice_used=3, rocks=3),
        S(7, ["coruja", "raposa", "ourico"], ice=10, ice_used=2, rocks=4),
        S(7, ["esquilo", "coruja", "coelho"], ice=10, ice_used=2, rocks=4, max_givens=2),
    ]),
    ("Vale escondido", [
        S(6, ["ourico", "esquilo"], rocks=2, hidden=2, extra=1),
        S(6, ["coelho", "coruja"], rocks=3, hidden=2, extra=1),
        S(6, ["raposa", "esquilo", "ourico"], rocks=3, hidden=3, extra=1, scale=0.8),
    ], [
        S(7, ["ourico", "coelho", "esquilo"], rocks=4, hidden=3),
        S(7, ["raposa", "coruja", "ourico"], rocks=4, hidden=3),
        S(7, ["esquilo", "raposa", "coelho"], rocks=4, hidden=4),
        S(7, ["coruja", "ourico", "coelho"], rocks=5, hidden=4, max_givens=2),
    ]),
    ("Floresta encantada", [
        S(6, ["ourico", "coelho", "raposa"], rocks=2, extra=1, scale=0.8),
        S(7, ["esquilo", "coruja", "ourico"], rocks=3, extra=1, scale=0.8),
        S(7, ["ourico", "coelho", "raposa", "esquilo"], rocks=3, extra=2, scale=0.7),
    ], [
        S(7, ["ourico", "coelho", "raposa", "esquilo"], rocks=4, scale=0.8),
        S(7, ["coruja", "ourico", "coelho", "raposa"], rocks=4, scale=0.8),
        S(7, ["esquilo", "coruja", "ourico", "coelho"], rocks=4, scale=0.8),
        S(8, ["ourico", "raposa", "esquilo", "coruja"], rocks=5, scale=0.8, max_givens=2),
    ]),
    ("Pico gelado", [
        S(7, ["ourico", "raposa"], ice=8, ice_used=2, rocks=4, extra=1),
        S(7, ["coruja", "esquilo"], ice=8, ice_used=2, rocks=5, extra=1),
        S(7, ["coelho", "ourico", "coruja"], ice=8, ice_used=2, rocks=5, extra=1),
    ], [
        S(8, ["ourico", "coelho", "raposa"], ice=10, ice_used=2, rocks=6),
        S(8, ["esquilo", "coruja", "ourico"], ice=10, ice_used=2, rocks=6),
        S(8, ["raposa", "esquilo", "coelho"], ice=10, ice_used=2, rocks=6),
        S(8, ["coruja", "ourico", "coelho", "raposa"], ice=10, ice_used=2, rocks=6, scale=0.8, max_givens=2),
    ]),
    ("Grande tempestade", [
        S(7, ["ourico", "coelho", "raposa"], rocks=4, ice=6, ice_used=1, hidden=2, extra=1),
        S(7, ["esquilo", "coruja", "ourico"], rocks=4, ice=6, ice_used=1, hidden=2, extra=1),
        S(7, ["raposa", "esquilo", "coelho", "ourico"], rocks=4, hidden=2, extra=1, scale=0.8),
    ], [
        S(7, ["ourico", "coelho", "raposa", "esquilo"], rocks=4, ice=6, ice_used=1, hidden=2, scale=0.8),
        S(8, ["coruja", "raposa", "ourico"], rocks=6, ice=8, ice_used=2, hidden=3),
        S(8, ["esquilo", "coruja", "coelho", "ourico"], rocks=6, ice=8, ice_used=1, hidden=3, scale=0.8),
        S(8, ["ourico", "raposa", "esquilo", "coruja"], rocks=6, ice=8, ice_used=2, hidden=3, scale=0.8, max_givens=2),
    ]),
]

CANDIDATES = 30   # candidatos por lote para os 9 níveis principais

# Faixa de esforço (tools/rate.py) de cada mundo: os níveis normais ficam entre lo e hi,
# o Super difícil até top. Cada mundo começa um pouco abaixo de onde o anterior acabou.
BANDS = [(3, 12, 17), (4, 16, 23), (5, 20, 29), (6, 25, 36), (7, 30, 44), (8, 36, 55),
         (20, 38, 55), (22, 41, 60), (24, 44, 65), (26, 47, 70), (28, 50, 75), (30, 54, 85)]
INTRO_MAX = [3, 6, 8, 8, 9, 12, 16, 18, 20, 24, 26, 30]   # esforço máximo dos níveis de introdução (o 1.º é sempre fácil)
CACHE = os.path.join(os.path.dirname(__file__), "cache")


def _job(args):
    spec, seed = args
    return make_level(spec, random.Random(seed))


def pick_curve(cands, band):
    """7 níveis normais espalhados pela faixa, o Difícil perto do topo e o Super difícil acima."""
    lo, hi, top = band
    normal = sorted([lv for lv in cands if lo <= lv["score"] <= hi], key=lambda lv: lv["score"])
    above = sorted([lv for lv in cands if hi * 0.8 <= lv["score"] <= top], key=lambda lv: lv["score"])
    if len(normal) < 8 or not above:
        return None
    super_ = above[-1]
    rest = [lv for lv in normal if lv is not super_]
    hard = rest[-1]
    rest = rest[:-1]
    out = []
    for k in range(7):
        target = lo + (hi * 0.85 - lo) * k / 6
        best = min((lv for lv in rest if lv not in out), key=lambda lv: abs(lv["score"] - target))
        out.append(best)
    out.sort(key=lambda lv: lv["score"])
    return out, hard, super_


def _cached(w, name):
    path = os.path.join(CACHE, f"w{w + 1}_{name}.json")
    return json.load(open(path)) if os.path.exists(path) else []


def _store(w, name, data):
    os.makedirs(CACHE, exist_ok=True)
    json.dump(data, open(os.path.join(CACHE, f"w{w + 1}_{name}.json"), "w"))


def build_world(w, specs_intro, specs_main, pool, base_seed):
    intro = _cached(w, "intro")
    if len(intro) != len(specs_intro):
        intro = []
        for k, sp in enumerate(specs_intro):
            cap = ((3 if w < 5 else 6) if w < 6 else INTRO_MAX[w] * 0.6) if k == 0 else INTRO_MAX[w]
            for tries in range(12 if w < 6 else 40):
                lv = _job((sp, base_seed + k * 50 + tries))
                if lv and lv["score"] <= cap:
                    break
            else:
                raise RuntimeError(f"introdução {k + 1} falhou no mundo {w + 1}")
            intro.append(lv)
        _store(w, "intro", intro)
    cands = _cached(w, "cands")
    batch = len(cands) // CANDIDATES
    picked = pick_curve(cands, BANDS[w])
    while picked is None and batch < (6 if w < 6 else 8):
        jobs = [(specs_main[k % len(specs_main)], base_seed + 1000 + batch * CANDIDATES + k) for k in range(CANDIDATES)]
        cands += [lv for lv in pool.map(_job, jobs) if lv]
        _store(w, "cands", cands)
        batch += 1
        picked = pick_curve(cands, BANDS[w])
    if picked is None:
        raise RuntimeError(f"mundo {w + 1}: candidatos insuficientes na faixa {BANDS[w]}: "
                           f"{sorted(lv['score'] for lv in cands)}")
    rest, hard, super_ = picked
    hard["tag"], super_["tag"] = "hard", "super"
    return intro + rest[:2] + [hard] + rest[2:] + [super_]


def finish(levels, prefix):
    """Ids estáveis por posição e nota 1-10 pela ordem global de esforço."""
    scores = sorted(lv["score"] for lv in levels)
    for k, lv in enumerate(levels):
        lv["id"] = prefix(k)
        rank = scores.index(lv["score"]) / max(1, len(scores) - 1)
        lv["diff"] = 1 + round(rank * 9)
    return levels


def main_levels():
    """Os mundos que já estão em data/levels.json ficam iguais (o progresso guarda-se por id);
    só se geram os mundos que faltam."""
    old = json.load(open("data/levels.json")) if os.path.exists("data/levels.json") else []
    out = []
    with Pool(4) as pool:
        for w, (name, intro, main) in enumerate(WORLDS):
            seq = [lv for lv in old if lv["world"] == w + 1]
            if len(seq) != 12:
                seq = build_world(w, intro, main, pool, 1000 * (w + 1))
            for lv in seq:
                lv["world"] = w + 1
            out += seq
            print(name, [(lv["score"], lv.get("tag", "")) for lv in seq], file=sys.stderr, flush=True)
            json.dump(out, open("data/levels.json.tmp", "w"))
    finish(out, lambda k: "w%d-%02d" % (out[k]["world"], k % 12 + 1))
    os.replace("data/levels.json.tmp", "data/levels.json")
    json.dump(out, open("data/levels.json", "w"))
    print("níveis:", len(out), file=sys.stderr)


DAILY_SPECS = [
    S(6, ["ourico", "coelho"], rocks=2), S(6, ["raposa", "ourico"], rocks=3),
    S(6, ["esquilo", "coelho"], rocks=3), S(6, ["coruja", "ourico"], rocks=4),
    S(6, ["ourico", "coelho"], ice=6, ice_used=2, rocks=2),
    S(7, ["ourico", "raposa", "coelho"], rocks=4, max_givens=2),
    S(7, ["esquilo", "ourico", "coruja"], rocks=4, max_givens=2),
]


def daily_levels(n):
    with Pool(2) as pool:
        jobs = [(DAILY_SPECS[k % len(DAILY_SPECS)], 900000 + k) for k in range(int(n * 1.15))]
        cands = [lv for lv in pool.map(_job, jobs) if lv]
    # tira os mais fáceis e os mais difíceis, baralha para variar de dia para dia
    cands.sort(key=lambda lv: lv["score"])
    cut = (len(cands) - n) // 2
    cands = cands[cut:cut + n]
    random.Random(5).shuffle(cands)
    finish(cands, lambda k: "d%03d" % (k + 1))
    json.dump(cands, open("data/daily.json", "w"))
    print("puzzles do dia:", len(cands), file=sys.stderr)


if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "daily":
        daily_levels(int(sys.argv[2]) if len(sys.argv) > 2 else 120)
    else:
        main_levels()
