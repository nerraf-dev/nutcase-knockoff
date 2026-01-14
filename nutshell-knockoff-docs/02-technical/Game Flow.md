# Game Flow Documentation

## Complete Game Loop

### 1. Application Start
```
Main._ready()
  └─> load_splash_screen()
      └─> SplashScreen displays
          └─> emit splash_complete
```

### 2. Home Screen
```
_on_splash_complete()
  └─> load_game_home()
      └─> GameHome displays
          └─> User clicks "New Game"
              └─> emit new_game
```

### 3. Game Setup
```
_on_new_game()
  └─> load_game_init()
      └─> GameInit displays
          └─> User adds players (calls PlayerManager.add_player())
          └─> User selects game settings
          └─> User clicks "Confirm"
              └─> emit game_init_complete(settings)
```

### 4. Game Initialisation
```
_on_game_init_complete(settings)
  └─> GameManager.start_game(settings)
      ├─> Create new Game instance
      ├─> Load questions from JSON
      ├─> Clear used_question_ids
      └─> emit game_started
  └─> load_game_board()
```

### 5. Game Board Setup
```
GameBoard._ready()
  ├─> _setup_players_hud()
  │   └─> For each player in PlayerManager.players:
  │       └─> Create player badge
  │       └─> Call badge.setup(player)
  └─> _setup_round_area()
      ├─> Load QnA scene
      ├─> Instantiate QnA
      ├─> Add to round_area
      └─> Connect "round_result" signal
```

### 6. Round Start
```
QnA._ready()
  ├─> Get current player from PlayerManager
  ├─> Update current_player_label
  └─> Get first question from GameManager
      └─> start_new_question(question)
          ├─> Clear old sliders
          ├─> Calculate pot based on difficulty
          ├─> Split question into words
          └─> Spawn slider for each word
```

### 7. Gameplay Loop

#### Slider Click
```
User clicks slider
  └─> _on_slider_clicked()
      ├─> Reduce pot (optional)
      ├─> PlayerManager.next_turn()
      └─> Update current_player_label
```

#### Answer Submission
```
User clicks "Guess" button
  └─> _on_guess_btn_pressed()
      └─> Show answer modal
          └─> User enters answer
              └─> _on_answer_submitted(answer_text)
                  ├─> Check if correct
                  └─> emit round_result(player, is_correct, points)
```

### 8. Round Result Handling
```
GameBoard._on_round_result(player, is_correct, prize)
  ├─> IF correct:
  │   └─> PlayerManager.award_points(player, prize)
  │
  ├─> ELSE incorrect:
  │   ├─> Calculate penalty = player.score * 0.5
  │   └─> PlayerManager.award_points(player, -penalty)
  │
  ├─> _update_all_badges()
  │   └─> For each badge:
  │       ├─> Update score display
  │       └─> Highlight current player
  │
  └─> Check for winner
      ├─> GameManager.check_for_winner()
      │
      ├─> IF winners.is_empty():
      │   ├─> Wait 1 second (placeholder for round summary)
      │   └─> _start_next_round()
      │       ├─> GameManager.get_next_question()
      │       ├─> PlayerManager.unfreeze_all_players()
      │       ├─> Increment game.current_round
      │       └─> qna_instance.start_new_question(question)
      │
      └─> ELSE (winner found):
          ├─> GameManager.game_ended.emit(winner)
          └─> Disable round_area input
```

### 9. Game End
```
Winner determined
  └─> GameManager.game_ended.emit(winner)
      └─> (Future: Show end screen with leaderboard)
```

---

## State Transitions

### Player States
```
ACTIVE (is_frozen = false)
  └─> Answer wrong → FROZEN
      └─> New round → ACTIVE
```

### Game States
```
NULL (no game)
  └─> start_game() → ACTIVE (is_active = true)
      └─> Winner found → ENDED (game_ended emitted)
          └─> (Future: reset or new game)
```

### Turn Flow
```
Player 1 turn
  └─> Clicks slider → Player 2 turn
      └─> Clicks slider → Player 3 turn
          └─> ... (cycles through all players)
              └─> Back to Player 1
```

---

## Timing Diagram

```
Time    Event
----    -----
T0      User launches game
T1      Splash screen shows (2-3 seconds)
T2      Home screen shows
T3      User clicks "New Game"
T4      Game setup UI shows
T5      User adds 2 players, selects settings
T6      User clicks "Confirm"
T7      GameManager.start_game() called
T8      Game board loads
T9      First question displays
T10     Player 1 clicks slider → Player 2's turn
T11     Player 2 clicks slider → Player 1's turn
T12     Player 1 clicks "Guess" → Modal shows
T13     Player 1 enters correct answer
T14     Points awarded, badges update
T15     1-second delay (round summary placeholder)
T16     New question loads
T17     ... (repeat T10-T16 until winner)
T18     Winner reaches target score
T19     Game end signal emitted
T20     (Future: End screen shows)
```

---

## Critical Checkpoints

### Before Game Starts
- [ ] PlayerManager.players has at least 1 player
- [ ] GameManager.available_questions is not empty
- [ ] Game.game_target is set

### Before Round Starts
- [ ] GameManager.get_next_question() returns valid Question
- [ ] PlayerManager.get_current_player() returns valid Player
- [ ] All players unfrozen (PlayerManager.unfreeze_all_players())

### After Answer Submitted
- [ ] Score updated in PlayerManager
- [ ] Badges reflect new scores
- [ ] Winner check performed
- [ ] Next question loaded OR game ended

---

## Error Handling

### No Players
If `PlayerManager.get_current_player()` returns null:
- QnA will print error and not display question
- Should never happen if game_init properly adds players

### No Questions
If `GameManager.get_next_question()` returns null:
- Game board prints "No more questions available!"
- Round does not start
- Should add question recycling logic or end game

### All Players Frozen
If `PlayerManager.next_turn()` finds all frozen:
- Prints warning
- Turn does not advance
- Should not happen in QnA mode (no freeze logic currently)

---

## Future Enhancements

### Round Summary Screen
Between rounds, show:
- Who answered
- Correct answer
- Points awarded/lost
- Updated leaderboard
- "Next Round" button

### End Screen
Show:
- Winner announcement
- Final leaderboard
- Game statistics
- "Play Again" / "Exit" buttons

### Question Recycling
When all questions used:
- Clear used_question_ids
- Reshuffle questions
- Continue game
