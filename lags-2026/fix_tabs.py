import os

def fix():
    path = r"c:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\minijuego_store_search.gd"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    start_str = 'var wrapper = preload("res://store_card.tscn").instantiate()\n\t\twrapper.show()'
    
    parts = content.split(start_str)
    if len(parts) == 2:
        top = parts[0] + start_str
        bottom = parts[1]
        
        fix_part, rest = bottom.split("\t\t\tboard_grid.add_child(wrapper)", 1)
        fix_part = fix_part.replace("\n\t\t\t", "\n\t\t")
        
        final = top + fix_part + "\t\tboard_grid.add_child(wrapper)" + rest
        with open(path, 'w', encoding='utf-8') as f:
            f.write(final)
            print("OK")
            
if __name__ == "__main__":
    fix()
