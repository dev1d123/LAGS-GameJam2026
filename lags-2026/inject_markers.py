import re

def main():
    path = "c:\\Users\\DrN\\Documents\\LAGS2026\\LAGS-GameJam2026\\lags-2026\\minijuego_cafe_cyber.tscn"
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to find every PortA_... and PortB_... and append a Marker2D child if it doesn't have one.
    colors = ["amarillo", "verde", "negro", "morado", "azul", "rojo", "blanco", "naranja"]
    
    for c in colors:
        for prefix in ["PortA", "PortB"]:
            node_name = f"{prefix}_{c}"
            marker_str = f"""
[node name="WirePoint" type="Marker2D" parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/{"SourceGrid" if prefix == "PortA" else "TargetGrid"}/{node_name}"]
position = Vector2(50, 35)
"""
            # Inject right after the node definition
            # Find the match and inject BEFORE the next [node or EOF
            pattern = re.compile(r'(\[node name="' + node_name + r'".*?\](?!.*?\[node name="WirePoint".*?parent=".*?/' + node_name + r'").*?)(?=\n\[node|\Z)', re.DOTALL)
            
            # Since my logic above looks for trailing nodes, let's just append it to the end of the file!
            # It's perfectly safe in Godot 4.
            if f'parent="MainPanel/Margin/VBox/Content/CenterPanel/CableArea/Inner/{"SourceGrid" if prefix == "PortA" else "TargetGrid"}/{node_name}"' not in content:
                content += marker_str

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
        
    print("Injected Marker2Ds accurately!")

if __name__ == "__main__":
    main()
