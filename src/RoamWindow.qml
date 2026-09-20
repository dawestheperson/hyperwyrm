import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.Commons
import "Brain.js" as Brain
import "Sprites.js" as Sprites
import "Badges.js" as Badges
import "Phrases.js" as Phrases
import "Learner.js" as Learner

// The dragon's playground: a transparent full-screen overlay above your
// windows. Input is limited to the dragon and the mess on the floor (mask), so
// everything else stays clickable.
//
// Who decides what the dragon does, in priority order:
//   1. Resting     walk to its favourite spot, curl up for a minute (Zzz)
//   2. Food        a dropped snack falls; the dragon goes over and eats it
//   3. Play        for 10-15 s it chases your mouse cursor
//   4. Sulking     below 35 happiness it keeps away from the window you use
//                  and leaves messes that stay until you click them
//   5. Its brain   otherwise a CfC/NCP network (Brain.js) steers it
//
// The Wyrmling walks on the floor and window tops; Wyvern and Emperor Dragon
// fly. Physics is time-based; the timer ticks at about 30 fps only while
// something is moving, 10 fps otherwise and 1 fps while curled up.
//
//   click        chat          drag         pick it up and throw it anywhere
//   right-click  put it away   click mess   clean it up   click a snack   pick it up
PanelWindow {
  id: win

  required property var pet

  readonly property int scale: 3
  readonly property int spriteW: 32 * scale
  readonly property int spriteH: 32 * scale
  // Distance from the sprite's top edge to the soles of its feet (walking) or
  // to the ground (curled up).
  readonly property int footOffset: [30, 31, 32][pet.stage] * scale
  readonly property int curlOffset: 31 * scale
  readonly property bool flying: pet.flies
  readonly property real speed: [70, 95, 130][pet.stage] * (scale / 3)
  readonly property int foodPx: 3
  readonly property int foodSize: 14 * foodPx

  screen: {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++)
      if (screens[i].name === pet.roamScreenName) return screens[i]
    return screens.length > 0 ? screens[0] : null
  }
  readonly property var hyprMonitor: Hyprland.monitorFor(win.screen)

  anchors { left: true; right: true; top: true; bottom: true }
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "hyperwyrm"
  mask: Region {
    item: mouse.dragging ? win.contentItem : sprite
    Region { item: p0 }
    Region { item: giftItem }
    Region { item: p1 }
    Region { item: p2 }
    Region { item: p3 }
    Region { item: p4 }
    Region { item: p5 }
    Region { item: f0 }
    Region { item: f1 }
    Region { item: f2 }
    Region { item: f3 }
    Region { item: f4 }
    Region { item: f5 }
    Region { item: f6 }
    Region { item: f7 }
  }

  // --- world -----------------------------------------------------------------
  readonly property real minX: 0
  readonly property real maxX: Math.max(0, width - spriteW)
  readonly property real minY: 0
  readonly property real maxY: Math.max(0, height - spriteH)
  readonly property real floorY: Math.max(0, height - footOffset)
  readonly property real curlY: Math.max(0, height - curlOffset)
  readonly property var floorSurface: ({ x1: 0, x2: width, y: height, address: "" })

  // Window tops the dragon can stand on: {x1, x2, y, address}.
  property var platforms: []
  property var support: null            // null = floor

  function rebuildPlatforms() {
    var list = []
    if (hyprMonitor) {
      var ws = hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : -1
      var tl = Hyprland.toplevels.values
      for (var i = 0; i < tl.length; i++) {
        var t = tl[i], ipc = t.lastIpcObject
        if (!ipc || !ipc.at || !ipc.size) continue
        if (!t.workspace || t.workspace.id !== ws) continue
        if (ipc.hidden === true || ipc.mapped === false || ipc.fullscreen) continue
        var y = ipc.at[1] - hyprMonitor.y
        var x1 = Math.max(0, ipc.at[0] - hyprMonitor.x)
        var x2 = Math.min(width, ipc.at[0] - hyprMonitor.x + ipc.size[0])
        if (y < footOffset + 8 || y > floorY - 12 || x2 - x1 < spriteW) continue
        list.push({ x1: x1, x2: x2, y: y, address: t.address })
      }
    }
    platforms = list
    if (support && !flying && pet.roamEnabled && action !== "jump" && action !== "fall" && action !== "held" && action !== "curl") {
      for (var k = 0; k < list.length; k++) {
        if (list[k].address === support.address) {
          support = list[k]
          posY = support.y - footOffset
          if (posX + spriteW * 0.5 < support.x1 || posX + spriteW * 0.5 > support.x2) startFall()
          return
        }
      }
      startFall()
    }
  }

  Connections {
    target: Hyprland
    enabled: win.visible
    function onRawEvent(event) {
      var n = event.name
      if (n === "openwindow" || n === "closewindow" || n === "movewindow" || n === "movewindowv2"
          || n === "workspace" || n === "workspacev2" || n === "fullscreen" || n === "changefloatingmode"
          || n === "moveworkspace" || n === "activewindow")
        platformRefresh.restart()
    }
  }
  Timer { id: platformRefresh; interval: 250; onTriggered: { Hyprland.refreshToplevels(); platformApply.restart() } }
  Timer { id: platformApply; interval: 120; onTriggered: win.rebuildPlatforms() }

  // --- state -----------------------------------------------------------------
  property real posX: 200
  property real posY: 200
  property int dir: 1
  // sit | walk | fly | jump | fall | eat | curl | held
  property string action: "sit"
  property real targetX: 0            // desired velocity, px/s
  property real targetY: 0
  property real velX: 0
  property real velY: 0
  property int frame: 0
  property real frameT: 0
  property double lastMs: 0
  property real vy: 0
  property double holdUntil: 0
  property int zStep: 0
  // jump arc
  property real jx0: 0
  property real jy0: 0
  property real jx1: 0
  property real jy1: 0
  property real jt: 0
  property real jdur: 1
  property real jarc: 80
  property var jsupport: null
  // eating
  property int eatFid: -1
  property string eatKind: ""
  property double eatEnd: 0
  // play
  property real curX: -1
  property real curY: -1
  property real wobX: 0
  property real wobY: 0
  property double wobAt: 0
  property double lastPounce: 0
  // sulking
  property double snackWaitUntil: 0
  property double nextPuffAt: 0
  property double scootUntil: 0
  property real sulkT: 0
  property bool glanced: false
  // fire breathing (Emperor Dragon)
  property real fireT: 0

  readonly property string anim: action === "curl" ? "curl" : action === "fire" ? "fire"
    : ((action === "walk" || action === "fly" || action === "jump" || action === "fall" || action === "held") ? "walk" : "idle")

  function startFall() { support = null; vy = 0; action = "fall" }

  // Emperor Dragon: hover, lift the head, open wide and breathe a jet of flame.
  function startFire() {
    if (pet.stage < 2 || !pet.roamEnabled || pet.evolving || pet.playing || pet.restPhase !== "") return
    if (action !== "sit" && action !== "walk" && action !== "fly") return
    action = "fire"; fireT = 0; frame = 0; frameT = 0
    velX = 0; velY = 0; targetX = 0; targetY = 0
  }
  Connections { target: win.pet; function onFireBreath() { win.startFire() } }

  // --- food and mess ---------------------------------------------------------
  // Snacks and droppings in the air or on the floor: plain objects
  // {fid, kind, fx, fy, vy, landed, ignored}, at most 8. Reassigned whenever
  // one changes, which re-binds the (few) slots below.
  property var foods: []
  property int foodSeq: 0
  property bool foodsFalling: false
  readonly property int maxFoods: 8

  function setFoods(list) { foods = list; pet.foodOnScreen = list.length }

  function pullFood() {
    var q = pet.takeFood()
    if (q.length === 0) return
    var list = foods.slice()
    for (var i = 0; i < q.length && list.length < maxFoods; i++)
      list.push({ fid: ++foodSeq, kind: q[i].kind, fx: q[i].x, fy: q[i].y, vy: 0, landed: false, ignored: false })
    setFoods(list)
  }
  Connections {
    target: win.pet
    function onFoodQueued() { win.pullFood() }
    function onClearFoodRequested() { win.setFoods([]) }
    function onRoamEnabledChanged() { if (win.pet.roamEnabled && win.visible) win.placeDragon() }
    function onEvolvingChanged() { if (!win.pet.evolving && win.pet.roamEnabled && win.visible) win.placeDragon() }
  }

  function foodIndexOf(fid) {
    for (var i = 0; i < foods.length; i++) if (foods[i].fid === fid) return i
    return -1
  }

  function removeFood(fid) {
    var i = foodIndexOf(fid)
    if (i < 0) return
    var list = foods.slice()
    list.splice(i, 1)
    setFoods(list)
    // Picking up the snack the dragon is heading for or chewing stops that.
    if (action === "eat" && eatFid === fid) { action = "sit"; frame = 0; lastBrainMs = 0 }
  }

  // Gravity for snacks and for droppings; droppings become permanent mess.
  function stepFoods(dt) {
    var falling = false, changed = false
    var landY = height - foodSize / 2 - 2
    var list = foods.slice()
    for (var i = list.length - 1; i >= 0; i--) {
      var it = list[i]
      if (it.landed) continue
      var v = it.vy + 1500 * dt
      var y = it.fy + v * dt
      changed = true
      if (y >= landY) {
        if (it.kind === "poop") {
          var fx = it.fx / Math.max(1, width)
          list.splice(i, 1)
          pet.addPoop(Math.max(0.02, Math.min(0.98, fx)))
          continue
        }
        list[i] = { fid: it.fid, kind: it.kind, fx: it.fx, fy: landY, vy: 0, landed: true, ignored: it.ignored }
      } else {
        list[i] = { fid: it.fid, kind: it.kind, fx: it.fx, fy: y, vy: v, landed: false, ignored: it.ignored }
        falling = true
      }
    }
    if (changed) setFoods(list)
    foodsFalling = falling
  }

  function nearestFood() {
    var best = -1, bd = 1e9, cx = posX + spriteW / 2
    for (var i = 0; i < foods.length; i++) {
      var it = foods[i]
      if (it.kind === "poop" || it.ignored) continue
      var d = Math.abs(it.fx - cx)
      if (d < bd) { bd = d; best = i }
    }
    return best
  }

  function poopsPending() {
    var n = 0
    for (var i = 0; i < foods.length; i++) if (foods[i].kind === "poop") n++
    return n
  }

  function doPoop() {
    if (!pet.roamEnabled || pet.poops.length + poopsPending() >= 6) return
    if (action === "held" || action === "jump" || action === "fall" || action === "curl" || action === "eat") return
    if (foods.length >= maxFoods) return
    var l = foods.slice()
    l.push({ fid: ++foodSeq, kind: "poop", fx: posX + spriteW / 2 - dir * spriteW * 0.3,
             fy: posY + spriteH * 0.62, vy: 0, landed: false, ignored: true })
    setFoods(l)
    holdUntil = Date.now() + 900
  }
  // A digested snack: the dragon stops for a moment and leaves a poop (as soon as it is free to).
  property bool poopWaiting: false
  Connections { target: win.pet; function onPoopDue() { win.poopWaiting = true } }

  // --- happy tricks ----------------------------------------------------------
  // The CfC decides *when*: its jump gate (or rest gate, when sleepy) has to fire
  // before a trick starts. Tricks are pure transforms on the sprite: no extra frames.
  property string trick: ""
  property real trickT: 0
  property real trickDur: 1
  property real trickDx: 0
  property real trickDy: 0
  property real trickRot: 0
  property double nextTrickAt: Date.now() + 25000
  // A trick counts as liked if you pet or reward the dragon within 10 s of it; otherwise it slowly loses favour.
  property string lastTrick: ""
  property double lastTrickEnd: 0
  property bool trickLikedYet: false
  property var lastCtx: ({})
  function judgeTrick() {
    if (lastTrick !== "" && !trickLikedYet) pet.learnTrick(lastTrick, false, lastCtx)
    lastTrick = ""
  }
  Connections {
    target: win.pet
    function onRewarded(kind, amount) {
      if (win.lastTrick === "" || win.trickLikedYet || kind === "clean") return
      var end = win.lastTrickEnd > 0 ? win.lastTrickEnd : Date.now()
      if (Date.now() - end > 10000) return
      win.trickLikedYet = true
      win.pet.learnTrick(win.lastTrick, true, win.lastCtx)
      if (Math.random() < 0.4) win.pet.say(Phrases.pick(["You liked that one! I'll do it more.", "Ooh, a fan! More " + win.lastTrick + "s coming.", "Noted: you like the " + win.lastTrick + "."]))
    }
  }
  function startTrick() {
    var mood = pet.mood
    var pool
    if (mood === "sleepy") pool = ["yawn"]
    else if (mood === "hungry") pool = ["rumble"]
    else if (mood === "playful") pool = flying ? ["zoom", "spin", "loop", "smokering"] : ["zoom", "spin", "smokering"]
    else pool = flying ? ["spin", "loop", "smokering"] : ["spin", "smokering"]
    // Tricks you have reacted to before are picked more often (the learning layer).
    judgeTrick()
    lastCtx = pet.learnCtx((posX + spriteW / 2) / Math.max(1, width))
    trick = Learner.TRICKS.indexOf(pool[0]) >= 0 ? Learner.pickTrick(pet.prefs, pool, lastCtx) : pool[0]
    lastTrick = trick; lastTrickEnd = 0; trickLikedYet = false
    trickT = 0
    trickDur = { spin: 0.9, loop: 1.5, zoom: 3.0, yawn: 2.2, rumble: 1.3, smokering: 2.0 }[trick]
    velX = 0; velY = 0; targetX = 0; targetY = 0
    if (trick === "yawn") pet.say(Phrases.pick(["*yaaaawn*", "*big yawn* ...sorry.", "So sleepy... *yawn*"]))
    else if (trick === "rumble") pet.say(Phrases.pick(["*grrrumble*", "That was my tummy. Not a monster.", "Feed me? Please?"]))
    else if (trick === "smokering") { pet.say(Phrases.pick(["*puff* ...a smoke ring!", "Watch this one.", "I can do rings."])); blowRing() }
    else if (trick === "zoom") pet.say(Phrases.pick(["Zoomies!!", "Can't stop, won't stop!", "Wheee!"]))
  }
  function endTrick() {
    lastTrickEnd = Date.now()
    trick = ""; trickRot = 0; trickDx = 0; trickDy = 0
    nextTrickAt = Date.now() + 25000 + Math.random() * 30000
    action = "sit"; frame = 0; lastBrainMs = 0
    if (!flying) posY = support ? support.y - footOffset : floorY
  }
  function stepTrick(dt) {
    if (pet.unhappy || pet.restPhase !== "" || pet.playing || pet.evolving || pet.gameState === "run" || foods.length > 0) { endTrick(); return }
    trickT += dt
    var t = Math.min(1, trickT / trickDur)
    var ease = t * t * (3 - 2 * t)
    if (trick === "spin") {
      trickRot = 360 * ease * dir
      trickDy = -Math.sin(Math.PI * t) * 46
    } else if (trick === "loop") {
      var R = 70
      trickRot = 360 * t * dir
      trickDx = R * Math.sin(2 * Math.PI * t) * dir
      trickDy = R * (Math.cos(2 * Math.PI * t) - 1)
    } else if (trick === "zoom") {
      var mid = posX + spriteW * 0.5
      posX += dir * speed * 2.6 * dt
      if (flying) posY += Math.sin(trickT * 5) * speed * 0.9 * dt
      if (posX <= minX || posX >= maxX || (!flying && support && (mid < support.x1 + 20 || mid > support.x2 - 20))) dir = -dir
      posX = Math.max(minX, Math.min(maxX, posX)); posY = Math.max(minY, Math.min(maxY, posY))
      action = flying ? "fly" : "walk"; frameT += dt
      if (frameT >= 0.06) { frameT = 0; frame = (frame + 1) % 8 }
    } else if (trick === "smokering") {
      action = "sit"; frame = 0; trickRot = -5 * Math.sin(Math.PI * t) * dir
    } else if (trick === "yawn") {
      trickRot = -7 * Math.sin(Math.PI * t) * dir
      action = "sit"; frame = 0
    } else if (trick === "rumble") {
      trickRot = 3 * Math.sin(trickT * 55)
      action = "sit"; frame = 0
    }
    if (t >= 1) endTrick()
  }
  function maybeTrick(now) {
    if (now < nextTrickAt || pet.unhappy || pet.gameState !== "") return
    if (action !== "sit" && action !== "walk" && action !== "fly") return
    if (foods.length > 0) return
    var gate = pet.mood === "sleepy" ? brainRest : brainJump
    if (gate > 0.3 || now > nextTrickAt + 60000) startTrick()
  }

  // The happy glow (sparkles and hearts) is a short treat: it shows for 90 s when the dragon's
  // happiness climbs past 80%, and returns every 30 minutes for as long as it stays that happy.
  property bool glowing: false
  property real prevJoy: pet.joy
  Timer { id: glowTimer; interval: 90000; onTriggered: win.glowing = false }
  Timer {
    id: sustainTimer
    interval: 1800000
    onTriggered: if (win.pet.joy >= 80) win.startGlow()
  }
  function startGlow() { glowing = true; glowTimer.restart(); sustainTimer.restart() }
  Connections {
    target: win.pet
    function onJoyChanged() {
      var j = win.pet.joy
      if (j >= 80 && win.prevJoy < 80) win.startGlow()
      else if (j < 80) { win.glowing = false; glowTimer.stop(); sustainTimer.stop() }
      win.prevJoy = j
    }
  }

  // --- a full belly: on the last bite it swells like a balloon, then sighs out a big cloud of smoke ---
  property real bloatScale: 1
  property real bloatT: 0
  property bool bloatWaiting: false
  property bool exhaled: false
  Connections { target: win.pet; function onBloat() { win.bloatWaiting = true } }
  function nosePos() {
    var n = Sprites.NOSE[Math.max(0, Math.min(2, pet.stage))]
    return { x: sprite.x + (dir > 0 ? n.x : 32 - n.x) * scale, y: sprite.y + n.y * scale }
  }
  function blowRing() {
    var p = nosePos()
    puffFx.ring(p.x + dir * 18, p.y - 6, dir, 14, pet.stage >= 2 ? ["#fff3a8", "#ffd23f", "#ff9a2e"] : ["#f2f4f8", "#d5dae2", "#b4bcc9"])
  }
  function startBloat() {
    bloatWaiting = false; bloatT = 0; exhaled = false; action = "bloat"; frame = 0
    velX = 0; velY = 0; targetX = 0; targetY = 0
    pet.say(Phrases.pick(["Ooof... so... full...", "One... more... bite... oof.", "I think I'm going to pop."]))
  }
  function stepBloat(dt) {
    bloatT += dt
    var b = bloatT
    if (b < 1.5) { var u = b / 1.5; bloatScale = 1 + 0.34 * u * u * (3 - 2 * u); trickDx = 0 }
    else if (b < 2.1) { bloatScale = 1.34 + 0.015 * Math.sin(b * 60); trickDx = Math.sin(b * 70) * 1.5 }   // trembling
    else if (b < 3.4) {
      trickDx = 0
      bloatScale = 1 + 0.34 * Math.max(0, 1 - (b - 2.1) / 0.7)
      if (!exhaled) { exhaled = true; pet.say(Phrases.pick(["*hhhhhhhhh* ...ahh. Much better.", "*long sigh* ...phew.", "Phew. Room for dessert."])) }
      if (b < 3.0) {
        var p = nosePos()
        puffFx.puff(p.x, p.y, dir, 4, ["#f4f6fa", "#dfe3ea", "#c2c9d6", "#a4adbd"], 2.6)
      }
    } else { bloatScale = 1; trickDx = 0; action = "sit"; frame = 0; lastBrainMs = 0 }
  }

  // --- gifts -----------------------------------------------------------------
  property var gift: null
  Connections {
    target: win.pet
    function onGiftDue() {
      if (!win.pet.roamEnabled || win.gift) return
      var gy = win.flying ? win.height : (win.support ? win.support.y : win.height)
      win.gift = { id: win.pet.pickGiftId(), fx: win.posX + win.spriteW / 2 - win.dir * win.spriteW * 0.5, fy: gy - 26, at: Date.now() }
      giftExpire.restart()
    }
  }
  Timer { id: giftExpire; interval: 240000; onTriggered: win.gift = null }

  // --- cursor (only tracked during a play session) ---------------------------
  Process {
    id: cursorProc
    command: ["bash", "-c", "while :; do hyprctl cursorpos; sleep 0.1; done"]
    running: win.visible && (win.pet.playing || win.pet.gameState === "run")
    stdout: SplitParser {
      onRead: function(line) {
        var m = /(-?\d+),\s*(-?\d+)/.exec(line)
        if (m && win.hyprMonitor) {
          win.curX = Number(m[1]) - win.hyprMonitor.x
          win.curY = Number(m[2]) - win.hyprMonitor.y
        }
      }
    }
    onRunningChanged: if (!running) { win.curX = -1; win.curY = -1 }
  }

  // --- brain ---------------------------------------------------------------
  property var brain: null
  property var brainIn: new Array(15).fill(0)
  property real activity: 0
  property real petted: 0
  property real noise1: 0
  property real noise2: 0
  property double lastBrainMs: 0
  property double lastJumpMs: 0
  property int seenSwitch: 0
  property int seenChat: 0
  property real brainRest: -1
  property real brainJump: -1

  function gauss() {
    return Math.sqrt(-2 * Math.log(Math.random() + 1e-9)) * Math.cos(2 * Math.PI * Math.random())
  }
  function clamp1(v) { return Math.max(-1, Math.min(1, v)) }

  // Centre of the window you are working in, as a fraction of this screen.
  function attention() {
    if (pet.gameState === "run" && curX >= 0) return [curX / Math.max(1, width), curY / Math.max(1, height)]
    var t = Hyprland.activeToplevel
    var ipc = t ? t.lastIpcObject : null
    if (!ipc || !ipc.at || !ipc.size || !hyprMonitor) return null
    var cx = (ipc.at[0] - hyprMonitor.x + ipc.size[0] / 2) / Math.max(1, width)
    var cy = (ipc.at[1] - hyprMonitor.y + ipc.size[1] / 2) / Math.max(1, height)
    return [Math.max(0, Math.min(1, cx)), Math.max(0, Math.min(1, cy))]
  }

  function brainStep() {
    var now = Date.now()
    var dt = lastBrainMs > 0 ? Math.max(0.05, Math.min(0.3, (now - lastBrainMs) / 1000)) : 0.1
    lastBrainMs = now
    if (!brain) brain = Brain.create()

    if (pet.switchCount !== seenSwitch) { seenSwitch = pet.switchCount; activity = Math.min(1, activity + 0.3) }
    activity *= Math.exp(-dt / 15)
    if (pet.chatCount !== seenChat) { seenChat = pet.chatCount; petted = 1 }
    petted *= Math.exp(-dt / 1.5)
    var k = Math.sqrt(dt)
    noise1 = Math.max(-1, Math.min(1, noise1 - noise1 * dt / 2.5 + 0.55 * k * gauss()))
    noise2 = Math.max(-1, Math.min(1, noise2 - noise2 * dt / 2.5 + 0.55 * k * gauss()))

    var cx = posX + spriteW / 2, cy = posY + spriteH / 2
    var px, py, wallx, wally
    if (flying || !support) {
      px = cx / Math.max(1, width); py = cy / Math.max(1, height)
    } else {
      px = (cx - support.x1) / Math.max(1, support.x2 - support.x1); py = 0.5
    }
    if (!flying && !support) { px = cx / Math.max(1, width); py = 0.5 }
    wallx = Math.pow(clamp1((px - 0.5) * 2), 3)
    wally = flying ? Math.pow(clamp1((py - 0.5) * 2), 3) : 0

    var att = attention()
    var awdx = 0, awdy = 0, awnear = 0
    if (att) {
      awdx = clamp1((att[0] - cx / Math.max(1, width)) * 2)
      awdy = clamp1((att[1] - cy / Math.max(1, height)) * 2)
      awnear = Math.max(0, Math.min(1, 1 - Math.sqrt(awdx * awdx + awdy * awdy) / Math.SQRT2))
    }
    var hour = new Date().getHours() + new Date().getMinutes() / 60
    var ang = 2 * Math.PI * hour / 24
    var x = brainIn
    x[0] = 1 - pet.fullness / 100
    x[1] = 1 - pet.energy / 100
    x[2] = pet.joy / 100
    x[3] = Math.sin(ang); x[4] = Math.cos(ang)
    x[5] = activity
    x[6] = awdx; x[7] = awdy; x[8] = awnear
    x[9] = wallx; x[10] = wally
    x[11] = Math.min(1, petted)
    x[12] = noise1; x[13] = noise2
    x[14] = pet.gameState === "run" ? 1 : 0        // tag: the attention target is the cursor, and the trained net runs from it
    var o = Brain.step(brain, x, dt)
    var gm = pet.gameState === "run" ? 1.5 : (pet.mood === "sleepy" ? 0.6 : 1)
    var tvx = o[0] * speed * gm, tvy = flying ? o[1] * speed * gm : 0
    // Learned favourite spot (where you pet it): a gentle pull back towards it, stronger the closer you are.
    if (pet.gameState !== "run") tvx += Learner.spotBias(pet.prefs, posX / Math.max(1, width - spriteW), pet.learnCtx(posX / Math.max(1, width))) * speed * 0.3 * (0.4 + pet.bond / 100)
    brainRest = o[2]; brainJump = o[3]
    if (brainRest > 0.3) { tvx = 0; tvy = 0 }
    targetX = tvx; targetY = tvy
  }

  // --- movement helpers ------------------------------------------------------

  function beginJump(dest, xLeft) {
    jsupport = dest.address === "" ? null : dest
    jx0 = posX; jy0 = posY
    jx1 = Math.max(minX, Math.min(maxX, xLeft))
    jy1 = dest.y - footOffset
    var dist = Math.abs(jx1 - jx0) + Math.abs(jy1 - jy0)
    jdur = Math.max(0.6, Math.min(1.4, dist / 700 + 0.5))
    jarc = 50 + Math.min(160, Math.abs(jy1 - jy0) * 0.5 + 40)
    jt = 0
    dir = jx1 >= jx0 ? 1 : -1
    support = null
    velX = 0; velY = 0
    action = "jump"
  }

  // A short in-place pounce.
  function hop(dx) {
    jsupport = support
    jx0 = posX; jy0 = posY
    jx1 = Math.max(minX, Math.min(maxX, posX + dx)); jy1 = posY
    jdur = 0.45; jarc = 70; jt = 0
    support = null
    action = "jump"
  }

  function trySpontaneousJump() {
    if (flying || action === "jump" || action === "fall" || action === "held") return
    if (brainJump < 0.6 || Date.now() - lastJumpMs < 6000 || (platforms.length === 0 && !support)) return
    lastJumpMs = Date.now()
    var cands = [floorSurface].concat(platforms)
    var dest = cands[Math.floor(Math.random() * cands.length)]
    if (support && dest.address === support.address) return
    if (!support && dest.address === "") return
    beginJump(dest, dest.x1 + Math.random() * (dest.x2 - dest.x1) - spriteW * 0.5)
  }

  function land() {
    support = jsupport
    posX = jx1; posY = jy1
    action = "sit"
    velX = 0; velY = 0
    frame = 0
  }

  // Steer toward a sprite top-left position. Walkers only use x. Returns true
  // once there.
  function steer(tx, ty, spd) {
    var dx = tx - posX
    var dy = flying ? ty - posY : 0
    var dist = Math.sqrt(dx * dx + dy * dy)
    if (dist < 6) { targetX = 0; targetY = 0; return true }
    var s = Math.min(spd, dist * 4)
    targetX = dx / dist * s
    targetY = dy / dist * s
    return false
  }

  function placeDragon() {
    lastMs = 0; lastBrainMs = 0
    velX = 0; velY = 0; targetX = 0; targetY = 0
    support = null
    posX = Math.random() * maxX
    posY = flying ? Math.random() * maxY : floorY
    brain = Brain.create()
    seenSwitch = pet.switchCount; seenChat = pet.chatCount
    action = pet.restPhase === "resting" ? "curl" : "sit"
    if (pet.spawnFx >= 0) {                 // just hatched: appear where the cutscene ended, then drop
      posX = Math.max(minX, Math.min(maxX, pet.spawnFx * width - spriteW / 2))
      posY = Math.max(minY, Math.min(maxY, pet.spawnFy * height - spriteH / 2))
      pet.spawnFx = -1; pet.spawnFy = -1
      if (!flying) startFall()
    }
    Hyprland.refreshToplevels(); platformApply.restart()
  }

  // --- goals: return true when one is in charge of movement ------------------

  function goalRest() {
    if (pet.restPhase !== "going" && pet.restPhase !== "resting") return false
    var fx = pet.favSpotFx
    if (fx < 0) { fx = Math.random() < 0.5 ? 0.07 : 0.93; pet.setFavSpot(fx) }
    var spotX = Math.max(minX, Math.min(maxX, fx * width - spriteW / 2))
    if (!flying && support) { beginJump(floorSurface, spotX); return true }
    if (Math.abs(posX + spriteW / 2 - (spotX + spriteW / 2)) > 1) dir = spotX > posX ? 1 : -1
    if (steer(spotX, curlY, speed)) {
      posX = spotX; posY = curlY
      velX = 0; velY = 0
      action = "curl"; frame = 0; frameT = 0; zStep = 0
      pet.restArrived()
    }
    return true
  }

  function goalFood() {
    if (!pet.canEat) return false
    var i = nearestFood()
    if (i < 0) return false
    if (pet.restPhase !== "" && pet.fullness >= 40) return false
    if (pet.restPhase !== "") pet.cancelRest()
    if (Date.now() < snackWaitUntil) return false          // sulking: it turned the snack down for a few seconds
    var it = foods[i]
    var cx = posX + spriteW / 2, cy = posY + spriteH / 2
    if (!flying && support) { beginJump(floorSurface, it.fx - spriteW / 2); return true }
    if (Math.abs(it.fx - cx) > 4) dir = it.fx > cx ? 1 : -1
    var near = Math.abs(it.fx - cx) < spriteW * 0.28 && (flying ? Math.abs(it.fy - cy) < spriteH * 0.34 : it.landed)
    if (near && pet.unhappy && !pet.snackRefused) {          // "I don't want it!", then it sneaks back for it
      pet.refuseSnack()
      snackWaitUntil = Date.now() + 3500 + Math.random() * 2000
      velX = 0; velY = 0; targetX = 0; targetY = 0
      return true
    }
    if (near) {
      action = "eat"; eatFid = it.fid; eatKind = it.kind; eatEnd = Date.now() + 1300
      velX = 0; velY = 0; targetX = 0; targetY = 0; frame = 0; frameT = 0
      return true
    }
    steer(it.fx - spriteW / 2, it.fy - spriteH / 2, speed * 1.3)
    return true
  }

  function goalPlay(dt) {
    if (!pet.playing || curX < 0) return false
    var now = Date.now()
    if (now > wobAt) { wobAt = now + 900; wobX = (Math.random() - 0.5) * 140; wobY = (Math.random() - 0.5) * 120 }
    var tx = curX - spriteW / 2 + (flying ? wobX : 0)
    var ty = curY - spriteH / 2 + (flying ? wobY : 0)
    if (Math.abs(curX - (posX + spriteW / 2)) > 4) dir = curX > posX + spriteW / 2 ? 1 : -1
    // Walkers on a window top or the floor chase along their surface and pounce.
    if (!flying && Math.abs(curX - (posX + spriteW / 2)) < 90 && now - lastPounce > 1300 && action !== "jump") {
      lastPounce = now
      hop(dir * 60)
      return true
    }
    steer(tx, ty, speed * 1.7)
    return true
  }

  // Tag: the CfC does the running; walkers also hop away when the cursor gets close.
  function goalGame() {
    if (pet.gameState !== "run" || curX < 0) return false
    var now = Date.now()
    if (!flying && action !== "jump" && now - lastPounce > 900 && Math.abs(curX - (posX + spriteW / 2)) < 170) {
      lastPounce = now
      var away = curX > posX + spriteW / 2 ? -1 : 1
      dir = away
      hop(away * 220)
      return true
    }
    return false
  }
  function goalSulk(dt) {
    if (!pet.unhappy) return false
    var att = attention()
    var cx = posX + spriteW / 2, cy = posY + spriteH / 2
    if (!att) { targetX = 0; targetY = 0; return true }
    var ax = cx - att[0] * width, ay = cy - att[1] * height
    var tvx = ax >= 0 ? 1 : -1
    var tvy = 0
    if (flying) {
      var m = Math.max(1, Math.sqrt(ax * ax + ay * ay))
      tvx = ax / m; tvy = ay / m
    }
    tvx *= speed * 0.8; tvy *= speed * 0.8
    var away = tvx >= 0 ? 1 : -1
    dir = away                                     // faces away from you
    // Stops at the screen edge (or window edge) and sulks there.
    if ((tvx < 0 && posX <= minX + 2) || (tvx > 0 && posX >= maxX - 2)) tvx = 0
    if ((tvy < 0 && posY <= minY + 2) || (tvy > 0 && posY >= maxY - 2)) tvy = 0
    if (!flying && support) {
      var mid = posX + spriteW * 0.5
      if ((tvx < 0 && mid < support.x1 + 30) || (tvx > 0 && mid > support.x2 - 30)) tvx = 0
    }
    // Parked in its corner: every few seconds it glances back over its shoulder.
    if (tvx === 0 && tvy === 0) {
      sulkT += dt
      if (sulkT > 8.5) { sulkT = 0; glanced = false }
      if (sulkT > 7.0) {
        dir = -away
        if (!glanced) { glanced = true; if (Math.random() < 0.45) pet.glanceSay() }
      }
    } else { sulkT = 0; glanced = false }
    targetX = tvx; targetY = tvy
    return true
  }

  // Poked while sulking: it spins around and scoots off.
  function scoot() {
    dir = -dir
    scootUntil = Date.now() + 1800
  }
  function goalScoot() {
    if (Date.now() >= scootUntil) return false
    var tvx = dir * speed * 2.4
    if (!flying && support) {
      var mid = posX + spriteW * 0.5
      if ((tvx < 0 && mid < support.x1 + 30) || (tvx > 0 && mid > support.x2 - 30)) tvx = 0
    }
    if ((tvx < 0 && posX <= minX + 2) || (tvx > 0 && posX >= maxX - 2)) tvx = 0
    targetX = tvx; targetY = 0
    return true
  }

  // Grumpy little puffs from the nostril: steam, or (Emperor Dragon) a tiny fire puff.
  function emitPuff() {
    var n = Sprites.NOSE[Math.max(0, Math.min(2, pet.stage))]
    var x = sprite.x + (dir > 0 ? n.x : 32 - n.x) * scale
    var y = sprite.y + n.y * scale
    if (pet.stage >= 2) puffFx.puff(x, y, dir, 6, ["#fff3a8", "#ffd23f", "#ff9a2e", "#d63a24"])
    else puffFx.puff(x, y, dir, 8, ["#f2f4f8", "#d5dae2", "#b4bcc9"])
  }

  // --- tick ------------------------------------------------------------------

  function tick() {
    var now = Date.now()
    var dt = lastMs > 0 ? Math.min(0.1, (now - lastMs) / 1000) : 0.033
    lastMs = now
    stepFoods(dt)
    if (!pet.roamEnabled || pet.evolving) return
    if (action === "held") return
    if (action === "bloat") { stepBloat(dt); return }
    if (trick !== "") { stepTrick(dt); return }

    if (pet.sleeping && pet.restPhase === "") pet.startRest()

    if (action === "jump") {
      jt += dt / jdur
      var t = Math.min(1, jt)
      posX = jx0 + (jx1 - jx0) * t
      posY = jy0 + (jy1 - jy0) * t - jarc * 4 * t * (1 - t)
      frame = 2 + Math.floor(t * 4) % 4
      if (jt >= 1) land()
      return
    }
    if (action === "fall") {
      vy += 1400 * dt
      var ny = posY + vy * dt
      var landY = floorY, landOn = null
      for (var i = 0; i < platforms.length; i++) {
        var p = platforms[i], py = p.y - footOffset
        var cx = posX + spriteW * 0.5
        if (cx >= p.x1 && cx <= p.x2 && posY <= py + 2 && ny >= py && py < landY) { landY = py; landOn = p }
      }
      if (ny >= landY) { posY = landY; support = landOn; vy = 0; action = "sit"; frame = 0; velX = 0; velY = 0 }
      else posY = ny
      frame = 4
      return
    }

    if (action === "curl") {
      if (pet.restPhase !== "resting") {
        action = "sit"; frame = 0; lastBrainMs = 0
        if (!flying) { posY = floorY; support = null }
        return
      }
      frameT += dt
      if (frameT >= 1.0) { frameT = 0; frame = (frame + 1) % 2; zStep = (zStep + 1) % 4 }
      return
    }

    if (action === "eat") {
      frameT += dt
      if (frameT >= 0.15) { frameT = 0; frame = (frame + 1) % 4 }
      if (now >= eatEnd) {
        var idx = foodIndexOf(eatFid)
        if (idx >= 0) {
          removeFood(eatFid)
          if (pet.canEat) pet.eat(eatKind); else pet.sniffFull()
        }
        action = "sit"; frame = 0; lastBrainMs = 0
      }
      return
    }

    if (action === "fire") {
      fireT += dt
      var ft = fireT
      frame = ft < 0.4 ? 0 : (ft < 0.65 ? 1 : (ft < 2.45 ? 2 + (Math.floor(ft * 10) % 2) : (ft < 2.7 ? 1 : 0)))
      var mx = Sprites.FIRE_MOUTH.x, my = Sprites.FIRE_MOUTH.y
      fireFx.dir = dir
      fireFx.ox = sprite.x + (dir > 0 ? mx : 32 - mx) * scale
      fireFx.oy = sprite.y + my * scale
      if (ft >= 3.0) { action = "sit"; frame = 0; lastBrainMs = 0 }
      return
    }

    if (pet.unhappy && now >= nextPuffAt && (action === "sit" || action === "walk" || action === "fly")) {
      if (nextPuffAt > 0) emitPuff()
      nextPuffAt = now + 3500 + Math.random() * 4500
    }
    if (bloatWaiting && (action === "sit" || action === "walk" || action === "fly")) { startBloat(); return }
    if (poopWaiting && (action === "sit" || action === "walk" || action === "fly")) { poopWaiting = false; doPoop() }

    // Who is in charge of the legs/wings this tick?
    var steered = false
    if (now < holdUntil) { targetX = 0; targetY = 0; steered = true }
    else steered = goalScoot() || goalGame() || goalRest() || goalFood() || goalPlay(dt) || goalSulk(dt)
    if (action === "jump" || action === "curl" || action === "eat") return   // a goal just started one

    if (!steered && now - lastBrainMs >= 100) { brainStep(); trySpontaneousJump(); if (!steered) maybeTrick(now); if (trick !== "") return }

    // Smooth toward the desired velocity.
    var k = Math.min(1, dt * 6)
    velX += (targetX - velX) * k
    velY += (targetY - velY) * k
    posX += velX * dt
    posY += velY * dt
    var sp = Math.sqrt(velX * velX + velY * velY)
    if (!steered && Math.abs(velX) > 6) dir = velX > 0 ? 1 : -1
    else if (steered && Math.abs(velX) > 6 && !pet.unhappy) dir = velX > 0 ? 1 : -1

    if (sp > 8) {
      action = flying ? "fly" : "walk"
      frameT += dt
      var period = Math.max(0.06, Math.min(0.24, 0.1 * speed / Math.max(1, sp)))
      if (frameT >= period) { frameT = 0; frame = (frame + 1) % 8 }
    } else {
      action = "sit"
      frameT += dt
      if (frameT >= 0.35) { frameT = 0; frame = (frame + 1) % 4 }
    }
    // Walkers stay on their surface; running off the edge is a fall.
    if (!flying) {
      var mid = posX + spriteW * 0.5
      if (support && (mid < support.x1 || mid > support.x2)) startFall()
      else posY = support ? support.y - footOffset : floorY
    }
    posX = Math.max(minX, Math.min(maxX, posX))
    posY = Math.max(minY, Math.min(maxY, posY))
  }

  readonly property bool moving: action === "walk" || action === "fly" || action === "jump" || action === "fall" || action === "fire" || action === "bloat" || trick !== ""
  Timer {
    interval: (win.moving || win.foodsFalling) ? 33 : ((win.action === "curl" || !win.pet.roamEnabled) ? 1000 : 100)
    repeat: true
    running: win.visible
    onTriggered: win.tick()
  }

  onVisibleChanged: if (visible) {
    pullFood()
    if (pet.roamEnabled) placeDragon()
  }
  onWidthChanged: if (visible && pet.roamEnabled && !flying && action !== "curl") posY = support ? support.y - footOffset : floorY
  onHeightChanged: if (visible && pet.roamEnabled && !flying && !support && action !== "curl") posY = floorY
  Connections {
    target: win.pet
    function onStageChanged() {
      if (!win.visible || !win.pet.roamEnabled) return
      if (win.pet.flies) { win.support = null; win.action = "sit" }
      else win.posY = win.support ? win.support.y - win.footOffset : win.floorY
    }
  }

  // --- visuals ---------------------------------------------------------------
  // Ground shadow: under the feet when standing, on the floor when flying.
  Rectangle {
    visible: win.pet.roamEnabled && win.action !== "held" && win.action !== "curl"
    readonly property real groundY: win.flying ? win.height : (win.support ? win.support.y : win.height)
    readonly property real lift: Math.max(0, groundY - (win.posY + win.footOffset))
    width: win.spriteW * 0.62 * (1 - Math.min(0.5, lift / 900))
    height: 7 * win.scale / 3
    radius: height / 2
    color: "black"
    opacity: 0.28 * (1 - Math.min(0.7, lift / 700))
    x: win.posX + win.spriteW / 2 - width / 2
    y: groundY - height / 2 - 1
  }

  // Snacks and droppings: each slot is one entity. Click one to pick it up.
  component FoodSlot: Item {
    id: fslot
    required property int idx
    readonly property var entry: idx < win.foods.length ? win.foods[idx] : null
    visible: entry !== null
    width: entry ? win.foodSize : 0
    height: entry ? win.foodSize : 0
    x: entry ? entry.fx - win.foodSize / 2 : -300
    y: entry ? entry.fy - win.foodSize / 2 : -300
    FoodSprite { kind: fslot.entry ? fslot.entry.kind : "apple"; px: win.foodPx }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: if (fslot.entry) win.removeFood(fslot.entry.fid)
    }
  }
  FoodSlot { id: f0; idx: 0 }
  FoodSlot { id: f1; idx: 1 }
  FoodSlot { id: f2; idx: 2 }
  FoodSlot { id: f3; idx: 3 }
  FoodSlot { id: f4; idx: 4 }
  FoodSlot { id: f5; idx: 5 }
  FoodSlot { id: f6; idx: 6 }
  FoodSlot { id: f7; idx: 7 }

  // Mess left by an unhappy dragon: click to clean. Six slots at most.
  component PoopSlot: Item {
    id: slot
    required property int idx
    readonly property var entry: idx < win.pet.poops.length ? win.pet.poops[idx] : null
    visible: entry !== null
    width: entry ? win.foodSize : 0
    height: entry ? win.foodSize : 0
    x: entry ? entry.fx * win.width - win.foodSize / 2 : -200
    y: win.height - win.foodSize - 2
    FoodSprite { kind: "poop"; px: win.foodPx }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: if (slot.entry) win.pet.cleanPoop(slot.entry.id)
    }
  }
  PoopSlot { id: p0; idx: 0 }
  PoopSlot { id: p1; idx: 1 }
  PoopSlot { id: p2; idx: 2 }
  PoopSlot { id: p3; idx: 3 }
  PoopSlot { id: p4; idx: 4 }
  PoopSlot { id: p5; idx: 5 }

  DragonSprite {
    id: sprite
    px: win.scale
    stage: win.pet.stage
    colorName: win.pet.colorName
    dull: win.pet.unhappy
    action: win.anim
    frame: win.frame
    mirrored: win.dir === -1
    visible: win.pet.roamEnabled && !win.pet.evolving
    x: (win.pet.roamEnabled && !win.pet.evolving) ? win.posX + win.trickDx : -3000
    y: win.posY + win.trickDy - (win.bloatScale - 1) * win.spriteH / 2
    scale: win.bloatScale
    rotation: win.trickRot
    transformOrigin: Item.Center

    MouseArea {
      id: mouse
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      cursorShape: dragging ? Qt.ClosedHandCursor : Qt.PointingHandCursor
      property bool dragging: false
      property real grabX: 0
      property real grabY: 0

      onPressed: function(e) {
        if (e.button === Qt.RightButton) { win.pet.setRoam(false); return }
        var p = mapToItem(win.contentItem, e.x, e.y)
        grabX = p.x - win.posX
        grabY = p.y - win.posY
        dragging = false
      }
      onPositionChanged: function(e) {
        if (!pressed) return
        var p = mapToItem(win.contentItem, e.x, e.y)
        if (!dragging) {
          if (Math.abs(p.x - grabX - win.posX) < 6 && Math.abs(p.y - grabY - win.posY) < 6) return
          dragging = true
          win.pet.cancelRest()
          win.bloatScale = 1; win.trick = ""; win.trickRot = 0; win.trickDx = 0; win.trickDy = 0      // picking it up ends any trick
          win.action = "held"
          win.support = null
        }
        win.posX = Math.max(win.minX, Math.min(win.maxX, p.x - grabX))
        win.posY = Math.max(win.minY, Math.min(win.maxY, p.y - grabY))
        win.frame = 4
      }
      onReleased: function(e) {
        if (dragging) {
          dragging = false
          win.lastMs = 0
          if (win.flying) { win.action = "sit"; win.velX = 0; win.velY = 0 } else win.startFall()
        } else if (e.button === Qt.LeftButton) {
          if (win.pet.gameState === "offer") win.pet.startGame()
          else if (win.pet.gameState === "run") { win.pet.gameHit(); win.scoot() }
          else { win.pet.chat(); if (win.pet.unhappy) win.scoot(); else win.pet.learnTouch((win.posX + win.spriteW / 2) / Math.max(1, win.width)) }
        }
      }
    }
  }

  Sparkle {
    px: win.scale
    width: win.spriteW; height: win.spriteH
    hearts: win.pet.joy >= 90
    visible: win.glowing && win.pet.roamEnabled && !win.pet.evolving && !win.pet.unhappy && win.pet.joy >= 80
      && (win.pet.mood === "happy" || win.pet.mood === "playful") && win.action !== "curl"
    x: sprite.x; y: sprite.y - win.spriteH * 0.2
  }
  // A gift left on the floor: click to collect the badge.
  Item {
    id: giftItem
    visible: win.gift !== null
    width: win.gift ? 40 : 0
    height: win.gift ? 40 : 0
    x: win.gift ? Math.max(0, Math.min(win.width - 40, win.gift.fx - 20)) : -200
    y: win.gift ? win.gift.fy - 6 : -200
    Gem {
      anchors.centerIn: parent
      px: 4
      kind: win.gift ? win.gift.id : "pebble"
      tint: win.gift ? (Badges.find(win.gift.id) || { color: "#ffd84d" }).color : "#ffd84d"
    }
    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: { if (win.gift) { win.pet.collectGift(win.gift.id); win.gift = null; giftExpire.stop() } }
    }
  }

  // Sulking: a little storm cloud follows it around, and it huffs.
  StormCloud {
    px: win.scale + 1
    visible: win.pet.roamEnabled && win.pet.unhappy && !win.pet.evolving
    x: Math.max(0, Math.min(win.width - width, sprite.x + win.spriteW / 2 - width / 2))
    y: Math.max(0, sprite.y - height * 0.7)
  }
  Puff { id: puffFx; anchors.fill: parent; cell: win.scale * 1.5 }

  FireBreath {
    id: fireFx
    anchors.fill: parent
    cell: win.scale * 2
    active: win.action === "fire" && win.fireT >= 0.65 && win.fireT < 2.45
  }

  // Zzz while curled up (steps once a second, so it costs nothing).
  Repeater {
    model: 3
    delegate: Text {
      required property int index
      visible: win.action === "curl"
      text: index === 2 ? "Z" : "z"
      color: Color.popups.text
      font.family: Style.font.family
      font.bold: true
      font.pixelSize: 11 + index * 5
      opacity: Math.max(0.15, 1 - ((win.zStep + index) % 4) * 0.25)
      x: sprite.x + win.spriteW * 0.66 + index * 12
      y: sprite.y + win.spriteH * 0.30 - ((win.zStep + index) % 4) * 9 - index * 9
    }
  }

  Rectangle {
    id: bubble
    visible: win.pet.speech !== "" && win.pet.roamEnabled && !win.pet.evolving
    color: Color.popups.background
    border.color: Color.popups.border
    border.width: 1
    radius: Style.cornerRadius > 0 ? 8 : 0
    width: Math.min(240, label.implicitWidth + 20)
    height: label.implicitHeight + 14
    x: Math.max(4, Math.min(win.width - width - 4, sprite.x + sprite.width / 2 - width / 2))
    y: Math.max(4, sprite.y - height + 4 - (win.pet.unhappy ? 8 * win.scale : 0))

    Text {
      id: label
      anchors.centerIn: parent
      width: Math.min(220, implicitWidth)
      text: win.pet.speech
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
    }
  }
}
