# Training the brain

The dragon's movement network is a CfC with an NCP wiring (`ncps.wirings.AutoNCP`, 108 neurons, 15 inputs, 4 outputs). It is trained here by distillation: a hand-written teacher policy drives simulated dragons, and the network learns to reproduce it from the same inputs it sees at runtime.

## Setup

```bash
python -m venv .venv && source .venv/bin/activate
pip install torch numpy ncps
```

## Train

```bash
python train.py 1200 brain.pt      # steps, output checkpoint (defaults to /tmp/omg_brain.pt)
python export.py ../../src/BrainWeights.js brain.pt
```

`export.py` writes the weights as a JavaScript module (`src/BrainWeights.js`) and a `parity.json` fixture (git-ignored). Run `node tools/brain/parity.js` to confirm the JavaScript forward pass in `src/Brain.js` matches the real `ncps` cell.

## Inputs and outputs

Inputs, in order: hunger, tiredness, happiness, sin(time of day), cos(time of day), recent window switching, direction to the focused window (x, y), how close it is, wall proximity (x, y), being petted, noise 1, noise 2, tag-game flag.

Outputs: horizontal velocity, vertical velocity, rest gate, jump gate.

If you change the input or output layout, update `brainIn` and `brainStep` in `src/RoamWindow.qml` and retrain.
