## Style Prompt

Factos Football uses a premium mobile pixel-art sports style: cinematic night training pitch, crisp grass texture, teal stadium light, warm golden volley energy, and small red enemy accents. The loading shell should feel like the game is already alive before Godot finishes booting.

## Colors

- Field Night: `#03170f` for the base page background.
- Grass Shadow: `#0b3520` for dark panels and overlays.
- Stadium Cyan: `#63e8ff` for technical UI lines and progress.
- Volley Gold: `#ffd34a` for the football glow and key highlight.
- Enemy Red: `#ff4a3d` for small warning accents only.

## Typography

- Display: `Arial Black`, `Impact`, system sans fallback. Heavy, compact, arcade-sports energy.
- Data/UI: `Consolas`, `Menlo`, monospace fallback for percent and boot labels.

## Motion

- Deterministic CSS motion only. No random drift.
- Ambient scanlines and subtle pitch breathing.
- The ball pulses and rises along the same center-lane energy as the game shot fantasy.
- Loading progress must remain legible and calm, not noisy.

## What Not To Do

- Do not show Godot branding.
- Do not use generic black loading screens.
- Do not put UI text into the generated background image.
- Do not rely on external network fonts or scripts for first load.
- Do not block the game from booting if decorative loading assets fail.
