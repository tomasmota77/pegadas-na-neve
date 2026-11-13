# Pegadas na Neve

Puzzle de lógica para telemóvel (Godot 4.7, GDScript, renderizador Compatibilidade, ecrã vertical).

**Objetivo:** levar cada animal da toca até à sua comida. Os números nas bordas dizem quantas casas são pisadas em cada linha e coluna. Ninguém pisa a mesma casa duas vezes, e as pegadas já marcadas pertencem ao caminho daquele animal.

| Animal | Movimento |
|---|---|
| Ouriço | 1 casa para cima, baixo ou lados |
| Coelho | Salta sempre 2 casas em linha reta, por cima de tudo |
| Raposa | 1 casa na diagonal; o caminho não se cruza em X |
| Esquilo | Salto em L (cavalo do xadrez), por cima de tudo |
| Coruja | Voa em linha reta quantas casas quiser, por cima de tudo; só deixa pegada onde pousa (no jogo, pousa ao levantar o dedo) |

| Novidade | Regra |
|---|---|
| Rocha | Ninguém pousa lá |
| Gelo | Quem pousa no gelo tem de repetir o mesmo movimento (mesma direção e tamanho) |
| Nevão | Alguns números das bordas estão tapados e não contam |

## Mundos

Cada mundo traz uma novidade; as anteriores voltam misturadas. Em cada mundo: 3 níveis de introdução, 9 normais a subir de dificuldade, com o **Difícil** em 6.º lugar e o **Super difícil** a fechar.

| Mundo | Novidade | Grelhas |
|---|---|---|
| 1 Clareira | Ouriço e coelho | 4×4 a 6×6 |
| 2 Bosque | Raposa e rochas | 4×4 a 7×7 |
| 3 Lago gelado | Gelo | 4×4 a 7×7 |
| 4 Pinhal | Esquilo | 4×4 a 7×7 |
| 5 Montanha | Coruja | 5×5 a 8×8 |
| 6 Nevão | Números tapados, todos os animais | 5×5 a 8×8 |

Há também um **puzzle do dia** (`data/daily.json`, 120 puzzles em ciclo), que abre depois do mundo 1 e conta os dias seguidos.

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
scripts/sfx.gd          autoload "Sfx": efeitos sonoros e música
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

## Sons

Os sons ficam em `assets/sounds/` (`.ogg`, `.mp3` ou `.wav`). A lista, quando toca cada um e os prompts para os gerar estão em [`docs/sons.md`](docs/sons.md). Um som que não exista não toca. Sons e música desligam-se em separado nas Definições.

## Línguas

O jogo está em português, inglês, espanhol, francês e alemão. Escolhe a língua do telemóvel (ou inglês, se não for nenhuma destas), e pode mudar-se nas Definições.

Todos os textos estão em `data/traducoes.csv`: uma linha por texto e uma coluna por língua. Para juntar uma língua, acrescenta a coluna, junta o ficheiro `data/traducoes.<código>.translation` em `project.godot` e o nome em `Game.LANGS` (`scripts/globals.gd`).

### Imagens novas (prompts em `docs/imagens.md`)

Já têm marcadores provisórios simples; substitui-os pelos finais com o mesmo nome.

| Ficheiro | Tamanho | O quê |
|---|---|---|
| `coruja.png` | 512×512 | Coruja |
| `comida_coruja.png` | 512×512 | Ninho (destino da coruja) |
| `pegada_coruja.png` | 256×256 | Pegada **branca** da coruja, a apontar para cima |
| `gelo.png` | 512×512 | Casa de gelo do tabuleiro (também no cartão) |
| `nevao.png` | 512×512 | Cartão e apresentação do nevão |
| `numero_tapado.png` | 256×256 | Substitui os números tapados |
| `calendario.png` | 256×256 | Ícone do puzzle do dia (opcional) |
| `fundo_mundo1.png` … `fundo_mundo6.png` | 1080×1920 | Fundo de cada mundo durante o jogo (sem transparência) |
| `mundo_1.png` … `mundo_6.png` | 1200×400 | Faixa de cada mundo no menu (sem transparência) |

## Gerar níveis

Os mundos estão em `WORLDS` em `tools/gen.py`: para cada um, os níveis de introdução e os modelos dos níveis normais (tamanho, animais, rochas, gelo, números tapados). As regras estão em `tools/rules.py`.

Cada nível tem uma única solução (confirmada com CP-SAT) e uma **medida de esforço** (`tools/rate.py`): um resolvedor que pensa como uma pessoa, por deduções (contagens, alcance de cada animal, ligações) e, quando estas param, por "e se" de um e dois passos. Níveis que só se resolvem a adivinhar são deitados fora. De todos os candidatos de um mundo, o gerador escolhe 9 espalhados pela faixa desse mundo (`BANDS`), para a dificuldade subir de forma suave. O campo `diff` (1 a 10) é a nota no jogo todo.

Os candidatos ficam guardados em `tools/cache/`: correr outra vez reaproveita-os. Para refazer um mundo, apaga os ficheiros dele nessa pasta. O progresso dos jogadores é guardado pelo `id` (`w3-07` = mundo 3, nível 7).

```
pip install ortools
python tools/gen.py              # 6 mundos x 12 níveis → data/levels.json
python tools/gen.py daily 120    # puzzles do dia → data/daily.json
python tools/rate.py             # esforço medido de cada nível
python tools/verify.py           # confirma por força bruta que cada nível tem 1 solução
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
godot --headless --path . -s tests/test_puzzle.gd     # lógica dos 60 níveis e dos toques
godot --path . -- --shots                             # capturas para user://shots/
```

## Publicar nas lojas

- **Ficha das lojas** (nomes, descrições, palavras-chave e declaração de dados, nas 5 línguas): `docs/loja.md`.
- **Capturas**: `store/android/` (1080×1920) e `store/iphone/` (1320×2868), geradas com
  `godot --path . --resolution 1080x1920 -- --shots` (ficam em `user://shots/`).
- **Gráfico de destaque do Google Play** (1024×500, obrigatório): `store/android/grafico_destaque_<língua>.png`
  (um por língua, com o logótipo traduzido). Refaz com `python tools/feature_graphic.py`;
  a ilustração está em `assets/images/fontes/caminhada_destaque.png`.
- **Política de privacidade e termos**: `site/` (português e inglês), publicados no GitHub Pages.
- **Exportação**: perfis "Android" (AAB, alvo API 36, compilação Gradle) e "iOS" em `export_presets.cfg`.
  No editor: Projeto → Instalar modelo de compilação Android; no iOS preenche o Team ID.
  O identificador `com.tomasmota.pegadasnaneve` não se pode mudar depois da primeira publicação.

### Anúncios (AdMob)

O plugin da Poing Studios (v5.1.0, MIT) está em `addons/admob/` e o jogo usa-o através de `scripts/ads.gd`:
consentimento RGPD ao abrir, anúncio entre níveis (nunca nos primeiros 8, no máximo um a cada 3 níveis
e 150 s) e anúncio com prémio para uma dica extra. Fora do telemóvel não faz nada.

No teu PC, uma vez:
1. Projeto → Definições do projeto → Plugins → ativa **AdMob** (descarrega as bibliotecas nativas;
   se falhar: Projeto → Ferramentas → AdMob Manager → Android/iOS → Download & Install).
2. Cria a app no AdMob (admob.google.com) e põe o **App ID** (tem `~`) no AdMob Manager, em Android e iOS.
3. Cria dois blocos de anúncios (Intersticial e Com prémio) e põe os IDs em `REAL_IDS` em `scripts/ads.gd`.
   As compilações de teste usam sempre os anúncios de teste da Google.
4. No AdMob, em Privacidade e mensagens, cria a mensagem do RGPD (é a que o jogo mostra).

### Compra "remover anúncios", avaliação e lembrete diário

Plugins (já no repositório, ativos em `project.godot`):
- **godot-iap** 1.2.9 (`addons/godot-iap/`, MIT) usado por `scripts/store.gd`: compra única `remover_anuncios`.
- **In-app Review** 5.3 (`addons/InappReviewPlugin/`, MIT) usado por `scripts/review.gd`: pede avaliação no fim do mundo 1, do mundo 3 e aos 7 dias seguidos do puzzle do dia (uma vez cada).
- **Notification Scheduler** 6.0 (`addons/NotificationSchedulerPlugin/`, MIT) usado por `scripts/reminder.gd`: "O puzzle de hoje está pronto" à hora escolhida nas definições.

No teu PC, uma vez:
1. Projeto → Instalar modelo de compilação Android (se ainda não fizeste).
2. Copia `android_res/drawable/ic_notificacao.png` para `android/build/res/drawable/` (ícone branco da notificação).
3. **Google Play Console** → a tua app → Monetizar → Produtos → Produtos na app → Criar produto:
   ID `remover_anuncios`, nome "Remover anúncios", preço (ex.: 2,99 €), ativar. Precisa de uma conta de comerciante.
4. **App Store Connect** → a tua app → Monetização → Compras na app → "+" → **Não consumível**,
   ID do produto `remover_anuncios`, preço e uma captura do ecrã das definições (pede a Apple).
5. As compras só funcionam em compilações instaladas pela loja (teste interno no Play, TestFlight no iOS).
