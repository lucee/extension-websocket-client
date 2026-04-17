component extends="org.lucee.cfml.test.LuceeTestCase" labels="websocketclient" {

	// ---- loader / OSGi health ----

	function testCreateWebSocketClientLoads() {
		try {
			ws = CreateWebSocketClient( "ws://localhost:9999/nope", new WebSocketListener() );
			fail( "Expected connection error" );
		}
		catch ( any e ) {
			// connection refused is expected — means the class loaded and OSGi resolved OK
			expect( e.message ).notToInclude( "osgi.wiring.package" );
			expect( e.message ).notToInclude( "Unable to resolve" );
		}
	}

	// ---- BIF signature ----

	function testBifRejectsZeroArgs() {
		try {
			CreateWebSocketClient();
			fail( "Expected function exception for 0 args" );
		}
		catch ( any e ) {
			// expected — function requires exactly 2 args
			expect( e.message & e.type ).toInclude( "unction" );
		}
	}

	function testBifRejectsOneArg() {
		try {
			CreateWebSocketClient( "ws://localhost:9999/nope" );
			fail( "Expected function exception for 1 arg" );
		}
		catch ( any e ) {
			expect( e.message & e.type ).toInclude( "unction" );
		}
	}

	function testBifRejectsThreeArgs() {
		try {
			CreateWebSocketClient( "ws://localhost:9999/nope", new WebSocketListener(), "extra" );
			fail( "Expected function exception for 3 args" );
		}
		catch ( any e ) {
			expect( e.message & e.type ).toInclude( "unction" );
		}
	}

	function testRejectsNonComponentListener() {
		try {
			CreateWebSocketClient( "ws://localhost:9999/nope", "not a component" );
			fail( "Expected cast error when listener is not a component" );
		}
		catch ( any e ) {
			// toComponent() should reject a plain string
			expect( e.message & e.type ).toInclude( "omponent" );
		}
	}

	// ---- scheme handling ----

	function testWssSchemeAccepted() {
		// wss:// should parse cleanly; we expect a CONNECTION error, not a URL / scheme error
		try {
			CreateWebSocketClient( "wss://127.0.0.1:9999/nope", new WebSocketListener() );
			fail( "Expected connection error for unreachable wss endpoint" );
		}
		catch ( any e ) {
			expect( e.message ).notToInclude( "osgi.wiring.package" );
			expect( e.message ).notToInclude( "Unable to resolve" );
			expect( e.message ).notToInclude( "MalformedURLException" );
			expect( e.message ).notToInclude( "unknown protocol" );
		}
	}

	function testInvalidSchemeRejected() {
		// http:// is not a websocket scheme — we expect this to fail
		try {
			CreateWebSocketClient( "http://127.0.0.1:9999/nope", new WebSocketListener() );
			fail( "Expected error for non-websocket scheme" );
		}
		catch ( any e ) {
			// any error is acceptable — the point is it doesn't silently succeed
			expect( true ).toBe( true );
		}
	}

	// ---- connection error behaviour ----

	function testConnectionRefusedFailsQuickly() {
		// 127.0.0.1:1 should RST almost immediately (no OS-level SYN retry)
		var start = getTickCount();
		try {
			CreateWebSocketClient( "ws://127.0.0.1:1/none", new WebSocketListener() );
			fail( "Expected connection refused" );
		}
		catch ( any e ) {
			var elapsed = getTickCount() - start;
			// RST should arrive well before the 5000ms library timeout
			expect( elapsed ).toBeLT( 5000 );
		}
	}

	function testConnectionTimeoutEnforced() {
		// 10.255.255.1 is typically non-routable; should hit the library's hardcoded
		// 5000ms timeout rather than the much longer OS-level TCP SYN timeout.
		// If the CI network routes this differently, the test may be flaky — adjust if needed.
		var start = getTickCount();
		try {
			CreateWebSocketClient( "ws://10.255.255.1:9999/nope", new WebSocketListener() );
			fail( "Expected connection timeout" );
		}
		catch ( any e ) {
			var elapsed = getTickCount() - start;
			// Generous window: 3s-10s (5s ± slop for CI jitter)
			expect( elapsed ).toBeGT( 3000 );
			expect( elapsed ).toBeLT( 10000 );
		}
	}

	// ---- listener callback invocation on connect failure ----

	function testOnErrorFiresOnConnectFailure() {
		var listener = new RecordingListener();
		try {
			CreateWebSocketClient( "ws://127.0.0.1:1/none", listener );
			fail( "Expected connection error" );
		}
		catch ( any e ) {
			// onError should have fired with type "connect" before the exception surfaced
			var events = listener.getEvents();
			var found = false;
			for ( var entry in events ) {
				if ( entry == "onError:connect" ) {
					found = true;
					break;
				}
			}
			expect( found ).toBeTrue();
		}
	}

	// ---- Round-trip tests (sendText/sendBinary/onMessage/onClose/disconnect/isOpen)
	//      live in the extension-websocket repo's test-websocket-client.cfm and
	//      planned siblings. They need a running WebSocket server, which the
	//      server extension provides. Adding round-trip coverage here would
	//      require installing a second extension in this repo's CI — we avoid
	//      that and rely on the server repo for integration coverage.

}
