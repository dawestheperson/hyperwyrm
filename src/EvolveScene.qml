import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import "Hatch.js" as Hatch
import "Sprites.js" as Sprites

// The evolution cutscene, old-Pokemon style:
//
//   glow      the old form in colour, pulsing light rings
//   flicker   it turns into a white silhouette that flips between the old and
//             the new shape, faster and faster
//   burst     white flash, expanding ring, confetti; the new form appears as a
//             silhouette and turns to colour
//   show      "<name> evolved into a <form>!" holds for a few seconds
//   done      everything shrinks back to normal size and it carries on
//
// Escape (or the Skip link) jumps straight to the end.
PanelWindow {
  id: scene

  required property var pet

  screen: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === pet.evolveScreenName) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }
  anchors { left: true; right: true; top: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "hyperwyrm-evolve"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  readonly property int cells: Math.max(Sprites.size(fromStage), Sprites.size(toStage))      // 32, or 64 when the Celestial Dragon is involved
  readonly property int bigPx: Math.max(3, Math.min(14, Math.floor(Math.min(width, height) * 0.5 / cells)))
  readonly property int normalPx: 3
  readonly property int fromStage: pet.evolveFrom
  readonly property int toStage: pet.stage

  property string phase: "glow"     // glow | flicker | burst | show | done
  property real pxNow: bigPx
  property real glowSil: 0          // old form fading to a silhouette
  property real silAlpha: 1         // new form's silhouette turning to colour
  property bool altNew: false
  property int flickerMs: 0
  property bool finishing: false

  // --- timeline --------------------------------------------------------------

  function begin() {
    finishing = false
    pxNow = bigPx
    glowSil = 0
    silAlpha = 1
    altNew = false
    phase = "glow"
    glowAnim.restart()
    beat.interval = 1700; beat.restart()
  }

  function advance() {
    if (phase === "glow") {
      phase = "flicker"
      flickerMs = 0
      flick.interval = 520; flick.restart()
    } else if (phase === "burst") {
      phase = "show"
      beat.interval = 3200; beat.restart()
    } else if (phase === "show") {
      finish()
    }
  }

  function burst() {
    phase = "burst"
    silAlpha = 1
    flashAnim.restart()
    ringAnim.restart()
    var pal = Sprites.palette(pet.colorName)
    confetti.colors = Hatch.CONFETTI.concat([pal.m, pal.h, pal.a, pal.m, pal.a])
    confetti.burst(width / 2, height / 2, 120, 350, 1150, 8, 20)
    silReveal.restart()
    beat.interval = 1800; beat.restart()
  }

  function finish() {
    if (finishing) return
    finishing = true
    beat.stop(); flick.stop()
    phase = "done"
    doneAnim.restart()
  }

  Timer { id: beat; onTriggered: scene.advance() }
  // The silhouette flips between old and new shape, faster each time.
  Timer {
    id: flick
    onTriggered: {
      scene.altNew = !scene.altNew
      scene.flickerMs += interval
      interval = Math.max(70, interval * 0.84)
      if (scene.flickerMs >= 3300) scene.burst()
      else restart()
    }
  }
  Timer {
    interval: 1000
    running: scene.phase === "burst"
    onTriggered: confetti.burst(scene.width / 2, scene.height / 2 - 40, 80, 250, 850, 8, 16)
  }
  onVisibleChanged: if (visible) begin(); else { beat.stop(); flick.stop() }

  // --- visuals ---------------------------------------------------------------

  FocusScope {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: scene.finish()

    Rectangle {
      anchors.fill: parent
      color: "black"
      opacity: scene.phase === "done" ? 0 : 0.7
      Behavior on opacity { NumberAnimation { duration: scene.phase === "done" ? 900 : 500 } }
      MouseArea { anchors.fill: parent }
    }

    // Pulsing light rings behind the sprite while it changes.
    Repeater {
      model: 3
      delegate: Rectangle {
        required property int index
        anchors.centerIn: parent
        width: scene.cells * scene.bigPx * (0.5 + index * 0.28)
        height: width
        radius: width / 2
        color: "white"
        visible: scene.phase === "glow" || scene.phase === "flicker"
        opacity: 0.05 + 0.05 * (scene.phase === "flicker" ? 2 : 1)
        scale: 1
        SequentialAnimation on scale {
          running: scene.visible && (scene.phase === "glow" || scene.phase === "flicker")   // never spin while hidden
          loops: Animation.Infinite
          NumberAnimation { to: 1.18; duration: 500 + index * 130; easing.type: Easing.InOutSine }
          NumberAnimation { to: 0.92; duration: 500 + index * 130; easing.type: Easing.InOutSine }
        }
      }
    }

    Item {
      id: box
      anchors.centerIn: parent
      width: scene.cells * scene.pxNow; height: scene.cells * scene.pxNow
      transformOrigin: Item.Bottom

      property int frame: 0
      Timer {
        interval: 100
        repeat: true
        running: scene.visible && scene.phase !== "done"
        onTriggered: box.frame = (box.frame + 1) % 8
      }
      readonly property int spx: Math.max(scene.normalPx, Math.round(scene.pxNow))

      // old form, in colour
      DragonSprite {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; px: box.spx
        stage: scene.fromStage; colorName: scene.pet.colorName; action: "walk"; frame: box.frame
        opacity: scene.phase === "glow" ? 1 - scene.glowSil : 0
      }
      // old form, white silhouette
      DragonSprite {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; px: box.spx
        stage: scene.fromStage; colorName: scene.pet.colorName; action: "walk"; frame: box.frame
        silhouette: true
        opacity: scene.phase === "glow" ? scene.glowSil : (scene.phase === "flicker" && !scene.altNew ? 1 : 0)
      }
      // new form, in colour
      DragonSprite {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; px: box.spx
        stage: scene.toStage; colorName: scene.pet.colorName; action: "walk"; frame: box.frame
        opacity: (scene.phase === "burst" || scene.phase === "show" || scene.phase === "done") ? 1 : 0
      }
      // new form, white silhouette (flicker, then fades to colour)
      DragonSprite {
        anchors.bottom: parent.bottom; anchors.horizontalCenter: parent.horizontalCenter; px: box.spx
        stage: scene.toStage; colorName: scene.pet.colorName; action: "walk"; frame: box.frame
        silhouette: true
        opacity: scene.phase === "flicker" ? (scene.altNew ? 1 : 0)
          : ((scene.phase === "burst" || scene.phase === "show") ? scene.silAlpha : 0)
      }
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height / 2 + 16 * scene.bigPx + 24
      visible: scene.phase === "burst" || scene.phase === "show"
      opacity: scene.phase === "show" ? 1 : 0.0
      Behavior on opacity { NumberAnimation { duration: 500 } }
      text: scene.pet.petName + " evolved into a " + scene.pet.stageLabel + "!"
      color: "white"
      font.family: Style.font.family
      font.pixelSize: Style.font.title + 8
      font.bold: true
    }

    Rectangle { id: flash; anchors.fill: parent; color: "white"; opacity: 0 }
    Rectangle {
      id: ring
      anchors.centerIn: parent
      width: 200; height: 200; radius: 100
      color: "transparent"; border.color: "white"; border.width: 10
      opacity: 0; scale: 0.2
    }
    Confetti { id: confetti; anchors.fill: parent }

    Text {
      anchors.top: parent.top; anchors.right: parent.right
      anchors.margins: 24
      visible: scene.phase !== "done"
      text: "Skip  (Esc)"
      color: "white"; opacity: 0.6
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: scene.finish() }
    }
  }

  // --- animations ------------------------------------------------------------
  SequentialAnimation {
    id: glowAnim
    PauseAnimation { duration: 900 }
    NumberAnimation { target: scene; property: "glowSil"; to: 1; duration: 700; easing.type: Easing.InOutQuad }
  }
  SequentialAnimation {
    id: flashAnim
    NumberAnimation { target: flash; property: "opacity"; to: 1; duration: 110 }
    PauseAnimation { duration: 160 }
    NumberAnimation { target: flash; property: "opacity"; to: 0; duration: 950; easing.type: Easing.OutQuad }
  }
  ParallelAnimation {
    id: ringAnim
    NumberAnimation { target: ring; property: "scale"; from: 0.2; to: 9; duration: 950; easing.type: Easing.OutCubic }
    SequentialAnimation {
      NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0.9; duration: 1 }
      NumberAnimation { target: ring; property: "opacity"; to: 0; duration: 949; easing.type: Easing.OutQuad }
    }
  }
  SequentialAnimation {
    id: silReveal
    PauseAnimation { duration: 700 }
    NumberAnimation { target: scene; property: "silAlpha"; to: 0; duration: 1200; easing.type: Easing.InOutQuad }
  }
  SequentialAnimation {
    id: doneAnim
    NumberAnimation { target: scene; property: "pxNow"; to: scene.normalPx; duration: 900; easing.type: Easing.InOutCubic }
    ScriptAction { script: scene.pet.finishEvolve() }
  }
}
