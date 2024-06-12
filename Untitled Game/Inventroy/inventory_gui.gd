extends Control

var isOpen: bool = false 

@onready var inventory: Inventory = preload("res://Inventroy/playerinventory.tres")
@onready var slots = $NinePatchRect/GridContainer.get_children()


func _ready():
	inventory.Inventoryupdated.connect(update)
	update()

func update():
	for i in range(min(inventory.items.size(),slots.size())):
		slots[i].update(inventory.items[i])

func open():
	visible = true
	isOpen = true
	
func close():
	visible = false
	isOpen = false
