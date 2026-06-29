def print_lines(filepath, start, end):
    print(f"=== {filepath} ({start} - {end}) ===")
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()
    for idx in range(max(0, start - 1), min(len(lines), end)):
        line = lines[idx]
        # Print with representation to see tabs/spaces and weird chars
        print(f"{idx+1}: {repr(line)}")

print_lines(r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd", 2085, 2105)
print_lines(r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd", 2305, 2320)
print_lines(r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd", 2470, 2485)
print_lines(r"c:\Users\ASUS\OneDrive\Documents\CratAble-Field-System 1\scripts\FieldCreator.gd", 2565, 2580)
