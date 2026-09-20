<h1 align="center">Hyperwyrm</h1>

<p align="center">
  A pixel-art eastern dragon that lives in your <a href="https://omarchy.org">Omarchy</a> bar, roams your windows,<br>
  grows through three forms, and is steered by a tiny CfC neural network.
</p>

<p align="center">
  <img src="docs/media/hatch.gif" alt="Hatching an egg into a Wyrmling" width="720">
</p>

<p align="center">
  <a href="https://github.com/dawestheperson/hyperwyrm/releases/latest">Download the full demo video</a>
</p>

---

## See it in action

<p align="center">
  <img src="docs/media/evolve.gif" alt="Wyvern evolving into an Emperor Dragon" width="640"><br>
  <sub>Evolving from a Wyvern into an Emperor Dragon</sub>
</p>

<p align="center">
  <img src="docs/media/fire.gif" alt="Opening the panel to the badge row, then the dragon breathes fire" width="640"><br>
  <sub>The badge row in the panel, then the Emperor Dragon breathes fire</sub>
</p>

<p align="center">
  <img src="docs/media/sulking.gif" alt="A sulking dragon under a storm cloud" width="640"><br>
  <sub>Neglect it and it sulks: storm cloud, faded colours and mean-but-cute remarks</sub>
</p>

## Features

- **Lives on your screen.** Out of the bar it walks along window tops, jumps, falls and (once grown) flies over your applications. Only the dragon and its mess catch mouse clicks; everything else passes straight through.
- **Three forms.** Feed and play with it and it grows from Wyrmling to Wyvern to Emperor Dragon, with a light-burst-and-confetti cutscene at each step. The bar icon changes with it.
- **Real needs.** Fullness, happiness and energy drain over time. It gets hungry, sleepy and playful, and tells you so.
- **Talks about what you are doing.** Its speech reacts to the window you have focused (terminal, browser, editor and so on) and to its own mood.
- **Bond.** Every kind thing you do builds bond, which slows how fast it gets unhappy.
- **A sulking mode.** Neglect it and a storm cloud follows it around, its colours fade, it refuses a first snack, huffs steam and stomps off to the edge of the screen.
- **Mess to clean up.** It poops after eating. Leave it for 30 seconds and it stresses out.
- **Happy tricks.** A cheerful dragon glows with sparkles and hearts for 90 seconds when it gets happy (and again every 30 minutes it stays that way), dances, spins, does zoomies and loop-the-loops, and even a moonwalk, and leaves gifts on the floor.
- **Badges.** Fourteen collectable gems, shown at the top right of its home menu.
- **Tag.** An optional 20-second mini-game where the neural network runs from your cursor.
- **It learns you.** It notices which tricks you react to and does those more, which snack you feed it most, where on the screen you pet it (and drifts and naps there), and roughly when you visit. The panel shows what it has learned so far.
- **Seven colours.** Red, blue, green, gold, purple, silver and black.

## The forms

<p align="center">
  <img src="docs/art/evolution.png" alt="Egg, Wyrmling, Wyvern and Emperor Dragon" width="640">
</p>

| Form | XP | What it is |
| --- | --- | --- |
| **Egg** | 0 | Pick a colour and hatch it: a big egg wobbles, cracks and bursts open, then you name the wyrmling. |
| **Wyrmling** | 0 | A small, snake-like serpent that slithers along the ground and window tops. |
| **Wyvern** | 100 | Grows horns and a beard, and takes to the air. |
| **Emperor Dragon** | 300 | A branched antler crown, a golden belly band and a crest. Breathes fire when it is completely fed, rested and happy. |

Growth comes from feeding and playing. Passive growth is capped just below the next threshold, so evolving is always something you did.

<p align="center">
  <img src="docs/art/colors.png" alt="The Emperor Dragon in all seven colours" width="640"><br>
  <sub>Seven colours</sub>
</p>

## Install

Hyperwyrm is an Omarchy shell plugin (service and bar widget).

```bash
omarchy plugin add https://github.com/dawestheperson/hyperwyrm --enable
omarchy restart shell
```

Then add the **Hyperwyrm** widget to your bar if it was not placed automatically (`omarchy bar` has the commands). Click the icon to open its home, pick a colour and hatch the egg.

Requires Omarchy with the plugin-capable shell (Quickshell) and Hyprland.

## Remove

```bash
omarchy plugin remove dawestheperson.hyperwyrm
omarchy restart shell
```

Your dragon's save (`~/.local/state/omarchy/hyperwyrm.json`) is left behind so you can reinstall later without losing it. Delete it if you want a clean slate.

## Permissions and dependencies

- **No dependencies.** The plugin is QML and JavaScript, run by the Omarchy shell. Python is only needed if you retrain the brain (`tools/brain`).
- **Screen overlay.** A transparent full-screen layer above your windows. It only accepts mouse clicks on the dragon, its snacks, its mess and its gifts.
- **What it reads.** The class of the focused window (to comment on what you are doing), window positions (so it can stand on window tops), and the cursor position via `hyprctl cursorpos`, only during Play and Tag.
- **What it writes.** Its own save file, and one desktop notification when the dragon becomes unhappy. It never changes your Omarchy or Hyprland configuration.
- **License.** [MIT](LICENSE). The neural network weights and pixel art in this repository are part of that license.

## Caring for your dragon

**Food.** Open the home menu and drag a snack out onto the screen. It falls, the dragon walks over and eats it. Snacks it cannot eat yet stay put until you click them away.

| Snack | Fullness | Happiness |
| --- | --- | --- |
| Apple | +15 | +4 |
| Cookie | +10 | +10 |
| Fish | +25 | +6 |
| Meat | +30 | +5 |
| Cake | +20 | +14 |

<p align="center"><img src="docs/art/foods.png" alt="Apple, cookie, fish, meat, cake and a poop" width="420"></p>

**Rest.** It walks to its favourite spot, curls up and sleeps for about a minute (Zzz included).

**Play.** For 30 to 45 seconds it chases your mouse cursor like a kitten after a laser dot.

**Tag.** Occasionally it asks for a game, or press *Tag*. Click it four times in 20 seconds while it dashes away. Winning earns the Tag Champion badge.

**Poop.** A snack is digested one to three minutes later. Click the mess to clean it up; left for more than 30 seconds it costs happiness. It happens even while the dragon is put away.

**Moods.** *Happy, hungry, sleepy, playful,* or *unhappy*. Below 35% happiness it turns unhappy and stays that way until it climbs back over 50%. You can still put an unhappy dragon away, and poke it if you like (it scoots off).

**Badges.** Eight gift gems, three bond milestones (25, 50, 100), Firebreather, Emperor Form and Tag Champion.

<p align="center"><img src="docs/art/badges.png" alt="The fourteen badges" width="480"></p>

Hover a badge in the panel to see how it was earned.

## How the brain works

Its movement is not scripted. A small **CfC** (closed-form continuous-time) network wired with an **NCP** (Neural Circuit Policy, inspired by the *C. elegans* nervous system) turns its state into motion every tenth of a second.

| | |
| --- | --- |
| Model | `ncps` `AutoNCP`, 108 neurons, about 38k trainable parameters |
| Inputs (15) | hunger, tiredness, happiness, time of day (sin, cos), recent window-switching, direction and distance to the focused window, wall proximity (x, y), being petted, two noise channels, tag-game flag |
| Outputs (4) | horizontal velocity, vertical velocity, a rest gate, a jump gate |
| Runtime | a pure-JavaScript forward pass inside QML; no Python, no GPU, no daemon |

The network is trained offline by distilling a hand-written teacher policy (see [`tools/brain`](tools/brain)). Its own outputs decide *when* the dragon stops to rest and when it feels like a trick. In the tag game the same network runs away from your cursor.

### The learning layer

Alongside the CfC (which steers the body) sits a small learner ([`src/Learner.js`](src/Learner.js)) modelled on the **fruit fly's mushroom body**, the part of the fly brain that learns. In the fly, a few thousand Kenyon cells turn what the animal senses into a sparse code, and a reward signal (dopamine) strengthens or weakens their connections to output neurons. Here the "situation" is the hour, the kind of window you are using, the dragon's mood and where it is on screen; the outputs are choices (which trick, which snack, which part of the screen). It is a simplified model, not the real wiring, and a few hundred numbers in total. It does not retrain the CfC; it biases what the dragon chooses.

| It learns | From | Effect |
| --- | --- | --- |
| Which tricks you like, and when | Petting it within 10 s of a trick is a reward; being ignored is a small penalty | Liked tricks are picked more often, in the situations where you liked them (spin in the evening on a terminal, say) |
| Favourite snack | What you feed it | Your favourite gives a happiness bonus and a special line |
| Favourite spot | Where on the screen you pet it | It drifts back there, and its resting spot moves there |
| Usual time | The hour of day you interact | Shown in the panel |

It is saved with the pet and reset with a new egg.

### Cost

Measured on the author's machine (Intel UHD graphics, 1920x1080 at 1.25x scale), running the plugin alone in a separate Quickshell against an empty one. CPU is a share of one core over 30-second windows; version 0.2.2.

| State | CPU | Memory over an empty shell |
| --- | --- | --- |
| Empty Quickshell (reference) | 0.0% | 0 MB |
| Plugin loaded, dragon put away | 0.0% | +48 MB |
| Wyrmling walking | 6.6% | +97 MB |
| Emperor Dragon flying | 7.1% | +96 MB |
| Resting (curled up) | 2.6% | +102 MB |
| Sulking (storm cloud, steam) | 5.7% | +108 MB |
| Play (cursor polled 10 times a second) | 7.6% | +98 MB |

- A dragon that is put away costs nothing measurable. Only the bar icon and the game clock (one 60-second timer) remain.
- A brain step takes about 2 ms and runs 10 times a second, only while the dragon is out and awake.
- Most of the cost while it moves is redrawing the transparent full-screen overlay. It redraws at about 20 frames a second while walking and not at all while it sits still.
- Sprites are pre-rendered 32x32 pixel-art frames, so nothing is computed while drawing them.

## Project layout

```
manifest.json     plugin manifest
src/              the plugin (QML and JS)
  Service.qml     game state: needs, growth, mood, badges, persistence
  RoamWindow.qml  the full-screen click-through overlay: movement, food, tricks, tag
  Panel.qml       the bar icon and home menu
  HatchScene.qml, EvolveScene.qml, Confetti.qml   the cutscenes
  Brain.js, BrainWeights.js                       the CfC forward pass and trained weights
  Sprites.js, Foods.js, Phrases.js, Badges.js     art, food data, dialogue, badges
docs/             screenshots, art sheets and the demo video
tools/brain/      train and export the network
tools/docs/       regenerate the art sheets in docs/art
```

Your dragon is saved to `~/.local/state/omarchy/hyperwyrm.json`.

## Development

Plugin code under `~/.config/omarchy/plugins/` hot-reloads on save for simple edits; run `omarchy restart shell` to be sure after larger changes. To work on a clone, symlink or copy it to `~/.config/omarchy/plugins/dawestheperson.hyperwyrm`.

```bash
omarchy plugin validate .                     # check the manifest
python tools/docs/render_art.py               # rebuild docs/art (needs Node and Pillow)
```

Retraining the brain is described in [`tools/brain/README.md`](tools/brain/README.md).

## Contributing

Ideas, sprites, phrases and tricks are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## Credits

- CfC networks: Hasani et al., *Closed-form continuous-time neural networks*, Nature Machine Intelligence, 2022.
- [`ncps`](https://github.com/mlech26l/ncps) by Mathias Lechner, used for training.
- Built for [Omarchy](https://omarchy.org).

## License

[MIT](LICENSE)
