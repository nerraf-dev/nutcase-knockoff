param(
	[string]$GodotExe = $env:GODOT_EXE,
	[string]$TestScript = "res://tests/godot/vote_multiplayer_headless_scaffold.gd",
	[string]$ProjectPath = "."
)

function Resolve-GodotExeFromDirectory {
	param([string]$DirectoryPath)

	if (-not (Test-Path $DirectoryPath)) {
		return $null
	}

	# Prefer console binary for clean headless logs on Windows.
	$consoleCandidates = Get-ChildItem -Path $DirectoryPath -Filter "*console*.exe" -File -ErrorAction SilentlyContinue | Sort-Object Name
	if ($consoleCandidates -and $consoleCandidates.Count -gt 0) {
		return $consoleCandidates[0].FullName
	}

	$fallbackCandidates = Get-ChildItem -Path $DirectoryPath -Filter "*.exe" -File -ErrorAction SilentlyContinue | Sort-Object Name
	if ($fallbackCandidates -and $fallbackCandidates.Count -gt 0) {
		return $fallbackCandidates[0].FullName
	}

	return $null
}

if ($GodotExe -and (Test-Path $GodotExe) -and (Get-Item $GodotExe).PSIsContainer) {
	$resolved = Resolve-GodotExeFromDirectory -DirectoryPath $GodotExe
	if ($resolved) {
		$GodotExe = $resolved
	}
}

if (-not $GodotExe) {
	$cmd = Get-Command godot -ErrorAction SilentlyContinue
	if ($cmd) {
		$GodotExe = $cmd.Source
	}
}

if (-not $GodotExe) {
	$candidates = @(
		"D:\Godot\Editors\4.6.1-stable\Godot_v4.6.1-stable_win64_console.exe",
		"D:\Godot\Editors\4.6.1-stable\Godot_v4.6.1-stable_win64.exe",
		"D:\Godot\Editors\4.6.1-stable",
		"D:\Godot\Editors",
		"$env:ProgramFiles\Godot\Godot.exe",
		"$env:ProgramFiles\Godot\godot.exe",
		"$env:LOCALAPPDATA\Programs\Godot\Godot.exe"
	)
	foreach ($candidate in $candidates) {
		if (-not (Test-Path $candidate)) {
			continue
		}

		if ((Get-Item $candidate).PSIsContainer) {
			$resolved = Resolve-GodotExeFromDirectory -DirectoryPath $candidate
			if ($resolved) {
				$GodotExe = $resolved
				break
			}
		}
		else {
			$GodotExe = $candidate
			break
		}
	}
}

if (-not $GodotExe) {
	Write-Error "Could not find Godot executable. Add 'godot' to PATH or set GODOT_EXE."
	exit 1
}

if (-not (Test-Path $ProjectPath)) {
	Write-Error "Project path not found: $ProjectPath"
	exit 1
}

Write-Host "Running headless test: $TestScript"
Write-Host "Using Godot executable: $GodotExe"

& $GodotExe --headless --path $ProjectPath -s $TestScript
exit $LASTEXITCODE
