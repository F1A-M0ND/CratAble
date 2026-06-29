filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "collapse_bar" in line:
        # Encode and decode as ascii, replacing errors with '?'
        safe_line = line.strip().encode('ascii', 'replace').decode('ascii')
        print(f"{i+1}: {safe_line}")
