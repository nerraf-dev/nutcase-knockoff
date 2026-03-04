# Game Rules & Mechanics

> Based on the board game *In a Nutshell*.

## Round Flow

### Turn Order
- **First Round**: Players in list order (potentially randomized at game start)
- **Subsequent Rounds**: Winner of previous round goes first, then continues in list order
  - Example: P1→P2→P3→P4, P2 wins Round 1, Round 2 starts: P2→P3→P4→P1

### Question Lifecycle
1. Question loads, pot calculated based on difficulty
2. **On their turn, the current player chooses one action:**
   - **Reveal a slider** — one tile is uncovered:
     - If it contains a **word**: pot reduces by `prize_per_word`, turn passes to next player
     - If it is **blank**: player gets a **free pick** — no pot reduction, turn does **not** pass, they may immediately reveal another tile or submit a guess
   - **Submit a guess** — see Incorrect/Correct Answer below
3. Only the current (unfrozen) player can take any action — no other player can reveal or guess out of turn
4. Answer submitted → Correct or Incorrect handling

## Scoring System

### Pot (Prize)
- Starting value: `BASE_POT × difficulty_multiplier` (e.g. 100 × 1.5 = 150 for medium)
- Each word revealed reduces the pot by `prize_per_word = (pot - minimum_pot) / word_count`
- Minimum pot: 10% of starting value — always guaranteed regardless of how many words are revealed
- Blank tiles (padding in the 3×3 grid) do **not** reduce the pot and do **not** advance the turn — the current player gets a **free pick** and continues their turn

### Answer Outcomes

When a player submits a guess, the answer is compared to the correct answer using Levenshtein distance scaled to answer length. There are four possible outcomes:

#### 1. Exact Match (distance = 0)
- Player receives full current pot value
- Round ends, winner starts next round
- No fanfare needed — clean and immediate

#### 2. Auto-Accept / Very Close (distance within auto-accept threshold)
- Answer is close enough to be unambiguously a typo (e.g. "avacado" / "avocado", "octogon" / "octagon")
- **Auto-accepted** — no player choice, no vote
- Player receives full current pot value
- A cheeky message is shown acknowledging it wasn't quite right but close enough
- Round ends
- *The distinction between this tier and the vote tier is the whole game — tune the threshold carefully*

#### 3. Fuzzy Match — Player Choice + Vote (distance within fuzzy threshold)
- Answer is recognisably related but not a clean typo — could be legitimately wrong or could be a rushed mobile answer
- **Player chooses**: stand by their answer, or concede (take it as incorrect)
  - If they **concede**: treated as Incorrect (see below) — no vote triggered
  - If they **stand by it**: vote is triggered
- **Vote phase:**
  - Both the submitted answer *and* the correct answer are shown to all players on screen and devices
  - All players except the submitter vote (including frozen players in normal play; all other players in LPS/2-player)
  - Simple majority decides — accepted or rejected
  - Timeout applies — if it expires, answer is **auto-accepted**
  - Round ends regardless of vote outcome (the correct answer has been revealed)
- If **accepted**: submitter receives full current pot value
- If **rejected**: treated as Incorrect (see below), but round still ends (answer has been revealed)

> **Why the round always ends after a vote:** once the correct answer is shown to all players during the vote phase, the round cannot continue — remaining players would already know the answer.

#### 4. Incorrect (distance exceeds fuzzy threshold)
- Player loses 50% of their **current score** (not pot value)
  - Example: 200 points → loses 100 points
- Player is **frozen** for the remainder of this question
- Turn advances to the next unfrozen player
- Round continues
- **Exception — Last Player Standing**: if only one unfrozen player remains after a freeze, they receive a free guess with no penalty (see below)

### Distance Threshold
- Thresholds are **relative to answer length**, not absolute
- Formula (provisional): `auto_accept ≤ max(1, answer_length / 8)`, `fuzzy ≤ max(2, answer_length / 5)`
- Short answers (≤ 4 chars) have tighter tolerances than long answers
- These values will need tuning based on playtesting

### Free Guess (Last Player Standing)
Triggered when all other players are frozen on the current question:
- Last player gets to answer without any score penalty if wrong
- Voting rules still apply if their answer falls in the fuzzy tier
- In a 2-player game where both conditions overlap (only one other player, who is frozen), all players including the frozen one vote

## Player States

### Active (Unfrozen)
- Can click sliders
- Can submit answers
- Participates in turn rotation

### Frozen
- Locked out for current question only
- Cannot interact with sliders or answer
- Skipped in turn rotation
- **Unfrozen at start of next round**

## Win Condition
- First player to reach target score (default: 1000)
- Check performed after each correct answer

## Constants

### Scoring
- `INCORRECT_ANSWER_PENALTY`: 0.5 (50% of player's score)
- `BASE_POT`: 100
- `MINIMUM_POT_PERCENT`: 0.1 (10% minimum guaranteed)

### Difficulty Multipliers
- Easy: 1.0x
- Medium: 1.5x
- Hard: 2.0x

## UI Indicators

### Player Badges
- **Current Player**: Visual indicator (color/highlight) showing whose turn it is
- **Leader**: Removed in favor of score display only
  - Consider: Color-coding badges by rank (1st, 2nd, 3rd, etc.)

## Future Considerations
- Question word limit enforcement (10-12 words)
- Round timer (optional)
- Streak bonuses for consecutive correct answers
- Tune fuzzy/auto-accept distance thresholds based on playtesting
- Vote timeout duration (needs to feel snappy — current thinking: 10-15 seconds)
