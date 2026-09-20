import QtQuick

// A small flower that marks where the Earth Dragon went underground. It grows when the dragon
// dives, and withers away when the dragon comes up somewhere else. Painted once per state.
Item {
  id: root
  property bool withered: false
  property real cell: 3
  width: 12 * cell; height: 16 * cell
  transformOrigin: Item.Bottom

  onVisibleChanged: {
    if (visible) { rotation = 0; opacity = 1; scale = 0; growAnim.restart() }
    else { growAnim.stop(); wiltAnim.stop() }
  }
  onWitheredChanged: { canvas.requestPaint(); if (withered) wiltAnim.restart() }

  NumberAnimation { id: growAnim; target: root; property: "scale"; from: 0; to: 1; duration: 600; easing.type: Easing.OutBack }
  ParallelAnimation {
    id: wiltAnim
    NumberAnimation { target: root; property: "rotation"; to: 32; duration: 1300; easing.type: Easing.InQuad }
    SequentialAnimation {
      PauseAnimation { duration: 900 }
      NumberAnimation { target: root; property: "opacity"; to: 0; duration: 600 }
    }
  }

  Canvas {
    id: canvas
    anchors.fill: parent
    renderTarget: Canvas.Image
    renderStrategy: Canvas.Immediate
    onPaint: {
      var ctx = getContext("2d"), p = root.cell, w = root.withered
      ctx.clearRect(0, 0, width, height)
      var petal = w ? "#8a6a4a" : "#ff8fb8", core = w ? "#6b5636" : "#ffd23f", stem = w ? "#7a6a3a" : "#4fa832", leaf = w ? "#8c7a3f" : "#6fc94a", dark = w ? "#5a4a26" : "#2f7a25"
      function cell(x, y, c) { ctx.fillStyle = c; ctx.fillRect(x * p, y * p, p + 0.5, p + 0.5) }
      var petals = [[5,0],[6,0],[3,1],[4,1],[5,1],[6,1],[7,1],[8,1],[2,2],[3,2],[4,2],[7,2],[8,2],[9,2],[3,3],[4,3],[7,3],[8,3],[4,4],[5,4],[6,4],[7,4]]
      for (var i = 0; i < petals.length; i++) cell(petals[i][0] + 0, petals[i][1] + 0, petal)
      cell(5, 2, core); cell(6, 2, core); cell(5, 3, core); cell(6, 3, core)
      for (var y = 5; y < 16; y++) { cell(5, y, stem); cell(6, y, dark) }
      var leaves = [[3,8],[4,8],[2,7],[3,7],[7,10],[8,10],[9,9],[8,9]]
      for (var j = 0; j < leaves.length; j++) cell(leaves[j][0], leaves[j][1], leaf)
    }
  }
}
