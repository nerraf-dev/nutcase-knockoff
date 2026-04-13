// @ts-check
const { defineConfig } = require("@playwright/test");

module.exports = defineConfig({
	testDir: "./tests/e2e",
	timeout: 30_000,
	retries: 0,
	fullyParallel: true,
	reporter: [["list"], ["html", { open: "never" }]],
	use: {
		baseURL: "http://127.0.0.1:4173",
		trace: "retain-on-failure",
		screenshot: "only-on-failure",
		video: "retain-on-failure",
	},
	webServer: {
		command: "node tools/static-server.cjs",
		port: 4173,
		reuseExistingServer: true,
		timeout: 30_000,
	},
});
