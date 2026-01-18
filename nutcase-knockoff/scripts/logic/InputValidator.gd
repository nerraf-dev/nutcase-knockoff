class_name InputValidator

static func validate_player_count(count: int) -> Dictionary:
    # Returns {"valid": bool, "error": String}
    # Check against GameConfig.MIN_PLAYERS / MAX_PLAYERS
    if count < GameConfig.MIN_PLAYERS:
        return {"valid": false, "error": "Not enough players. Minimum is %d." % GameConfig.MIN_PLAYERS}
    elif count > GameConfig.MAX_PLAYERS:
        return {"valid": false, "error": "Too many players. Maximum is %d." % GameConfig.MAX_PLAYERS}
    return {"valid": true, "error": ""}

static func validate_player_name(name: String) -> Dictionary:
    # Check length, empty, special chars
    var trimmed_name := name.strip_edges()
    if trimmed_name == "":
        return {"valid": false, "error": "Player name cannot be empty."}
    elif trimmed_name.length() > 20:
        return {"valid": false, "error": "Player name too long. Max 20 characters."}
    var regex := RegEx.new()
    # Allow letters, digits, spaces, underscore, hyphen, dot, and apostrophe.
    regex.compile("^[A-Za-z0-9 _\\-\\.']+$")
    if not regex.search(trimmed_name):
        return {"valid": false, "error": "Player name contains invalid characters."}
    return {"valid": true, "error": ""}

static func validate_answer(answer: String) -> Dictionary:
    # Check not empty after trim
    if answer.strip_edges() == "":
        return {"valid": false, "error": "Answer cannot be empty."}
    return {"valid": true, "error": ""}

static func validate_game_settings(settings: Dictionary) -> Dictionary:
    # Check all required fields present
    # Returns {"valid": bool, "errors": Array[String]}
    var errors: Array[String] = []
    if not settings.has("players") or settings["players"].size() < GameConfig.MIN_PLAYERS:
        errors.append("Not enough players to start the game.")
    if not settings.has("game_type") or settings["game_type"] == "":
        errors.append("Game type must be selected.")
    if not settings.has("game_target") or settings["game_target"] <= 0:
        errors.append("Game target must be a positive number.")
    if errors.size() > 0:
        return {"valid": false, "errors": errors}
    return {"valid": true, "errors": []}

