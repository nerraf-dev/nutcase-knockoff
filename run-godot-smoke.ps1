param(
	[string]$GodotExe = $env:GODOT_EXE,
	[string]$ProjectPath = ".\nutcase-knockoff"
)

$tests = @(
	"res://scenes/tests/answer_modal_headless_test.gd",
	"res://scenes/tests/vote_multiplayer_headless_scaffold.gd"
)

$failed = 0

foreach ($test in $tests) {
	Write-Host ""
	Write-Host "=== Running: $test ==="
	& ".\run-godot-headless.ps1" -GodotExe $GodotExe -ProjectPath $ProjectPath -TestScript $test
	$code = $LASTEXITCODE
	if ($code -ne 0) {
		$failed += 1
		Write-Host "[FAIL] $test (exit $code)"
	}
	else {
		Write-Host "[PASS] $test"
	}
}

Write-Host ""
if ($failed -eq 0) {
	Write-Host "Smoke suite passed: $($tests.Count)/$($tests.Count)"
	exit 0
}

Write-Host "Smoke suite failed: $failed test(s) failed"
exit 1
