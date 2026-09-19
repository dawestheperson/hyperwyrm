import QtQuick

// Happy glow: hearts and sparkles drifting up around the dragon. Steps at 2.5 fps,
// only exists while it is happy.
Canvas {
  id: root
  property int px: 3
  property bool hearts: false
  property int step: 0
  renderTarget: Canvas.Image
  Timer {
    interval: 400
    repeat: true
    running: root.visible
    onTriggered: { root.step = (root.step + 1) % 8; root.requestPaint() }
  }
  readonly property var heart: ["0110110", "1111111", "1111111", "0111110", "0011100", "0001000"]
  readonly property var star: ["00100", "01110", "11111", "01110", "00100"]
  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var seeds = [[0.12, 0], [0.82, 3], [0.5, 5], [0.28, 6], [0.7, 1]]
    for (var i = 0; i < seeds.length; i++) {
      var ph = ((step + seeds[i][1]) % 8) / 8
      var x = seeds[i][0] * width + Math.sin(ph * 6.28 + i) * px * 2
      var y = height * (0.85 - ph * 0.8)
      var isHeart = hearts && i % 2 === 0
      var art = isHeart ? heart : star
      ctx.globalAlpha = Math.max(0, 1 - ph * ph)
      ctx.fillStyle = isHeart ? "#ff6f9c" : "#ffe27a"
      for (var r = 0; r < art.length; r++)
        for (var c = 0; c < art[r].length; c++)
          if (art[r].charAt(c) === "1") ctx.fillRect(x + c * px * 0.7, y + r * px * 0.7, px * 0.7 + 0.5, px * 0.7 + 0.5)
    }
    ctx.globalAlpha = 1
  }
}
