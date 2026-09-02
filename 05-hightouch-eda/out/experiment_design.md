# SAMPLE: Hightouch 90-minute experiment design

One page for the live experiment-design screen. Not a model card. Not a reward-function rewrite.

## Goal

Decide whether an always-on email should keep sending, pause, or only fire with a promo. The unit is the **user**. Treatment is “eligible to receive this email under the send-volume cap.” The counterfactual is a persistent holdout that **does not receive the email**. We are not optimizing opens, clicks, or last-click attributed revenue.

## Success metric

Primary: **incremental conversion rate (ITT)** over a **4-week window** after `cohort_week` — `CR(holdout_flag=0) − CR(holdout_flag=1)`, with a 95% interval (Wilson on each arm; bootstrap on the difference).

Secondary: incremental **revenue per user** on the same window (cash, not ESP-attributed).

Not success: send volume itself, reachability rate, or a model score. Those are **constraints and diagnostics**.

Ship if: pre-registered MDE is cleared, the holdout is clean (`sent | holdout_flag=1` ≤ 1%), and the lift is not a single-cohort accident. Otherwise hold or kill.

## Features and constraints (send volume, reachability)

**Reachability.** A user with no valid address, a suppression, or a bounce cannot be treated. They stay in the ITT denominator. Do not drop them and then call the remainder a randomized experiment. If treated sent-rate is 70–90% because of reachability plus a cap, that is expected; if holdout sent-rate is not ~0%, the experiment is over.

**Send volume.** ESP and fatigue caps mean some treated-and-reachable users are not sent. That is still ITT: the policy you can actually run. TOT / compiler (“among sent”) is a follow-up, not the decision metric, and it is the first number a leaky holdout will fake.

**Channel.** This SAMPLE is email only. If SMS or push share the same offer, say so in the design or you will read spillover as email lift.

**Assignment.** User-level, persistent for the window. Do not re-randomize mid-window. Do not let the agent “explore” into the holdout.

## If lift is concentrated in one cohort

Do **not** nationalize always-on.

1. Name the week (promo, deliverability, list pull, seasonality). Check whether that cohort’s offer or audience differs.
2. Pre-register a **replicate** on a later cohort with the same MDE, holdout share, and send cap. Same creative, no promo — or promo in both arms.
3. If the lift is a promo interaction, ship **only with the promo**, not as a weekly drip.
4. If one cohort is 40%+ of incremental cash, treat the rest of the calendar as uninformed. More send volume on the quiet weeks is not a strategy; it is burning reachability.

## Kill rule (say this out loud)

If `P(sent=1 | holdout_flag=1) > 1%`, stop the read. The holdout is contaminated. You cannot salvage it with a covariate model. Fix assignment/suppression, then rerun. A smaller ITT on the dirty file is not “the creative is weak.”
