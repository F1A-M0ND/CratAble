import os

scripts_dir = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts"
for f in os.listdir(scripts_dir):
    if f.endswith(".gd"):
        path = os.path.join(scripts_dir, f)
        with open(path, "r", encoding="utf-8") as file:
            for i, line in enumerate(file):
                if "save" in line.lower() and ("func" in line.lower() or "pressed" in line.lower() or "button" in line.lower()):
                    safe_line = line.strip().encode('ascii', 'replace').decode('ascii')
                    print(f"{f}:{i+1}: {safe_line}")
