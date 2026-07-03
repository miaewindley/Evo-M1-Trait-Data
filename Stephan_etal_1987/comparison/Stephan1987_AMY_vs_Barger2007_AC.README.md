# Cross-check: Stephan 1987 AMY vs Barger 2007 amygdaloid_complex_total (shared hominoids)

Tests the "amygdaloid complex volume is compatible across these datasets" assumption on the four
species both report. Units reconciled: Barger `amygdaloid_complex_total` (cm³, both hemispheres) × 1000 = mm³.

| species | Stephan'87 AMY (mm³) | Barger'07 amygdaloid_complex_total (mm³) | Barger n | ratio S/B | Δ% |
|---|---|---|---|---|---|
| *Pan troglodytes* | 1421.8 | 1315.0 | 3 | 1.08 | +8% |
| *Hylobates lar* | 666.2 | 522.0 | 2 | 1.28 | +28% |
| *Homo sapiens* | 5286.6 | 3805.0 | 1 | 1.39 | +39% |
| *Gorilla gorilla* | 2752.6 | 1306.0 | 1 | 2.11 | +111% |

## Reading
- **Not directly interchangeable at face value.** Stephan 1987 AMY is systematically *larger* than
  Barger amygdaloid_complex_total — by +8% to +111% (mean ≈ 1.46×).
- **Same hemisphere basis.** The best-sampled species (chimp, Barger n=3) is closest (+8%), which
  implies Stephan AMY is **bilateral** (whole structure), like Barger's both-hemisphere amygdaloid_complex_total — so
  the offset is *not* a unilateral-vs-bilateral factor-of-2.
- **Likely a definitional difference.** Stephan's "amygdala" is defined inclusively (its LAM contains
  the cortical nuclei; the complex extends into periamygdaloid/cortical tissue), whereas Barger's
  modern stereological complex is more restricted. Stephan's human AMY (5.29 cm³) is large vs the
  stereological literature (~2.5–3.8 cm³ bilateral); Barger's (3.81 cm³) sits in range.
- **Single-specimen noise.** Gorilla and human are n=1 on both sides; the 2.1× gorilla gap is the
  least reliable point.

## Implication for the Study-3 merge
The agreed rule is **average the two where they overlap** (Homo, *Pan troglodytes*, *Gorilla gorilla*,
*Hylobates lar*) — `merged_mean_mm3` in the CSV. Given the systematic Stephan>Barger offset, consider
revisiting this before finalizing: options are (a) apply a definitional scaling factor, (b) prefer one
source for hominoids, or (c) keep both and treat the spread as measurement uncertainty. Flagging for
your call — the averaging is implemented as requested but the offset is real.
