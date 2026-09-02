I would not ship this send.

On the clean holdout, the email looks incremental: treated conversion rate 6.38% vs holdout 4.29%, incremental CR 2.08% (95% bootstrap CI 1.28% to 2.88%) on a 4-week window. That is the number I would take to a marketer if the holdout were a holdout.

It is not. In the contaminated file, 15% of users with holdout_flag=1 still have sent=1 — they actually received the email. Holdout CR rises from 4.29% to 4.65% and incremental CR collapses from 2.08% to 1.73% (CI 0.90% to 2.56%). The creative did not get worse. The counterfactual got polluted.

Kill rule: if send rate among holdout_flag=1 is above 1%, stop. Do not scale. Do not retune the agent. Fix suppression and assignment, then rerun. A smaller lift on a dirty holdout is not evidence the campaign should stay on; it is evidence you can no longer measure it. Even on the clean file, most incremental cash sits in cohort 2024-01-01 — I would not turn this into always-on without a replicate on a later cohort.
