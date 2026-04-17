component hint="Test fixture — records every callback invocation for assertion" {

	variables.events = [];

	function onMessage( message ) {
		arrayAppend( variables.events, "onMessage:" & arguments.message );
	}

	function onBinaryMessage( binary ) {
		arrayAppend( variables.events, "onBinaryMessage:" & arrayLen( arguments.binary ) );
	}

	function onClose() {
		arrayAppend( variables.events, "onClose" );
	}

	function onError( type, cause ) {
		// Match the 2-arg signature the existing WebSocketListener uses. The 3rd
		// `data` arg is only populated for `message`-type errors; if we need to
		// test that later, add a separate fixture.
		arrayAppend( variables.events, "onError:" & arguments.type );
	}

	function onPing() {
		arrayAppend( variables.events, "onPing" );
	}

	function onPong() {
		arrayAppend( variables.events, "onPong" );
	}

	array function getEvents() {
		return variables.events;
	}

	function reset() {
		variables.events = [];
	}

}
