# Contributing

Thanks for wanting to make the dragon better. Small, focused pull requests are easiest to review.

## Good first contributions

- **Phrases.** Add lines to `src/Phrases.js`: window categories, moods, reactions. Keep them short and kind; the sulking lines should be cranky but cute.
- **Tricks.** A trick in `src/RoamWindow.qml` is a transform on the existing sprite (see `startTrick` and `stepTrick`), so no new frames are needed.
- **Badges.** Add an entry to `src/Badges.js`, then award it with `awardBadge(id)` in `Service.qml`.
- **Sprites.** Frames in `src/Sprites.js` are 32x32 strings using the palette characters described at the top of the file. Run `python tools/docs/render_art.py` to preview them.
- **Mini-games.** The tag game (`goalGame` in `RoamWindow.qml`, `startGame` in `Service.qml`) is a template for new ones.

## Ground rules

- Keep the runtime cost near zero. Anything that runs continuously needs a reason; prefer timers that stop when the dragon is not visible.
- Do not add input that needs a compositor permission or reads anything except the active window's class.
- Match the surrounding code style. No new dependencies in `src/`.
- If you change the brain's inputs or outputs, retrain it (`tools/brain`) and update `BrainWeights.js` in the same pull request.

## Testing

Run the shell against a scratch state directory so you do not touch your own pet:

```bash
XDG_STATE_HOME=/tmp/hyperwyrm-test quickshell -n -p <path-to-a-copy-of-src>
```

Run `omarchy plugin validate .` before opening a pull request.
