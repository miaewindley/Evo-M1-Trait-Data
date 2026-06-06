# How to make a snapshot — a guide for RAs

This dataset compiles published trait tables from many papers into one
comparable format. For every table we keep four files in the paper's folder:

| file | what it is |
|---|---|
| `..._snapshot.csv` *(or `.xlsx`)* | **the snapshot** — a frozen, faithful copy of the table *as published* |
| `....csv` | the cleaned, analysis-ready data ("use this") |
| `....R` | the script that turns the snapshot into the clean CSV |
| `....ReadMe.md` | a short note on where the table came from and what was done |

This guide is about the first one.

---

## What a snapshot is

> **A snapshot is a frozen, faithful digital copy of a published table, saved
> exactly as it appears in the source — before any cleaning.**

Think of it as a photograph of the table. It looks like the paper: same layout,
same column headers, same values, same footnote marks, same reference numbers,
same units. It is *digitized* (so R can read it — CSV or Excel) but **not yet
tidied**.

## Why we bother (the point of it)

The snapshot is the **audit anchor** between the paper and our analysis.

- **Traceability.** Anyone can lay the snapshot next to the PDF and confirm,
  cell by cell, that we copied the paper correctly.
- **Separation of "what the paper said" from "what we changed."** Every edit —
  renaming a column, dropping a unit, fixing a typo — happens *after* the
  snapshot, inside the `.R` script. So the changes are visible and reversible.
- **Durability.** Papers, links and supplementary files disappear. The snapshot
  is our own permanent copy. *(We keep a hardcopy snapshot file even when the
  data is also available at a URL.)*

If the clean data ever looks wrong, the snapshot is how we find out whether the
mistake came from the paper or from our cleaning.

## The one golden rule

**Freeze the snapshot before you clean anything. Do all cleaning in the `.R`
script.**

The most common mistake is saving the snapshot *after* already renaming headers
or stripping symbols — then it no longer matches the paper, and the whole point
(comparison to source) is lost. Capture first, clean second.

## What the snapshot must keep (fidelity checklist)

Keep everything that is in the printed table, even if it looks messy:

- [ ] **Original column headers** (even long, multi-line, or symbol-heavy ones)
- [ ] **All values exactly as printed** — including units, `×10⁶`-style notation,
      and spaces inside numbers (`47 960`)
- [ ] **Footnote markers** — `*`, superscript letters (`218a`), daggers, etc.
- [ ] **Reference citations** printed in the cells — `[19]`, `(20)`
- [ ] **`n.a.` / `—` / blank** cells, as printed (don't "fix" them yet)
- [ ] **Grouping / header rows** (e.g. clade names that span the table)
- [ ] **Row order** as published

Cleaning (numbers → numeric, splitting columns, NCBI species names, etc.) comes
later, in the script. Not here.

## How to make one — methods, best first

1. **Direct download.** If the journal offers the table/supplement as `.xlsx`
   or `.csv`, download it and use that file as the snapshot. Easiest and most
   faithful.

2. **PDF → Excel (our default for printed tables).** Open the PDF in Adobe
   Acrobat Pro → *Export a PDF → Microsoft Excel Workbook*. Copy/paste the table
   and lightly reformat so it matches the printed layout. Save as
   `..._snapshot.xlsx`.

3. **Manual entry** (when the PDF is a scan or export is garbled). Type it in,
   keeping the original layout. Then double-check it — e.g. ask an AI assistant
   to read the table from the PDF and diff it against your file, and correct any
   mismatches by hand.

4. **Web-scrape the publisher's HTML** (when the PDF won't extract — e.g. a
   wide, rotated table). Pull the table from the open-access HTML version (PMC,
   journal site) in R with `rvest`. **Then cross-check it against the PDF**, and
   document in the ReadMe that the source was the HTML version. *(Worked example
   in the repo: `HerculanoHouzel__2015/` Table 1.)*

Whatever the method, the result is the same kind of file: a faithful, frozen
copy you can compare to the paper.

## File naming

Inside the paper's folder (e.g. `JardimMesseder_etal_2017/`):

```
<Paper>_<Table>_snapshot.csv     # or .xlsx — the snapshot
<Paper>_<Table>.csv              # cleaned data, "use this"
<Paper>_<Table>.R                # snapshot -> clean
<Paper>_<Table>.ReadMe.md        # source + steps
```

The ReadMe follows the team pipeline:
`Source → Snapshot → Data readable → (Transpose / Variables / Species notes) →
Online database`. See the `Pipeline` sheet in `__ReadMe.xlsx` for the full
sequence, and any existing `*.ReadMe.md` for the format.

## Quick self-check before you move on

- Could someone open my snapshot next to the PDF and see they're the same table?
- Did I keep the footnotes and reference numbers?
- Is *every* change to the data written down in the `.R` script (and nothing
  baked silently into the snapshot)?
- Did I save a local snapshot file, even though the data is online?

If yes to all four, the snapshot is proper.
