# Sons

O jogo já está preparado: põe cada som em `assets/sounds/` com o nome da tabela e passa a tocar. Um som que não exista simplesmente não toca.

O som de ambiente (vento) foi tirado do jogo: era quase só ruído agudo e soava a chiado por baixo da música. Está em `assets/sounds/alternativas/ambiente_vento.ogg`. A música (Suno) passou por um filtro de ruído suave antes de ser ligada em ciclo.

Os sons atuais foram gerados no ElevenLabs com os prompts abaixo, cortados no início e no fim, igualados em volume e convertidos para `.ogg`. As outras versões que o ElevenLabs gerou estão em `assets/sounds/alternativas/` (o Godot ignora essa pasta): para trocar, copia a que preferires para `assets/sounds/` com o nome da tabela.

- **Formato:** `.ogg`, `.mp3` ou `.wav`. Para a música e o ambiente, prefere `.ogg` ou `.mp3`, que ocupam menos.
- **Variações:** para os sons que se repetem muito (os passos), gera 2 ou 3 versões e grava-as como `passo_ourico.mp3`, `passo_ourico_2.mp3`, `passo_ourico_3.mp3`. O jogo escolhe uma ao acaso.
- **Silêncio no início:** corta-o. Um passo que começa 0,2 s depois do dedo parece atrasado.
- **Volumes:** acertam-se no jogo (`scripts/sfx.gd`, tabela `VOLUME`). Não precisas de os acertar ao gerar.
- **Definições:** o jogador pode desligar os sons e a música em separado.

## Como os sons foram pensados

- **Cada ação tem resposta.** Arrastar, marcar, desfazer, pedir dica: tudo faz um som, curto e suave.
- **O que se repete muito tem de cansar pouco.** Os passos são o som mais ouvido do jogo, por isso são os mais suaves e mudam um pouco de altura em cada toque, para não soarem a máquina.
- **O caminho é uma melodia.** Por baixo de cada passo toca uma nota que sobe à medida que o caminho cresce, numa escala pentatónica (soa sempre bem). Na vitória, as pegadas que saltam tocam essas notas a subir.
- **Os erros não castigam.** Não há buzinas: quando a solução está errada, toca uma vez um "hmm" baixinho e amigável.
- **Ambiente acolhedor.** Nada de estrondos nem acordes dissonantes. Música calma de piano e celesta, e vento suave de inverno.
- **Muita gente joga sem som.** O som nunca dá informação que o ecrã não dê: é sempre um extra.

## Lista de sons

Prompts em inglês para o gerador de efeitos sonoros (por exemplo, o ElevenLabs Sound Effects). Entre parênteses, a duração a pedir.

### Os essenciais (começa por estes)

| Ficheiro | Quando toca | Prompt |
|---|---|---|
| `passo_ourico` (+ `_2`, `_3`) | Cada casa que o ouriço pisa | `A single soft footstep of a tiny animal paw in fresh powdery snow, gentle muffled crunch, very short, close-up, dry, no reverb` (0,3 s) |
| `passo_coelho` (+ `_2`, `_3`) | Cada salto do coelho | `A small rabbit hop landing in soft snow, light soft thump with a little puff of powder snow, very short, close-up, dry` (0,3 s) |
| `passo_raposa` (+ `_2`, `_3`) | Cada passo da raposa | `A quick light fox paw step on crisp snow, delicate crunch, very short, close-up, dry` (0,3 s) |
| `nota` | Por baixo de cada passo, a subir; e na animação de vitória | `A single soft celesta note, C5, gentle bell-like tone, quick attack, short natural decay, one note only, no reverb` (0,8 s) |
| `chegou` | Um animal chega à comida | `Cute happy two-note glockenspiel chime going up, with a tiny soft nibble sound, cozy and cheerful` (0,8 s) |
| `vitoria` | Nível resolvido, quando aparece o painel | `Short cheerful cozy victory jingle, glockenspiel and soft pizzicato strings, warm, ascending melody ending on a bright major chord` (2 s) |
| `estrela` | Cada estrela que aparece no fim | `A single soft sparkly twinkle chime, bright and magical, one note, short` (0,5 s) |
| `toque` | Qualquer botão | `Very soft short UI tap, like a gentle muted bubble pop, subtle, dry` (0,1 s) |

### Os restantes

| Ficheiro | Quando toca | Prompt |
|---|---|---|
| `marca` | Marcar ou tirar um X | `A soft short pencil tick on paper, single stroke, dry` (0,2 s) |
| `passo_voltar` | Arrastar para trás no caminho | `A very short soft brush of snow being swept away, light airy whoosh` (0,25 s) |
| `desfazer` | Botão desfazer | `A short soft reverse whoosh, gentle and light` (0,4 s) |
| `limpar` | Botão limpar | `A soft brushing sweep of snow across a wooden surface, gentle whoosh` (0,7 s) |
| `dica` | Pedir uma dica | `Gentle magical shimmer, soft fairy dust sparkle going up, light and friendly` (0,9 s) |
| `linha` | Mais uma linha ou coluna bate certo | `A tiny soft wooden marimba blip, single note, very short, dry` (0,3 s) |
| `errado` | Todos chegaram à comida, mas a solução está errada | `Soft low muted two-note marimba phrase going down, like a friendly "hmm", gentle, not harsh` (0,5 s) |
| `painel` | Abre um painel (regras, vitória, definições) | `Soft airy whoosh, like a light winter breeze, short` (0,4 s) |
| `animal_ourico` | Apresentação do ouriço | Melodia curta feita com a nota de celesta (`python tools/motifs.py`). A versão antiga do ElevenLabs está em `alternativas/animal_ourico_ia.ogg` |
| `animal_coelho` | Apresentação do coelho | Melodia curta feita com a nota de celesta (`python tools/motifs.py`). A versão antiga do ElevenLabs está em `alternativas/animal_coelho_ia.ogg` |
| `animal_raposa` | Apresentação da raposa | Melodia curta feita com a nota de celesta (`python tools/motifs.py`). A versão antiga do ElevenLabs está em `alternativas/animal_raposa_ia.ogg` |
| `animal_esquilo` | Apresentação do esquilo | Melodia curta feita com a nota de celesta (`python tools/motifs.py`). A versão antiga do ElevenLabs está em `alternativas/animal_esquilo_ia.ogg` |
| `animal_coruja` | Apresentação da coruja | Melodia curta feita com a nota de celesta (`python tools/motifs.py`). A versão antiga do ElevenLabs está em `alternativas/animal_coruja_ia.ogg` |

### Música e ambiente (tocam sempre, em ciclo)

| Ficheiro | Prompt |
|---|---|
| `musica` | `Calm cozy winter puzzle game background music, soft piano and celesta with light pizzicato strings, slow tempo around 70 BPM, gentle and warm, no drums, no vocals, seamless loop` (60 a 120 s, num gerador de música) |
| `ambiente` | `Quiet winter forest ambience, gentle soft wind, very occasional distant small bird chirp, calm, no music, seamless loop` (30 a 60 s) |

Para a música, ativa a opção de ciclo (loop) do gerador, se existir, para o fim ligar ao início sem salto.

## Fontes

- [Squeezing more juice out of your game design (Game Developer)](https://www.gamedeveloper.com/design/squeezing-more-juice-out-of-your-game-design-)
- [The power of pitch shifting (Game Developer)](https://gamedeveloper.com/audio/the-power-of-pitch-shifting)
- [Creating "game juice": using sound effects to improve player feedback](https://creatorsoundspro.com/creating-game-juice-using-sound-effects-to-improve-player-feedback)
- [How one sound effect made my puzzle game juicy (itch.io)](https://itch.io/blog/809496/how-one-sound-effect-made-my-puzzle-game-juicy)
- [Juice overload: when sensory feedback hurts gameplay](https://www.wayline.io/blog/juice-overload-sensory-feedback-hurts-gameplay)
- [GDC Audio Summit: How do you...](https://gdcvault.com/play/1034780/Audio-Summit-How-Do-You)
- [73% of mobile gamers play with the sound on (TouchArcade)](https://toucharcade.com/2013/11/05/73-of-mobile-gamers-play-with-the-sound-on/)
