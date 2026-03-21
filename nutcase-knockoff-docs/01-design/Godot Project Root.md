**Godot Project Root**, create these folders:

- 📁 **`assets/`** (Raw files from outside Godot)
    - 📁 `fonts/`
    - 📁 `images/` (The "Nut" graphic, backgrounds)
    - 📁 `sounds/` (Buzzer, slider slide, correct/wrong)
- 📁 **`data/`**
    - 📄 `questions.json` (Your actual trivia content)
- 📁 **`scenes/`** (The "Physical" pieces of the game)
    - 📁 `components/` (Small reusable parts)
        - 📄 `Slider.tscn` (The single word reveal)
        - 📄 `PlayerCard.tscn` (UI for each player in the lobby)
    - 📁 `screens/` (The full-screen views)
        - 📄 `Lobby.tscn`
        - 📄 `MainGame.tscn`
        - 📄 `Results.tscn`
- 📁 **`scripts/`** (The logic)
    - 📁 `autoload/` (Scripts that run globally)
        - 📄 `GameManager.gd` (Tracks pot, rounds, state)
        - 📄 `NetworkManager.gd` (Handles server/client talk)
    - 📁 `resources/` (Templates for data)
        - 📄 `PlayerData.gd` (The Player object script)
- 📁 **`ui/`** (General UI theme/styles)
    - 📄 `main_theme.tres`

