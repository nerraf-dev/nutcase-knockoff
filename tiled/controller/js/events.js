import { el } from "./dom.js";
import {
	connect,
	disconnect
} from "./network.js";
import {
	joinLobby,
	sendReady,
	sendOverlayContinue,
	sendSliderClick,
	beginGuessFlow,
	submitGuess,
	cancelGuessFlow,
	sendVote,
	selectAvatar,
	toggleDebugMode,
	persist
} from "./actions.js";


/**
 * Registers all UI event listeners for the controller layer.
 *
 * Wires button clicks, keyboard submit behavior, and form field persistence
 * handlers to their corresponding action functions. This function should be
 * called once during initialization to activate user interaction.
 *
 * @function bindEvents
 * @returns {void}
 *
 * @listens HTMLElement#click
 * @listens HTMLElement#keydown
 * @listens HTMLElement#change
 * @listens HTMLElement#blur
 *
 * @sideeffects
 * Attaches multiple DOM event listeners to elements referenced by `el`,
 * enabling connection flow, lobby actions, guessing flow, voting, slider
 * interactions, and settings persistence.
 */
export function bindEvents() {
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
	el.avatarButtons.forEach((button) => {
		button.addEventListener("click", () => {
			const idx = Number(button.dataset.avatarIndex || 0);
			selectAvatar(idx);
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