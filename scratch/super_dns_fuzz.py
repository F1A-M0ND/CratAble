import socket
import concurrent.futures

base_id = "opfwntnvhqxunztuakdx"
alphabet = "abcdefghijklmnopqrstuvwxyz"

candidates = set()

# 1-character mutations (change any single character to any other letter)
for i in range(len(base_id)):
    for char in alphabet:
        if base_id[i] != char:
            mutant = list(base_id)
            mutant[i] = char
            candidates.add("".join(mutant))

# Visual substitutions (focused 2-character mutations)
# Visual alternatives:
# 'f' <-> 't', 'r'
# 'n' <-> 'm', 'u', 'v'
# 'v' <-> 'u', 'y'
# 'h' <-> 'b', 'k'
# 'q' <-> 'g'
# 'x' <-> 'y', 'v'
# 'd' <-> 'b'

visuals = {
    2: ["f", "t", "r"],
    4: ["n", "m", "u", "v"],
    6: ["n", "m", "u", "v"],
    7: ["v", "u", "y"],
    8: ["h", "b", "k"],
    9: ["q", "g"],
    10: ["x", "y", "v"],
    12: ["n", "m", "u", "v"],
    17: ["k", "h"],
    18: ["d", "b"]
}

# Generate combinations of any 2 of the visual indices changing
keys = list(visuals.keys())
for i in range(len(keys)):
    for j in range(i + 1, len(keys)):
        idx1, idx2 = keys[i], keys[j]
        for v1 in visuals[idx1]:
            for v2 in visuals[idx2]:
                mutant = list(base_id)
                mutant[idx1] = v1
                mutant[idx2] = v2
                candidates.add("".join(mutant))

# Add the base itself
candidates.add(base_id)

print(f"Total candidates to check: {len(candidates)}")

found = []

def check_domain(cand):
    domain = f"{cand}.supabase.co"
    try:
        ip = socket.gethostbyname(domain)
        return cand, ip
    except socket.gaierror:
        return None

with concurrent.futures.ThreadPoolExecutor(max_workers=100) as executor:
    results = executor.map(check_domain, candidates)
    for res in results:
        if res:
            print(f"FOUND! {res[0]} -> {res[1]}")
            found.append(res[0])

print(f"Finished check. Found: {found}")
