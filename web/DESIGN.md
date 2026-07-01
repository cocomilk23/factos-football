## Style Prompt

Factos Football uses a fast mobile-first loading shell: lightweight CSS-only night pitch, crisp title, simple progress, and no external visual or audio assets before Godot boots.

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
- Keep the shell fast: CSS-only background, crisp title, and lightweight progress only.
- Do not add decorative balls, shot trails, scanlines, background images, loading music, or background scale animations to the loader.
- Loading progress must remain legible and calm, not noisy.

## What Not To Do

- Do not show Godot branding.
- Do not use generic black loading screens.
- Do not put UI text into the generated background image.
- Do not rely on external network fonts or scripts for first load.
- Do not block the game from booting if decorative loading assets fail.
