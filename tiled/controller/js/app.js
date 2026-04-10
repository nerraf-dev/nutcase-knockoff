import { updateControllerState, 
			stateHint,
			resetVoteState,
			state,
			ControllerState
		}	from "./state.js";

const STORAGE_KEY = "nutcase-controller";



const el = {
	hostInput: document.getElementById("hostInput"),
	nameInput: document.getElementById("nameInput"),
	avatarInput: document.getElementById("avatarInput"),
	sliderButtons: Array.from(document.querySelectorAll(".slider-tile")),
	guessInput: document.getElementById("guessInput"),
	guessModal: document.getElementById("guessModal"),
	forcedGuessBanner: document.getElementById("forcedGuessBanner"),
	startGuessBtn: document.getElementById("startGuessBtn"),
	guessSubmitBtn: document.getElementById("guessSubmitBtn"),
	guessCancelBtn: document.getElementById("guessCancelBtn"),
	votePanel: document.getElementById("votePanel"),
	statePanel: document.getElementById("statePanel"),
	connectPanel: document.getElementById("connectPanel"),
	profilePanel: document.getElementById("profilePanel"),
	gameplayPanel: document.getElementById("gameplayPanel"),
	logPanel: document.getElementById("logPanel"),
	controllerStateText: document.getElementById("controllerStateText"),
	controllerHintText: document.getElementById("controllerHintText"),
	debugToggleBtn: document.getElementById("debugToggleBtn"),
	connectBtn: document.getElementById("connectBtn"),
	disconnectBtn: document.getElementById("disconnectBtn"),
	joinBtn: document.getElementById("joinBtn"),
	readyBtn: document.getElementById("readyBtn"),
	continueBtn: document.getElementById("continueBtn"),
	voteAcceptBtn: document.getElementById("voteAcceptBtn"),
	voteRejectBtn: document.getElementById("voteRejectBtn"),
	votePrompt: document.getElementById("votePrompt"),
	voteResultText: document.getElementById("voteResultText"),
	statusText: document.getElementById("statusText"),
	turnText: document.getElementById("turnText"),
	logBox: document.getElementById("logBox"),
};

function init() {
	hydrate();
	bindEvents();
	render();
	log("Controller loaded");
}

function hydrate() {
	const defaultHost = `ws://${window.location.hostname || "127.0.0.1"}:9080`;
	const urlDebug = new URLSearchParams(window.location.search).get("debug");
	const savedRaw = localStorage.getItem(STORAGE_KEY);
	if (!savedRaw) {
		el.hostInput.value = defaultHost;
		state.debugMode = urlDebug === "1";
		return;
	}

	try {
		const saved = JSON.parse(savedRaw);
		el.hostInput.value = saved.host || defaultHost;
		el.nameInput.value = saved.name || "";
		el.avatarInput.value = String(saved.avatarIndex ?? 0);
		state.clientId = saved.clientId || state.clientId;
		state.debugMode = urlDebug === "1" ? true : Boolean(saved.debugMode);
	} catch (_err) {
		el.hostInput.value = defaultHost;
		state.debugMode = urlDebug === "1";
	}
}

function persist() {
	const payload = {
		host: el.hostInput.value.trim(),
		name: el.nameInput.value.trim(),
		avatarIndex: Number(el.avatarInput.value || 0),
		clientId: state.clientId,
		debugMode: state.debugMode,
	};
	localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
}

function bindEvents() {
	el.connectBtn.addEventListener("click", connect);
	el.disconnectBtn.addEventListener("click", () => disconnect(true));
	el.debugToggleBtn.addEventListener("click", toggleDebugMode);
	el.joinBtn.addEventListener("click", joinLobby);
	el.readyBtn.addEventListener("click", sendReady);
	el.continueBtn.addEventListener("click", sendOverlayContinue);
	el.startGuessBtn.addEventListener("click", beginGuessFlow);
	el.guessSubmitBtn.addEventListener("click", submitGuess);
	el.guessCancelBtn.addEventListener("click", cancelGuessFlow);
	el.voteAcceptBtn.addEventListener("click", () => sendVote(true));
	el.voteRejectBtn.addEventListener("click", () => sendVote(false));
	el.sliderButtons.forEach((button) => {
		button.addEventListener("click", () => {
			const idx = Number(button.dataset.index || -1);
			sendSliderClick(idx);
		});
	});
	el.guessInput.addEventListener("keydown", (event) => {
		if (event.key === "Enter") {
			submitGuess();
		}
	});

	[el.hostInput, el.nameInput, el.avatarInput].forEach((input) => {
		input.addEventListener("change", persist);
		input.addEventListener("blur", persist);
	});
}

function connect() {
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

async function handleServerMessage(rawData) {
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

async function decodeWsData(rawData) {
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

function disconnect(manual = true, clearReconnectIntent = true) {
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

function send(type, payload = {}) {
	if (!state.ws || state.ws.readyState !== WebSocket.OPEN) {
		log(`Cannot send ${type}: not connected`);
		return;
	}

	const message = { type, ...payload };
	state.ws.send(JSON.stringify(message));
	log(`send ${JSON.stringify(message)}`);
}

function joinLobby() {
	const name = el.nameInput.value.trim();
	const avatarIndex = Number(el.avatarInput.value || 0);
	if (!name) {
		log("Name is required");
		return;
	}

	persist();
	send("join", {
		name,
		avatar_index: avatarIndex,
		client_id: state.clientId,
	});
}

function sendReady() {
	state.ready = !state.ready;
	updateControllerState();
	render();
	send("ready", { ready: state.ready, client_id: state.clientId });
}

function sendOverlayContinue() {
	if (!state.overlayActive) {
		return;
	}
	send("overlay_continue", { client_id: state.clientId });
}

function sendSliderClick(index) {
	if (index < 0 || index > 8) {
		log(`Invalid slider index ${index}`);
		return;
	}
	if (state.forcedGuess) {
		log("You must submit a guess now");
		return;
	}

	const button = el.sliderButtons.find((b) => Number(b.dataset.index) === index);
	if (button && button.classList.contains("revealed")) {
		return;
	}
	send("slider_click", { index });
}

function beginGuessFlow() {
	const controlsEnabled = state.connected && state.joined && state.turnStateKnown && state.isYourTurn && !state.overlayActive;
	if (!controlsEnabled) {
		return;
	}
	state.guessMode = true;
	send("guess_start", { client_id: state.clientId });
	render();
	el.guessInput.focus();
}

function submitGuess() {
	if (!state.guessMode) {
		return;
	}
	const answer = el.guessInput.value.trim();
	if (!answer) {
		log("Guess is empty");
		return;
	}
	send("guess", { answer });
	el.guessInput.value = "";
	state.guessMode = false;
	render();
}

function cancelGuessFlow() {
	if (state.forcedGuess) {
		return;
	}
	state.guessMode = false;
	el.guessInput.value = "";
	render();
}

function sendVote(accepted) {
	if (!state.voteActive) {
		log("No active vote");
		return;
	}
	if (!state.voteCanCast) {
		log("You are not eligible to vote this round");
		return;
	}
	if (state.voteSubmitted) {
		return;
	}

	state.voteSubmitted = true;
	state.voteResultText = `Vote submitted: ${accepted ? "Accept" : "Reject"}`;
	updateControllerState();
	render();
	send("vote", { accepted });
}

function render() {
	updateControllerState();
	const status = state.connected ? "Connected" : "Disconnected";
	el.statusText.textContent = `Status: ${status}`;
	el.statusText.classList.toggle("ok", state.connected);
	el.debugToggleBtn.textContent = `Debug: ${state.debugMode ? "On" : "Off"}`;

	el.controllerStateText.textContent = `State: ${state.controllerState.replaceAll("_", " ")}`;
	el.controllerHintText.textContent = stateHint(state.controllerState);

	let turn = "Waiting for game";
	if (!state.connected || !state.joined) {
		turn = "Waiting for game";
	} else if (!state.turnStateKnown) {
		turn = "Waiting for turn sync";
	} else {
		turn = state.isYourTurn ? "Your turn" : "Waiting";
	}
	el.turnText.textContent = `Turn: ${turn}`;
	el.turnText.classList.toggle("ok", state.isYourTurn);

	el.connectBtn.disabled = state.connected;
	el.disconnectBtn.disabled = !state.connected;
	el.joinBtn.disabled = !state.connected;
	el.readyBtn.disabled = !state.connected || state.inGame;

	const controlsEnabled = state.connected && state.joined && state.turnStateKnown && state.isYourTurn && !state.overlayActive;
	const canRevealSliders = controlsEnabled && !state.forcedGuess;
	el.forcedGuessBanner.classList.toggle("hidden", !state.forcedGuess);
	if (state.forcedGuess) {
		el.forcedGuessBanner.textContent = "Forced guess mode: submit your answer now. Tile reveals are locked.";
	}
	el.sliderButtons.forEach((button) => {
		const isRevealed = button.classList.contains("revealed");
		button.disabled = !canRevealSliders || isRevealed;
	});
	el.startGuessBtn.disabled = !controlsEnabled || state.guessMode;
	el.guessSubmitBtn.disabled = !state.guessMode;
	el.guessCancelBtn.disabled = !state.guessMode;
	el.guessInput.disabled = !state.guessMode;
	const canContinueOverlay = state.connected && state.joined && state.overlayActive && state.turnStateKnown && state.isYourTurn;
	el.continueBtn.disabled = !canContinueOverlay;

	el.votePrompt.textContent = state.votePrompt;
	el.voteResultText.textContent = state.voteResultText;
	const canVote = state.connected && state.joined && state.voteActive && state.voteCanCast && !state.voteSubmitted;
	el.voteAcceptBtn.disabled = !canVote;
	el.voteRejectBtn.disabled = !canVote;

	el.joinBtn.textContent = state.joined ? "Update Profile" : "Join / Reconnect";
	el.readyBtn.textContent = state.ready ? "Unready" : "Ready";

	const showConnectPanel = !state.connected || state.debugMode;
	el.connectPanel.classList.toggle("hidden", !showConnectPanel);
	el.votePanel.classList.toggle("hidden", !state.voteActive);
	el.guessModal.classList.toggle("hidden", !state.guessMode);

	const showProfilePanel = !state.inGame || state.debugMode;
	const showGameplayPanel = state.inGame || state.debugMode;
	el.profilePanel.classList.toggle("hidden", !showProfilePanel);
	el.gameplayPanel.classList.toggle("hidden", !showGameplayPanel);
	el.logPanel.classList.toggle("hidden", !state.debugMode);
}

function resetSliderButtons() {
	el.sliderButtons.forEach((button, i) => {
		button.classList.remove("revealed");
		button.textContent = String(i + 1);
	});
}

function applySliderReveal(index, word) {
	const button = el.sliderButtons.find((b) => Number(b.dataset.index) === Number(index));
	if (!button) {
		return;
	}

	button.classList.add("revealed");
	button.textContent = (word || "").trim() === "" ? "-" : word;
	render();
}



function toggleDebugMode() {
	state.debugMode = !state.debugMode;
	persist();
	render();
}

function scheduleReconnect() {
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

function _clearReconnectTimer() {
	if (state.reconnectTimer != null) {
		clearTimeout(state.reconnectTimer);
		state.reconnectTimer = null;
	}
}





function log(message) {
	const stamp = new Date().toLocaleTimeString();
	el.logBox.textContent = `[${stamp}] ${message}\n${el.logBox.textContent}`;
}

init();
