import QtQuick

// A one-shot confetti/shell-shard burst. Runs a 30 fps timer only while any
// piece is still in the air, so it is free the rest of the time.
Canvas {
  id: root
  renderTarget: Canvas.Image
  renderStrategy: Canvas.Immediate

  property var parts: []
  property var colors: ["#ffffff"]
  property real gravity: 1200

  function burst(cx, cy, count, minSpeed, maxSpeed, minSize, maxSize) {
    var list = parts.slice()
    for (var i = 0; i < count; i++) {
      var a = Math.random() * Math.PI * 2
      var s = minSpeed + Math.random() * (maxSpeed - minSpeed)
      var w = minSize + Math.random() * (maxSize - minSize)
      list.push({
        x: cx, y: cy,
        vx: Math.cos(a) * s, vy: Math.sin(a) * s - 250,
        rot: Math.random() * 6.283, vr: (Math.random() - 0.5) * 14,
        w: w, h: w * (0.45 + Math.random() * 0.5),
        color: colors[Math.floor(Math.random() * colors.length)],
        age: 0, life: 2.2 + Math.random() * 1.6
      })
    }
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
        if (p.age >= p.life || p.y > root.height + 60) continue
        p.vy += root.gravity * dt
        p.vx *= 0.992
        p.x += p.vx * dt; p.y += p.vy * dt; p.rot += p.vr * dt
        out.push(p)
      }
      root.parts = out
      root.requestPaint()
    }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    for (var i = 0; i < parts.length; i++) {
      var p = parts[i]
      ctx.save()
      ctx.globalAlpha = Math.max(0, Math.min(1, (p.life - p.age) / 0.6))
      ctx.translate(p.x, p.y)
      ctx.rotate(p.rot)
      ctx.fillStyle = p.color
      ctx.fillRect(-p.w / 2, -p.h / 2, p.w, p.h)
      ctx.restore()
    }
  }
}
