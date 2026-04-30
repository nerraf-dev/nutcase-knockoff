class_name InputValidator

enum ValidationResult {
    EXACT,
    INVALID,
    AUTO_ACCEPT,
    FUZZY,
    INCORRECT
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

static func validate_answer(answer: String, current_question: Question, fuzzy_enabled: bool = true) -> Dictionary:
    if answer.strip_edges() == "":
        return {"result": ValidationResult.INVALID, "error": "Answer cannot be empty."}

    var normalised_submitted = _normalise(answer)
    var normalised_correct = _normalise(current_question.answer)

    # Find minimum distance across main answer and any alternatives.
    # Track the matched string length so thresholds scale correctly.
    var best_distance = levenshtein_distance(normalised_submitted, normalised_correct)
    var best_match_length = normalised_correct.length()

    for alt in current_question.alt_answers:
        var normalised_alt = _normalise(alt)
        var d = levenshtein_distance(normalised_submitted, normalised_alt)
        if d < best_distance:
            best_distance = d
            best_match_length = normalised_alt.length()

    # Thresholds scale with the length of the best-matching string.
    var auto_accept_threshold = max(1, best_match_length / 8)
    var fuzzy_threshold = max(2, best_match_length / 6)

    print("DISTANCE: %d (auto_accept ≤ %d, fuzzy ≤ %d) for submitted '%s' vs correct '%s'"
        % [best_distance, auto_accept_threshold, fuzzy_threshold, normalised_submitted, normalised_correct])

    if best_distance == 0:
        return {"result": ValidationResult.EXACT}

    # Numeric answers must be exact — a digit off is a different answer, not a typo.
    if normalised_correct.is_valid_int():
        return {"result": ValidationResult.INCORRECT, "distance": best_distance, "error": "Answer is incorrect."}

    # Short answers and fuzzy-disabled games only accept exact matches (or alts, handled above).
    if not fuzzy_enabled or best_match_length <= GameConfig.FUZZY_MIN_LENGTH:
        return {"result": ValidationResult.INCORRECT, "distance": best_distance, "error": "Answer is incorrect."}

    if best_distance <= auto_accept_threshold:
        return {"result": ValidationResult.AUTO_ACCEPT, "distance": best_distance}
    elif best_distance <= fuzzy_threshold:
        return {"result": ValidationResult.FUZZY, "distance": best_distance}
    else:
        return {"result": ValidationResult.INCORRECT, "distance": best_distance, "error": "Answer is incorrect."}

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

