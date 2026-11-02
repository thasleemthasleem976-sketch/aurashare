import os
from PIL import Image, ImageDraw

def create_icon(size, is_maskable=False):
    # Dark cyber background with rounded corners or full fill
    img = Image.new("RGBA", (size, size), (7, 11, 20, 255))
    draw = ImageDraw.Draw(img)

    # Gradient-like background circle
    margin = int(size * 0.12) if is_maskable else int(size * 0.05)
    center = size // 2
    radius = (size - 2 * margin) // 2

    # Outer glow / ring
    for r in range(radius, radius - int(size * 0.04), -1):
        alpha = int(120 * (r / radius))
        draw.ellipse(
            [center - r, center - r, center + r, center + r],
            outline=(0, 180, 216, alpha),
            width=2
        )

    # Core node circles (sharing network symbol: 3 nodes connected by lines)
    # Node 1: Top (center, y1)
    # Node 2: Bottom Left (x2, y2)
    # Node 3: Bottom Right (x3, y2)
    node_r = int(size * 0.09)
    y1 = int(size * 0.32)
    y2 = int(size * 0.68)
    x2 = int(size * 0.30)
    x3 = int(size * 0.70)
    x1 = center

    # Connecting lines (thick neon blue)
    line_w = max(4, int(size * 0.035))
    draw.line([(x1, y1), (x2, y2)], fill=(0, 180, 216, 255), width=line_w)
    draw.line([(x1, y1), (x3, y2)], fill=(0, 180, 216, 255), width=line_w)

    # Draw Nodes with gradients and highlights
    for nx, ny, fill_col in [(x1, y1, (0, 180, 216)), (x2, y2, (0, 119, 182)), (x3, y2, (72, 202, 228))]:
        # Glow
        draw.ellipse([nx - node_r - 4, ny - node_r - 4, nx + node_r + 4, ny + node_r + 4], fill=(*fill_col, 80))
        # Solid core
        draw.ellipse([nx - node_r, ny - node_r, nx + node_r, ny + node_r], fill=(*fill_col, 255), outline=(255, 255, 255, 200), width=max(2, int(size * 0.015)))
        # Center white highlight
        inner_r = max(2, int(node_r * 0.35))
        draw.ellipse([nx - inner_r, ny - inner_r, nx + inner_r, ny + inner_r], fill=(255, 255, 255, 240))

    return img

def main():
    web_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "web")
    os.makedirs(web_dir, exist_ok=True)

    # 1. 192x192 PNG
    icon_192 = create_icon(192)
    icon_192.save(os.path.join(web_dir, "icon-192.png"), "PNG")
    print("Created icon-192.png")

    # 2. 512x512 PNG
    icon_512 = create_icon(512)
    icon_512.save(os.path.join(web_dir, "icon-512.png"), "PNG")
    print("Created icon-512.png")

    # 3. 512x512 Maskable PNG
    icon_maskable = create_icon(512, is_maskable=True)
    icon_maskable.save(os.path.join(web_dir, "icon-maskable-512.png"), "PNG")
    print("Created icon-maskable-512.png")

    # 4. Favicon (ICO + PNG)
    icon_32 = create_icon(32)
    icon_64 = create_icon(64)
    icon_32.save(os.path.join(web_dir, "favicon.ico"), format="ICO", sizes=[(16, 16), (32, 32), (64, 64)])
    icon_64.save(os.path.join(web_dir, "favicon.png"), "PNG")
    print("Created favicon.ico & favicon.png")

if __name__ == "__main__":
    main()
