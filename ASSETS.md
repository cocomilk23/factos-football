# Assets

**Art direction:** Bright arcade football challenge arena, closer to a finished mobile/PC survival shooter screen: stadium field, bold HUD panels, readable monsters/robots, glowing curved football trail.

## Runtime Image Assets

These files are loaded by `res://scripts/Main.gd` at runtime.

| File | Purpose | Notes |
|------|---------|-------|
| `assets/img/stadium_field.png` | Full-screen football challenge arena background | 1280x720 |
| `assets/img/player_volley.png` | Fixed blue #10 volley shooter | Transparent PNG |
| `assets/img/launcher.png` | Ball feeder machine | Transparent PNG |
| `assets/img/ball_projectile.png` | Feed ball and kicked football | Transparent PNG |
| `assets/img/enemy_0.png` - `assets/img/enemy_3.png` | Advancing enemy variants | Transparent PNG |
| `assets/img/heart_icon.png` | Lives HUD | Transparent PNG |
| `assets/img/electric_icon.png` | Bottom HUD skill icon | Visual-only in v1 |
| `assets/img/target_icon.png` | Bottom HUD skill icon | Visual-only in v1 |
| `assets/img/fireball_icon.png` | Bottom HUD skill icon | Visual-only in v1 |

## Source Images

Original generated sheets are kept outside the Godot runtime asset tree at `_meta/generated_sources/`.

Regenerate processed runtime assets with:

```powershell
python tools/process_generated_assets.py
```

The processor removes chroma-key backgrounds, crops the sheets, resizes sprites, and writes the final PNG files to `assets/img/`.
