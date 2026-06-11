# Stephan, Bauchot & Andy 1970 - Tables 1-6 (Insectivores & Primates)  [DRAFT - verify]
Stephan H, Bauchot R, Andy OJ (1970). *Data on Size of the Brain and of Various Brain Parts in
Insectivores and Primates.* In: C.R. Noback & W. Montagna (eds), The Primate Brain
(Advances in Primatology, vol. 1), Appleton-Century-Crofts, New York, pp. 289-297.
This is **DeCasien & Higham 2019 reference 51**.

## Two different "Stephan 1970" papers - do not confuse
- THIS folder = the **Insectivores & Primates** brain-size paper (Stephan, Bauchot & Andy 1970).
- `../____Brain_structure_volumes/Stephan-1970-Volumetric Compariso.pdf` is a DIFFERENT paper,
  **Stephan & Pirlot 1970, "Volumetric Comparisons of Brain Structures in Bats"** - not this one.

## What is here
- `stephan_etal_1970.pdf` - the correct source PDF (Insectivores & Primates).
- `Stephan_etal_1970_p1..p6_Table.png` - 300-dpi renders of Tables 1-6. **Use these to verify** - the
  PDF text layer and the figshare-style xlsx are both corrupted OCR and were NOT usable for extraction.
- `Stephan_etal_1970_Tables1-3_snapshot_DRAFT.csv` - body weight (g), brain weight (mg), total brain
  NET volume, and the 5 fundamental sections (Medulla, Cerebellum, Mesencephalon, Diencephalon,
  Telencephalon), mm3. Tables 1/2/3 = Insectivores/Prosimians/Simians.
- `Stephan_etal_1970_Tables4-6_snapshot_DRAFT.csv` - the 7 telencephalon COMPONENTS (Bulbus
  olfactorius, Palaeocortex+NA, Septum, Striatum, Schizocortex, Hippocampus, Neocortex), mm3.
- `Stephan_etal_1970.R` -> `Stephan_etal_1970_Tables1-6.csv`/`.tsv` (clean, all 63 species x 15 vars).
- `Stephan_etal_1970_definitions.csv`, `Stephan_etal_1970_Tables1-6_standardized_terms.READY.csv`.
- `Stephan_etal_1970_rawtext_DRAFT.txt` - the corrupted OCR text (kept only to show why it was not used).

## DRAFT status - needs a verification pass
Values were transcribed from the legible page images, but per the build convention they are a DRAFT
until checked against the PDF. A cross-check against the existing merge (later Stephan tables) is very
reassuring - several cells are EXACT (e.g. Homo telencephalon 1,063,398 vs merge 1,063,399; Nycticebus
coucang medulla/cerebellum/telencephalon all exact; Macaca telencephalon 71,080 exact) and the rest are
within ~1-2% (expected, since the merge uses the more recent Stephan remeasurements).
- **Flagged cell**: `Saguinus oedipus` total brain printed ambiguously; entered as **9576** (a net
  volume must be < the 10,000 mg brain weight, so the "10,576"-looking render was read as 9,576).
  Verify against the PDF.
- **Tables 4-6 now transcribed** (the 7 telencephalon components). Strong internal check: the 7
  components sum to the Tables 1-3 Telencephalon total to **max 0.35%, median 0.006% (0 species >1%)**
  across all 63 species - independently validating both transcriptions (the residual is source rounding).
- **Palaeocortex+NA caveat**: column 10 is Palaeocortex PLUS the amygdala (NA), which the 1970 study
  could not separate. It is mapped to a distinct `Palaeocortex_plus_amygdala_Vol.mm3` term and must NOT
  be merged with the later Stephan `Palaeocortex_Vol.mm3` (which excludes amygdala).

## Why it is NOT in the merge yet (and its expected impact)
Merging is gated on the verification pass (per the project plan). Note also that within the
Tier-1 `Stephan_collection` rule the merge keeps the **most recent** value per (species x structure),
so 1970 (the oldest) is **superseded by 1981/1982/1984/1987** wherever they overlap; body/brain mass
also defer to Stephan 1981. So 1970's net contribution to the merged output is limited to species or
structures the later tables do not cover. It is still valuable as the original provenance and for the
DeCasien ref-51 crosswalk.

## To activate after verification
1. Verify both `..._snapshot_DRAFT.csv` files against the page images / PDF; rename to
   `..._Tables1-3_snapshot.csv` / `..._Tables4-6_snapshot.csv` and point `Stephan_etal_1970.R` at them.
2. Move `Stephan_etal_1970_Tables1-6_standardized_terms.READY.csv` to
   `__merging_volumes/standardized_term_by_reference/Stephan_etal_1970_Tables1-6_standardized_terms.csv`.
3. In `__merging_volumes/volumes_compiled.R`:
   - add to `papers`:  `"Stephan_etal_1970_Tables1-6", "Stephan_collection", 1970, "Stephan1970", "species"`
   - add `enc_override["Stephan_etal_1970_Tables1-6"] = "Stephan_etal_1970_Tables1-6"`
     (and write the clean TSV to `__Public/comparative-data/Stephan_etal_1970_Tables1-6.tsv`),
     or register a `__ReadMe.xlsx` row.
   - decide whether to keep `Palaeocortex_plus_amygdala_Vol.mm3` distinct (recommended) or split it.
4. Add a `Stephan1970` token to `_keys/Stephan/species_key.csv` for the names that need reconciling
   (e.g. Gorilla gorilla -> Gorilla sp., Cebus sp., Aotes trivirgatus -> Aotus trivirgatus, etc.).
5. Re-run `standardized_term.R` then `volumes_compiled.R`; confirm counts and check `volumes_flags.csv`.

Pipeline: Source identified -> Snapshot DRAFT (transcribed) -> cross-checked vs merge (excellent) -> user verification (pending) -> activate in merge.
