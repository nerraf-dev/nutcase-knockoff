class_name InputValidator

enum ValidationResult {
    EXACT,
    INVALID,
    AUTO_ACCEPT,
    FUZZY
}

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

static func validate_answer(answer: String, current_question: Question) -> Dictionary:
    # Check not empty after trim
    if answer.strip_edges() == "":
        return {"valid": false, "error": "Answer cannot be empty."}
    # return {"valid": true, "error": ""}
    # levenshtein_distance
    var distance = levenshtein_distance(answer.strip_edges().to_lower(), current_question.answer.strip_edges().to_lower())
    # Auto distance ≤ max(1, answer_length / 8) 
    # Fuzzy distance ≤ max(2, answer_length / 5) 
    var answer_length = answer.strip_edges().length()
    if distance == 0:
        return {"result": ValidationResult.EXACT}
    elif  distance <= max(1, answer_length / 8):
        return {"result": ValidationResult.AUTO_ACCEPT, "distance": distance}
    elif distance <= max(2, answer_length / 5):
        return {"result": ValidationResult.FUZZY, "distance": distance}
    else:
        return {"result": ValidationResult.INVALID, "distance": distance}

static func levenshtein_distance(s1: String, s2: String) -> int:
    var m = s1.length()
    var n = s2.length()
    # dp = [[0 for _ in range(n+1)] for _ in range(m+1)]
    var dp = []
    for i in range(m + 1):
        var row = []
        for j in range(n + 1):
            row.append(0)
        dp.append(row)

    var cost = 0
    for i in range(1, m + 1):
        for j in range(1, n + 1):
            if s1[i - 1] == s2[j - 1]:
                cost = 0
            else:
                cost = 1
            dp[i][j] = min(
                dp[i - 1][j] + 1,      # Deletion
                dp[i][j - 1] + 1,      # Insertion
                dp[i - 1][j - 1] + cost  # Substitution
            )

    # DEBUG: Print initial dp table
    var cell_value = ""
    for i in range(m + 1):
        for j in range(n + 1):
            cell_value += "%d " % dp[i][j]
        print(cell_value)
        cell_value = ""
    return dp[m][n]

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

