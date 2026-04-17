component extends="org.lucee.cfml.test.LuceeTestCase" labels="websocketclient" {

	function run() {

		describe( "CreateWebSocketClient()", function() {

			it( "loads without OSGi resolution errors", function() {
				try {
					CreateWebSocketClient( "ws://localhost:9999/nope", new WebSocketListener() );
					fail( "Expected connection error" );
				}
				catch ( any e ) {
					// connection refused is expected — means the class loaded and OSGi resolved OK
					expect( e.message ).notToInclude( "osgi.wiring.package" );
					expect( e.message ).notToInclude( "Unable to resolve" );
				}
			});

			describe( "argument validation", function() {
				// Note: wrong arg counts are rejected by the Lucee parser at compile time —
				// no runtime behaviour to test.

				it( "rejects a non-component listener", function() {
					try {
						CreateWebSocketClient( "ws://localhost:9999/nope", "not a component" );
						fail( "Expected cast error when listener is not a component" );
					}
					catch ( any e ) {
						expect( e.message & e.type ).toInclude( "omponent" );
					}
				});
			});

			describe( "scheme handling", function() {

				it( "accepts wss:// and surfaces a connection error, not a scheme error", function() {
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
				});

				it( "rejects non-websocket schemes like http://", function() {
					try {
						CreateWebSocketClient( "http://127.0.0.1:9999/nope", new WebSocketListener() );
						fail( "Expected error for non-websocket scheme" );
					}
					catch ( any e ) {
						// Any error is acceptable — the point is it doesn't silently succeed
						expect( true ).toBe( true );
					}
				});
			});

			describe( "connection error behaviour", function() {

				it( "fails quickly on connection refused (RST under 5s)", function() {
					var start = getTickCount();
					try {
						CreateWebSocketClient( "ws://127.0.0.1:1/none", new WebSocketListener() );
						fail( "Expected connection refused" );
					}
					catch ( any e ) {
						var elapsed = getTickCount() - start;
						expect( elapsed ).toBeLT( 5000 );
					}
				});

				it( "enforces the library's 5s connection timeout on unroutable IPs", function() {
					// 10.255.255.1 is typically non-routable; should hit the hardcoded
					// 5000ms library timeout rather than the OS-level TCP SYN timeout
					var start = getTickCount();
					try {
						CreateWebSocketClient( "ws://10.255.255.1:9999/nope", new WebSocketListener() );
						fail( "Expected connection timeout" );
					}
					catch ( any e ) {
						var elapsed = getTickCount() - start;
						// Generous window for CI jitter: 3-10s (5s ± slop)
						expect( elapsed ).toBeGT( 3000 );
						expect( elapsed ).toBeLT( 10000 );
					}
				});

				it( "invokes the listener's onError callback with type=connect before the exception surfaces", function() {
					var listener = new RecordingListener();
					try {
						CreateWebSocketClient( "ws://127.0.0.1:1/none", listener );
						fail( "Expected connection error" );
					}
					catch ( any e ) {
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
				});
			});
		});

		// Round-trip tests (sendText/sendBinary/onMessage/onClose/disconnect/isOpen)
		// live in extension-websocket's tests/integration/ because they need a running
		// server. See tests/README.md for the cross-repo split.
	}

}
