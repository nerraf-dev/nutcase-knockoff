# Nutcase Knockoff - Architecture Overview

## Design Philosophy

**Single Responsibility Principle**: Each manager/class owns one aspect of the game.

## Core Components

### Autoload Managers (Singletons)

#### PlayerManager
- **Purpose**: Owns the player roster and all player operations
- **Scope**: Session-wide player state
- **Location**: `scripts/autoload/PlayerManager.gd`

#### GameManager  
- **Purpose**: Orchestrates game sessions and manages questions
- **Scope**: Game lifecycle and session coordination
- **Location**: `scripts/autoload/GameManager.gd`

### Data Classes

#### Player
- **Type**: Resource class
- **Purpose**: Individual player data
- **Location**: `scripts/classes/Player.gd`

#### Game
- **Type**: Resource class  
- **Purpose**: Session metadata and history (pure data, no logic)
- **Location**: `scripts/classes/Game.gd`

#### Question
- **Type**: Resource class
- **Purpose**: Question data structure
- **Location**: `scripts/resources/Question.gd`

### Scene Controllers

#### Main
- **Purpose**: Scene manager - handles scene transitions
- **Location**: `scenes/screens/main.gd`

#### GameBoard
- **Purpose**: UI orchestrator - coordinates HUD, player badges, and round area
- **Location**: `scenes/screens/game_board.gd`

#### QnA (Round Component)
- **Purpose**: Round UI and gameplay - handles question display, sliders, answer checking
- **Location**: `scenes/components/rounds/qna.gd`

## Data Flow

```
Main (Scene Manager)
  └─> GameInit (Setup UI)
      └─> PlayerManager.add_player()
      └─> emit game_init_complete(settings)
          └─> GameManager.start_game(settings)
              └─> Load questions
              └─> emit game_started
                  └─> GameBoard loads
                      └─> QnA instance created
                          └─> get_next_question() from GameManager
                          └─> Player answers
                              └─> emit round_result(player, is_correct, points)
                                  └─> GameBoard handles scoring
                                      └─> Check for winner
                                          └─> Next round OR Game end
```

## Separation of Concerns

| Component | Owns | Does NOT Own |
|-----------|------|--------------|
| **PlayerManager** | Player objects, turn order, scoring | Game session, questions |
| **GameManager** | Game session, questions, win detection | Player data |
| **Game** | Session metadata, history | Player data, logic |
| **GameBoard** | UI coordination, badge updates | Round logic, player data |
| **QnA** | Round UI, answer validation | Scoring, player management |

## Signal Architecture

### PlayerManager Signals
- `turn_changed(player: Player)` - Emitted when turn advances
- `player_added(player: Player)` - Emitted when player joins
- `player_removed(player: Player)` - Emitted when player leaves
- `player_scored(player: Player, points: int)` - Emitted on score change

### GameManager Signals
- `game_started` - Emitted when game session begins
- `game_ended(winner: Player)` - Emitted when winner is determined

### QnA Signals
- `round_result(player: Player, is_correct: bool, points: int)` - Emitted after answer submission

### Scene Signals
- `game_init_complete(settings: Dictionary)` - From GameInit to Main
- `splash_complete` - From SplashScreen to Main
- `new_game` - From GameHome to Main

## Key Design Decisions

1. **No Player Duplication**: PlayerManager is the single source of truth for player data. Game class only stores session metadata.

2. **Questions Managed Centrally**: GameManager loads and tracks used questions to prevent repeats.

3. **Signal-Based Communication**: Scenes communicate via signals, not direct calls, for loose coupling.

4. **GameBoard as Coordinator**: GameBoard doesn't contain game logic - it coordinates between QnA (UI) and Managers (logic).

5. **Pure Data Classes**: Game, Player, Question are data containers with minimal logic.
