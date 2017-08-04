
CloneClass( MenuManager )
CloneClass( MenuCallbackHandler )
CloneClass( ModMenuCreator )
CloneClass( MenuModInfoGui )

Hooks:RegisterHook( "MenuManagerInitialize" )
Hooks:RegisterHook( "MenuManagerPostInitialize" )
function MenuManager.init( self, ... )
	self.orig.init( self, ... )
	Hooks:Call( "MenuManagerInitialize", self )
	Hooks:Call( "MenuManagerPostInitialize", self )
end

Hooks:RegisterHook( "MenuManagerOnOpenMenu" )
function MenuManager.open_menu( self, menu_name, position )
	self.orig.open_menu( self, menu_name, position )
	Hooks:Call( "MenuManagerOnOpenMenu", self, menu_name, position )
end

function MenuManager.open_node( self, node_name, parameter_list )
	self.orig.open_node( self, node_name, parameter_list )
end

function MenuManager:show_download_progress( mod_name )

	local dialog_data = {}
	dialog_data.title = managers.localization:text("base_mod_download_downloading_mod", { ["mod_name"] = mod_name })
	dialog_data.mod_name = mod_name or "No Mod Name"

	local ok_button = {}
	ok_button.cancel_button = true
	ok_button.text = managers.localization:text("dialog_ok")

	dialog_data.focus_button = 1
	dialog_data.button_list = {
		ok_button
	}

	managers.system_menu:show_download_progress( dialog_data )

end

-- Add menus
Hooks:Add( "MenuManagerPostInitialize", "MenuManagerPostInitialize_Base", function( menu_manager )

	local success, err = pcall(function()

		-- Setup lua mods menu
		menu_manager:_base_process_menu(
			{"menu_main"},
			"mods_options",
			"options",
			"MenuManager_Base_SetupModsMenu",
			"MenuManager_Base_PopulateModsMenu",
			"MenuManager_Base_BuildModsMenu"
		)

		-- Setup mod options/keybinds menu
		menu_manager:_base_process_menu(
			{"menu_main", "menu_pause"},
			"video",
			"options",
			"MenuManager_Base_SetupModOptionsMenu",
			"MenuManager_Base_PopulateModOptionsMenu",
			"MenuManager_Base_BuildModOptionsMenu"
		)

		-- Allow custom menus on the main menu (and lobby) and the pause menu 
		menu_manager:_base_process_menu( {"menu_main"} )
		menu_manager:_base_process_menu( {"menu_pause"} )

	end)
	if not success then
		log("[Error] " .. tostring(err))
	end

end )

function MenuManager._base_process_menu( menu_manager, menu_names, parent_menu_name, parent_menu_button, setup_hook, populate_hook, build_hook )

	for k, v in pairs( menu_names ) do

		local menu = menu_manager._registered_menus[ v ]
		if menu then

			local nodes = menu.logic._data._nodes
			local hook_id_setup = setup_hook or "MenuManagerSetupCustomMenus"
			local hook_id_populate = populate_hook or "MenuManagerPopulateCustomMenus"
			local hook_id_build = build_hook or "MenuManagerBuildCustomMenus"

			MenuHelper:SetupMenu( nodes, parent_menu_name or "video" )
			MenuHelper:SetupMenuButton( nodes, parent_menu_button or "options" )

			Hooks:RegisterHook( hook_id_setup )
			Hooks:RegisterHook( hook_id_populate )
			Hooks:RegisterHook( hook_id_build )

			Hooks:Call( hook_id_setup, menu_manager, nodes )
			Hooks:Call( hook_id_populate, menu_manager, nodes )
			Hooks:Call( hook_id_build, menu_manager, nodes )

		end

	end

end

-- Add lua mods menu
function ModMenuCreator.modify_node(self, original_node, data)

	ModMenuCreator._mod_menu_modifies = {}

	local node_name = original_node._parameters.name
	if self._mod_menu_modifies then
		if self._mod_menu_modifies[node_name] then

			local func = self._mod_menu_modifies[node_name]
			local node = original_node
			self[func](self, node, data)

			return node

		end
	end

	return self.orig.modify_node(self, original_node, data)

end

-- Create this function if it doesn't exist
function MenuCallbackHandler.can_toggle_chat( self )
	if managers and managers.menu then
		local input = managers.menu:active_menu() and managers.menu:active_menu().input
		return not input or input.can_toggle_chat and input:can_toggle_chat()
	else
		return true
	end
end

--------------------------------------------------------------------------------
-- Add BLT save function

function MenuCallbackHandler:perform_blt_save()
	BLT.Mods:Save()
end

--------------------------------------------------------------------------------
-- Add BLT dll update notification

function MenuCallbackHandler:blt_update_dll_dialog()
	
	local dialog_data = {}
	dialog_data.title = managers.localization:text( "blt_update_dll_title" )
	dialog_data.text = managers.localization:text( "blt_update_dll_text" )

	local download_button = {}
	download_button.text = managers.localization:text( "blt_update_dll_goto_website" )
	download_button.callback_func = callback( self, self, "clbk_goto_paydaymods_download" )

	local ok_button = {}
	ok_button.text = managers.localization:text( "blt_update_later" )
	ok_button.cancel_button = true

	dialog_data.button_list = { download_button, ok_button }
	managers.system_menu:show( dialog_data )

end

function MenuCallbackHandler:clbk_goto_paydaymods_download()
	os.execute( "cmd /c start http://paydaymods.com/download/" )
end

--------------------------------------------------------------------------------
-- Add visibility callback for showing keybinds

function MenuCallbackHandler:blt_show_keybinds_item()
	return BLT.Keybinds and BLT.Keybinds:has_keybinds()
end
