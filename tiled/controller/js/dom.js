/**
 * @fileoverview DOM element references for the controller interface.
 *
 * This module exports a single object, `el`, which contains references to
 * all relevant DOM elements used in the controller's UI. This centralizes
 * access to these elements and promotes cleaner code in other modules by
 * avoiding repeated calls to `document.getElementById` or similar methods.
 *
 * Each property of the `el` object corresponds to a specific UI element,
 * identified by its ID or class in the HTML structure. For example, `el.connectBtn` references the button used to initiate a connection to the game server, while `el.statusText` references the element that displays the current connection status.
 *
 * By importing this module, other parts of the application can easily manipulate
 * the UI by accessing these pre-referenced elements, improving readability and maintainability.
 *
 * @module dom
 */
export const el = {
	hostInput: document.getElementById("hostInput"),
	nameInput: document.getElementById("nameInput"),
	avatarGrid: document.getElementById("avatarGrid"),
	avatarButtons: Array.from(document.querySelectorAll(".avatar-option")),
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