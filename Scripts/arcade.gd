extends Node3D

var players = {}
var player = null
var transformChange = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$Node3D.make_current()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _grabUpdateState():
	if ( players[ player ].needsUpdate == true ) :
		return true
	else :
		return false

func _resetUpdateState():
	players[ player ].needsUpdate == false

func _makePlayers( users ):
	var playerTemplate = preload("res://GameEntities/PlayerAssets/player_template.tscn")
	
	var userIDs = users.keys()
	
	for user in userIDs :
		var playerinst = playerTemplate.instantiate()
		
		if ( user == player ) :
			playerinst.activePlayer = true
		
		add_child(playerinst)
		
		players[ user ] = playerinst
		
		playerinst.position = Vector3( users[ user ].position.x, users[ user ].position.y, users[ user ].position.z );
		playerinst.quaternion = Quaternion( users[ user ].rotation.x, users[ user ].rotation.y, users[ user ].rotation.z, users[ user ].rotation.w )

func _makePlayer( socketID, userData ) :
	var playerTemplate = preload("res://GameEntities/PlayerAssets/player_template.tscn")
	
	var playerinst = playerTemplate.instantiate()
	
	add_child(playerinst)
	
	playerinst.position = Vector3( userData.position.x, userData.position.y, userData.position.z );
	playerinst.quaternion = Quaternion( userData.rotation.x, userData.rotation.y, userData.rotation.z, userData.rotation.w )
	
	players[ socketID ] = playerinst

func _possessPlayer( socketID ) :
	players[ socketID ]._possessPlayer()

func _playerJoin( socketID, userData ) :
	_makePlayer( socketID, userData )

func _removePlayer( socketID ) :
	players[ socketID ].queue_free()
	
	players.erase( socketID )

func _requestTransform() :
	return {
		"pos" : { "x" : 0, "y" : 0, "z" : 0 },
		"rot" : { "x" : 0, "y" : 0, "z" : 0, "w" : 0 }
	}

func _updateTransform( socketID ) :
	return {
		"position" : { "x" : players[ socketID ].position.x, "y" : players[ socketID ].position.y, "z" : players[ socketID ].position.z },
		"rotation" : { "x" : players[ socketID ].quaternion.x, "y" : players[ socketID ].quaternion.y, "z" : players[ socketID ].quaternion.z, "w" : players[ socketID ].quaternion.w }
	}

func _sessionStateUpdate( RecievedData ):
	var users = RecievedData.keys()
	
	for user in users :
		var userData = RecievedData[ user ]
		
		if ( user in players ) :
			if ( user !=  player ) :
				players[ user ].position = Vector3( userData.position.x, userData.position.y, userData.position.z );
				players[ user ].quaternion = Quaternion( userData.rotation.x, userData.rotation.y, userData.rotation.z, userData.rotation.w )
		else :
			_makePlayer( user, RecievedData[ user ] )

func _input(event):
	if ( player in players ):
		if ( event is InputEventKey ):
			if ( event.pressed ):
				#print("Key Pressed:", OS.get_keycode_string(event.keycode))
				if ( OS.get_keycode_string( event.keycode ) == "W" ):
					players[ player ]._updateMovementInputs( "W", true )
				if ( OS.get_keycode_string( event.keycode ) == "A" ):
					players[ player ]._updateMovementInputs( "A", true )
				if ( OS.get_keycode_string( event.keycode ) == "S" ):
					players[ player ]._updateMovementInputs( "S", true )
				if ( OS.get_keycode_string( event.keycode ) == "D" ):
					players[ player ]._updateMovementInputs( "D", true )
			else:
				#print("Key Released:", OS.get_keycode_string(event.keycode))
				if ( OS.get_keycode_string( event.keycode ) == "W" ):
					players[ player ]._updateMovementInputs( "W", false )
				if ( OS.get_keycode_string( event.keycode ) == "A" ):
					players[ player ]._updateMovementInputs( "A", false )
				if ( OS.get_keycode_string( event.keycode ) == "S" ):
					players[ player ]._updateMovementInputs( "S", false )
				if ( OS.get_keycode_string( event.keycode ) == "D" ):
					players[ player ]._updateMovementInputs( "D", false )
			
		if ( event is InputEventMouseMotion ) :
			var mouse_delta = event.relative
			
			players[ player ]._updateLeftRightRotation( mouse_delta.x )
