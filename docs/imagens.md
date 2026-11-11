# Prompts para as imagens

Onde aparece **(estilo comum)**, cola no lugar o texto da secção "Estilo comum". O primeiro prompt, `ourico.png`, já está completo como exemplo.
Gera com **fundo transparente** (exceto `fundo.png` e `icon.png`), guarda em `assets/images/` com o nome indicado e reduz para o tamanho da tabela do README.

Dicas:
- Gera primeiro o `ourico.png`. Depois usa-o como imagem de referência nos outros, para o estilo ficar igual.
- Os ícones da interface ficam melhor gerados todos de uma vez numa grelha, e recortados depois (prompt no fim).
- Se o fundo transparente não sair limpo, pede fundo branco liso e remove-o depois.

## Estilo comum

> Cute cozy winter mobile puzzle game art, soft rounded shapes, thick dark navy outline (#34303C), flat colors with gentle soft shading, minimal detail, readable at small sizes, centered, front view, isolated on a transparent background, no text, no shadow on the ground.

## Animais (512×512)

**`ourico.png`**
> Cute cozy winter mobile puzzle game art, soft rounded shapes, thick dark navy outline (#34303C), flat colors with gentle soft shading, minimal detail, readable at small sizes, centered, front view, isolated on a transparent background, no text, no shadow on the ground. A small chubby hedgehog sitting, full body, warm brown spikes, cream face, tiny black nose, big shiny eyes, rosy cheeks, a tiny teal (#2E8C7E) knitted scarf.

**`coelho.png`**
> (estilo comum) A small fluffy rabbit sitting, full body, light grey-beige fur, long upright ears with pink inside, big shiny eyes, rosy cheeks, a tiny raspberry pink (#C2477A) knitted scarf.

**`raposa.png`**
> (estilo comum) A small fox sitting, full body, bright orange fur, white cheeks and chest, fluffy tail curled around its feet, pointy ears with dark tips, big shiny eyes, a tiny orange (#E3801F) knitted scarf.

## Comidas e rocha (512×512)

**`comida_ourico.png`**
> (estilo comum) A single cute mushroom with a round red cap with white spots and a short cream stem, a little snow on top of the cap.

**`comida_coelho.png`**
> (estilo comum) A single fresh orange carrot with green leafy top, slightly tilted, a few snowflakes around it.

**`comida_raposa.png`**
> (estilo comum) A small cluster of three round blueberries with a small green leaf, shiny highlights.

**`rocha.png`**
> (estilo comum) A single rounded grey stone boulder with a soft white snow cap on top, wide and low, fills most of the square.

## Pegadas (256×256)

O jogo pinta as pegadas com a cor de cada animal, por isso têm de ser **brancas puras** e **apontar para cima**.

**`pegada_ourico.png`**
> A single hedgehog footprint, pure white silhouette, solid flat white, no outline, no shading, pointing straight up, centered, transparent background: one oval pad with five small round toes in an arc above it.

**`pegada_coelho.png`**
> A single rabbit track, pure white silhouette, solid flat white, no outline, no shading, pointing straight up, centered, transparent background: two long oval hind-foot prints side by side at the top and two small round front-foot prints below them.

**`pegada_raposa.png`**
> A single fox paw print, pure white silhouette, solid flat white, no outline, no shading, pointing straight up, centered, transparent background: one heart-shaped pad with four oval toes above it.

## Ícones da interface (256×256)

Estilo dos ícones:

> Simple rounded mobile game UI icon, single flat color, thick rounded strokes, no outline, no shading, no text, centered with generous padding, transparent background.

| Ficheiro | Prompt (depois do estilo dos ícones) |
|---|---|
| `voltar.png` | `A left-pointing arrow, color #20304A.` |
| `ajuda.png` | `A bold rounded question mark, color #20304A.` |
| `definicoes.png` | `A gear / cog with 8 rounded teeth and a round hole, color #20304A.` |
| `desfazer.png` | `An undo arrow curving counter-clockwise, color #20304A.` |
| `limpar.png` | `A trash can with lid, color #20304A.` |
| `dica.png` | `A light bulb, pure white #FFFFFF.` |
| `relogio.png` | `A small round clock face with two hands, color #5D6F89.` |
| `cadeado.png` | `A closed padlock, color #A9BCCF.` |

**`estrela.png`** (vai ficar pequena nos níveis, por isso tem de ser simples)
> Simple rounded five-point star for a mobile game, warm golden yellow (#F5B82E) with a lighter top highlight and thin darker gold edge, cute and chunky, no face, centered, transparent background, no text.

**Todos de uma vez (grelha):**
> A sprite sheet of 8 simple rounded mobile game UI icons in a 4×2 grid, evenly spaced, each icon single flat color, thick rounded strokes, no outline, no shading, no text, transparent background. Row 1: left arrow (#20304A), question mark (#20304A), gear (#20304A), undo arrow (#20304A). Row 2: trash can (#20304A), light bulb (white), clock (#5D6F89), padlock (#A9BCCF).

## Ilustrações

**`floco.png`** (512×512, ecrã "Como se joga")
> (estilo comum) A trail of small animal footprints winding through fresh snow, with a hedgehog peeking from behind a little snowy mound, a few big soft snowflakes.

**`vitoria.png`** (512×512, ecrã de vitória)
> (estilo comum) A happy hedgehog, rabbit and fox sitting together in the snow, cheering, each holding their food (mushroom, carrot, blueberries), little sparkles and snowflakes around them.

## Logótipos, um por língua (1024×512, título do menu)

O menu mostra `logo_<língua>.png`. Se não existir para a língua escolhida, mostra o título escrito pelo jogo.

| Ficheiro | Texto exato |
|---|---|
| `logo_en.png` | Snow Tracks (já existe) |
| `logo_pt.png` | Pegadas na Neve |
| `logo_es.png` | Huellas en la Nieve |
| `logo_fr.png` | Traces dans la Neige |
| `logo_de.png` | Spuren im Schnee |

Gera cada um com o `logo_en.png` como imagem de referência, para o estilo ficar igual. Os modelos de imagem às vezes trocam ou esquecem letras: confirma o texto antes de usar.

**`logo_pt.png`**
> Game logo, same style as the reference image. The exact text "Pegadas na Neve" in two lines: "Pegadas" on the first line and "na Neve" on the second line, both lines centered. Spelled P-E-G-A-D-A-S, N-A, N-E-V-E. No other words or letters. Very chunky, soft, rounded bubble letters in solid dark navy (#20304A), each letter with a thick fluffy white snow cap on top with soft light blue shading. Two small dark navy animal paw prints on the left and two on the right. Cute cozy winter mobile game style, flat colors, no outline around the letters, no background, transparent background.

**`logo_es.png`**
> Game logo, same style as the reference image. The exact text "Huellas en la Nieve" in two lines: "Huellas en" on the first line and "la Nieve" on the second line, both lines centered. Spelled H-U-E-L-L-A-S, E-N, L-A, N-I-E-V-E. No other words or letters. Very chunky, soft, rounded bubble letters in solid dark navy (#20304A), each letter with a thick fluffy white snow cap on top with soft light blue shading. Two small dark navy animal paw prints on the left and two on the right. Cute cozy winter mobile game style, flat colors, no outline around the letters, no background, transparent background.

**`logo_fr.png`**
> Game logo, same style as the reference image. The exact text "Traces dans la Neige" in two lines: "Traces dans" on the first line and "la Neige" on the second line, both lines centered. Spelled T-R-A-C-E-S, D-A-N-S, L-A, N-E-I-G-E. No other words or letters. Very chunky, soft, rounded bubble letters in solid dark navy (#20304A), each letter with a thick fluffy white snow cap on top with soft light blue shading. Two small dark navy animal paw prints on the left and two on the right. Cute cozy winter mobile game style, flat colors, no outline around the letters, no background, transparent background.

**`logo_de.png`**
> Game logo, same style as the reference image. The exact text "Spuren im Schnee" in two lines: "Spuren" on the first line and "im Schnee" on the second line, both lines centered. Spelled S-P-U-R-E-N, I-M, S-C-H-N-E-E. No other words or letters. Very chunky, soft, rounded bubble letters in solid dark navy (#20304A), each letter with a thick fluffy white snow cap on top with soft light blue shading. Two small dark navy animal paw prints on the left and two on the right. Cute cozy winter mobile game style, flat colors, no outline around the letters, no background, transparent background.

## Botões e caixas (opcional)

O jogo desenha os botões e as caixas sozinho. Se puseres estas imagens, passa a usá-las. **Não podem ter texto:** o texto é escrito pelo jogo, na língua escolhida.

Os botões, cartões e pílulas são esticados no meio e os cantos ficam iguais. Por isso o desenho tem de ser **liso no meio**, sem padrões, brilhos nem desenhos que se notem esticados, e com os cantos arredondados iguais nos quatro lados.

Estilo das caixas:

> Mobile game UI element, cute cozy winter style matching the reference image, soft rounded corners, gentle top highlight, subtle darker bottom edge for a slight 3D look, flat and plain in the middle, no text, no icons, no pattern, centered, transparent background.

| Ficheiro | Usado em | Prompt (depois do estilo) |
|---|---|---|
| `ui_botao.png` | Botão principal ("Jogar", "Próximo nível") | `A wide pill-shaped button, about 3 times wider than tall, dark navy blue (#20304A) with a slightly lighter top.` |
| `ui_botao_claro.png` | Botões secundários | `A wide pill-shaped button, about 3 times wider than tall, very light icy blue (#E7EFF6) with a white top highlight.` |
| `ui_cartao.png` | Cartões do menu e das regras | `A square card panel with large rounded corners, white with a very soft light blue bottom edge.` |
| `ui_pilula.png` | Tempo, progresso, estrelas | `A small pill-shaped label background, about 3 times wider than tall, white with a soft light blue bottom edge.` |
| `ui_redondo.png` | Botões redondos claros | `A perfectly round button, white with a soft light blue bottom edge.` |
| `ui_redondo_escuro.png` | Botão da dica | `A perfectly round button, dark navy blue (#20304A) with a slightly lighter top.` |
| `ui_nivel.png` | Nível disponível | `A rounded square tile, white with a soft light blue bottom edge.` |
| `ui_nivel_feito.png` | Nível resolvido | `A rounded square tile, dark navy blue (#20304A) with a slightly lighter top.` |
| `ui_nivel_fechado.png` | Nível fechado | `A rounded square tile, pale grey-blue (#CFDCE8), flat, no highlight.` |

Depois de pores qualquer imagem nova, corre `python tools/prep_images.py`.

**`fundo.png`** (1080×1920, vertical, sem transparência)
> Soft calm winter landscape background for a vertical mobile puzzle game, very light pale blue sky (#E7EFF6) fading to white, gentle snowy hills only along the bottom 20% of the image, a few small pine trees on the hills, falling snowflakes, flat pastel colors, low contrast, lots of empty calm space in the middle so UI can sit on top, no characters, no text.

**`icon.png`** (1024×1024, ícone da app, sem transparência, fica na raiz do projeto)
> Mobile app icon, cute hedgehog face peeking from the bottom, a trail of colorful footprints (teal, pink, orange) in white snow above it, pale blue background (#E7EFF6), thick dark navy outline, flat soft shading, square, no text.

**`chama.png`** (256×256, opcional): marca dos níveis Difícil e Super difícil no menu. Sem ela, aparece um círculo com "!" ou "!!".
> Simple rounded mobile game UI icon of a small cute flame, warm orange and red with a yellow center, thick dark navy outline (#34303C), flat colors, no text, centered, transparent background.

## Versão 2 dos bonecos e das comidas (recomendada)

Gera os três animais **numa só imagem** e as três comidas **noutra**: assim saem com o mesmo traço, o mesmo tamanho e a mesma luz. Depois corta-se com:

```
python tools/split_sheet.py assets/images/animais.png ourico coelho raposa
python tools/split_sheet.py assets/images/comidas.png comida_ourico comida_coelho comida_raposa
python tools/prep_images.py
```

As folhas originais ficam em `assets/images/fontes/` (o Godot ignora essa pasta). Por fim, `python tools/outline.py` engrossa o contorno escuro das figuras do tabuleiro (10 px), para se lerem bem pequenas.

**`animais.png`** (formato largo, 3:1)
> A sprite sheet of three cute chibi animal characters for a cozy winter mobile puzzle game, side by side in a single row, evenly spaced with clear empty space between them, all the same size and drawn in exactly the same style. Each sits facing the viewer. Left: a hedgehog with warm dark-brown spikes, a cream face and a teal (#2E8C7E) knitted scarf. Middle: a rabbit with warm caramel-brown fur, a cream belly, long upright ears with pink inside and a raspberry-pink (#C2477A) knitted scarf. Right: a fox with bright orange fur, white cheeks and chest, a fluffy white-tipped tail and a cream knitted scarf with orange stripes. Big round heads (about 60% of the character's height), small simple bodies, large shiny eyes, rosy cheeks, small happy smile. Thick dark navy outline (#34303C) of the same thickness on all three, flat colors with one soft shade, almost no fur texture, no thin lines, readable at 64 pixels. Transparent background, no text, no ground, no shadow.

**`comidas.png`** (formato largo, 3:1)
> A sprite sheet of three food items for a cozy winter mobile puzzle game, side by side in a single row, evenly spaced with clear empty space between them, all the same size and drawn in exactly the same style, each filling a square of the same size. Left: a round red mushroom with big white spots and a short cream stem. Middle: a short, chubby orange carrot standing upright with a bushy green leafy top. Right: a cluster of three round medium-blue blueberries (#5B74D6) with two green leaves. Each one has a small soft white snow cap on top. No faces, no snowflakes or sparkles around them. Thick dark navy outline (#34303C) of the same thickness on all three, flat colors with one soft shade, simple shapes, readable at 48 pixels. Transparent background, no text, no ground, no shadow.

**`toca.png`** (sem bagas de Natal)
> Cute cozy winter mobile puzzle game art, a small round animal burrow entrance in a snowy mound, dark round opening, soft white snow cap on top, a few small rocks at the base, no berries, no plants. Thick dark navy outline (#34303C), flat colors with one soft shade, simple shapes, readable at 48 pixels, centered, transparent background, no text, no shadow.

## Esquilo (mundo Pinhal)

Usa `assets/images/fontes/animais.png` e `fontes/comidas.png` como imagens de referência, para sair no mesmo estilo. Depois: `python tools/prep_images.py` e `python tools/outline.py esquilo comida_esquilo`.

**`esquilo.png`**
> A single cute chibi squirrel character for a cozy winter mobile puzzle game, exactly the same style, size, proportions and outline as the reference image. Sitting facing the viewer, warm red-brown fur, cream belly and cheeks, a big fluffy curled tail behind it, small tufted ears, large shiny eyes, rosy cheeks, small happy smile, and a violet (#7B5CC4) knitted scarf. Big round head (about 60% of the height), small simple body, thick dark navy outline (#34303C), flat colors with one soft shade, almost no fur texture, readable at 64 pixels. Transparent background, no text, no ground, no shadow.

**`comida_esquilo.png`**
> A single acorn for a cozy winter mobile puzzle game, exactly the same style as the reference image of food items: a plump round light-brown acorn with a darker textured cap and a tiny stem, a small soft white snow cap on top, upright, filling most of a square. No face, no sparkles. Thick dark navy outline (#34303C), flat colors with one soft shade, simple shapes, readable at 48 pixels. Transparent background, no text, no shadow.

**`pegada_esquilo.png`** (256×256)
> A single squirrel footprint, pure white silhouette, solid flat white, no outline, no shading, pointing straight up, centered, transparent background: one small oval palm pad with four thin oval toes spread in a fan above it.

