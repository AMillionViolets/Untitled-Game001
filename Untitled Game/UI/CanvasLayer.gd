extends CanvasLayer

@onready var inventory = $"Inventory Gui"

func _ready():
	inventory.close()

func _input(event):
	if event.is_action_pressed("Inventory"):
		if inventory.isOpen:
			inventory.close()
		else:
			inventory.open()
		
	


