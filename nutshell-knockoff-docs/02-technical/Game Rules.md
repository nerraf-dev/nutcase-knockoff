# Game Rules & Mechanics

## Round Flow

### Turn Order
- **First Round**: Players in list order (potentially randomized at game start)
- **Subsequent Rounds**: Winner of previous round goes first, then continues in list order
  - Example: P1→P2→P3→P4, P2 wins Round 1, Round 2 starts: P2→P3→P4→P1

### Question Lifecycle
1. Question loads, pot calculated based on difficulty
2. Players take turns clicking sliders (reveals words, may reduce pot)
3. Current player can guess at any time
4. Answer submitted → Correct or Incorrect handling

## Scoring System

### Correct Answer
- Player receives full current pot value
- Round ends
- Winner starts next round

### Incorrect Answer
- Player loses 50% of **current score** (not pot value)
  - Example: Player has 200 points → Loses 100 points
- Player is **frozen** for remainder of that question
- Turn advances to next unfrozen player
- **Exception - Last Player Standing**:
  - If only 1 unfrozen player remains, they get a "free guess"
  - No point penalty if wrong
  - Acts as safety mechanism

### Free Guess Conditions
Triggered when:
- All other players are frozen on current question
- Last player gets to answer without risk

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
- Pot reduction per slider reveal (currently disabled)
- Question word limit enforcement (10-12 words)
- Round timer (optional)
- Streak bonuses for consecutive correct answers
