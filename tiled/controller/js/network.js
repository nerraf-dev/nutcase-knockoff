/**
 * WebSocket and networking layer for the controller UI.
 *
 * This module owns connection lifecycle, outbound messages, inbound message handling,
 * and reconnect behavior.
 */

import {
			el
		} from "./dom.js";
		
import {
			state,
			ControllerState,
			resetVoteState,
			updateControllerState
		} from "./state.js";

import {
			render,
			applySliderReveal,
			resetSliderButtons
		} from "./ui.js";

import {
			joinLobby,
			log
		} from "./actions.js";

/**
 * Opens a WebSocket connection to the host in the UI.
 *
 * When the connection opens, the controller restores prior lobby/ready state if needed.
 * Connection events also drive UI state resets and auto-reconnect scheduling.
 *
 * @returns {void}
 */
export function connect() {
	const url = el.hostInput.value.trim();
	if (!url) {
		log("Host URL is empty");
		return;
	}

	state.shouldAutoReconnect = false;
	_clearReconnectTimer();
	disconnect(true, false);

	try {
		state.ws = new WebSocket(url);
	} catch (err) {
		log(`Connect failed: ${err.message}`);
		return;
	}

	state.ws.addEventListener("open", () => {
		state.connected = true;
		state.shouldAutoReconnect = true;
		state.reconnectAttempt = 0;
		if (state.wasJoinedBeforeDisconnect) {
			joinLobby();
			if (state.wasReadyBeforeDisconnect) {
				send("ready", { ready: true, client_id: state.clientId });
				state.ready = true;
			}
		}
		updateControllerState();
		render();
		log(`Connected to ${url}`);
	});

	state.ws.addEventListener("close", () => {
		state.wasJoinedBeforeDisconnect = state.joined;
		state.wasReadyBeforeDisconnect = state.ready;
		state.connected = false;
		state.joined = false;
		state.inGame = false;
		state.ready = false;
		state.playerId = "";
		state.isYourTurn = false;
		state.turnStateKnown = false;
		state.overlayActive = false;
		state.guessMode = false;
		state.forcedGuess = false;
		resetVoteState();
		resetSliderButtons();
		updateControllerState();
		render();
		log("Disconnected");
		if (state.shouldAutoReconnect) {
			scheduleReconnect();
		}
	});

	state.ws.addEventListener("error", () => {
		log("WebSocket error");
	});

	state.ws.addEventListener("message", (event) => {
		handleServerMessage(event.data);
	});
}

/**
 * Closes the active WebSocket connection and resets local controller state.
 *
 * @param {boolean} [manual=true] - True when the disconnect was initiated by the user.
 * @param {boolean} [clearReconnectIntent=true] - True to cancel any pending auto-reconnect behavior.
 * @returns {void}
 */
export function disconnect(manual = true, clearReconnectIntent = true) {
	if (manual && clearReconnectIntent) {
		state.shouldAutoReconnect = false;
	}
	_clearReconnectTimer();
	if (state.ws) {
		state.ws.close();
		state.ws = null;
	}
	state.connected = false;
	state.joined = false;
	state.inGame = false;
	state.ready = false;
	state.playerId = "";
	state.isYourTurn = false;
	state.turnStateKnown = false;
	state.overlayActive = false;
	state.guessMode = false;
	state.forcedGuess = false;
	resetVoteState();
	resetSliderButtons();
	updateControllerState();
	render();
}

/**
 * Sends a JSON message over the active WebSocket connection.
 *
 * @param {string} type - Message type to send.
 * @param {object} [payload={}] - Additional message payload fields.
 * @returns {void}
 */
export function send(type, payload = {}) {
	if (!state.ws || state.ws.readyState !== WebSocket.OPEN) {
		log(`Cannot send ${type}: not connected`);
		return;
	}

	const message = { type, ...payload };
	state.ws.send(JSON.stringify(message));
	log(`send ${JSON.stringify(message)}`);
}

/**
 * Handles an incoming message from the server.
 *
 * The payload is decoded, parsed as JSON when possible, and applied to controller state.
 * Non-JSON messages are ignored after being logged.
 *
 * @param {string|Blob|ArrayBuffer} rawData - Raw WebSocket message payload.
 * @returns {Promise<void>}
 */
export async function handleServerMessage(rawData) {
	const text = await decodeWsData(rawData);
	log(`recv ${text}`);

	try {
		const msg = JSON.parse(text);
		if (msg.type === "room_joined") {
			state.joined = true;
			state.playerId = String(msg.player_id || "");
			updateControllerState();
			render();
			log("Joined lobby");
		}
		if (msg.type === "game_started") {
			state.inGame = true;
			state.overlayActive = false;
			state.guessMode = false;
			state.forcedGuess = false;
			updateControllerState();
			render();
			log("Game started");
		}
		if (msg.type === "new_round") {
			resetSliderButtons();
			state.overlayActive = false;
			state.turnStateKnown = false;
			state.guessMode = false;
			state.forcedGuess = false;
			resetVoteState();
			log(`New round ${msg.round_num ?? "?"}`);
			updateControllerState();
			render();
		}
		if (msg.type === "your_turn") {
			state.turnStateKnown = true;
			state.isYourTurn = true;
			updateControllerState();
			render();
			log("It is your turn");
		}
		if (msg.type === "turn_changed") {
			state.turnStateKnown = true;
			state.isYourTurn = String(msg.player_id || "") === state.playerId;
			if (!state.isYourTurn) {
				state.guessMode = false;
				state.forcedGuess = false;
			}
			updateControllerState();
			render();
		}
		if (msg.type === "force_guess") {
			state.turnStateKnown = true;
			state.isYourTurn = true;
			state.forcedGuess = true;
			state.guessMode = true;
			updateControllerState();
			render();
			el.guessInput.focus();
			log("Forced guess: submit an answer now");
		}
		if (msg.type === "overlay_prompt") {
			state.overlayActive = Boolean(msg.active);
			if (state.overlayActive) {
				state.guessMode = false;
			}
			updateControllerState();
			render();
		}
		if (msg.type === "vote_request") {
			state.voteActive = true;
			state.voteSubmitted = false;
			state.voteResultText = "";
			const guesserId = String(msg.guesser_id || "");
			const answerText = String(msg.answer || "");
			state.voteCanCast = guesserId !== "" && guesserId !== state.playerId;
			if (state.voteCanCast) {
				state.votePrompt = `Vote now: \"${answerText}\"`;
			} else {
				state.votePrompt = "You submitted this answer. Waiting for votes...";
			}
			updateControllerState();
			render();
			log("Vote request received");
		}
		if (msg.type === "vote_result") {
			const accepted = Boolean(msg.accepted);
			const correctAnswer = String(msg.correct_answer || "");
			state.voteActive = false;
			state.voteSubmitted = false;
			state.voteCanCast = false;
			state.votePrompt = "No vote in progress.";
			state.voteResultText = accepted
				? `Vote accepted. Correct answer: \"${correctAnswer}\"`
				: `Vote rejected. Correct answer: \"${correctAnswer}\"`;
			updateControllerState();
			render();
			log(`Vote ${accepted ? "accepted" : "rejected"}`);
		}
		if (msg.type === "game_over") {
			state.inGame = false;
			state.turnStateKnown = false;
			state.isYourTurn = false;
			state.guessMode = false;
			state.forcedGuess = false;
			state.controllerState = ControllerState.GAME_OVER;
			render();
			log("Game over");
		}
		if (msg.type === "slider_revealed") {
			applySliderReveal(msg.index, msg.word);
		}
		if (msg.type === "error") {
			log(`server error: ${msg.message}`);
		}
	} catch (_err) {
		// Non-JSON message; already logged.
	}
}

/**
 * Converts a WebSocket payload into text.
 *
 * @param {string|Blob|ArrayBuffer} rawData - Raw payload from the socket.
 * @returns {Promise<string>}
 */
export async function decodeWsData(rawData) {
	if (typeof rawData === "string") {
		return rawData;
	}
	if (rawData instanceof Blob) {
		return await rawData.text();
	}
	if (rawData instanceof ArrayBuffer) {
		return new TextDecoder().decode(new Uint8Array(rawData));
	}
	return String(rawData);
}

/**
 * Schedules the next reconnect attempt using a simple backoff.
 *
 * The wait time increases with each retry up to a fixed cap.
 *
 * @returns {void}
 */
export function scheduleReconnect() {
	if (state.reconnectTimer != null) {
		return;
	}
	state.reconnectAttempt += 1;
	const waitMs = Math.min(10000, 1000 * state.reconnectAttempt);
	log(`Reconnecting in ${Math.round(waitMs / 1000)}s...`);
	state.reconnectTimer = setTimeout(() => {
		state.reconnectTimer = null;
		if (!state.shouldAutoReconnect || state.connected) {
			return;
		}
		connect();
	}, waitMs);
}

/**
 * Clears any pending reconnect timer.
 *
 * @returns {void}
 */
export function _clearReconnectTimer() {
	if (state.reconnectTimer != null) {
		clearTimeout(state.reconnectTimer);
		state.reconnectTimer = null;
	}
}