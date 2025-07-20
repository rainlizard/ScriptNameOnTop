@tool
extends EditorPlugin

const SCENE_TOP_BAR: PackedScene = preload("res://addons/script-name-on-top/topbar.tscn")
const MAX_RECENT_ITEMS := 10
const COLOR_BUTTONS := Color8(106, 180, 255, 255)
const COLOR_BACKGROUND := Color8(66, 78, 120, 128)

const HIDE_SCRIPTS_PANEL_CONFIG_INFO: Dictionary = {
	"name" = "addons/script_name_on_top/hide_scripts_panel",
	"type" = TYPE_BOOL,
	"hint" = PROPERTY_HINT_NONE,
}

const HIDE_BOTTOM_BAR_CONFIG_INFO: Dictionary = {
	"name" = "addons/script_name_on_top/hide_bottom_bar",
	"type" = TYPE_BOOL,
	"hint" = PROPERTY_HINT_NONE,
}

const SHOW_BOTTOM_BAR_WARNING_CONFIG_INFO: Dictionary = {
	"name" = "addons/script_name_on_top/show_bottom_bar_on_warning",
	"type" = TYPE_BOOL,
	"hint" = PROPERTY_HINT_NONE,
}

const SHOW_BOTTOM_BAR_ERROR_CONFIG_INFO: Dictionary = {
	"name" = "addons/script_name_on_top/show_bottom_bar_on_error",
	"type" = TYPE_BOOL,
	"hint" = PROPERTY_HINT_NONE,
}

var _hide_scripts_panel: bool = false
var _hide_bottom_bar: bool = false
var _show_bottom_bar_on_warning: bool = true
var _show_bottom_bar_on_error: bool = true

var _editor_interface: EditorInterface
var _script_editor: ScriptEditor
var _script_editor_menu: Control
var _the_tree: Tree
var _current_editor: ScriptEditorBase
var _scripts_panel_collapse: PopupMenu
var _scripts_panel: Control

var _recently_opened: Array[String] = []
var _extension_top_bar: MenuButton
var _extension_popup: PopupMenu


func _enter_tree() -> void:
	_set_plugin_settings()
	_get_plugin_settings()
	_init_vars()


func _exit_tree() -> void:
	if not _scripts_panel.visible:
		_scripts_panel_collapse.emit_signal("id_pressed", 14)

	var bottom_bar: Control = _get_bottom_bar()
	if is_instance_valid(bottom_bar):
		bottom_bar.visible = true

	if is_instance_valid(_extension_top_bar):
		_extension_top_bar.queue_free()

	ProjectSettings.save()


func _ready() -> void:
	# Wait until Godot Editor is fully loaded before continuing
	while _script_editor_menu.get_children().size() < 13:
		await get_tree().process_frame

	_add_extension_top_bar()

	# Get script that is initially open
	_build_recent_scripts_list()
	_editing_something_new(_script_editor.get_current_editor())


func _init_vars() -> void:
	_editor_interface = get_editor_interface()
	_script_editor = _editor_interface.get_script_editor()
	_script_editor_menu = _script_editor.get_child(0).get_child(0)
	var scene_tree_dock = _editor_interface.get_base_control().find_children("*", "SceneTreeDock", true, false)[0]
	var scene_tree_editor = scene_tree_dock.find_children("*", "SceneTreeEditor", true, false)[0]
	_the_tree = scene_tree_editor.get_child(0)
	_scripts_panel = _script_editor.get_child(0).get_child(1).get_child(0)
	_scripts_panel_collapse = _script_editor_menu.get_child(0).get_popup()


func _add_extension_top_bar() -> void:
	# Make everything in the top bar not expand, while the extension_top_bar will expand
	for i in _script_editor_menu.get_children():
		i.size_flags_horizontal = 0

	_extension_top_bar = SCENE_TOP_BAR.instantiate()
	_script_editor_menu.add_child(_extension_top_bar)
	_script_editor_menu.move_child(_extension_top_bar, -8)

	_extension_popup = _extension_top_bar.get_popup()

	_extension_top_bar.pressed.connect(_build_recent_scripts_list)
	_extension_popup.id_pressed.connect(_on_recent_submenu_pressed)
	_extension_popup.window_input.connect(_on_recent_submenu_window_input)


func _process(_delta: float) -> void:
	# This is better than "editor_script_changed" signal since it includes when you edit other files such as .cfg
	if _current_editor != _script_editor.get_current_editor():
		_current_editor = _script_editor.get_current_editor()
		_editing_something_new(_current_editor)

	_tree_recursive_highlight(_the_tree.get_root())

	# Ideally, we'd use ProjectSettings.settings_changed signal
	# but it's only available for v4.2 and up
	# so we retrieve and update plugin settings on lifecycle
	_get_plugin_settings()
	_toggle_scripts_panel()
	_toggle_bottom_bar()


func _build_recent_scripts_list() -> void:
	_extension_popup.clear()
	for i in _recently_opened.size():
		var filepath: String = _recently_opened[i]
		_extension_popup.add_item(filepath)

	# Don't bother opening an empty menu
	if _recently_opened.size() == 0:
		_extension_popup.visible = false


func _add_recent_script_to_array(recent_string: String) -> void:
	var find_existing: int = _recently_opened.find(recent_string)
	if find_existing == -1:
		_recently_opened.push_front(recent_string)
		if _recently_opened.size() > MAX_RECENT_ITEMS:
			_recently_opened.pop_back()
	else:
		_recently_opened.push_front(_recently_opened.pop_at(find_existing))


func _toggle_scripts_panel() -> void:
	# If hide option is enabled, panel should not be visible or viceversa
	if _hide_scripts_panel == _scripts_panel.visible:
		_scripts_panel_collapse.emit_signal("id_pressed", 14)


func _toggle_bottom_bar() -> void:
	var bottom_bar: Control = _get_bottom_bar()
	if not is_instance_valid(bottom_bar): return

	bottom_bar.visible = not _hide_bottom_bar

	# This setting allows for overriding _hide_bottom_bar config

	# Only when er	rors are present in the editor
	if _show_bottom_bar_on_error:
		var btn_errors: Button = bottom_bar.get_child(2)
		if btn_errors.visible == true:
			bottom_bar.visible = true
			return
	
	# Only when warnings are present in the editor
	if not _show_bottom_bar_on_warning:
		var btn_warnings: Button = bottom_bar.get_child(3)
		if btn_warnings.visible == true:
			bottom_bar.visible = true
			return


func _editing_something_new(current_editor: ScriptEditorBase) -> void:
	if not is_instance_valid(_extension_top_bar): return

	var new_text: String = ""
	var current_script = _script_editor.get_current_script()

	if is_instance_valid(current_script):
		new_text = current_script.resource_path
		_add_recent_script_to_array(new_text)
		_extension_top_bar.modulate = Color(1,1,1,1)
	else:
		_extension_top_bar.modulate = Color(0,0,0,0) # Make it invisible if not using it

	_extension_top_bar.text = new_text
	_extension_top_bar.tooltip_text = new_text


func _is_main_screen_visible(screen) -> bool:
	# 0 = 2D, 1 = 3D, 2 = Script, 3 = AssetLib
	return _editor_interface.get_editor_main_screen().get_child(2).visible


func _get_bottom_bar() -> Control:
	var bottom_bar: Control = _current_editor
	if not is_instance_valid(bottom_bar): return null

	bottom_bar = bottom_bar.get_child(0)
	if not is_instance_valid(bottom_bar): return null

	bottom_bar = bottom_bar.get_child(0)
	if not is_instance_valid(bottom_bar) or bottom_bar.get_child_count() <= 1: return null

	bottom_bar = bottom_bar.get_child(1)
	if not is_instance_valid(bottom_bar): return null

	return bottom_bar


func _tree_recursive_highlight(item) -> void:
	while item != null:
		item.set_custom_bg_color(0, Color(0,0,0,0))

		# Set color of only Script Buttons, not the Visibility Buttons
		for i in item.get_button_count(0):
			var tooltip_text = item.get_button_tooltip_text(0,i)

			item.set_button_color(0, i, Color(1,1,1,1))

			if not tooltip_text.ends_with(".gd") or not _is_main_screen_visible(2) == true:
				continue

			item.set_button_color(0, i, Color(1,1,1,1))

			# Change the script tooltip into a script path
			var script_path = tooltip_text.get_slice(": ", 1)
			script_path = script_path.trim_suffix("This script is currently running in the editor.")
			script_path = script_path.strip_escapes()

			var current_script = _script_editor.get_current_script()
			if current_script == null or not script_path == current_script.resource_path:
				continue

			item.set_button_color(0, i, COLOR_BUTTONS)
			item.set_custom_bg_color(0, COLOR_BACKGROUND)

		_tree_recursive_highlight(item.get_first_child())
		item = item.get_next()


func _on_recent_submenu_window_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.button_index == MOUSE_BUTTON_RIGHT:
		return

	if event.pressed == true:
		# Erase item from list
		_recently_opened.erase(_extension_popup.get_item_text(_extension_popup.get_focused_item()))
		_build_recent_scripts_list()
		if _recently_opened.size() > 0:
			# Refresh and display shrunken list correctly
			_extension_top_bar.show_popup()
		else:
			# Don't bother opening an empty menu
			_extension_popup.visible = false
	else:
		# Prevent switching to an item upon releasing right click
		_extension_popup.hide_on_item_selection = false
		_extension_popup.id_pressed.disconnect(_on_recent_submenu_pressed)
		await get_tree().process_frame
		_extension_popup.hide_on_item_selection = true
		_extension_popup.id_pressed.connect(_on_recent_submenu_pressed)


func _on_recent_submenu_pressed(pressedID: int) -> void:
	var recent_string: String = _extension_popup.get_item_text(pressedID)
	var load_script: Resource = load(recent_string)
	if load_script != null:
		_editor_interface.edit_script(load_script)


func _set_plugin_settings() -> void:
	_set_plugin_setting(HIDE_SCRIPTS_PANEL_CONFIG_INFO, _hide_scripts_panel)
	_set_plugin_setting(HIDE_BOTTOM_BAR_CONFIG_INFO, _hide_bottom_bar)
	_set_plugin_setting(SHOW_BOTTOM_BAR_WARNING_CONFIG_INFO, _show_bottom_bar_on_warning)
	_set_plugin_setting(SHOW_BOTTOM_BAR_ERROR_CONFIG_INFO, _show_bottom_bar_on_error)


func _set_plugin_setting(config_info: Dictionary, value: Variant) -> void:
	if not ProjectSettings.has_setting(config_info["name"]):
		ProjectSettings.set_setting(config_info["name"], value)

	ProjectSettings.add_property_info(config_info)
	ProjectSettings.set_initial_value(config_info["name"], value)


func _get_plugin_settings() -> void:
	_hide_scripts_panel = ProjectSettings.get_setting(HIDE_SCRIPTS_PANEL_CONFIG_INFO["name"], false)
	_hide_bottom_bar = ProjectSettings.get_setting(HIDE_BOTTOM_BAR_CONFIG_INFO["name"], false)
	_show_bottom_bar_on_warning = ProjectSettings.get_setting(SHOW_BOTTOM_BAR_WARNING_CONFIG_INFO["name"], true)
	_show_bottom_bar_on_error = ProjectSettings.get_setting(SHOW_BOTTOM_BAR_ERROR_CONFIG_INFO["name"], true)
