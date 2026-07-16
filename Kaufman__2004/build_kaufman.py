#!/usr/bin/env python3
# Build Kaufman (2004) Table A15 "Species Means in Conscious Subjects" into a tidy dataset.
# Primary: dissertation PDF pp.169-176 (pdftotext -layout). Disambiguation: xlsx sheets Table 97-104.
import re, csv
import openpyxl
RAW = "/sessions/sweet-adoring-galileo/mnt/outputs/A15_raw.txt"
XLSX = "/sessions/sweet-adoring-galileo/mnt/Kaufman__2004/Kaufman__2004_dissertation.xlsx"
OUT  = "/sessions/sweet-adoring-galileo/mnt/outputs/Kaufman__2004_A15_tidy.csv"

REGIONS = ["Whole Brain","Frontal Cortex","Parietal Cortex","Temporal Cortex","Auditory Cortex",
           "Occipital Cortex","Sensorimotor Cortex","Cingulate Cortex","Cortex",
           "Thalamus","Hippocampus","Basal Ganglia","Cerebellum","White Matter"]
REGION_ORDER = ["Whole Brain","Cortex","Frontal Cortex","Parietal Cortex","Temporal Cortex",
           "Auditory Cortex","Occipital Cortex","Sensorimotor Cortex","Cingulate Cortex",
           "Thalamus","Hippocampus","Basal Ganglia","Cerebellum","White Matter"]
SPECIES = ["Homo","Macaca","Canis","Rattus","Mus","Lepus","Felis","Meriones","Ovis","Capra","Sus","Equus"]
MEASURES = ["CMRgl","CMRO2","CBF"]
NOISE = ["reproduced with permission","table a15","unbiased coefficient","species means",
         "conscious subjects","coefficient of variation"]
# phrases scrubbed from header text before region/measure detection (their letters cause false matches)
HDR_SCRUB = ["copyright owner","further reproduction","reproduction prohibited","without permission",
             "reproduced with permission","permission","table","subjects","species","means",
             "conscious","unbiased","coefficient","variation","further","without","owner","prohibited"]
NUM = re.compile(r"-?\d+(?:\.\d+)?$")
def squish(s): return re.sub(r"\s+"," ",s).strip()
def letters(s): return re.sub(r"[^a-z]","",s.lower())
def is_subseq(needle,hay):
    it=iter(hay)
    return all(c in it for c in needle)
def region_of(text):
    L=letters(text); best=None; blen=-1
    for r in REGIONS:
        rl=letters(r)
        if is_subseq(rl,L) and len(rl)>blen: best=r; blen=len(rl)
    return best
def measure_of(text):
    t=text.replace(" ","")
    if re.search(r"MRgl",t): return "CMRgl"
    if re.search(r"MR[O0Q]2",t) or re.search(r"R[O0Q]2",t): return "CMRO2"
    if "BF" in t: return "CBF"
    return None
def scrub_header(text):
    t=text
    for p in HDR_SCRUB:
        t=re.sub(p, " ", t, flags=re.I)
    return t
def parse_header(text):
    t=scrub_header(text)
    return region_of(t), measure_of(t)
def is_data(line):
    return re.search(r"\b(unweighted|weighted)\b",line.lower()) is not None
def is_noise(line):
    low=line.lower()
    if any(n in low for n in NOISE): return True
    if re.fullmatch(r"\d{2,3}",line.strip()): return True   # stray page number
    return False

def parse_pdf():
    lines=[squish(l) for l in open(RAW)]
    lines=[l for l in lines if l and not is_noise(l)]
    records=[]; cur_r=cur_m=cur_sp=None; header_buf=[]; pending=None
    def flush():
        nonlocal pending
        if pending is not None: records.append(pending); pending=None
    def resolve_header():
        nonlocal cur_r,cur_m,cur_sp,header_buf
        if header_buf:
            r,m=parse_header(" ".join(header_buf))
            if r and m: cur_r,cur_m,cur_sp=r,m,None
            header_buf=[]
    for line in lines:
        if is_data(line):
            resolve_header(); flush()
            low=line.lower()
            mm=re.search(r"\b(unweighted|weighted)\b",low)
            weighting=mm.group(1); before=line[:mm.start()]
            sp=None
            for s in SPECIES:
                if re.search(r"\b"+s+r"\b",before): sp=s; break
            if sp: cur_sp=sp
            nums=NUM_all(line[mm.end():])
            pending={"region":cur_r,"measure":cur_m,"species":cur_sp,"weighting":weighting,"nums":nums}
        else:
            toks=line.split()
            if pending is not None and toks and all(NUM.match(t) for t in toks):
                pending["nums"].extend(toks)
            else:
                flush(); header_buf.append(line)
    resolve_header(); flush()
    # reconstruct 5 numbers per record
    def dedupe(xs):
        out=[]
        for n in xs:
            if out and out[-1]==n: continue
            out.append(n)
        return out
    for r in records:
        R=r["nums"]; note=""
        if len(R)==5: rec=R
        elif len(R)>5:
            D=dedupe(R)
            if len(D)==5: rec=D; note="dedup"
            elif len(D)>5:
                while len(D)>5 and re.fullmatch(r"\d{1,3}",D[-1]): D=D[:-1]
                rec=D[:5]; note="trim"
            elif len(D)==4: rec=D+[D[-1]]; note="CVstar=CV"
            else: rec=D; note="short"
        else: rec=R; note="short_raw"
        r["nums_clean"]=rec; r["note"]=note
    return records
def NUM_all(s): return re.findall(r"-?\d+(?:\.\d+)?",s)

def parse_xlsx():
    wb=openpyxl.load_workbook(XLSX, read_only=True, data_only=True); ref={}
    for si in range(97,105):
        ws=wb[f"Table {si}"]; cur_r=cur_m=cur_sp=None
        for row in ws.iter_rows(values_only=True):
            cells=[("" if c is None else str(c)) for c in row]; flat=[]
            for c in cells: flat.extend(c.split("\n"))
            flat=[squish(x) for x in flat if squish(x)]; text=" ".join(flat); low=text.lower()
            if is_noise(text): 
                pass
            if not is_data(text):
                r=region_of(text); m=measure_of(text)
                # header row if has measure and region and looks like a title (contains 'mean' or short)
                if r and m and ("mean" in low or "deviation" in low or len(flat)<=4):
                    cur_r,cur_m,cur_sp=r,m,None
                continue
            mm=re.search(r"\b(unweighted|weighted)\b",low)
            if mm and cur_r and cur_m:
                weighting=mm.group(1); before=text[:mm.start()]
                for s in SPECIES:
                    if re.search(r"\b"+s+r"\b",before): cur_sp=s; break
                nums=NUM_all(text[mm.end():]); dd=[]
                for n in nums:
                    if dd and dd[-1]==n: continue
                    dd.append(n)
                if cur_sp: ref[(cur_r,cur_m,cur_sp,weighting)]=dd[:5]
    return ref

pdf=parse_pdf(); ref=parse_xlsx()
# collapse duplicate (region,measure,species,weighting): keep the record with most numeric values
from collections import OrderedDict
best={}
order=[]
for r in pdf:
    if not r["region"] or not r["measure"] or r["species"] is None: 
        continue
    key=(r["region"],r["measure"],r["species"],r["weighting"])
    score=sum(1 for v in r["nums_clean"] if v not in ("",None))
    if key not in best:
        best[key]=r; order.append(key)
    else:
        prev=sum(1 for v in best[key]["nums_clean"] if v not in ("",None))
        if score>prev: best[key]=r
pdf=[best[k] for k in order]
STAT=["N","Mean","SD","CV","CVstar"]; final=[]; issues=[]
seen=set()
for r in pdf:
    key=(r["region"],r["measure"],r["species"],r["weighting"]); nums=r["nums_clean"]; note=r["note"]
    if not r["region"] or not r["measure"]: issues.append(("no_region_measure",r)); continue
    if r["species"] is None: issues.append(("no_species",key,nums)); continue
    if key in seen: issues.append(("DUP_KEY",key,nums))
    seen.add(key)
    if len(nums)!=5:
        xr=ref.get(key)
        if xr and len(xr)==5: note=(note+"|filled_from_xlsx").strip("|"); nums=xr
        else: issues.append(("bad_count",key,f"pdf={nums} xlsx={xr}")); nums=(nums+["","","","",""])[:5]
    rec={"species":r["species"],"weighting":r["weighting"],"region":r["region"],"measure":r["measure"],
         "units":"mL/100g/min" if r["measure"]=="CBF" else "umol/100g/min"}
    for s,v in zip(STAT,nums): rec[s]=v
    keepnote = "" 
    for flag in ("CVstar=CV","filled_from_xlsx","trim","short"):
        if flag in note: keepnote=note; break
    rec["note"]=keepnote; final.append(rec)
print("PDF records:",len(pdf)," final:",len(final)," xlsx ref:",len(ref)," issues:",len(issues))
for it in issues: print("  ISSUE",it)
cols=["species","weighting","region","measure","units","N","Mean","SD","CV","CVstar","note"]
def sk(x): return (REGION_ORDER.index(x["region"]),MEASURES.index(x["measure"]),SPECIES.index(x["species"]),x["weighting"])
with open(OUT,"w",newline="") as f:
    w=csv.DictWriter(f,fieldnames=cols); w.writeheader()
    for rec in sorted(final,key=sk): w.writerow(rec)
print("wrote",OUT)
# summary of blocks
from collections import Counter
bc=Counter((x["region"],x["measure"]) for x in final)
print("distinct region/measure blocks:",len(bc))
