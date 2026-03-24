component extends="org.lucee.cfml.test.LuceeTestCase" labels="websocketclient" {

	function testCreateWebSocketClientLoads() {
		try {
			ws = CreateWebSocketClient( "ws://localhost:9999/nope", new WebSocketListener() );
			fail( "Expected connection error" );
		}
		catch ( any e ) {
			// connection refused is expected - means the class loaded and OSGi resolved OK
			expect( e.message ).notToInclude( "osgi.wiring.package" );
			expect( e.message ).notToInclude( "Unable to resolve" );
		}
	}

}
