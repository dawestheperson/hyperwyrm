import QtQuick

// A tiny pixel storm cloud with a few raindrops. It steps at 3 fps and only
// exists while the dragon is unhappy.
Canvas {
  id: root
  property int px: 3
  property int step: 0
  readonly property var art: [
    "....GGGG......",
    "..GGgggggG....",
    ".GgwwggggggG..",
    "GgggggggggggG.",
    ".GgggggggggG..",
    "..GGGGGGGGG...",
  ]
  readonly property var colors: ({ G: "#39404f", g: "#6b7686", w: "#93a0b6" })
  width: 14 * px
  height: 12 * px
  renderTarget: Canvas.Image
  renderStrategy: Canvas.Immediate

  Timer {
    interval: 350
    repeat: true
    running: root.visible
    onTriggered: { root.step = (root.step + 1) % 4; root.requestPaint() }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    for (var y = 0; y < art.length; y++)
      for (var x = 0; x < art[y].length; x++) {
        var c = colors[art[y].charAt(x)]
        if (!c) continue
        ctx.fillStyle = c
        ctx.fillRect(x * px, y * px, px + 0.5, px + 0.5)
      }
    // raindrops falling under the cloud
    ctx.fillStyle = "#5aa9e6"
    var cols = [3, 7, 10]
    for (var i = 0; i < cols.length; i++) {
      var yy = 6 + ((step + i) % 4) * 1.5
      ctx.fillRect(cols[i] * px, yy * px, px, px * 1.5)
    }
  }
}
