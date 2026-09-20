import QtQuick
import "Sprites.js" as Sprites

// One pre-rendered 32x32 dragon frame, painted as horizontal runs of rects.
// The canvas only repaints when something visible changes.
Item {
  id: root

  property int stage: 0
  property string colorName: "red"
  property string action: "idle"     // walk | idle | sleep
  property int frame: 0
  property real px: 1
  property bool mirrored: false
  property bool egg: false
  property bool silhouette: false
  property bool dull: false            // sulking: washed-out colours

  readonly property int cells: egg ? Sprites.N : Sprites.size(stage)
  implicitWidth: cells * px
  implicitHeight: cells * px

  onStageChanged: canvas.requestPaint()
  onColorNameChanged: canvas.requestPaint()
  onActionChanged: canvas.requestPaint()
  onFrameChanged: canvas.requestPaint()
  onPxChanged: canvas.requestPaint()
  onMirroredChanged: canvas.requestPaint()
  onEggChanged: canvas.requestPaint()
  onSilhouetteChanged: canvas.requestPaint()
  onDullChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate

    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var pal = Sprites.palette(root.colorName, root.dull)
      var rows = Sprites.frame(root.egg ? -1 : root.stage, root.egg ? "idle" : root.action, root.frame)
      var p = root.px
      var n = rows.length
      for (var y = 0; y < rows.length; y++) {
        var row = rows[y]
        var x = 0
        while (x < row.length) {
          var ch = row.charAt(x)
          var start = x
          while (x < row.length && row.charAt(x) === ch) x++
          if (ch === "." || !pal[ch]) continue
          ctx.fillStyle = root.silhouette ? "#ffffff" : pal[ch]
          var x0 = root.mirrored ? n - x : start
          // +0.5 px overlap hides hairline seams at fractional display scales
          ctx.fillRect(x0 * p, y * p, (x - start) * p + 0.5, p + 0.5)
        }
      }
    }
  }
}
