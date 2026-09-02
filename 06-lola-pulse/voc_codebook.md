# SAMPLE VoC codebook

Synthetic tickets only. This codebook was **not** run on Lola Blankets CX, social, or surveys. Keyword rules, no LLM.

`voc.py` applies these lists to `data/cx_tickets.csv` and **does not read** the hidden `theme` column. That column exists so we can score the codebook against the generator, not to train anything.

## Match order (first hit wins)

1. **shipping** — fulfillment / carrier / delayed delivery
2. **product** — quality, fit, wash, fabric
3. **ads** — paid creative, promo codes, platform ads
4. **other** — residual (no keyword hit)

Shipping wins on mixed tickets on purpose. “The ad promised two-day shipping and the box is still in transit” is a **shipping** problem the site and CX own, not an ads-budget problem. Last-click email does not get a theme; it is not a ticket.

## shipping

Case-insensitive; `voc.py` uses word boundaries.

`delay`, `delayed`, `late`, `tracking`, `tracker`, `carrier`, `transit`, `delivery`, `delivered`, `package`, `parcel`, `shipping`, `warehouse`, `backorder`, `backlog`, `fulfillment`, `usps`, `ups`, `fedex`, `lost`, `never arrived`, `in transit`, `estimated arrival`

Do not put these words in product- or ads-only SAMPLE tickets.

## product

`quality`, `tear`, `torn`, `pilling`, `pill`, `sizing`, `color`, `texture`, `wash`, `washed`, `washing`, `smell`, `odor`, `stitch`, `stitching`, `seam`, `fabric`, `scratchy`, `shedding`, `dye`, `faded`, `thin`, `thinner`

`size` is omitted on purpose (`size` matches “resize the photo”). Use `sizing`.

## ads

`advertisement`, `facebook`, `instagram`, `tiktok`, `retarget`, `retargeting`, `promo code`, `discount code`, `misleading`, `\bad\b`, `\bads\b`, `clicked the ad`

Short tokens `ad` / `ads` are bounded so `address` and `added` do not fire.

## other

No keywords. Gift message, ship-to change, invoice, wholesale, login, press — if it does not hit 1–3, it is `other`.

## Scoring (not a Lola metric)

After tagging, `voc.py` prints accuracy vs the hidden `theme` column. That is a check that this SAMPLE codebook recovers the generator. It is **not** a claim about Lola’s ticket mix.
