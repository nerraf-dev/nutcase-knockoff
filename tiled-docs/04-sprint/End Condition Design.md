# End Condition Design

## The Idea

Two distinct win conditions for a Tiled session:

1. **Score race** — first player to reach a target score wins. Session length is unpredictable but tension increases as someone approaches the goal. (This is the current model.)
2. **Question sprint** — fixed number of questions (e.g. 5 / 10 / 20), highest cumulative score at the end wins. Session length is known in advance.

These are orthogonal to game type (the reveal mechanic) and to player count mode. They should not be coupled to either.

## Why Both

Score race suits a relaxed social session where you play until someone wins and stop naturally. It rewards staying engaged.

Question sprint suits a structured context — pub quiz style, classroom, or a session with a fixed time window — because players know when it ends and can calibrate effort accordingly.

Both feel legitimate in the same product.

## Naming

**Avoid "Game Mode"** — already mentally occupied by 1P/MP distinction (even if that is removed).

Candidate term: **Format**

- Format: Score Race / Question Sprint

Clear, neutral, doesn't collide with other label choices. Could also show the specific target:
- Score Race to 500
- Best of 10 Questions

## How Close to the Current Build Is This

This is probably simpler to implement than it sounds, because the scoring and round flow do not need to change — only the end condition check does.

### Score Race (current)
Check after each resolution: has any player reached target score? If yes, end session.

### Question Sprint
Track current question index. After each resolution: has index reached N? If yes, end session.

Neither requires changes to validation logic, scoring per round, controller flow, or reveal presentation.

The session setup screen would need:
- a Format picker (Score Race / Question Sprint)
- a target value picker (score threshold or question count)
- the current Short/Medium/Long could map to specific targets, or could be replaced by numeric values

## The Setup Page Labelling Problem

Current setup page has a "game length" picker using Short/Medium/Long. This worked for one end condition model.

With two formats:
- Short/Medium/Long stops making semantic sense for Question Sprint (is "Short" 5 questions or 10?)
- The existing labels could still map: Short = 5 questions or 200pts, Medium = 10 or 350pts, Long = 20 or 500pts
- Or explicit numeric values could replace the labels — player sees exactly what they're choosing

The setup page rename question (what to call the section that was "Mode") is separate from this, but they should be resolved at the same time to avoid two half-baked passes at the same page.

## Hold Until After V1

Do not implement this in V1. The current score race model is sufficient.

Add this to V1's "Open Questions" list so it isn't lost. When v1 is validated through external testing, this is a strong candidate for the first meaningful post-launch addition — it's architecturally clean and adds genuine replay variety.

## Implementation Note for When Ready

The safest path:
1. Add a `win_condition` enum to GameConfig: `SCORE_RACE`, `QUESTION_SPRINT`
2. Add `win_condition_target: int` (score or question count)
3. Move end-condition check into a single helper in the round resolution path
4. Update setup UI to expose format picker and target value
5. Update any "player-visible" status display to reflect the active format (e.g. "Round 3 of 10" vs "First to 500")

No changes required to: scoring logic, validation, controller flow, reveal presentation, or content schema.
