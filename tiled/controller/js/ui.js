import { el } from "./dom.js";
import { state, stateHint, updateControllerState } from "./state.js";


/**
 * Renders the controller UI based on the latest application state.
 *
 * This function:
 * - Refreshes controller-related state via `updateControllerState()`.
 * - Updates status, turn, controller state, and hint text.
 * - Enables/disables action buttons and inputs according to connection,
 *   game phase, turn ownership, overlay visibility, guess mode, and vote state.
 * - Toggles visibility of panels/modals (connect, profile, gameplay, vote, guess, log).
 * - Updates forced-guess banner messaging and slider button availability.
 *
 * @function render
 * @returns {void}
 *
 * @sideeffects
 * Mutates DOM elements referenced by `el` (text content, `disabled` flags, CSS classes),
 * and reads shared runtime state from `state`.
 */
export function render() {
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

	const selectedAvatarIndex = Number(el.avatarInput.value || 0);
	el.avatarButtons.forEach((button) => {
		const idx = Number(button.dataset.avatarIndex || -1);
		const selected = idx === selectedAvatarIndex;
		button.classList.toggle("selected", selected);
		button.setAttribute("aria-pressed", selected ? "true" : "false");
	});

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

/**
 * Resets all slider buttons to their default visual and label state.
 *
 * Iterates through `el.sliderButtons`, removes the `"revealed"` CSS class
 * from each button, and sets its text content to a 1-based index
 * (e.g., `"1"`, `"2"`, `"3"`, ...).
 *
 * @returns {void}
 */
export function resetSliderButtons() {
	el.sliderButtons.forEach((button, i) => {
		button.classList.remove("revealed");
		button.textContent = String(i + 1);
	});
}

/**
 * Reveals a slider button for the given index and updates its displayed label.
 *
 * Finds the matching button in `el.sliderButtons` by comparing each element's
 * `data-index` with the provided `index`. If found, it adds the `"revealed"`
 * CSS class, sets the button text to `word` (or `"-"` when `word` is empty/blank),
 * and triggers a UI refresh via `render()`.
 *
 * @param {number|string} index - The target slider button index to reveal.
 * @param {string} [word] - The text to display on the revealed button. If omitted
 * or whitespace-only, a hyphen (`"-"`) is displayed instead.
 * @returns {void}
 */
export function applySliderReveal(index, word) {
	const button = el.sliderButtons.find((b) => Number(b.dataset.index) === Number(index));
	if (!button) {
		return;
	}

	button.classList.add("revealed");
	button.textContent = (word || "").trim() === "" ? "-" : word;
	render();
}