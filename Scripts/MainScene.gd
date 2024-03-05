extends Node2D

var client = SocketIOClient
var clientID = null
var backendURL : String

var activeSessions = []
var joinedSession = "none"

var arcadeInstance = null


func _ready():
	pass

func _process(delta):
	if ( !( joinedSession == "none" ) && !(arcadeInstance == null) ) :
		if ( arcadeInstance.player == null ) :
			return
		
		if ( arcadeInstance._grabUpdateState() == true ) :
			arcadeInstance._resetUpdateState()
			
			on_socket_send( "playerRequest", {
				"sessionID" : joinedSession,
				"socketID" : clientID,
				"requestType" : "updatePlayerTransform",
				"requestedData" : arcadeInstance._updateTransform( clientID )
			} );

func _joinServer():
	# prepare URL
	backendURL = "http://localhost:3000/socket.io"

	# initialize client
	client = SocketIOClient.new( backendURL )

	# this signal is emitted when the socket is ready to connect
	client.on_engine_connected.connect( on_socket_ready )

	# this signal is emitted when socketio server is connected
	client.on_connect.connect( on_socket_connect )

	# this signal is emitted when socketio server sends a message
	client.on_event.connect( on_socket_event )

	# add client to tree to start websocket
	add_child( client )

func _exit_tree():
	# optional: disconnect from socketio server
	client.socketio_disconnect()

func on_socket_ready( _sid: String ):
	# connect to socketio server when engine.io connection is ready
	client.socketio_connect()

func on_socket_connect( _payload: Variant, _name_space, error: bool ):
	if error:
		push_error( "I Failed To Connect To The Server" )
	else:
		print( "I Am Now Connected To The Server" )

func on_socket_event( event_name: String, payload: Variant, _name_space ):
	match event_name :
		"playerJoined" :
			arcadeInstance._playerJoin( payload.socketID, payload.userData )
		"recieveSessionNames" :
			activeSessions = payload.sessions.duplicate( true )
			
			_loadActiveSessions()
		"removeUser" :
			arcadeInstance._removePlayer( payload.socketID )
		"requestTransform" :
			print( "Recieved Transform Request" )
			
			clientID = payload.connectionID
			joinedSession = payload.sessionID
			
			var newPacket = arcadeInstance._requestTransform()
			newPacket.sessionID = joinedSession
			
			on_socket_send( "serveTransformRequest", newPacket )
		"sessionJoined" :
			print( payload.message )
			
			arcadeInstance.player = payload.socketID
			
			arcadeInstance._makePlayers( payload.sessionData )
		"updateSessionState" :
			arcadeInstance._sessionStateUpdate( payload )

func on_socket_send( event_name: String, payload ) :
	client.socketio_send( event_name, payload )

func _swapMenu(menu):
	match menu :
		"serverConnectionMenu" :
			$ServerConnectionMenu.visible = true
			$SessionConnectionMenu.visible = false
			$StartPlayerControllMenu.visible = false
		"sessionConnectionMenu" :
			$ServerConnectionMenu.visible = false
			$SessionConnectionMenu.visible = true
			$StartPlayerControllMenu.visible = false
		"startPlayerControlMenu" :
			$ServerConnectionMenu.visible = false
			$SessionConnectionMenu.visible = false
			$StartPlayerControllMenu.visible = true
		"none" :
			$ServerConnectionMenu.visible = false
			$SessionConnectionMenu.visible = false
			$StartPlayerControllMenu.visible = false

func _joinSession( sessionID ):
	on_socket_send( "joinSession", { "message" : "Hello Server I'd Like To Join A Session", "sessionID" : sessionID } )
	_swapMenu( "startPlayerControlMenu" )
	_setUpArcade()

func _makeSession():
	on_socket_send( "makeSession", { "message" : "Hello Server Please Make A Session" } )

func _loadActiveSessions():
	if ( activeSessions.size() > 0 ):
		var sessionButtonTemplate = preload( "res://session_button.tscn" )
		
		for session in activeSessions:
			var sessionButtonInstance = sessionButtonTemplate.instantiate()
			
			sessionButtonInstance.text = session
			
			sessionButtonInstance.pressed.connect( func(): _joinSession( session ) )
			
			$SessionConnectionMenu/ScrollContainer/SessionList.add_child( sessionButtonInstance )

func _on_button_pressed():
	_joinServer()
	_swapMenu( "sessionConnectionMenu" )

func _on_make_session_button_pressed():
	_makeSession()
	_swapMenu( "startPlayerControlMenu" )
	_setUpArcade()

func _setUpArcade():
	var arcadeTemplate = preload( "res://Scenes/arcade.tscn" )
	
	arcadeInstance = arcadeTemplate.instantiate()
	
	add_child( arcadeInstance )

func _on_start_button_pressed():
	arcadeInstance._possessPlayer( clientID )
	_swapMenu( "none" )
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED) # To Keep Mouse Within The Screen
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE) # To Release Mouse From The Screen
