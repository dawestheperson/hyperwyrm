import QtQuick

// A tiny pixel gem used for badges and dropped gifts.
Canvas {
  id: root
  property color tint: "#ffd84d"
  property int px: 2
  property bool locked: false
  readonly property var art: [
    "..oooo..",
    ".ohhllo.",
    "ohhllllo",
    "ohllllmo",
    ".ollmmo.",
    "..ommo..",
    "...oo..."
  ]
  width: 8 * px
  height: 7 * px
  renderTarget: Canvas.Image
  onTintChanged: requestPaint()
  onLockedChanged: requestPaint()
  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var cols = locked
      ? { o: "#3b3f47", h: "#555b66", l: "#4a4f59", m: "#3f444d" }
      : { o: Qt.darker(tint, 1.9), h: Qt.lighter(tint, 1.6), l: tint, m: Qt.darker(tint, 1.3) }
    for (var y = 0; y < art.length; y++)
      for (var x = 0; x < art[y].length; x++) {
        var c = cols[art[y].charAt(x)]
        if (!c) continue
        ctx.fillStyle = c
        ctx.fillRect(x * px, y * px, px + 0.5, px + 0.5)
      }
  }
}
