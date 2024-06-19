extends Control

var isOpen: bool = false 

@onready var inventory: Inventory = preload("res://Inventroy/playerinventory.tres")
@onready var slots = $VBoxContainer/NinePatchRect/GridContainer.get_children()

@onready var goldamount = $VBoxContainer/HBoxContainer/Label


func _ready():
	inventory.Inventoryupdated.connect(update)
	update()

func update():
	for i in range(min(inventory.items.size(),slots.size())):
		slots[i].update(inventory.items[i])
	goldamount.text = str(inventory.playergold)
	
	

func open():
	visible = true
	isOpen = true
	
func close():
	visible = false
	isOpen = false
