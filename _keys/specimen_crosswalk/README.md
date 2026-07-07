# Fossil specimen crosswalk (cross-paper)

Cross-links fossil specimens shared between papers in this dataset, so the same
individual can be matched across independent studies. This lives in `_keys/`
(not inside any one paper's folder) because it is a cross-paper harmonisation key,
analogous to `_keys/Stephan/species_key.csv` but at the **specimen** level.

## Files

| File | Contents |
|---|---|
| `fossil_specimen_crosswalk.csv` | Long form (one row per paper × specimen): `canonical_specimen`, `source_publication`, `printed_name`, `taxon_code`, `taxon`, `item_reference`, `match`, `note`. |
| `fossil_specimen_cerebellum_comparison.csv` | The one genuinely comparable quantity (cerebellar volume, cc) for the shared specimens, with Kochiyama/Weaver ratio and difference. |

## How the matching was done

1. **Resolve aliases before matching** — the important case is **Gibraltar 1 =
   Forbes' Quarry 1** (one skull, two names). Weaver prints "Gibraltar/Forbes Quarry";
   Kochiyama prints "Forbes' Quarry 1". Also format variants: Weaver "La Chapelle I"
   = Kochiyama "La Chapelle-aux-Saints 1"; Weaver "La Ferrassie I" = "La Ferrassie 1";
   Weaver "Cro-Magnon" = "Cro-Magnon 1".
2. **One canonical name per specimen**; each paper's printed name kept as the alias.
3. **Align only comparable measures.** Both report cerebellar **volume in cc** →
   compared. Weaver's brain **mass (g)** and Kochiyama's cerebral **volume (cc)** are
   different physical quantities and are *not* aligned (kept side-by-side for context).
4. **Taxonomy agrees** across both: Weaver's "12-LAH" (Late Archaic Homo) = Kochiyama
   NT (Neanderthal); Weaver "13-EMH" (Early Modern Homo, Cro-Magnon) = Kochiyama EH.

## Overlap

- **Shared (4):** La Chapelle-aux-Saints 1, La Ferrassie 1, Gibraltar 1 / Forbes'
  Quarry 1, Cro-Magnon 1.
- **Kochiyama-only (4):** Amud 1, Qafzeh 9, Skhul 5, Mladeč 1 (not in Weaver A-15).
- Weaver A-11 (extant hominoid MRIs) has **no** fossil overlap.

## Key finding (why this matters for combining the papers)

For the 4 shared specimens, Kochiyama's cerebellar volumes are **systematically ~30%
larger** than Weaver's (ratio mean 1.30, range 1.18–1.40). Yet for **modern humans**
the two agree almost exactly (Kochiyama MH 140.65 cc vs Weaver recent-human MRI
140.5 cc). The difference is **method-dependent**: Kochiyama reconstructs the actual
cerebellum (GM+WM) by deforming MRI brains onto the endocast, whereas Weaver measures
cerebellar volume from 3D virtual endocast models. So even "cerebellar volume in cc"
is **not interchangeable across these two papers for fossils** — the crosswalk makes
that explicit and is the correct place to record such offsets before any merge.

## Provenance

Kochiyama values: `Kochiyama_etal_2018_FossilSpecimensText.csv`. Weaver values:
`Weaver__2001_TableA-15` (verified extraction). Update the Weaver figures here if the
Weaver build is committed to the repo.
