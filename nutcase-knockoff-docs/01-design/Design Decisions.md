# Design Decisions

This document tracks the current rules, open questions, and alternatives for core game mechanics. Update this as you iterate!

---

## Scoring System


**Current Implementation/Preference:**
- Pot starts at a base value, modified by question difficulty.
- Pot reduces by a fixed amount per word revealed (preferred mechanic).
- Winner of the round gets the remaining pot.

**Future Ideas:**
- Combine score and board movement (e.g., move around a board based on points earned).
- Board/score system could be added as an extra mode later.

**Open Questions:**
- Should scoring be a fixed amount per question, per word, or based on difficulty?
- Should incorrect guesses lose a fixed amount, the current pot, or a percentage of the pot?
- Should there be bonus points for quick/early guesses?

**Alternatives Considered:**
- Fixed score per question (e.g., 10 points each)
- Variable score per word revealed
- Percentage loss for incorrect guesses

**Notes/TODO:**
- Playtest different penalty systems for incorrect guesses.
- Decide if bonus points for early guesses are fun/fair.

---

## Game Modes & Extensibility

**Goal:**
- Build the core logic so it is easy to add extra game modes in the future (e.g., board mode, speed mode, team mode).
- Keep game rules and win conditions modular (consider separate GameMode scripts/classes).

**Current Focus:**
- Get the basics up and running: a working 2+ player game with pot reduction and scoring.
- Avoid overcomplicating the MVP; document future ideas for later implementation.

---

## Win Condition

**Current Implementation:**
- (Describe what is currently coded: e.g., first to X points, best of N rounds, etc.)
- Considering both score-based and board-based win conditions for future modes.

**Open Questions:**
- Should the game be best of N rounds, first to X points, or another system (e.g., climb a ladder)?
- Should there be a board or visual progress indicator?

**Alternatives Considered:**
- First to X points
- Best of N rounds
- Ladder/board progression

**Notes/TODO:**
- Try out different win conditions in playtests.

---

## Player Penalties

**Current Implementation:**
- Incorrect guess freezes player for the round.

**Open Questions:**
- Should frozen players lose points?
- Should penalties scale with pot size?

**Alternatives Considered:**
- Fixed penalty
- Percentage penalty
- No penalty (just frozen)

**Notes/TODO:**
- Gather feedback on penalty impact.

---

## Other Open Questions
- Should there be categories/tags for questions?
- How to handle ties?
- Should there be a timer for guesses?

---

## Playtest Feedback
(Add notes here after each playtest: what worked, what didn’t, what you want to try next)

---

## Change Log
- 2025-12-31: Created initial design decisions doc.
 - 2025-12-31: Added pot reduction preference, extensibility notes, and MVP focus.
