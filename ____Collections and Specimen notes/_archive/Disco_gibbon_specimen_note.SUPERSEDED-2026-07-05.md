# Specimen note: Gibbon "Disco" / GPZ-5542

## Summary

The gibbon specimen named **Disco** should be treated as a single biological individual with multiple identifiers and conflicting published taxonomic labels.

The most defensible current interpretation is:

- **Specimen / house name:** Disco
- **MacLeod/Yerkes identifier:** GPZ-5542
- **Studbook ID:** 0050
- **Studbook taxon:** *Nomascus leucogenys* / white-cheeked gibbon
- **Sex:** Female
- **Estimated birth date:** 1972-01-01, estimated to year
- **Death date:** 1994-02-17
- **Relevant institutions:** Baltimore Zoo; Gladys Porter Zoo, Brownsville; Yerkes brain/tissue collection
- **Database handling:** do not treat generic `GIBBON` as *Hylobates lar*. Keep the specimen identity separate from taxonomic labels and preserve all aliases/identifiers.

The database should probably represent this as a specimen-level identity with a taxonomic note rather than silently resolving all mentions to a single published species name.

## Core evidence

### 1. MacLeod Appendix I links Disco to GPZ-5542

In `MacLeod__2000_APPENDIXI.csv`, the row for Disco is:

| Field | Value |
|---|---|
| SPECIMEN | `GIBBON / ZILLES(SEMEND.)` |
| IDENT. NUMBER | `DISCO (3/97) / GPZ-5542` |
| SEX | `F` |
| WEIGHT | `6.8 K.` |
| BRAIN WT. GRAMS | `120` |
| FIXED VOL. CC'S | `53.64` |
| AGE | `22 YRS.` |
| SOURCE | `YERKES` |
| CAUSE OF DEATH | `HEMORRHAGIC ENTERITIS` |
| CUT | `FRONTAL` |
| STAINS MEASURED | `AG` |

This is the direct source tying **Disco** to **GPZ-5542** in the brain dataset. The important detail is that `GPZ-5542` appears on the second line of the same `IDENT. NUMBER` cell as `DISCO (3/97)`, so it is easy to miss if the cell is displayed as a single-line value.

### 2. The white-cheeked gibbon studbook links Disco to BROWNSVIL local ID 5542

The relevant studbook is:

> White-Cheeked Gibbon Studbook, *Nomascus leucogenys*, North American Region Studbook, data current as of 2011-10-25, published 2011-11-01.

The studbook record for **Studbook ID 0050** gives:

| Field | Value |
|---|---|
| Studbook ID | `0050` |
| Birth date | `1/1/1972` |
| Birth date estimate | `Year` |
| Sire | `UNK` |
| Dam | `UNK` |
| Sex | `Female` |
| House name | `DISCO` |
| Transfer | `BALTIMORE`, local ID `72225`, date `7/11/1972` |
| Transfer | `BROWNSVIL`, local ID `5542`, date `9/21/1993` |
| Death | `BROWNSVIL`, local ID `NHXX`, date `2/17/1994` |

The same studbook defines **BROWNSVIL** as **Gladys Porter Zoo, Brownsville, TX, USA**.

Therefore, the link is not that the studbook prints `GPZ-5542`; it prints **BROWNSVIL local ID 5542**. The interpretation is:

```text
MacLeod:     GIBBON DISCO = GPZ-5542
Studbook:   DISCO = BROWNSVIL local ID 5542
BROWNSVIL:  Gladys Porter Zoo, Brownsville, TX
Therefore:  GPZ-5542 = Gladys Porter Zoo local ID 5542 for Disco
```

This is a strong specimen-identity match because the name, sex, age, and institution/local-ID trail all agree.

### 3. Age agreement supports the match

MacLeod lists Disco as **22 years** old. The studbook lists Disco's estimated birth date as **1972-01-01** and death as **1994-02-17**, which is approximately 22 years. This independently supports that the MacLeod/Yerkes specimen and the studbook animal are the same individual.

### 4. Barger 2007 includes Disco but only labels the taxon as generic `Gibbon`

In `Barger_etal_2007_Table1_snapshot.csv`, Table 1 has a generic **Gibbon** section with two individuals:

| Published group | Specimen ID | Age | Sex | Hemi cm3 | Amygdaloid complex L | Lateral L | Basal L | Accessory basal L |
|---|---:|---:|---|---:|---:|---:|---:|---:|
| Gibbon | Disco | 22 | F | 93.2 | 0.270 | 0.060 | 0.086 | 0.0223 |
| Gibbon | YN81-146 | Adult | F | 68.3 | 0.203 | 0.046 | 0.063 | 0.0206 |

Barger 2007's table itself does not map Disco to a formal species name. It only places Disco under the broad heading `Gibbon`.

### 5. Barger 2014 maps the Barger 2007 Disco values to *Nomascus concolor*

In `Barger_etal_2014_Table1_snapshot.xlsx`, Table 1 has starred rows for cases included in Barger et al. 2007. The starred gibbon rows are:

| Published taxon in Barger 2014 | Lateral | Basal | Accessory basal | Central | Total amygdala | Hippocampus | Striatum |
|---|---:|---:|---:|---:|---:|---:|---:|
| *Hylobates lar* *,a | 0.046* | 0.063* | 0.021* | 0.009 | 0.203* | 0.805 | 1.510 |
| *Nomascus concolor* *,a | 0.060* | 0.086* | 0.022* | 0.012 | 0.270* | 0.950 | 1.994 |

The *Nomascus concolor* row matches the **left hemisphere** values for Barger 2007's **Disco** row:

| Measure | Barger 2007 Disco L | Barger 2014 *Nomascus concolor* |
|---|---:|---:|
| Amygdala total | 0.270 | 0.270* |
| Lateral nucleus | 0.060 | 0.060* |
| Basal nucleus | 0.086 | 0.086* |
| Accessory basal nucleus | 0.0223 | 0.022* |

The *Hylobates lar* row instead matches Barger 2007's **YN81-146** row:

| Measure | Barger 2007 YN81-146 L | Barger 2014 *Hylobates lar* |
|---|---:|---:|
| Amygdala total | 0.203 | 0.203* |
| Lateral nucleus | 0.046 | 0.046* |
| Basal nucleus | 0.063 | 0.063* |
| Accessory basal nucleus | 0.0206 | 0.021* |

This means Barger 2014 explicitly maps **Disco** to *Nomascus concolor*, not to *Hylobates lar*. However, the studbook evidence points to *Nomascus leucogenys*, so Barger 2014 may still be using a taxonomic identification that does not match the studbook.

## Interpretation

### What is secure

The following points are secure enough to encode in the database:

1. **Disco** is the same specimen as **GPZ-5542** in MacLeod Appendix I.
2. The white-cheeked gibbon studbook contains a female **DISCO**, studbook ID **0050**, with **BROWNSVIL local ID 5542**.
3. **BROWNSVIL** is Gladys Porter Zoo, Brownsville, TX.
4. The `GPZ` in `GPZ-5542` is therefore best interpreted as **Gladys Porter Zoo**, with `5542` matching the studbook local ID.
5. Barger 2007's **Disco** row is the same individual that Barger 2014 reports as *Nomascus concolor*.
6. Barger 2007's **YN81-146** row, not Disco, is the row later reported as *Hylobates lar* in Barger 2014.

### What remains uncertain

The exact species label to use for Disco is the only remaining issue.

- MacLeod prints only `GIBBON`, not a formal species name, in the Disco row.
- Barger 2007 prints only `Gibbon` in Table 1, although the paper text says the sample includes *Hylobates concolor* and *Hylobates lar*.
- Barger 2014 maps Disco's values to *Nomascus concolor*.
- The white-cheeked gibbon studbook places Disco under *Nomascus leucogenys*.

Because the studbook is a specimen/provenance record rather than an inferred table label, it is probably the strongest source for the individual animal's taxon. Still, it would be best to mark this as a resolved-by-studbook decision rather than pretending all publications agree.

## Recommended database treatment

### Recommended specimen fields

```text
specimen_name = DISCO
primary_identifier = GPZ-5542
studbook_id = 0050
alternate_identifiers = DISCO (3/97); GPZ-5542; BROWNSVIL 5542; Baltimore 72225
sex = F
source = YERKES
origin_or_prior_institution = Gladys Porter Zoo / BROWNSVIL
birth_date_estimated = 1972-01-01
birth_date_estimate_precision = year
death_date = 1994-02-17
age_at_death_years = 22
```

### Recommended taxon fields

Best option, if accepting the studbook as authoritative:

```text
taxon_current = Nomascus leucogenys
taxon_basis = White-cheeked Gibbon Studbook, Studbook ID 0050, house name DISCO, BROWNSVIL local ID 5542
taxon_conflict = TRUE
```

More conservative option, if not yet accepting the studbook as final:

```text
taxon_current = NA
taxon_common_printed = gibbon
taxon_conflict = TRUE
taxon_note = Formal species unresolved in published brain datasets; MacLeod prints GIBBON; Barger 2014 maps this specimen to Nomascus concolor; white-cheeked gibbon studbook identifies Disco/BROWNSVIL 5542 as Nomascus leucogenys.
```

### Recommended publication-alias note

```text
MacLeod 2000: printed as GIBBON, identifier DISCO (3/97) / GPZ-5542.
Barger 2007: printed as Gibbon, specimen ID Disco.
Barger 2014: same left-hemisphere values as Barger 2007 Disco are published under Nomascus concolor.
Studbook: DISCO, Studbook ID 0050, BROWNSVIL local ID 5542, in the White-Cheeked Gibbon Studbook for Nomascus leucogenys.
```

## Script/data-cleaning implications

The Appendix I script should keep these concepts separate:

```text
taxon_printed
species
specimen_name
record_note
primary_identifier
alternate_identifiers
taxon_common_printed
taxonomic_issue
taxonomic_note
```

For Disco, the multiline `IDENT. NUMBER` cell should be parsed as:

```text
specimen_name = DISCO
record_note = 3/97
primary_identifier = GPZ-5542
alternate_identifiers = DISCO (3/97); GPZ-5542
```

The script should **not** convert generic `GIBBON` to *Hylobates lar*. That conversion would incorrectly make Disco look like the lar gibbon specimen, when Barger 2014 shows that the lar row corresponds to YN81-146.

## Suggested final note for database documentation

> The specimen "Disco" is a female gibbon specimen from the Yerkes/Zilles-Semendeferi material. MacLeod Appendix I identifies it as `GIBBON`, identifier `DISCO (3/97) / GPZ-5542`, age 22 years, source Yerkes. A white-cheeked gibbon studbook record gives `DISCO`, Studbook ID 0050, female, estimated birth 1972, transfer to Baltimore local ID 72225, transfer to BROWNSVIL local ID 5542 on 1993-09-21, and death at BROWNSVIL on 1994-02-17. BROWNSVIL is Gladys Porter Zoo, Brownsville, Texas, so `GPZ-5542` is interpreted as Gladys Porter Zoo local ID 5542. Barger 2007 lists the specimen as `Gibbon / Disco`; Barger 2014 maps the same left-hemisphere amygdala values to *Nomascus concolor*. The studbook, however, is for *Nomascus leucogenys*. Therefore this specimen should be tracked by specimen identity and aliases, with a taxonomic-conflict note. Do not infer *Hylobates lar* from the generic label `Gibbon`; Barger 2014's *Hylobates lar* row corresponds to YN81-146, not Disco.

## Sources checked

- `MacLeod__2000_APPENDIXI.csv`, row for `GIBBON / ZILLES(SEMEND.)`, `DISCO (3/97) / GPZ-5542`.
- `Barger_etal_2007_Table1_snapshot.csv`, `Gibbon` rows for `Disco` and `YN81-146`.
- `Barger_etal_2014_Table1_snapshot.xlsx`, starred rows for *Hylobates lar* and *Nomascus concolor*.
- White-Cheeked Gibbon Studbook, *Nomascus leucogenys*, North American Region Studbook, data current 2011-10-25, published 2011-11-01: https://alouattasen.weebly.com/uploads/8/9/5/6/8956452/gibbonwhitecheekedstudbook2011-1f204327.pdf
