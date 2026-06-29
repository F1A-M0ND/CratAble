import os
import sys

def find_godot():
    search_paths = [
        os.path.expanduser("~"),
        "C:\\Program Files",
        "C:\\Program Files (x86)",
        "D:\\",
        "E:\\"
    ]
    
    print("Searching for Godot executable...")
    found = []
    for base in search_paths:
        if not os.path.exists(base):
            continue
        print(f"Checking: {base}")
        try:
            for root, dirs, files in os.walk(base):
                # Limit depth to avoid infinite scanning
                depth = root.replace(base, "").count(os.sep)
                if depth > 4:
                    # Skip deep subfolders to be fast
                    dirs.clear()
                    continue
                for f in files:
                    if f.lower().startswith("godot") and f.lower().endswith(".exe"):
                        p = os.path.join(root, f)
                        print(f"FOUND: {p}")
                        found.append(p)
                        if len(found) >= 5:
                            return found
        except Exception as e:
            print(f"Error scanning {base}: {e}")
            
    return found

found = find_godot()
print("Search finished. Found paths:", found)
