#!/usr/bin/env python3
import csv, re, os
BASE="/sessions/sweet-adoring-galileo/mnt/Kaufman__2004"
ADDED=os.path.join(BASE,"comparison","Kaufman data added to compilation")
GOBF=os.path.join(ADDED,"Kaufman glucose oxygen blood flow")
BUILT="/sessions/sweet-adoring-galileo/mnt/outputs/Kaufman__2004_A15_tidy.csv"
OUTDIR="/sessions/sweet-adoring-galileo/mnt/outputs"

def squish(s): return re.sub(r"\s+"," ",s).strip()
def norm_measure(m): return "CMRO2" if m in ("CMR02","CMRQ2") else m
def to_num(x):
    if x is None: return None
    x=str(x).strip().replace(",","")
    if x=="" or x.upper()=="NA": return None
    try: return float(x)
    except: return None

STATS_RE=r"(N|Mean|Std Deviation|CV_unbiased|CV)"
def canon_stat(s):
    return {"Std Deviation":"SD","CV_unbiased":"CVstar"}.get(s,s)
def parse_col(col):
    """Return (region,measure,stat,weighting or None) from a wide column name."""
    t=squish(col.replace("."," ").replace("_"," _"))  # keep CV_unbiased detectable
    t=col.replace("."," ")
    t=squish(t)
    weighting=None
    m=re.search(r"\b(weighted|unweighted)\b$",t)
    if m: weighting=m.group(1); t=squish(t[:m.start()])
    m=re.search(r"\b(N|Mean|Std\s+Deviation|CV_unbiased|CV)$",t)
    if not m: return None
    stat=canon_stat(squish(m.group(1)))
    t=squish(t[:m.start()])
    m=re.search(r"\b(CMRgl|CMR02|CMRO2|CMRQ2|CBF)$",t)
    if not m: return None
    measure=norm_measure(m.group(1))
    region=squish(t[:m.start()])
    return region,measure,stat,weighting

# ---- built dataset ----
built={}
for r in csv.DictReader(open(BUILT)):
    key=(r["species"],r["weighting"],r["region"],r["measure"])
    built.setdefault(key,{})
    for st in ("N","Mean","SD","CV","CVstar"):
        built[key][st]=to_num(r[st])

# ---- manual: weights (one row per species, both weightings) ----
def load_weights():
    out={}
    for r in csv.DictReader(open(os.path.join(ADDED,"Kaufman_energetics_weights.csv"))):
        genus=r["Kaufman.Species"]
        for col,val in r.items():
            if col in ("Species","Kaufman.Species"): continue
            p=parse_col(col)
            if not p: continue
            region,measure,stat,weighting=p
            if weighting is None: continue
            key=(genus,weighting,region,measure)
            out.setdefault(key,{})[stat]=to_num(val)
    return out

# ---- manual: wholebrain + partsbrain (one row per species x weighting) ----
def load_wb_pb():
    out={}
    for fn,wcol in [("wholebrain_Kaufman2004.csv","weight"),("partsbrain_Kaufman2004.csv","Weight")]:
        for r in csv.DictReader(open(os.path.join(GOBF,fn))):
            genus=r["Species"]; weighting=squish(r[wcol]).lower()
            for col,val in r.items():
                if col in ("Speciesweight","Species","weight","Weight"): continue
                p=parse_col(col)
                if not p: continue
                region,measure,stat,_=p
                key=(genus,weighting,region,measure)
                out.setdefault(key,{})[stat]=to_num(val)
    return out

weights=load_weights()
wbpb=load_wb_pb()

STAT_ORDER=["N","Mean","SD","CV","CVstar"]
def compare(manual, tag):
    rows=[]; nmatch=0; nmis=0; man_only=0; built_only=0; ncmp=0
    allkeys=set(built)|set(manual)
    for key in sorted(allkeys):
        b=built.get(key,{}); m=manual.get(key,{})
        for st in STAT_ORDER:
            bv=b.get(st); mv=m.get(st)
            in_b = key in built and bv is not None
            in_m = key in manual and mv is not None
            if not in_b and not in_m: continue
            status=""; diff=""
            if in_b and in_m:
                ncmp+=1
                tol = 0 if st=="N" else 0.011
                d=abs(bv-mv)
                if d<=tol: status="match"; nmatch+=1
                else: status="MISMATCH"; nmis+=1; diff=round(bv-mv,4)
            elif in_b and not in_m:
                status="built_only"; built_only+=1
            else:
                status="manual_only"; man_only+=1
            rows.append(dict(source=tag,species=key[0],weighting=key[1],region=key[2],
                measure=key[3],stat=st,built=bv,manual=mv,status=status,diff=diff))
    summary=dict(source=tag,compared=ncmp,match=nmatch,mismatch=nmis,
                 built_only=built_only,manual_only=man_only)
    return rows,summary

all_rows=[]; summaries=[]
for man,tag in [(weights,"weights_compilation"),(wbpb,"wholebrain+partsbrain")]:
    rows,summ=compare(man,tag); all_rows+=rows; summaries.append(summ)

# write full comparison
cols=["source","species","weighting","region","measure","stat","built","manual","status","diff"]
with open(os.path.join(OUTDIR,"Kaufman__2004_A15_comparison_long.csv"),"w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=cols); w.writeheader(); w.writerows(all_rows)
with open(os.path.join(OUTDIR,"Kaufman__2004_A15_comparison_mismatches.csv"),"w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=cols); w.writeheader()
    w.writerows([r for r in all_rows if r["status"] in ("MISMATCH","built_only","manual_only")])

print("BUILT cells:",sum(len(v) for v in built.values()),"in",len(built),"keys")
for s in summaries: print(s)
print("\n--- MISMATCH rows ---")
for r in all_rows:
    if r["status"]=="MISMATCH":
        print(f'{r["source"]:22} {r["species"]:9} {r["weighting"]:10} {r["region"]:18} {r["measure"]:6} {r["stat"]:6} built={r["built"]} manual={r["manual"]} diff={r["diff"]}')
print("\n--- built_only (in PDF build, absent in manual) ---")
for r in all_rows:
    if r["status"]=="built_only":
        print(f'{r["source"]:22} {r["species"]:9} {r["weighting"]:10} {r["region"]:18} {r["measure"]:6} {r["stat"]:6} built={r["built"]}')
print("\n--- manual_only (in manual, absent in PDF build) ---")
for r in all_rows:
    if r["status"]=="manual_only":
        print(f'{r["source"]:22} {r["species"]:9} {r["weighting"]:10} {r["region"]:18} {r["measure"]:6} {r["stat"]:6} manual={r["manual"]}')
