import re

path = r'C:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\levels\TestLevel.tscn'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

before = content

# 1. Remove the EnvSprites node definition (the node + its blank line)
content = content.replace('[node name="EnvSprites" type="Node2D" parent="Spawner/YSortLayer"]\n\n', '')

# 2. Re-parent all sprites from EnvSprites to YSortLayer directly
content = content.replace('parent="Spawner/YSortLayer/EnvSprites"', 'parent="Spawner/YSortLayer"')

# 3. Negate all positive offset.y values: offset = Vector2(0, POSITIVE) -> offset = Vector2(0, -POSITIVE)
def negate_offset(m):
    val = float(m.group(1))
    if val > 0:
        return f'offset = Vector2(0, -{val})'
    return m.group(0)

content = re.sub(r'offset = Vector2\(0, (\d+(?:\.\d+)?)\)', negate_offset, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

changed = content != before
print("Done. Lines modified:", changed)
