import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "Hatch.js" as Hatch
import "Sprites.js" as Sprites

// The hatching cutscene: a full-screen overlay with a big egg.
//
//   0-5 s      the egg just sits there
//   5-10 s     it jostles faintly from the inside
//   5-8 s      cracks appear in three stages, the egg holds still
//   then       a shudder, a white flash, the silhouette, confetti, and the
//              wyrmling comes up in colour, wiggling
//   then       a box asks for a name; confirming shrinks everything back to
//              normal size and the dragon starts roaming from the spot
//
// Escape (or the Cancel link) backs out any time before the burst.
PanelWindow {
  id: scene

  required property var pet

  screen: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === pet.hatchScreenName) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }
  anchors { left: true; right: true; top: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "hyperwyrm-hatch"
  WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  readonly property int bigPx: Math.max(6, Math.min(14, Math.floor(Math.min(width, height) * 0.5 / 32)))
  readonly property int normalPx: 3

  // sit | jostle | cracks | shudder | burst | naming | done
  property string phase: "sit"
  property int crackStage: 0
  property real pxNow: bigPx
  property real silAlpha: 0
  property real crackTotal: 6500
  readonly property bool preBurst: phase === "sit" || phase === "jostle" || phase === "cracks" || phase === "shudder"

  // --- timeline --------------------------------------------------------------

  function begin() {
    pxNow = bigPx
    crackStage = 0
    silAlpha = 0
    nameInput.text = ""
    if (pet.namingPending && pet.hatched) {          // resumed after a restart
      phase = "naming"
      Qt.callLater(function() { nameInput.forceActiveFocus() })
      return
    }
    phase = "sit"
    beat.interval = 5000
    beat.restart()
  }

  function advance() {
    if (phase === "sit") {
      phase = "jostle"
      beat.interval = 5000; beat.restart()
    } else if (phase === "jostle") {
      phase = "cracks"
      crackStage = 1
      crackTotal = 5000 + Math.random() * 3000
      beat.interval = crackTotal * 0.4; beat.restart()
    } else if (phase === "cracks") {
      if (crackStage === 1) { crackStage = 2; beat.interval = crackTotal * 0.35; beat.restart() }
      else if (crackStage === 2) { crackStage = 3; beat.interval = crackTotal * 0.25; beat.restart() }
      else { phase = "shudder"; beat.interval = 500; beat.restart() }
    } else if (phase === "shudder") {
      burst()
    } else if (phase === "burst") {
      phase = "naming"
      Qt.callLater(function() { nameInput.forceActiveFocus() })
    }
  }

  function burst() {
    phase = "burst"
    pet.hatchBurst()
    silAlpha = 1
    flashAnim.restart()
    ringAnim.restart()
    var pal = Sprites.palette(pet.colorName)
    confetti.colors = Hatch.CONFETTI.concat([pal.m, pal.h, pal.a, pal.m, pal.a])
    confetti.burst(width / 2, height / 2, 110, 350, 1100, 8, 20)
    silReveal.restart()
    beat.interval = 2800; beat.restart()
  }

  function cancel() {
    if (!preBurst) return
    beat.stop()
    pet.cancelHatch()
  }

  function confirm() {
    if (phase !== "naming") return
    phase = "done"
    beat.stop()
    doneAnim.restart()
  }

  Timer { id: beat; onTriggered: scene.advance() }
  onVisibleChanged: if (visible) begin(); else beat.stop()

  // Second confetti pop as the silhouette turns to colour.
  Timer {
    id: pop2
    interval: 1300
    running: scene.phase === "burst"
    onTriggered: confetti.burst(scene.width / 2, scene.height / 2 - 40, 70, 250, 800, 8, 16)
  }

  // --- visuals ---------------------------------------------------------------

  FocusScope {
    anchors.fill: parent
    focus: true
    Keys.onEscapePressed: scene.cancel()

    Rectangle {
      id: dim
      anchors.fill: parent
      color: "black"
      opacity: scene.phase === "done" ? 0 : 0.66
      Behavior on opacity { NumberAnimation { duration: scene.phase === "done" ? 900 : 500 } }
      MouseArea { anchors.fill: parent }        // modal: swallow clicks
    }

    // ---- the egg ----
    Item {
      id: eggBox
      anchors.centerIn: parent
      width: 32 * scene.bigPx; height: 32 * scene.bigPx
      visible: scene.preBurst
      property real jx: 0
      property real jr: 0
      transform: Translate { x: eggBox.jx }
      rotation: jr
      transformOrigin: Item.Bottom

      DragonSprite {
        anchors.fill: parent
        px: scene.bigPx
        egg: true
        colorName: scene.pet.colorName
      }
      Canvas {
        id: cracks
        anchors.fill: parent
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate
        Connections { target: scene; function onCrackStageChanged() { cracks.requestPaint() } }
        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var n = scene.crackStage
          if (n < 1) return
          var st = Hatch.CRACKS[n - 1], p = scene.bigPx
          if (n >= 2) {
            ctx.fillStyle = n >= 3 ? "#fff3a8" : "#ffd23f"
            for (var g = 0; g < st.glow.length; g++) ctx.fillRect(st.glow[g][0] * p, st.glow[g][1] * p, p, p)
          }
          ctx.fillStyle = "#20140f"
          for (var d = 0; d < st.dark.length; d++) ctx.fillRect(st.dark[d][0] * p, st.dark[d][1] * p, p, p)
        }
      }

      // Faint jostle from the inside (5-10 s), never big.
      SequentialAnimation {
        running: scene.phase === "jostle"
        loops: Animation.Infinite
        onRunningChanged: if (!running) eggBox.jx = 0
        NumberAnimation { target: eggBox; property: "jx"; to: 5; duration: 240; easing.type: Easing.InOutSine }
        NumberAnimation { target: eggBox; property: "jx"; to: -3; duration: 330; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 180 }
        NumberAnimation { target: eggBox; property: "jx"; to: 2; duration: 210; easing.type: Easing.InOutSine }
        NumberAnimation { target: eggBox; property: "jx"; to: -5; duration: 290; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 260 }
      }
      SequentialAnimation {
        running: scene.phase === "jostle"
        loops: Animation.Infinite
        onRunningChanged: if (!running) eggBox.jr = 0
        NumberAnimation { target: eggBox; property: "jr"; to: 1.4; duration: 310; easing.type: Easing.InOutSine }
        NumberAnimation { target: eggBox; property: "jr"; to: -1.1; duration: 420; easing.type: Easing.InOutSine }
        PauseAnimation { duration: 220 }
        NumberAnimation { target: eggBox; property: "jr"; to: 0.8; duration: 260; easing.type: Easing.InOutSine }
        NumberAnimation { target: eggBox; property: "jr"; to: -1.4; duration: 380; easing.type: Easing.InOutSine }
      }
      // A hard shudder right before it bursts.
      SequentialAnimation {
        running: scene.phase === "shudder"
        loops: Animation.Infinite
        onRunningChanged: if (!running) { eggBox.jx = 0; eggBox.jr = 0 }
        ParallelAnimation {
          NumberAnimation { target: eggBox; property: "jx"; to: 9; duration: 45 }
          NumberAnimation { target: eggBox; property: "jr"; to: 4; duration: 45 }
        }
        ParallelAnimation {
          NumberAnimation { target: eggBox; property: "jx"; to: -9; duration: 45 }
          NumberAnimation { target: eggBox; property: "jr"; to: -4; duration: 45 }
        }
      }
    }

    // ---- the wyrmling ----
    Item {
      id: hatchBox
      anchors.centerIn: parent
      width: 32 * scene.pxNow; height: 32 * scene.pxNow
      visible: !scene.preBurst
      transformOrigin: Item.Bottom
      property real wr: 0
      property real wy: 0
      rotation: wr
      transform: Translate { y: hatchBox.wy }

      property int frame: 0
      Timer {
        interval: 100
        repeat: true
        running: hatchBox.visible && scene.phase !== "done"
        onTriggered: hatchBox.frame = (hatchBox.frame + 1) % 8
      }
      DragonSprite {
        anchors.fill: parent
        px: Math.max(scene.normalPx, Math.round(scene.pxNow))
        stage: 0
        colorName: scene.pet.colorName
        action: "walk"
        frame: hatchBox.frame
      }
      // White silhouette that fades into colour.
      DragonSprite {
        anchors.fill: parent
        px: Math.max(scene.normalPx, Math.round(scene.pxNow))
        stage: 0
        colorName: scene.pet.colorName
        action: "walk"
        frame: hatchBox.frame
        silhouette: true
        opacity: scene.silAlpha
      }
      SequentialAnimation {
        running: !scene.preBurst && scene.phase !== "done"
        loops: Animation.Infinite
        NumberAnimation { target: hatchBox; property: "wr"; to: 7; duration: 240; easing.type: Easing.InOutSine }
        NumberAnimation { target: hatchBox; property: "wr"; to: -7; duration: 300; easing.type: Easing.InOutSine }
      }
      SequentialAnimation {
        running: !scene.preBurst && scene.phase !== "done"
        loops: Animation.Infinite
        NumberAnimation { target: hatchBox; property: "wy"; to: -26; duration: 260; easing.type: Easing.OutQuad }
        NumberAnimation { target: hatchBox; property: "wy"; to: 0; duration: 260; easing.type: Easing.InQuad }
        PauseAnimation { duration: 140 }
      }
    }

    // White burst, expanding ring, confetti.
    Rectangle {
      id: flash
      anchors.fill: parent
      color: "white"
      opacity: 0
    }
    Rectangle {
      id: ring
      anchors.centerIn: parent
      width: 200; height: 200; radius: 100
      color: "transparent"
      border.color: "white"; border.width: 10
      opacity: 0; scale: 0.2
    }
    Confetti { id: confetti; anchors.fill: parent }

    // ---- naming ----
    Rectangle {
      id: card
      width: 380
      height: cardCol.implicitHeight + 36
      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.min(parent.height - height - 24, parent.height / 2 + 16 * scene.bigPx + 20)
      radius: Style.cornerRadius > 0 ? 12 : 0
      color: Color.popups.background
      border.color: Color.popups.border
      border.width: 2
      opacity: scene.phase === "naming" ? 1 : 0
      scale: scene.phase === "naming" ? 1 : 0.9
      visible: opacity > 0
      Behavior on opacity { NumberAnimation { duration: 260 } }
      Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack } }

      Column {
        id: cardCol
        anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
        anchors.margins: 18
        spacing: 12
        Text {
          text: "Name your dragon"
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
        }
        TextField {
          id: nameInput
          width: parent.width
          maximumLength: 16
          placeholderText: "Ember"
          foreground: Color.popups.text
          onAccepted: scene.confirm()
        }
        Button {
          text: "Confirm"
          foreground: Color.popups.text
          bordered: true
          onClicked: scene.confirm()
        }
      }
    }

    // Back out before the burst.
    Text {
      anchors.top: parent.top; anchors.right: parent.right
      anchors.margins: 24
      visible: scene.preBurst
      text: "Cancel  (Esc)"
      color: "white"
      opacity: 0.6
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: scene.cancel() }
    }
  }

  // --- animations ------------------------------------------------------------

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
  // The silhouette holds for a beat, then turns to colour.
  SequentialAnimation {
    id: silReveal
    PauseAnimation { duration: 1000 }
    NumberAnimation { target: scene; property: "silAlpha"; to: 0; duration: 1300; easing.type: Easing.InOutQuad }
  }
  // Confirm: shrink to normal size, fade the backdrop, hand over to roaming.
  SequentialAnimation {
    id: doneAnim
    NumberAnimation { target: scene; property: "pxNow"; to: scene.normalPx; duration: 900; easing.type: Easing.InOutCubic }
    ScriptAction {
      script: scene.pet.finishHatch(nameInput.text, 0.5, 0.5)
    }
  }
}
