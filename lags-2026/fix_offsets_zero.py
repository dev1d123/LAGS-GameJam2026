import re

path = r'C:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\levels\TestLevel.tscn'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Track which nodes are in Spawner/YSortLayer (direct children = sprites)
# and set their offset to Vector2(0, 0)
lines = content.split('\n')
result = []
in_ysort_sprite = False

for line in lines:
    # Detect node start
    node_match = re.match(r'\[node name="[^"]*" (?:type="[^"]*" )?parent="([^"]*)"', line)
    if node_match:
        parent = node_match.group(1)
        # Direct child of YSortLayer, but NOT the PlayerScene (CharacterBody2D handles its own offset)
        in_ysort_sprite = (parent == 'Spawner/YSortLayer') and ('PlayerScene' not in line)

    if in_ysort_sprite and re.match(r'offset = Vector2\(0, -?\d', line):
        result.append('offset = Vector2(0, 0)')
        continue

    result.append(line)

with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))

print("Done. All EnvSprite offsets set to Vector2(0, 0).")
