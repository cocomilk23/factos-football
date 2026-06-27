from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "_meta" / "generated_sources"
OUT = ROOT / "assets" / "img"


def source(name: str) -> Path:
    path = SOURCE / name
    if not path.exists():
        raise SystemExit(f"Missing generated source: {path}")
    return path


def save_background(path: Path) -> None:
    img = Image.open(path).convert("RGB")
    img = img.resize((720, 1280), Image.Resampling.NEAREST)
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
            elif diff <= tolerance + 100:
                alpha = int(255 * (diff - tolerance) / 100)
                px[x, y] = (r, g, b, max(0, min(255, alpha)))
            elif kg > 190 and g > r * 1.18 and g > b * 1.18:
                edge = max(r, b)
                px[x, y] = (r, min(g, edge + 10), b, max(0, a - 150))
            elif kr > 190 and kb > 190 and r > 190 and b > 190 and g < 100:
                px[x, y] = (min(r, g + 38), g, min(b, g + 38), max(0, a - 135))
    remove_color_spill(rgba, key)
    return rgba


def remove_color_spill(img: Image.Image, key: tuple[int, int, int]) -> None:
    px = img.load()
    w, h = img.size
    kr, kg, kb = key
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a <= 0:
                continue
            if kg > kr and kg > kb:
                edge = max(r, b)
                if g > edge + 18:
                    px[x, y] = (r, min(g, edge + 8), b, int(a * 0.92))
            elif kr > kg and kb > kg:
                edge = g
                if r > edge + 30 and b > edge + 30:
                    px[x, y] = (min(r, edge + 52), g, min(b, edge + 52), int(a * 0.94))


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
    return img.resize(size, Image.Resampling.NEAREST)


def save_asset(img: Image.Image, name: str, max_w: int, max_h: int) -> None:
    trim_alpha(img, 10)
    resize_fit(trim_alpha(img, 10), max_w, max_h).save(OUT / name)


def process_player_sheet(path: Path, prefix: str, write_legacy: bool = False, flip_x: bool = False) -> None:
    img = Image.open(path).convert("RGBA")
    cell_w = img.width // 4
    h = img.height
    crop_boxes = [
        (0, 70, int(cell_w * 0.92), h - 30),
        (0, 70, int(cell_w * 0.96), h - 30),
        (0, 70, int(cell_w * 0.98), h - 30),
        (0, 70, int(cell_w * 0.98), h - 30),
    ]
    for idx, box in enumerate(crop_boxes):
        cell = img.crop((idx * cell_w, 0, (idx + 1) * cell_w, h))
        cropped = cell.crop(box)
        frame = trim_alpha(alpha_from_key(cropped, (0, 255, 0), 130), 12)
        if flip_x:
            frame = frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        result = resize_fit(frame, 290, 360)
        result.save(OUT / f"player_{prefix}_frame_{idx}.png")
        if write_legacy:
            result.save(OUT / f"player_frame_{idx}.png")
            if idx == 0:
                result.save(OUT / "player_volley.png")


def process_enemies(path: Path) -> None:
    for idx, cell in enumerate(split_grid(path, 2, 3)):
        enemy = trim_alpha(alpha_from_key(cell, (255, 0, 255), 115), 12)
        resize_fit(enemy, 180, 190).save(OUT / f"enemy_{idx}.png")


def process_props(path: Path) -> None:
    cells = split_grid(path, 2, 5)
    names = [
        ("launcher.png", 240, 190),
        ("ball_projectile.png", 150, 150),
        ("curve_ball.png", 180, 180),
        ("fireball_projectile.png", 180, 180),
        ("perfect_impact.png", 230, 230),
        ("heart_icon.png", 120, 120),
        ("curve_icon.png", 150, 150),
        ("pierce_icon.png", 150, 150),
        ("slow_icon.png", 150, 150),
        ("trail_segment.png", 150, 150),
    ]
    processed: dict[str, Image.Image] = {}
    for cell, (name, max_w, max_h) in zip(cells, names):
        asset = trim_alpha(alpha_from_key(cell, (0, 255, 0), 115), 10)
        result = resize_fit(asset, max_w, max_h)
        result.save(OUT / name)
        processed[name] = result

    processed["curve_icon.png"].save(OUT / "electric_icon.png")
    processed["pierce_icon.png"].save(OUT / "target_icon.png")
    processed["slow_icon.png"].save(OUT / "fireball_icon.png")


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    save_background(source("v7_open_arcade_grass_background.png"))
    process_player_sheet(source("v4_messi_sheet.png"), "messi", True)
    process_player_sheet(source("v4_ronaldo_sheet.png"), "ronaldo")
    process_player_sheet(source("v4_neymar_sheet.png"), "neymar")
    process_enemies(source("v5_grounded_enemy_sheet.png"))
    process_props(source("v3_pixel_prop_sheet.png"))


if __name__ == "__main__":
    main()
