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

**`logo.png`** (1024×512, título do menu)
> Game logo text "Pegadas na Neve" in a chunky rounded bold font, dark navy (#20304A) letters with a soft white snow cap on top of the letters, small animal paw prints next to the text, cute cozy winter mobile game style, centered, transparent background.

Os modelos de imagem às vezes trocam letras: confirma que diz exatamente "Pegadas na Neve".

**`fundo.png`** (1080×1920, vertical, sem transparência)
> Soft calm winter landscape background for a vertical mobile puzzle game, very light pale blue sky (#E7EFF6) fading to white, gentle snowy hills only along the bottom 20% of the image, a few small pine trees on the hills, falling snowflakes, flat pastel colors, low contrast, lots of empty calm space in the middle so UI can sit on top, no characters, no text.

**`icon.png`** (1024×1024, ícone da app, sem transparência, fica na raiz do projeto)
> Mobile app icon, cute hedgehog face peeking from the bottom, a trail of colorful footprints (teal, pink, orange) in white snow above it, pale blue background (#E7EFF6), thick dark navy outline, flat soft shading, square, no text.
