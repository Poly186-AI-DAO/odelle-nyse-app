#!/usr/bin/env python3
from PIL import Image
import numpy as np

# Open original
img = Image.open('app-icon-black.png').convert('RGBA')
arr = np.array(img)

# Find logo bounding box
r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]
logo_mask = (r > 10) | (g > 10) | (b > 10)

rows = np.any(logo_mask, axis=1)
cols = np.any(logo_mask, axis=0)
y_min, y_max = np.where(rows)[0][[0, -1]]
x_min, x_max = np.where(cols)[0][[0, -1]]

# Add small padding
padding = 5
y_min = max(0, y_min - padding)
y_max = min(1023, y_max + padding)
x_min = max(0, x_min - padding)
x_max = min(1023, x_max + padding)

# Crop the logo
logo = img.crop((x_min, y_min, x_max + 1, y_max + 1))

# Calculate new size (90% of 1024 = 921)
target_fill = 0.90
target_size = int(1024 * target_fill)

# Scale logo to fit target while maintaining aspect ratio
logo_w, logo_h = logo.size
scale = target_size / max(logo_w, logo_h)
new_w = int(logo_w * scale)
new_h = int(logo_h * scale)

logo_scaled = logo.resize((new_w, new_h), Image.Resampling.LANCZOS)

# Create new black canvas and paste centered logo
new_img = Image.new('RGBA', (1024, 1024), (0, 0, 0, 255))
paste_x = (1024 - new_w) // 2
paste_y = (1024 - new_h) // 2

# Composite to preserve transparency blending
new_img.paste(logo_scaled, (paste_x, paste_y), logo_scaled)

# Flatten to RGB with black background
final = Image.new('RGB', (1024, 1024), (0, 0, 0))
final.paste(new_img, mask=new_img.split()[3])

# Save as new file
final.save('app-icon-black-large.png')
print(f'Saved app-icon-black-large.png')
print(f'Logo now fills {target_fill*100:.0f}% of canvas')
