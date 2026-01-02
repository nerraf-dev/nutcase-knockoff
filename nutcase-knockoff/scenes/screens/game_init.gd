extends Node2D

signal game_init_complete

func _ready() -> void:
    print("GameInit scene ready")
    # The screen lets the player pick the number of players and what type of game.
    #  For now, 
    #   - 3 players
    #   - Q n A type game
    #   - 10 rounds

    # Values will coem from selectors on the UI

    game_init_complete.emit()

func _initialize_players() -> void:
    PlayerManager.add_player("Alice")
    PlayerManager.add_player("Bob")
    PlayerManager.add_player("Charlie")
    print("Players initialized: ")
    for player in PlayerManager.players:
        print("- %s (ID: %s)" % [player.name, player.id])
