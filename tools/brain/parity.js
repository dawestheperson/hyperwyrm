// Checks the QML/JS forward pass (src/Brain.js) against the reference outputs
// from the real ncps cell (parity.json, written by export.py).
//   node tools/brain/parity.js
const fs = require('fs'), path = require('path');
const src = (f) => fs.readFileSync(path.join(__dirname, '../../src', f), 'utf8');
const Weights = new Function(src('BrainWeights.js').replace('.pragma library', '') + '; return { BRAIN }')();
const Brain = new Function('Weights', src('Brain.js').replace('.pragma library', '').replace(/^\.import.*$/m, '')
  + '; return { create, step }')(Weights);
const fx = JSON.parse(fs.readFileSync(path.join(__dirname, 'parity.json'), 'utf8'));
const b = Brain.create();
let worst = 0;
fx.x.forEach((x, t) => {
  const y = Brain.step(b, x, fx.dt[t]);
  y.forEach((v, i) => { worst = Math.max(worst, Math.abs(v - fx.y[t][i])) });
});
console.log('max abs difference over', fx.x.length, 'steps:', worst.toExponential(2));
process.exit(worst < 1e-3 ? 0 : 1);
