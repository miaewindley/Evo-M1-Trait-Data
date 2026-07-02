#!/usr/bin/env python3
"""Faithful Python port of volumes_compiled.R's per-paper -> long step, used ONLY to
verify (no R available) that: (a) the Sherwood_2004 crash is gone, (b) every core paper
yields a character Species column so bind_rows succeeds, and (c) the fixed `keep` never
coerces a species column to numeric. Mirrors read_item + reshapes + generic wide->long."""
import re, pandas as pd, numpy as np
BASE="/sessions/zen-vibrant-albattani/mnt/Evo-M1-Trait-Data"
MV=f"{BASE}/__merging_volumes"

papers=[  # item, team, year, token, spcol  (the canonical 30 after the edit)
 ("Stephan_etal_1970_Tables1-6","Stephan_collection",1970,"Stephan1970","species"),
 ("Stephan_etal_1981_TablesI-VI","Stephan_collection",1981,"Stephan1981","Species_Stephan1981"),
 ("Stephan_etal_1982_Table1","Stephan_collection",1982,"Stephan1982","Species_Stephan1982"),
 ("Stephan_etal_1984_Table1","Stephan_collection",1984,"Stephan1984","Species_Stephan1984"),
 ("Stephan_etal_1987_Table1","Stephan_collection",1987,"Stephan1987","Species_Stephan1987"),
 ("Frahm_etal_1982_Table2","Stephan_collection",1982,"Frahm1982","Species_Frahm1982"),
 ("Frahm_etal_1984_Table1","Stephan_collection",1984,"Frahm_1984","Species_Frahm_1984"),
 ("Frahm_Zilles_1994_Table1","Stephan_collection",1994,"Frahm1994","Species_Frahm1994"),
 ("Frahm_etal_1997_Table1","Stephan_collection",1997,"Frahm1997","Species_Frahm1997"),
 ("Frahm_etal_1998_Table1","Stephan_collection",1998,"Frahm98","Species_Frahm98"),
 ("Baron_etal_1983_Table1","Stephan_collection",1983,"Baron1983","Species_Baron1983"),
 ("Baron_etal_1987_Table1","Stephan_collection",1987,"Baron1987","Species_Baron1987"),
 ("Baron_etal_1988_Table1","Stephan_collection",1988,"Baron1988","Species_Baron1988"),
 ("Baron_etal_1990_Table1","Stephan_collection",1990,"Baron1990","Species_Baron1990"),
 ("Matano_etal_1985_a_Table1","Stephan_collection",1985,"Matano1985a","Species_Matano1985a"),
 ("Matano_etal_1985_b_Table1","Stephan_collection",1985,"Matano1985b","Species_Matano1985b"),
 ("Zilles_Rehkämper_1988_Table12-2","Stephan_collection",1988,"Zilles1988","Species_Zilles1988"),
 ("deSousa_etal_2010_Table1","Zilles",2010,"deSousa2010","Species_deSousa2010"),
 ("deSousa_etal_2013_Table1","Zilles",2013,"deSousa2013","Species_deSousa2013"),
 ("MacLeod_etal_2003_","Zilles",2003,None,"species"),
 ("Bauernfeind_etal_2013_Table1","Zilles",2013,"Bauernfeind2013","Species_Bauernfeind2013"),
 ("Bauernfeind_etal_2013_Table2","Zilles",2013,"Bauernfeind2013","Species_Bauernfeind2013"),
 ("Bush_Allman_2003_Table1","Bush",2003,"Bush_Allman_2003","species"),
 ("Bush_Allman_2004_b_TABLE1","Bush",2004,"Bush_Allman_2004_b","species"),
 ("Smaers_etal_2011_SupplementaryTable1","Zilles",2011,None,"species"),
 ("Ashwell__2020_SupplementaryTable","Ashwell",2020,"Ashwell2020","species"),
 ("Semendeferi_etal_1998_Table2","Semendeferi",1998,"Semendeferi","species"),
 ("Semendeferi_etal_2001_Table2","Semendeferi",2001,"Semendeferi","species"),
 ("Sherwood_etal_2005_Table1","Sherwood",2005,"Sherwood_2005","species"),
 ("Barger_etal_2007_TABLE1","Zilles",2007,"Barger2007","species"),
]
enc_override={
 "Bauernfeind_etal_2013_Table2":"10.1016%2Fj.jhevol.2012.12.003_Table2",
 "Stephan_etal_1970_Tables1-6":"ISBN%3A0390672505_Tables1-6",
 "MacLeod_etal_2003_":"10.1016%2Fs0047-2484(03)00028-9_Table1",
 "Semendeferi_etal_1998_Table2":"10.1002%2F(SICI)1096-8644(199806)106%3A2%3C129%3A%3AAID-AJPA3%3E3.0.CO;2-L_TABLE2",
 "Semendeferi_etal_2001_Table2":"10.1002%2F1096-8644(200103)114%3A3%3C224%3A%3AAID-AJPA1022%3E3.0.CO;2-I_TABLE2",
}
fc=pd.read_excel(f"{BASE}/__ReadMe.xlsx",sheet_name="Sheet1")
def normn(x): return re.sub(" ","",str(x).lower())
fc_name=fc["Item name"].map(normn); fc_enc=fc["Item encoded"].astype(str)
def read_item(it):
    m=fc_name[fc_name==normn(it)]
    enc=None
    if len(m): enc=re.sub(" ","",fc_enc[m.index[0]])
    if (enc is None or enc=="" or enc=="nan") and it in enc_override: enc=enc_override[it]
    p=f"{BASE}/__Public/comparative-data/{enc}.tsv"
    import os
    if it in enc_override and not os.path.exists(p): enc=enc_override[it]; p=f"{BASE}/__Public/comparative-data/{enc}.tsv"
    return pd.read_csv(p,sep="\t",dtype=str,keep_default_na=True)

terms=pd.read_csv(f"{MV}/standardized_term_volumes.csv")
# species keys
keys=pd.concat([pd.read_csv(f"{BASE}/_keys/{k}/species_key.csv") for k in ("Stephan","Allman","Ashwell")],ignore_index=True)
def nrm(x):
    return re.sub(r"\s+"," ",re.sub(r"[._]"," ",str(x))).strip().lower()
def accepted(tok,series):
    if tok is None: return series.astype(str)
    k=keys[keys.source_publication==tok]
    look={nrm(v):a for v,a in zip(k.variant_name,k.accepted_name)}
    return series.astype(str).map(lambda n: look.get(nrm(n),n))
def num(s): return pd.to_numeric(s.astype(str).str.replace(",","",regex=False),errors="coerce")

results=[]; longs=[]
for it,team,year,tok,spcol in papers:
    df=read_item(it); tmap=terms[terms.Reference==it]
    # reshapes that the generic path depends on (species-affecting / mass ones)
    if it=="Stephan_etal_1987_Table1" and "Nucleus_tractus_olfactorius_mm3" in df:
        v=num(df["Nucleus_tractus_olfactorius_mm3"]); df["Nucleus_tractus_olfactorius_mm3"]=v.mask(v==0)
    if it=="MacLeod_etal_2003_":
        meas=["cerebellum_volume_cm3","vermis_volume_cm3","hemisphere_volume_cm3","brain_volume_cm3"]
        df=df.groupby("species",as_index=False)[meas].agg(lambda c:(num(c)*1000).mean())
    if it in ("Bush_Allman_2003_Table1","Bush_Allman_2004_b_TABLE1"):
        for c in [c for c in df if c.endswith("_cm3")]: df[c]=num(df[c])*1000
    if it=="Barger_etal_2007_TABLE1":
        meas=["hemispheres_cm3","AC_total","BLD_total","lateral_total","basal_total","accessory_basal_total"]
        meas=[m for m in meas if m in df]
        df=df.groupby("species",as_index=False)[meas].agg(lambda c:(num(c)*1000).mean())
    # (Zilles/Bauernfeind/Smaers have bespoke long builders; for the dtype check we still
    #  run the generic path on their raw frame, which is enough to detect species coercion.)
    spcol_present = spcol in df.columns
    interm = spcol in set(tmap.Original_Term)
    keep_old=[c for c in df.columns if c in set(tmap.Original_Term)]              # buggy
    keep_new=[c for c in keep_old if c!=spcol]                                    # fixed
    would_break = (spcol in keep_old)
    # generic build with FIX
    if spcol_present:
        out=pd.DataFrame({"Species":accepted(tok,df[spcol])})
        for c in keep_new: out[c]=num(df[c])
        m=out.melt("Species",var_name="orig",value_name="Value").dropna(subset=["Value"])
        longs.append(m.assign(Source=it))
        sp_dtype=str(out["Species"].dtype)
    else:
        sp_dtype="(spcol absent: bespoke reshape)"
    results.append((it,spcol,spcol_present,interm,would_break,sp_dtype))

print(f"{'item':38}{'spcol':22}{'present':8}{'inTerms':8}{'OLD_break':10}{'Species dtype(FIX)'}")
for r in results:
    print(f"{r[0]:38}{r[1]:22}{str(r[2]):8}{str(r[3]):8}{str(r[4]):10}{r[5]}")
bad=[r for r in results if r[5] not in ("object","(spcol absent: bespoke reshape)")]
print("\nPapers whose OLD code would coerce species ->", [r[0] for r in results if r[4]])
print("Papers with non-character Species under FIX ->", [r[0] for r in bad])
allcat=pd.concat(longs,ignore_index=True)
print("Concatenated long rows:", len(allcat), "| Species dtype after concat:", allcat["Species"].dtype)
