#!/usr/bin/env python3
"""
Build the __merging_metabolic compilation-aware merge.

Design (confirmed with curator):
  * BRAIN-ONLY: regional + whole-brain cerebral metabolic rate. No body/basal MR.
  * Measures: CMRgl, CMRO2 (umol/100g/min) and CBF (mL/100g/min).
  * COMPILATION-AWARE: Kaufman 2004 (A1-A14, per-study) and Karbowski 2007 (S1-S23,
    per-primary-reference rows) are both SECONDARY compilations of other labs' primary
    measurements. Rather than averaging their published species-means as if independent
    (which double-counts primary studies they share), we pull each compilation down to
    the PRIMARY-STUDY level, dedupe studies that appear in both (by first-author+year),
    and average across the DISTINCT primary studies. Heiss 2004 is a genuine primary.

R is unavailable in this build environment, so the CSVs are generated here in Python;
metabolic_compiled.R / standardized_term.R are shipped as the house-style reproducible
equivalents (same pattern as the Karbowski build).
"""
import pandas as pd, numpy as np, glob, re, os

BASE = "/sessions/peaceful-tender-rubin/mnt/Evo-M1-Trait-Data"
OUT  = os.path.join(BASE, "__merging_metabolic")
STBR = os.path.join(OUT, "standardized_term_by_reference")
os.makedirs(STBR, exist_ok=True)

# ----------------------------------------------------------------------------------
# Crosswalks
# ----------------------------------------------------------------------------------
REGION_CANON = {
    # whole brain
    "Whole Brain (direct measurement)": "Whole_brain", "Brain": "Whole_brain",
    "Whole Brain": "Whole_brain",
    # neocortex / cerebral cortex (global)
    "Neocortex": "Neocortex", "Cerebral cortex": "Neocortex",
    "Cerebral cortex (global average)": "Neocortex", "Cortex": "Neocortex",
    # cortical subregions
    "Frontal Cortex": "Frontal_cortex", "Frontal cortex": "Frontal_cortex", "Frontal lobe": "Frontal_cortex",
    "Prefrontal cortex": "Prefrontal_cortex",
    "Parietal Cortex": "Parietal_cortex", "Parietal cortex": "Parietal_cortex", "Parietal lobe": "Parietal_cortex",
    "Temporal Cortex": "Temporal_cortex", "Temporal cortex": "Temporal_cortex", "Temporal lobe": "Temporal_cortex",
    "Occipital Cortex": "Occipital_cortex", "Occipital cortex": "Occipital_cortex", "Occipital lobe": "Occipital_cortex",
    "Visual cortex": "Visual_cortex",
    "Auditory Cortex": "Auditory_cortex",
    "Sensorimotor Cortex": "Sensorimotor_cortex", "Sensorimotor cortex": "Sensorimotor_cortex",
    "Cingulate Cortex": "Cingulate_cortex", "Cingulate cortex": "Cingulate_cortex",
    "Insular lobe": "Insula",
    # subcortical / deep
    "Thalamus": "Thalamus", "Nucleus medial thalami": "Thalamus_medial_nucleus",
    "Hypothalamus": "Hypothalamus",
    "Hippocampus": "Hippocampus",
    "Amygdala": "Amygdala", "Corpus amygdaloideum": "Amygdala",
    "Septum": "Septum",
    "Basal Ganglia": "Basal_ganglia",             # Kaufman aggregate (NOT 1:1 with the split nuclei)
    "Caudate": "Caudate_nucleus", "Caudatum": "Caudate_nucleus",
    "Putamen": "Putamen",
    "Globus pallidus": "Pallidum", "Pallidum": "Pallidum",
    "Nucleus accumbens": "Nucleus_accumbens",
    "Substantia nigra": "Substantia_nigra",
    "Nucleus subthalamicus": "Nucleus_subthalamicus",
    "Nucleus ruber": "Nucleus_ruber",
    "Basal forebrain": "Basal_forebrain",
    "Corpus geniculatum laterale": "Corpus_geniculatum_laterale",
    "Corpus geniculatum mediale": "Corpus_geniculatum_mediale",
    "Colliculus superior": "Colliculus_superior", "Colliculus inferior": "Colliculus_inferior",
    # cerebellum / brainstem / white matter
    "Cerebellum": "Cerebellum", "Cerebellar cortex": "Cerebellar_cortex",
    "Nucleus dentatus cerebelli": "Nucleus_dentatus_cerebelli", "Vermis": "Vermis",
    "Brain stem": "Brain_stem",
    "White Matter": "White_matter", "White matter": "White_matter",
    "Capsula interna": "Capsula_interna", "Centrum semiovale": "Centrum_semiovale",
}

# canonical region -> volume-merge term (only where one clean counterpart exists)
VOLUME_TERM = {
    "Neocortex": "Neocortex_Vol.mm3", "Cerebellum": "Cerebellum_Vol.mm3",
    "Thalamus": "Thalamus_Vol.mm3", "Hippocampus": "Hippocampus_Vol.mm3",
    "Amygdala": "Amygdala_Vol.mm3", "Pallidum": "Pallidum_Vol.mm3",
    "Nucleus_subthalamicus": "Nucleus_subthalamicus_Vol.mm3",
    "Corpus_geniculatum_laterale": "Corpus_geniculatum_laterale_Vol.mm3",
    "Whole_brain": "Total_brain_net_volume_Vol.mm3",
}

# accepted species name; preserve printed name separately.
# Kaufman genus labels -> the standard lab binomial (same animals Karbowski names);
# generic "Macaca" kept as Macaca sp. (Kaufman also lists M mulatta / M fascic explicitly).
SPECIES_CANON = {
    "Homo": "Homo sapiens", "Homo sapiens": "Homo sapiens",
    "M mulatta": "Macaca mulatta", "M fascic": "Macaca fascicularis",
    "Macaca": "Macaca sp.", "Macaca mulatta": "Macaca mulatta",
    "Papio": "Papio anubis", "Papio anubis": "Papio anubis",
    "Saimiri": "Saimiri sciureus",
    "Canis": "Canis lupus familiaris", "Canis lupus familiaris": "Canis lupus familiaris",
    "Felis": "Felis catus", "Felis catus": "Felis catus",
    "Rattus": "Rattus norvegicus", "Rattus norvegicus": "Rattus norvegicus",
    "Mus": "Mus musculus", "Mus musculus": "Mus musculus",
    "Meriones": "Meriones unguiculatus", "Gerbil": "Meriones unguiculatus",
    "Ovis": "Ovis aries", "Ovis aries": "Ovis aries",
    "Capra": "Capra aegagrus hircus", "Capra aegagrus hircus": "Capra aegagrus hircus",
    "Sus": "Sus scrofa",
    "Equus": "Equus caballus",
    "Lepus": "Lepus sp.",
    "Spermophilus tridecemlineatus": "Spermophilus tridecemlineatus",
    "Oryctolagus cuniculus": "Oryctolagus cuniculus",
}
# genus-level Kaufman labels (binomial assigned by standard-lab-species convention, flagged)
KAUFMAN_GENUS_ASSIGNED = {"Homo","Papio","Canis","Felis","Rattus","Mus","Meriones",
                          "Gerbil","Ovis","Capra","Sus","Equus","Lepus","Saimiri"}

MEASURE_UNITS = {"CMRgl": "umol/100g/min", "CMRO2": "umol/100g/min", "CBF": "mL/100g/min"}

def ref_key(s):
    """first-author surname + 4-digit year -> lowercase token, e.g. '(Baxter et al., 1987)'->'baxter1987'."""
    if s is None or (isinstance(s, float) and np.isnan(s)): return None
    s = str(s).strip()
    if s.lower().startswith("present study") or "present study" in s.lower():
        return "kaufman2004_present"
    s = s.strip("()").strip()
    yr = re.search(r'(1[89]\d\d|20\d\d)', s)
    year = yr.group(1) if yr else "NA"
    # surname = first alphabetic token
    m = re.search(r"[A-Za-zÀ-ſ']+", s)
    sur = m.group(0).lower() if m else "anon"
    return f"{sur}{year}"

def ref_keys_multi(s):
    """Karbowski joins multiple refs with ';'. Return list of ref_keys."""
    if s is None or (isinstance(s, float) and np.isnan(s)): return []
    return [ref_key(part) for part in re.split(r';', str(s)) if part.strip()]

def conscious_flag_kaufman(anes):
    if anes is None or (isinstance(anes, float) and np.isnan(anes)): return "unknown"
    a = str(anes).strip().lower()
    if a.startswith("none") or "awake" in a: return "conscious"
    return "anesthetized"

# ----------------------------------------------------------------------------------
# 1. Load & normalise each source to primary-study level
#    columns: Compilation, Species_printed, Species, genus, Region_raw, Region,
#             Measure, Value(=per 100g), SD, n, conscious, ref_raw, ref_keys(list), Units, Table
# ----------------------------------------------------------------------------------
recs = []

# --- Kaufman A1-A14 (per-study) ---
kfiles = [f for f in glob.glob(os.path.join(BASE, "Kaufman__2004/Kaufman__2004_TableA*.csv"))
          if re.search(r'A(\d+)\.csv$', f) and int(re.search(r'A(\d+)\.csv$', f).group(1)) <= 14]
for f in sorted(kfiles, key=lambda p:int(re.search(r'A(\d+)',p).group(1))):
    tbl = re.search(r'(TableA\d+)', f).group(1)
    d = pd.read_csv(f)
    for _, r in d.iterrows():
        sp_print = str(r["Species"]).strip()
        genus = sp_print.split()[0] if sp_print and not sp_print.startswith("M ") else {"M mulatta":"Macaca","M fascic":"Macaca"}.get(sp_print, sp_print)
        genus = {"Gerbil":"Meriones"}.get(genus, genus)
        acc = SPECIES_CANON.get(sp_print, SPECIES_CANON.get(genus, sp_print))
        reg_raw = str(r["Region"]).strip()
        reg = REGION_CANON.get(reg_raw, reg_raw)
        con = conscious_flag_kaufman(r.get("Anesthesia"))
        rk = ref_key(r.get("Reference"))
        for meas, vcol, scol, unit in [("CMRgl","CMRgl_umol_100g_min","CMRgl_SD","umol/100g/min"),
                                       ("CMRO2","CMRO2_umol_100g_min","CMRO2_SD","umol/100g/min"),
                                       ("CBF","CBF_ml_100g_min","CBF_SD","mL/100g/min")]:
            v = pd.to_numeric(r.get(vcol), errors="coerce")
            if pd.isna(v): continue
            recs.append(dict(Compilation="Kaufman_2004", Species_printed=sp_print, Species=acc,
                             genus=genus, Region_raw=reg_raw, Region=reg, Measure=meas,
                             Value=float(v), SD=pd.to_numeric(r.get(scol), errors="coerce"),
                             n=pd.to_numeric(r.get("n"), errors="coerce"), conscious=con,
                             ref_raw=str(r.get("Reference")), ref_keys=[rk] if rk else [],
                             Units=unit, Table=tbl))

# --- Karbowski S1-S23 (primary rows only; drop 'average' rows and Total_* whole-brain absolutes) ---
kbfiles = sorted(glob.glob(os.path.join(BASE, "Karbowski__2007/Karbowski__2007_TableS*.csv")),
                 key=lambda p:int(re.search(r'S(\d+)',p).group(1)))
for f in kbfiles:
    tbl = re.search(r'(TableS\d+)', f).group(1)
    d = pd.read_csv(f)
    for _, r in d.iterrows():
        if bool(r.get("is_average")): continue                         # drop Karbowski's own averages
        meas = str(r.get("measure")).strip()
        if meas not in ("CMRgl", "CMRO2"): continue                    # skip Total_* absolutes
        sp_print = str(r.get("species_printed")).strip()
        acc = str(r.get("species")).strip()                            # already harmonised binomial
        acc = SPECIES_CANON.get(acc, acc)
        genus = acc.split()[0]
        reg_raw = str(r.get("structure")).strip()
        reg = REGION_CANON.get(reg_raw, reg_raw)
        v = pd.to_numeric(r.get("value"), errors="coerce")
        if pd.isna(v): continue
        v100 = float(v) * 100.0                                        # per g -> per 100 g
        sd = pd.to_numeric(r.get("sd"), errors="coerce")
        sd = sd*100.0 if pd.notna(sd) else np.nan
        recs.append(dict(Compilation="Karbowski_2007", Species_printed=sp_print, Species=acc,
                         genus=genus, Region_raw=reg_raw, Region=reg, Measure=meas,
                         Value=v100, SD=sd, n=np.nan, conscious="unknown",
                         ref_raw=str(r.get("reference")), ref_keys=ref_keys_multi(r.get("reference")),
                         Units=MEASURE_UNITS[meas], Table=tbl))

# --- Heiss 2004 (primary; Homo regional CMRgl) ---
h = pd.read_csv(os.path.join(BASE, "Heiss_etal_2004/Heiss_etal_2004_TABLE1.csv"))
for _, r in h.iterrows():
    v = pd.to_numeric(r.get("Both hemispheres Mean"), errors="coerce")
    if pd.isna(v): continue
    reg_raw = str(r.get("Region")).strip()
    reg = REGION_CANON.get(reg_raw, reg_raw)
    recs.append(dict(Compilation="Heiss_etal_2004", Species_printed="Homo sapiens", Species="Homo sapiens",
                     genus="Homo", Region_raw=reg_raw, Region=reg, Measure="CMRgl",
                     Value=float(v), SD=pd.to_numeric(r.get("Both hemispheres SD"), errors="coerce"),
                     n=np.nan, conscious="conscious", ref_raw="Heiss et al 2004",
                     ref_keys=["heiss2004"], Units="umol/100g/min", Table="TABLE1"))

U = pd.DataFrame(recs)
U["ref_keys_str"] = U["ref_keys"].apply(lambda L: ";".join([x for x in L if x]))
print(f"[unfiltered] {len(U)} primary-study rows | compilations: "
      f"{U['Compilation'].value_counts().to_dict()}")

# report any unmapped regions
unmapped = sorted(set(U.loc[U['Region']==U['Region_raw'],'Region_raw']) - set(REGION_CANON.values()))
if unmapped:
    print("  [warn] regions passed through unmapped:", unmapped)

# ----------------------------------------------------------------------------------
# 2. Unfiltered long table (every primary-study datum, full provenance)
# ----------------------------------------------------------------------------------
U_out = U[["Species","Species_printed","Compilation","Table","Region","Region_raw",
           "Measure","Value","SD","n","Units","conscious","ref_raw","ref_keys_str"]].copy()
U_out = U_out.sort_values(["Measure","Species","Region","Compilation"]).reset_index(drop=True)
U_out.to_csv(os.path.join(OUT, "metabolic_unfiltered.csv"), index=False)

# ----------------------------------------------------------------------------------
# 3. Filter for the merged means: drop explicitly anesthetized (match Kaufman's
#    conscious-only species-mean convention). conscious + unknown are kept.
# ----------------------------------------------------------------------------------
F = U[U["conscious"] != "anesthetized"].copy()
print(f"[filter] dropped {len(U)-len(F)} anesthetized rows; {len(F)} kept")

# ----------------------------------------------------------------------------------
# 4. Compilation-aware dedupe of shared primary studies.
#    Within (Species, Region, Measure): if a primary ref_key is reported by >1
#    compilation, keep the Kaufman datum (study-level, conscious-confirmed) and drop the
#    Karbowski duplicate. Record every collision.
# ----------------------------------------------------------------------------------
dedupe_rows = []
drop_idx = set()
COMP_PRIORITY = {"Kaufman_2004": 0, "Heiss_etal_2004": 1, "Karbowski_2007": 2}  # keep lower
for (sp, reg, meas), g in F.groupby(["Species","Region","Measure"]):
    # map ref_key -> list of (idx, compilation)
    key_map = {}
    for idx, row in g.iterrows():
        for k in row["ref_keys"]:
            if k: key_map.setdefault(k, []).append((idx, row["Compilation"]))
    for k, hits in key_map.items():
        comps = sorted(set(c for _, c in hits))
        if len(comps) > 1:                                            # shared across compilations
            # keep the highest-priority compilation's row(s); drop the rest for this key
            best = min(comps, key=lambda c: COMP_PRIORITY[c])
            kept = [i for i, c in hits if c == best]
            dropped = [i for i, c in hits if c != best]
            for i in dropped: drop_idx.add(i)
            dedupe_rows.append(dict(Species=sp, Region=reg, Measure=meas, shared_ref=k,
                                    reported_by="; ".join(comps), kept=best,
                                    dropped="; ".join(sorted(set(c for i,c in hits if c!=best)))))
D = F.drop(index=[i for i in drop_idx if i in F.index]).copy()
dedupe_report = pd.DataFrame(dedupe_rows).sort_values(["Species","Region","Measure"]) if dedupe_rows else \
                pd.DataFrame(columns=["Species","Region","Measure","shared_ref","reported_by","kept","dropped"])
dedupe_report.to_csv(os.path.join(OUT, "metabolic_dedupe_report.csv"), index=False)
print(f"[dedupe] {len(dedupe_report)} shared primary-study collisions removed "
      f"({len(F)-len(D)} rows dropped)")

# ----------------------------------------------------------------------------------
# 5. Aggregate to Species x Region x Measure.
#    a) study-mean: average within (Species,Region,Measure,ref_keys_str) -> one value per study
#    b) merged mean: average across distinct studies
# ----------------------------------------------------------------------------------
D["study_id"] = D["ref_keys_str"].where(D["ref_keys_str"] != "", D["Compilation"] + ":" + D["Table"])
study = (D.groupby(["Species","Region","Measure","Units","study_id"], as_index=False)
           .agg(Value=("Value","mean"),
                Compilation=("Compilation", lambda s: "; ".join(sorted(set(s))))))
merged = (study.groupby(["Species","Region","Measure","Units"], as_index=False)
                .agg(Value=("Value","mean"),
                     n_studies=("study_id","nunique"),
                     Compilations=("Compilation", lambda s: "; ".join(sorted(set(
                         c for x in s for c in x.split("; ")))))))
merged["Volume_term"] = merged["Region"].map(VOLUME_TERM)
merged = merged.sort_values(["Species","Region","Measure"]).reset_index(drop=True)
merged["Value"] = merged["Value"].round(3)
merged.to_csv(os.path.join(OUT, "metabolic_long.csv"), index=False)
print(f"[merged] {len(merged)} cells | {merged['Species'].nunique()} species | "
      f"{merged['Region'].nunique()} regions")

# ----------------------------------------------------------------------------------
# 6. Wide view (one row per species; col = Region__Measure)
# ----------------------------------------------------------------------------------
w = merged.assign(col=merged["Region"]+"__"+merged["Measure"]) \
          .pivot_table(index="Species", columns="col", values="Value", aggfunc="first") \
          .sort_index()
w.to_csv(os.path.join(OUT, "metabolic_wide.csv"))
print(f"[wide] {w.shape[0]} species x {w.shape[1]} region-measure cols")

# ----------------------------------------------------------------------------------
# 7. Species id / crosswalk table
# ----------------------------------------------------------------------------------
sid = (U.groupby(["Species","Species_printed","Compilation"]).size()
         .reset_index(name="n_rows"))
sid_wide = (sid.groupby(["Species","Species_printed"])
              .agg(Compilations=("Compilation", lambda s: "; ".join(sorted(set(s)))),
                   n_rows=("n_rows","sum")).reset_index())
def note(row):
    n=[]
    if row["Species_printed"] in KAUFMAN_GENUS_ASSIGNED:
        n.append("Kaufman genus label; binomial assigned by standard-lab-species convention")
    if row["Species_printed"]=="Macaca":
        n.append("generic Macaca kept as Macaca sp. (Kaufman also lists M mulatta / M fascic)")
    return "; ".join(n)
sid_wide["note"] = sid_wide.apply(note, axis=1)
sid_wide = sid_wide.sort_values(["Species","Species_printed"])
sid_wide.to_csv(os.path.join(OUT, "metabolic_source_species_ids.csv"), index=False)
print(f"[species] {sid_wide['Species'].nunique()} accepted species from "
      f"{len(sid_wide)} printed labels")

# ----------------------------------------------------------------------------------
# 8. standardized_term_by_reference/*.csv  (Original_Term, Reference, Standardized_Term)
#    + stacked standardized_term_metabolic.csv
# ----------------------------------------------------------------------------------
def write_terms(reference, mapping):
    df = pd.DataFrame([(o, reference, s) for o, s in mapping], columns=["Original_Term","Reference","Standardized_Term"])
    df.to_csv(os.path.join(STBR, f"{reference}_standardized_terms.csv"), index=False)
    return df

term_frames = []
# Kaufman: region label -> canonical region; the measure columns -> canonical measure
kauf_terms = [("Species","Species")]+[(r, REGION_CANON.get(r,r)) for r in sorted(U[U.Compilation=='Kaufman_2004'].Region_raw.unique())]
kauf_terms += [("CMRgl_umol_100g_min","CMRgl"),("CMRO2_umol_100g_min","CMRO2"),("CBF_ml_100g_min","CBF")]
term_frames.append(write_terms("Kaufman__2004_TableA1-A14", kauf_terms))
karb_terms = [("species","Species")]+[(r, REGION_CANON.get(r,r)) for r in sorted(U[U.Compilation=='Karbowski_2007'].Region_raw.unique())]
karb_terms += [("CMRgl","CMRgl"),("CMRO2","CMRO2")]
term_frames.append(write_terms("Karbowski__2007_TableS1-S23", karb_terms))
heiss_terms = [("Region","Species→Region")]+[(r, REGION_CANON.get(r,r)) for r in sorted(U[U.Compilation=='Heiss_etal_2004'].Region_raw.unique())]
heiss_terms += [("Both hemispheres Mean","CMRgl")]
term_frames.append(write_terms("Heiss_etal_2004_TABLE1", heiss_terms))
pd.concat(term_frames, ignore_index=True).to_csv(os.path.join(OUT,"standardized_term_metabolic.csv"), index=False)
print("[terms] wrote per-reference standardized-term files + stacked standardized_term_metabolic.csv")

print("\nDONE. Outputs in __merging_metabolic/")
