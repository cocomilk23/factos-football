# Memory

- Godot 4.7 Mono is installed at `D:\Codex\godogen-tools\godot\Godot_v4.7-stable_mono_win64\Godot_v4.7-stable_mono_win64_console.exe`.
- `.NET 9 SDK` winget installation stalled, so the first playable version uses Godot GDScript instead of C#.
- Standard Godot 4.7 is installed at `D:\Codex\godogen-tools\godot-standard\Godot_v4.7-stable_win64_console.exe` and is the verified runtime for this project.
- The user explicitly requested Godot only; no HTML fallback should be built.
- Verification passed with:
  - `Godot_v4.7-stable_win64_console.exe --headless --path . --import --quit`
  - `Godot_v4.7-stable_win64_console.exe --headless --path . --quit-after 90`
  - `Godot_v4.7-stable_win64_console.exe --headless --path . --script res://test/SmokeTest.gd`
