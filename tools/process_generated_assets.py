from __future__ import annotations

from collections import deque
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "_meta" / "generated_sources"
OUT = ROOT / "assets" / "img"


def newest_sources() -> list[Path]:
    return sorted(SOURCE.glob("*.png"), key=lambda p: p.stat().st_mtime)


def save_background(path: Path) -> None:
    img = Image.open(path).convert("RGB")
    img = img.resize((1280, 720), Image.Resampling.LANCZOS)
    img.save(OUT / "stadium_field.png")


def alpha_from_key(img: Image.Image, key: tuple[int, int, int], tolerance: int) -> Image.Image:
    rgba = img.convert("RGBA")
    px = rgba.load()
    w, h = rgba.size
    kr, kg, kb = key
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            diff = abs(r - kr) + abs(g - kg) + abs(b - kb)
            if diff <= tolerance:
                px[x, y] = (r, g, b, 0)
            elif diff <= tolerance + 95:
                alpha = int(255 * (diff - tolerance) / 95)
                px[x, y] = (r, g, b, max(0, min(255, alpha)))
            elif kg > 200 and g > r * 1.22 and g > b * 1.22:
                px[x, y] = (r, min(g, max(r, b) + 18), b, max(0, a - 120))
            elif kr > 200 and kb > 200 and r > 210 and b > 210 and g < 80:
                px[x, y] = (min(r, g + 35), g, min(b, g + 35), max(0, a - 120))
    return rgba


def trim_alpha(img: Image.Image, pad: int = 8) -> Image.Image:
    alpha = img.getchannel("A")
    box = alpha.getbbox()
    if box is None:
        return img
    left, top, right, bottom = box
    left = max(0, left - pad)
    top = max(0, top - pad)
    right = min(img.width, right + pad)
    bottom = min(img.height, bottom + pad)
    return img.crop((left, top, right, bottom))


def split_grid(path: Path, rows: int, cols: int) -> list[Image.Image]:
    img = Image.open(path).convert("RGBA")
    cell_w = img.width // cols
    cell_h = img.height // rows
    cells: list[Image.Image] = []
    for row in range(rows):
        for col in range(cols):
            cells.append(img.crop((col * cell_w, row * cell_h, (col + 1) * cell_w, (row + 1) * cell_h)))
    return cells


def resize_fit(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    scale = min(max_w / img.width, max_h / img.height, 1.0)
    size = (max(1, int(img.width * scale)), max(1, int(img.height * scale)))
    return img.resize(size, Image.Resampling.LANCZOS)


def process_player_launcher(path: Path) -> None:
    img = Image.open(path).convert("RGBA")
    left = img.crop((0, 0, img.width // 2, img.height))
    right = img.crop((img.width // 2 + 70, 0, img.width, img.height))
    player = trim_alpha(alpha_from_key(left, (0, 255, 0), 135), 12)
    launcher = trim_alpha(alpha_from_key(right, (0, 255, 0), 135), 12)
    resize_fit(player, 250, 340).save(OUT / "player_volley.png")
    resize_fit(launcher, 230, 220).save(OUT / "launcher.png")


def process_enemies(path: Path) -> None:
    for idx, cell in enumerate(split_grid(path, 2, 2)):
        enemy = trim_alpha(alpha_from_key(cell, (255, 0, 255), 100), 10)
        resize_fit(enemy, 150, 160).save(OUT / f"enemy_{idx}.png")


def process_ui(path: Path) -> None:
    cells = split_grid(path, 2, 3)
    names = ["ball_projectile", "curve_slash", "electric_icon", "target_icon", "fireball_icon", "heart_icon"]
    for name, cell in zip(names, cells):
        asset = trim_alpha(alpha_from_key(cell, (0, 255, 0), 110), 8)
        resize_fit(asset, 180, 180).save(OUT / f"{name}.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    sources = newest_sources()
    if len(sources) < 4:
        raise SystemExit(f"Expected 4 generated sources, found {len(sources)}")
    save_background(sources[0])
    process_player_launcher(sources[1])
    process_enemies(sources[2])
    process_ui(sources[3])


if __name__ == "__main__":
    main()
