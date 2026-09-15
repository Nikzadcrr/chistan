#!/bin/bash
# تولید هنر چیستان — ۱۶ تصویر
ART=/home/z/my-project/chistan/assets/art
mkdir -p "$ART"
S="warm cozy storybook illustration, soft painterly digital art, mobile game art, Dream Games quality, rich warm palette of orange gold green and cream, Iranian atmosphere, no text, no letters, no watermark"

gen() { # نام، سایز، پرامپت
  local name="$1"; local size="$2"; local prompt="$3"
  if [ -s "$ART/$name.png" ]; then echo "موجود: $name"; return; fi
  sleep 25
  echo "تولید: $name ..."
  z-ai image -p "$prompt, $S" -o "$ART/$name.png" -s "$size" && echo "OK: $name" || echo "FAIL: $name"
}

# پدربزرگ (سه حالت — توصیف ثابت برای یکدستی)
G="lovable elderly Iranian grandfather character, full body, round friendly face, big warm gentle smile, white beard and white mustache, bushy white eyebrows, kind sparkling eyes, wearing a traditional beige kolanbarji shirt with a dark brown sleeveless vest (jeligha), brown loose trousers, giveh shoes, holding a small hot glass cup of Iranian tea with steam"
gen grand_welcome  1024x1024 "$G, standing and welcoming with one open hand"
gen grand_celebrate 1024x1024 "$G, both arms raised in joyful celebration, happy closed eyes, little golden stars floating around"
gen grand_think    1024x1024 "$G, thoughtful pose with finger on chin, one eyebrow raised, a glowing lightbulb idea above his head"

# پس‌زمینه‌ها (پرتره موبایل)
gen menu_bg 768x1344 "cozy Iranian traditional teahouse interior at golden hour, wooden tables with patterned termeh carpet, samovar and tea glasses, santur instrument on cushions, string of warm lanterns, orange sunlight through arched orsi window with colorful lattice glass, soft cream ambience"
gen city_shiraz 768x1344 "Shiraz Iran scenery, Hafez tomb pavilion with turquoise tiled columns among orange trees, pink mosque Nasir-ol-Molk arches with rose petals falling, spring orange blossoms, soft pink and warm sky"
gen city_esfahan 768x1344 "Isfahan Iran scenery, grand turquoise dome and half-finished minaret of Naqsh-e Jahan square, Si-o-se-pol bridge arches reflected in Zayandeh river, cream and turquoise palette, warm golden light"
gen city_yazd 768x1344 "Yazd Iran scenery, desert city rooftops with tall badgir windcatcher towers, adobe mud-brick walls, golden desert light, deep blue sky with soft clouds, warm ochre and sand palette"
gen city_tabriz 768x1344 "Tabriz Iran scenery, El Goli pavilion on a hill by a large pool, brick vaulted bazaar corridors with skylights, snowy Sahand mountain in distance, crimson and cream palette, late afternoon light"
gen city_rasht 768x1344 "Rasht Gilan Iran scenery, lush green rice paddies and tall trees, traditional wooden gabled house with red tiled roof, soft mist, orange trees, rainy green atmosphere with warm accents"
gen city_mashhad 768x1344 "Mashhad Iran scenery, golden dome and two golden minarets shining under warm sky, green flag gently waving, white marble courtyard with pilgrims as tiny silhouettes, gold and green palette, serene warm light"

# آیکون بازی
gen icon 1024x1024 "mobile game app icon, rounded square, a circle of golden letter tiles around a glowing gold star, Persian tilework motifs in corners, warm orange to cream gradient background, glossy premium game icon"

# آیکون‌های کوچک UI
gen ic_coin 1024x1024 "single golden game coin icon on plain cream background, embossed Persian star motif, glossy, centered, simple"
gen ic_star 1024x1024 "single golden five-pointed game star icon on plain cream background, glossy rounded, centered, simple"
gen ic_chest 1024x1024 "small ornate wooden treasure chest with gold fittings and Persian patterns, slightly open glowing with golden light, plain cream background, centered, game icon"
gen ic_gift 1024x1024 "gift box wrapped in Persian termeh patterned paper with golden ribbon bow, plain cream background, centered, game icon"
gen ic_trophy 1024x1024 "golden trophy cup with Persian ornamental engraving on cream background, centered, glossy game icon"
echo "تمام شد."
