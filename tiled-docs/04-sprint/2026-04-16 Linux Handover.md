# Linux Handover (2026-04-16)

## Current Snapshot

- Repo: `LittleCogWorks/tiled`
- Branch: `main`
- Last smoke run on current machine: pass (`run-godot-smoke.ps1`, 3/3)
- Current focus: v1 polish + external tester readiness, no major gameplay blockers found

## What Was Changed Recently

### Overlay interaction locking (background controls)
- Setup confirm modal now disables background button interaction while visible.
- Home exit dialog now disables menu controls while visible and restores on close.
- Game board exit dialog now disables HUD/round interaction while visible and restores on close.

### Type-safety cleanup from those changes
- `game_init.gd` now uses `BaseButton` where mixed button types are used (fixes TextureButton type mismatch).
- `game_home.gd` and `game_board.gd` were adjusted to avoid brittle inferred typing in overlay loops.

### Setup flow simplification
- 1P/MP mode selection is hidden in setup UI.
- `game_mode` remains defaulted to `multi` in settings.

### Messaging
- One exact-correct transition line was made more game-like in `RoundResolutionHelper.gd`.

## Known Pending Work

1. Transition message pass
- Replace/expand generic round messages with stronger game-feel copy.

2. Controller join flow redesign (logic first, styling second)
- Target flow: Connect -> default profile appears -> edit name/avatar -> Ready.

3. Viewport framing decision
- Current project stretch uses `expand`; if you want hard framing without extra visible area in windowed mode, switch to `keep`.

4. Optional cleanup
- Overlay-lock code works but could be reduced to a lighter helper style once stable.

## Linux Bring-Up Checklist (First Hour)

1. Install matching Godot version and export templates.
2. Open project and let imports settle.
3. Verify no case-sensitive resource path breaks.
4. Run smoke tests.
5. Run one local controller join test from a phone on LAN.
6. Verify overlays block background interactions on:
   - Home exit dialog
   - Setup confirm modal
   - In-game exit dialog

## Smoke Test Commands

If PowerShell is available on Linux:

```bash
cd tiled
pwsh ./run-godot-smoke.ps1
```

If not, run tests directly with Godot headless:

```bash
cd tiled
godot --headless --path . -s res://scenes/tests/input_validator_test.gd
godot --headless --path . -s res://scenes/tests/answer_modal_headless_test.gd
godot --headless --path . -s res://scenes/tests/vote_multiplayer_headless_scaffold.gd
```

## Linux-Specific Watchouts

- Case-sensitive file paths can break scene/resource loads that worked on Windows.
- Ensure executable permissions for any shell scripts you add.
- Re-check firewall/LAN permissions for controller URL access.
- Confirm fonts and text layout still look correct across your target desktop environment.

## Resume Here Next

1. Confirm overlay-lock behavior manually on Linux.
2. Decide stretch framing (`expand` vs `keep`) and lock it for v1.
3. Do a short transition-copy pass (at least correct-answer + pre-question lines).
4. Capture final external tester checklist and ship the next build.
