# Heffner & Masterton 1975 — Table I (pyramidal tract and digital dexterity)

Heffner R, Masterton B (1975). *Variation in form of the pyramidal tract and its relationship to
digital dexterity.* Brain Behav Evol 12(3):161–200. doi:10.1159/000124401

Full table title (see `__ReadMe.xlsx`): **"Table I"** — animals, pyramidal-tract morphometry and
digital dexterity. 69 animal rows spanning mammals. Superseded by the smaller
Heffner & Masterton 1983 Table I sample (`compare to 1983`).

## Source → Snapshot
PDF is paywalled and Table I runs over several pages. Transcribed by hand (kept to the original
layout) and cross-checked against an AI table extraction of the PDF. Frozen transcription:
`Heffner_Masterton_1975_TableI_snapshot.xlsx`. (`pyramidal_tract_data.xlsx` is a working copy.)
*Recommend a visual diff against the PDF before publication.*

## Data readable
`Heffner_Masterton_1975_TableI.R` → `Heffner_Masterton_1975_TableI.csv` (**use this**). The script
reads the snapshot, makes the headings readable, collapses the stacked value/reference rows into
one row per animal, and parses numbers. Common name is in `Animal`; the binomial is in `Species`.
Columns defined in `reference_tables/Heffner_Masterton_1975_TableI_definitions.csv`.

## Species note
`Species` holds the binomial **as printed**; reconcile to `_keys/Stephan/species_key.csv`
downstream. Several printed spellings are transcription typos and are flagged here rather than
altered in the frozen CSV (fix in a later pass if desired): *Ateleus ater* (→ Ateles),
*Sciurrrus hudsonius* (→ Sciurus/Tamiasciurus), *Elephus maximus* (→ Elephas), *Saquinas oedipus*
(→ Saguinus oedipus), *Tasarida cynocephala* (→ Tadarida), *Cricetus auratus* (→ Mesocricetus),
*Phocaena phocoena* (→ Phocoena), *Spermophillus tridecemlineatus* (→ Spermophilus), *Microsorex
hoyi* (→ Sorex hoyi), *Erinaceous* (→ Erinaceus), *Macaca ira* (→ Macaca irus),
*Horpyiocepalus leucogostra* (Indian tube-nosed bat, spelling uncertain). Several rows are
genus-only (*Myotis*, *Rhinolophus*, *Tarsius*, *Tapirus*, *Camelus*, *Equus*, *Didelphis*,
*Erinaceus*, *Paraechinus*), and a few have **no** species because the paper leaves them
unspecified (bear, cow, deer, mouse, rat) — `Species` is blank for those. Taxonomy is not
modernised.

## Provenance
Secondary compilation: anatomical values are drawn largely from the cited literature (see the
`*_ref` columns); the digital-dexterity rank is Heffner & Masterton's own scale.
Measure: behavioural (digital dexterity) + corticospinal tract morphometry.

Pipeline: Source → Snapshot ✅ → Data readable ✅ → Species note ✅ → Online database ✅
(`10.1159%2F000124401_TableI.tsv` in `__Public/comparative-data/`)
