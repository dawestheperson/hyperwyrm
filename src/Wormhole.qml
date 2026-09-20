import QtQuick

// A wormhole: a tall grey oval with a swirl turning inside it. It scales open and shut,
// and only repaints (about 15 times a second) while it is at least partly open.
Canvas {
  id: root
  property real open: 0                // 0 = closed, 1 = fully open
  property real cell: 3
  property real t: 0
  readonly property int cols: 24
  readonly property int rows: 40
  width: cols * cell; height: rows * cell
  visible: open > 0.01
  scale: open
  opacity: Math.min(1, open * 1.4)
  renderTarget: Canvas.Image
  renderStrategy: Canvas.Immediate

  Timer {
    interval: 66
    repeat: true
    running: root.visible
    onTriggered: { root.t += 0.28; root.requestPaint() }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var rx = cols / 2, ry = rows / 2
    for (var y = 0; y < rows; y++)
      for (var x = 0; x < cols; x++) {
        var dx = (x + 0.5 - rx) / rx, dy = (y + 0.5 - ry) / ry
        var r = Math.sqrt(dx * dx + dy * dy)
        if (r > 1) continue
        var ang = Math.atan2(dy, dx)
        var v = Math.sin(3 * ang + r * 9 - t)                 // the swirl: three arms winding in
        var col
        if (r > 0.86) col = v > 0 ? "#dfe3ee" : "#aab1c4"    // a bright rim
        else if (r < 0.14) col = "#15171d"                    // the dark core
        else if (v > 0.55) col = "#c9cfde"
        else if (v > 0) col = "#8f97ab"
        else if (v > -0.55) col = "#626a7e"
        else col = "#3b4152"
        ctx.fillStyle = col
        ctx.fillRect(x * cell, y * cell, cell + 0.5, cell + 0.5)
      }
  }
}
