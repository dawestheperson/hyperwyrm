.pragma library

// Collectable badges. `gift` ones drop from a happy dragon; the rest are earned.
// `how` is the condition shown when you hover a badge in the panel.
var LIST = [
  { id: "pebble", name: "Shiny Pebble", color: "#9fb3c8", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "ember", name: "Warm Ember", color: "#ff7a3d", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "leaf", name: "Lucky Leaf", color: "#5cc96b", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "shell", name: "Sea Shell", color: "#f0c9b0", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "star", name: "Star Chip", color: "#ffd84d", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "moon", name: "Moon Drop", color: "#b9a7ff", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "coin", name: "Old Coin", color: "#d9a441", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "feather", name: "Sky Feather", color: "#7fd6e8", gift: true, how: "Found as a gift: a happy dragon left it on the floor." },
  { id: "bond25", name: "Friend", color: "#ff8fb1", how: "Earned by growing your bond with the dragon to 25." },
  { id: "bond50", name: "Best Friend", color: "#ff5f8a", how: "Earned by growing your bond with the dragon to 50." },
  { id: "bond100", name: "Soulbound", color: "#ff3d6e", how: "Earned by reaching the maximum bond of 100." },
  { id: "fire", name: "Firebreather", color: "#ff9020", how: "Earned the first time the Emperor Dragon breathes fire, which needs full fullness, happiness and energy." },
  { id: "grand", name: "Emperor Form", color: "#e6c14d", how: "Earned by growing the dragon into an Emperor Dragon." },
  { id: "celestial", name: "Celestial Form", color: "#ff9a4d", how: "Earned by growing the dragon into a Celestial Dragon." },
  { id: "tag", name: "Tag Champion", color: "#4fc3f7", how: "Earned by winning a game of tag: click the dragon 4 times in 20 seconds." }
]

// 8x8 pixel icons. o outline, h highlight, l base colour, m shade, y yellow, w white, k dark, r red,
// L leaf green (the badge colour is used for l).
var ART = {
  "pebble": [
   "..oooo..",
   ".ohhllo.",
   "ohhllllo",
   "ohllllmo",
   ".ollmmo.",
   "..ommo..",
   "...oo...",
   "........"
  ],
  "ember": [
   "...o....",
   "..olo...",
   ".olylo.o",
   ".olyylo.",
   "oolyyylo",
   "olyyyylo",
   "olllyllo",
   ".ooollo."
  ],
  "leaf": [".....ooo", "...ooLLo", "..oLLhLo", ".oLLhLLo", ".oLhLLo.", "oLhLLoo.", "khLoo...", "ko......"],
  "moon": [
  "..ooo...",
  ".ohhlo..",
  "ohhllo.y",
  "ohllo...",
  "ohllo...",
  "ohhllo..",
  ".ohhlllo",
  "..oooooo"
  ],
  "shell": [
   "..oooo..",
   ".ohhhlo.",
   "ohlhlmlo",
   "olmlhlmo",
   "olmlhlmo",
   ".olmhmlo",
   "..olmlo.",
   "...oo..."
  ],
  "star": [
   "...oo...",
   "..ohlo..",
   "ooohlooo",
   "ohhlllmo",
   ".ohlllo.",
   ".ollmlo.",
   ".olmomlo",
   ".oo..oo."
  ],
  "coin": [
   "..oooo..",
   ".ohllmo.",
   "ohllklmo",
   "olllklmo",
   "olllklmo",
   "ollllmmo",
   ".ommmmo.",
   "..oooo.."
  ],
  "feather": [
   "......oo",
   "....ohho",
   "...ohllo",
   "..ohllmo",
   ".ohllmo.",
   "ohllmo..",
   "kolmo...",
   "ko.oo..."
  ],
  "bond25": [
   "........",
   ".oo..oo.",
   "ohhoolmo",
   "ohhlllmo",
   "ollllmmo",
   ".olllmo.",
   "..olmo..",
   "...oo..."
  ],
  "bond50": [
   ".......w",
   ".oo..oo.",
   "ohhoolmo",
   "ohwlllmo",
   "ollllmmo",
   ".olllmo.",
   "..olmo..",
   "...oo..."
  ],
  "bond100": [
   ".oo..oo.",
   "ohhoolmo",
   "ohhlllmo",
   "oyyyyyyo",
   "ollllmmo",
   ".olllmo.",
   "..olmo..",
   "...oo..."
  ],
  "fire": ["o.o.....", "olloo...", "ollllooy", "olkllyry", "ollllooy", ".olllo..", "..ooo...", "........"],
  "grand": [
   "o..oo..o",
   "olloollo",
   "olllllho",
   "orllllro",
   "ollllllo",
   "oooooooo",
   "........",
   "........"
  ],
  "celestial": [
  "...yy...",
  "..yffy..",
  ".yfeefy.",
  "yfeyyefy",
  "yfeyyefy",
  ".yfeefy.",
  "..yffy..",
  "...yy..."
 ],
 "tag": [
   ".oooooo.",
   "ohllllmo",
   "ohllllmo",
   ".ohllmo.",
   "..olmo..",
   "...oo...",
   "..olmo..",
   ".oooooo."
  ]
}

function find(id) {
  for (var i = 0; i < LIST.length; i++) if (LIST[i].id === id) return LIST[i]
  return null
}
function gifts() { return LIST.filter(function(b) { return b.gift }) }
