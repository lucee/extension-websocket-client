# WebSocket Client Extension — Tests

## Two test tiers

### Unit tests (this folder)

`WebSocketClientTest.cfc` extends `org.lucee.cfml.test.LuceeTestCase` and exercises the BIF's own contract — no WebSocket server required:

- `CreateWebSocketClient()` argument validation (arg counts, non-component listener)
- Scheme handling (`ws://`, `wss://`, rejection of `http://`)
- Connection error timing (refused-connection fails fast, unroutable IP hits the library's 5s timeout)
- `onError( type="connect", ... )` listener invocation on connect failure
- OSGi loader health

Runs in the `test` job via `lucee/script-runner@main` with `testLabels: websocketclient`. Fast, no network dependencies beyond loopback.

### Integration tests (server repo)

The real client⇄server coverage — `sendText`, `sendBinary`, `onMessage`, `onClose`, `disconnect`, `isOpen`, lifecycle event ordering — lives in the server extension repo:

[lucee/extension-websocket — `tests/integration/`](https://github.com/lucee/extension-websocket/tree/master/tests/integration)

Those tests use `CreateWebSocketClient` as the driver against a Lucee WebSocket server listener, so they cover both extensions end to end.

## Why not duplicate the integration tests here?

Every integration test needs both extensions running. Duplicating the suite across two repos guarantees drift. Instead:

- One copy lives in the server repo.
- The `test-integration` job in this repo's workflow **sparse-checkouts** `tests/integration/` from the server repo, builds this branch's client `.lex`, pulls the latest server `.lex` from download.lucee.org, and runs the suite against the combined pair.
- Each side's CI catches the bug on its own side — server changes fail in the server repo, client changes fail here.

## What fails where

| Bug source | Caught by |
| --- | --- |
| Client BIF contract (scheme handling, error shape, connection timing) | Unit tests in this repo |
| Client send/receive, lifecycle, reconnect | Integration tests (cross-repo) |
| Server callback firing, broadcast, state | Integration tests (server repo CI) |

## Adding a test

Needs a server to drive it? **Add it to the server repo's [`tests/integration/`](https://github.com/lucee/extension-websocket/tree/master/tests/integration).** Both CIs will pick it up.

No server needed (argument validation, error shape, scheme parsing)? **Add a `testXxx()` method to [`WebSocketClientTest.cfc`](WebSocketClientTest.cfc) here.**

## Running locally

Unit tests — whatever CFML test runner you use that picks up `labels="websocketclient"`. Or invoke `WebSocketClientTest.cfc` methods directly from a test script.

Integration tests — spin up Lucee with both extensions, drop the server listeners into `{lucee-config}/websockets/`, and `curl` the `.cfm` scripts from the server repo's `tests/integration/` folder. See [that repo's CI workflow](https://github.com/lucee/extension-websocket/blob/master/.github/workflows/main.yml) for the exact setup — it's the same one this repo's `test-integration` job uses.
