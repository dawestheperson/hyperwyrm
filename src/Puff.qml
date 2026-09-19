import QtQuick

// Small rising puffs (nostril steam, or a grumpy little fire puff). Only
// simulated while a puff is still alive.
Canvas {
  id: root
  renderTarget: Canvas.Image
  renderStrategy: Canvas.Immediate

  property real cell: 4
  property var parts: []

  function puff(x, y, dir, count, palette) {
    var list = parts.slice()
    for (var i = 0; i < count; i++)
      list.push({
        x: x + (Math.random() - 0.5) * cell, y: y + (Math.random() - 0.5) * cell,
        vx: dir * (30 + Math.random() * 80), vy: -(35 + Math.random() * 60),
        size: cell * (0.9 + Math.random() * 0.9), age: 0, life: 0.7 + Math.random() * 0.5,
        color: palette[Math.floor(Math.random() * palette.length)]
      })
    parts = list
  }

  Timer {
    interval: 33
    repeat: true
    running: root.parts.length > 0
    onTriggered: {
      var dt = 0.033, out = []
      for (var i = 0; i < root.parts.length; i++) {
        var p = root.parts[i]
        p.age += dt
        if (p.age >= p.life) continue
        p.vx *= 0.97; p.vy -= 20 * dt
        p.x += p.vx * dt; p.y += p.vy * dt
        out.push(p)
      }
      root.parts = out
      root.requestPaint()
    }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var g = root.cell
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i], f = p.age / p.life
      var s = Math.max(g, Math.round(p.size * (1 + f * 1.4) / g) * g)
      ctx.globalAlpha = Math.max(0, 0.9 * (1 - f))
      ctx.fillStyle = p.color
      ctx.fillRect(Math.round((p.x - s / 2) / g) * g, Math.round((p.y - s / 2) / g) * g, s, s)
    }
    ctx.globalAlpha = 1
  }
}
