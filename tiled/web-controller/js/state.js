
export const ControllerState = {
	DISCONNECTED: "disconnected",
	CONNECTED_UNJOINED: "connected_unjoined",
	PROFILE_EDIT: "profile_edit",
	LOBBY_READY: "lobby_ready",
	WAITING_TURN: "waiting_turn",
	ACTIVE_TURN: "active_turn",
	VOTING: "voting",
	ROUND_RESULT: "round_result",
	GAME_OVER: "game_over",
};

export const state = {
	ws: null,
	connected: false,
	joined: false,
	inGame: false,
	ready: false,
	deviceId: "",
	playerId: "",
	isYourTurn: false,
	turnStateKnown: false,
	overlayActive: false,
	voteActive: false,
	voteSubmitted: false,
	voteCanCast: false,
	votePrompt: "No vote in progress.",
	voteResultText: "",
	clientId: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
	controllerState: ControllerState.DISCONNECTED,
	debugMode: false,
	guessMode: false,
	forcedGuess: false,
	shouldAutoReconnect: false,
	reconnectTimer: null,
	reconnectAttempt: 0,
	wasJoinedBeforeDisconnect: false,
	wasReadyBeforeDisconnect: false,
};

/**
 * Updates `state.controllerState` based on the current connection, lobby, and in-game flags.
 *
 * Evaluation is performed in priority order with early returns:
 * 1. If currently `GAME_OVER` and no longer connected, transitions to `DISCONNECTED`.
 * 2. If not connected, sets `DISCONNECTED`.
 * 3. If connected but not joined, sets `CONNECTED_UNJOINED`.
 * 4. If joined but not in-game, sets:
 *    - `LOBBY_READY` when `state.ready` is `true`
 *    - otherwise `PROFILE_EDIT`
 * 5. If in-game and voting is active, sets `VOTING`.
 * 6. If in-game and an overlay is active, sets `ROUND_RESULT`.
 * 7. If turn state is known and it is the player's turn, sets `ACTIVE_TURN`.
 * 8. Otherwise, defaults to `WAITING_TURN`.
 *
 * @returns {void} This function mutates `state.controllerState` in place.
 */
export function updateControllerState() {
	if (state.controllerState === ControllerState.GAME_OVER && !state.connected) {
		state.controllerState = ControllerState.DISCONNECTED;
	}

	if (!state.connected) {
		state.controllerState = ControllerState.DISCONNECTED;
		return;
	}
	if (!state.joined) {
		state.controllerState = ControllerState.CONNECTED_UNJOINED;
		return;
	}
	if (!state.inGame) {
		state.controllerState = state.ready ? ControllerState.LOBBY_READY : ControllerState.PROFILE_EDIT;
		return;
	}
	if (state.voteActive) {
		state.controllerState = ControllerState.VOTING;
		return;
	}
	if (state.overlayActive) {
		state.controllerState = ControllerState.ROUND_RESULT;
		return;
	}
	if (state.turnStateKnown && state.isYourTurn) {
		state.controllerState = ControllerState.ACTIVE_TURN;
		return;
	}
	state.controllerState = ControllerState.WAITING_TURN;
}

/**
 * Returns a short UI hint for the current controller state.
 *
 * @param {ControllerState} controllerState - The current state of the controller.
 * @returns {string} A user-facing hint describing what to do next, or an empty string for unknown states.
 */
export function stateHint(controllerState) {
	switch (controllerState) {
		case ControllerState.DISCONNECTED:
			return "Connect to the host to begin.";
		case ControllerState.CONNECTED_UNJOINED:
			return "Set your name/avatar and join the lobby.";
		case ControllerState.PROFILE_EDIT:
			return "You are in lobby. Update profile and mark ready.";
		case ControllerState.LOBBY_READY:
			return "Ready. Waiting for host to start the game.";
		case ControllerState.ACTIVE_TURN:
			return "Your turn. Reveal a tile or submit a guess.";
		case ControllerState.WAITING_TURN:
			return "Wait for your turn.";
		case ControllerState.VOTING:
			return "Vote on the fuzzy answer.";
		case ControllerState.ROUND_RESULT:
			return "Round transition. Continue when prompted.";
		case ControllerState.GAME_OVER:
			return "Game over. Wait for next game.";
		default:
			return "";
	}
}

/**
 * Resets all vote-related state fields to their default inactive values.
 *
 * Sets voting flags to `false`, restores the default prompt message,
 * and clears any existing vote result text.
 *
 * @returns {void}
 */
export function resetVoteState() {
	state.voteActive = false;
	state.voteSubmitted = false;
	state.voteCanCast = false;
	state.votePrompt = "No vote in progress.";
	state.voteResultText = "";
}