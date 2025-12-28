from collections import defaultdict

# -------------------------------------------------------------
# CONFIG — CHANGE THESE TO MATCH YOUR FILE PATHS
# -------------------------------------------------------------
REL_FILES = [
    "20241101.as-rel2.txt"
]

# -------------------------------------------------------------
# STEP 1 — LOAD AS RELATIONSHIPS AND BUILD AS GRAPH
# -------------------------------------------------------------
adj = defaultdict(set)      # undirected graph (for degree)
p2c = defaultdict(set)      # provider -> customer
peers = defaultdict(set)    # peer <-> peer

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
                rel = int(parts[2])
            except:
                continue

            # Add undirected edge for global degree
            adj[a].add(b)
            adj[b].add(a)

            # Relationship type:
            # -1 = provider→customer
            #  0 = peer↔peer
            if rel == -1:
                p2c[a].add(b)   # provider a → customer b
            elif rel == 0:
                peers[a].add(b)
                peers[b].add(a)


for f in REL_FILES:
    print(f"Loading {f} ...")
    load_relationships(f)

print("Graph loaded.")
print(f"Total AS nodes (degree graph): {len(adj)}")

# ensure every AS is present in p2c and peers
all_as = set(adj.keys())
for asn in all_as:
    p2c.setdefault(asn, set())
    peers.setdefault(asn, set())



# -------------------------------------------------------------
# STEP 3 — CLASSIFY ASes FOR GRAPH #4
# -------------------------------------------------------------
classification = {}  # AS → class string

enterprise = 0
content = 0
transit = 0

for asn in all_as:
    num_customers = len(p2c[asn])
    num_peers = len(peers[asn])

    if num_customers == 0 and num_peers == 0:
        classification[asn] = "Enterprise"
        enterprise += 1
    elif num_customers == 0 and num_peers > 0:
        classification[asn] = "Content"
        content += 1
    elif num_customers > 0:
        classification[asn] = "Transit"
        transit += 1
    else:
        classification[asn] = "Unknown"  # normally won't happen


total_as = len(all_as)

print("\nClassification counts for Graph #4:")
print(f"Enterprise: {enterprise}  ({enterprise/total_as*100:.2f}%)")
print(f"Content:    {content}     ({content/total_as*100:.2f}%)")
print(f"Transit:    {transit}     ({transit/total_as*100:.2f}%)")

# You can now use these three values to generate the pie chart.

# -------------------------------------------------------------
# STEP 5 — PRINT RESULTS FOR GRAPH #4
# -------------------------------------------------------------
print("\n\nGraph #4 classification data:")
print(f"Enterprise AS count: {enterprise}")
print(f"Content AS count:    {content}")
print(f"Transit AS count:    {transit}")

print("Done.")
