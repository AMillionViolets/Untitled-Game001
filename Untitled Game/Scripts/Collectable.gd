extends Area2D
class_name Collectable

@export var itemRes: InventoryItem

func collect(inventory: Inventory):
	inventory.insert(itemRes)
	queue_free()
	
