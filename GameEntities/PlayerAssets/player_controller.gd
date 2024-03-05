extends Node3D

var movementInputs = [ false, false, false, false ] # W A S D
var activePlayer = false # If This Is The Current Player
var playerSpeed = 15
var possessed = false
var previousPos = Vector3( 0, 0, 0 )
var previousRot = Quaternion( 0, 0, 0, 0 )
var processFrame = 0
var needsUpdate = false

# The Mouse Moves And Changes This
var leftRightRotationInput = 0 # The Amount Of Left Right Rotation Input
var upDownRotationInput = 0

# The Amount Of Speed The Player Is Keeping Between Processes In Percentage
var exponentialDecay = 0.01
# The Character's Current Movement Speed And Direction
var characterVelocity = Vector3( 0, 0, 0 )

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Don't Even Think About Running The Movement Logic If This Isn't The Current Player
	if ( activePlayer == false || possessed == false ) :
		return
	
	# Update Based On Player Inputs
	var forward_vector = global_transform.basis.x
	var rightward_vector = global_transform.basis.z
	
	var directedVelocity = Vector3( 0, 0, 0 )
	
	if ( movementInputs[0] == true ) : # Forward
		directedVelocity += forward_vector
	if ( movementInputs[1] == true ) : # Leftward
		directedVelocity -= rightward_vector
	if ( movementInputs[2] == true ) : # Backward
		directedVelocity -= forward_vector
	if ( movementInputs[3] == true ) : # Rightward
		directedVelocity += rightward_vector
	
	var normalizedDirection = directedVelocity.normalized()
	
	characterVelocity += normalizedDirection * playerSpeed * delta
	
	position += characterVelocity * delta
	
	if ( characterVelocity.length() > 0.03 ) :
		var currentDecay = pow( exponentialDecay, delta )
		
		characterVelocity *= currentDecay
	
	if ( directedVelocity.length() == 0 ) :
		characterVelocity *= 0
	
	if ( abs( leftRightRotationInput ) > 0 ) :
		
		var newRotation = Quaternion( global_transform.basis.y, -leftRightRotationInput/10 * delta )
		
		quaternion *= newRotation
		
		leftRightRotationInput = 0
	
	if ( processFrame == 0 ) :
		
		if ( !( position.x == previousPos.x && position.y == previousPos.y && position.z == previousPos.z) || !( quaternion.x == previousRot.x && quaternion.y == previousRot.y && quaternion.z == previousRot.z && quaternion.w == previousRot.w) ) :
			previousPos = position
			previousRot = quaternion
			
			## Send Off New Data
			needsUpdate = true
		
		processFrame = 1
	elif ( processFrame == 1 ):
		processFrame = 0

func _possessPlayer():
	$HeadController/Camera3D.make_current()
	
	possessed = true
	
	$HeadController/Head.visible = false
	$HeadController/Nose.visible = false
	$CSGBox3D.visible = false

func _updateLeftRightRotation( playerRotationInput : float ) :
	leftRightRotationInput += playerRotationInput

func _updateUpDownRotation( playerRotationInput : float ) :
	upDownRotationInput += playerRotationInput

func _updateMovementInputs( currentInput : String, inputValue : bool ):
	var playerInputs = [ "W", "A", "S", "D" ]
	
	movementInputs[ playerInputs.find( currentInput ) ] = inputValue

func _roundToNearest( number, hundreds ) :
	return round(number * hundreds)/hundreds
