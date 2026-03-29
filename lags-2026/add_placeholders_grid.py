import os

def main():
    path = "c:\\Users\\DrN\\Documents\\LAGS2026\\LAGS-GameJam2026\\lags-2026\\minijuego_cafe_cyber.tscn"
    
    with open(path, 'a', encoding='utf-8') as f:
        # Append 8 placeholders for SourceGrid
        for i in range(1, 9):
            node_str = f"""
[node name="PlaceholderSrc{i}" type="ColorRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/SourceGrid"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2
color = Color(0.12, 0.12, 0.12, 0.5)
"""
            f.write(node_str)
            
        # Append 8 placeholders for TargetGrid
        for i in range(1, 9):
            node_str = f"""
[node name="PlaceholderTgt{i}" type="ColorRect" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/TargetGrid"]
custom_minimum_size = Vector2(100, 70)
layout_mode = 2
color = Color(0.12, 0.12, 0.12, 0.5)
"""
            f.write(node_str)
            
    print("Done adding placeholders!")

if __name__ == "__main__":
    main()
