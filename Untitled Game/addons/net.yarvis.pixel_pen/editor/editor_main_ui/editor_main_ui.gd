@tool
extends Control


const new_project_dialog := preload("../new_project_dialog.tscn")
const edit_canvas_size := preload("../edit_canvas_size.tscn")
const startup_window := preload("../startup_window.tscn")
const image_reference_window := preload("../window_reference.tscn")
const import_window := preload("../import_window.tscn")
const export_manager := preload("../export_manager.tscn")
const shorcut : EditorShorcut = preload("../../resources/editor_shorcut.tres")

const Tool := preload("../editor_canvas/tool.gd")
const MoveTool := preload("../editor_canvas/move_tool.gd")

enum PixelPenID{
	ABOUT = 0,
	PREFERENCE,
	QUIT
}

enum FileID{
	NEW = 0,
	OPEN,
	OPEN_RECENTS,
	SAVE,
	SAVE_AS,
	IMPORT,
	EXPORT,
	EXPORT_ANIMATION,
	QUICK_EXPORT,
	CLOSE
}

enum ExportAsID{
	JPG = 0,
	PNG,
	WEBP
}

enum ExportAnimationID{
	FRAME = 0,
	GIF,
	SHEETS
}

enum EditID{
	UNDO = 0,
	REDO,
	INVERSE_SELECTION,
	CLEAR_SELECTION,
	DELETE_ON_SELECTION,
	COPY,
	CUT,
	PASTE,
	CREATE_BRUSH,
	RESET_BRUSH,
	CREATE_STAMP,
	RESET_STAMP,
	SWITCH_LAST_TOOLBOX,
	CANVAS_SIZE
}

enum LayerID{
	ADD_LAYER = 0,
	DELETE_LAYER,
	DUPLICATE_LAYER,
	COPY_LAYER,
	CUT_LAYER,
	DUPLICATE_SELECTION,
	COPY_SELECTION,
	CUT_SELECTION,
	PASTE,
	RENAME_LAYER,
	MERGE_DOWN,
	MERGE_VISIBLE,
	MERGE_ALL,
	SHOW_ALL_LAYER,
	HIDE_ALL_LAYER,
	LAYER_ACTIVE_GO_UP,
	LAYER_ACTIVE_GO_DOWN,
}

enum PaletteID{
	RESET = 0,
	SORT_COLOR,
	DELETE_UNUSED,
	DELETE_SELECTED_COLOR,
	CLEAN_INVISIBLE_COLOR,
	LOAD_AND_REPLACE,
	LOAD_AND_MERGE,
	SAVE
}

enum AnimationID{
	PLAY_PAUSE,
	SKIP_TO_FRONT,
	STEP_BACKWARD,
	STEP_FORWARD,
	SKIP_TO_END,
	TOGGLE_LOOP,
	TOGGLE_ONION_SKINNING,
	INSERT_FRAME_LEFT,
	INSERT_FRAME_RIGHT,
	DUPLICATE_FRAME,
	DUPLICATE_FRAME_LINKED,
	CONVERT_FRAME_LINKED_TO_UNIQUE,
	MOVE_FRAME_TO_LEFT,
	MOVE_FRAME_TO_RIGHT,
	MOVE_FRAME_TO_TIMELINE,
	MOVE_FRAME_TO_DRAFT,
	CREATE_DRAFT_FRAME,
	DELETE_DRAFT_FRAME
}

enum ViewID{
	SHOW_GRID = 0,
	SHOW_VERTICAL_MIRROR_GUIDE,
	SHOW_HORIZONTAL_MIRROR_GUIDE,
	SHOW_VIRTUAL_MOUSE,
	ROTATE_CANVAS_90,
	ROTATE_CANVAS_MIN_90,
	FLIP_CANVAS_HORIZONTAL,
	FLIP_CANVAS_VERTICAL,
	RESET_CANVAS_TRANSFORM,
	BACKGROUND_COLOR,
	NEW_IMAGE_REFERENCE,
	TOGGLE_TINT_SELECTED_LAYER,
	EDIT_SELECTION_ONLY,
	SHOW_TILE,
	SHOW_PREVIEW,
	FILTER_GRAYSCALE,
	SHOW_ANIMATION_TIMELINE,
	SHOW_INFO
}

@export var pixel_pen_menu : MenuButton
@export var file_menu: MenuButton
@export var edit_menu : MenuButton
@export var layer_menu : MenuButton
@export var palette_menu : MenuButton
@export var animation_menu : MenuButton
@export var view_menu : MenuButton
@export var toolbox_dock : Panel
@export var canvas : Node2D
@export var canvas_dock : ColorRect
@export var canvas_color_base : Color
@export var canvas_color_sample : Color
@export var debug_label : Label
@export var preview_node : Control
@export var animation_panel : Control
@export var layer_dock : Control
@export var layers_tool : Control
@export var theme_config : Node
@export var layout_node : Control
@export var subtool_dock : Control

var recent_submenu : PopupMenu
var background_color_submenu : PopupMenu

var _new_project_dialog : ConfirmationDialog

var _cache_layout_portrait : DataBranch
var _cache_layout_landscape : DataBranch
var _is_prev_landscape : bool


func _init():
	if not Engine.is_editor_hint():
		ThemeConfig.init_screen()


func _on_size_changed():
	if OS.get_name() == "Android" and get_rect().size != Vector2.ZERO:
		var viewport_size = get_viewport().get_visible_rect().size
		if (_is_prev_landscape and viewport_size.x > viewport_size.y) or (not _is_prev_landscape and viewport_size.x < viewport_size.y):
			return
		_is_prev_landscape = viewport_size.x > viewport_size.y
		if _is_prev_landscape and _cache_layout_landscape != null:
			layout_node.branches = _cache_layout_landscape
		elif not _is_prev_landscape and _cache_layout_portrait != null:
			layout_node.branches = _cache_layout_portrait
		else:
			layout_node.branches = theme_config.get_default_layout(layout_node)
			if _is_prev_landscape:
				_cache_layout_landscape = layout_node.branches
			else:
				_cache_layout_portrait = layout_node.branches
		layout_node.branches.clear_cache()
		layout_node.update_layout()


func _ready():
	if not PixelPen.need_connection(get_window()):
		if layout_node.branches == null:
			layout_node.branches = theme_config.get_default_layout(layout_node)
			layout_node.update_layout()
		return
	
	layout_node.branches = theme_config.get_default_layout(layout_node)
	layout_node.update_layout()
	_is_prev_landscape = get_viewport().get_visible_rect().size.x > get_viewport().get_visible_rect().size.y
	if _is_prev_landscape:
		_cache_layout_landscape = layout_node.branches
	else:
		_cache_layout_portrait = layout_node.branches

	if not Engine.is_editor_hint():
		get_window().content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
		get_window().content_scale_aspect = Window.CONTENT_SCALE_ASPECT_IGNORE
	_init_popup_menu()
	_set_shorcut()
	connect_signal()
	_on_project_file_changed()
	if OS.get_name() == "Android":
		OS.request_permissions()


func _process(_delta):
	if not PixelPen.need_connection(get_window()):
		return
	
	var edit_popup := edit_menu.get_popup()
	if PixelPen.current_project == null:
		edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.UNDO), true)
		edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.REDO), true)
		return
	
	if PixelPen.current_project.undo_redo != null:
		var undo : bool = PixelPen.current_project.undo_redo.has_undo()
		var redo : bool = PixelPen.current_project.undo_redo.has_redo()
		
		edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.UNDO), not undo)
		edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.REDO), not redo)
	
	var can_copy_cut : bool = MoveTool.mode == MoveTool.Mode.UNKNOWN
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.COPY), not can_copy_cut)
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.CUT), not can_copy_cut)
	
	var can_paste : bool = canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE and canvas.canvas_paint.tool.mode != MoveTool.Mode.UNKNOWN
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.PASTE), not can_paste)


func _on_project_file_changed():
	_on_selection_texture_changed()
	
	var pixelpen_popup = pixel_pen_menu.get_popup()
	pixelpen_popup.set_item_disabled(pixelpen_popup.get_item_index(PixelPenID.ABOUT), true)
	pixelpen_popup.set_item_disabled(pixelpen_popup.get_item_index(PixelPenID.PREFERENCE), true)
	
	var disable : bool = PixelPen.current_project == null

	animation_menu.disabled = disable

	var quick_export_path_empty : bool = false
	if PixelPen.current_project != null:
		quick_export_path_empty = PixelPen.current_project.last_export_file_path == ""
		
		canvas_dock.color = canvas_color_sample if PixelPen.current_project.use_sample else canvas_color_base
		
		file_menu.get_popup().set_item_disabled(
			file_menu.get_popup().get_item_index(FileID.EXPORT_ANIMATION)
			, not PixelPen.current_project.show_timeline)

		edit_menu.get_popup().set_item_disabled(edit_menu.get_popup().get_item_index(EditID.CANVAS_SIZE), PixelPen.current_project.use_sample)
		
		palette_menu.disabled = PixelPen.current_project.use_sample
		
		animation_panel.visible = PixelPen.current_project.show_timeline
		
		animation_menu.disabled = PixelPen.current_project.use_sample or not PixelPen.current_project.show_timeline
		
		var animation_popup = animation_menu.get_popup()
		animation_popup.set_item_checked(animation_popup.get_item_index(AnimationID.TOGGLE_LOOP), PixelPen.current_project.animation_loop)
		animation_popup.set_item_checked(animation_popup.get_item_index(AnimationID.TOGGLE_ONION_SKINNING), PixelPen.current_project.onion_skinning)

		var view_popup := view_menu.get_popup()
		view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_GRID), PixelPen.current_project.show_grid)
		view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_VERTICAL_MIRROR_GUIDE), PixelPen.current_project.show_symetric_vertical)
		view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_HORIZONTAL_MIRROR_GUIDE), PixelPen.current_project.show_symetric_horizontal)
		view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_TILE), PixelPen.current_project.show_tile)
		view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_PREVIEW), PixelPen.current_project.show_preview)
		
		preview_node.visible = PixelPen.current_project.show_preview

		view_popup.set_item_checked(view_popup.get_item_index(ViewID.EDIT_SELECTION_ONLY), PixelPen.current_project.use_sample)
		view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_ANIMATION_TIMELINE), PixelPen.current_project.show_timeline)
		
		var need_update_layout : bool = false
		var has_anim_dock : bool = layout_node.has_dock(animation_panel)
		if PixelPen.current_project.show_timeline and not has_anim_dock:
			layout_node.dock(animation_panel, canvas_dock, false, 0.8, true)
			need_update_layout = true
		elif has_anim_dock and not PixelPen.current_project.show_timeline:
			layout_node.undock(animation_panel)
			need_update_layout = true
		var has_preview_dock : bool = layout_node.has_dock(preview_node)
		if has_preview_dock and not PixelPen.current_project.show_preview:
			layout_node.undock(preview_node)
			need_update_layout = true
		elif not has_preview_dock and PixelPen.current_project.show_preview:
			layout_node.dock(preview_node, layer_dock, true, 0.35, true)
			need_update_layout = true
		if need_update_layout:
			layout_node.update_layout()
		
	else:
		preview_node.visible = true
		animation_panel.visible = false
		canvas_dock.color = canvas_color_base
		var need_update_layout : bool = false
		if layout_node.has_dock(animation_panel):
			layout_node.undock(animation_panel)
			need_update_layout = true
		if not layout_node.has_dock(preview_node):
			layout_node.dock(preview_node, layer_dock, true, 0.35, true)
			need_update_layout = true
		if need_update_layout:
			layout_node.update_layout()
		
		file_menu.get_popup().set_item_disabled(file_menu.get_popup().get_item_index(FileID.EXPORT_ANIMATION), disable )
		palette_menu.disabled = true

	var file_popup = file_menu.get_popup()
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.SAVE), disable)
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.SAVE_AS), disable)
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.EXPORT), disable )
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.QUICK_EXPORT), disable or quick_export_path_empty)
	file_popup.set_item_disabled(file_popup.get_item_index(FileID.CLOSE), disable )
	edit_menu.disabled = disable
	layer_menu.disabled = disable
	view_menu.disabled = disable
	
	var is_window_running : bool = false
	if get_window() and get_window().is_inside_tree() and get_window().has_method("is_window_running"):
		is_window_running = get_window().is_window_running()
	
	if disable and (not Engine.is_editor_hint() or is_window_running):
		var ok = PixelPen.load_cache_project()
		if not ok:
			_on_request_startup_window()
	
	if PixelPen.current_project != null:
		PixelPen.current_project.undo_redo = UndoRedoManager.new()
		
	_update_title()
	_update_recent_submenu()
	_update_background_color_submenu()


func _on_request_startup_window():
	var startup = startup_window.instantiate()
	add_child(startup)
	startup.popup_centered()
	startup.call_deferred("grab_focus")


func _update_title():
	if is_inside_tree():
		if PixelPen.current_project == null:
			get_window().title = "Empty - " + PixelPen.EDITOR_TITTLE
			return
		
		var is_saved : bool = (PixelPen.current_project as PixelPenProject).is_saved
		
		var canvas_size = str("(", PixelPen.current_project.canvas_size.x, "x", PixelPen.current_project.canvas_size.y , "px)")
		if PixelPen.current_project.use_sample:
			canvas_size = str("(region ", 
					PixelPen.current_project.canvas_size.x, "x", PixelPen.current_project.canvas_size.y , "px of ", 
					PixelPen.current_project._cache_canvs_size.x, "x", PixelPen.current_project._cache_canvs_size.y , "px)")
		get_window().title = PixelPen.current_project.project_name + " " + canvas_size + " - " + PixelPen.EDITOR_TITTLE
		if PixelPen.current_project.file_path == "" or not is_saved:
			get_window().title = "(*)" + get_window().title


func _update_recent_submenu():
	recent_submenu.clear(true)
	if PixelPen.userconfig.recent_projects != null and PixelPen.userconfig.recent_projects.size() > 0:
		for i in range(PixelPen.userconfig.recent_projects.size()):
			recent_submenu.add_item(PixelPen.userconfig.recent_projects[i], i)
	else:
		recent_submenu.add_item("_", 0)


func _update_background_color_submenu():
	background_color_submenu.clear(true)
	if PixelPen.current_project != null :
		var project : PixelPenProject = PixelPen.current_project as PixelPenProject
		background_color_submenu.add_radio_check_item("Transparent", project.BackgroundColor.TRANSPARENT)
		background_color_submenu.add_radio_check_item("White", project.BackgroundColor.WHITE)
		background_color_submenu.add_radio_check_item("Grey", project.BackgroundColor.GREY)
		background_color_submenu.add_radio_check_item("Black", project.BackgroundColor.BLACK)
		background_color_submenu.set_item_checked(project.background_color, true)
		var colors : Array = [
			Color(0, 0, 0, 0),
			Color.WHITE,
			Color.GRAY,
			Color.BLACK
		]
		canvas.background_canvas.material.set_shader_parameter("tint", colors[project.background_color])


func _init_popup_menu():
	var pixelpen_popup : PopupMenu = pixel_pen_menu.get_popup()
	pixelpen_popup.add_item("About", PixelPenID.ABOUT)
	pixelpen_popup.add_item("Preferences", PixelPenID.PREFERENCE)
	pixelpen_popup.add_separator("", 100)
	pixelpen_popup.add_item("Quit PixePen", PixelPenID.QUIT)
	
	var file_popup : PopupMenu = file_menu.get_popup()
	file_popup.add_item("New Project...", FileID.NEW)
	file_popup.add_item("Open Existing Project...", FileID.OPEN)
	file_popup.add_item("Open Recents Project...", FileID.OPEN_RECENTS)
	file_popup.add_separator("", 100)
	file_popup.add_item("Save Project", FileID.SAVE)
	file_popup.add_item("Save Project As...", FileID.SAVE_AS)
	file_popup.add_separator("", 100)
	file_popup.add_item("Import Image...", FileID.IMPORT)
	file_popup.add_separator("", 100)
	file_popup.add_item("Exports As Image...", FileID.EXPORT)
	file_popup.add_item("Quick Export Image", FileID.QUICK_EXPORT)
	file_popup.add_item("Exports Animation...", FileID.EXPORT_ANIMATION)
	file_popup.add_separator("", 100)
	file_popup.add_item("Close Project", FileID.CLOSE)
	
	recent_submenu = PopupMenu.new()
	recent_submenu.set_name("recent_submenu")
	_update_recent_submenu()
	recent_submenu.id_pressed.connect(func (id : int):
			if PixelPen.userconfig.recent_projects != null and PixelPen.userconfig.recent_projects.size() > id:
				PixelPen.load_project(PixelPen.userconfig.recent_projects[id])
				_update_recent_submenu()
			)
	file_popup.add_child(recent_submenu)
	file_popup.set_item_submenu(file_popup.get_item_index(FileID.OPEN_RECENTS), "recent_submenu")
	
	var import_submenu : PopupMenu = PopupMenu.new()
	import_submenu.set_name("import_submenu")
	import_submenu.add_item("*.jpg", ExportAsID.JPG)
	import_submenu.add_item("*.png", ExportAsID.PNG)
	import_submenu.add_item("*.webp", ExportAsID.WEBP)
	import_submenu.id_pressed.connect(_on_export)
	file_popup.add_child(import_submenu)
	file_popup.set_item_submenu(file_popup.get_item_index(FileID.EXPORT), "import_submenu")
	
	var export_animation_submenu : PopupMenu = PopupMenu.new()
	export_animation_submenu.set_name("export_animation_submenu")
	export_animation_submenu.add_item("[*.png, ...]", ExportAnimationID.FRAME)
	export_animation_submenu.add_item("*.gif", ExportAnimationID.GIF)
	export_animation_submenu.add_item("*.png; Animation sheets", ExportAnimationID.SHEETS)
	export_animation_submenu.id_pressed.connect(_on_export_animation)
	file_popup.add_child(export_animation_submenu)
	file_popup.set_item_submenu(file_popup.get_item_index(FileID.EXPORT_ANIMATION), "export_animation_submenu")
	
	var edit_popup : PopupMenu = edit_menu.get_popup()
	edit_popup.add_item("Undo", EditID.UNDO)
	edit_popup.add_item("Redo", EditID.REDO)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Inverse selection", EditID.INVERSE_SELECTION)
	edit_popup.add_item("Clear selection", EditID.CLEAR_SELECTION)
	edit_popup.add_item("Delete on selection", EditID.DELETE_ON_SELECTION)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Copy", EditID.COPY)
	edit_popup.add_item("Cut", EditID.CUT)
	edit_popup.add_item("Paste", EditID.PASTE)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Create brush from selection", EditID.CREATE_BRUSH)
	edit_popup.add_item("Reset brush to default", EditID.RESET_BRUSH)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Create stamp from selection", EditID.CREATE_STAMP)
	edit_popup.add_item("Reset stamp to default", EditID.RESET_STAMP)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Switch to previous toolbox", EditID.SWITCH_LAST_TOOLBOX)
	edit_popup.add_separator("", 100)
	edit_popup.add_item("Canvas size...", EditID.CANVAS_SIZE)
	
	var layer_popup : PopupMenu = layer_menu.get_popup()
	layer_popup.add_item("Add layer...", LayerID.ADD_LAYER)
	layer_popup.add_item("Delete layer", LayerID.DELETE_LAYER)
	layer_popup.add_separator()
	layer_popup.add_item("Duplicate layer", LayerID.DUPLICATE_LAYER)
	layer_popup.add_item("Duplicate selection", LayerID.DUPLICATE_SELECTION)
	layer_popup.add_separator()
	layer_popup.add_item("Copy layer", LayerID.COPY_LAYER)
	layer_popup.add_item("Cut layer", LayerID.CUT_LAYER)
	layer_popup.add_separator()
	layer_popup.add_item("Paste to new layer", LayerID.PASTE)
	layer_popup.add_separator()
	layer_popup.add_item("Rename layer...", LayerID.RENAME_LAYER)
	layer_popup.add_separator()
	layer_popup.add_item("Merge down", LayerID.MERGE_DOWN)
	layer_popup.add_item("Merge visible", LayerID.MERGE_VISIBLE)
	layer_popup.add_item("Merge all", LayerID.MERGE_ALL)
	layer_popup.add_separator()
	layer_popup.add_item("Show all layers", LayerID.SHOW_ALL_LAYER)
	layer_popup.add_item("Hide all layers", LayerID.HIDE_ALL_LAYER)
	layer_popup.add_separator("", 100)
	layer_popup.add_item("Layer active go up", LayerID.LAYER_ACTIVE_GO_UP)
	layer_popup.add_item("Layer active go down", LayerID.LAYER_ACTIVE_GO_DOWN)
	
	var palette_popup : PopupMenu = palette_menu.get_popup()
	palette_popup.add_item("Reset To Default Preset", PaletteID.RESET)
	palette_popup.add_item("Sort Color", PaletteID.SORT_COLOR)
	palette_popup.add_item("Delete Unused Color", PaletteID.DELETE_UNUSED)
	palette_popup.add_item("Delete Selected Color", PaletteID.DELETE_SELECTED_COLOR)
	palette_popup.add_item("Clean Invisible Color", PaletteID.CLEAN_INVISIBLE_COLOR)
	palette_popup.add_separator("", 100)
	palette_popup.add_item("Load and replace...", PaletteID.LOAD_AND_REPLACE)
	palette_popup.add_item("Load and merge...", PaletteID.LOAD_AND_MERGE)
	palette_popup.add_item("Save As...", PaletteID.SAVE)
	
	var animation_popup : PopupMenu = animation_menu.get_popup()
	animation_popup.add_item("Play/Pause", AnimationID.PLAY_PAUSE)
	animation_popup.add_item("Skip to front", AnimationID.SKIP_TO_FRONT)
	animation_popup.add_item("Step backward", AnimationID.STEP_BACKWARD)
	animation_popup.add_item("Step forward", AnimationID.STEP_FORWARD)
	animation_popup.add_item("Skip to end", AnimationID.SKIP_TO_END)
	animation_popup.add_separator("", 100)
	animation_popup.add_check_item("Loop animation playback", AnimationID.TOGGLE_LOOP)
	animation_popup.add_check_item("Show onion skinning", AnimationID.TOGGLE_ONION_SKINNING)
	animation_popup.add_separator("", 100)
	animation_popup.add_item("Insert frame to right", AnimationID.INSERT_FRAME_RIGHT)
	animation_popup.add_item("Insert frame to left", AnimationID.INSERT_FRAME_LEFT)
	animation_popup.add_separator("", 100)
	animation_popup.add_item("Duplicate frame", AnimationID.DUPLICATE_FRAME)
	animation_popup.add_item("Duplicate frame linked", AnimationID.DUPLICATE_FRAME_LINKED)
	animation_popup.add_item("Convert frame linked to unique", AnimationID.CONVERT_FRAME_LINKED_TO_UNIQUE)
	animation_popup.add_separator("", 100)
	animation_popup.add_item("Right shift frame", AnimationID.MOVE_FRAME_TO_RIGHT)
	animation_popup.add_item("Left shift frame", AnimationID.MOVE_FRAME_TO_LEFT)
	animation_popup.add_item("Use frame in timeline", AnimationID.MOVE_FRAME_TO_TIMELINE)
	animation_popup.add_item("Remove frame from timeline", AnimationID.MOVE_FRAME_TO_DRAFT)
	animation_popup.add_separator("", 100)
	animation_popup.add_item("Create draft frame", AnimationID.CREATE_DRAFT_FRAME)
	animation_popup.add_item("Delete draft frame", AnimationID.DELETE_DRAFT_FRAME)
	
	var view_popup : PopupMenu = view_menu.get_popup()
	view_popup.add_item("Rotate canvas 90", ViewID.ROTATE_CANVAS_90)
	view_popup.add_item("Rotate canvas -90", ViewID.ROTATE_CANVAS_MIN_90)
	view_popup.add_item("Flip canvas horizontal", ViewID.FLIP_CANVAS_HORIZONTAL)
	view_popup.add_item("Flip canvas vertical", ViewID.FLIP_CANVAS_VERTICAL)
	view_popup.add_item("Reset canvas transform", ViewID.RESET_CANVAS_TRANSFORM)
	view_popup.add_separator("", 100)
	view_popup.add_item("Background color", ViewID.BACKGROUND_COLOR)
	view_popup.add_separator("", 100)
	view_popup.add_item("New image references...", ViewID.NEW_IMAGE_REFERENCE)
	view_popup.add_separator("", 100)
	view_popup.add_check_item("Edit selection only", ViewID.EDIT_SELECTION_ONLY)
	view_popup.add_separator("", 100)
	view_popup.add_check_item("Show virtual mouse", ViewID.SHOW_VIRTUAL_MOUSE)
	view_popup.add_check_item("Show grid", ViewID.SHOW_GRID)
	view_popup.add_check_item("Show vertical mirror guid", ViewID.SHOW_VERTICAL_MIRROR_GUIDE)
	view_popup.add_check_item("Show horizontal mirror guid", ViewID.SHOW_HORIZONTAL_MIRROR_GUIDE)
	view_popup.add_check_item("Show tile", ViewID.SHOW_TILE)
	view_popup.add_separator("", 100)
	view_popup.add_check_item("Show preview", ViewID.SHOW_PREVIEW)
	view_popup.add_check_item("Show animation timeline", ViewID.SHOW_ANIMATION_TIMELINE)
	view_popup.add_separator("", 100)
	view_popup.add_check_item("Tint black to layer", ViewID.TOGGLE_TINT_SELECTED_LAYER)
	view_popup.add_check_item("Filter grayscale", ViewID.FILTER_GRAYSCALE)
	view_popup.add_separator("", 100)
	view_popup.add_check_item("Show info", ViewID.SHOW_INFO)
	
	background_color_submenu = PopupMenu.new()
	background_color_submenu.set_name("background_color_submenu")
	_update_background_color_submenu()
	background_color_submenu.id_pressed.connect(func(id):
			PixelPen.current_project.background_color = id
			_update_background_color_submenu()
			PixelPen.project_saved.emit(false)
			)
	view_popup.add_child(background_color_submenu)
	view_popup.set_item_submenu(view_popup.get_item_index(ViewID.BACKGROUND_COLOR), "background_color_submenu")
	
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_PREVIEW), preview_node.visible)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.TOGGLE_TINT_SELECTED_LAYER), canvas.silhouette)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.FILTER_GRAYSCALE), canvas.show_view_grayscale)
	view_popup.set_item_checked(view_popup.get_item_index(ViewID.SHOW_INFO), debug_label.visible)


func _set_shorcut():
	var pixelpen_popup := pixel_pen_menu.get_popup()
	pixelpen_popup.set_item_shortcut(pixelpen_popup.get_item_index(PixelPenID.QUIT), shorcut.quit_editor)
	
	var file_popup := file_menu.get_popup()
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.NEW), shorcut.new_project)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.OPEN), shorcut.open_project)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.SAVE), shorcut.save)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.SAVE_AS), shorcut.save_as)
	file_popup.set_item_shortcut(file_popup.get_item_index(FileID.QUICK_EXPORT), shorcut.quick_export)
	
	var edit_popup := edit_menu.get_popup()
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.UNDO), shorcut.undo)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.REDO), shorcut.redo)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.INVERSE_SELECTION), shorcut.tool_inverse_selection)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.CLEAR_SELECTION), shorcut.tool_remove_selection)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.DELETE_ON_SELECTION), shorcut.tool_delete_selected)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.COPY), shorcut.copy)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.CUT), shorcut.cut)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.PASTE), shorcut.paste)
	edit_popup.set_item_shortcut(edit_popup.get_item_index(EditID.SWITCH_LAST_TOOLBOX), shorcut.prev_toolbox)
	
	var layer_popup := layer_menu.get_popup()
	layer_popup.set_item_shortcut(layer_popup.get_item_index(LayerID.LAYER_ACTIVE_GO_UP), shorcut.arrow_up_variant)
	layer_popup.set_item_shortcut(layer_popup.get_item_index(LayerID.LAYER_ACTIVE_GO_DOWN), shorcut.arrow_down_variant)
	
	var animation_popup := animation_menu.get_popup()
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.PLAY_PAUSE), shorcut.animation_play_pause)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.STEP_BACKWARD), shorcut.arrow_left_variant)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.STEP_FORWARD), shorcut.arrow_right_variant)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.MOVE_FRAME_TO_LEFT), shorcut.animation_shift_frame_left)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.MOVE_FRAME_TO_RIGHT), shorcut.animation_shift_frame_right)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.MOVE_FRAME_TO_TIMELINE), shorcut.animation_move_frame_to_timeline)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.MOVE_FRAME_TO_DRAFT), shorcut.animation_move_frame_to_draft)
	animation_popup.set_item_shortcut(animation_popup.get_item_index(AnimationID.TOGGLE_ONION_SKINNING), shorcut.animation_onion_skinning)
	
	var view_popup := view_menu.get_popup()
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.SHOW_GRID), shorcut.view_show_grid)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.ROTATE_CANVAS_90), shorcut.rotate_canvas_90)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.ROTATE_CANVAS_MIN_90), shorcut.rotate_canvas_min90)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.FLIP_CANVAS_HORIZONTAL), shorcut.flip_canvas_horizontal)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.FLIP_CANVAS_VERTICAL), shorcut.flip_canvas_vertical)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.RESET_CANVAS_TRANSFORM), shorcut.reset_canvas_transform)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.TOGGLE_TINT_SELECTED_LAYER), shorcut.toggle_tint_layer)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.EDIT_SELECTION_ONLY), shorcut.toggle_edit_selection_only)
	view_popup.set_item_shortcut(view_popup.get_item_index(ViewID.SHOW_TILE), shorcut.view_show_tile)


func connect_signal():
	pixel_pen_menu.get_popup().id_pressed.connect(_on_pixelpen_popup_pressed)
	file_menu.get_popup().id_pressed.connect(_on_file_popup_pressed)
	edit_menu.get_popup().id_pressed.connect(_on_edit_popup_pressed)
	layer_menu.get_popup().id_pressed.connect(_on_layer_popup_pressed)
	layer_menu.get_popup().about_to_popup.connect(_on_layer_about_to_popup)
	palette_menu.get_popup().id_pressed.connect(_on_palette_popup_pressed)
	animation_menu.get_popup().id_pressed.connect(_on_animation_popup_pressed)
	view_menu.get_popup().id_pressed.connect(_on_view_popup_pressed)
	PixelPen.tool_changed.connect(_on_tool_changed)
	PixelPen.request_new_project.connect(_new)
	PixelPen.request_open_project.connect(_open)
	PixelPen.request_import_image.connect(func ():
			_on_file_popup_pressed(FileID.IMPORT)
			)
	PixelPen.request_save_project.connect(_save)
	PixelPen.request_save_as_project.connect(_save_as)
	PixelPen.project_file_changed.connect(_on_project_file_changed)
	PixelPen.project_saved.connect(_on_project_saved)
	canvas.selection_tool_hint.texture_changed.connect(_on_selection_texture_changed)


func _on_project_saved(is_saved : bool):
	if PixelPen.current_project != null:
		PixelPen.current_project.is_saved = is_saved
	_update_title()


func _new():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_new_project_dialog = new_project_dialog.instantiate()
	_new_project_dialog.confirmed.connect(func():
			_new_project_dialog.hide()
			PixelPen.dialog_visibled.emit(false)
			PixelPen.project_file_changed.emit()
			_new_project_dialog.queue_free()
			)
	_new_project_dialog.canceled.connect(func():
			_new_project_dialog.hide()
			PixelPen.dialog_visibled.emit(false)
			_new_project_dialog.queue_free()
			)
	add_child(_new_project_dialog)
	PixelPen.dialog_visibled.emit(true)
	_new_project_dialog.popup_centered()


func _open():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.filters = ["*.res"]
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.get_directory()
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			PixelPen.load_project(file)
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
		
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)


func _save():
	if PixelPen.current_project == null:
		return
	if (PixelPen.current_project as PixelPenProject).file_path == "":
		_show_save_as_dialog(
				func (file_path):
					if file_path != "":
						_save_project(file_path)
		)
	else:
		_save_project(PixelPen.current_project.file_path)


func _save_as():
	if PixelPen.current_project == null:
		return
	_show_save_as_dialog(func (file_path):
			if file_path != "":
				_save_project(file_path)
			)


func _save_project(file_path : String):
	var prev_path = PixelPen.current_project.file_path
	var prev_name = PixelPen.current_project.project_name
	PixelPen.current_project.file_path = file_path
	PixelPen.current_project.project_name = file_path.get_file().get_basename()
	var err = ResourceSaver.save(PixelPen.current_project, file_path)
	if err == OK:
		PixelPen.userconfig.insert_recent_projects(PixelPen.current_project.file_path)
		_update_recent_submenu()
		PixelPen.current_project.is_saved = true
		PixelPen.project_saved.emit(true)
	else:
		PixelPen.current_project.file_path = prev_path
		PixelPen.current_project.project_name = prev_name


func _show_save_as_dialog(callback : Callable = Callable()):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".res")
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.filters = ["*.res"]
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.get_directory()
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			callback.call(file)
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			callback.call("")
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)


func _close_project():
	PixelPen.current_project = null
	PixelPen.save_cache_project_config()
	PixelPen.project_file_changed.emit()


func _on_selection_texture_changed():
	var disable = canvas.selection_tool_hint.texture == null
	
	var edit_popup = edit_menu.get_popup()
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.INVERSE_SELECTION), disable)
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.CLEAR_SELECTION), disable)
	edit_popup.set_item_disabled(edit_popup.get_item_index(EditID.DELETE_ON_SELECTION), disable)


func _on_tool_changed(grup : int, type: int, _grab_active : bool):
	if grup == PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBAR:
		match type:
			PixelPen.ToolBar.TOOLBAR_UNDO:
				_on_edit_popup_pressed(EditID.UNDO)
				get_viewport().set_input_as_handled()

			PixelPen.ToolBar.TOOLBAR_REDO:
				_on_edit_popup_pressed(EditID.REDO)
				get_viewport().set_input_as_handled()

			PixelPen.ToolBar.TOOLBAR_SHOW_GRID:
				_on_view_popup_pressed(ViewID.SHOW_GRID)
				get_viewport().set_input_as_handled()

			PixelPen.ToolBar.TOOLBAR_TOGGLE_TINT_BLACK_LAYER:
				_on_view_popup_pressed(ViewID.TOGGLE_TINT_SELECTED_LAYER)
				get_viewport().set_input_as_handled()

			PixelPen.ToolBar.TOOLBAR_SAVE:
				_on_file_popup_pressed(FileID.SAVE)
				get_viewport().set_input_as_handled()


func _on_pixelpen_popup_pressed(id : int):
	if id == PixelPenID.QUIT:
		if Engine.is_editor_hint():
			get_window().hide()
			get_window().queue_free()
		else:
			get_tree().quit()


func _on_file_popup_pressed(id : int):
	if id == FileID.NEW:
		_new()
		
	elif id == FileID.OPEN:
		_open()
	
	elif id == FileID.SAVE:
		_save()
	
	elif id == FileID.SAVE_AS:
		_save_as()
		
	elif id == FileID.IMPORT:
		var callback_no_project = func(file : String):
			if file != "":
				var window : ConfirmationDialog = import_window.instantiate()
				add_child(window)
				window.confirmed.connect(func():
						var image : Image = window.get_image() 
						var current_project = PixelPenProject.new()
						current_project.initialized(
								image.get_size(), "Untitled", 16, "", false
								)
						PixelPen.current_project = current_project
						var layer_uid : Vector3i = PixelPen.current_project.import_image(image, file)
						PixelPen.current_project.project_name = PixelPen.current_project.get_index_image(layer_uid).label
						window.closed.emit()
						window.queue_free()
						PixelPen.project_file_changed.emit()
						)
				window.canceled.connect(func():
						window.closed.emit()
						window.queue_free()
						)
				window.show_file(file)
				window.popup_centered()
				PixelPen.dialog_visibled.emit(true)
				await window.closed
				PixelPen.dialog_visibled.emit(false)
		var callback = func(files : PackedStringArray):
			if not files.is_empty():
				(PixelPen.current_project as PixelPenProject).create_undo_layer_and_palette("Add layer", func ():
						PixelPen.layer_items_changed.emit()
						PixelPen.project_saved.emit(false)
						PixelPen.palette_changed.emit()
						)
				for i in range(files.size()):
					var window : ConfirmationDialog = import_window.instantiate()
					add_child(window)
					window.confirmed.connect(func():
							(PixelPen.current_project as PixelPenProject).import_image(window.get_image() , files[i])
							window.closed.emit()
							window.queue_free()
							)
					window.canceled.connect(func():
							window.closed.emit()
							window.queue_free()
							)
					window.show_file(files[i])
					window.popup_centered()
					await window.closed
				(PixelPen.current_project as PixelPenProject).create_redo_layer_and_palette(func ():
						PixelPen.layer_items_changed.emit()
						PixelPen.project_saved.emit(false)
						PixelPen.palette_changed.emit()
						)
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.palette_changed.emit()
		if PixelPen.current_project == null:
			get_image_file(callback_no_project, FileDialog.FILE_MODE_OPEN_FILE)
		else:
			get_image_file(callback, FileDialog.FILE_MODE_OPEN_FILES)
	
	elif id == FileID.QUICK_EXPORT:
		var file : String = PixelPen.current_project.last_export_file_path
		var ext : String = file.get_extension().to_lower()
		if ext == "jpg" or ext == "jpeg":
			(PixelPen.current_project as PixelPenProject).export_jpg_image(file)
		elif ext == "png":
			(PixelPen.current_project as PixelPenProject).export_png_image(file)
		elif ext == "webp":
			(PixelPen.current_project as PixelPenProject).export_webp_image(file)
		PixelPen.project_saved.emit(false)
		
		##TODO: remove below on export debug
		if get_window().has_method("scan"):
			get_window().scan()

	elif id == FileID.CLOSE:
		_close_project()


func _on_edit_popup_pressed(id : int):
	match id:
		EditID.UNDO:
			PixelPen.current_project.undo()
		
		EditID.REDO:
			PixelPen.current_project.redo()

		EditID.INVERSE_SELECTION:
			PixelPen.tool_changed.emit(
					PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
					PixelPen.ToolBoxSelection.TOOL_SELECTION_INVERSE, false)
	
		EditID.CLEAR_SELECTION:
			PixelPen.tool_changed.emit(
					PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
					PixelPen.ToolBoxSelection.TOOL_SELECTION_REMOVE, false)

		EditID.DELETE_ON_SELECTION:
			PixelPen.tool_changed.emit(
					PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL,
					PixelPen.ToolBoxSelection.TOOL_SELECTION_DELETE_SELECTED, false)
		
		EditID.COPY:
			if canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE:
				canvas.canvas_paint.tool._show_guid = true
			else:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MOVE, true)
			PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, PixelPen.ToolBoxMove.TOOL_MOVE_COPY, false)
		
		EditID.CUT:
			if canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE:
				canvas.canvas_paint.tool._show_guid = true
			else:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_MOVE, true)
			PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX_SUB_TOOL, PixelPen.ToolBoxMove.TOOL_MOVE_CUT, false)
		
		EditID.PASTE:
			if canvas.canvas_paint.tool.tool_type == PixelPen.ToolBox.TOOL_MOVE and canvas.canvas_paint.tool.mode != MoveTool.Mode.UNKNOWN:
				canvas.canvas_paint.tool._on_move_commit()
		
		EditID.CREATE_BRUSH:
			if canvas.selection_tool_hint.texture == null:
				PixelPen.userconfig.make_brush_from_project(null)
			else:
				var mask = canvas.selection_tool_hint.texture.get_image()
				PixelPen.userconfig.make_brush_from_project(MaskSelection.get_image_no_margin(mask))
			if subtool_dock.current_toolbox == PixelPen.ToolBox.TOOL_BRUSH:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_BRUSH, true)
		
		EditID.RESET_BRUSH:
			PixelPen.current_project.reset_brush_to_default()
			if subtool_dock.current_toolbox == PixelPen.ToolBox.TOOL_BRUSH:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_BRUSH, true)
		
		EditID.CREATE_STAMP:
			if canvas.selection_tool_hint.texture == null:
				PixelPen.userconfig.make_stamp_from_project(null)
			else:
				var mask = canvas.selection_tool_hint.texture.get_image()
				PixelPen.userconfig.make_stamp_from_project(MaskSelection.get_image_no_margin(mask))
			if subtool_dock.current_toolbox == PixelPen.ToolBox.TOOL_STAMP:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_STAMP, true)
		
		EditID.RESET_STAMP:
			PixelPen.current_project.reset_stamp_to_default()
			if subtool_dock.current_toolbox == PixelPen.ToolBox.TOOL_STAMP:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, PixelPen.ToolBox.TOOL_STAMP, true)
		
		EditID.SWITCH_LAST_TOOLBOX:
			if PixelPen.current_project == null:
				return
			if toolbox_dock.prev_toolbox != PixelPen.ToolBox.TOOL_UNKNOWN:
				PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_TOOLBOX, toolbox_dock.prev_toolbox, true)
		
		EditID.CANVAS_SIZE:
			_open_canvas_size_window()


func _on_layer_popup_pressed(id : int):
	match id as LayerID:
		LayerID.ADD_LAYER:
			layers_tool._on_add_pressed()
		
		LayerID.DUPLICATE_LAYER:
			layers_tool._on_duplicate_layer()
		
		LayerID.COPY_LAYER:
			layers_tool._on_copy_layer()
		
		LayerID.CUT_LAYER:
			layers_tool._on_cut_layer()
		
		LayerID.DELETE_LAYER:
			layers_tool._on_trash_pressed()
		
		LayerID.DUPLICATE_SELECTION:
			layers_tool._on_duplicate_selection()
		
		LayerID.PASTE:
			layers_tool._on_paste()
		
		LayerID.RENAME_LAYER:
			var uid = (PixelPen.current_project as PixelPenProject).active_layer
			if uid != null:
				layers_tool._on_layer_properties(uid.layer_uid)
		
		LayerID.MERGE_DOWN:
			layers_tool._on_merge_down()
		
		LayerID.MERGE_VISIBLE:
			layers_tool._on_merge_visible()
		
		LayerID.MERGE_ALL:
			layers_tool._on_merge_all()
		
		LayerID.SHOW_ALL_LAYER:
			layers_tool._on_show_all()
		
		LayerID.HIDE_ALL_LAYER:
			layers_tool._on_hide_all()
		
		LayerID.LAYER_ACTIVE_GO_UP:
			if MoveTool.mode == MoveTool.Mode.UNKNOWN or PixelPen.current_project.multilayer_selected.is_empty():
				if not PixelPen.current_project.active_layer_is_valid():
					if PixelPen.current_project.active_frame.layers.size() > 0:
						PixelPen.current_project.active_layer_uid = PixelPen.current_project.active_frame.layers[0].layer_uid
				var index := (PixelPen.current_project as PixelPenProject).get_image_index(PixelPen.current_project.active_layer_uid)
				if index != -1:
					index += 1
					if PixelPen.current_project.active_frame.layers.size() <= index:
						index = 0
					PixelPen.current_project.multilayer_selected.clear()
					PixelPen.current_project.active_layer_uid = PixelPen.current_project.active_frame.layers[index].layer_uid
					PixelPen.layer_active_changed.emit(PixelPen.current_project.active_layer_uid)
			
		LayerID.LAYER_ACTIVE_GO_DOWN:
			if MoveTool.mode == MoveTool.Mode.UNKNOWN or PixelPen.current_project.multilayer_selected.is_empty():
				if not PixelPen.current_project.active_layer_is_valid():
					if PixelPen.current_project.active_frame.layers.size() > 0:
						PixelPen.current_project.active_layer_uid = PixelPen.current_project.active_frame.layers[0].layer_uid
				var index := (PixelPen.current_project as PixelPenProject).get_image_index(PixelPen.current_project.active_layer_uid)
				if index != -1:
					PixelPen.current_project.multilayer_selected.clear()
					PixelPen.current_project.active_layer_uid = PixelPen.current_project.active_frame.layers[index - 1].layer_uid
					PixelPen.layer_active_changed.emit(PixelPen.current_project.active_layer_uid)


func _on_layer_about_to_popup():
	var disable = (PixelPen.current_project as PixelPenProject).active_layer == null
	var selection = canvas.selection_tool_hint.texture == null
	var edit_mode_sample : bool = PixelPen.current_project.use_sample
	var multiselect : bool = not PixelPen.current_project.multilayer_selected.is_empty()
	var popup := layer_menu.get_popup()
	popup.set_item_disabled(popup.get_item_index(LayerID.ADD_LAYER), edit_mode_sample)
	
	popup.set_item_disabled(popup.get_item_index(LayerID.DELETE_LAYER), disable or edit_mode_sample)
	popup.set_item_disabled(popup.get_item_index(LayerID.DUPLICATE_LAYER), disable or edit_mode_sample or multiselect)
	
	popup.set_item_disabled(popup.get_item_index(LayerID.COPY_LAYER), disable or edit_mode_sample or multiselect)
	popup.set_item_disabled(popup.get_item_index(LayerID.CUT_LAYER), disable or edit_mode_sample or multiselect)
	
	popup.set_item_disabled(popup.get_item_index(LayerID.DUPLICATE_SELECTION), disable or selection or edit_mode_sample or multiselect)
	
	popup.set_item_disabled(popup.get_item_index(LayerID.PASTE), (PixelPen.current_project as PixelPenProject).cache_copied_colormap == null or edit_mode_sample or multiselect)
	
	popup.set_item_disabled(popup.get_item_index(LayerID.RENAME_LAYER), disable or multiselect)
	
	popup.set_item_disabled(popup.get_item_index(LayerID.MERGE_DOWN), disable or edit_mode_sample)
	popup.set_item_disabled(popup.get_item_index(LayerID.MERGE_VISIBLE), edit_mode_sample)
	popup.set_item_disabled(popup.get_item_index(LayerID.MERGE_ALL), edit_mode_sample)


func _on_palette_popup_pressed(id : int):
	if id == PaletteID.RESET:
		(PixelPen.current_project as PixelPenProject).create_undo_palette_all("Palette", func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.current_project.unbreak_history()
				)
		
		(PixelPen.current_project as PixelPenProject).palette.set_color_index_preset()
		(PixelPen.current_project as PixelPenProject).palette.grid_sync_to_palette()
		
		(PixelPen.current_project as PixelPenProject).create_redo_palette_all(func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.current_project.break_history()
				)
		PixelPen.palette_changed.emit()
		PixelPen.project_saved.emit(false)
		PixelPen.current_project.break_history()
		
	elif id == PaletteID.SORT_COLOR:
		var new_grid_palette : PackedInt32Array = (PixelPen.current_project as PixelPenProject).sort_palette()
		if new_grid_palette.size() > 0:
			(PixelPen.current_project as PixelPenProject).create_undo_palette_gui("Palette", func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				)
				
			(PixelPen.current_project as PixelPenProject).palette.grid_color_index = new_grid_palette
			
			(PixelPen.current_project as PixelPenProject).create_redo_palette_gui(func():
					PixelPen.palette_changed.emit()
					PixelPen.project_saved.emit(false)
					)
			PixelPen.palette_changed.emit()
			PixelPen.project_saved.emit(false)
		
	elif id == PaletteID.DELETE_UNUSED:
		(PixelPen.current_project as PixelPenProject).create_undo_palette("Palette", func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		(PixelPen.current_project as PixelPenProject).delete_unused_color_palette()
		(PixelPen.current_project as PixelPenProject).create_redo_palette(func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				)
		PixelPen.palette_changed.emit()
		PixelPen.project_saved.emit(false)
	
	elif id == PaletteID.DELETE_SELECTED_COLOR:
		(PixelPen.current_project as PixelPenProject).create_undo_palette_all("Palette", func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.current_project.unbreak_history()
				)
		(PixelPen.current_project as PixelPenProject).delete_color(Tool._index_color)
		(PixelPen.current_project as PixelPenProject).create_redo_palette_all(func():
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.current_project.break_history()
				)
		PixelPen.palette_changed.emit()
		PixelPen.project_saved.emit(false)
		PixelPen.current_project.break_history()
	
	elif id == PaletteID.CLEAN_INVISIBLE_COLOR:
		PixelPen.current_project.clean_invisible_color()
		PixelPen.palette_changed.emit()
		PixelPen.project_saved.emit(false)
		PixelPen.current_project.undo_redo.clear_history()
	
	elif id == PaletteID.LOAD_AND_REPLACE:
		var callback = func(file):
			if file != "":
				(PixelPen.current_project as PixelPenProject).create_undo_palette_all("Load palette", func():
						PixelPen.palette_changed.emit()
						PixelPen.project_saved.emit(false)
						PixelPen.current_project.unbreak_history()
						)
				
				(PixelPen.current_project as PixelPenProject).palette.load_image(file)
				(PixelPen.current_project as PixelPenProject).palette.grid_sync_to_palette()
				
				(PixelPen.current_project as PixelPenProject).create_redo_palette_all(func():
						PixelPen.palette_changed.emit()
						PixelPen.project_saved.emit(false)
						PixelPen.current_project.break_history()
						)
				
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.current_project.break_history()
		get_image_file(callback, FileDialog.FILE_MODE_OPEN_FILE)
		
	elif id == PaletteID.LOAD_AND_MERGE:
		var callback = func(file):
			if file != "":
				(PixelPen.current_project as PixelPenProject).create_undo_palette_all("Load palette", func():
						PixelPen.palette_changed.emit()
						PixelPen.project_saved.emit(false)
						PixelPen.current_project.unbreak_history()
						)
				
				(PixelPen.current_project as PixelPenProject).palette.load_image(file, true)
				(PixelPen.current_project as PixelPenProject).palette.grid_sync_to_palette()
				
				(PixelPen.current_project as PixelPenProject).create_redo_palette_all(func():
						PixelPen.palette_changed.emit()
						PixelPen.project_saved.emit(false)
						PixelPen.current_project.break_history()
						)
				
				PixelPen.palette_changed.emit()
				PixelPen.project_saved.emit(false)
				PixelPen.current_project.break_history()
		get_image_file(callback, FileDialog.FILE_MODE_OPEN_FILE)
		
	elif id == PaletteID.SAVE:
		var callback = func(file):
			if file != "":
				(PixelPen.current_project as PixelPenProject).palette.save_image(file)
		get_image_file(callback, FileDialog.FILE_MODE_SAVE_FILE)


func _on_animation_popup_pressed(id : int):
	var project : PixelPenProject = PixelPen.current_project as PixelPenProject
	if id == AnimationID.PLAY_PAUSE:
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_ANIMATION, PixelPen.ToolAnimation.TOOL_ANIMATION_PLAY_PAUSE, false)
	
	elif id == AnimationID.SKIP_TO_FRONT:
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_ANIMATION, PixelPen.ToolAnimation.TOOL_ANIMATION_SKIP_TO_FRONT, false)
	
	elif id == AnimationID.SKIP_TO_END:
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_ANIMATION, PixelPen.ToolAnimation.TOOL_ANIMATION_SKIP_TO_END, false)
	
	elif id == AnimationID.STEP_BACKWARD:
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_ANIMATION, PixelPen.ToolAnimation.TOOL_ANIMATION_STEP_BACKWARD, false)
	
	elif id == AnimationID.STEP_FORWARD:
		PixelPen.tool_changed.emit(PixelPen.ToolBoxGrup.TOOL_GRUP_ANIMATION, PixelPen.ToolAnimation.TOOL_ANIMATION_STEP_FORWARD, false)
	
	elif id == AnimationID.TOGGLE_LOOP:
		PixelPen.current_project.animation_loop = not PixelPen.current_project.animation_loop
		var popup := animation_menu.get_popup()
		var index = popup.get_item_index(id)
		popup.set_item_checked(index, PixelPen.current_project.animation_loop)
	
	elif id == AnimationID.TOGGLE_ONION_SKINNING:
		PixelPen.current_project.onion_skinning = not PixelPen.current_project.onion_skinning
		var popup := animation_menu.get_popup()
		var index = popup.get_item_index(id)
		popup.set_item_checked(index, PixelPen.current_project.onion_skinning)
		PixelPen.layer_items_changed.emit()
	
	elif id == AnimationID.INSERT_FRAME_LEFT:
		var cell : AnimationCell = AnimationCell.create(PixelPen.current_project.get_uid())
		var frame = Frame.create(PixelPen.current_project.get_uid())
		project.pool_frames.push_back(frame)
		cell.frame = frame
		var cell_index : int = maxi(0, project.animation_frame_index)
		project.animation_timeline.insert(cell_index, cell)
		project.animation_frame_index = cell_index
		project.canvas_pool_frame_uid = project.animation_timeline[cell_index].frame.frame_uid
		project.add_layer()
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
		
	elif id == AnimationID.INSERT_FRAME_RIGHT:
		var cell : AnimationCell = AnimationCell.create(PixelPen.current_project.get_uid())
		var frame = Frame.create(PixelPen.current_project.get_uid())
		project.pool_frames.push_back(frame)
		cell.frame = frame
		var cell_index : int = maxi(0, project.animation_frame_index)
		if project.animation_timeline.size() > 0:
			cell_index += 1
		project.animation_timeline.insert(cell_index, cell)
		project.animation_frame_index = cell_index
		project.canvas_pool_frame_uid = project.animation_timeline[cell_index].frame.frame_uid
		project.add_layer()
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.DUPLICATE_FRAME:
		if project.animation_frame_index != -1:
			var cell_index : int = project.animation_frame_index
			if cell_index != -1:
				var src_cell = project.animation_timeline[cell_index]
				var cell : AnimationCell = AnimationCell.create(PixelPen.current_project.get_uid())
				var frame : Frame = Frame.create(PixelPen.current_project.get_uid())
				frame.layers = src_cell.frame.get_layer_duplicate()
				cell.frame = frame
				project.pool_frames.push_back(cell.frame)
				project.animation_timeline.insert(cell_index + 1, cell)
				project.animation_frame_index = cell_index + 1
				project.canvas_pool_frame_uid = project.animation_timeline[cell_index + 1].frame.frame_uid
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.DUPLICATE_FRAME_LINKED:
		if project.animation_frame_index != -1:
			var cell_index : int = project.animation_frame_index
			if cell_index != -1:
				var cell : AnimationCell = project.animation_timeline[cell_index].duplicate()
				cell.cell_uid = PixelPen.current_project.get_uid()
				project.animation_timeline.insert(cell_index + 1, cell)
				project.animation_frame_index = cell_index + 1
				project.canvas_pool_frame_uid = project.animation_timeline[cell_index + 1].frame.frame_uid
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.CONVERT_FRAME_LINKED_TO_UNIQUE:
		if project.animation_frame_index != -1:
			var cell_index : int = project.animation_frame_index
			if cell_index != -1:
				var cell : AnimationCell = project.animation_timeline[cell_index]
				var new_frame : Frame = cell.frame.get_duplicate()
				project.pool_frames.push_back(new_frame)
				cell.frame = new_frame
				project.canvas_pool_frame_uid = cell.frame.frame_uid
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.MOVE_FRAME_TO_LEFT:
		if project.animation_frame_index != -1:
			var cell_index : int = project.animation_frame_index
			var new_index = cell_index - 1
			if cell_index != -1 and new_index >= 0:
				var cell : AnimationCell = project.animation_timeline[cell_index]
				project.animation_timeline.remove_at(cell_index)
				project.animation_timeline.insert(new_index, cell)
				project.animation_frame_index = new_index
				project.canvas_pool_frame_uid = project.animation_timeline[new_index].frame.frame_uid
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.MOVE_FRAME_TO_RIGHT:
		if project.animation_frame_index != -1:
			var cell_index : int = project.animation_frame_index
			var new_index = cell_index + 1
			if cell_index != -1 and new_index != project.animation_timeline.size():
				var cell : AnimationCell = project.animation_timeline[cell_index]
				project.animation_timeline.remove_at(cell_index)
				project.animation_timeline.insert(new_index, cell)
				project.animation_frame_index = new_index
				project.canvas_pool_frame_uid = project.animation_timeline[new_index].frame.frame_uid
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
		
	elif id == AnimationID.MOVE_FRAME_TO_TIMELINE:
		if project.animation_frame_index == -1:
			var cell : AnimationCell = AnimationCell.create(PixelPen.current_project.get_uid()) 
			cell.frame = project.active_frame
			var cell_index : int = project.animation_timeline.size()
			project.animation_timeline.insert(cell_index, cell)
			project.animation_frame_index = cell_index
			project.canvas_pool_frame_uid = project.animation_timeline[cell_index].frame.frame_uid
			PixelPen.layer_items_changed.emit()
			PixelPen.project_saved.emit(false)
		
	elif id == AnimationID.MOVE_FRAME_TO_DRAFT:
		if project.animation_frame_index != -1:
			var cell_index : int = project.animation_frame_index
			if cell_index != -1:
				project.animation_timeline.remove_at(cell_index)
				project.animation_frame_index -= 1
				if project.animation_frame_index == -1:
					project.canvas_pool_frame_uid = project.pool_frames[project.get_animation_draft_pool_index()[0]].frame_uid
				else:
					project.canvas_pool_frame_uid = project.animation_timeline[project.animation_frame_index].frame.frame_uid
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.CREATE_DRAFT_FRAME:
		var frame = Frame.create(PixelPen.current_project.get_uid())
		project.pool_frames.push_back(frame)
		project.animation_frame_index = -1
		project.canvas_pool_frame_uid = project.pool_frames[project.pool_frames.size()-1].frame_uid
		project.add_layer()
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
	
	elif id == AnimationID.DELETE_DRAFT_FRAME:
		if project.animation_frame_index == -1:
			if project.pool_frames.size() > 1 and project.active_frame != null:
				project.pool_frames.erase(project.active_frame)
				PixelPen.current_project.resolve_missing_visible_frame()
				PixelPen.layer_items_changed.emit()
				PixelPen.project_saved.emit(false)


func _on_view_popup_pressed(id : int):
	var popup : PopupMenu = view_menu.get_popup()
	var index = popup.get_item_index(id)
	
	if id == ViewID.SHOW_GRID:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		PixelPen.current_project.show_grid = popup.is_item_checked(index)
		PixelPen.project_saved.emit(false)
	
	elif id == ViewID.SHOW_VIRTUAL_MOUSE:
		canvas.center_virtual_mouse()
		canvas.virtual_mouse = not canvas.virtual_mouse
		popup.set_item_checked(index, canvas.virtual_mouse)
		PixelPen.project_saved.emit(false)
	
	elif id == ViewID.SHOW_VERTICAL_MIRROR_GUIDE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		PixelPen.current_project.show_symetric_vertical = popup.is_item_checked(index)
		PixelPen.project_saved.emit(false)
	
	elif id == ViewID.SHOW_HORIZONTAL_MIRROR_GUIDE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		PixelPen.current_project.show_symetric_horizontal = popup.is_item_checked(index)
		PixelPen.project_saved.emit(false)
	
	elif id == ViewID.ROTATE_CANVAS_90:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.rotate(PI * 0.5)
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	
	elif id == ViewID.ROTATE_CANVAS_MIN_90:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.rotate(PI * -0.5)
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	
	elif id == ViewID.FLIP_CANVAS_HORIZONTAL:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.scale.x *= -1
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	
	elif id == ViewID.FLIP_CANVAS_VERTICAL:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.scale.y *= -1
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	
	elif id == ViewID.RESET_CANVAS_TRANSFORM:
		canvas.camera.force_update_scroll()
		var prev_screen_center = canvas.to_local(canvas.camera.get_screen_center_position())
		
		canvas.scale = Vector2.ONE
		canvas.rotation = 0
		canvas.queue_redraw()
		
		canvas.camera.force_update_scroll()
		canvas.camera.offset -= canvas.to_global(canvas.to_local(canvas.camera.get_screen_center_position()) - prev_screen_center)
	
	elif id == ViewID.NEW_IMAGE_REFERENCE:
		get_image_file(func(files : PackedStringArray):
				for file in files:
					var window = image_reference_window.instantiate()
					window.load_texture(file)
					add_child(window)
					window.popup_centered()
					window.grab_focus()
				,FileDialog.FILE_MODE_OPEN_FILES
				)
	
	elif id == ViewID.EDIT_SELECTION_ONLY:
		if (PixelPen.current_project as PixelPenProject).use_sample:
			(PixelPen.current_project as PixelPenProject).set_mode(0)
		elif canvas.selection_tool_hint.texture != null:
			var mask : Image = MaskSelection.get_image_no_margin(canvas.selection_tool_hint.texture.get_image())
			(PixelPen.current_project as PixelPenProject).set_mode(1, mask)
		popup.set_item_checked(index, (PixelPen.current_project as PixelPenProject).use_sample)
		PixelPen.project_file_changed.emit()
	
	elif id == ViewID.SHOW_TILE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		PixelPen.current_project.show_tile = popup.is_item_checked(index)
		(PixelPen.current_project as PixelPenProject).get_image() # Force to create first cache image for tile
		PixelPen.thumbnail_changed.emit()
		PixelPen.project_saved.emit(false)
	
	elif id == ViewID.SHOW_PREVIEW:
		PixelPen.current_project.show_preview = not PixelPen.current_project.show_preview
		popup.set_item_checked(index, PixelPen.current_project.show_preview)
		preview_node.visible = PixelPen.current_project.show_preview 
		
		var has_dock : bool = layout_node.has_dock(preview_node)
		if has_dock and not PixelPen.current_project.show_preview:
			layout_node.undock(preview_node)
			layout_node.update_layout()
		elif not has_dock and PixelPen.current_project.show_preview:
			layout_node.dock(preview_node, layer_dock, true, 0.35, true)
			layout_node.update_layout()
		PixelPen.project_saved.emit(false)
	
	elif id == ViewID.SHOW_ANIMATION_TIMELINE:
		PixelPen.current_project.show_timeline = not PixelPen.current_project.show_timeline
		popup.set_item_checked(index, PixelPen.current_project.show_timeline)
		animation_panel.visible = PixelPen.current_project.show_timeline
		animation_menu.disabled = not PixelPen.current_project.show_timeline or PixelPen.current_project.use_sample
		
		var has_anim_dock : bool = layout_node.has_dock(animation_panel)
		if has_anim_dock and not PixelPen.current_project.show_timeline:
			layout_node.undock(animation_panel)
			layout_node.update_layout()
		elif not has_anim_dock and PixelPen.current_project.show_timeline:
			layout_node.dock(animation_panel, canvas_dock, false, 0.8, true)
			layout_node.update_layout()
		
		PixelPen.project_saved.emit(false)
		file_menu.get_popup().set_item_disabled(
			file_menu.get_popup().get_item_index(FileID.EXPORT_ANIMATION)
			, not PixelPen.current_project.show_timeline)
	
	elif id == ViewID.TOGGLE_TINT_SELECTED_LAYER:
		var active_layer_uid : Vector3i = (PixelPen.current_project as PixelPenProject).active_layer_uid
		canvas.silhouette = false
		for frame in (PixelPen.current_project as PixelPenProject).pool_frames:
			for layer in frame.layers:
		#for layer in (PixelPen.current_project as PixelPenProject).active_frame.layers:
				layer.silhouette = not layer.silhouette and layer.layer_uid == active_layer_uid
				canvas.silhouette = canvas.silhouette or layer.silhouette
		PixelPen.layer_items_changed.emit()
		PixelPen.project_saved.emit(false)
		popup.set_item_checked(index, canvas.silhouette)
	
	elif id == ViewID.FILTER_GRAYSCALE:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		canvas.show_view_grayscale = popup.is_item_checked(index)
	
	elif id == ViewID.SHOW_INFO:
		popup.set_item_checked(index, not popup.is_item_checked(index))
		debug_label.visible = popup.is_item_checked(index)


func get_image_file(callback : Callable, mode : FileDialog.FileMode = FileDialog.FILE_MODE_OPEN_FILE):
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = mode
	_file_dialog.filters = ["*.png, *.jpg, *.jpeg ; Supported Images"]
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.get_directory()
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			callback.call(file)
			_file_dialog.queue_free()
			)
	_file_dialog.files_selected.connect(func(files):
			_file_dialog.hide()
			callback.call(files)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			if mode == FileDialog.FileMode.FILE_MODE_OPEN_FILES:
				callback.call([])
			else:
				callback.call("")
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()


func _open_canvas_size_window():
	var edit_canvas_window = edit_canvas_size.instantiate()
	edit_canvas_window.canvas_width = PixelPen.current_project.canvas_size.x 
	edit_canvas_window.canvas_height = PixelPen.current_project.canvas_size.y
	edit_canvas_window.checker_size = PixelPen.current_project.checker_size
	edit_canvas_window.custom_action.connect(func(action):
			if action == "on_reset":
				edit_canvas_window.canvas_width = PixelPen.current_project.canvas_size.x 
				edit_canvas_window.canvas_height = PixelPen.current_project.canvas_size.y
				edit_canvas_window.checker_size = PixelPen.current_project.checker_size
			)
	edit_canvas_window.confirmed.connect(func():
			if edit_canvas_window.checker_size != PixelPen.current_project.checker_size:
				PixelPen.current_project.checker_size = edit_canvas_window.checker_size
				canvas.update_background_shader_state()
			var changed : bool = edit_canvas_window.canvas_width != PixelPen.current_project.canvas_size.x 
			changed = changed or edit_canvas_window.canvas_height != PixelPen.current_project.canvas_size.y
			if changed:
				(PixelPen.current_project as PixelPenProject).resize_canvas(
					Vector2i(edit_canvas_window.canvas_width, edit_canvas_window.canvas_height),
					edit_canvas_window.anchor
				)
				PixelPen.project_file_changed.emit()
				PixelPen.project_saved.emit(false)
			edit_canvas_window.queue_free()
			)
	edit_canvas_window.canceled.connect(func():
			edit_canvas_window.queue_free()
			)
	add_child(edit_canvas_window)
	edit_canvas_window.popup_centered()


func _on_export(id : int):
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	
	if id == ExportAsID.JPG:
		_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".jpg")
	elif id == ExportAsID.PNG:
		_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".png")
	elif id == ExportAsID.WEBP:
		_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".webp")
	
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	
	if id == ExportAsID.JPG:
		_file_dialog.filters = ["*.jpg"]
	elif id == ExportAsID.PNG:
		_file_dialog.filters = ["*.png"]
	elif id == ExportAsID.WEBP:
		_file_dialog.filters = ["*.webp"]
		
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.get_directory()
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			if id == ExportAsID.JPG:
				(PixelPen.current_project as PixelPenProject).export_jpg_image(file)
			elif id == ExportAsID.PNG:
				(PixelPen.current_project as PixelPenProject).export_png_image(file)
			elif id == ExportAsID.WEBP:
				(PixelPen.current_project as PixelPenProject).export_webp_image(file)
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)


func _on_export_animation(id : int):
	if id == ExportAnimationID.FRAME:
		_on_export_animation_frames()
	elif id == ExportAnimationID.GIF:
		_on_export_animation_gif()
	elif id == ExportAnimationID.SHEETS:
		var window := export_manager.instantiate()
		window.canceled.connect(func():
			window.hide()
			window.queue_free()
			)
		add_child(window)
		window.popup_centered()


func _on_export_animation_frames():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.get_directory()
	_file_dialog.dir_selected.connect(func(dir : String):
			_file_dialog.hide()
			(PixelPen.current_project as PixelPenProject).export_animation_frame(dir)
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)


func _on_export_animation_gif():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var _file_dialog = FileDialog.new()
	
	_file_dialog.current_file = str((PixelPen.current_project as PixelPenProject).project_name , ".gif")
	
	_file_dialog.use_native_dialog = true
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	
	_file_dialog.filters = ["*.gif"]
		
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.current_dir = PixelPen.get_directory()
	_file_dialog.file_selected.connect(func(file):
			_file_dialog.hide()
			(PixelPen.current_project as PixelPenProject).export_animation_gif(file)
			
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free()
			)
	_file_dialog.canceled.connect(func():
			PixelPen.dialog_visibled.emit(false)
			_file_dialog.queue_free())
	
	add_child(_file_dialog)
	_file_dialog.popup_centered(Vector2i(540, 540))
	_file_dialog.grab_focus()
	PixelPen.dialog_visibled.emit(true)
