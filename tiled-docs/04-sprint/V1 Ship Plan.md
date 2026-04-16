# Tiled V1 Ship Plan

## Positioning

Tiled v1 should ship as a simple, family-friendly reveal game.

The goal is not to prove every future direction. The goal is to prove that one reveal-based party game loop is fun, reliable, easy to understand, and easy to share.

## Product Constraint

- Prefer a single executable distribution.
- Avoid loose external folders where possible.
- Accept temporary implementation compromises if they preserve a simpler player-facing package.
- Keep the host flow and mobile controller flow fast and low-friction.

## V1 Outcome

A player can:
- launch the game with minimal setup
- start a local multiplayer session
- join with phones reliably
- play a polished family-friendly round loop
- complete several rounds without confusion or technical issues

## Core Scope

### Must ship
- stable host and controller connection flow
- reliable QR/controller join experience
- one polished reveal game type
- enough family-friendly question content to feel like a real release
- answer validation that feels fair and predictable
- scoring and round transitions that are clear
- basic onboarding and instructions
- export/build process that is repeatable
- smoke tests for the main gameplay flow

### Nice to have if cheap
- basic category selection
- more visual polish on lobby and round transitions
- improved local test tooling for multiple controllers
- lightweight analytics via playtest notes rather than instrumentation

### Not for v1
- multiple major game modes
- cheeky/adult content branch as a separate product
- classroom-specific features
- open-ended content framework work beyond what directly helps v1
- question sprint / alternative end condition format (see [[End Condition Design]])

## Release Priorities

### 1. Stability first
- no broken joins
- no broken round flow
- no export-specific missing assets
- no dead-end controller states

### 2. Comprehension second
- players understand reveal vs guess
- players understand score/pot changes
- players understand why answers were accepted, challenged, or rejected

### 3. Content third
- enough prompts to avoid repetition in short sessions
- categories and phrasing that suit family play
- consistent tone across packs

### 4. Presentation fourth
- attractive enough for itch.io
- clear enough to stream or couch-play
- light enough that setup does not feel technical

## Suggested Workstreams

### Gameplay loop
- finalize the single game mode rules
- remove edge-case confusion in turn flow
- ensure guess, reveal, vote, and resolution states are deterministic

### Controller reliability
- lock down the packaged controller experience
- keep single-exe distribution as the product goal
- document any temporary technical compromises that support that goal

### Content
- define a minimum content target for launch
- review prompts for clarity, tone, duplicates, and difficulty spread
- separate content cleanup from mechanic changes

### Testing
- maintain headless tests for validation logic and vote flow
- add smoke checks for exported controller behavior where possible
- create a simple regression checklist for playtest sessions

### Release prep
- create itch.io page assets and short description
- document known limitations honestly
- ship free and use playtesting feedback to decide the next branch

## Exit Criteria

Tiled v1 is ready when:
- the main game loop is consistently fun in repeat playtests
- joining from phones is reliable enough that it is no longer the main topic of testing
- the family-friendly content pool is large enough for short sessions
- exported builds behave like the editor build in the core flow
- the game can be handed to someone else without live developer support

## Open Questions

- What is the launch content target by question count and category count?
- How many players should v1 officially support with confidence?
- Which rule variants are real features, and which are just unresolved design choices?
- What is the minimum acceptable polish bar for an itch.io release?
- Should 1P mode be removed before external testers see the build? (see [[1P Mode Decision]])
- What numeric values should Short/Medium/Long map to if labels are replaced?

## Immediate Next Steps

1. Finish and stabilize the current family-friendly game mode.
2. Build out launch-worthy content for that mode.
3. Tighten export and controller reliability.
4. Run focused playtests and fix the repeated confusion points.
5. Ship on itch.io before expanding the product surface.
