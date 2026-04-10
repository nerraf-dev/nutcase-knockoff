
import { bindEvents } from "./events.js";
import {
	render,
} from "./ui.js";
import {
	log,
	hydrate,
} from "./actions.js";


function init() {
	hydrate();
	bindEvents();
	render();
	log("Controller loaded");
}


init();
