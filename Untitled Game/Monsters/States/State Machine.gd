extends Node

@export var InitState: state

var currentState: state
var states : Dictionary = {}



func _ready():
	for child in get_children():
		if child is state:
			states[child.name.to_lower ()]=child
			child.transitoned.connect(on_child_transition)
		if InitState:
			InitState.enter()
			currentState=InitState


func _process(delta):
	if currentState:
		currentState.update(delta)
	
func _physics_process(delta):
	if currentState:
		currentState.physics_update(delta)
		
func on_child_transition(change_to_state, new_state_name):
	if change_to_state !=currentState:
		return
	var new_state 
	new_state = states.get(new_state_name.to_lower())
	if !new_state:
		return
	
	if currentState:
		currentState.exit()
	new_state.enter()
	
	currentState = new_state
