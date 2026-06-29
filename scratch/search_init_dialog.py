filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "_init_save_field_dialog" in line:
        safe_line = line.strip().encode('ascii', 'replace').decode('ascii')
        print(f"{i+1}: {safe_line}")
