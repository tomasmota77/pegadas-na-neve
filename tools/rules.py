"""Regras partilhadas pelo gerador, verificador e medidor de dificuldade.

Coordenadas: (linha, coluna).

Animais:
  ourico  1 casa na horizontal ou vertical
  coelho  salta exatamente 2 casas em linha reta (por cima de tudo)
  raposa  1 casa na diagonal; o caminho não se cruza em X
  esquilo salto em L (cavalo do xadrez), por cima de tudo
  coruja  voa em linha reta (horizontal ou vertical) quantas casas quiser, por cima de tudo;
          só deixa pegada onde pousa

Terreno:
  rocha   ninguém pousa lá
  gelo    quem pousa numa casa de gelo tem de repetir o mesmo movimento a seguir
          (mesma direção e mesmo tamanho)

Números das bordas: casas pisadas (toca e comida incluídas) em cada linha/coluna.
None = número tapado pelo nevão (sem restrição).
"""

BASE_MOVES = {
    "ourico": [(0, 1), (0, -1), (1, 0), (-1, 0)],
    "coelho": [(0, 2), (0, -2), (2, 0), (-2, 0)],
    "raposa": [(1, 1), (1, -1), (-1, 1), (-1, -1)],
    "esquilo": [(1, 2), (2, 1), (-1, 2), (-2, 1), (1, -2), (2, -1), (-1, -2), (-2, -1)],
}

ANIMAL_ORDER = ["ourico", "coelho", "raposa", "esquilo", "coruja"]


def moves(t, W, H):
    if t == "coruja":
        n = max(W, H)
        return [(0, k) for k in range(1, n)] + [(0, -k) for k in range(1, n)] + \
               [(k, 0) for k in range(1, n)] + [(-k, 0) for k in range(1, n)]
    return BASE_MOVES[t]


def diag_cross(a, b, c, d):
    """Os movimentos diagonais a->b e c->d cruzam-se em X?"""
    if abs(a[0] - b[0]) != 1 or abs(a[1] - b[1]) != 1:
        return False
    if abs(c[0] - d[0]) != 1 or abs(c[1] - d[1]) != 1:
        return False
    return {c, d} == {(a[0], b[1]), (b[0], a[1])}


def check_solution(level, sol):
    """Confirma que `sol` ({tipo: [células]}) cumpre todas as regras do nível."""
    W, H = level["w"], level["h"]
    rocks = set(map(tuple, level["rocks"]))
    ice = set(map(tuple, level.get("ice", [])))
    used = set()
    diag = []
    rows, cols = [0] * H, [0] * W
    for a in level["animals"]:
        t = a["type"]
        p = [tuple(c) for c in sol[t]]
        if p[0] != tuple(a["den"]) or p[-1] != tuple(a["food"]):
            return False
        mv = set(moves(t, W, H))
        for i, c in enumerate(p):
            if not (0 <= c[0] < H and 0 <= c[1] < W) or c in rocks or c in used:
                return False
            used.add(c)
            rows[c[0]] += 1
            cols[c[1]] += 1
            if i > 0:
                v = (c[0] - p[i - 1][0], c[1] - p[i - 1][1])
                if v not in mv:
                    return False
                if i >= 2 and p[i - 1] in ice:
                    pv = (p[i - 1][0] - p[i - 2][0], p[i - 1][1] - p[i - 2][1])
                    if v != pv:
                        return False
                if t == "raposa":
                    for (x, y) in diag:
                        if diag_cross(p[i - 1], c, x, y):
                            return False
                    diag.append((p[i - 1], c))
    for g in level.get("givens", []):
        if tuple(g["cell"]) not in [tuple(c) for c in sol[g["type"]]]:
            return False
    for r in range(H):
        if level["rows"][r] is not None and level["rows"][r] != rows[r]:
            return False
    for c in range(W):
        if level["cols"][c] is not None and level["cols"][c] != cols[c]:
            return False
    return True
