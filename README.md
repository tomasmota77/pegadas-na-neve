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
scripts/menu.gd         menu, seleção de níveis (com cadeados) e definições
scripts/sheet.gd        painel que sobe do fundo (regras, vitória, definições)
scripts/globals.gd      autoload "Game": níveis, progresso, estrelas, cores, animais
scripts/ui_theme.gd     tema da interface (cores, fontes, botões)
scripts/round_button.gd botão redondo com ícone e contador
scripts/level_tile.gd   quadrado de nível do menu
scripts/icons.gd        ícones da interface (imagem ou texto provisório)
tests/                  testes da lógica e capturas automáticas
tools/                  gerador de níveis e marcadores provisórios
```

## Imagens

Todas as imagens ficam em `assets/images/`. Põe lá o ficheiro **com o nome da tabela** e o jogo passa a usá-lo. Enquanto uma imagem não existir, o jogo mostra texto no lugar dela.

PNG com **fundo transparente** (exceto `fundo.png` e `icon.png`), tudo no mesmo estilo. Os prompts para gerar cada uma estão em [`docs/imagens.md`](docs/imagens.md).

Depois de juntar ou trocar imagens, corre `python tools/prep_images.py`: corta as margens vazias, centra cada imagem num quadrado (para não ficar esticada) e reduz para o tamanho da tabela. Não faz mal correr mais do que uma vez.

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
| `definicoes.png` | 256×256 | Ícone de definições (roda dentada), cor `#20304A` |
| `desfazer.png` | 256×256 | Ícone de desfazer, cor `#20304A` |
| `limpar.png` | 256×256 | Ícone de limpar (caixote do lixo), cor `#20304A` |
| `dica.png` | 256×256 | Ícone de dica (lâmpada), **branco** (fica num botão escuro) |
| `relogio.png` | 256×256 | Relógio pequeno para o tempo, cor `#5D6F89` |
| `cadeado.png` | 256×256 | Cadeado dos níveis fechados, cor `#A9BCCF` |
| `estrela.png` | 256×256 | Estrela dourada (níveis, vitória, contador do menu) |
| `floco.png` | 512×512 | Ilustração para o ecrã "Como se joga" |
| `vitoria.png` | 512×512 | Ilustração para o ecrã de vitória |
| `logo_<língua>.png` | 1024×512 | Título do menu nessa língua (`logo_pt`, `logo_en`, ...); sem ele, o jogo escreve o título |
| `ui_*.png` | ver `docs/imagens.md` | Fundos opcionais de botões, cartões, pílulas e níveis (sem texto) |
| `fundo.png` | 1080×1920 | Fundo de todos os ecrãs, **sem** transparência |
| `icon.png` (raiz) | 1024×1024 | Ícone da app, **sem** transparência |

Paleta: fundo `#E7EFF6`, texto `#20304A`, ouriço `#2E8C7E`, coelho `#C2477A`, raposa `#E3801F`.

## Línguas

O jogo está em português, inglês, espanhol, francês e alemão. Escolhe a língua do telemóvel (ou inglês, se não for nenhuma destas), e pode mudar-se nas Definições.

Todos os textos estão em `data/traducoes.csv`: uma linha por texto e uma coluna por língua. Para juntar uma língua, acrescenta a coluna, junta o ficheiro `data/traducoes.<código>.translation` em `project.godot` e o nome em `Game.LANGS` (`scripts/globals.gd`).

## Gerar níveis

```
pip install ortools
python tools/gen.py 7        # semente 7 → data/levels.json
python tools/verify.py       # confirma por força bruta que cada nível tem 1 solução
```

## Versão web

Precisa dos modelos de exportação do Godot 4.7.1 (no editor: Editor > Gerir modelos de exportação).

```
godot --headless --path . --export-release "Web" build/web/index.html
python tools/patch_web.py
```

O `patch_web.py` comprime o motor (`engine-gz.wasm`), muda o nome do `.pck` para `pck.wasm` (para caberem nos limites de publicação como artifact do Claude) e põe o título "Pegadas na Neve".

## Testes

```
godot --headless --path . -s tests/test_puzzle.gd     # lógica dos 12 níveis e dos toques
godot --path . -- --shots                             # capturas para user://shots/
```
