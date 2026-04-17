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

	function onError( type, cause, data ) {
		var entry = "onError:" & arguments.type;
		if ( structKeyExists( arguments, "data" ) && !isNull( arguments.data ) )
			entry &= ":withData";
		arrayAppend( variables.events, entry );
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
