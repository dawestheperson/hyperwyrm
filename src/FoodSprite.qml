import QtQuick
import "Foods.js" as Foods

// A 14x14 8-bit food (or poop) at an integer pixel scale. Painted once.
Item {
  id: root
  property string kind: "apple"
  property int px: 3

  implicitWidth: Foods.M * px
  implicitHeight: Foods.M * px
  width: implicitWidth
  height: implicitHeight

  onKindChanged: canvas.requestPaint()
  onPxChanged: canvas.requestPaint()

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    onPaint: {
      var ctx = getContext("2d")
      ctx.clearRect(0, 0, width, height)
      var rows = Foods.ART[root.kind] || Foods.ART.apple
      var p = root.px
      for (var y = 0; y < rows.length; y++) {
        var row = rows[y], x = 0
        while (x < row.length) {
          var ch = row.charAt(x), start = x
          while (x < row.length && row.charAt(x) === ch) x++
          var col = Foods.PAL[ch]
          if (ch === "." || !col) continue
          ctx.fillStyle = col
          ctx.fillRect(start * p, y * p, (x - start) * p + 0.5, p + 0.5)
        }
      }
    }
  }
}
