
- **Resolution:** $1920 \times 1080$
    
- **Slider Base Size:** Try $250 \times 80$ pixels (Good balance for 11 words on screen).
    
- **GridContainer Columns:** Set to `4` or `5` (to keep the words legible).

| **File**            | **Type** | **Purpose**                                                            |
| ------------------- | -------- | ---------------------------------------------------------------------- |
| **`Slider.tscn`**   | Scene    | The individual nut (PanelContainer > Label + ColorRect).               |
| **`Slider.gd`**     | Script   | Attached to Slider. Handles `set_word()` and the `reveal()` animation. |
| **`MainGame.tscn`** | Scene    | The "Stage." Contains a `GridContainer` and the `Pot` UI.              |
| **`main_game.gd`**  | Script   | Attached to MainGame. Handles `spawn_question()` and total score.      |