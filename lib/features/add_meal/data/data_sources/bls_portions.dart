/// Household portions for common BLS foods (#158), keyed by BLS code.
///
/// The BLS gives every value per 100 g and no portion sizes, so a banana or
/// an egg could only be logged in grams. This table adds the measures people
/// count in: pieces in small/medium/large, eggs in the EU size classes,
/// slices, spoons, glasses and cups. Weights are the edible part, in grams,
/// or in millilitres for a food the app measures in millilitres. Where they
/// come from is listed in `docs/bls-portions.md`. Extend the table when a
/// common food is missing, like the synonyms in `bls_synonyms.dart`.
///
/// The first portion is the default: what "1 Banane" or a bare count means
/// in the bulk add, and the serving the meal detail opens on. A food that is
/// measured rather than counted (oil, sugar, flour) sets
/// [BlsFoodPortions.counted] to false and keeps opening on grams; its spoons
/// are offered but never picked for a bare count.
library;

/// One household measure: a German and an English label, both starting with
/// the count "1 ", and what it weighs.
class BlsPortion {
  final String de;
  final String en;
  final double amount;

  const BlsPortion(this.de, this.en, this.amount);
}

/// The portions of one BLS food, default first.
class BlsFoodPortions {
  final List<BlsPortion> portions;
  final bool counted;

  const BlsFoodPortions(this.portions, {this.counted = true});
}

const _eggs = BlsFoodPortions([
  BlsPortion('1 Ei, mittel (M)', '1 egg, medium (M)', 50),
  BlsPortion('1 Ei, klein (S)', '1 egg, small (S)', 44),
  BlsPortion('1 Ei, groß (L)', '1 egg, large (L)', 56),
  BlsPortion('1 Ei, sehr groß (XL)', '1 egg, very large (XL)', 63),
]);

const _friedEggs = BlsFoodPortions([
  BlsPortion('1 Ei, mittel (M)', '1 egg, medium (M)', 46),
  BlsPortion('1 Ei, klein (S)', '1 egg, small (S)', 40),
  BlsPortion('1 Ei, groß (L)', '1 egg, large (L)', 52),
  BlsPortion('1 Ei, sehr groß (XL)', '1 egg, very large (XL)', 58),
]);

const _scrambledEggs = BlsFoodPortions([
  BlsPortion('1 Ei, mittel (M)', '1 egg, medium (M)', 61),
  BlsPortion('1 Ei, klein (S)', '1 egg, small (S)', 54),
  BlsPortion('1 Ei, groß (L)', '1 egg, large (L)', 68),
  BlsPortion('1 Ei, sehr groß (XL)', '1 egg, very large (XL)', 77),
]);

const _breadSlice = BlsFoodPortions([
  BlsPortion('1 Scheibe', '1 medium slice', 50),
]);

const _potato = BlsFoodPortions([
  BlsPortion('1 Kartoffel', '1 medium potato', 213),
  BlsPortion('1 Kartoffel, klein', '1 small potato', 170),
  BlsPortion('1 Kartoffel, groß', '1 large potato', 369),
]);

const _pepper = BlsFoodPortions([
  BlsPortion('1 Paprika, mittel', '1 medium pepper', 119),
  BlsPortion('1 Paprika, groß', '1 large pepper', 164),
]);

const _cheeseSlice = BlsFoodPortions([BlsPortion('1 Scheibe', '1 slice', 25)]);

const _oil = BlsFoodPortions([
  BlsPortion('1 Esslöffel', '1 tablespoon', 13.5),
  BlsPortion('1 Teelöffel', '1 teaspoon', 4.5),
], counted: false);

const _juice = BlsFoodPortions([BlsPortion('1 Glas', '1 glass', 200)]);

const _hotDrink = BlsFoodPortions([
  BlsPortion('1 Tasse', '1 cup', 150),
  BlsPortion('1 Becher', '1 mug', 250),
]);

const blsPortions = <String, BlsFoodPortions>{
  'F503100': BlsFoodPortions([
    BlsPortion('1 Banane, mittel', '1 medium banana', 118),
    BlsPortion('1 Banane, klein', '1 small banana', 101),
    BlsPortion('1 Banane, groß', '1 large banana', 136),
  ]),
  'F110100': BlsFoodPortions([
    BlsPortion('1 Apfel, mittel', '1 medium apple', 182),
    BlsPortion('1 Apfel, klein', '1 small apple', 149),
    BlsPortion('1 Apfel, groß', '1 large apple', 223),
  ]),
  'F130100': BlsFoodPortions([
    BlsPortion('1 Birne, mittel', '1 medium pear', 177),
    BlsPortion('1 Birne, klein', '1 small pear', 152),
    BlsPortion('1 Birne, groß', '1 large pear', 227),
  ]),
  'F603100': BlsFoodPortions([
    BlsPortion('1 Orange, mittel', '1 medium orange', 131),
    BlsPortion('1 Orange, klein', '1 small orange', 96),
    BlsPortion('1 Orange, groß', '1 large orange', 184),
  ]),
  'F606100': BlsFoodPortions([
    BlsPortion('1 Mandarine', '1 medium mandarin', 88),
    BlsPortion('1 Mandarine, klein', '1 small mandarin', 76),
    BlsPortion('1 Mandarine, groß', '1 large mandarin', 120),
  ]),
  'F514100': BlsFoodPortions([BlsPortion('1 Kiwi', '1 kiwi', 69)]),
  'F203100': BlsFoodPortions([
    BlsPortion('1 Pfirsich, mittel', '1 medium peach', 150),
    BlsPortion('1 Pfirsich, klein', '1 small peach', 130),
    BlsPortion('1 Pfirsich, groß', '1 large peach', 175),
  ]),
  'F202100': BlsFoodPortions([
    BlsPortion('1 Nektarine', '1 medium nectarine', 142),
    BlsPortion('1 Nektarine, klein', '1 small nectarine', 129),
    BlsPortion('1 Nektarine, groß', '1 large nectarine', 156),
  ]),
  'F220100': BlsFoodPortions([BlsPortion('1 Pflaume', '1 plum', 66)]),
  'F201100': BlsFoodPortions([BlsPortion('1 Aprikose', '1 apricot', 35)]),
  'F516100': BlsFoodPortions([BlsPortion('1 Mango', '1 mango', 336)]),
  'F502100': BlsFoodPortions([BlsPortion('1 Avocado', '1 avocado', 201)]),
  'F601100': BlsFoodPortions([BlsPortion('1 Zitrone', '1 lemon', 58)]),
  'G561100': BlsFoodPortions([
    BlsPortion('1 Tomate, mittel', '1 medium tomato', 123),
    BlsPortion('1 Tomate, klein', '1 small tomato', 91),
    BlsPortion('1 Tomate, groß', '1 large tomato', 182),
    BlsPortion('1 Kirschtomate', '1 cherry tomato', 17),
  ]),
  'G520100': BlsFoodPortions([BlsPortion('1 Gurke', '1 cucumber', 301)]),
  'G543100': _pepper,
  'G541100': _pepper,
  'G542100': _pepper,
  'G620100': BlsFoodPortions([
    BlsPortion('1 Karotte, mittel', '1 medium carrot', 61),
    BlsPortion('1 Karotte, klein', '1 small carrot', 50),
    BlsPortion('1 Karotte, groß', '1 large carrot', 72),
  ]),
  'G480100': BlsFoodPortions([
    BlsPortion('1 Zwiebel, mittel', '1 medium onion', 110),
    BlsPortion('1 Zwiebel, klein', '1 small onion', 70),
    BlsPortion('1 Zwiebel, groß', '1 large onion', 150),
  ]),
  'G490100': BlsFoodPortions([BlsPortion('1 Zehe', '1 clove', 3)]),
  'K110100': _potato,
  'K120100': _potato,
  'K420100': BlsFoodPortions([
    BlsPortion('1 Süßkartoffel', '1 sweet potato', 130),
  ]),
  'G582100': BlsFoodPortions([
    BlsPortion('1 Zucchini, mittel', '1 medium zucchini', 196),
    BlsPortion('1 Zucchini, klein', '1 small zucchini', 118),
    BlsPortion('1 Zucchini, groß', '1 large zucchini', 323),
  ]),
  'G510100': BlsFoodPortions([BlsPortion('1 Aubergine', '1 eggplant', 548)]),
  'K701100': BlsFoodPortions([
    BlsPortion('1 Champignon', '1 medium mushroom', 18),
    BlsPortion('1 Champignon, groß', '1 large mushroom', 23),
  ]),
  'E111100': _eggs,
  'E111132': _eggs,
  'E107122': _eggs,
  'Y740162': _eggs,
  'Y740342': _eggs,
  'Y740842': _eggs,
  'E111182': _friedEggs,
  'Y710142': _friedEggs,
  'Y710162': _friedEggs,
  'Y720143': _scrambledEggs,
  'Y720163': _scrambledEggs,
  'B251000': _breadSlice,
  'B271000': _breadSlice,
  'B221000': _breadSlice,
  'B101000': _breadSlice,
  'B254000': BlsFoodPortions([BlsPortion('1 Scheibe', '1 slice', 25)]),
  'B511000': BlsFoodPortions([BlsPortion('1 Brötchen', '1 roll', 55)]),
  'B401000': BlsFoodPortions([BlsPortion('1 Brötchen', '1 roll', 60)]),
  'D771600': BlsFoodPortions([
    BlsPortion('1 Croissant', '1 medium croissant', 57),
    BlsPortion('1 Croissant, klein', '1 small croissant', 42),
    BlsPortion('1 Croissant, groß', '1 large croissant', 67),
  ]),
  'X061410': BlsFoodPortions([
    BlsPortion('1 Brezel', '1 medium pretzel', 115),
    BlsPortion('1 Brezel, klein', '1 small pretzel', 62),
    BlsPortion('1 Brezel, groß', '1 large pretzel', 143),
  ]),
  'B6A2000': BlsFoodPortions([BlsPortion('1 Scheibe', '1 crispbread', 11)]),
  'M111300': BlsFoodPortions([
    BlsPortion('1 Glas', '1 glass', 200),
    BlsPortion('1 Esslöffel', '1 tablespoon', 15),
  ]),
  'M141300': BlsFoodPortions([BlsPortion('1 Becher', '1 pot', 150)]),
  'M713100': BlsFoodPortions([BlsPortion('1 Packung', '1 pack', 250)]),
  'M402600': _cheeseSlice,
  'M304600': _cheeseSlice,
  'M032100': BlsFoodPortions([BlsPortion('1 Kugel', '1 ball', 125)]),
  'M602600': BlsFoodPortions([BlsPortion('1 Ecke (1/8)', '1 wedge', 31)]),
  'M306400': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon, grated', 5),
  ], counted: false),
  'Q630000': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 14),
    BlsPortion('1 Teelöffel', '1 teaspoon', 5),
  ], counted: false),
  'S120000': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 21),
    BlsPortion('1 Teelöffel', '1 teaspoon', 7),
  ], counted: false),
  'S132000': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 20),
    BlsPortion('1 Teelöffel', '1 teaspoon', 7),
  ], counted: false),
  'S145000': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 18.5),
    BlsPortion('1 Teelöffel', '1 teaspoon', 6),
  ], counted: false),
  'H880200': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 16),
    BlsPortion('1 Teelöffel', '1 teaspoon', 5),
  ], counted: false),
  'Q120000': _oil,
  'Q180000': _oil,
  'Q320000': _oil,
  'Q550000': _oil,
  'S111000': BlsFoodPortions([
    BlsPortion('1 Teelöffel', '1 teaspoon', 4.2),
    BlsPortion('1 Esslöffel', '1 tablespoon', 12.5),
    BlsPortion('1 Würfelzucker', '1 sugar cube', 2.3),
  ], counted: false),
  'C214100': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 7.8),
  ], counted: false),
  'C133000': BlsFoodPortions([
    BlsPortion('1 Esslöffel', '1 tablespoon', 5),
  ], counted: false),
  'S830000': BlsFoodPortions([BlsPortion('1 Riegel', '1 bar', 25)]),
  'S530000': BlsFoodPortions([BlsPortion('1 Tafel', '1 bar', 100)]),
  'H120100': BlsFoodPortions([BlsPortion('1 Walnuss', '1 walnut', 4)]),
  'W211200': BlsFoodPortions([BlsPortion('1 Würstchen', '1 sausage', 49)]),
  'W222600': BlsFoodPortions([BlsPortion('1 Bratwurst', '1 sausage', 100)]),
  'W140000': BlsFoodPortions([BlsPortion('1 Scheibe', '1 slice', 12)]),
  'W424000': BlsFoodPortions([BlsPortion('1 Scheibe', '1 slice', 28)]),
  'T930100': BlsFoodPortions([BlsPortion('1 Fischstäbchen', '1 stick', 28)]),
  'V416100': BlsFoodPortions([BlsPortion('1 Brustfilet', '1 fillet', 150)]),
  'T410100': BlsFoodPortions([BlsPortion('1 Filet', '1 fillet', 125)]),
  'X820162': BlsFoodPortions([
    BlsPortion('1 Tasse', '1 cup', 158),
  ], counted: false),
  'F603600': _juice,
  'F110600': _juice,
  'N330000': BlsFoodPortions([
    BlsPortion('1 Glas', '1 glass', 200),
    BlsPortion('1 Dose', '1 can', 330),
    BlsPortion('1 Flasche', '1 bottle', 500),
  ]),
  'P163000': BlsFoodPortions([
    BlsPortion('1 Flasche', '1 bottle', 500),
    BlsPortion('1 kleine Flasche', '1 small bottle', 330),
    BlsPortion('1 Glas', '1 glass', 300),
  ]),
  'P2A3000': BlsFoodPortions([BlsPortion('1 Glas', '1 glass', 200)]),
  'N410100': _hotDrink,
  'N630000': _hotDrink,
};
