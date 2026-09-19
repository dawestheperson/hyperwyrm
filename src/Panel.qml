import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Ui
import qs.Commons
import "Sprites.js" as Sprites
import "Foods.js" as Foods
import "Badges.js" as Badges

Panel {
  id: root
  moduleName: "dracula.hyperwyrm"
  ipcTarget: "dracula.hyperwyrm"

  readonly property var pet: bar && bar.shell ? bar.shell.serviceFor(moduleName) : null
  property string badgeHint: ""
  readonly property bool ready: !!pet && pet.initialized === true
  property bool confirmReset: false

  // Food drag from the shelf to anywhere on screen (window coordinates; the
  // panel window covers the whole screen, so these are screen coordinates).
  property string dragKind: ""
  property real dragX: 0
  property real dragY: 0
  function beginDrag(kind, p) { dragKind = kind; dragX = p.x; dragY = p.y }
  function moveDrag(p) { if (dragKind !== "") { dragX = p.x; dragY = p.y } }
  function endDrag(p) {
    var kind = dragKind
    dragKind = ""
    if (kind === "" || !root.pet) return
    var c = panel.cardOrigin
    var inside = p.x >= c.x - 8 && p.x <= c.x + panel.contentWidth + 8 && p.y >= c.y - 8 && p.y <= c.y + panel.contentHeight + 8
    if (inside) return                       // released on the card: cancel
    root.pet.dropFood(kind, p.x, p.y, panel.screen ? panel.screen.name : "")
    root.close()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (!opened) confirmReset = false

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    dimmed: !root.ready || (root.ready && root.pet.roamEnabled)
    tooltipText: root.ready
      ? root.pet.tooltip + (root.pet.roamEnabled ? "\nOut exploring · right-click to call it back" : "\nRight-click to let it out")
      : "Hyperwyrm"
    onPressed: function(b) {
      if (b === Qt.RightButton && root.ready) root.pet.setRoam(!root.pet.roamEnabled)
      else root.toggle()
    }

    // One static idle frame: the bar icon never animates, so it never repaints.
    Item {
      id: iconBox
      anchors.centerIn: parent
      readonly property real size: Style.bar.iconCanvas + 6
      width: size; height: size
      DragonSprite {
        anchors.centerIn: parent
        px: 1
        scale: iconBox.size / 32
        transformOrigin: Item.Center
        stage: root.ready ? root.pet.stage : 0
        colorName: root.ready ? root.pet.colorName : "red"
        dull: root.ready && root.pet.unhappy
        egg: root.ready ? root.pet.isEgg : true
        action: root.ready && root.pet.sleeping ? "sleep" : "idle"
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight((colLoader.item ? colLoader.item.implicitHeight : 0), Style.space(720))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Loader {
        id: colLoader
        width: parent.width
        active: root.ready
        sourceComponent: panelContent
      }

      // The snack you are carrying; it can leave the card.
      FoodSprite {
        visible: root.dragKind !== ""
        kind: root.dragKind !== "" ? root.dragKind : "apple"
        px: 4
        z: 100
        x: keyCatcher.mapFromItem(null, root.dragX, root.dragY).x - width / 2
        y: keyCatcher.mapFromItem(null, root.dragX, root.dragY).y - height / 2
      }

    }
  }

  Component {
    id: panelContent
    Column {
      id: column
      width: parent ? parent.width : 0
      spacing: Style.space(10)

      // ---- header: portrait + name + speech ----
      Item {
        width: parent.width
        height: headerRow.height
      Row {
        id: headerRow
        spacing: Style.space(12)
        DragonSprite {
          px: 3
          stage: root.pet.stage
          colorName: root.pet.colorName
          dull: root.pet.unhappy
          egg: root.pet.isEgg
          action: root.pet.asleepNow ? "curl" : "idle"
        }
        Column {
          anchors.verticalCenter: parent.verticalCenter
          spacing: Style.space(2)
          Text {
            text: root.pet.isEgg ? "Egg" : root.pet.petName
            color: root.bar.foreground
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.title
            font.bold: true
          }
          Text {
            text: root.pet.isEgg ? "Pick a color, then hatch it." : root.pet.stageLabel + "  \u00b7  " + root.pet.mood
            color: Qt.darker(root.bar.foreground, 1.4)
            font.family: root.bar.fontFamily
            font.pixelSize: Style.font.body
          }
        }
      }
      // Collected badges, top right. Hover one for its name.
      Flow {
        id: badgeFlow
        visible: root.pet.badges.length > 0
        anchors.top: parent.top
        anchors.right: parent.right
        width: Math.min(parent.width - headerRow.width - 8, 6 * 22)
        spacing: 4
        layoutDirection: Qt.RightToLeft
        Repeater {
          model: root.pet.badges
          delegate: Gem {
            required property string modelData
            px: 2
            tint: (Badges.find(modelData) || { color: "#ffd84d" }).color
            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              onEntered: root.badgeHint = (Badges.find(parent.modelData) || { name: "" }).name
              onExited: root.badgeHint = ""
            }
          }
        }
      }
      Text {
        visible: root.badgeHint !== ""
        anchors.right: parent.right
        anchors.top: badgeFlow.bottom
        text: root.badgeHint
        color: Qt.darker(root.bar.foreground, 1.3)
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body - 1
      }
      }
      Text {
        width: parent.width
        visible: text.trim() !== ""
        text: root.pet.speech !== "" ? "\u201c" + root.pet.speech + "\u201d" : ""
        wrapMode: Text.WordWrap
        color: root.bar.foreground
        font.family: root.bar.fontFamily
        font.pixelSize: Style.font.body
        font.italic: true
      }

      PanelSeparator { foreground: root.bar.foreground }

      // ---- egg only: name, colour, hatch ----
      Column {
        width: parent.width
        spacing: Style.space(10)
        visible: root.pet.isEgg

        Text {
          text: "Color"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Flow {
          width: parent.width
          spacing: Style.space(8)
          Repeater {
            model: Sprites.COLOR_NAMES
            delegate: Rectangle {
              required property string modelData
              width: Style.space(26); height: width
              radius: width / 2
              color: Sprites.COLORS[modelData].main
              border.width: root.pet.colorName === modelData ? 3 : 1
              border.color: root.pet.colorName === modelData ? root.bar.foreground : Qt.rgba(0, 0, 0, 0.4)
              MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.pet.setColor(modelData) }
            }
          }
        }
        Button {
          text: "Hatch"
          foreground: root.bar.foreground
          bordered: true
          onClicked: { root.pet.beginHatch(panel.screen ? panel.screen.name : ""); root.close() }
        }
      }

      // ---- hatched only: stats and care ----
      Column {
        width: parent.width
        spacing: Style.space(10)
        visible: !root.pet.isEgg

        Text {
          width: parent.width
          visible: root.pet.unhappy
          text: "Unhappy! It avoids you until it's cheered up. Snacks, naps and cleaning up its mess all help."
          wrapMode: Text.WordWrap
          color: root.bar.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          width: parent.width
          visible: root.pet.poops.length > 0
          text: "Mess on your screen: " + root.pet.poops.length + ". Click it to clean it up. It stresses the dragon out after 30 seconds!"
          wrapMode: Text.WordWrap
          color: root.bar.urgent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        StatBar { label: "Fullness";  hint: "Its tummy. Snacks keep it purring!"; value: root.pet.fullness }
        StatBar { label: "Happiness"; hint: "Its mood. Low = grumpy and messy!"; value: root.pet.joy; lowAt: 35 }
        StatBar { label: "Energy";    hint: "Sleepy meter. Naps refill it!"; value: root.pet.energy }
        StatBar { label: "Bond";      hint: "Trust in you. Slows sulking a bit!"; value: root.pet.bond }
        StatBar {
          label: root.pet.maxStage
            ? "Fully grown  " + Math.floor(root.pet.xp) + " XP"
            : "Growth  " + Math.floor(root.pet.xp) + "/" + root.pet.stageXp[root.pet.stage + 1] + " XP"
          hint: root.pet.maxStage ? "All grown up. So proud!" : "Feed and play to grow!"
          value: root.pet.maxStage ? 100 : root.pet.xp / root.pet.stageXp[root.pet.stage + 1] * 100
        }

        // ---- 8-bit food: drag a piece onto your screen ----
        Text {
          text: "Feed  \u00b7  drag a snack onto your screen"
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Row {
          spacing: Style.space(8)
          Repeater {
            model: Foods.KINDS
            delegate: Rectangle {
              id: cell
              required property string modelData
              width: Style.space(48); height: width
              radius: Style.cornerRadius > 0 ? 8 : 0
              color: Style.selectedFillFor(root.bar.foreground, Color.accent)
              border.width: 1
              border.color: Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.25)
              FoodSprite {
                anchors.centerIn: parent
                kind: cell.modelData
                px: 3
                opacity: root.dragKind === cell.modelData ? 0.3 : 1
              }
              MouseArea {
                anchors.fill: parent
                cursorShape: Qt.OpenHandCursor
                preventStealing: true
                onPressed: function(m) { root.beginDrag(cell.modelData, mapToItem(null, m.x, m.y)) }
                onPositionChanged: function(m) { if (pressed) root.moveDrag(mapToItem(null, m.x, m.y)) }
                onReleased: function(m) { root.endDrag(mapToItem(null, m.x, m.y)) }
                onCanceled: root.dragKind = ""
              }
            }
          }
        }

        Button {
          visible: root.pet.foodOnScreen > 0
          text: "Clear food from screen (" + root.pet.foodOnScreen + ")"
          foreground: root.bar.foreground
          bordered: true
          tooltipText: "Removes every snack lying around. You can also click one to pick it up."
          onClicked: root.pet.clearFood()
        }

        Row {
          spacing: Style.space(6)
          Button {
            text: root.pet.restPhase === "resting" ? "Resting " + root.pet.restRemaining + "s"
              : (root.pet.restPhase === "going" ? "Going to bed..." : "Rest")
            foreground: root.bar.foreground
            bordered: true
            selected: root.pet.resting
            tooltipText: "Sends it to its favourite spot to curl up for a minute"
            onClicked: root.pet.resting ? root.pet.cancelRest() : root.pet.startRest()
          }
          Button {
            text: root.pet.playing ? "Playing..." : "Play"
            foreground: root.bar.foreground
            bordered: true
            selected: root.pet.playing
            tooltipText: "It chases your mouse cursor for 30-45 seconds, like a kitten chasing a laser dot"
            onClicked: root.pet.startPlay()
          }
          Button {
            text: root.pet.gameState === "run" ? "Tag! " + root.pet.gameLeft + "s" : "Tag"
            foreground: root.bar.foreground
            bordered: true
            selected: root.pet.gameState === "run"
            tooltipText: "A 20 second game of tag: click the dragon 4 times while it dashes away. It runs on its little neural net."
            onClicked: root.pet.startGame()
          }
        }

        Button {
          text: root.pet.roamEnabled ? "Put away" : "Let it out"
          foreground: root.bar.foreground
          bordered: true
          selected: root.pet.roamEnabled
          tooltipText: "Out: it roams over your windows. Drag it, click to chat, right-click to put it away."
          onClicked: root.pet.setRoam(!root.pet.roamEnabled)
        }

        PanelSeparator { foreground: root.bar.foreground }

        Button {
          text: root.confirmReset ? "Really start over?" : "New egg"
          foreground: root.confirmReset ? root.bar.urgent : root.bar.foreground
          bordered: true
          onClicked: {
            if (root.confirmReset) { root.pet.newEgg(); root.confirmReset = false }
            else root.confirmReset = true
          }
        }
      }
    }
  }

  component StatBar: Item {
    property string label: ""
    property string hint: ""
    property real value: 0
    property real lowAt: 25
    width: parent.width
    implicitHeight: Style.space(28)
    Text {
      id: lbl
      text: parent.label
      color: Qt.darker(root.bar.foreground, 1.4)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.bodySmall
    }
    Text {
      anchors.left: lbl.right
      anchors.leftMargin: Style.space(8)
      anchors.right: parent.right
      anchors.baseline: lbl.baseline
      text: parent.hint
      horizontalAlignment: Text.AlignRight
      elide: Text.ElideRight
      color: Qt.darker(root.bar.foreground, 1.7)
      font.family: root.bar.fontFamily
      font.pixelSize: Style.font.caption
      font.italic: true
    }
    Rectangle {
      anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
      height: Style.space(6)
      radius: height / 2
      color: Style.selectedFillFor(root.bar.foreground, Color.accent)
      Rectangle {
        width: parent.width * Math.max(0, Math.min(1, parent.parent.value / 100))
        height: parent.height
        radius: parent.radius
        color: parent.parent.value < parent.parent.lowAt ? root.bar.urgent : Color.accent
      }
    }
  }
}
