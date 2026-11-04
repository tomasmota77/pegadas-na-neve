# Pegadas na Neve

Puzzle de lógica para telemóvel (Godot 4.7, GDScript, renderizador Compatibilidade, ecrã vertical).

**Objetivo:** levar cada animal da toca até à sua comida. Os números nas bordas dizem quantas casas são pisadas em cada linha e coluna. Ninguém pisa a mesma casa duas vezes, e as pegadas já marcadas pertencem ao caminho daquele animal.

| Animal | Movimento |
|---|---|
| Ouriço | 1 casa para cima, baixo ou lados |
| Coelho | Salta sempre 2 casas em linha reta, por cima de tudo |
| Raposa | 1 casa na diagonal; o caminho não se cruza em X |

## Estrutura

```
data/levels.json        níveis (gerados por tools/gen.py, cada um com solução única)
scripts/puzzle_state.gd regras e estado do puzzle (sem interface)
scripts/board.gd        desenho do tabuleiro e toque/arrasto
scripts/game_screen.gd  ecrã de jogo (dicas, desfazer, vitória, tutoriais)
scripts/menu.gd         menu e seleção de níveis
scripts/globals.gd      autoload "Game": níveis, progresso, cores, animais
scripts/ui_theme.gd     tema da interface (cores, fontes, botões)
tests/                  testes da lógica e capturas automáticas
tools/                  gerador de níveis e marcadores provisórios
```

## Imagens

Todas as imagens ficam em `assets/images/`. Substitui o ficheiro pelo teu **com o mesmo nome** e o jogo passa a usá-lo. Os ícones que ainda não existem aparecem como texto nos botões.

PNG com **fundo transparente**, tudo no mesmo estilo.

| Ficheiro | Tamanho | O quê |
|---|---|---|
| `ourico.png` | 512×512 | Ouriço, corpo inteiro, centrado |
| `coelho.png` | 512×512 | Coelho, corpo inteiro, centrado |
| `raposa.png` | 512×512 | Raposa, corpo inteiro, centrada |
| `comida_ourico.png` | 512×512 | Cogumelo |
| `comida_coelho.png` | 512×512 | Cenoura |
| `comida_raposa.png` | 512×512 | Mirtilos |
| `rocha.png` | 512×512 | Rocha com um pouco de neve |
| `pegada_ourico.png` | 256×256 | Pegada **branca**, a apontar para cima (o jogo pinta-a) |
| `pegada_coelho.png` | 256×256 | Pegada **branca**, a apontar para cima |
| `pegada_raposa.png` | 256×256 | Pegada **branca**, a apontar para cima |
| `voltar.png` | 256×256 | Ícone de voltar, cor `#20304A` |
| `ajuda.png` | 256×256 | Ícone de regras/ajuda, cor `#20304A` |
| `desfazer.png` | 256×256 | Ícone de desfazer, cor `#20304A` |
| `limpar.png` | 256×256 | Ícone de limpar, cor `#20304A` |
| `dica.png` | 256×256 | Ícone de dica (lâmpada), **branco** (fica num botão escuro) |
| `floco.png` | 512×512 | Ilustração para o ecrã "Como se joga" |
| `estrela.png` | 512×512 | Ilustração para o ecrã de vitória |
| `icon.png` (raiz) | 1024×1024 | Ícone da app, **sem** transparência |

Paleta: fundo `#E7EFF6`, texto `#20304A`, ouriço `#2E8C7E`, coelho `#C2477A`, raposa `#E3801F`.

## Gerar níveis

```
pip install ortools
python tools/gen.py 7        # semente 7 → data/levels.json
python tools/verify.py       # confirma por força bruta que cada nível tem 1 solução
```

## Testes

```
godot --headless --path . -s tests/test_puzzle.gd     # lógica dos 12 níveis
godot --path . -- --shots                             # capturas para user://shots/
```
