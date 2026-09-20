import QtQuick
import "Sprites.js" as Sprites

// The Celestial Dragon's long body: a chain of pixel-art segments that follow the head's trail,
// so it slithers across the screen and can coil up in rings. The head is the ordinary sprite.
//
// Cost: no painting after the first frame (each segment is a static image that is only moved),
// and the layout only runs when the owner asks for it.
Item {
  id: root
  property string colorName: "red"
  property bool dull: false
  property real px: 4                  // one art pixel, in screen pixels
  property bool coil: false            // curled up to rest: rings around (coilX, coilY)
  property real coilX: 0
  property real coilY: 0
  property bool moving: false
  readonly property int count: 44
  readonly property real spacing: 4.2 * px
  readonly property string paletteKey: colorName + (dull ? "|dull" : "")

  property var trail: []               // recent anchor positions, oldest first
  property var segs: []                // laid-out segments: {x, y, rot}
  property real phase: 0
  property real blend: 0               // 0 = following the trail, 1 = coiled

  anchors.fill: parent

  function reset(x, y, dirSign) {
    var t = []
    var len = count * spacing + 40
    for (var d = len; d >= 0; d -= 6) t.push({ x: x - dirSign * d, y: y })
    trail = t; blend = 0; layout(0.03)
  }
  function push(x, y) {
    var t = trail
    if (t.length === 0) { reset(x, y, 1); return }
    var l = t[t.length - 1]
    var dx = x - l.x, dy = y - l.y
    if (dx * dx + dy * dy < 9) return
    t.push({ x: x, y: y })
    if (t.length > 700) t.splice(0, 100)
    trail = t
  }

  function layout(dt) {
    var t = trail, n = t.length
    if (n < 2) return
    phase += dt * (moving ? 5.5 : 1.4)
    blend += ((coil ? 1 : 0) - blend) * Math.min(1, dt * 2.2)
    var amp = (moving ? 7 : 2.2) * px / 3
    var out = [], i = n - 1, acc = 0
    var cx = t[i].x, cy = t[i].y
    // the spiral for the coiled pose
    var sp = [], r = 9 * px, th = Math.PI
    for (var k = 0; k < count; k++) {
      sp.push({ x: coilX + Math.cos(th) * r * 1.3, y: coilY + Math.sin(th) * r * 0.5 })
      var dth = spacing / Math.max(r, 6 * px)
      th += dth; r += 1.55 * px * dth
    }
    for (var s = 0; s < count; s++) {
      var want = s * spacing
      while (i > 0 && acc + Math.hypot(t[i - 1].x - cx, t[i - 1].y - cy) < want) {
        acc += Math.hypot(t[i - 1].x - cx, t[i - 1].y - cy); i--; cx = t[i].x; cy = t[i].y
      }
      var px_, py_
      if (i > 0) {
        var seg = Math.hypot(t[i - 1].x - cx, t[i - 1].y - cy) || 1, f = (want - acc) / seg
        px_ = cx + (t[i - 1].x - cx) * f; py_ = cy + (t[i - 1].y - cy) * f
      } else { px_ = cx; py_ = cy }
      out.push({ x: px_, y: py_ })
    }
    // slither: a wave running down the body, then blend towards the coil
    for (var q = 0; q < count; q++) {
      var a = out[q], b = out[Math.min(count - 1, q + 1)], c0 = out[Math.max(0, q - 1)]
      var tx = c0.x - b.x, ty = c0.y - b.y, tl = Math.hypot(tx, ty) || 1
      var off = amp * Math.sin(q * 0.55 - phase) * Math.min(1, q / 8)
      var wx = a.x - ty / tl * off, wy = a.y + tx / tl * off
      out[q] = { x: wx + (sp[q].x - wx) * blend, y: wy + (sp[q].y - wy) * blend }
    }
    for (var m = 0; m < count; m++) {
      var p0 = out[Math.max(0, m - 1)], p1 = out[Math.min(count - 1, m + 1)]
      var rot = Math.atan2(p0.y - p1.y, p0.x - p1.x) * 180 / Math.PI
      if (rot > 90) rot -= 180; else if (rot < -90) rot += 180       // segments are symmetric: keep the belly down
      out[m].rot = rot
    }
    segs = out
  }

  // --- the segments ---------------------------------------------------------------------
  Repeater {
    model: root.count
    delegate: Item {
      id: seg
      required property int index
      readonly property var pos: root.segs.length > index ? root.segs[index] : null
      readonly property int rows: index < 6 ? 7 : Math.round(3 + 5 * Math.min(1, (root.count - 1 - index) / 15))
      readonly property bool spiky: index % 3 === 1
      width: 9 * root.px; height: (rows + 2) * root.px
      visible: pos !== null
      x: pos ? pos.x - width / 2 : 0
      y: pos ? pos.y - height / 2 - root.px : 0
      rotation: pos ? pos.rot : 0
      z: root.count - index

      Canvas {
        anchors.fill: parent
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate
        property string key: root.paletteKey
        onKeyChanged: requestPaint()
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var pal = Sprites.palette(root.colorName, root.dull), p = root.px, h = seg.rows, w = 9
          function cell(x, y, col) { ctx.fillStyle = col; ctx.fillRect(x * p, (y + 2) * p, p + 0.5, p + 0.5) }
          function inside(x, y) { var ex = (x + 0.5 - w / 2) / (w / 2), ey = (y + 0.5 - h / 2) / (h / 2); return ex * ex + ey * ey <= 1 }
          for (var y = 0; y < h; y++)
            for (var x = 0; x < w; x++) {
              if (!inside(x, y)) continue
              var edge = !inside(x - 1, y) || !inside(x + 1, y) || !inside(x, y - 1) || !inside(x, y + 1)
              var col = y >= h * 0.62 ? pal.b : pal.m
              if (edge) col = (y <= 1 ? pal.h : pal.o)
              else if ((x * 7 + y * 13 + seg.index * 5) % 6 === 0) col = pal.l
              else if ((x * 5 + y * 3 + seg.index * 3) % 7 === 0) col = pal.a
              cell(x, y, col)
            }
          if (seg.spiky) {                                            // a back spike, in the mane colour
            ctx.fillStyle = pal.a
            ctx.fillRect(3.5 * p, 1 * p, 2 * p, 2 * p); ctx.fillRect(4 * p, 0, p, p + 0.5)
          }
        }
      }
      // a small clawed leg on four segments
      Canvas {
        visible: [7, 10, 27, 30].indexOf(seg.index) >= 0
        x: 3 * root.px; y: (seg.rows + 1) * root.px; width: 6 * root.px; height: 5 * root.px
        rotation: (seg.index % 2 ? 22 : -22)
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate
        property string key: root.paletteKey
        onKeyChanged: requestPaint()
        onPaint: {
          var ctx = getContext("2d"), pal = Sprites.palette(root.colorName, root.dull), p = root.px
          ctx.clearRect(0, 0, width, height)
          ctx.fillStyle = pal.d; ctx.fillRect(1 * p, 0, 2 * p, 3 * p)
          ctx.fillStyle = pal.m; ctx.fillRect(1.5 * p, 0, p, 2.5 * p)
          ctx.fillStyle = pal.t
          ctx.fillRect(0, 3 * p, p, p); ctx.fillRect(1.5 * p, 3.5 * p, p, p); ctx.fillRect(3 * p, 3 * p, p, p)
        }
      }
    }
  }

  // the tail plume: a fan of pale strokes with a red stripe
  Canvas {
    id: plume
    readonly property var pos: root.segs.length > 0 ? root.segs[root.count - 1] : null
    readonly property var prev: root.segs.length > 1 ? root.segs[root.count - 3] : null
    width: 20 * root.px; height: 20 * root.px
    visible: pos !== null
    x: pos ? pos.x - 1 * root.px : 0
    y: pos ? pos.y - height / 2 : 0
    transformOrigin: Item.Left
    rotation: (pos && prev) ? Math.atan2(pos.y - prev.y, pos.x - prev.x) * 180 / Math.PI : 0
    z: 0
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    property string key: root.paletteKey
    onKeyChanged: requestPaint()
    onPaint: {
      var ctx = getContext("2d"), pal = Sprites.palette(root.colorName, root.dull), p = root.px
      ctx.clearRect(0, 0, width, height)
      for (var k = -4; k <= 4; k++) {
        var len = 18 - Math.abs(k) * 1.6, col = (k % 2 === 0) ? pal.l : pal.a
        for (var s = 0; s < len; s++) {
          var t = s / len, x = 1 + s, y = 10 + k * (0.15 + t * 0.9)
          ctx.fillStyle = (Math.abs(k) === 0) ? pal.m : col
          ctx.fillRect(x * p, Math.round(y) * p, p + 0.5, p + 0.5)
          if (s > 3 && s < len - 2 && Math.abs(k) > 0) { ctx.fillStyle = col; ctx.fillRect(x * p, Math.round(y + (k > 0 ? 1 : -1)) * p, p + 0.5, p + 0.5) }
        }
      }
    }
  }
}
