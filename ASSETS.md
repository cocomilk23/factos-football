# Assets

**Art direction:** Premium pixel-art soccer training ground. The visual target is a unified high-end pixel style across field, player, enemies, launcher, footballs, HUD icons, and effects.

## Runtime Image Assets

These files are loaded by `res://scripts/Main.gd` at runtime.

| File | Purpose | Notes |
|------|---------|-------|
| `assets/img/stadium_field.png` | Pixel-art training field background | 1280x720 |
| `assets/img/player_frame_0.png` - `assets/img/player_frame_3.png` | Four-frame volley animation | Transparent PNG |
| `assets/img/player_volley.png` | Idle player fallback | Same as frame 0 |
| `assets/img/launcher.png` | Pixel-art ball feeder machine | Transparent PNG |
| `assets/img/ball_projectile.png` | Normal feed ball / shot ball | Transparent PNG |
| `assets/img/curve_ball.png` | Curve-shot projectile visual | Transparent PNG |
| `assets/img/fireball_projectile.png` | Focus/power shot projectile visual | Transparent PNG |
| `assets/img/enemy_0.png` - `assets/img/enemy_5.png` | Six enemy variants | Transparent PNG |
| `assets/img/perfect_impact.png` | Perfect shot / hit burst | Transparent PNG |
| `assets/img/heart_icon.png` | Lives HUD | Transparent PNG |
| `assets/img/curve_icon.png` | Focus HUD skill icon | Transparent PNG |
| `assets/img/pierce_icon.png` | Focus HUD skill icon | Transparent PNG |
| `assets/img/slow_icon.png` | Focus HUD skill icon | Transparent PNG |
| `assets/img/trail_segment.png` | Optional pixel trail asset | Transparent PNG |

Compatibility aliases are also written for older code paths: `electric_icon.png`, `target_icon.png`, and `fireball_icon.png`.

## Source Images

Original generated sheets are kept outside the Godot runtime asset tree at `_meta/generated_sources/`.

Current pixel-art sources:

- `_meta/generated_sources/v3_pixel_background.png`
- `_meta/generated_sources/v3_pixel_player_sheet.png`
- `_meta/generated_sources/v3_pixel_enemy_sheet.png`
- `_meta/generated_sources/v3_pixel_prop_sheet.png`

Regenerate processed runtime assets with:

```powershell
python tools/process_generated_assets.py
```

The processor removes chroma-key backgrounds, crops the sheets, uses nearest-neighbor resizing for pixel clarity, and writes final PNG files to `assets/img/`.
