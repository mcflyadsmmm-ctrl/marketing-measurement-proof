# SAMPLE: Robyn vs Meridian — one budget decision

Public SAMPLE only. Meta Robyn `dt_simulated_weekly` and Google Meridian `national_media` are **different simulated worlds**. They are not McFly client runs. They are not Black Clover or Nutricost. No ROI from those desks belongs here.

**Status (1 Sep 2026 evening):** both runners wrote artifacts. Laptop timebox, not production.

| Library | What ran | What it wants |
|---|---|---|
| Robyn 3.12.1 | Nevergrad 200×1, solID `1_174_1`, holdout MAPE **13.06%** | Cut **OOH −30%**. Scale facebook_I and print to the **+50%** cap. Search **+44%**. TV **+15%**. |
| Meridian 1.8.0 | MCMC 2 chains × 100 draws on vendored `national_media.csv` | Scale **Channel2 +30%** (posterior mean ROI **1.22**). Scale Channel0 +16% (ROI **1.00**). Cut Channel1 −13% (ROI **0.77**). Cut **Channel3 −24%** (biggest spend, weakest posterior ROI **0.72**). |

Google’s sample names channels `Channel0`–`Channel3`. I will not rename them Facebook/TV to make the tables look comparable.

---

## Do they want money in the same channel?

**No — and they cannot.** These are not the same mix, not the same weeks, not the same KPI grain (Robyn revenue on `dt_simulated_weekly`; Meridian conversions × revenue_per_conversion on `national_media`). Mapping facebook_I to Channel2 would be a lie.

Inside Meridian, the fight is identified: **Channel3 is the high-spend, low-posterior-ROI cell.** Allocator wants −24% there and +30% on Channel2.

Inside Robyn, the fight is identified: **OOH is the cut.** Allocator hits the −30% floor. Facebook and print hit the +50% cap because Nevergrad thinks they are still on the steep part of the Hill.

I will not average those two stories. I will not spend either recommendation on a disputed cell until a geo ATT on cash sales excludes zero.

---

## Which side I pick

**GeoLift (`01-geolift`) wins.** This SAMPLE recovered **+9.8%** vs an injected **+8%** on cash sales (Milwaukee / Orlando / Saint Paul, ATT 1192, p=0.034). The 90% CI covers 8% and is wide. That is still identified incrementality. National MMM coefficients are not.

**On this Meridian SAMPLE:** freeze **Channel3**. Biggest share of spend (~31%), posterior mean ROI 0.72 (95% interval still includes values below a 1.0 hurdle). Do not give `BudgetOptimizer` that cell.

**On this Robyn SAMPLE:** the OOH cut is an Allocator output, not a geo. Freeze OOH at **current** until a geo (or a clean national pause) says cash moved. Facebook/print hitting the cap is a constraint artifact of a 200×1 search, not permission to scale a W-2 brand.

**Holdout MAPE 13.06%** is a veto check on a laptop mix. It is not a budget. Meridian’s 2×100 posterior is not Getting Started (10×1000 on GPU). Do not ship either mix.

**Default when they conflict on a high-spend, low-incremental channel:** trust the geo test, freeze that channel’s coefficient in **both** libraries, do not average the two allocators.

---

## Four sentences for a CFO

1. Do not average two MMMs that were fit on two different SAMPLE worlds.
2. Meridian wants money out of Channel3 (ROI 0.72) into Channel2 (ROI 1.22). Robyn wants money out of OOH into Facebook and print. Those sentences are not about the same dollars.
3. Holdout MAPE and a short MCMC are vetoes, not spend permission.
4. Spend permission is a geo ATT on cash sales. After that ATT lands, lock that cell and only then let the rest of the mix move.

---

## What geo test settles it

**Design (Project `01-geolift`, Meta GeoLift package data — not invented DMAs):**

- **Question:** On the disputed high-spend / low-incremental channel, is cash sales incremental at the planned spend, or is the MMM fitting base as media?
- **KPI:** cash sales. Not platform ROAS, not conversions the pixel claimed.
- **Markets:** this SAMPLE used Milwaukee / Orlando / Saint Paul, collapsed to one treatment cell because augsynth 0.2.0 cannot fit N>1 treated units. Refuse overlapping media or one market ~40% of sales.
- **Recovery check:** injected **+8%**; recovered **+9.8%**, p=0.034; CI covers 8% and is wide.
- **Decision rule:**
  - CI includes zero → freeze spend; freeze the MMM coefficient on that channel in **both** Robyn and Meridian; do not let Allocator or `BudgetOptimizer` move it.
  - ATT clearly above zero → set that channel’s coefficient / ROI prior to the geo-implied return; re-run allocation with the channel **locked**; throw out the other model’s recommendation on that channel.
  - ATT clearly below zero or CI below the spend hurdle → cut. The geo test overrules the MMM that wanted to scale it.

National TV, always-on brand, and spillover across markets are **not** identified by this geo test. Those stay frozen until the design matches the channel.

---

## What this folder will not say

- It will not say the two libraries “both add value” as a substitute for a pick.
- It will not put SAMPLE Allocator or Meridian ROI onto a W-2 brand.
- It will not imply McFly clients ran Meridian.
- It will not pretend Channel2 is Facebook.
