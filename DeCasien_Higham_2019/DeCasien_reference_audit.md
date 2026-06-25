# DeCasien reference audit — are we using the correct sources? (2026-06-24)

Two independent checks, because the DeCasien ref list is hard to read (it uses **compound
refs** like `62-63`, where one cell blends two different papers).

## Method A — bibliographic crosswalk
Extracted DeCasien & Higham's own numbered reference list (refs 24–65) from the paper PDF and
mapped each to our merge source. Full table: `DeCasien_reference_audit.csv`.

## Method B — empirical value-match (the rigorous check)
For every ref where we hold a primary table, compared DeCasien's per-species value to our
primary (species mean). **If the numbers are identical, the attribution is correct.**

| ref | region | our primary | result |
|---|---|---|---|
| 62 | Cerebellum | Rilling & Insel 1998 Table1 | **9/9 species exact (0.0%)** ✓ |
| 62 | brain volume (BV) | Rilling & Insel 1998 Table1 | 8/9 exact; Gorilla 3.5% (subspecies subset) ✓ |
| 63 | Neocortex | — (none) | **no local match → confirms a different paper** |
| 64 | brain volume (BV) | Sherwood 2004 TABLEI | Pan & Pongo exact, Gorilla ≤4.5% ✓ |
| 65 | brain volume (BV) | Barks 2014 TABLE1 | Gorilla beringei/gorilla ≤1.1% ✓ |

## Verdict

**Correct and confirmed (14 refs):** 24 Stephan 1981 · 34 Frahm 1984 · 43 Bauernfeind 2013 ·
51 Stephan 1970 · 53 Sherwood 2005 · 54 Bush & Allman 2004 (V1) · 56 Barger 2007 ·
58 Stimpson 2015 · 59 Zilles & Rehkämper 1988 · 60 de Sousa 2010 · 61 MacLeod 2003 ·
62 Rilling & Insel 1998 (cerebellum) · 64 Sherwood 2004 · 65 Barks 2014/2015.

**Issues found — the compound refs:**

1. **Ref 63 = Rilling & Insel *1999* (neocortex), J. Hum. Evol. 37 — a different paper from
   ref 62 (1998, cerebellum).** DeCasien's `62-63` rows put **cerebellum from 1998 and
   neocortex from 1999** in the same row. Our DeCasien-extracted Rilling table had the neocortex
   mislabeled as 1998. The value-match proves it: cerebellum matches the 1998 primary exactly,
   neocortex has no 1998 source. → **Fix:** attribute that neocortex to Rilling & Insel 1999
   (we have no primary for it; it lives only in DeCasien's sheet).

2. **Ref 52 = Stephan, Baron & Frahm 1988** (Comparative Primate Biology Vol. 4): the `51-52`
   data is the Stephan collection, which we already carry via the individual Stephan/Baron/Frahm
   papers. Not a separate table — fine, but note it's *not* "just Stephan 1970".

3. **Ref 55 = Bush & Allman 2004 (frontal scaling, PNAS)** — companion of ref 54 (V1). Our
   frontal volumes come from Smaers 2011, not ref 55. Confirm if you want ref-55 frontal added.

4. **Ref 57 = Barger et al. 2014 (limbic, Front. Hum. Neurosci.)** — companion of ref 56. The
   `56-57` amygdala may blend Barger 2007 & 2014; we carry Barger 2007 only.

5. **Ref 65 Barks** — DeCasien cites the **2015** print (Am. J. Phys. Anthropol. 156:252–262);
   our folder is `Barks_etal_2014` (epub 2014). Same paper, year-label only.

## How to re-run this check
`python3 decasien_ref_audit.py` (in the session outputs) regenerates the value-match and the
crosswalk CSV. Point it at any new primary table to confirm a ref by value.
