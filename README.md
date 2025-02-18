# Script Name on Top

![Untitled](https://user-images.githubusercontent.com/15337628/196391599-4cf0336d-8e8a-4d22-84db-7ae46146d697.png)

## Overview

**Script Name on Top** is a Godot Editor plugin that enhances the script editor by displaying the name of the currently active script in the top bar. It also provides quick access to recently opened scripts and includes options to hide the scripts panel and bottom bar for a cleaner workspace.

## Features

- Displays the currently active script's name in the top bar.
- Provides a dropdown menu to access recently opened scripts (up to 10 recent items).
- Allows users to hide the scripts panel and bottom bar for a more compact interface.
- Automatically updates the script name display when switching between scripts.
- Color highlights for currently active scripts in the scene tree.

## Installation

### Assets Library

1. Open the assets library tab and search for **Script Name on Top**.
2. Download the plugin.
3. Go to **Project > Project Settings > Plugins**.
4. Locate **Script Name on Top** in the plugin list and enable it.
5. Reload Godot.

### GitHub

1. Download or clone this repository.
2. Copy the `addons/script-name-on-top` folder into your Godot project’s `addons/` directory.
3. In Godot, go to **Project > Project Settings > Plugins**.
4. Locate **Script Name on Top** in the plugin list and enable it.
5. Reload Godot.

## Usage

### Display Script Name on Top
Once enabled, the plugin will display the active script’s filename in a top bar above the script editor.

### Recent Scripts Dropdown
- Click the script name to open a dropdown list of recently accessed scripts (up to 10 items).
- Right-click a script in the list to remove it from recent items.

### Hiding UI Elements
- The plugin settings allow you to toggle the visibility of the scripts panel and bottom bar.
- These settings are stored in `ProjectSettings` and persist across sessions.

## Configuration

The plugin offers three configuration options:

- **Hide Scripts Panel**: Automatically hides the scripts panel from the editor when enabled.
- **Hide Bottom Bar**: Automatically hides the editor bottom bar when enabled.
- **Show Bottom Bar on Warning**: Automatically shows the bottom bar when a warning occurs.

You can find these settings under **Project > Project Settings... > General > Addons > Script Name On Top**.
