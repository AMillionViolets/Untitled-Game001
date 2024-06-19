extends Resource
class_name Inventory 

signal Inventoryupdated

@export var items: Array[InventoryItem]
@export var playergold: int 

func insert(item :InventoryItem):
	for i in range(items.size()):
		if !items[i]:
			items[i] = item
			break
	Inventoryupdated.emit()
	
func insertgold(gold: InventoryItem):
	playergold =+ gold.goldValue
	Inventoryupdated.emit()
	
	
