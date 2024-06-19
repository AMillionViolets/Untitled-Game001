extends Node2D

@export var itemRes: InventoryItem
func collect_gold(inventory: Inventory):
	inventory.insertgold(itemRes)
	queue_free()
	
	
	
