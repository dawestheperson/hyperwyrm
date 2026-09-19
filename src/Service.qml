import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "Phrases.js" as Phrases
import "Foods.js" as Foods
import "Badges.js" as Badges

// Headless dragon brain. Runs once for the whole shell session.
//
// Cost model: one 60 s timer for needs, a 1 s timer only while resting, one
// Hyprland event handler (string compare on "activewindow" only), and a disk
// write on actions or every fifth tick. The roaming overlay owns its own
// animation timer and only runs while visible.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME")
    || ((Quickshell.env("HOME") || "") + "/.local/state")) + "/omarchy"
  readonly property string statePath: stateDir + "/hyperwyrm.json"
  readonly property int maxStateBytes: 65536

  // --- persisted -------------------------------------------------------------
  property string colorName: "red"
  property string petName: "Ember"
  property bool hatched: false
  property real xp: 0
  property real fullness: 60            // 100 = stuffed, 0 = starving
  property real joy: 70                 // shown as Happiness
  property real energy: 80
  property real bond: 0                 // grows with every rewarded interaction
  property bool roamEnabled: false
  property real favSpotFx: -1           // favourite curl-up spot, fraction of screen width
  property var poops: []                // [{id, fx}] mess left on the floor
  property int poopSeq: 0
  property var badges: []               // collected badge ids
  // Tag mini-game: "" | "offer" | "run"
  property string gameState: ""
  property int gameScore: 0
  property int gameLeft: 0
  property double savedAtMs: 0

  // --- derived ---------------------------------------------------------------
  readonly property var stageXp: [0, 100, 300]
  readonly property int stage: xp >= stageXp[2] ? 2 : (xp >= stageXp[1] ? 1 : 0)
  readonly property bool isEgg: !hatched
  readonly property bool maxStage: stage >= 2
  readonly property real stageProgress: maxStage ? 1
    : (xp - stageXp[stage]) / (stageXp[stage + 1] - stageXp[stage])
  readonly property var stageNames: ["Wyrmling", "Wyvern", "Emperor Dragon"]
  readonly property string stageLabel: isEgg ? "Egg" : stageNames[stage]
  // Wyvern and Emperor Dragon fly; the Wyrmling walks on windows and the floor.
  readonly property bool flies: hatched && stage >= 1
  readonly property bool sleeping: hatched && energy < 10
  readonly property bool resting: restPhase !== ""
  readonly property bool asleepNow: hatched && (sleeping || restPhase === "resting")
  readonly property string mood: unhappy ? "unhappy" : (fullness < 25 ? "hungry"
    : (energy < 20 ? "sleepy" : (wantsPlay ? "playful" : "happy")))

  // --- runtime ---------------------------------------------------------------
  property bool initialized: false
  // Hatching cutscene: `hatching` while it plays; `namingPending` from the burst until
  // the dragon has been named (persisted, so a restart resumes at the name box).
  property bool hatching: false
  property bool namingPending: false
  property string hatchScreenName: ""
  // One-shot spawn point (fractions of the screen) for the overlay after hatching.
  property real spawnFx: -1
  property real spawnFy: -1
  property string speech: ""
  property string currentClass: ""
  property string category: "desktop"
  property string roamScreenName: ""
  property double lastSpokeMs: 0
  property int tickCount: 0
  property bool dirty: false
  // Event counters the roaming brain watches (activity and "petted" inputs).
  property int switchCount: 0
  property int chatCount: 0
  // Below 35 happiness it sulks (avoids you, makes a mess); it forgives at 50.
  property bool unhappy: false
  // Sulking rules: it turns down the first snack, then sneaks a bite.
  property bool snackRefused: false
  property bool sneakSaid: false
  // Resting: "" | "going" (walking to its spot) | "resting" (curled up, 60 s).
  property string restPhase: ""
  property double restEndMs: 0
  property int restRemaining: 0
  // Play: a 10-15 s chase-the-mouse session.
  property bool playing: false
  property double lastPlayMs: Date.now()
  // Rested, fed and happy, and it has been a while since the last game.
  property bool wantsPlay: false
  property double nextChatMs: 0
  // Evolution cutscene: the form it came from; the new one is `stage`.
  property bool evolving: false
  property int evolveFrom: 0
  property string evolveScreenName: ""
  // Food dropped on the screen, waiting for the overlay to pick it up.
  property var foodQueue: []
  // Snacks it has eaten and is still digesting: the times at which each one turns into a poop.
  property var pendingPoops: []
  property var stressNoted: ({})
  // How many snacks/droppings are currently in the air or on the floor (set by the overlay).
  property int foodOnScreen: 0

  signal evolved(int newStage)
  signal foodQueued()
  signal poopDue()
  signal fireBreath()
  signal giftDue()
  signal clearFoodRequested()
  // Every interaction it is rewarded for (feed, play, rest, clean). Bond grows
  // with these; this is also the hook for on-device learning.
  signal rewarded(string kind, real amount)

  readonly property string tooltip: {
    if (isEgg) return "Egg"
    var line = petName + " the " + stageLabel + " (" + (isEgg ? "unhatched" : mood) + ")"
    return speech !== "" ? line + "\n\"" + speech + "\"" : line
  }

  function clamp(v) { return Math.max(0, Math.min(100, v)) }

  function say(text) {
    speech = text
    lastSpokeMs = Date.now()
    speechTimer.restart()
  }

  // --- badges, gifts and the tag game ----------------------------------------
  function hasBadge(id) { return badges.indexOf(id) >= 0 }
  function awardBadge(id) {
    var b = Badges.find(id)
    if (!b || hasBadge(id) || !hatched) return false
    badges = badges.concat([id])
    say("New badge: " + b.name + "!")
    markDirty(true)
    return true
  }
  // A gift is picked up from the floor: a new badge, or a coin's worth of affection.
  function collectGift(id) {
    if (!awardBadge(id)) {
      joy = clamp(joy + 2)
      say("I found another one! Keep it safe for me?")
    }
    reward("gift", 2)
    markDirty(false)
  }
  function pickGiftId() {
    var pool = Badges.gifts().filter(function(b) { return !hasBadge(b.id) })
    if (pool.length === 0) pool = Badges.gifts()
    return pool[Math.floor(Math.random() * pool.length)].id
  }
  readonly property bool canGame: hatched && roamEnabled && !unhappy && !evolving && !hatching
    && !playing && !asleepNow && restPhase === "" && gameState === "" && energy >= 30
  function offerGame() {
    if (!canGame) return
    gameState = "offer"
    say("Wanna play tag? Click me!")
    gameOffer.restart()
  }
  function startGame() {
    if (!canGame && gameState !== "offer") return
    gameOffer.stop()
    gameState = "run"; gameScore = 0; gameLeft = 20
    say("Catch me if you can!")
    gameTick.restart()
  }
  function gameHit() {
    if (gameState !== "run") return
    gameScore++
    say(gameScore >= 4 ? "Okay okay, you got me!" : ["Hey!", "Ooh, fast!", "Tag!", "Nice one!"][gameScore % 4])
  }
  function endGame() {
    gameTick.stop()
    if (gameState !== "run") return
    gameState = ""
    energy = clamp(energy - 6)
    if (gameScore >= 4) {
      joy = clamp(joy + 10); reward("game", 6); awardBadge("tag")
      say("You got me! Good game!")
    } else {
      joy = clamp(joy + 3)
      say("Too slow~ Try again later?")
    }
    markDirty(true)
  }

  function reward(kind, amount) {
    bond = Math.min(100, bond + amount * 0.3)
    if (bond >= 25) awardBadge("bond25")
    if (bond >= 50) awardBadge("bond50")
    if (bond >= 99.5) awardBadge("bond100")
    rewarded(kind, amount)
  }

  function beginHatch(screenName) {
    if (hatched || hatching) return
    hatchScreenName = screenName || focusedMonitorName()
    hatching = true
  }
  function cancelHatch() { if (!hatched) hatching = false }
  // The egg bursts: from here on it is a (still unnamed) wyrmling.
  function hatchBurst() {
    if (hatched) return
    hatched = true
    namingPending = true
    markDirty(true)
  }
  // Named: the cutscene hands the dragon to the roaming overlay.
  function finishHatch(name, fx, fy) {
    petName = String(name).substring(0, 16).trim() || "Ember"
    namingPending = false
    hatching = false
    spawnFx = fx; spawnFy = fy
    roamScreenName = hatchScreenName || roamScreenName || focusedMonitorName()
    roamEnabled = true
    say("*crack* Hello, world!")
    markDirty(true)
  }

  function grow(amount) {
    var before = stage
    xp += amount
    if (stage > before && !evolving) {
      evolveFrom = before
      evolveScreenName = roamScreenName || focusedMonitorName()
      evolving = true
      cancelPlay()
      evolved(stage)
    }
  }
  // The cutscene is over: the dragon appears where it ended and carries on.
  function finishEvolve() {
    if (!evolving) return
    evolving = false
    if (stage >= 2) awardBadge("grand")
    if (roamEnabled) { spawnFx = 0.5; spawnFy = 0.5 }
    say(Phrases.pick(Phrases.EVOLVE))
    markDirty(true)
  }

  // --- unhappiness -----------------------------------------------------------

  function updateUnhappy() {
    if (!initialized) return                  // loading a save: no storm-out or notification
    if (!hatched) { unhappy = false; return }
    if (!unhappy && joy < 35) {
      unhappy = true
      snackRefused = false; sneakSaid = false
      cancelPlay()
      say(Phrases.pick(Phrases.UNHAPPY))
      Quickshell.execDetached(["omarchy-notification-send", petName + " is unhappy",
        "Feed it, let it rest or clean up any mess. It will avoid you until it is cheered up."])
      // It storms out of the bar and stays out until it has been cheered up.
      if (!roamEnabled) { roamScreenName = roamScreenName || focusedMonitorName(); roamEnabled = true }
      markDirty(true)
    } else if (unhappy && joy >= 50) {
      unhappy = false
      snackRefused = false; sneakSaid = false
      say("Okay... I feel better.")
      markDirty(true)
    }
  }
  onJoyChanged: updateUnhappy()

  // --- care ------------------------------------------------------------------

  // Foods are dragged from the panel and dropped on the screen (see Panel.qml);
  // the overlay makes them fall, and the dragon walks over and eats them.
  function dropFood(kind, x, y, screenName) {
    if (isEgg || !Foods.INFO[kind]) return
    var q = foodQueue.slice()
    if (q.length >= 5) return
    q.push({ kind: kind, x: x, y: y })
    foodQueue = q
    cancelPlay()
    if (screenName && roamScreenName !== screenName) roamScreenName = screenName
    if (!roamEnabled) roamEnabled = true
    foodQueued()
    if (!canEat) say("I'm too full right now, but I'll save it for later.")
    markDirty(false)
  }
  function clearFood() { foodQueue = []; clearFoodRequested() }
  function takeFood() { var q = foodQueue; foodQueue = []; return q }
  readonly property bool canEat: fullness < 95

  function eat(kind) {
    var f = Foods.INFO[kind]
    if (!f) return
    fullness = clamp(fullness + f.fill)
    joy = clamp(joy + f.joy)
    if (unhappy && snackRefused && !sneakSaid) { sneakSaid = true; say(Phrases.pick(Phrases.SNEAK)) }
    else say(Phrases.pick(Phrases.FED))
    reward("feed", 3 + f.joy * 0.2)
    grow(f.fill * 1.0)          // 1 XP per point of fullness: care is the main way to grow
    pendingPoops = pendingPoops.concat([Date.now() + 60000 + Math.random() * 120000])   // what goes in must come out
    markDirty(true)
  }
  // Unprompted talk, by how it feels: hungry, sleepy, wants to play, happy, or
  // (sometimes) about what you are doing on screen.
  function chatter() {
    nextChatMs = Date.now() + 150000 + Math.random() * 210000
    var hour = new Date().getHours()
    var line
    if (unhappy) line = Phrases.pick(Phrases.MOOD.unhappy)
    else if (fullness < 45) line = Phrases.pick(Phrases.MOOD.hungry)
    else if (energy < 35) line = Phrases.pick(Phrases.MOOD.sleepy)
    else if (wantsPlay && Math.random() < 0.6) line = Phrases.pick(Phrases.MOOD.playful)
    else line = Phrases.contextual(category, "happy", hour)
    say(line)
  }
  // Emperor Dragon only: when everything is full, a happy line, then a jet of fire.
  function tryFire() {
    if (stage < 2 || !roamEnabled || unhappy || evolving || hatching || playing || asleepNow || restPhase !== "") return
    // Only a dragon that is fully fed, fully rested and fully happy (95%+ each).
    if (fullness < 95 || energy < 95 || joy < 95) return
    say(Phrases.pick(Phrases.FIRE_PRELUDE))
    fireDelay.restart()
  }
  // The overlay calls these while it sulks.
  function refuseSnack() { snackRefused = true; say(Phrases.pick(Phrases.REFUSE_FOOD)) }
  function glanceSay() { say(Phrases.pick(Phrases.GLANCE)) }
  function sniffFull() { say(Phrases.pick(Phrases.FULL)) }

  function startRest() {
    if (isEgg || restPhase !== "") return
    if (energy >= 90 && !sleeping) { say(Phrases.pick(Phrases.NOT_TIRED)); return }
    cancelPlay()
    if (roamEnabled) {
      restPhase = "going"
      goingTimer.restart()
      say(Phrases.pick(Phrases.GOING_REST))
    } else {
      beginResting()
    }
  }
  function beginResting() {
    goingTimer.stop()
    restPhase = "resting"
    restEndMs = Date.now() + 60000
    restRemaining = 60
    say(Phrases.pick(Phrases.REST_START))
  }
  // The overlay calls this once the dragon has reached its spot and curled up.
  function restArrived() { if (restPhase === "going") beginResting() }
  function cancelRest() {
    if (restPhase === "") return
    goingTimer.stop()
    restPhase = ""
    markDirty(false)
  }
  function endRest() {
    restPhase = ""
    joy = clamp(joy + 5)
    reward("rest", 3)
    say(Phrases.pick(Phrases.RESTED))
    markDirty(true)
  }
  function setFavSpot(fx) { favSpotFx = fx; markDirty(false) }

  function startPlay() {
    if (isEgg || playing) return
    if (restPhase !== "") return
    if (unhappy) { say(Phrases.pick(Phrases.NO_PLAY)); return }
    if (energy < 15) { say(Phrases.pick(Phrases.MOOD.sleepy)); return }
    if (!roamEnabled) { roamScreenName = roamScreenName || focusedMonitorName(); roamEnabled = true }
    playing = true
    playTimer.interval = 30000 + Math.floor(Math.random() * 15000)
    playTimer.restart()
    say(Phrases.pick(Phrases.PLAY_START))
  }
  function endPlay() {
    if (!playing) return
    playing = false
    lastPlayMs = Date.now()
    wantsPlay = false
    joy = clamp(joy + 30)
    energy = clamp(energy - 12)
    fullness = clamp(fullness - 6)
    say(Phrases.pick(Phrases.PLAYED))
    reward("play", 4)
    grow(6)
    markDirty(true)
  }
  function cancelPlay() { playing = false; playTimer.stop() }

  function addPoop(fx) {
    if (poops.length >= 6) return
    var p = poops.slice()
    p.push({ id: ++poopSeq, fx: fx, at: Date.now() })
    poops = p
    say(Phrases.pick(Phrases.POOP))
    markDirty(true)
  }
  function cleanPoop(id) {
    var p = poops.filter(function(e) { return e.id !== id })
    if (p.length === poops.length) return
    poops = p
    delete stressNoted[id]
    joy = clamp(joy + 2)
    reward("clean", 1.5)
    say(Phrases.pick(Phrases.CLEAN))
    markDirty(true)
  }

  // Poke / pet: a contextual line, or a happy one. Sulking dragons snap.
  function chat() {
    if (isEgg) return
    if (unhappy) { joy = clamp(joy + 0.5); say(Phrases.pick(Phrases.GRUMBLE)); return }
    chatCount++
    joy = clamp(joy + 2)
    reward("pet", 1)
    say(Math.random() < 0.4 ? Phrases.pick(Phrases.PET)
      : Phrases.contextual(category, mood, new Date().getHours()))
    markDirty(false)
  }

  // The color can only be chosen while it is an egg; the name is given at hatching.
  function setColor(c) { if (!isEgg || c === colorName) return; colorName = c; markDirty(true) }

  function setRoam(on, screenName) {
    if (on && isEgg) return
    if (on) roamScreenName = screenName || roamScreenName || focusedMonitorName()
    if (!on) { cancelPlay(); cancelRest() }
    roamEnabled = on
    markDirty(true)
  }

  function newEgg() {
    gameState = ""; gameTick.stop()
    hatched = false; xp = 0; fullness = 60; joy = 70; energy = 80; bond = 0
    unhappy = false; playing = false; restPhase = ""; foodQueue = []; poops = []; pendingPoops = []; stressNoted = ({})
    hatching = false; namingPending = false
    roamEnabled = false; speech = ""
    markDirty(true)
  }

  function focusedMonitorName() {
    var m = Hyprland.focusedMonitor
    return m ? m.name : ""
  }

  function markDirty(saveNow) {
    dirty = true
    if (saveNow) save()
  }

  // --- window awareness ------------------------------------------------------

  function onActiveWindow(data) {
    var cls = String(data).split(",")[0]
    if (cls === currentClass) return
    currentClass = cls
    switchCount++
    var cat = Phrases.categorize(cls)
    if (cat === category) return
    category = cat
    if (!hatched || asleepNow) return
    if (Date.now() - lastSpokeMs < 60000 || Math.random() > 0.5) return
    say(Phrases.contextual(cat, mood, new Date().getHours()))
  }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activewindow") root.onActiveWindow(event.data)
    }
  }

  Timer {
    id: speechTimer
    interval: 8000
    onTriggered: root.speech = ""
  }

  // A stuck walk to its spot must not hang the rest: give up after 45 s.
  Timer { id: goingTimer; interval: 45000; onTriggered: if (root.restPhase === "going") root.beginResting() }
  Timer { id: playTimer; onTriggered: root.endPlay() }
  // Digestion: a snack becomes a poop 1-3 minutes after it was eaten.
  Timer {
    interval: 5000
    repeat: true
    running: root.pendingPoops.length > 0 && root.initialized
    onTriggered: {
      var now = Date.now(), rest = [], due = 0
      for (var i = 0; i < root.pendingPoops.length; i++) {
        if (root.pendingPoops[i] <= now && due === 0) due++
        else rest.push(root.pendingPoops[i])
      }
      root.pendingPoops = rest
      if (due === 0) return
      if (root.roamEnabled && !root.evolving && !root.hatching) root.poopDue()      // the dragon does it, on screen
      else root.addPoop(0.1 + Math.random() * 0.8)                                  // in the bar: it turns up anyway
    }
  }
  // Mess left lying around for over 30 seconds stresses it out: 1 happiness per minute each.
  Timer {
    interval: 10000
    repeat: true
    running: root.poops.length > 0 && root.hatched
    onTriggered: {
      var now = Date.now(), n = 0, fresh = false
      for (var i = 0; i < root.poops.length; i++) {
        var p = root.poops[i]
        if (now - (p.at || now) > 30000) {
          n++
          if (!root.stressNoted[p.id]) { root.stressNoted[p.id] = true; fresh = true }
        }
      }
      if (n > 0) {
        root.joy = root.clamp(root.joy - n / 6)
        if (fresh) root.say(Phrases.pick(Phrases.STRESS))
      }
    }
  }
  Timer { id: fireDelay; interval: 2300; onTriggered: { root.fireBreath(); root.awardBadge("fire"); fireAfter.restart() } }
  Timer { id: gameOffer; interval: 12000; onTriggered: if (root.gameState === "offer") root.gameState = "" }
  Timer {
    id: gameTick; interval: 1000; repeat: true
    onTriggered: { root.gameLeft--; if (root.gameLeft <= 0 || root.unhappy) root.endGame() }
  }
  // A happy dragon now and then leaves a gift on the floor; and sometimes wants to play tag.
  Timer {
    id: giftTimer
    interval: 150000; repeat: true; running: root.initialized && root.roamEnabled
    onTriggered: {
      interval = 240000 + Math.random() * 240000
      if (root.hatched && root.roamEnabled && !root.unhappy && !root.asleepNow && !root.evolving
          && !root.playing && root.gameState === "" && root.joy >= 70) {
        if (Math.random() < 0.4) root.offerGame()
        else { root.giftDue(); root.say("I found something for you!") }
      }
    }
  }
  Timer { id: fireAfter; interval: 3300; onTriggered: root.say(Phrases.pick(Phrases.FIRE_AFTER)) }
  // Every few minutes a happy Emperor Dragon breathes fire.
  Timer {
    interval: 60000          // the first one comes a minute after it starts flying
    repeat: true
    running: root.initialized && root.stage >= 2 && root.roamEnabled && !root.unhappy && !root.evolving && !root.hatching
    onTriggered: { interval = 150000 + Math.floor(Math.random() * 210000); root.tryFire() }
  }
  // A cheer now and then while it chases the cursor.
  Timer {
    interval: 9000
    repeat: true
    running: root.playing
    onTriggered: root.say(Phrases.pick(Phrases.PLAY_DURING))
  }

  // While curled up: +0.5 energy/s, so a 60 s rest restores about 30.
  Timer {
    interval: 1000
    repeat: true
    running: root.restPhase === "resting"
    onTriggered: {
      root.energy = root.clamp(root.energy + 0.5)
      root.joy = root.clamp(root.joy + 0.1)
      root.restRemaining = Math.max(0, Math.ceil((root.restEndMs - Date.now()) / 1000))
      if (Date.now() >= root.restEndMs) root.endRest()
    }
  }

  // Once a minute: needs drift, growth is only ever earned by care. Neglect
  // (hunger, no sleep, mess on the floor) drains happiness faster.
  Timer {
    interval: 60000
    repeat: true
    running: root.initialized && root.hatched
    onTriggered: {
      root.tickCount++
      var restingNow = root.restPhase === "resting"
      root.fullness = root.clamp(root.fullness - (restingNow ? 0.1 : 0.25))
      // A little passive growth while it is well looked after. It stops just short of the
      // next form, so an evolution only ever happens when you feed or play with it.
      if (!restingNow && !root.unhappy && root.fullness >= 50 && root.joy >= 60 && root.energy >= 30 && !root.maxStage)
        root.xp = Math.min(root.stageXp[root.stage + 1] - 0.5, root.xp + 0.05)
      if (!restingNow) {
        root.energy = root.clamp(root.energy - 0.12)
        var drain = 0.15
        if (root.fullness < 40) drain += 0.3
        if (root.energy < 30) drain += 0.3
        drain *= 1 - 0.2 * root.bond / 100          // a strong bond softens the sulking a little
        root.joy = root.clamp(root.joy - drain)
      }
      if (root.energy < 10 && root.restPhase === "") root.startRest()
      root.wantsPlay = !root.unhappy && root.energy >= 50 && root.joy >= 45 && root.fullness >= 40
        && Date.now() - root.lastPlayMs > 900000
      if (!root.asleepNow && !root.evolving && !root.hatching && !root.playing
          && Date.now() >= root.nextChatMs && Date.now() - root.lastSpokeMs > 60000)
        root.chatter()
      if (root.tickCount % 5 === 0) root.dirty = true
      if (root.dirty) root.save()
    }
  }

  // --- persistence -----------------------------------------------------------

  function save() {
    savedAtMs = Date.now()
    stateFile.setText(JSON.stringify({
      version: 3, colorName: colorName, petName: petName,
      hatched: hatched, xp: xp, fullness: fullness, joy: joy, energy: energy,
      bond: bond, namingPending: namingPending, favSpotFx: favSpotFx, poops: poops, poopSeq: poopSeq,
      badges: badges, roamEnabled: roamEnabled, savedAtMs: savedAtMs
    }))
    dirty = false
  }

  function applyLoaded(text) {
    var d = null
    try { d = JSON.parse(text) } catch (e) { d = null }
    if (d && typeof d === "object") {
      var num = function(v, fb) { v = Number(v); return isFinite(v) ? v : fb }
      if (typeof d.colorName === "string") colorName = d.colorName
      if (typeof d.petName === "string") petName = d.petName.substring(0, 16)
      hatched = d.hatched === true
      xp = Math.max(0, num(d.xp, 0))
      fullness = clamp(num(d.fullness, 60))
      joy = clamp(num(d.joy, 70))
      energy = clamp(num(d.energy, 80))
      bond = clamp(num(d.bond, 0))
      favSpotFx = num(d.favSpotFx, -1)
      if (Array.isArray(d.badges)) badges = d.badges.filter(function(b) { return Badges.find(b) }).filter(function(b, i, a) { return a.indexOf(b) === i })
      if (d.namingPending === true && hatched) { namingPending = true; hatching = true; hatchScreenName = focusedMonitorName() }
      poopSeq = Math.max(0, Math.floor(num(d.poopSeq, 0)))
      if (Array.isArray(d.poops))
        poops = d.poops.filter(function(p) { return p && isFinite(Number(p.fx)) }).slice(0, 6)
          .map(function(p) { return { id: Math.floor(num(p.id, 0)), fx: Math.max(0.02, Math.min(0.98, Number(p.fx))), at: Math.min(Date.now(), num(p.at, Date.now())) } })
      roamEnabled = d.roamEnabled === true && hatched
      // Time away is gentler than time at the desk, and never fatal.
      var mins = Math.min(720, Math.max(0, (Date.now() - num(d.savedAtMs, Date.now())) / 60000))
      if (hatched) {
        fullness = Math.max(15, fullness - mins * 0.1)
        joy = Math.max(20, joy - mins * 0.06 * (1 - 0.2 * bond / 100))
        energy = clamp(energy + mins * 0.2)
      }
    }
    initialized = true
    nextChatMs = Date.now() + 120000
    if (hatched && joy < 35) unhappy = true      // already sulking: no fresh storm-out on load
    if (hatched) updateUnhappy()
    if (hatched && unhappy) say(Phrases.pick(Phrases.MOOD.unhappy))
    else if (hatched && mood !== "happy") say(Phrases.pick(Phrases.MOOD[mood]))
    else if (hatched) say("I'm back!")
  }

  Process {
    id: reader
    command: ["head", "-c", String(root.maxStateBytes), root.statePath]
    running: true
    stdout: StdioCollector { id: readerOut }
    onExited: function(exitCode) {
      var t = exitCode === 0 ? readerOut.text : ""
      root.applyLoaded(t.length >= root.maxStateBytes ? "" : t)
    }
  }

  // Write-only: never preloaded or watched.
  FileView {
    id: stateFile
    path: root.statePath
    preload: false
    watchChanges: false
    atomicWrites: true
    printErrors: false
  }

  // Static window bound to visibility (a Loader-created layer surface can
  // survive a plugin hot-reload as a zombie). It also stays up while there is
  // mess on the floor, even with the dragon put away.
  RoamWindow {
    pet: root
    visible: root.initialized && root.hatched && !root.namingPending && (root.roamEnabled || root.poops.length > 0)
  }

  HatchScene {
    pet: root
    visible: root.initialized && (root.hatching || root.namingPending)
  }

  EvolveScene {
    pet: root
    visible: root.initialized && root.evolving
  }
}
