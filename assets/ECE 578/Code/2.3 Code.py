from collections import defaultdict

# -------------------------------------------------------------
# CONFIG — CHANGE THESE TO MATCH YOUR FILE PATHS
# -------------------------------------------------------------
REL_FILES = [
    "20241101.as-rel2.txt"
]

ORG_FILES = [
    "20251001.as-org2info1.txt"
]


# -------------------------------------------------------------
# STEP 1 — LOAD AS RELATIONSHIPS AND BUILD AS GRAPH
# -------------------------------------------------------------
adj = defaultdict(set)

def load_relationships(filepath):
    with open(filepath, "r", encoding="latin-1", errors="ignore") as f:
        for line in f:
            line=line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("|")
            if len(parts) < 3:
                continue
            try:
                a = int(parts[0])
                b = int(parts[1])
            except:
                continue

            # Add undirected edge
            adj[a].add(b)
            adj[b].add(a)


for f in REL_FILES:
    print(f"Loading {f} ...")
    load_relationships(f)

print("Graph loaded.")
print(f"Total AS nodes: {len(adj)}")


# -------------------------------------------------------------
# STEP 2 — COMPUTE GLOBAL DEGREE FOR EACH AS
# -------------------------------------------------------------
degrees = {asn: len(nei) for asn, nei in adj.items()}

# Sort ASes by descending degree
sorted_ases = sorted(degrees.keys(), key=lambda x: degrees[x], reverse=True)

print("Top 10 ASes by degree:")
for i in range(10):
    asn = sorted_ases[i]
    print(i+1, asn, degrees[asn])


# -------------------------------------------------------------
# STEP 3 — GREEDY TIER-1 CLIQUE HEURISTIC
# -------------------------------------------------------------
clique = []

def is_connected_to_all(candidate, clique_list):
    """Check if candidate AS has edges to ALL ASes in the current clique."""
    cand_neighbors = adj[candidate]
    for c in clique_list:
        if c not in cand_neighbors:
            return False
    return True


# Start with highest-degree AS
clique.append(sorted_ases[0])
candidates_examined = 0
# Check next AS in ranked list until clique reaches up to 10 nodes
for asn in sorted_ases[1:50]:   #scanning the top 50
    candidates_examined += 1
    if is_connected_to_all(asn, clique):
        clique.append(asn)
    if len(clique) == 10:
        break

print("\nFinal clique (Tier-1 candidates):")
print(clique)
print(f"Clique size = {len(clique)}")
print(f"Candidates examined to get clique = {candidates_examined}")


# -------------------------------------------------------------
# STEP 4 — LOAD ORG INFO MAPPING (AS → ORG NAME)
# -------------------------------------------------------------
as_to_org = {}

def load_org_file(filepath):
    with open(filepath, "r", encoding="latin-1", errors="ignore") as f:
        for line in f:
            if not line or line.startswith("#"):
                continue
            parts = line.strip().split("|")
            if len(parts) < 3:
                continue
            
            # FORMAT: org_id|changed|org_name|country|source
            # But CAIDA AS-org2info format ALSO contains lines like AS_NUMBER|DATE|ORG_NAME...
            try:
                asn = int(parts[0])
            except:
                continue
            
            org_name = parts[2].strip()
            as_to_org[asn] = org_name


for f in ORG_FILES:
    print(f"Loading org info from {f} ...")
    load_org_file(f)

print(f"Loaded org mappings for {len(as_to_org)} AS numbers.")


# -------------------------------------------------------------
# STEP 5 — PRINT TABLE 1
# -------------------------------------------------------------
print("\n\nTABLE 1 — Tier-1 Inference Results\n")
print(f"{'Rank':<5} {'AS':<10} {'Organization':<40} {'Degree':<10}")
print("-"*80)

for i, asn in enumerate(clique, start=1):
    org = as_to_org.get(asn, "N/A")
    deg = degrees.get(asn, 0)
    print(f"{i:<5} {asn:<10} {org:<40} {deg:<10}")

print("\nDone.")