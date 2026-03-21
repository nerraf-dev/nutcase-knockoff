## Plan: Multiplayer Guess Flow + Reveal + Docs/Test Pass

Stabilize the current cleanup by enforcing mode-specific input behavior, making answer visibility consistent, and adding documentation visuals plus targeted smoke tests so regression checks are faster and clearer.

**Steps**
1. Phase 1 - Modal routing by mode: update the guess click and free-guess modal entry points so modal UI is single-player only, while multiplayer continues to use controller-submitted guesses.
2. Phase 1 - Routing verification (depends on 1): confirm multiplayer still flows through network guess signals and single-player local modal flow remains unchanged.
3. Phase 2 - Correct-answer reveal: update resolution flow so canonical answer is always revealed after correct outcomes in both local and multiplayer, with stable ordering after score/badge updates.
4. Phase 2 - Incorrect-share broadcast (parallel with 3 once payload shape is agreed): broadcast guessed text plus incorrect result message to other multiplayer participants.
5. Phase 2 - Fuzzy/vote visibility closure (depends on 3 and 4): wire final vote outcome + answer reveal across multiplayer so this is no longer host-only.
6. Phase 3 - Documentation refresh (parallel with 4 if split): update technical docs and add Mermaid diagrams for round state machine, multiplayer turn flow, voting sequence, and freeze lifecycle.
7. Phase 4 - Smoke test uplift (depends on 1-6): add focused tests for modal behavior by mode, network guess routing, correct-answer reveal, and incorrect-share behavior.
8. Phase 4 - Verification loop (depends on 7): run manual smoke checklist + headless tests, then log residual follow-ups in sprint notes.

**Relevant files**
- [nutcase-knockoff/scenes/components/rounds/qna.gd](nutcase-knockoff/scenes/components/rounds/qna.gd) - Guess click and free-guess modal guard points.
- [nutcase-knockoff/scenes/screens/game_board.gd](nutcase-knockoff/scenes/screens/game_board.gd) - Network guess handling, round result routing, overlay/reveal ordering, fuzzy vote hook points.
- [nutcase-knockoff/scripts/autoload/NetworkManager.gd](nutcase-knockoff/scripts/autoload/NetworkManager.gd) - Multiplayer broadcast methods for reveal/share events.
- [nutcase-knockoff/scripts/autoload/GameManager.gd](nutcase-knockoff/scripts/autoload/GameManager.gd) - Result orchestration contract and payload continuity.
- [nutcase-knockoff/scripts/logic/RoundResolutionHelper.gd](nutcase-knockoff/scripts/logic/RoundResolutionHelper.gd) - Correct/incorrect result shaping and answer source behavior.
- [nutcase-knockoff/scenes/components/vote_modal.gd](nutcase-knockoff/scenes/components/vote_modal.gd) - Fuzzy vote completion timing and reveal consistency.
- [nutcase-knockoff/scenes/tests/answer_modal_test.gd](nutcase-knockoff/scenes/tests/answer_modal_test.gd) - Existing test style reference.
- [nutcase-knockoff/scenes/tests/answer_modal_headless_test.gd](nutcase-knockoff/scenes/tests/answer_modal_headless_test.gd) - Headless smoke pattern to extend.
- [nutshell-knockoff-docs/02-technical/Networking Architecture.md](nutshell-knockoff-docs/02-technical/Networking%20Architecture.md) - Message contracts and multiplayer sequence docs.
- [nutshell-knockoff-docs/02-technical/Game Flow.md](nutshell-knockoff-docs/02-technical/Game%20Flow.md) - Round-end, freeze, reveal, and voting flow updates.
- [nutshell-knockoff-docs/02-technical/Player Management.md](nutshell-knockoff-docs/02-technical/Player%20Management.md) - Freeze lifecycle and player-device relationship.
- [nutshell-knockoff-docs/02-technical/Managers.md](nutshell-knockoff-docs/02-technical/Managers.md) - Responsibility boundaries with networking/result flow.
- [nutshell-knockoff-docs/04-sprint/2026-03-15-handoff.md](nutshell-knockoff-docs/04-sprint/2026-03-15-handoff.md) - Handoff notes and smoke-test outcomes.

**Verification**
1. Manual: single-player guess opens modal and resolves as expected.
2. Manual: multiplayer host guess click does not open modal; controller guess still resolves round.
3. Manual: correct answer always shows canonical reveal in local and multiplayer.
4. Manual: incorrect multiplayer guess shares guessed text + result message to other players/controllers.
5. Manual: fuzzy/vote path communicates final accepted/rejected result and answer across multiplayer.
6. Automated: existing and new headless smoke tests pass under [nutcase-knockoff/scenes/tests](nutcase-knockoff/scenes/tests).
7. Regression: turn progression, frozen-skip behavior, and last-standing/free-guess behavior remain stable.

**Decisions captured**
- Included scope: code + testing + docs/diagrams in one pass.
- Reveal behavior: always reveal canonical answer on correct.
- Multiplayer incorrect-share: include guessed text and result message.
- Diagram format: Mermaid in markdown.
- Out of scope: broad architecture rewrite beyond targeted flow/broadcast fixes.

**Further Considerations**
1. If message ordering becomes noisy, prefer one consolidated multiplayer round-result broadcast payload over multiple event-specific messages.
2. If free-guess rules differ between local and multiplayer, codify that explicitly in Game Flow.md to avoid future regressions.
3. If smoke tests expose race conditions, add deterministic timing helpers for overlay async completion in test harness.
