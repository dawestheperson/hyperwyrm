# Changelog

## Unreleased

- New final stage at 600 XP with five branching forms, decided by how the dragon was raised: Celestial (Tianlong), Spiritual (Shenlong), Earth (Dilong), Treasure (Fuzanglong), or a zombie Dragon if it was neglected. Each is a 64x32 pixel-art dragon, twice as long as the others.
- Removed the dance tricks. New: on the last bite before it is full, the dragon swells like a balloon, floats upside down, then sighs out a big plume of smoke; and it can blow smoke rings.

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
