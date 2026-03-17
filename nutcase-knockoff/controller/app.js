const STORAGE_KEY = "nutcase-controller";

const state = {
	ws: null,
	connected: false,
	joined: false,
	inGame: false,
	ready: false,
	isYourTurn: false,
	turnStateKnown: false,
	clientId: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
};

const el = {
	hostInput: document.getElementById("hostInput"),
	nameInput: document.getElementById("nameInput"),
	avatarInput: document.getElementById("avatarInput"),
	sliderButtons: Array.from(document.querySelectorAll(".slider-tile")),
	guessInput: document.getElementById("guessInput"),
	connectBtn: document.getElementById("connectBtn"),
	disconnectBtn: document.getElementById("disconnectBtn"),
	joinBtn: document.getElementById("joinBtn"),
	readyBtn: document.getElementById("readyBtn"),
	guessBtn: document.getElementById("guessBtn"),
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
	const savedRaw = localStorage.getItem(STORAGE_KEY);
	if (!savedRaw) {
		el.hostInput.value = defaultHost;
		return;
	}

	try {
		const saved = JSON.parse(savedRaw);
		el.hostInput.value = saved.host || defaultHost;
		el.nameInput.value = saved.name || "";
		el.avatarInput.value = String(saved.avatarIndex ?? 0);
		state.clientId = saved.clientId || state.clientId;
	} catch (_err) {
		el.hostInput.value = defaultHost;
	}
}

function persist() {
	const payload = {
		host: el.hostInput.value.trim(),
		name: el.nameInput.value.trim(),
		avatarIndex: Number(el.avatarInput.value || 0),
		clientId: state.clientId,
	};
	localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
}

function bindEvents() {
	el.connectBtn.addEventListener("click", connect);
	el.disconnectBtn.addEventListener("click", disconnect);
	el.joinBtn.addEventListener("click", joinLobby);
	el.readyBtn.addEventListener("click", sendReady);
	el.sliderButtons.forEach((button) => {
		button.addEventListener("click", () => {
			const idx = Number(button.dataset.index || -1);
			sendSliderClick(idx);
		});
	});
	el.guessBtn.addEventListener("click", sendGuess);

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

	disconnect();

	try {
		state.ws = new WebSocket(url);
	} catch (err) {
		log(`Connect failed: ${err.message}`);
		return;
	}

	state.ws.addEventListener("open", () => {
		state.connected = true;
		render();
		log(`Connected to ${url}`);
	});

	state.ws.addEventListener("close", () => {
		state.connected = false;
		state.joined = false;
		state.inGame = false;
		state.ready = false;
		state.isYourTurn = false;
		state.turnStateKnown = false;
		resetSliderButtons();
		render();
		log("Disconnected");
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
			render();
			log("Joined lobby");
		}
		if (msg.type === "game_started") {
			state.inGame = true;
			render();
			log("Game started");
		}
		if (msg.type === "new_round") {
			resetSliderButtons();
			log(`New round ${msg.round_num ?? "?"}`);
		}
		if (msg.type === "your_turn") {
			state.turnStateKnown = true;
			state.isYourTurn = true;
			render();
			log("It is your turn");
		}
		if (msg.type === "turn_changed") {
			state.turnStateKnown = true;
			state.isYourTurn = false;
			render();
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

function disconnect() {
	if (state.ws) {
		state.ws.close();
		state.ws = null;
	}
	state.connected = false;
	state.joined = false;
	state.inGame = false;
	state.ready = false;
	state.isYourTurn = false;
	state.turnStateKnown = false;
	resetSliderButtons();
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
	render();
	send("ready", { ready: state.ready, client_id: state.clientId });
}

function sendSliderClick(index) {
	if (index < 0 || index > 8) {
		log(`Invalid slider index ${index}`);
		return;
	}

	const button = el.sliderButtons.find((b) => Number(b.dataset.index) === index);
	if (button && button.classList.contains("revealed")) {
		return;
	}
	send("slider_click", { index });
}

function sendGuess() {
	const answer = el.guessInput.value.trim();
	if (!answer) {
		log("Guess is empty");
		return;
	}
	send("guess", { answer });
}

function render() {
	const status = state.connected ? "Connected" : "Disconnected";
	el.statusText.textContent = `Status: ${status}`;
	el.statusText.classList.toggle("ok", state.connected);

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
	el.joinBtn.disabled = !state.connected || state.inGame;
	el.readyBtn.disabled = !state.connected || state.inGame;

	const controlsEnabled = state.connected && state.joined && state.turnStateKnown && state.isYourTurn;
	el.sliderButtons.forEach((button) => {
		const isRevealed = button.classList.contains("revealed");
		button.disabled = !controlsEnabled || isRevealed;
	});
	el.guessBtn.disabled = !controlsEnabled;

	el.joinBtn.textContent = state.joined ? "Update Profile" : "Join Lobby";
	el.readyBtn.textContent = state.ready ? "Unready" : "Ready";
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

function log(message) {
	const stamp = new Date().toLocaleTimeString();
	el.logBox.textContent = `[${stamp}] ${message}\n${el.logBox.textContent}`;
}

init();
