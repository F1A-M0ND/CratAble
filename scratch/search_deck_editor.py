filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\DeckEditor.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "_save_deck" in line or "file" in line.lower() or "local" in line.lower() or "dialog" in line.lower():
        safe_line = line.strip().encode('ascii', 'replace').decode('ascii')
        print(f"{i+1}: {safe_line}")
