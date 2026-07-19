#!/usr/bin/env python3
"""
build_body_ecology_merge.py  --  whole-organism (body & ecology) merge.

First measure class: BODY MASS, harvested from every source table that records
it (39 tables), pooled team/role-aware so the same specimens / compilations are
not double-counted. Structured (measure_class column) so body BMR and
ecological/life-history measures can be appended as further classes later.

Pipeline (mirrors __merging_cerebral_metabolic_rate):
  1. pick the species-level body-mass column + unit per source (auditable map)
  2. harvest -> resolve species -> convert to grams  -> *_unfiltered.csv
  3. team-dedupe (same collection = one value), then pool across teams
     (primary preferred)                                -> *_long.csv / *_wide.csv
  4. dedupe / disagreement report                       -> *_dedupe_report.csv

R is unavailable in the build env, so this tested builder ships the CSVs; the
house-style twin `body_ecology_compiled.R` implements the same logic.
"""
import csv, glob, os, re, statistics, sys

REPO = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
PUB  = os.path.join(REPO, "__Public", "comparative-data")
OUT  = os.path.dirname(__file__)

# ---------------------------------------------------------------- lookups ----
def read_csv(path):
    with open(path, encoding="utf-8") as f:
        return list(csv.DictReader(f))

manifest = {r["file"]: r for r in read_csv(os.path.join(REPO, "__ShinyApp", "data", "source_manifest.csv"))}

# crosswalk: (first_author_lower, year) -> team (same-collection dedupe)
team_by_ay = {}
for r in read_csv(os.path.join(REPO, "_keys", "team_grouping_crosswalk.csv")):
    item = (r.get("item (papers tribble)") or "").strip()
    team = (r.get("script_team (volumes_compiled.R)") or "").strip()
    m = re.match(r"([A-Za-z]+).*?_((?:19|20)\d\d)", item)
    if m and team:
        team_by_ay[(m.group(1).lower(), m.group(2))] = team

# role from variable_catalog: (first_author_lower, year) -> role (body-mass rows)
role_by_ay = {}
for r in read_csv(os.path.join(REPO, "_keys", "variable_catalog.csv")):
    if r["measure_class"] != "mass":
        continue
    t = (r["Code"] + " " + r["Definition"]).lower()
    if "body" not in t or "brain" in t:
        continue
    m = re.match(r"([A-Za-z]+).*?((?:19|20)\d\d)", r["paper"])
    if m:
        role_by_ay.setdefault((m.group(1).lower(), m.group(2)), r["role"])

# species resolver: combine every _keys/*/species_key.csv + species_reference
ref = [r["accepted_name"] for r in read_csv(os.path.join(REPO, "_keys", "species_reference.csv"))]
ref_l = {r.lower(): r for r in ref}
variant = {}
for kf in glob.glob(os.path.join(REPO, "_keys", "*", "species_key.csv")):
    for r in read_csv(kf):
        v = (r.get("variant_name") or "").strip()
        a = (r.get("accepted_name") or "").strip()
        if v and a:
            variant.setdefault(v.lower(), a)
def clean_sp(x):
    x = re.sub(r"\*", "", str(x)).replace("_", " ")
    return re.sub(r"\s+", " ", x).strip()
def resolve(x):
    c = clean_sp(x)
    if c.lower() in ref_l: return ref_l[c.lower()]
    if c.lower() in variant: return variant[c.lower()]
    return c  # keep cleaned printed name if unresolved

# ------------------------------------------------ body-mass column picker ----
BODY_RX = re.compile(r"(body.?mass|body.?weight|bodyweight|bo[wm]ass|bo?w_g|body_?wt)", re.I)
EXCLUDE = ("source", "ref", "note", "_sd", " sd", "sem", "dimorph", "log", "raw",
           "spinal", "brain", "assoc", ": data", "original")
SKIP_FILES = {  # tables whose only body column is not a species mass value
    "10.1016%2Fj.jhevol.2008.08.004_Table7.tsv",  # body mass *dimorphism* (ratio)
}
def norm(h): return h.strip().strip('"').lower()

def pick_column(headers, fn):
    cands = [h for h in headers if BODY_RX.search(norm(h)) and not any(e in norm(h) for e in EXCLUDE)]
    # drop count columns ("N body mass ...")
    cands = [h for h in cands if not (norm(h).startswith(("n ", "n_")) or "sample_size" in norm(h))]
    if not cands:
        return None, None
    # drop a "(mg)" duplicate when a "(g)" sibling exists
    if any("(g)" in norm(h) for h in cands):
        cands = [h for h in cands if "(mg)" not in norm(h)]
    # prefer an explicit species mean over sex-specific
    sp = [h for h in cands if "species" in norm(h)]
    if sp:
        pick = sp[0]
    else:
        cands2 = [h for h in cands if not any(s in norm(h) for s in ("male", "female"))]
        pick = (cands2 or cands)[0]
    n = norm(pick)
    unit = "kg" if "kg" in n else ("mg" if re.search(r"\bmg\b|\(mg\)|_mg", n) else "g")
    return pick, unit

FACTOR = {"g": 1.0, "kg": 1000.0, "mg": 0.001}

# ---------------------------------------------------------------- harvest ----
def paper_key(file):
    m = manifest.get(file, {})
    return (m.get("first_author", "").strip(), m.get("year", "").strip())

BINOM = re.compile(r"^[A-Z][a-z]+ [a-z][a-z-]+")
def species_getter(headers, sample):
    """Return f(row)->species string. Detect the binomial column by value
    pattern; if none, combine a Genus + Species split; else fall back."""
    idx = {h: i for i, h in enumerate(headers)}
    def val(row, i): return row[i].strip().strip('"') if len(row) > i else ""
    def score(i):
        vals = [val(r, i) for r in sample if val(r, i)]
        return (sum(bool(BINOM.match(v)) for v in vals) / len(vals)) if vals else 0.0
    scores = {h: score(idx[h]) for h in headers}
    best = max(scores, key=scores.get) if scores else None
    if best is not None and scores[best] >= 0.5:
        i = idx[best]; return (lambda r: val(r, i)), best
    genus = next((h for h in headers if norm(h) == "genus"), None)
    spec  = next((h for h in headers if norm(h) in ("species", "species epithet")), None)
    if genus and spec:
        gi, si = idx[genus], idx[spec]
        return (lambda r: (val(r, gi) + " " + val(r, si)).strip()), f"{genus}+{spec}"
    for h in headers:
        if norm(h) in ("species", "scientific", "scientific name", "taxon", "binomial",
                       "genus species", "species name", "species_name", "animal"):
            i = idx[h]; return (lambda r: val(r, i)), h
    return (lambda r: val(r, 0)), headers[0]

unfiltered = []            # dict rows
colmap_rows = []           # audit: which column/unit chosen per source
for path in sorted(glob.glob(os.path.join(PUB, "*.tsv"))):
    fn = os.path.basename(path)
    with open(path, encoding="utf-8") as f:
        rows = list(csv.reader(f, delimiter="\t"))
    if not rows:
        continue
    headers = rows[0]
    if not any(BODY_RX.search(norm(h)) for h in headers):
        continue
    author, year = paper_key(fn)
    col, unit = (None, None) if fn in SKIP_FILES else pick_column(headers, fn)
    colmap_rows.append({"file": fn, "first_author": author, "year": year,
                        "chosen_column": col or "(none/skipped)", "unit": unit or "",
                        "all_body_columns": "; ".join(h for h in headers
                                                       if BODY_RX.search(norm(h)))})
    if not col:
        continue
    ay = (author.lower(), year)
    team = team_by_ay.get(ay, author or fn)          # independent team if not a known collection
    role = role_by_ay.get(ay, "secondary")           # default secondary if not catalogued
    idx = {h: i for i, h in enumerate(headers)}
    get_sp, sp_src = species_getter(headers, rows[1:60])
    for r in rows[1:]:
        if len(r) <= idx[col]:
            continue
        raw = r[idx[col]].strip().strip('"')
        try:
            val = float(raw)
        except ValueError:
            continue
        sp_raw = get_sp(r)
        sp = resolve(sp_raw)
        if not sp or sp.lower() in ("na", "none", ""):
            continue
        unfiltered.append({
            "Species": sp, "Species_raw": sp_raw, "measure_class": "mass",
            "Measure": "Body_Mass", "Units": "g",
            "Value_g": val * FACTOR[unit], "raw_value": raw, "raw_unit": unit,
            "Source": fn, "first_author": author, "Year": year,
            "Team": team, "role": role,
        })

# ------------------------------------------------------------------ pool -----
by_species = {}
for row in unfiltered:
    by_species.setdefault(row["Species"], []).append(row)

long_rows, dedupe_rows = [], []
for sp, rows in sorted(by_species.items()):
    # team-dedupe: mean within each team (same specimens / same collection)
    teams = {}
    for r in rows:
        teams.setdefault(r["Team"], []).append(r)
    team_vals = {t: statistics.mean(x["Value_g"] for x in rs) for t, rs in teams.items()}
    team_role = {t: ("primary" if any(x["role"] == "primary" for x in rs) else
                     rs[0]["role"]) for t, rs in teams.items()}
    prim = {t: v for t, v in team_vals.items() if team_role[t] == "primary"}
    used = prim if prim else team_vals            # primary preferred
    pooled = statistics.mean(used.values())
    pooled_med = statistics.median(used.values())  # robust to source outliers
    vals_all = [r["Value_g"] for r in rows]
    spread = (max(vals_all) / min(vals_all)) if min(vals_all) > 0 else float("nan")
    long_rows.append({
        "Species": sp, "measure_class": "mass", "Measure": "Body_Mass", "Units": "g",
        "Value": round(pooled, 3), "Value_median": round(pooled_med, 3),
        "n_sources": len(rows), "n_teams": len(team_vals),
        "n_teams_primary": len(prim), "primary_used": bool(prim),
        "Teams": "; ".join(sorted(team_vals)),
        "roles": "; ".join(sorted({r["role"] for r in rows})),
        "value_min": round(min(vals_all), 3), "value_max": round(max(vals_all), 3),
    })
    if len(rows) > 1:
        dedupe_rows.append({
            "Species": sp, "n_sources": len(rows), "n_teams": len(team_vals),
            "pooled_g": round(pooled, 3),
            "spread_max_over_min": round(spread, 2),
            "flag": "DISAGREEMENT>2x" if (spread == spread and spread > 2) else "",
            "per_source": " | ".join(f'{r["first_author"]}{r["Year"]}({r["Team"]},{r["role"]})='
                                     f'{round(r["Value_g"])}' for r in rows),
        })

# ------------------------------------------------------------------ write ----
def write(fn, rows, cols):
    with open(os.path.join(OUT, fn), "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=cols); w.writeheader()
        for r in rows: w.writerow(r)

write("body_ecology_source_columns.csv", colmap_rows,
      ["file", "first_author", "year", "chosen_column", "unit", "all_body_columns"])
write("body_ecology_unfiltered.csv", unfiltered,
      ["Species", "Species_raw", "measure_class", "Measure", "Units", "Value_g",
       "raw_value", "raw_unit", "Source", "first_author", "Year", "Team", "role"])
write("body_ecology_long.csv", long_rows,
      ["Species", "measure_class", "Measure", "Units", "Value", "Value_median",
       "n_sources", "n_teams", "n_teams_primary", "primary_used", "Teams", "roles",
       "value_min", "value_max"])
write("body_ecology_dedupe_report.csv", sorted(dedupe_rows, key=lambda x: -x["n_sources"]),
      ["Species", "n_sources", "n_teams", "pooled_g", "spread_max_over_min", "flag", "per_source"])
# wide (one measure so far)
write("body_ecology_wide.csv",
      [{"Species": r["Species"], "Body_Mass.g": r["Value"]} for r in long_rows],
      ["Species", "Body_Mass.g"])

print(f"sources with body mass: {sum(1 for c in colmap_rows if c['chosen_column'] not in ('(none/skipped)',))}")
print(f"unfiltered rows: {len(unfiltered)}  |  species pooled: {len(long_rows)}")
print(f"disagreement>2x flags: {sum(1 for d in dedupe_rows if d['flag'])}")
