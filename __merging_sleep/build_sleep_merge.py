#!/usr/bin/env python3
"""Python port of sleep_compiled.R — regenerates the sleep merge outputs without R.

Reads the sources' harmonized TSVs from ../__Public/comparative-data/, resolves Eagleman common
names to binomials via species_resolution_Eagleman.csv, and writes sleep_long.csv, sleep_wide.csv,
sleep_source_species_ids.csv. R (sleep_compiled.R) is the canonical path; this reproduces it
identically. Run from inside the __merging_sleep folder:  python3 build_sleep_merge.py
"""
import csv, os

HERE = os.path.dirname(os.path.abspath(__file__))
BASE = os.path.normpath(os.path.join(HERE, ".."))
TSV  = os.path.join(BASE, "__Public", "comparative-data")
EAG  = os.path.join(TSV, "10.3389%2Ffnins.2021.632853_TABLE1.tsv")
HH   = os.path.join(TSV, "10.1098%2Frspb.2015.1853_Table1.tsv")

def read_tsv(p):
    with open(p, newline="", encoding="utf-8") as f:
        rows = [[c.strip('"') for c in r] for r in csv.reader(f, delimiter="\t")]
    return rows[0], rows[1:]

# Eagleman common -> binomial resolution (editable in the CSV)
res = {}
with open(os.path.join(HERE, "species_resolution_Eagleman.csv"), newline="", encoding="utf-8") as f:
    for row in csv.DictReader(f):
        res[row["Species_common"]] = (row["Species"], row["species_confidence"], row["note"])

hh_alias = {"Loxodonta Africana": "Loxodonta africana"}

long = []  # Species, Species_printed, Standardized_Term, Value, Units, source, team, ref, conf, dep
eh, er = read_tsv(EAG); i_sp = eh.index("Species"); i_rem = eh.index("REM_sleep_percent")
for row in er:
    common, val = row[i_sp], row[i_rem]
    if val in ("", "NA"):
        continue
    b, conf, _ = res.get(common, (common, "review", "UNMAPPED"))
    long.append([b, common, "REM_sleep_pct", float(val), "percent",
                 "Eagleman_Vaughn_2021_TABLE1", "Eagleman_2021", "Table1", conf, "REM_pct"])

hh, hr = read_tsv(HH); i_hsp = hh.index("species"); i_slp = hh.index("daily.sleep..h.")
for row in hr:
    sp, val = row[i_hsp], row[i_slp]
    if val in ("", "NA"):
        continue
    long.append([hh_alias.get(sp, sp), sp, "Sleep_h_day", float(val), "hours/day",
                 "HerculanoHouzel__2015_Table1", "HerculanoHouzel_2015", "Table1", "high", "dailysleep"])

with open(os.path.join(HERE, "sleep_long.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["Species", "Species_printed", "Standardized_Term", "Value", "Units",
                "source", "team", "ref", "species_confidence", "dependency_group"])
    w.writerows(long)

sp_all = sorted(set(r[0] for r in long))
rem = {r[0]: r for r in long if r[2] == "REM_sleep_pct"}
slp = {r[0]: r for r in long if r[2] == "Sleep_h_day"}
with open(os.path.join(HERE, "sleep_wide.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["Species", "REM_sleep_pct", "Sleep_h_day", "source_REM_sleep_pct",
                "source_Sleep_h_day", "n_traits", "REM_species_confidence"])
    for s in sp_all:
        rr, ss = rem.get(s), slp.get(s)
        w.writerow([s, rr[3] if rr else "", ss[3] if ss else "",
                    "Eagleman_Vaughn_2021_TABLE1" if rr else "",
                    "HerculanoHouzel__2015_Table1" if ss else "",
                    (1 if rr else 0) + (1 if ss else 0), rr[8] if rr else ""])

with open(os.path.join(HERE, "sleep_source_species_ids.csv"), "w", newline="") as f:
    w = csv.writer(f)
    w.writerow(["source", "Species", "Species_printed", "Standardized_Term", "Value", "species_confidence"])
    for r in long:
        w.writerow([r[5], r[0], r[1], r[2], r[3], r[8]])

print(f"sleep: {len(long)} long rows "
      f"({sum(1 for r in long if r[2]=='REM_sleep_pct')} REM, "
      f"{sum(1 for r in long if r[2]=='Sleep_h_day')} daily-sleep), "
      f"{len(sp_all)} species ({sum(1 for s in sp_all if s in rem and s in slp)} with both traits)")
