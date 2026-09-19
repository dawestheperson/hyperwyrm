.pragma library

// Collectable badges. `gift` ones drop from a happy dragon; the rest are earned.
var LIST = [
  { id: "pebble",  name: "Shiny Pebble",  color: "#9fb3c8", gift: true },
  { id: "ember",   name: "Warm Ember",    color: "#ff7a3d", gift: true },
  { id: "leaf",    name: "Lucky Leaf",    color: "#5cc96b", gift: true },
  { id: "shell",   name: "Sea Shell",     color: "#f0c9b0", gift: true },
  { id: "star",    name: "Star Chip",     color: "#ffd84d", gift: true },
  { id: "moon",    name: "Moon Drop",     color: "#b9a7ff", gift: true },
  { id: "coin",    name: "Old Coin",      color: "#d9a441", gift: true },
  { id: "feather", name: "Sky Feather",   color: "#7fd6e8", gift: true },
  { id: "bond25",  name: "Friend (bond 25)",       color: "#ff8fb1" },
  { id: "bond50",  name: "Best Friend (bond 50)",  color: "#ff5f8a" },
  { id: "bond100", name: "Soulbound (bond 100)",   color: "#ff3d6e" },
  { id: "fire",    name: "Firebreather",  color: "#ff9020" },
  { id: "grand",   name: "Emperor Form",    color: "#e6c14d" },
  { id: "tag",     name: "Tag Champion",  color: "#4fc3f7" }
]

function find(id) {
  for (var i = 0; i < LIST.length; i++) if (LIST[i].id === id) return LIST[i]
  return null
}
function gifts() { return LIST.filter(function(b) { return b.gift }) }
