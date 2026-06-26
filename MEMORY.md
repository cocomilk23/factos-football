# Memory

- Godot 4.7 Mono is installed at `D:\Codex\godogen-tools\godot\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe`.
- `.NET 9 SDK` winget installation stalled, so the first playable version uses Godot GDScript instead of C#.
- Standard Godot 4.7 is installed at `D:\Codex\godogen-tools\godot-standard\Godot_v4.7-stable_win64_console.exe` and is the verified runtime for this project.
- The user explicitly requested Godot only; no HTML fallback should be built.
- Visual polish pass uses generated PNG assets through the built-in Codex image generation flow; no `OPENAI_API_KEY` is required for the user.
- Version 2 art direction was changed per user request to premium pixel art, using the provided screenshot only as style reference.
- Runtime images live in `assets/img/`; original generated sheets live in `_meta/generated_sources/` with `.gdignore` so Godot does not import them into the game.
- `tools/process_generated_assets.py` rebuilds transparent runtime PNG assets from the pixel-art generated sheets and uses nearest-neighbor resizing.
- Version 2 gameplay adds four-frame player volley animation, visibly stronger curved football preview/trails, six enemy profiles, enemy HP, curve bonuses, perfect streaks, and a Focus skill on `E` / right mouse.
- Verification passed with:
  - `Godot_v4.7-stable_win64_console.exe --headless --path . --import --quit`
  - `Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 90`
  - `Godot_v4.7-stable_win64_console.exe --headless --path . --script res://test/SmokeTest.gd`
  - `Godot_v4.7-stable_win64_console.exe --path . --write-movie screenshots/polish/frame.png --fixed-fps 30 --quit-after 60`
  - `Godot_v4.7-stable_win64_console.exe --path . --write-movie screenshots/pixel_v2b/frame.png --fixed-fps 30 --quit-after 60`
