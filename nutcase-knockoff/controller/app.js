const STORAGE_KEY = "nutcase-controller";

const state = {
	ws: null,
	connected: false,
	joined: false,
	ready: false,
	clientId: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
};

const el = {
	hostInput: document.getElementById("hostInput"),
	nameInput: document.getElementById("nameInput"),
	avatarInput: document.getElementById("avatarInput"),
	sliderInput: document.getElementById("sliderInput"),
	guessInput: document.getElementById("guessInput"),
	connectBtn: document.getElementById("connectBtn"),
	disconnectBtn: document.getElementById("disconnectBtn"),
	joinBtn: document.getElementById("joinBtn"),
	readyBtn: document.getElementById("readyBtn"),
	sliderBtn: document.getElementById("sliderBtn"),
	guessBtn: document.getElementById("guessBtn"),
	statusText: document.getElementById("statusText"),
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
	el.sliderBtn.addEventListener("click", sendSliderClick);
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
		state.ready = false;
		render();
		log("Disconnected");
	});

	state.ws.addEventListener("error", () => {
		log("WebSocket error");
	});

	state.ws.addEventListener("message", (event) => {
		log(`recv ${event.data}`);
		try {
			const msg = JSON.parse(event.data);
			if (msg.type === "room_joined") {
				state.joined = true;
				render();
				log("Joined lobby");
			}
			if (msg.type === "error") {
				log(`server error: ${msg.message}`);
			}
		} catch (_err) {
			// Keep raw log only.
		}
	});
}

function disconnect() {
	if (state.ws) {
		state.ws.close();
		state.ws = null;
	}
	state.connected = false;
	state.joined = false;
	state.ready = false;
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

	// Optimistic join state for current server behavior.
	state.joined = true;
	render();
}

function sendReady() {
	state.ready = !state.ready;
	render();
	send("ready", { ready: state.ready, client_id: state.clientId });
}

function sendSliderClick() {
	const index = Number(el.sliderInput.value || 0);
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

	el.connectBtn.disabled = state.connected;
	el.disconnectBtn.disabled = !state.connected;
	el.joinBtn.disabled = !state.connected;
	el.readyBtn.disabled = !state.connected;
	el.sliderBtn.disabled = !state.connected;
	el.guessBtn.disabled = !state.connected;

	el.joinBtn.textContent = state.joined ? "Update Profile" : "Join Lobby";
	el.readyBtn.textContent = state.ready ? "Unready" : "Ready";
}

function log(message) {
	const stamp = new Date().toLocaleTimeString();
	el.logBox.textContent = `[${stamp}] ${message}\n${el.logBox.textContent}`;
}

init();
