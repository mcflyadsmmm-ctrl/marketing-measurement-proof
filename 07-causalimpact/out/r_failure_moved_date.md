SAMPLE. Brodersen CausalImpact. Not Python.

Pre-period weeks 1–59. Post-period weeks 60–104.
True DGP: +12% from week 80.
Ship this design? NO.

Average and cumulative effects from CausalImpact$summary:
               Actual       Pred Pred.lower Pred.upper    Pred.sd  AbsEffect
Average      61227.62   57428.25   56591.42   58330.14   444.1499   3799.375
Cumulative 2755243.09 2584271.20 2546613.71 2624856.50 19986.7442 170971.890
           AbsEffect.lower AbsEffect.upper AbsEffect.sd  RelEffect
Average            2897.48        4636.208     444.1499 0.06616688
Cumulative       130386.60      208629.379   19986.7442 0.06616688
           RelEffect.lower RelEffect.upper RelEffect.sd alpha           p
Average          0.0496738      0.08192425  0.008236706  0.05 0.001004016
Cumulative       0.0496738      0.08192425  0.008236706  0.05 0.001004016

Would not ship: moving the intervention date still draws a gap because the real week-80 shock sits inside the mis-dated post window. Lock the week before anyone fits. Cherry-picking the date is not identification.
