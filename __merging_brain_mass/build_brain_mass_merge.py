#!/usr/bin/env python3
"""
build_brain_mass_merge.py  --  whole-brain mass merge.

Pools whole-brain mass from every source table that records it (29 tables,
Burger et al. 2019 SD1 = 1,552 species being the largest), team/role-aware so
the same specimens / compilations are not double-counted. Sibling of the body
mass merge in __merging_body_ecology; same pipeline as
__merging_cerebral_metabolic_rate.

  1. pick the whole-brain-mass column + unit per source (auditable map)
     - unit from the column name; for unit-less columns inferred by magnitude
       (mammal brains are <~10,000 g, so a source whose max > 20,000 is in mg).
  2. harvest -> resolve species -> convert to grams        -> *_unfiltered.csv
  3. team-dedupe, then pool across teams (primary preferred),
     mean + robust median                                   -> *_long.csv / *_wide.csv
  4. cross-source disagreement report                       -> *_dedupe_report.csv

The Python builder is the tested artifact (no R in the build env); the twin
`brain_mass_compiled.R` implements the same logic.
"""
import csv, glob, os, re, statistics

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PUB  = os.path.join(REPO, "__Public", "comparative-data")
OUT  = os.path.dirname(__file__)

def read_csv(p):
    with open(p, encoding="utf-8") as f:
        return list(csv.DictReader(f))

manifest = {r["file"]: r for r in read_csv(os.path.join(REPO, "__ShinyApp", "data", "source_manifest.csv"))}

team_by_ay = {}
for r in read_csv(os.path.join(REPO, "_keys", "team_grouping_crosswalk.csv")):
    item = (r.get("item (papers tribble)") or "").strip()
    team = (r.get("script_team (volumes_compiled.R)") or "").strip()
    m = re.match(r"([A-Za-z]+).*?_((?:19|20)\d\d)", item)
    if m and team:
        team_by_ay[(m.group(1).lower(), m.group(2))] = team

role_by_ay = {}
for r in read_csv(os.path.join(REPO, "_keys", "variable_catalog.csv")):
    if r["measure_class"] != "mass":
        continue
    t = (r["Code"] + " " + r["Definition"]).lower()
    if "brain" not in t or "body" in t:
        continue
    m = re.match(r"([A-Za-z]+).*?((?:19|20)\d\d)", r["paper"])
    if m:
        role_by_ay.setdefault((m.group(1).lower(), m.group(2)), r["role"])

ref = [r["accepted_name"] for r in read_csv(os.path.join(REPO, "_keys", "species_reference.csv"))]
ref_l = {r.lower(): r for r in ref}
variant = {}
for kf in glob.glob(os.path.join(REPO, "_keys", "*", "species_key.csv")):
    for r in read_csv(kf):
        v = (r.get("variant_name") or "").strip(); a = (r.get("accepted_name") or "").strip()
        if v and a:
            variant.setdefault(v.lower(), a)
def clean_sp(x):
    return re.sub(r"\s+", " ", re.sub(r"\*", "", str(x)).replace("_", " ")).strip()
def resolve(x):
    c = clean_sp(x)
    if c.lower() in ref_l: return ref_l[c.lower()]
    if c.lower() in variant: return variant[c.lower()]
    return c

# ---- whole-brain-mass column picker ----------------------------------------
BRAIN_RX = re.compile(r"brain.{0,3}(mass|weight|wt)", re.I)   # brain within 3 chars of mass/weight
EXCLUDE = ("neonat", "fetal", "cerebel", "cortex", "cortic", "olfact", "rest of brain",
           "diencephal", "mesencephal", "pons", "medulla", "hemisphere", "white", "grey",
           "gray", "region", "residual", "resid", "net", "ratio", "source", "ref", "note",
           "_sd", " sd", ": data", "%", "index", "relative")
def norm(h): return h.strip().strip('"').lower()

def pick_column(headers):
    cand = [h for h in headers if BRAIN_RX.search(norm(h)) and not any(e in norm(h) for e in EXCLUDE)]
    cand = [h for h in cand if not (norm(h).startswith(("n ", "n_")) or "sample_size" in norm(h))]
    if not cand:
        return None
    if any("whole" in norm(h) for h in cand):
        cand = [h for h in cand if "whole" in norm(h)] or cand
    return cand[0]

def named_unit(colname):
    """Unit from the column name, or None if unit-less."""
    n = norm(colname)
    if "kg" in n: return "kg"
    if re.search(r"\bmg\b|\(mg\)|_mg", n): return "mg"
    if "(g)" in n or n.endswith("_g") or ", g" in n or "cm3" in n or re.search(r"\bg\b", n):
        return "g"
    return None

def unit_of(colname, global_max):
    """Named unit if present; else inferred from the GLOBAL max of that column
    across all of an author's tables (mammal brains are < ~10,000 g, so a
    unit-less column whose max exceeds 20,000 is milligrams). Deciding per
    source-group, not per file, avoids mislabelling a small-taxa subtable."""
    return named_unit(colname) or ("mg" if global_max > 20000 else "g")

FACTOR = {"g": 1.0, "kg": 1000.0, "mg": 0.001}

BINOM = re.compile(r"^[A-Z][a-z]+ [a-z][a-z-]+")
def species_getter(headers, sample):
    idx = {h: i for i, h in enumerate(headers)}
    def val(row, i): return row[i].strip().strip('"') if len(row) > i else ""
    def score(i):
        vals = [val(r, i) for r in sample if val(r, i)]
        return (sum(bool(BINOM.match(v)) for v in vals) / len(vals)) if vals else 0.0
    scores = {h: score(idx[h]) for h in headers}
    best = max(scores, key=scores.get) if scores else None
    if best is not None and scores[best] >= 0.5:
        i = idx[best]; return lambda r: val(r, i)
    g = next((h for h in headers if norm(h) == "genus"), None)
    s = next((h for h in headers if norm(h) in ("species", "species epithet")), None)
    if g and s:
        gi, si = idx[g], idx[s]
        return lambda r: (val(r, gi) + " " + val(r, si)).strip()
    for h in headers:
        if norm(h) in ("species", "scientific", "scientific name", "taxon", "binomial",
                       "genus species", "species name", "species_name", "animal"):
            i = idx[h]; return lambda r: val(r, i)
    return lambda r: val(r, 0)

def paper_key(fn):
    m = manifest.get(fn, {})
    return (m.get("first_author", "").strip(), m.get("year", "").strip())

# ---- pass 1: locate the brain-mass column per file + global max per (author,col)
targets, colmap, gmax = [], [], {}
for path in sorted(glob.glob(os.path.join(PUB, "*.tsv"))):
    fn = os.path.basename(path)
    with open(path, encoding="utf-8") as f:
        rows = list(csv.reader(f, delimiter="\t"))
    if not rows:
        continue
    headers = [h.strip('"') for h in rows[0]]
    if not any(BRAIN_RX.search(norm(h)) for h in headers):
        continue
    allbrain = "; ".join(h for h in headers if BRAIN_RX.search(norm(h)))
    col = pick_column(headers)
    if not col:
        colmap.append({"file": fn, "chosen_column": "(none)", "unit": "", "all_brain_columns": allbrain})
        continue
    ci = headers.index(col)
    vals = []
    for r in rows[1:]:
        if len(r) > ci:
            try: vals.append(float(r[ci].strip().strip('"')))
            except ValueError: pass
    if not vals:
        colmap.append({"file": fn, "chosen_column": col + " (non-numeric)", "unit": "", "all_brain_columns": allbrain})
        continue
    author, year = paper_key(fn)
    targets.append((fn, rows, headers, col, ci, author, year, allbrain))
    if named_unit(col) is None:                     # unit-less -> pool max by (author, col)
        k = (author.lower(), norm(col)); gmax[k] = max(gmax.get(k, 0), max(vals))

# ---- pass 2: harvest with the group-resolved unit --------------------------
unfiltered = []
for fn, rows, headers, col, ci, author, year, allbrain in targets:
    gm = gmax.get((author.lower(), norm(col)), 0)
    unit = unit_of(col, gm)
    colmap.append({"file": fn, "chosen_column": col, "unit": unit, "all_brain_columns": allbrain})
    ay = (author.lower(), year)
    team = team_by_ay.get(ay, author or fn)
    role = role_by_ay.get(ay, "secondary")
    get_sp = species_getter(headers, rows[1:60])
    for r in rows[1:]:
        if len(r) <= ci: continue
        raw = r[ci].strip().strip('"')
        try: v = float(raw)
        except ValueError: continue
        sp = resolve(get_sp(r))
        if not sp or sp.lower() in ("na", "none", ""): continue
        unfiltered.append({"Species": sp, "Measure": "Brain_Mass", "Units": "g",
                           "Value_g": v * FACTOR[unit], "raw_value": raw, "raw_unit": unit,
                           "Source": fn, "first_author": author, "Year": year,
                           "Team": team, "role": role})

# ---- pool ------------------------------------------------------------------
by_sp = {}
for row in unfiltered:
    by_sp.setdefault(row["Species"], []).append(row)
long_rows, dedupe = [], []
for sp, rs in sorted(by_sp.items()):
    teams = {}
    for r in rs: teams.setdefault(r["Team"], []).append(r)
    tv = {t: statistics.mean(x["Value_g"] for x in xs) for t, xs in teams.items()}
    trole = {t: ("primary" if any(x["role"] == "primary" for x in xs) else xs[0]["role"]) for t, xs in teams.items()}
    prim = {t: v for t, v in tv.items() if trole[t] == "primary"}
    used = prim if prim else tv
    va = [r["Value_g"] for r in rs]
    spread = (max(va) / min(va)) if min(va) > 0 else float("nan")
    long_rows.append({"Species": sp, "measure_class": "mass", "Measure": "Brain_Mass", "Units": "g",
        "Value": round(statistics.mean(used.values()), 4),
        "Value_median": round(statistics.median(used.values()), 4),
        "n_sources": len(rs), "n_teams": len(tv), "n_teams_primary": len(prim),
        "primary_used": bool(prim), "Teams": "; ".join(sorted(tv)),
        "roles": "; ".join(sorted({r["role"] for r in rs})),
        "value_min": round(min(va), 4), "value_max": round(max(va), 4)})
    if len(rs) > 1:
        dedupe.append({"Species": sp, "n_sources": len(rs), "n_teams": len(tv),
            "pooled_g": round(statistics.mean(used.values()), 4),
            "spread_max_over_min": round(spread, 2),
            "flag": "DISAGREEMENT>2x" if (spread == spread and spread > 2) else "",
            "per_source": " | ".join(f'{r["first_author"]}{r["Year"]}({r["Team"]},{r["role"]})='
                                     f'{round(r["Value_g"],2)}' for r in rs)})

def write(fn, rows, cols):
    with open(os.path.join(OUT, fn), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols); w.writeheader(); [w.writerow(r) for r in rows]

write("brain_mass_source_columns.csv", colmap, ["file", "chosen_column", "unit", "all_brain_columns"])
write("brain_mass_unfiltered.csv", unfiltered,
      ["Species", "Measure", "Units", "Value_g", "raw_value", "raw_unit", "Source",
       "first_author", "Year", "Team", "role"])
write("brain_mass_long.csv", long_rows,
      ["Species", "measure_class", "Measure", "Units", "Value", "Value_median", "n_sources",
       "n_teams", "n_teams_primary", "primary_used", "Teams", "roles", "value_min", "value_max"])
write("brain_mass_dedupe_report.csv", sorted(dedupe, key=lambda x: -x["n_sources"]),
      ["Species", "n_sources", "n_teams", "pooled_g", "spread_max_over_min", "flag", "per_source"])
write("brain_mass_wide.csv", [{"Species": r["Species"], "Brain_Mass.g": r["Value"]} for r in long_rows],
      ["Species", "Brain_Mass.g"])

print("sources with brain mass:", sum(1 for c in colmap if c["chosen_column"] not in ("(none)",) and "non-numeric" not in c["chosen_column"]))
print("unfiltered rows:", len(unfiltered), "| species pooled:", len(long_rows))
print("disagreement>2x flags:", sum(1 for d in dedupe if d["flag"]))
