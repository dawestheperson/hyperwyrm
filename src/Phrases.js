.pragma library

// Window class -> what you are probably doing.
var CATEGORIES = [
  ["terminal", /alacritty|kitty|foot|ghostty|wezterm|xterm|konsole|terminal|st-256/i],
  ["editor",   /code|codium|zed|nvim|neovide|vim|emacs|sublime|jetbrains|idea|pycharm|helix|cursor/i],
  ["browser",  /firefox|chrom|brave|zen|librewolf|vivaldi|opera|qutebrowser|epiphany/i],
  ["chat",     /discord|signal|telegram|slack|element|teams|whatsapp|zoom|thunderbird|geary|mail/i],
  ["music",    /spotify|strawberry|rhythmbox|amberol|lollypop|cider|youtube-music|deadbeef|mpd|ncmpcpp/i],
  ["video",    /mpv|vlc|celluloid|totem|jellyfin|kodi|obs|freetube|haruna/i],
  ["game",     /steam|lutris|heroic|minecraft|prismlauncher|retroarch|wine|proton|gamescope|bottles/i],
  ["files",    /nautilus|thunar|dolphin|nemo|pcmanfm|yazi|ranger|files|spacefm/i],
  ["docs",     /libreoffice|obsidian|okular|zathura|evince|calibre|onlyoffice|typora|logseq|notion|foliate/i],
  ["design",   /gimp|krita|inkscape|blender|figma|aseprite|godot|pinta|darktable|davinci/i],
  ["claude",   /claude/i],
]

function categorize(cls) {
  var c = String(cls || "")
  if (c === "") return "desktop"
  for (var i = 0; i < CATEGORIES.length; i++)
    if (CATEGORIES[i][1].test(c)) return CATEGORIES[i][0]
  return "other"
}

// What it says when you switch to a kind of window.
var BY_CATEGORY = {
  terminal: ["Ooh, the hacker cave.", "Type faster, I'm hungry for output.", "sudo feed dragon?", "Is it compiling? Or burning?", "Careful with rm -rf. I mean it.", "So many tiny letters!", "I'll guard the command line.", "Press enter dramatically."],
  editor:   ["Writing code? I'll guard the semicolons.", "Bugs are just tiny worms. I eat them.", "Ship it!", "Tabs or spaces? I breathe fire on both.", "Don't forget to save.", "That function looks lovely.", "I'll keep watch for typos.", "Refactor? Only if there's a snack after."],
  browser:  ["So many tabs. So many treasures.", "Found anything shiny?", "Ten tabs open? That's a hoard.", "Don't fall down the rabbit hole. Dragons only.", "Research time!", "Ooh, what are we looking up?", "Bookmark the good stuff!", "I'll be quiet while you read."],
  chat:     ["Say hi from me!", "Gossip! I love gossip.", "Reply before it goes cold.", "Somebody's popular today.", "Tell them I said hello.", "Type something nice!", "Ooh, new messages!"],
  music:    ["This one slaps. Roar!", "Turn it up, I can barely hear.", "I can feel the bass in my scales.", "Nice tune.", "My tail is wiggling to the beat.", "Do you take requests?", "La la la roar!"],
  video:    ["Popcorn? I prefer roast knight.", "Movie night!", "Scoot over, I want a seat.", "Ooh, what are we watching?", "No spoilers!", "I'll be very still. Promise."],
  game:     ["Game time! Player two ready.", "Don't rage quit. Rage breathe instead.", "Go for the loot!", "Boss fight? I'll cheer.", "You've got this!", "One more level?", "I believe in your aim."],
  files:    ["Tidying the hoard?", "Delete nothing important, ok?", "So many files. Any of them edible?", "Organizing is dragon-approved.", "Found any treasure in there?", "Folders inside folders inside folders."],
  docs:     ["Reading time. I'll be quiet.", "Words, words, words.", "Take notes, wise one.", "Knowledge is treasure.", "That looks important.", "Shhh, I'm reading over your shoulder."],
  design:   ["Ooh, pretty colors.", "Make me look majestic.", "Art time! Add more sparkle.", "Draw me a bigger cave.", "Can I be in the picture?", "That shade is lovely."],
  claude:   ["I believe in you.", "Good prompt. Good prompt.", "Ask nicely, it works better.", "You've got this.", "Tiny dragon approves of this idea.", "Big brain time!", "Take your time. I'm not going anywhere."],
  desktop:  ["Empty desktop. Cozy.", "Nothing open. Let's nap.", "So quiet.", "Peace and quiet.", "A whole desktop just for me!", "Nothing to do. I like it."],
  other:    ["Whatcha doing?", "Interesting window.", "Carry on, I'm watching.", "New window, who dis?", "Ooh, what's that?", "Don't mind me."],
}

// How it feels. `playful` is when it is rested, fed, happy and wants a game.
var MOOD = {
  hungry:  ["My tummy is rumbling.", "Feed me?", "Snack? Please?", "Hungry hungry dragon.", "I smell apples... do you have apples?", "Is it snack time yet?", "My stomach is making dragon noises.", "Could I have a little something?", "I'd do a trick for a cookie.", "Just a nibble? A tiny one?", "I dreamed about cake."],
  sleepy:  ["So sleepy.", "*yawn*", "Nap time soon?", "My eyes are closing.", "Can I curl up somewhere cozy?", "Five more minutes...", "Zzz... oh! I'm awake. Mostly.", "A tiny nap would be lovely.", "Blankets would be nice right now.", "My wings feel heavy.", "I could sleep for a week."],
  playful: ["Wanna play? Press Play and I'll chase your cursor!", "That little arrow looks so fun... can I chase it?", "I have zoomies. Let me chase your cursor!", "Play with me? I promise not to bite the mouse.", "Cursor chase? Please please please?", "I'm bouncing off the walls!", "Psst... I'm bored. Cursor game?", "My paws are itchy for a chase."],
  happy:   ["Life is good.", "Best. Human. Ever.", "I love it here.", "*happy roar*", "Everything is nice.", "I'm having a lovely day.", "You're my favorite.", "Wiggling with joy!", "I feel like sparkles.", "Thanks for taking care of me."],
  unhappy: ["Leave me alone.", "I'm not talking to you.", "Hmph.", "Nobody cares about me...", "Feed me, then we'll talk.", "I'm grumpy.", "Don't look at me.", "I liked you better when you fed me.", "Some caretaker you are.", "I'm telling the other dragons about this.", "My snack bowl is emptier than your promises.", "I'm not mad. I'm just... hmph.", "Even the cursor is nicer to me.", "Go stare at your other windows.", "I'll forgive you for a cookie. Maybe."],
}

var TIME = {
  night:   ["It's late. Sleep is good for dragons.", "Nocturnal hours, my favorite.", "Go to bed soon?", "The stars are out. Make a wish."],
  morning: ["Good morning!", "Rise and shine, human.", "Coffee first, then code.", "A fresh new day!"],
  evening: ["Good evening.", "Long day, huh?", "Almost dinner time.", "Cozy evening vibes."],
}

var FED = ["Nom nom nom!", "Delicious!", "Thank you!", "Yum yum yum!", "That was perfect.", "More? ...no, I'm full. Maybe.", "You know me so well."]
var FULL = ["I'm stuffed!", "Too full, but thanks.", "Maybe later.", "Not even a nibble. I'm full!"]
var PET = ["Purr... dragons purr too.", "Hee hee!", "Right behind the horns...", "*happy wiggle*", "Do that again!", "That tickles!"]
var RESTED = ["Zzz... ahh, that's better.", "Refreshed!", "That was a good nap.", "I dreamed of flying."]
var EVOLVE = ["I feel different... I'm growing!", "Something is happening!", "Look at me now!", "I'm bigger! Am I bigger?"]

var UNHAPPY = ["That's it. I'm not happy.", "You've been ignoring me!", "I'm going out. Don't follow me.", "Feed me, rest me, or leave me alone!", "I'm sulking. Loudly.", "Fine. I'll just sit here. Alone."]
var GRUMBLE = ["Go away.", "Not now.", "Hmph!", "Don't touch me.", "I'm still mad.", "Talk to the tail.", "*turns away dramatically*", "Nope."]
var NOT_TIRED = ["I'm not tired.", "Maybe later.", "I'm wide awake!"]
var GOING_REST = ["Time for my favorite spot...", "Off to nap.", "Somewhere cozy..."]
var REST_START = ["*curls up* Zzz...", "Nighty night.", "Zzz..."]
var NO_PLAY = ["I'm not in the mood.", "Not until you treat me better.", "Play? After the way you've treated me?"]

// Play = it chases your mouse cursor like a kitten with a laser dot.
var PLAY_START = ["Ooh, a cursor! Must chase!", "That little arrow is MINE!", "Chase time! Don't move too fast!", "Cursor patrol, reporting for duty!", "I'm gonna get that arrow!"]
var PLAY_DURING = ["Gotcha... almost!", "Ha! Missed!", "Come back, little arrow!", "So fast!", "Pounce!", "Wheee!", "Where'd it go?", "I'll catch you!"]
var PLAYED = ["That was so fun!", "Again again!", "I caught it! ...I think.", "Best game ever!", "Phew! I need a snack now.", "Zoom zoom!"]

// The Grand Dragon, when it is happy, says so and then breathes fire.
var FIRE_PRELUDE = ["I'm so happy I could breathe fire!", "I'm happy! Watch this!", "Feeling great... time for fire!", "Happy dragon! Stand back!", "This calls for a little fire!", "I'm so happy! *inhales*"]
var FIRE_AFTER = ["Ta-da!", "Whoosh!", "Hot stuff!", "*proud snort*", "Too much? Sorry!"]

// Mess left on the floor for more than 30 seconds stresses it out.
var STRESS = ["Ew, that's stressing me out! Please clean it!", "Can you clean that? I can't relax.", "Poop alert! Poop alert!", "I can't relax with that lying there.", "Please. The mess. I'm begging."]

// Sulking: turning down the first snack, then giving in; glancing back from the corner.
var REFUSE_FOOD = ["I don't want it!", "Hmph. Not hungry.", "Keep your snack. I'm mad at you.", "No thank you. (Stares at it.)"]
var SNEAK = ["...fine. I guess I'll eat it.", "*sneaky nibble*", "Not because you asked. Because I'm hungry.", "Okay. But I'm still mad."]
var GLANCE = ["*glances back*", "...still mad.", "*sniff*", "Are you still there?", "Hmph."]

var CLEAN = ["Thank you!", "Phew, much better.", "That was gross. Thanks.", "Cleaner already."]
var POOP = ["*plop* That's what snacks do.", "Oops. Nature calls!", "Ta-da! ...sorry.", "Well, that happened.", "Don't look. Okay, look. Then clean it."]
var REFUSE_ROAM = ["I'm not going back in there!", "No. I'm staying out.", "Make it up to me first."]

function pick(list) { return list[Math.floor(Math.random() * list.length)] }

function timeBucket(hour) {
  if (hour < 5 || hour >= 23) return "night"
  if (hour < 11) return "morning"
  if (hour >= 18) return "evening"
  return ""
}

// What to say right now, from its mood, the time and what you are doing.
function contextual(category, mood, hour) {
  var r = Math.random()
  if (mood !== "happy" && r < 0.5) return pick(MOOD[mood] || MOOD.happy)
  var tb = timeBucket(hour)
  if (tb !== "" && r < 0.7) return pick(TIME[tb])
  if (r < 0.85) return pick(BY_CATEGORY[category] || BY_CATEGORY.other)
  return pick(MOOD.happy)
}
