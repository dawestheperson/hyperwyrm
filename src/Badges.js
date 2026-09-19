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
  { id: "tag", name: "Tag Champion", color: "#4fc3f7", how: "Earned by winning a game of tag: click the dragon 4 times in 20 seconds." }
]

function find(id) {
  for (var i = 0; i < LIST.length; i++) if (LIST[i].id === id) return LIST[i]
  return null
}
function gifts() { return LIST.filter(function(b) { return b.gift }) }
