import QtQuick

// A pixel-art jet of flame. Particles are only simulated (30 fps) while the
// jet is on or still fading, so it costs nothing the rest of the time.
Canvas {
  id: root
  renderTarget: Canvas.Image
  renderStrategy: Canvas.Immediate

  property bool active: false
  property real ox: 0          // where the flame leaves the mouth (screen px)
  property real oy: 0
  property int dir: 1          // 1 = to the right, -1 = to the left
  property real cell: 6        // pixel size of the flame's "pixels"
  property var parts: []

  Timer {
    interval: 33
    repeat: true
    running: root.active || root.parts.length > 0
    onTriggered: {
      var dt = 0.033, list = []
      for (var i = 0; i < root.parts.length; i++) {
        var p = root.parts[i]
        p.age += dt
        if (p.age >= p.life) continue
        p.vy -= 110 * dt                  // hot air rises
        p.vx *= 0.985
        p.x += p.vx * dt; p.y += p.vy * dt
        list.push(p)
      }
      if (root.active) {
        for (var k = 0; k < 7; k++) {
          var sp = 380 + Math.random() * 380
          list.push({
            x: root.ox + (Math.random() - 0.5) * root.cell, y: root.oy + (Math.random() - 0.5) * root.cell * 1.4,
            vx: root.dir * sp, vy: (Math.random() - 0.5) * 120,
            size: root.cell * (1.0 + Math.random() * 1.1), grow: 1.0 + Math.random() * 0.9,
            age: 0, life: 0.45 + Math.random() * 0.4
          })
        }
      }
      root.parts = list
      root.requestPaint()
    }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var g = root.cell
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i], f = p.age / p.life
      var col = f < 0.15 ? "#fffbe6" : (f < 0.38 ? "#ffe066" : (f < 0.65 ? "#ff9a2e" : "#d63a24"))
      var s = Math.max(g, Math.round(p.size * (1 + p.grow * f) / g) * g)
      ctx.globalAlpha = Math.max(0, 1 - f * f)
      ctx.fillStyle = col
      ctx.fillRect(Math.round((p.x - s / 2) / g) * g, Math.round((p.y - s / 2) / g) * g, s, s)
    }
    ctx.globalAlpha = 1
  }
}
