$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Godot = "D:\Codex\godogen-tools\godot-standard\Godot_v4.7-stable_win64_console.exe"

if (-not (Test-Path $Godot)) {
    throw "Godot executable not found: $Godot"
}

& $Godot --path $ProjectRoot
