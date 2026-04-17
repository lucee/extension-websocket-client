# Lucee WebSocket Client Extension

[![Java CI](https://github.com/lucee/extension-websocket-client/actions/workflows/main.yml/badge.svg)](https://github.com/lucee/extension-websocket-client/actions/workflows/main.yml)

WebSocket *client* support for Lucee CFML — connect to any WebSocket server from CFML and handle messages via listener components. Powered by [nv-websocket-client](https://github.com/TakahikoKawasaki/nv-websocket-client).

**Requires Lucee 6.2+** (supports both Lucee 6.x and 7.x / Jakarta).

## Installation

Install via Lucee Admin, or pin in your environment:

```bash
LUCEE_EXTENSIONS=org.lucee:websocket-client-extension:2.3.0.9-SNAPSHOT
```

## Documentation

- **Docs**: [docs.lucee.org/reference/functions/createwebsocketclient.html](https://docs.lucee.org/reference/functions/createwebsocketclient.html)
- **Downloads**: [download.lucee.org](https://download.lucee.org/#058215B3-5544-4392-A187A1649EB5CA90)
- **Issues**: [Lucee JIRA — WebSocket Issues](https://luceeserver.atlassian.net/issues/?jql=labels%20%3D%20%22websockets%22)

### What's Included

- **`CreateWebSocketClient( endpoint, component )` BIF** — connects to a WebSocket server and returns a client socket you can `sendText()` / `sendBinary()` / `disconnect()` on.
- **Listener callbacks** — your component receives `onMessage`, `onBinaryMessage`, `onClose`, `onError`, `onPing`, `onPong`.
- **Per-message deflate** — `permessage-deflate` extension enabled by default.

## Quick Example

```cfml
// Listener component
component {

    function onMessage( message ) {
        systemOutput( "received: " & message, true );
    }

    function onError( type, cause ) {
        systemOutput( "error [#type#]: #cause.getMessage()#", true );
    }

    function onClose() {
        systemOutput( "connection closed", true );
    }

}
```

```cfml
ws = CreateWebSocketClient( "ws://localhost:8080/ws/EchoListener", new Listener() );
ws.sendText( "hello server" );
// ...
ws.disconnect();
```

## Related

- **[extension-websocket](https://github.com/lucee/extension-websocket)** — the server-side companion for hosting WebSocket endpoints in Lucee. Its integration tests exercise the full client⇄server loop (connect, send, echo, disconnect) and provide the real coverage for `sendText()` / `disconnect()` in this extension.
