
import { bindEvents } from "./events.js";
import {
	render,
} from "./ui.js";
import {
	log,
	hydrate,
	joinLobby,
	sendReady,
} from "./actions.js";
import {
	connect,
} from "./network.js";
import {
	state,
} from "./state.js";


function isEnabledFlag(value) {
	return value === "1" || value === "true";
}


function bootstrapFromQuery() {
	const params = new URLSearchParams(window.location.search);
	const autoConnect = isEnabledFlag((params.get("autoconnect") || "").toLowerCase());
	const autoJoin = isEnabledFlag((params.get("autojoin") || "").toLowerCase());
	const autoReady = isEnabledFlag((params.get("autoready") || "").toLowerCase());

	if (!autoConnect && !autoJoin && !autoReady) {
		return;
	}

	if (autoConnect) {
		connect();
	}

	const maxAttempts = 40;
	let attempt = 0;
	const timer = window.setInterval(() => {
		attempt += 1;

		if ((autoJoin || autoReady) && state.connected && !state.joined) {
			joinLobby();
		}
		if (autoReady && state.joined && !state.ready) {
			sendReady();
		}

		const joinDone = !autoJoin || state.joined;
		const readyDone = !autoReady || state.ready;
		if ((joinDone && readyDone) || attempt >= maxAttempts) {
			window.clearInterval(timer);
		}
	}, 250);
}


function init() {
	hydrate();
	bindEvents();
	render();
	bootstrapFromQuery();
	log("Controller loaded");
}


init();
