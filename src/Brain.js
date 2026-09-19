.pragma library
.import "BrainWeights.js" as Weights

// A closed-form continuous-time (CfC) network with neural-circuit-policy (NCP)
// wiring: sensory -> inter -> command -> motor layers, as in MIT's `ncps`
// library. This is a straight port of ncps' WiredCfCCell, so the maths matches
// the trained PyTorch model exactly:
//
//   x      = [ input , h ]
//   ff1    = tanh(W1 x + b1)            ff2 = tanh(W2 x + b2)     (W1, W2 sparse)
//   t      = sigmoid((Wa x + ba) * dt + (Wb x + bb))
//   h_new  = ff1 * (1 - t) + ff2 * t
//
// Each layer feeds the next; the last (motor) layer's state is the output.
// One step is about 37k multiply-adds, so it is cheap at 10 Hz.

var _layers = null

function _prepare() {
  if (_layers) return
  _layers = []
  var src = Weights.BRAIN.layers
  for (var i = 0; i < src.length; i++) {
    var s = src[i]
    _layers.push({
      n: s.n, k: s.k,
      w1: Float32Array.from(s.w1), b1: Float32Array.from(s.b1),
      w2: Float32Array.from(s.w2), b2: Float32Array.from(s.b2),
      wa: Float32Array.from(s.wa), ba: Float32Array.from(s.ba),
      wb: Float32Array.from(s.wb), bb: Float32Array.from(s.bb),
    })
  }
}

var INPUTS = Weights.BRAIN.inputs
var OUTPUTS = Weights.BRAIN.outputs

// Fresh network state (all neurons at rest).
function create() {
  _prepare()
  var h = []
  for (var i = 0; i < _layers.length; i++) h.push(new Float32Array(_layers[i].n))
  return { h: h, out: new Float32Array(OUTPUTS), x: new Float32Array(256) }
}

// Advance the network by `dt` seconds. `input` has INPUTS entries; returns the
// motor outputs (a Float32Array reused between calls).
function step(brain, input, dt) {
  _prepare()
  var prev = input
  var prevN = INPUTS
  for (var l = 0; l < _layers.length; l++) {
    var L = _layers[l], h = brain.h[l], x = brain.x, n = L.n, k = L.k
    for (var i = 0; i < prevN; i++) x[i] = prev[i]
    for (var j = 0; j < n; j++) x[prevN + j] = h[j]
    var hn = new Float32Array(n)
    for (var u = 0; u < n; u++) {
      var a1 = L.b1[u], a2 = L.b2[u], ta = L.ba[u], tb = L.bb[u]
      var base = u * k
      for (var c = 0; c < k; c++) {
        var xv = x[c]
        a1 += L.w1[base + c] * xv
        a2 += L.w2[base + c] * xv
        ta += L.wa[base + c] * xv
        tb += L.wb[base + c] * xv
      }
      var f1 = Math.tanh(a1), f2 = Math.tanh(a2)
      var t = 1 / (1 + Math.exp(-(ta * dt + tb)))
      hn[u] = f1 * (1 - t) + t * f2
    }
    brain.h[l] = hn
    prev = hn
    prevN = n
  }
  for (var o = 0; o < OUTPUTS; o++) brain.out[o] = prev[o]
  return brain.out
}
