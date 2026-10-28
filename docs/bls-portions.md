# BLS portions

The BLS 4.0 gives every value per 100 g and no portion sizes. The fork adds
household portions for common foods in
`lib/features/add_meal/data/data_sources/bls_portions.dart` (#158). This file
says where the weights come from. All weights are the edible part, in grams,
or in millilitres for drinks.

## Sources

**USDA FoodData Central, SR Legacy** (household weights of the matching
food, FDC id in brackets):

| Food | Portions |
| --- | --- |
| Banana (173944) | small 101, medium 118, large 136 |
| Apple (171688) | small 149, medium 182, large 223 |
| Pear (167776) | small 152, medium 177, large 227 |
| Orange (169097) | small 96, medium 131, large 184 |
| Tangerine (169105) | small 76, medium 88, large 120 |
| Kiwi (168153) | 69 |
| Peach (169928) | small 130, medium 150, large 175 |
| Nectarine (169914) | small 129, medium 142, large 156 |
| Plum (169949) | 66 |
| Apricot (171697) | 35 |
| Mango (169910) | 336 |
| Avocado (171705) | 201 |
| Lemon (167746) | 58 |
| Tomato (170457) | small 91, medium 123, large 182, cherry 17 |
| Cucumber (168409) | 301 |
| Red pepper (170108), also used for green and yellow | medium 119, large 164 |
| Carrot (170393) | small 50, medium 61, large 72 |
| Onion (170000) | small 70, medium 110, large 150 |
| Garlic (169230) | clove 3 |
| Potato (170026) | small 170, medium 213, large 369 |
| Sweet potato (168482) | 130 |
| Zucchini (169291) | small 118, medium 196, large 323 |
| Eggplant (169228) | 548 |
| Mushroom (169251) | medium 18, large 23 |
| Egg, raw (171287) | medium 44, large 50, extra large 56, jumbo 63 |
| Egg, fried (173423) | large 46 |
| Egg, scrambled (172187) | large 61 |
| Olive oil (171413) | tablespoon 13.5, teaspoon 4.5; used for every oil |
| Butter (173410) | tablespoon 14, teaspoon 5 |
| Sugar (169655) | teaspoon 4.2, tablespoon 12.5, cube 2.3 |
| Honey (169640) | tablespoon 21, teaspoon 7 |
| Jam (169641) | tablespoon 20, teaspoon 7 |
| Peanut butter (172470) | tablespoon 16, teaspoon 5 |
| Hazelnut spread (168000) | tablespoon 18.5 (2 tbsp = 37), teaspoon 6 (a third) |
| Wheat flour (168894) | tablespoon 7.8 (cup 125 / 16) |
| Oats (173904) | tablespoon 5 (cup 81 / 16) |
| Croissant (174987) | small 42, medium 57, large 67 |
| Soft pretzel (169064) | small 62, medium 115, large 143 |
| Rye crispbread (172744) | 11 |
| Granola bar (167542) | 25 |
| Walnuts (170187) | one nut 4 (7 nuts = 28) |
| Frankfurter (173862) | 49 |
| Salami (172936) | slice 12 |
| Ham (173864) | slice 28 |
| Fish stick (174195) | 28 |
| Parmesan, grated (171247) | tablespoon 5 |
| Milk (171265) | tablespoon 15 |
| Rice, cooked | cup 158 |

**Eggs** are sold in the EU size classes by weight in the shell: S under
53 g, M 53–63 g, L 63–73 g, XL 73 g and more. They map onto the USDA classes
of the same shell weight: S to medium (44 g), M to large (50 g), L to extra
large (56 g), XL to jumbo (63 g). Boiled and poached eggs use the same
weights. Fried and scrambled eggs scale with the USDA large egg: fried
46/50, scrambled 61/50 (scrambled egg includes the milk and fat).

**German everyday measures** (Richtwerte, typical pack and serving sizes,
not measured values): a slice of bread 50 g, a slice of toast 25 g, a roll
55 g (wholemeal 60 g), a slice of cheese 25 g, a ball of mozzarella 125 g, a
pack of quark 250 g, a wedge of camembert 31 g (1/8 of 250 g), a pot of
yoghurt 150 g, a bar of chocolate 100 g, a bratwurst 100 g, a chicken breast
fillet 150 g, a salmon fillet 125 g, a glass 200 ml (beer 300 ml), a cup
150 ml, a mug 250 ml, a can 330 ml, a bottle 500 ml (small beer bottle
330 ml).

## Rules

- The first portion of a food is its default: "1 Banane" and a bare count
  like "2 Eier" use it, and the meal detail opens on it.
- Foods measured rather than counted (oils, butter, sugar, honey, jam,
  spreads, flour, oats, grated parmesan, rice) have `counted: false`: they
  open on grams and a bare count is not read as a portion.
- A German label stays short enough for the bulk add's unit dropdown (16
  characters without the count and a trailing bracket); a test checks it.
