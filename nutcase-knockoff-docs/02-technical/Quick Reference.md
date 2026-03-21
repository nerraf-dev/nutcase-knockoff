# Quick Reference Guide

## Common Tasks

### Add a Player
```gdscript
var player = PlayerManager.add_player("Player Name")
```

### Start a Game
```gdscript
var settings = {
    "game_type": "qna",
    "game_target": 1000,
    "player_count": PlayerManager.players.size()
}
GameManager.start_game(settings)
```

### Get Next Question
```gdscript
var question = GameManager.get_next_question()
if question:
    qna_instance.start_new_question(question)
```

### Award Points
```gdscript
PlayerManager.award_points(player, 100)      # Add points
PlayerManager.award_points(player, -50)      # Subtract points
```

### Advance Turn
```gdscript
PlayerManager.next_turn()
var current = PlayerManager.get_current_player()
```

### Check for Winner
```gdscript
var winners = GameManager.check_for_winner()
if not winners.is_empty():
    print("Winner: %s" % winners[0].name)
```

### Update Player Badge
```gdscript
badge.update_score(player.score)
badge.set_current_player(is_current)
badge.set_current_leader(is_leader)
```

---

## Common Patterns

### Scene Signal Connection
```gdscript
# In parent scene
child_instance.connect("signal_name", Callable(self, "_on_signal_handler"))

# Handler
func _on_signal_handler(param1, param2):
    # Handle signal
```

### Null-Safe Player Access
```gdscript
var player = PlayerManager.get_current_player()
if player:
    player_label.text = player.name
else:
    push_error("No current player!")
```

### Question Validation
```gdscript
var is_correct = answer_text.strip_edges().to_lower() == question.answer.strip_edges().to_lower()
```

### Loop Through Players
```gdscript
for player in PlayerManager.players:
    print("%s: %d points" % [player.name, player.score])
```

---

## File Locations Quick Map

### Scripts
- **Autoloads**: `scripts/autoload/`
  - `GameManager.gd`
  - `PlayerManager.gd`
  
- **Classes**: `scripts/classes/`
  - `Game.gd`
  - `Player.gd`
  
- **Resources**: `scripts/resources/`
  - `Question.gd`
  
- **Logic**: `scripts/logic/`
  - `QuestionLoader.gd`

### Scenes
- **Screens**: `scenes/screens/`
  - `main.gd` / `main.tscn`
  - `game_board.gd` / `game_board.tscn`
  - `game_init.gd` / `game_init.tscn`
  - `game_home.gd` / `game_home.tscn`
  - `splash_screen.gd` / `splash_screen.tscn`
  
- **Components**: `scenes/components/`
  - `player_badge.gd` / `player_badge.tscn`
  - `answer_modal.gd` / `answer_modal.tscn`
  
- **Rounds**: `scenes/components/rounds/`
  - `qna.gd` / `QnA.tscn`

### Data
- **Questions**: `data/questions.json`

---

## Debugging Tips

### Print Player State
```gdscript
func debug_players():
    print("=== PLAYER STATE ===")
    for i in range(PlayerManager.players.size()):
        var p = PlayerManager.players[i]
        var current = " <CURRENT>" if i == PlayerManager.current_turn_index else ""
        print("%s: %d points, frozen=%s%s" % [p.name, p.score, p.is_frozen, current])
```

### Print Game State
```gdscript
func debug_game():
    print("=== GAME STATE ===")
    print("Type: %s" % GameManager.game.game_type)
    print("Target: %d" % GameManager.game.game_target)
    print("Round: %d" % GameManager.game.current_round)
    print("Active: %s" % GameManager.game.is_active)
    print("Questions available: %d" % GameManager.available_questions.size())
    print("Questions used: %d" % GameManager.used_question_ids.size())
```

### Verify Signal Connections
```gdscript
# Check if signal is connected
if not qna_instance.is_connected("round_result", Callable(self, "_on_round_result")):
    push_error("Signal not connected!")
```

---

## Common Errors & Fixes

### "Invalid access to property 'name' on base object of type 'Nil'"
**Cause**: `get_current_player()` returned null  
**Fix**: Add null check before accessing properties
```gdscript
var player = PlayerManager.get_current_player()
if player:
    label.text = player.name
```

### "No round scene found for game type: X"
**Cause**: game_type doesn't match ROUND_SCENES dictionary key  
**Fix**: Ensure game_type matches key exactly (e.g., "qna" not "Q'n'A")

### Players not advancing on slider click
**Cause**: Missing `PlayerManager.next_turn()` call  
**Fix**: Ensure `next_turn()` is called in `_on_slider_clicked()`

### Winner check not working
**Cause**: Player scores not updating, or target score too high  
**Fix**: 
- Verify `PlayerManager.award_points()` is called
- Check `game.game_target` value
- Use `GameManager.check_for_winner()` after scoring

### Same question repeating
**Cause**: `used_question_ids` not being populated  
**Fix**: Ensure `get_next_question()` adds to `used_question_ids`

---

## Performance Notes

- Player badges update on every score change (fine for small player count)
- Questions loaded once at game start (not per-round)
- Signals are efficient - don't worry about signal overhead
- Instantiating sliders per question is acceptable (< 15 sliders typical)

---

## Testing Shortcuts

### Quick 2-Player Test
```gdscript
# In game_init or test script
PlayerManager.add_player("Alice")
PlayerManager.add_player("Bob")
var settings = {"game_type": "qna", "game_target": 200, "player_count": 2}
GameManager.start_game(settings)
```

### Force Winner (for testing end screen)
```gdscript
var player = PlayerManager.players[0]
player.score = GameManager.game.game_target
```

### Skip to Specific Round
```gdscript
GameManager.game.current_round = 5
```
