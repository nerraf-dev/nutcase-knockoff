# Playwright Setup (Controller)

## 1) Install dependencies

```bash
npm install
npx playwright install chromium
```

## 2) Run the smoke tests

```bash
npm run test:e2e
```

## 3) Run in headed mode (watch what it does)

```bash
npm run test:e2e:headed
```

## 4) Open Playwright UI mode

```bash
npm run test:e2e:ui
```

## What is covered now

- `tests/e2e/controller-multi.spec.js`
- Multi-controller harness spawns the requested number of clients.
- Controller page reads URL parameters for host/name/avatar/debug.

## Next suggested tests

- Add a mock WebSocket server in test setup to verify `join`, `ready`, `slider_click`, and `guess` messages.
- Add retries only for known flaky network tests.
- Add one CI job that runs Chromium e2e on pushes.
