@tool
extends EditorPlugin

var editorInterface = get_editor_interface()
var scriptEditor = editorInterface.get_script_editor()
var scriptEditorMenu = scriptEditor.get_child(0).get_child(0)
var sceneTreeDock = get_editor_interface().get_base_control().find_children("*", "SceneTreeDock", true, false)[0]
var sceneTreeEditor = sceneTreeDock.find_children("*", "SceneTreeEditor", true, false)[0]
var theTree = sceneTreeEditor.get_child(0)
var currentEditor

const sceneTopBar = preload("res://addons/script-name-on-top/topbar.tscn")
var recentlyOpened = []
var extensionTopBar

const MAX_RECENT_ITEMS = 10
const colorButtons = Color8(106, 180, 255, 255)
const colorBackground = Color8(66, 78, 120, 128)

func _enter_tree():
	turn_off_scripts_panel_if_on()
	
	# Wait until Godot Editor is fully loaded before continuing
	while true:
		await get_tree().process_frame
		if scriptEditorMenu.get_children().size() >= 13:
			break
	
	# Make everything in the top bar not expand, while the extensionTopBar will expand
	for i in scriptEditorMenu.get_children():
		i.size_flags_horizontal = 0
	
	# Add extensionTopBar
	extensionTopBar = sceneTopBar.instantiate()
	scriptEditorMenu.add_child(extensionTopBar)
	scriptEditorMenu.move_child(extensionTopBar,scriptEditorMenu.get_child_count()-8)
	extensionTopBar.get_node("Button").connect("pressed",Callable(self,"_on_topbar_button_pressed"))
	extensionTopBar.get_node("Button").get_node("MenuButton").get_popup().connect("id_pressed",Callable(self,"_on_RecentSubmenu_Pressed"))

func _on_RecentSubmenu_Pressed(pressedID):
	var pop = extensionTopBar.get_node("Button").get_node("MenuButton").get_popup()
	var recentString = pop.get_item_text(pressedID)
	var loadScript = load(recentString)
	if loadScript != null:
		editorInterface.edit_script(loadScript)

func _on_topbar_button_pressed():
	
	var btn = extensionTopBar.get_node("Button")
	var menuBtn = btn.get_node("MenuButton")
	var popup = menuBtn.get_popup()
	build_recent_scripts_list(popup)
	if popup.visible == true:
		popup.visible = false
	else:
		menuBtn.show_popup()
	btn.release_focus()
	

func build_recent_scripts_list(popup):
	popup.clear()
	for i in recentlyOpened.size():
		var filePath = recentlyOpened[i]
		popup.add_item(filePath)

func add_recent_script_to_array(recentString):
	var findExisting = recentlyOpened.find(recentString)
	if findExisting == -1:
		recentlyOpened.push_front(recentString)
		if recentlyOpened.size() > MAX_RECENT_ITEMS:
			recentlyOpened.pop_back()
	else:
		recentlyOpened.push_front(recentlyOpened.pop_at(findExisting))

func turn_off_scripts_panel_if_on():
	var getScriptsPanel = get_editor_interface().get_script_editor().get_child(0).get_child(1).get_child(0)
	if getScriptsPanel.visible == true:
		get_editor_interface().get_script_editor().get_child(0).get_child(0).get_child(0).get_popup().emit_signal("id_pressed", 14)

func _process(_delta):
	# This is better than "editor_script_changed" signal since it includes when you edit other files such as .cfg
	if currentEditor != scriptEditor.get_current_editor():
		currentEditor = scriptEditor.get_current_editor()
		editing_something_new(currentEditor)
	tree_recursive_highlight(theTree.get_root())
	
	var bottomBar = get_bottom_bar()
	if is_instance_valid(bottomBar):
		# Show bottom row only if there's an error message
		var errorMsgLabel = bottomBar.get_child(1).get_child(0)
		if errorMsgLabel.text == "":
			bottomBar.visible = false
		else:
			bottomBar.visible = true


func editing_something_new(currentEditor):
	if is_instance_valid(extensionTopBar):
		var newText
		if is_instance_valid(scriptEditor.get_current_script()):
			newText = scriptEditor.get_current_script().resource_path
			add_recent_script_to_array(newText)
			extensionTopBar.modulate = Color(1,1,1,1)
		else:
			newText = ""
			extensionTopBar.modulate = Color(0,0,0,0) # Make it invisible if not using it
		
		extensionTopBar.get_node("Button").text = newText
		extensionTopBar.get_node("Button").tooltip_text = newText

func _exit_tree():
	if is_instance_valid(extensionTopBar):
		extensionTopBar.queue_free()

func is_main_screen_visible(screen):
	# 0 = 2D, 1 = 3D, 2 = Script, 3 = AssetLib
	return editorInterface.get_editor_main_screen().get_child(2).visible

func tree_recursive_highlight(item):
	if item != null:
		while true:
			item.set_custom_bg_color(0, Color(0,0,0,0))
			
			# Set color of only Script Buttons, not the Visibility Buttons
			for i in item.get_button_count(0):
				var tooltipTxt = item.get_button_tooltip_text(0,i)
				
				item.set_button_color(0, i, Color(1,1,1,1))
				
				if tooltipTxt.begins_with("Open Script: ") and is_main_screen_visible(2) == true:
					item.set_button_color(0, i, Color(1,1,1,1))
					# Change the script tooltip into a script path
					var scriptPath = tooltipTxt.trim_prefix("Open Script: ")
					scriptPath = scriptPath.trim_suffix("This script is currently running in the editor.")
					scriptPath = scriptPath.strip_escapes()
					#print(scriptPath)
					#print(scriptEditor.get_current_script().resource_path)
					var currScript = scriptEditor.get_current_script()
					if currScript != null:
						if scriptPath == currScript.resource_path:
							item.set_button_color(0, i, colorButtons)
							item.set_custom_bg_color(0, colorBackground)
			
			tree_recursive_highlight(item.get_first_child())
			item = item.get_next()
			if item == null:
				break

func get_bottom_bar():
	var getBottomBar = get_editor_interface().get_script_editor().get_current_editor()
	if is_instance_valid(getBottomBar):
		getBottomBar = getBottomBar.get_child(0)
		if is_instance_valid(getBottomBar):
			getBottomBar = getBottomBar.get_child(0)
			if is_instance_valid(getBottomBar) and getBottomBar.get_child_count() > 1:
				getBottomBar = getBottomBar.get_child(1)
				if is_instance_valid(getBottomBar):
					return getBottomBar
	return null
