# Resolution: DeCasien 2019 `Nomascus_concolor` BV = the Disco / GPZ-5542 gibbon

Addendum to `Disco_gibbon_specimen_note.md`. Resolves the last unmatched DeCasien
datapoint in `DeCasien_Higham_2019/DeCasien_vs_merge_comparison.csv`:

    Nomascus_concolor | BV | Total_brain_net_volume_Vol.mm3 | 115800 | refs 56;57
    status=decasien_only | flag=decasien_only_no_comparable_source

## Finding
This is not a missing source. It is a within-DeCasien duplication of the single
specimen **Disco (3/97) / GPZ-5542**, entered under two genus labels.

DeCasien MOESM3 (Brain Region Data) contains BOTH:
- Hylobates_lar  BV 115800  (ref 60 = de Sousa et al. 2010)
- Nomascus_concolor BV 115800 (ref 56;57 = Barger 2007, 2014)
Same number, same animal.

## 115800 = Disco, published as *Hylobates lar* in three primary sources
- de Sousa et al. 2010, Table 1: `Hylobates lar, Disco 3/97, Zilles, 120 g, 115.8 cm3`  (= 115800 mm3; DeCasien ref 60)
- MacLeod et al. 2003, Table 2: `Hylobates lar (Disco 3/97), F, 115.8`                    (DeCasien ref 61)
- Zilles Collection (INM-1) specimen list: `Hylobates lar ... 3/97 whole brain`, beside `Hylobates lar f YN 81/146`
  -> direct provenance for de Sousa 2010 publishing Disco as H. lar.

## Where the *Nomascus concolor* label entered
- Barger 2007 Table 1 (as printed): generic "Gibbon" header over Disco + YN81-146, no binomial.
- Barger 2014: maps Disco's L-hemisphere values -> *Nomascus concolor*; YN81-146 -> *Hylobates lar*.
- DeCasien took the *Nomascus concolor* label (Barger 2014) + Barger citations, but filled BV from
  the de Sousa/MacLeod *Hylobates lar* measurement of the same animal.
- Companion cell: DeCasien Nomascus_concolor Amygdala 637 = Disco total amygdaloid complex
  0.270+0.367 cc (Barger 2007 "Gibbon"/H. lar row).

## Corpus-internal caution
`Barger_etal_2007_Table1.csv` ReadMe applies a blanket `Gibbon -> Hylobates lar` rule; row 12 reads
`Hylobates lar, Disco`. For Disco this is the exact silent GIBBON->H. lar conversion the specimen
note warns against, and it conflicts with Barger 2014's own *N. concolor* assignment. Studbook points
to *N. leucogenys*. Net: one individual, four labels (GIBBON, H. lar, N. concolor, N. leucogenys).

## Recommended comparison-CSV action
Reclassify the row rather than adding a *Nomascus* record:
- flag: decasien_duplicate_of_Hylobates_lar_Disco
- matched_source: deSousa_etal_2010_Table1 ; matched_value 115800 ; pct_diff 0 (cross-genus)
- specimen link: MacLeod__2000 GPZ-5542 ; see Disco_gibbon_specimen_note.md

## Sources checked (this addendum)
- DeCasien_Higham_2019/41559_2019_969_MOESM3_ESM.xlsx, sheet "Brain Region Data (mm3)"
- deSousa_etal_2010/deSousa_etal_2010_Table1.csv
- MacLeod_etal_2003/MacLeod_etal_2003_Table2.csv
- ____Collections and Specimen notes/Structural and functional organisation of the brain (INM-1)/Zilles_Collection.pdf
- Barger_etal_2007/Barger_etal_2007_Table1_snapshot.csv (+ .csv, ReadMe)
- DeCasien_Higham_2019/annotation_findings.md (Class D)

---

# Companion cell: `Nomascus_concolor` Amygdala 637 (same duplication)

DeCasien's second *Nomascus concolor* cell is the same Disco specimen, same mechanism.

## Trace
- DeCasien `Nomascus_concolor` Amygdala = **637** = Disco bilateral amygdaloid complex,
  Barger 2007 Table 1: L 0.270 + R 0.367 = 0.637 cc -> 637 mm3.
- The merge holds this under *Hylobates lar* (specimen source `Barger2007_specimen`, Disco),
  so a genus-restricted match cannot reach it from *Nomascus* -- identical to the BV cell.
- Parallel *Hylobates lar* Amygdala cell (DeCasien) = **407** = YN81-146 (0.203+0.204 cc) ->
  matches `Barger2007_specimen` at 0%. So DeCasien's two "gibbon" amygdala values are just
  Barger 2014's two-way relabel of the one Barger 2007 "Gibbon" pair: Disco->N. concolor,
  YN81-146->H. lar.

## Why the old 18% "mismatch" was spurious
The comparison had matched 637 against `Barger2014_specimen` *Nomascus concolor* = **540**
(mismatch_pct 17.96). But 540 is the SAME Disco animal: Barger 2014 reports only the LEFT
hemisphere (0.27 cc) and the merge doubles it (0.27 x 2000 = 540). Disco is markedly
asymmetric (L 0.270 vs R 0.367), so left-doubling understates the true bilateral 637.
The 18% gap is L-doubled-estimate vs true L+R of one specimen, not a species difference.

## Action applied to DeCasien_vs_merge_comparison.csv
Both *Nomascus concolor* Disco cells reclassified:
- status  = decasien_duplicate_of_Hylobates_lar_Disco
- flag    = decasien_duplicate_specimen_cross_genus
- BV:  matched_source deSousa_etal_2010_Table1, matched_value 115800, pct_diff 0
- Amy: matched_source Barger2007_specimen,      matched_value 637,    pct_diff 0
       (mismatch_source/value/pct kept as audit trail: Barger2014 L-doubled 540, 18%)

## Note: two unrelated decasien_only rows remain (NOT Disco)
After this fix the only remaining `decasien_only` cells are Bush & Allman 2004 (refs 54;55)
neocortex cells with no crosswalked counterpart: Cheirogaleus_medius Neocortex(GM) 890,
Mandrillus_sphinx Neocortex(GM+WM) 99260. Separate issue from the Disco specimen.
