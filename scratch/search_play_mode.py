filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "play_mode" in line:
        print(f"{i+1}: {line.strip()}")
