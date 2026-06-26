# Volley Shot Survivor

## Dimension

2D Godot project using GDScript.

## Input Actions

| Action | Keys |
|--------|------|
| shoot | Space |
| restart | R |
| skill | E |

Mouse:
- Hold/release left mouse button mirrors `shoot`.
- Mouse horizontal position controls aim angle and bend direction.
- Right mouse button activates Focus when charged.

## Scenes

### Main
- **File:** `res://scenes/main.tscn`
- **Root type:** `Node2D`
- **Script:** `res://scripts/Main.gd`
- **Responsibilities:** Owns game state, pixel-art image drawing, input, ball feeding, volley shots, enemy profiles, scoring, Focus skill, UI, and restart.

## Scripts

### Main
- **File:** `res://scripts/Main.gd`
- **Extends:** `Node2D`
- **Instantiates:** No child scenes in v2; uses arrays of dictionaries for feed ball, shot balls, enemies, particles, impact effects, and floating text.

## Asset Hints

- Runtime pixel art is in `res://assets/img/`.
- Original pixel-art generated sheets are in `_meta/generated_sources/v3_pixel_*.png`.
- `tools/process_generated_assets.py` crops and converts generated sheets into transparent runtime sprites.
- Player animation uses `player_frame_0.png` through `player_frame_3.png`.
- Most gameplay feedback still comes from code: predicted curve path, ball trails, particles, shake, hit text, power bar, wave bar, Focus meter, and skill icons.

## Build Order

1. Godot runs `res://scenes/main.tscn` directly.
2. No generated scene builders are required for the GDScript prototype.
