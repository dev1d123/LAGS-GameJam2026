import re

path = r'C:\Users\DrN\Documents\LAGS2026\LAGS-GameJam2026\lags-2026\levels\TestLevel.tscn'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Parse nodes in YSortLayer and fix their positions.
# For each Sprite2D in Spawner/YSortLayer with offset.y = -h (negative):
#   new position.y = old position.y + 2*h   (moves sort key to visual base)
#   offset stays as -h (sprite still renders above position)
# This keeps visual appearance IDENTICAL but moves the sort key to the bottom of the sprite.

lines = content.split('\n')
result = []
current_parent = ''
pending_offset_y = None
pending_pos_line_idx = None

i = 0
while i < len(lines):
    line = lines[i]
    
    # Track current node's parent
    node_match = re.match(r'\[node name="[^"]*" (?:type="[^"]*" )?parent="([^"]*)"', line)
    if node_match:
        current_parent = node_match.group(1)
        pending_offset_y = None
        pending_pos_line_idx = None
    
    # Only process nodes directly in YSortLayer (not PlayerScene which is CharacterBody2D)
    if current_parent == 'Spawner/YSortLayer':
        pos_m = re.match(r'(position = Vector2\()(-?\d+\.?\d*)(, )(-?\d+\.?\d*)(\))', line)
        if pos_m:
            pending_pos_line_idx = len(result)
            result.append(line)
            i += 1
            continue
        
        off_m = re.match(r'offset = Vector2\(0, (-?\d+\.?\d*)\)', line)
        if off_m:
            offset_y = float(off_m.group(1))
            if offset_y < 0 and pending_pos_line_idx is not None:
                # Fix position.y: add 2*abs(offset_y)
                old_pos_line = result[pending_pos_line_idx]
                pos_m2 = re.match(r'(position = Vector2\()(-?\d+\.?\d*)(, )(-?\d+\.?\d*)(\))', old_pos_line)
                if pos_m2:
                    old_y = float(pos_m2.group(4))
                    new_y = old_y + 2 * abs(offset_y)
                    result[pending_pos_line_idx] = f'{pos_m2.group(1)}{pos_m2.group(2)}{pos_m2.group(3)}{new_y:.5f}{pos_m2.group(5)}'
            pending_pos_line_idx = None
    
    result.append(line)
    i += 1

with open(path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(result))

print("Done. Sprite positions adjusted for Y-sort.")
