from collections import defaultdict, deque

# -------------------------------------------------------------
# CONFIG — CHANGE THESE PATHS FOR YOUR MACHINE
# -------------------------------------------------------------
AS_REL_FILES = [
    "20241101.as-rel2.txt"
]

PFX_FILE = "routeviews-rv2-20251110-1200.pfx2as.txt"

ORG_FILES = [
    "20251001.as-org2info1.txt"
]


# -------------------------------------------------------------
# STEP 1 — LOAD AS RELATIONSHIPS (WE ONLY NEED p2c LINKS)
# -------------------------------------------------------------
p2c = defaultdict(set)      # provider → customers
providers_of = defaultdict(set)

def load_relationships(path):
    with open(path, "r", encoding="latin-1", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("|")
            if len(parts) < 3:
                continue
            try:
                a = int(parts[0])
                b = int(parts[1])
                rel = int(parts[2])
            except:
                continue

            if rel == -1:  # provider → customer
                p2c[a].add(b)
                providers_of[b].add(a)


for f in AS_REL_FILES:
    print(f"Loading AS-rel file: {f}")
    load_relationships(f)

print(f"Loaded provider→customer graph.")
print(f"Providers with customers: {len(p2c)}")


# Collect all ASNs that appear as providers OR customers
all_as = set(p2c.keys()) | set(providers_of.keys())

# Ensure every ASN has a key in p2c (even empty set)
for asn in all_as:
    p2c.setdefault(asn, set())

# Freeze a stable list for iteration
asn_list = list(all_as)

print(f"Total unique ASes in relationship graph: {len(asn_list)}")


# -------------------------------------------------------------
# STEP 2 — LOAD PREFIX → AS MAPPINGS
# -------------------------------------------------------------
prefixes_of_as = defaultdict(list)

def load_prefixes(path):
    with open(path, "r", encoding="latin-1", errors="ignore") as f:
        for line in f:
            parts = line.strip().split("\t")
            if len(parts) < 3:
                continue
            prefix = parts[0]
            try:
                plen = int(parts[1])
                asn = int(parts[2])
            except:
                continue
            prefixes_of_as[asn].append((prefix, plen))


print(f"Loading prefix-to-AS file: {PFX_FILE}")
load_prefixes(PFX_FILE)
print(f"Loaded prefix data for {len(prefixes_of_as)} AS numbers.")


# -------------------------------------------------------------
# STEP 3 — LOAD ORG INFO (AS → org name)
# -------------------------------------------------------------
as_to_org = {}

def load_org_file(path):
    with open(path, "r", encoding="latin-1", errors="ignore") as f:
        for line in f:
            if not line or line.startswith("#"):
                continue
            parts = line.strip().split("|")
            if len(parts) < 3:
                continue
            try:
                asn = int(parts[0])
            except:
                continue
            org = parts[2].strip()
            as_to_org[asn] = org


for f in ORG_FILES:
    print(f"Loading org info from: {f}")
    load_org_file(f)

print(f"Loaded org mappings for {len(as_to_org)} ASes.")


# -------------------------------------------------------------
# STEP 4 — CUSTOMER CONE DFS/BFS
# -------------------------------------------------------------
def compute_customer_cone(start_as):
    """Return all ASes reachable from ASN following only provider→customer edges."""
    visited = set([start_as])
    queue = deque([start_as])

    while queue:
        node = queue.popleft()
        for cust in p2c[node]:
            if cust not in visited:
                visited.add(cust)
                queue.append(cust)

    return visited


# -------------------------------------------------------------
# STEP 5 — IP COUNT FOR PREFIX
# -------------------------------------------------------------
def ip_count(prefixlen):
    return 2 ** (32 - prefixlen)   # IPv4 only


# -------------------------------------------------------------
# PRECOMPUTE TOTAL PREFIX/IP SPACE FOR PERCENTAGES
# -------------------------------------------------------------
print("\nPrecomputing totals...")

all_prefixes = []
total_ips = 0

for asn, pfx_list in prefixes_of_as.items():
    for pfx, plen in pfx_list:
        all_prefixes.append((asn, pfx, plen))
        total_ips += ip_count(plen)

TOTAL_ASES = len(asn_list)
TOTAL_PREFIXES = len(all_prefixes)

print(f"Total ASes: {TOTAL_ASES}")
print(f"Total prefixes: {TOTAL_PREFIXES}")
print(f"Total IPs: {total_ips}")


# -------------------------------------------------------------
# STEP 6 — COMPUTE CUSTOMER CONES FOR ALL ASes
# -------------------------------------------------------------
results = []

print("\nComputing customer cones for all ASes (this will take time)...")

for asn in asn_list:
    cone = compute_customer_cone(asn)
    cone_as_count = len(cone)

    # Compute prefixes & IPs reachable
    prefix_set = set()
    ip_sum = 0

    for c in cone:
        for (pfx, plen) in prefixes_of_as.get(c, []):
            prefix_set.add((pfx, plen))
            ip_sum += ip_count(plen)

    results.append({
        "asn": asn,
        "as_count": cone_as_count,
        "prefixes": len(prefix_set),
        "ips": ip_sum
    })
    
print("Finished computing customer cones.")


# -------------------------------------------------------------
# STEP 7 — SORT & SELECT TOP 15
# -------------------------------------------------------------
results.sort(key=lambda x: x["as_count"], reverse=True)
top15 = results[:15]


# -------------------------------------------------------------
# STEP 8 — PRINT TABLE 2
# -------------------------------------------------------------
print("\n\nTABLE 2 — TOP 15 ASes BY CUSTOMER CONE SIZE")
line = (
    f"{'Rank':<5} {'AS':<10} {'Org Name':<40} "
    f"{'#AS':<10} {'#Pfx':<10} {'#IPs':<15} "
    f"{'%AS':<8} {'%Pfx':<8} {'%IPs':<8}"
)
print(line)
print("-" * len(line))

for rank, row in enumerate(top15, start=1):
    asn = row["asn"]
    org = as_to_org.get(asn, "N/A")

    as_cnt = row["as_count"]
    pfx_cnt = row["prefixes"]
    ip_cnt = row["ips"]

    pct_as = (as_cnt / TOTAL_ASES) * 100
    pct_pfx = (pfx_cnt / TOTAL_PREFIXES) * 100
    pct_ip = (ip_cnt / total_ips) * 100

    print(f"{rank:<5} {asn:<10} {org:<40} "
          f"{as_cnt:<10} {pfx_cnt:<10} {ip_cnt:<15} "
          f"{pct_as:6.2f} {pct_pfx:6.2f} {pct_ip:6.2f}")
    
# -------------------------------------------------------------
# Forgot to get Degree: compute global degree and print for top-15 ASes
# -------------------------------------------------------------
from collections import defaultdict

adj = defaultdict(set)

# Re-read the AS relationship files to build full adjacency graph
for path in AS_REL_FILES:
    print(f"\n(Re)loading AS-rel file for degree calc: {path}")
    with open(path, "r", encoding="latin-1", errors="ignore") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split("|")
            if len(parts) < 3:
                continue
            try:
                a = int(parts[0])
                b = int(parts[1])
            except ValueError:
                continue

            # undirected edge for global degree
            adj[a].add(b)
            adj[b].add(a)

# Build degree dict: AS → number of neighbors
degree = {asn: len(neighbors) for asn, neighbors in adj.items()}

print("\nDegrees for Top-15 ASes (global node degree):")
for row in top15:
    asn = row["asn"]          # assumes your top15 entries have key "asn"
    deg = degree.get(asn, 0)
    print(f"AS {asn}: degree = {deg}")


print("\nDone.")


