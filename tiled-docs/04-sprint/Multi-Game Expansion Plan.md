# Tiled Multi-Game Expansion Plan

## Purpose

This plan is for after Tiled v1 ships and the core reveal loop has been validated.

Do not use this plan to justify expanding v1 scope early.

## Expansion Principle

New game types should earn their place by reusing enough of the existing host, controller, session, and content architecture to justify staying in the same product.

If a new mode needs a substantially different player contract, moderation model, UI model, or scoring model, it may belong in a separate branch or product.

## Expansion Goals

- keep the reveal identity central
- broaden replayability without losing clarity
- reuse as much of the working architecture as possible
- avoid turning Tiled into an unfocused bundle of barely-related mini-games

## Candidate Direction

### Mode family: Hidden image reveal
Players reveal tiles covering an image, then guess before too much of the image is exposed.

Potential strengths:
- strong visual hook
- easy to understand quickly
- good fit for the reveal theme

Potential risks:
- content creation cost is higher
- image difficulty balancing may be harder than text balancing
- controller UX may diverge if interactions change too much


### Mode family: Clue ladder / layered hints
Players uncover clues one at a time, with score dropping as more clues are shown.

Potential strengths:
- strongly aligned with the current text reveal loop
- likely reuses content and validation structure well
- easier to author than image-heavy modes

Potential risks:
- may feel too close to the existing mode unless differentiated well
- requires careful pacing so rounds do not blur together

## Expansion Strategy

### Phase 1: Architectural review
Before building new modes, identify what is actually reusable:
- round lifecycle
- player turn handling
- scoring pot logic
- controller input patterns
- answer validation
- reveal presentation system
- content schema and pack loading

### Phase 2: Prototype two modes on paper
Document:
- core player action each turn
- what gets revealed
- how score changes
- how guesses are submitted and resolved
- what makes the mode distinct from the base game

### Phase 3: Build one low-risk mode first
Choose the mode that:
- reuses the most existing systems
- has the lowest content production cost
- is easiest to explain to players in one sentence

### Phase 4: Add a second mode only if the first proves the architecture
Do not build two new modes in parallel until one has shown that the shared systems are real rather than assumed.

## Decision Filter For Any New Mode

A new mode should answer yes to most of these:
- Does it still feel like Tiled?
- Does the reveal mechanic stay central?
- Can it reuse current session flow and controller flow?
- Can it be explained quickly in a room?
- Can content be produced at a sustainable pace?
- Does it add meaningfully different play, not just different assets?

## Suggested Order

1. Ship and observe v1.
2. Prototype clue-based expansion first.
3. Prototype hidden-image mode second.
4. Build the one with the best clarity-to-effort ratio.
5. Reassess whether the second mode still belongs in Tiled.

## Risks

- adding modes too early may dilute polish on the main game
- content pipelines may diverge faster than expected
- UX complexity may increase faster than player value
- a mode can be interesting in design docs but weak in live play

## Exit Criteria

A multi-mode Tiled direction is justified when:
- v1 is stable enough that core maintenance is not consuming all effort
- the shared architecture is clearly reusable
- the second mode feels distinct in playtests
- content creation for the new mode is sustainable
- the product still reads as one game identity, not a grab bag
