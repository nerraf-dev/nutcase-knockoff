# 1P Mode: Remove or Keep

## Background

1P mode was added during early scaffolding to test menus, buttons, keyboard/mouse/controller input, and basic game loop flow without needing multiple devices. The underlying game logic works with a single player, so an explicit 1P path was never removed.

## The Case for Removing It

- It is scaffolding presented as a feature. Players will read it as a real game choice.
- Solo play is not the product. The fun of this game is social: guessing, judging fuzzy answers, reacting to reveals together.
- Having the choice on the setup screen adds a question for every new player: "which should I pick?" That friction costs goodwill at the worst possible moment — first impression.
- Removing it simplifies the setup page, which directly reduces the label/mode confusion that also needs resolving when the End Condition Design is implemented.
- Anyone genuinely wanting to test solo can still launch multiplayer alone. The game will function. They just don't need a dedicated path for it.

## The Case for Keeping It

- If the 1P code path is used implicitly by headless tests or solo dev testing, removing it could require rerouting those flows.
- A solo "practice" mode is not absurd as a product concept — but it would need to be intentionally designed, not inherited by accident.

## Recommendation

Remove 1P as a player-facing mode.

If any internal test tooling relies on 1P game state, either preserve that as a dev-only shortcut (not exposed in the player UI) or check whether the multiplayer solo path covers the same cases.

## What Removing It Enables

- Simpler setup screen — one fewer choice, one fewer label to name
- Cleaner "Mode" concept elimination — if 1P is gone, the remaining configuration question is just how many players, which is handled by join flow naturally
- The setup page rename can focus on the remaining real choices: rounds format, categories, target score/count

## Timing

This is a short code change and a meaningful product clarity improvement. It is worth doing before the first external testers see the game.
