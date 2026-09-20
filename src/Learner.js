.pragma library

// The dragon's learning layer, modelled on the fruit fly's mushroom body.
//
// In the fly, a few thousand "Kenyon cells" turn what the animal senses into a sparse
// code (only a few percent fire for any one situation). Each Kenyon cell connects to a
// few output neurons, and a reward signal (dopamine) strengthens or weakens those
// connections. What the fly learns is therefore tied to the situation it was in.
//
// Here the "situation" is the hour of day, the kind of window you are using, the dragon's
// mood and where it is on screen. Output neurons stand for choices: which trick, which snack,
// which part of the screen. Being rewarded (petted after a trick, fed, petted somewhere) strengthens
// the connections from the cells that were active; being ignored weakens them. It is a simplified
// model, not the real wiring, and it is a few hundred numbers.
//
// The CfC network still decides how the dragon moves. This layer only biases what it chooses.

var TRICKS = ["spin", "loop", "zoom", "smokering"]
var FOODS = ["apple", "cookie", "fish", "meat", "cake"]
var SPOTS = 8
var KC = 240              // Kenyon cells
var FAN_IN = 4            // inputs each Kenyon cell listens to
var FIRE_AT = 2           // it fires when at least this many of them are active
var CATS = ["desktop", "terminal", "browser", "editor", "files", "chat", "media", "other"]
var MOODS = ["happy", "hungry", "sleepy", "playful", "unhappy"]
var D = 24 + CATS.length + MOODS.length + SPOTS

// A fixed pseudo-random wiring, so saved weights stay valid between runs.
function _rng(seed) {
  var a = seed >>> 0
  return function() {
    a = (a + 0x6D2B79F5) >>> 0
    var t = a
    t = Math.imul(t ^ (t >>> 15), t | 1)
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296
  }
}
var WIRING = (function() {
  var r = _rng(20260919), w = []
  for (var k = 0; k < KC; k++) {
    var ins = []
    while (ins.length < FAN_IN) {
      var i = Math.floor(r() * D)
      if (ins.indexOf(i) < 0) ins.push(i)
    }
    w.push(ins)
  }
  return w
})()

// The situation, as the set of active input lines.
function context(hour, cat, mood, fx) {
  var on = {}
  var h = Math.floor(((hour % 24) + 24) % 24)
  on[h] = 1; on[(h + 1) % 24] = 1                       // the hour, blurred a little
  var c = CATS.indexOf(cat); on[24 + (c < 0 ? CATS.length - 1 : c)] = 1
  var m = MOODS.indexOf(mood); if (m >= 0) on[24 + CATS.length + m] = 1
  on[24 + CATS.length + MOODS.length + Math.max(0, Math.min(SPOTS - 1, Math.floor((fx || 0) * SPOTS)))] = 1
  return on
}
// The sparse code: which Kenyon cells fire in this situation.
function _active(on) {
  var out = []
  for (var k = 0; k < KC; k++) {
    var n = 0, ins = WIRING[k]
    for (var j = 0; j < FAN_IN; j++) if (on[ins[j]]) n++
    if (n >= FIRE_AT) out.push(k)
  }
  return out
}

// Weights are stored sparsely: only cells whose connection has moved away from 1.
function fresh() {
  return { t: {}, f: {}, s: {}, hours: new Array(24).fill(0), n: 0, fed: 0 }
}
function clone(p) { return JSON.parse(JSON.stringify(p)) }
function _w(group, key, k) { var g = group[key]; return g && g[k] !== undefined ? g[k] : 1 }
function _out(group, key, act) {                       // an output neuron's activity
  var s = 0
  for (var i = 0; i < act.length; i++) s += _w(group, key, act[i])
  return act.length ? s / act.length : 1
}
// Dopamine: strengthen (reward > 0) or weaken the connections of the cells that fired.
function _learn(group, key, act, reward) {
  var g = group[key] || (group[key] = {})
  for (var i = 0; i < act.length; i++) {
    var k = act[i], v = (g[k] !== undefined ? g[k] : 1)
    v = reward > 0 ? v + reward * (3 - v) * 0.5 : v + reward * (v - 0.3) * 0.5
    v = Math.max(0.3, Math.min(3, v))
    if (Math.abs(v - 1) < 0.02) delete g[k]; else g[k] = Math.round(v * 1000) / 1000
  }
}

// Anything read from disk is checked before use.
function sanitize(d) {
  var p = fresh()
  if (!d || typeof d !== "object") return p
  var num = function(v, lo, hi, fb) { v = Number(v); return isFinite(v) ? Math.max(lo, Math.min(hi, v)) : fb }
  var take = function(src, keys, dst) {
    if (!src || typeof src !== "object") return
    for (var i = 0; i < keys.length; i++) {
      var g = src[keys[i]]; if (!g || typeof g !== "object") continue
      var o = {}
      for (var k in g) { var ki = Number(k); if (ki >= 0 && ki < KC && ki % 1 === 0) o[ki] = num(g[k], 0.3, 3, 1) }
      dst[keys[i]] = o
    }
  }
  take(d.t, TRICKS, p.t); take(d.f, FOODS, p.f)
  var sk = []; for (var j = 0; j < SPOTS; j++) sk.push(String(j))
  take(d.s, sk, p.s)
  if (Array.isArray(d.hours)) for (var h = 0; h < 24; h++) p.hours[h] = num(d.hours[h], 0, 100000, 0)
  p.n = num(d.n, 0, 1000000, 0); p.fed = num(d.fed, 0, 1000000, 0)
  return p
}

// --- tricks ------------------------------------------------------------------
function pickTrick(p, pool, ctx) {
  var act = _active(ctx || {}), total = 0, ws = [], i
  for (i = 0; i < pool.length; i++) { var v = _out(p.t, pool[i], act); v = v * v; ws.push(v); total += v }
  var r = Math.random() * total
  for (i = 0; i < pool.length; i++) { r -= ws[i]; if (r <= 0) return pool[i] }
  return pool[pool.length - 1]
}
function trickLiked(p, t, ctx) { _learn(p.t, t, _active(ctx || {}), 0.5) }
function trickIgnored(p, t, ctx) { _learn(p.t, t, _active(ctx || {}), -0.12) }
// A situation-free average of each output neuron: "what it likes in general".
function _mean(group, key) {
  var g = group[key], s = 0, n = 0
  if (g) for (var k in g) { s += g[k] - 1; n++ }
  return s
}
function favTrick(p) {
  var best = null, bv = 0.6
  for (var i = 0; i < TRICKS.length; i++) { var m = _mean(p.t, TRICKS[i]); if (m > bv) { bv = m; best = TRICKS[i] } }
  return best
}

// --- snacks ------------------------------------------------------------------
function ate(p, kind, ctx) { p.fed++; _learn(p.f, kind, _active(ctx || {}), 0.4) }
function favFood(p) {
  var best = null, bv = 0.6
  for (var i = 0; i < FOODS.length; i++) { var m = _mean(p.f, FOODS[i]); if (m > bv) { bv = m; best = FOODS[i] } }
  return p.fed >= 5 ? best : null
}

// --- places and times ------------------------------------------------------------
// fx: horizontal position on screen, 0..1.
function touch(p, fx, hour, ctx) {
  var b = Math.max(0, Math.min(SPOTS - 1, Math.floor(fx * SPOTS)))
  var act = _active(ctx || context(hour, "other", "happy", fx))
  _learn(p.s, String(b), act, 0.5)
  for (var j = 0; j < SPOTS; j++) if (j !== b) _learn(p.s, String(j), act, -0.03)   // the other places fade a little
  p.hours[Math.max(0, Math.min(23, Math.floor(hour)))] += 1
  p.n++
}
function _spotScores(p, act) {
  var s = []
  for (var j = 0; j < SPOTS; j++) s.push(_out(p.s, String(j), act))
  return s
}
function favSpotIndex(p, ctx) {
  if (p.n < 8) return -1
  var s = _spotScores(p, _active(ctx || {})), b = 0
  for (var j = 1; j < SPOTS; j++) if (s[j] > s[b]) b = j
  return s[b] > 1.15 ? b : -1
}
function favSpotFx(p, ctx) { var b = favSpotIndex(p, ctx); return b < 0 ? -1 : (b + 0.5) / SPOTS }
// -1..1: which way the favourite spot (for this situation) lies from where the dragon is now.
function spotBias(p, fx, ctx) {
  var t = favSpotFx(p, ctx)
  return t < 0 ? 0 : Math.max(-1, Math.min(1, (t - fx) * 3))
}
function spotLabel(p) {
  // In general, over the day: the spot with the strongest overall connections.
  if (p.n < 8) return ""
  var best = -1, bv = 0.6
  for (var j = 0; j < SPOTS; j++) { var m = _mean(p.s, String(j)); if (m > bv) { bv = m; best = j } }
  return best < 0 ? "" : (best < 3 ? "the left side" : (best > 4 ? "the right side" : "the middle"))
}
function usualHour(p) {
  if (p.n < 12) return -1
  var b = 0
  for (var h = 1; h < 24; h++) if (p.hours[h] > p.hours[b]) b = h
  return p.hours[b] >= 4 ? b : -1
}
function hourLabel(h) { return h < 0 ? "" : ((h % 12) === 0 ? 12 : h % 12) + (h < 12 ? " AM" : " PM") }
