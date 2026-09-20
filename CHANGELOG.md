# Changelog

## Unreleased

- The learning layer is now a fruit-fly mushroom-body model: what it learns depends on the situation (time, window, mood, position), not just totals.
- New trick: a moonwalk, a backwards glide, a spin and a lean.

## 0.2.2

- New learning layer: the dragon learns which tricks you react to, your favourite snack, where you pet it and when you visit. The panel shows what it has learned.
- Fixed high idle CPU: a hidden cutscene ran an endless animation that kept the overlay redrawing at the monitor's full refresh rate. A put-away dragon now costs nothing measurable, and a walking one about 7% of a core, down from about 18%.
- README: measured runtime cost.

## 0.2.1

- Fixed: the dance trick never ended, so a very happy dragon froze in place, and stayed frozen (floating, if picked up mid-dance).
- Picking the dragon up now cancels any trick in progress.
- A newly hatched dragon starts at 40% happiness, just above the unhappy line.
- The happy glow (sparkles and hearts) now shows for 90 seconds when happiness climbs past 80%, and returns every 30 minutes while it stays that happy, instead of showing permanently.

## 0.2.0

- First public release: three forms (Wyrmling, Wyvern, Emperor Dragon), needs and moods, food and poop, a sulking mode, happy tricks, gifts and fourteen badges, the optional tag mini-game, and a CfC/NCP movement brain.
