filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "draw" in line.lower() or "add_child" in line.lower():
        if "hand_zone" in line:
            safe_line = line.strip().encode('ascii', 'replace').decode('ascii')
            print(f"{i+1}: {safe_line}")
