.pragma library

// 14x14 8-bit pixel art for the food shelf and the mess a neglected dragon leaves.
// `fill` is how much fullness a piece restores; `joy` is its happiness bonus.
var M = 14
var KINDS = ["apple", "cookie", "fish", "meat", "cake"]
var INFO = {
  apple:  { label: "Apple",  fill: 15, joy: 4 },
  cookie: { label: "Cookie", fill: 10, joy: 10 },
  fish:   { label: "Fish",   fill: 25, joy: 6 },
  meat:   { label: "Meat",   fill: 30, joy: 5 },
  cake:   { label: "Cake",   fill: 20, joy: 14 },
}
var PAL = {
  k: "#2b1d1a", r: "#e0483c", R: "#a8281f", h: "#ffffff", B: "#5c3a1a", K: "#3c2410", g: "#4caf50",
  t: "#d9a066", b: "#8a5a2b", u: "#5aa9e6", U: "#2f6ea3", w: "#ffffff", c: "#fff2d0", p: "#f48fb1",
}
var ART = {
  apple: [
    ".......kk.....",
    "......kBBkk...",
    ".....kkBgggk..",
    "...kkrrBRggk..",
    "..krrrrrrrRk..",
    ".krrhhrrrrrRk.",
    ".krrhhrrrrrRk.",
    ".krrrrrrrrrRk.",
    ".krrrrrrrrrRk.",
    ".krrrrrrrrrRk.",
    ".kRrrrrrrrrRk.",
    "..kRrrrrrrRk..",
    "...kRRRRRRk...",
    "....kkkkkk...."
  ],
  cookie: [
    "..............",
    "....kkkkkk....",
    "...ktttttbk...",
    "..ktttttBtbk..",
    ".kttttttBttbk.",
    ".ktttBtttBtbk.",
    "ktttttttttttbk",
    "kbttttttttttbk",
    ".ktttttBtttbk.",
    ".kbtBtttttBbk.",
    "..kbttttttbk..",
    "...kbbbbbbk...",
    "....kkkkkk....",
    ".............."
  ],
  fish: [
    "..............",
    "......k.......",
    ".....kUk......",
    "...kkUUUkk....",
    "..kuuuuuuUk.k.",
    ".kuwuuuuuuUkUk",
    "kuukuuuuuuuUUk",
    "kUuwwwwwwuuUUk",
    ".kwwwwwwwwUkUk",
    "..kUwwwwUUk.k.",
    "...kkkkkkk....",
    "..............",
    "..............",
    ".............."
  ],
  meat: [
    "..............",
    ".......kkkk...",
    ".....kkBBBKk..",
    "....kBBBBBBKk.",
    "...kBBbbbbBBKk",
    "...kBBbbbbBBKk",
    "...kBBBBBBBBKk",
    "...kKBBBBBBBKk",
    "....kBBBBBBKk.",
    ".kkkcccKKKKk..",
    "kcccckkkkkk...",
    "kccck.........",
    "kccck.........",
    ".kcck........."
  ],
  cake: [
    ".......k......",
    "......kBk.....",
    ".....krrk.....",
    ".....krrk..kk.",
    ".....krrkkkppk",
    "...kkkkppppppk",
    ".kkppppppppppk",
    "kppppppppccctk",
    "kppppccccccctk",
    "kccccccccccctk",
    "kbbbbbbbbbbbbk",
    "kbbbbbbbbbbbbk",
    ".kkkkkkkkkkkk.",
    ".............."
  ],
  poop: [
    "....k.....k...",
    "...kgk...kgk..",
    "....kgkkkgk...",
    "...kgkkBkkgk..",
    "....kbbbBkk...",
    "...kbbbbbBk...",
    "...kbbbbbBk...",
    "..kbbbbbbbBk..",
    "..kbbbbbbbBk..",
    "..kbbbbbbbBk..",
    ".kbbbkbbbkbBk.",
    ".kBbbbbbbbbBk.",
    "..kBBBBBBBBk..",
    "...kkkkkkkk..."
  ]
}
