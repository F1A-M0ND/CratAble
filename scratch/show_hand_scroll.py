filepath = r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd"
with open(filepath, "r", encoding="utf-8") as f:
    lines = f.readlines()

start = max(0, 3330)
end = min(len(lines), 3380)
for idx in range(start, end):
    safe_line = lines[idx].strip().encode('ascii', 'replace').decode('ascii')
    print(f"{idx+1}: {safe_line}")
