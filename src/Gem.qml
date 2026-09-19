import QtQuick
import "Badges.js" as Badges

// A tiny 8x8 pixel badge icon, tinted with the badge colour. Used for the badges
// in the panel and for gifts left on the floor.
Canvas {
  id: root
  property string kind: "pebble"
  property color tint: "#ffd84d"
  property int px: 2
  property bool locked: false
  width: 8 * px
  height: 8 * px
  renderTarget: Canvas.Image
  onTintChanged: requestPaint()
  onKindChanged: requestPaint()
  onLockedChanged: requestPaint()
  onPaint: {
    var ctx = getContext("2d")
    ctx.clearRect(0, 0, width, height)
    var art = Badges.ART[kind] || Badges.ART.pebble
    var cols = locked
      ? { o: "#3b3f47", h: "#555b66", l: "#4a4f59", m: "#3f444d", L: "#4a4f59", y: "#4a4f59", w: "#555b66", k: "#3b3f47", r: "#4a4f59" }
      : { o: Qt.darker(tint, 1.9), h: Qt.lighter(tint, 1.6), l: tint, m: Qt.darker(tint, 1.3),
          L: "#4fb85a", y: "#ffe27a", w: "#ffffff", k: "#4a3626", r: "#e8484f" }
    if (!locked && kind === "leaf") { cols.h = "#8fe08f"; cols.m = "#2f7d3a" }
    for (var y = 0; y < art.length; y++)
      for (var x = 0; x < art[y].length; x++) {
        var c = cols[art[y].charAt(x)]
        if (!c) continue
        ctx.fillStyle = c
        ctx.fillRect(x * px, y * px, px + 0.5, px + 0.5)
      }
  }
}
