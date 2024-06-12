extends Panel

@onready var background_sprite = $BackgroundSprite
@onready var item_sprite = $CenterContainer/Panel/ItemSprite



func update(item: InventoryItem):
	if !item:
		item_sprite.visible = false
	else:
		item_sprite.visible = true
		item_sprite.texture = item.texture
