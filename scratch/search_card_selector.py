filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\CardSelector.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "load" in line.lower() or "fetch" in line.lower() or "supabase" in line.lower() or "file" in line.lower():
        safe_line = line.strip().encode('ascii', 'replace').decode('ascii')
        print(f"{i+1}: {safe_line}")
