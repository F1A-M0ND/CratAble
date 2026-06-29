def print_lines(filepath, start, end):
    print(f"=== {filepath} ({start} - {end}) ===")
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()
    for idx in range(max(0, start - 1), min(len(lines), end)):
        safe_line = lines[idx].strip().encode('ascii', 'replace').decode('ascii')
        print(f"{idx+1}: {safe_line}")

print_lines(r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd", 50, 110)
