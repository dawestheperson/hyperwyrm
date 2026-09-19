.pragma library

// The dragon's learning layer: small, online, and cheap. It sits on top of the CfC
// brain (which still decides how it moves) and learns what YOU reward:
//   - which tricks you react to (a bandit: liked tricks get picked more often),
//   - which snack you feed it most,
//   - where on the screen you pet it (it drifts back there, and naps there),
//   - roughly what time of day you visit.
// Everything is a handful of numbers, saved with the pet.

var TRICKS = ["dance", "spin", "loop", "zoom"]
var SPOTS = 8

function fresh() {
  var t = {}; for (var i = 0; i < TRICKS.length; i++) t[TRICKS[i]] = 1
  var s = []; for (var j = 0; j < SPOTS; j++) s.push(0)
  var h = []; for (var k = 0; k < 24; k++) h.push(0)
  return { tricks: t, foods: {}, spots: s, hours: h, n: 0, fed: 0 }
}

function clone(p) { return JSON.parse(JSON.stringify(p)) }

// Anything read from disk is checked before use.
function sanitize(d) {
  var p = fresh()
  if (!d || typeof d !== "object") return p
  var num = function(v, lo, hi, fb) { v = Number(v); return isFinite(v) ? Math.max(lo, Math.min(hi, v)) : fb }
  if (d.tricks) for (var i = 0; i < TRICKS.length; i++) p.tricks[TRICKS[i]] = num(d.tricks[TRICKS[i]], 0.4, 6, 1)
  if (d.foods) for (var f in d.foods) if (/^[a-z]{2,12}$/.test(f)) p.foods[f] = num(d.foods[f], 0, 100000, 0)
  if (Array.isArray(d.spots)) for (var j = 0; j < SPOTS; j++) p.spots[j] = num(d.spots[j], 0, 100000, 0)
  if (Array.isArray(d.hours)) for (var k = 0; k < 24; k++) p.hours[k] = num(d.hours[k], 0, 100000, 0)
  p.n = num(d.n, 0, 1000000, 0); p.fed = num(d.fed, 0, 1000000, 0)
  return p
}

// --- tricks ------------------------------------------------------------------
function pickTrick(p, pool) {
  var total = 0, i
  for (i = 0; i < pool.length; i++) total += p.tricks[pool[i]] || 1
  var r = Math.random() * total
  for (i = 0; i < pool.length; i++) { r -= p.tricks[pool[i]] || 1; if (r <= 0) return pool[i] }
  return pool[pool.length - 1]
}
function trickLiked(p, t) { if (p.tricks[t] !== undefined) p.tricks[t] = Math.min(6, p.tricks[t] + 0.6) }
function trickIgnored(p, t) { if (p.tricks[t] !== undefined) p.tricks[t] = Math.max(0.4, p.tricks[t] * 0.96) }
function favTrick(p) {
  var best = null, bv = 1.6
  for (var i = 0; i < TRICKS.length; i++) if (p.tricks[TRICKS[i]] > bv) { bv = p.tricks[TRICKS[i]]; best = TRICKS[i] }
  return best
}

// --- snacks ------------------------------------------------------------------
function ate(p, kind) { p.foods[kind] = (p.foods[kind] || 0) + 1; p.fed++ }
function favFood(p) {
  var best = null, bv = 2
  for (var f in p.foods) if (p.foods[f] > bv || (p.foods[f] === bv && best === null)) { bv = p.foods[f]; best = f }
  return p.fed >= 5 ? best : null
}

// --- places and times ------------------------------------------------------------
// fx: horizontal position on screen, 0..1. Old memories fade, so it follows your habits.
function touch(p, fx, hour) {
  for (var j = 0; j < SPOTS; j++) p.spots[j] *= 0.97
  p.spots[Math.max(0, Math.min(SPOTS - 1, Math.floor(fx * SPOTS)))] += 1
  p.hours[Math.max(0, Math.min(23, Math.floor(hour)))] += 1
  p.n++
}
function favSpotIndex(p) {
  if (p.n < 8) return -1
  var b = 0
  for (var j = 1; j < SPOTS; j++) if (p.spots[j] > p.spots[b]) b = j
  return p.spots[b] >= 3 ? b : -1
}
function favSpotFx(p) { var b = favSpotIndex(p); return b < 0 ? -1 : (b + 0.5) / SPOTS }
// -1..1: which way the favourite spot lies from where the dragon is now.
function spotBias(p, fx) {
  var t = favSpotFx(p)
  return t < 0 ? 0 : Math.max(-1, Math.min(1, (t - fx) * 3))
}
function spotLabel(p) {
  var b = favSpotIndex(p)
  return b < 0 ? "" : (b < 3 ? "the left side" : (b > 4 ? "the right side" : "the middle"))
}
function usualHour(p) {
  if (p.n < 12) return -1
  var b = 0
  for (var h = 1; h < 24; h++) if (p.hours[h] > p.hours[b]) b = h
  return p.hours[b] >= 4 ? b : -1
}
function hourLabel(h) { return h < 0 ? "" : ((h % 12) === 0 ? 12 : h % 12) + (h < 12 ? " AM" : " PM") }
