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
    if answer.strip_edges() == "":
        return {"result": ValidationResult.INVALID, "error": "Answer cannot be empty."}

    var normalised_submitted = _normalise(answer)
    var normalised_correct = _normalise(current_question.answer)

    # TODO: When Question gets an `alternatives` array, run this comparison against
    # each alternative too and take the minimum distance. That's how "Hastings" will
    # pass for "Battle of Hastings" — list it as an alternative in the data.
    var distance = levenshtein_distance(normalised_submitted, normalised_correct)

    # Thresholds scale with the normalised correct answer length.
    var answer_length = normalised_correct.length()
    var auto_accept_threshold = max(1, answer_length / 8)
    var fuzzy_threshold = max(2, answer_length / 6)

    if distance == 0:
        return {"result": ValidationResult.EXACT}
    elif distance <= auto_accept_threshold:
        return {"result": ValidationResult.AUTO_ACCEPT, "distance": distance}
    elif distance <= fuzzy_threshold:
        return {"result": ValidationResult.FUZZY, "distance": distance}
    else:
        return {"result": ValidationResult.INVALID, "distance": distance, "error": "Answer is incorrect."}

# Normalises a string before comparison:
#   - strips edges and lowercases
#   - removes leading articles (the, a, an)
#   - removes common geographical/title prefixes (mount, lake, saint, etc.)
# Applied to BOTH submitted and correct answer so the comparison is symmetric.
static func _normalise(s: String) -> String:
    var result = s.strip_edges().to_lower()

    # Strip leading articles
    for article in ["the ", "a ", "an "]:
        if result.begins_with(article):
            result = result.substr(article.length())
            break  # Only strip one article

    # Strip common geographical/title prefixes
    for prefix in ["mount ", "mt. ", "mt ", "lake ", "saint ", "st. ", "st ", "cape ", "fort "]:
        if result.begins_with(prefix):
            result = result.substr(prefix.length())
            break  # Only strip one prefix

    return result.strip_edges()

static func levenshtein_distance(s1: String, s2: String) -> int:
    var m = s1.length()
    var n = s2.length()
    var dp = []
    # Setup matrix, zeroed
    for i in range(m + 1):
        var row = []
        for j in range(n + 1):
            row.append(0)
        dp.append(row)

    # Initialize base cases
    for i in range(m + 1):
        dp[i][0] = i  # Deletion cost
    for j in range(n + 1):
        dp[0][j] = j  # Insertion cost

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

