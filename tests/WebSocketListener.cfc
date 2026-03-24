component {

	function onMessage( message ) {
		systemOutput( "onMessage: " & message, true );
	}

	function onError( type, cause ) {
		systemOutput( "onError: " & type, true );
	}

}
