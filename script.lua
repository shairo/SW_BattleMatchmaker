-- Battle Matchmaker
-- Version 1.6.0

g_players={}
g_popups={}
g_team_stats={}
g_vehicles={}
g_team_status_dirty=false
g_player_status_dirty=false
g_finish_dirty=false
g_in_game=false
g_in_countdown=false
g_pause=false
g_timer=0
g_remind_interval=3600
g_ui_reset_requested=false

g_ammo_supply_buttons={
	MG_K={42,50,'mg'},
	MG_AP={45,50,'mg'},
	MG_I={46,50,'mg'},

	LA_K={47,50,'la'},
	LA_HE={48,50,'la'},
	LA_F={49,50,'la'},
	LA_AP={50,50,'la'},
	LA_I={51,50,'la'},

	RA_K={52,25,'ra'},
	RA_HE={53,25,'ra'},
	RA_F={54,25,'ra'},
	RA_AP={55,25,'ra'},
	RA_I={56,25,'ra'},

	HA_K={57,10,'ha'},
	HA_HE={58,10,'ha'},
	HA_F={59,10,'ha'},
	HA_AP={60,10,'ha'},
	HA_I={61,10,'ha'},

	BS_K={62,1,'bs'},
	BS_HE={63,1,'bs'},
	BS_F={64,1,'bs'},
	BS_AP={65,1,'bs'},
	BS_I={66,1,'bs'},

	AS_HE={68,1,'as'},
	AS_F={66,1,'as'},
	AS_AP={70,1,'as'},
}

g_classes={
	ground_light	={hp=300},
	ground_medium	={hp=1200},
	ground_heavy	={hp=2400},
	ground_mega		={hp=3000},
	ground_boss		={hp=20000},
}

g_item_supply_buttons={
	['Take Extinguisher']	={1,10,0,  9},
	['Take Torch']			={1,27,0,400},
	['Take Welder']			={1,26,0,250},
	['Take FlashLight']		={2,15,0,100},
	['Take Binoculars']		={2, 6,0,  0},
	['Take NightVision']	={2,17,0,100},
	['Take Compass']		={2, 8,0,  0},
	['Take FirstAidKit']	={2,11,4,  0},
}

g_settings={
	{
		name='Vehicle HP',
		key='vehicle_hp',
		type='integer',
		min=1,
	},
	{
		name='Vehicle class Enabled',
		key='vehicle_class',
		type='boolean',
	},
	{
		name='Max Vehicle Damage',
		key='max_damage',
		type='integer',
		min=0,
	},
	{
		name='Ammo supply Enabled',
		key='ammo_supply',
		type='boolean',
	},
	{
		name='MG Ammo Count',
		key='ammo_mg',
		type='integer',
		min=-1,
	},
	{
		name='LA Ammo Count',
		key='ammo_la',
		type='integer',
		min=-1,
	},
	{
		name='RA Ammo Count',
		key='ammo_ra',
		type='integer',
		min=-1,
	},
	{
		name='HA Ammo Count',
		key='ammo_ha',
		type='integer',
		min=-1,
	},
	{
		name='BS Ammo Count',
		key='ammo_bs',
		type='integer',
		min=-1,
	},
	{
		name='AS Ammo Count',
		key='ammo_as',
		type='integer',
		min=-1,
	},
	{
		name='Game Time (min)',
		key='game_time',
		type='number',
		min=1,
	},
	{
		name='Order Command Enabled (in battle)',
		key='order_enabled',
		type='boolean',
	},
	{
		name='TPS Enabled (in battle)',
		key='tps_enabled',
		type='boolean',
	},
	{
		name='Player Damage (in battle)',
		key='player_damage',
		type='boolean',
	},
	{
		name='Auto standby',
		key='auto_standby',
		type='boolean',
	},
	{
		name='Auto vehicle cleanup',
		key='gc_vehicle',
		type='boolean',
	},
	{
		name='MG Auto reloading',
		key='mg_auto_reload',
		type='boolean',
	},
	{
		name='MG Auto reloading interval (sec)',
		key='mg_reload_time',
		type='number',
		min=1,
	},
	{
		name='Auto auth',
		key='auto_auth',
		type='boolean',
	},
}

g_default_teams={
	'RED',
	'BLUE',
	'PINK',
	'YLW',
}

g_temporary_team='Standby'

g_default_savedata={
	vehicle_hp		=property.slider("Vehicle HP", 100, 5000, 100, 2000),
	vehicle_class	=property.checkbox("Vehicle class Enabled", true),
	max_damage		=1000,
	ammo_supply		=property.checkbox("Ammo supply Enabled", true),
	ammo_mg			=-1,
	ammo_la			=-1,
	ammo_ra			=-1,
	ammo_ha			=-1,
	ammo_bs			=-1,
	ammo_as			=-1,
	game_time		=property.slider("Game time (min)", 1, 60, 1, 20),
	order_enabled	=property.checkbox("Order Command Enabled (in battle)", false),
	tps_enabled		=property.checkbox("Third Person Enabled (in battle)", true),
	player_damage	=property.checkbox("Player Damage Enabled (in battle)", true),
	auto_standby	=property.checkbox("Auto Standby after battle", false),
	gc_vehicle		=property.checkbox("Auto vehicle cleanup", false),
	supply_vehicles	={},
	flag_vehicles	={},
	mg_auto_reload	=property.checkbox("MG Auto reloading", true),
	mg_reload_time	=property.slider("MG Auto reloading interval (sec)", 1, 60, 1, 20),
	auto_auth		=property.checkbox("Auto Auth", false),
}

g_mag_names={}
for i=1,10 do g_mag_names[i]='magazine_'..tostring(i) end

-- Commands --

g_commands={
	{
		name='join',
		auth=true,
		action=function(peer_id, is_admin, is_auth, team_name, target_peer_id)
			if g_in_game and not is_admin then
				announce('Cannot join after game start..', peer_id)
				return
			end
			if not team_name then
				team_name=g_temporary_team
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			join(target_peer_id or peer_id, team_name, is_admin)
		end,
		args={
			{name='team_name', type='string', require=false},
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='leave',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			leave(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='die',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if not g_in_game then
				announce('Cannot die before game start.', peer_id)
				return
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			kill(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='ready',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if g_in_game then
				announce('Cannot ready after game start.', peer_id)
				return
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			ready(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='wait',
		auth=true,
		action=function(peer_id, is_admin, is_auth, target_peer_id)
			if g_in_game then
				announce('Cannot wait after game start.', peer_id)
				return
			end
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			wait(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='order',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			if g_in_game and not g_pause and not g_savedata.order_enabled then
				announce('Cannot order after game start.', peer_id)
				return
			end
			local player=g_players[peer_id]
			if not player then
				announce('Joind player not found. peer_id:'..tostring(peer_id), peer_id)
				return
			end
			if not player.alive then
				announce('Dead player cannot order vehicle.', peer_id)
				return
			end
			local vehicle=findVehicle(player.vehicle_id)
			if not vehicle then
				announce('Vehicle not found.', peer_id)
				return
			end

			server.setGroupPos(vehicle.group_id, getAheadMatrix(peer_id, 2, 8))
			announce('Vehicle orderd.', peer_id)
		end,
	},
	{
		name='start',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			readyAll(peer_id)
		end,
	},
	{
		name='abort',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			if g_in_countdown then
				stopCountdown()
			elseif g_in_game then
				finishGame()
				notify('Game Aborted', 'Game has been aborted by admin.', 6, -1)
			end
		end,
	},
	{
		name='supply',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			if g_in_game and not is_admin then
				announce('Cannot call supply after game start.', peer_id)
				return
			end
			spawnSupply(peer_id)
			announce('supply object deployed.', peer_id)
		end,
	},
	{
		name='delete_supply',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			despawnSupply(peer_id)
		end,
	},
	{
		name='clear_supply',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			clearSupplies()
			clearFlags()
			announce('All supplies cleared.', -1)
		end,
	},
	{
		name='flag',
		admin=true,
		action=function(peer_id, is_admin, is_auth, name)
			spawnFlag(peer_id, name:lower())
		end,
		args={
			{name='name', type='string', require=true},
		},
	},
	{
		name='delete_flag',
		admin=true,
		action=function(peer_id, is_admin, is_auth, name)
			despawnFlag(peer_id, name:lower())
		end,
		args={
			{name='name', type='string', require=true},
		},
	},
	{
		name='clear_flag',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			clearFlags()
			announce('All flags cleared.', -1)
		end,
	},
	{
		name='pause',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			if not g_in_game then
				announce('Cannot pause before game start.', peer_id)
				return
			end
			if g_pause then return end
			g_pause=true
			notify('Timer Operation', 'Game is paused.', 1, -1)
		end,
	},
	{
		name='resume',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			if not g_pause then
				announce('Cannot resume when not in pause.', peer_id)
				return
			end
			g_pause=false
			notify('Timer Operation', 'Game is resumed.', 1, -1)
		end,
	},
	{
		name='add_time',
		admin=true,
		action=function(peer_id, is_admin, is_auth, minute)
			if not g_in_game then
				announce('Cannot add time before game start.', peer_id)
				return
			end
			g_timer=g_timer+(minute*60*60//1|0)
			if g_timer>0 then
				local timerMin=g_timer//3600
				notify('Timer Updated', 'The remaining time has been changed to '..tostring(timerMin)..' minutes', 1, -1)
			end
		end,
		args={
			{name='minute', type='number', require=true},
		},
	},
	{
		name='shuffle',
		admin=true,
		action=function(peer_id, is_admin, is_auth, team_count)
			if g_in_game or g_in_countdown then
				announce('Cannot shuffle after game start.', peer_id)
				return
			end
			shuffle(team_count)
		end,
		args={
			{name='team_count', type='integer', require=true, min=2, max=#g_default_teams},
		},
	},
	{
		name='reset',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			for i,player in pairs(g_players) do
				unregisterPopup(player.popup_name)
			end
			g_players={}
			g_vehicles={}
			g_team_status_dirty=true
			g_player_status_dirty=true
			clearSupplies()
			clearFlags()
			finishGame()
			announce('Reset game.', -1)
		end,
	},
	{
		name='reset_ui',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			renewUiIds()
			announce('Refresh ui ids.', -1)
		end,
	},
	{
		name='set',
		admin=true,
		action=function(peer_id, is_admin, is_auth, key, value)
			if not key then
				showSettingsHelp(peer_id)
				return
			end
			local setting_define=findSetting(key)
			if not setting_define then
				announce('Setting "'..key..'" not found.', peer_id)
				return
			end
			if not value then
				announce('Argument not enough. Except ['..setting_define.type..'].', peer_id)
				return
			end
			local value, is_success=validateArg(setting_define, value, peer_id)
			if not is_success then return end
			g_savedata[setting_define.key]=value
			announce(setting_define.name..' set to '..tostring(value), -1)
		end,
		args={
			{name='key', type='string', require=false},
			{name='value', type='string', require=false},
		},
	},
}

function findCommand(command)
	for i,command_define in ipairs(g_commands) do
		if command_define.name==command then
			return command_define
		end
	end
end

function findSetting(key)
	for i,setting_define in ipairs(g_settings) do
		if setting_define.key==key then
			return setting_define
		end
	end
end


function showHelp(peer_id, is_admin, is_auth)
	local commands_help='Commands:\n'
	local any_commands=false
	for i,command_define in ipairs(g_commands) do
		if checkAuth(command_define, is_admin, is_auth) then
			local args=''
			if command_define.args then
				for i,arg in ipairs(command_define.args) do
					if arg.require then
						args=args..' ['..arg.name..']'
					else
						args=args..' ('..arg.name..')'
					end
				end
			end
			commands_help=commands_help..'  - ?mm '..command_define.name..args..'\n'
			any_commands=true
		end
	end
	if any_commands then
		announce(commands_help, peer_id)
	else
		announce('Permitted command is not found.', peer_id)
	end
end

function showSettings(peer_id)
	local settings_help='Settings:\n'
	for i,setting_define in ipairs(g_settings) do
		local value=g_savedata[setting_define.key]
		settings_help=settings_help..'  - '..setting_define.name..': '..tostring(value)..'\n'
	end
	announce(settings_help, peer_id)
end

function showSettingsHelp(peer_id)
	local settings_help='Setting commands:\n'
	for i,setting_define in ipairs(g_settings) do
		settings_help=settings_help..'  - ?mm set '..setting_define.key..': ['..setting_define.type..']\n'
	end
	announce(settings_help, peer_id)
end

function checkAuth(command, is_admin, is_auth)
	return is_admin or (not command.admin and (is_auth or not command.auth))
end

function checkTargetPeerId(target_peer_id, peer_id, is_admin)
	if not target_peer_id then return true end
	if not is_admin then
		announce('Permission denied. Only admin can specify target_peer_id.', peer_id)
		return false
	end
	local _, is_success=server.getPlayerName(target_peer_id)
	if not is_success then
		announce('Invalid peer_id.', peer_id)
		return false
	end
	return true
end

-- Callbacks --

function onCreate(is_world_create)
	for k,v in pairs(g_default_savedata) do
		if g_savedata[k]==nil then
			g_savedata[k]=v
		end
	end

	clearSupplies()
	clearFlags()

	registerPopup('countdown', 0, 0.6)
	registerPopup('game_time', 0, 0.9)

	setSettingsToStandby()
end

function onDestroy()
	clearPopups()
	clearSupplies()
	clearFlags()
end

function onTick()
	if g_ui_reset_requested then
		g_ui_reset_requested=false
		renewUiIds()
	end

	for i=#g_vehicles,1,-1 do
		updateVehicle(g_vehicles[i])
	end

	if g_in_countdown then
		if g_timer>0 then
			local sec=g_timer//60
			g_timer=g_timer-1
			g_countdown_text=string.format('Start in\n%.0f', sec)
			setPopup('countdown', true, string.format('Start in\n%.0f', sec))
		else
			startGame()
			notify('Game Start', 'Panzer Vor!', 9, -1)
		end
	end
	if g_in_game then
		if g_pause then
		elseif g_timer>0 then
			local sec=g_timer//60
			g_timer=g_timer-1
			local time_text=string.format('%02.f:%02.f', sec//60,sec%60)
			setPopup('game_time', true, time_text)

			if g_timer>0 and g_timer%g_remind_interval==0 then
				server.notify(-1, 'Time Reminder', time_text..' left.', 1)
			end
		else
			finishGame()
			notify('Game End', 'Timeup!', 9, -1)
		end
	end

	if g_finish_dirty then
		g_finish_dirty=false
		checkFinish()
	end

	if g_team_status_dirty then
		g_team_status_dirty=false
		updateTeamStatus()
	end

	if g_player_status_dirty then
		g_player_status_dirty=false
		updatePlayerStatus()
	end

	updatePopups()
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	g_ui_reset_requested=true

	if not is_auth and g_savedata.auto_auth then
		server.addAuth(peer_id)
	end
end

function onPlayerLeave(steam_id, name, peer_id, admin, auth)
	peer_id=peer_id//1|0
	leave(peer_id)
	despawnSupply(peer_id)
end

function onPlayerDie(steam_id, name, peer_id, is_admin, is_auth)
	peer_id=peer_id//1|0
	kill(peer_id)
end

function onButtonPress(vehicle_id, peer_id, button_name)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	if not peer_id or peer_id<0 then return end
	local character_id, is_success=server.getPlayerCharacterID(peer_id)
	if not is_success then return end

	if button_name=='?mm die' then
		kill(peer_id)
		return
	elseif button_name=='?mm ready' then
		ready(peer_id)
		return
	end

	if isSupply(vehicle_id) then
		if not server.getVehicleButton(vehicle_id, button_name).on then return end
		local item_supply=g_item_supply_buttons[button_name]
		if item_supply then
			local slot,equipment_id,v1,v2=table.unpack(item_supply)
			slot=findEmptySlot(character_id, slot)
			if not slot then
				announce('Inventory is full.', peer_id)
				return
			end
			server.setCharacterItem(character_id, slot, equipment_id, false, v1, v2)
		elseif button_name=='Join RED' then
			join(peer_id, 'RED')
		elseif button_name=='Join BLUE' then
			join(peer_id, 'BLUE')
		elseif button_name=='Join PINK' then
			join(peer_id, 'PINK')
		elseif button_name=='Join YLW' then
			join(peer_id, 'YLW')
		elseif button_name=='Leave' then
			leave(peer_id)
		elseif button_name=='Clear Large Equipment' then
			server.setCharacterItem(character_id, 1, 0, false)
		elseif button_name=='Clear Small Equipments' then
			for i=2,9 do
				server.setCharacterItem(character_id, i, 0, false)
			end
		elseif button_name=='Clear Outfit' then
			server.setCharacterItem(character_id, 10, 0, false)
		end
		return
	end

	if not g_savedata.ammo_supply then return end

	local equipment_data=g_ammo_supply_buttons[button_name]
	if not equipment_data then return end
	local equipment_id,amount,ammo_type=table.unpack(equipment_data)

	local current_equipment_id=server.getCharacterItem(character_id, 1)
	if current_equipment_id>0 then
		if current_equipment_id~=equipment_id then
			announce('Your large inventory is full.', peer_id)
		end
		return
	end

	local vehicle=findVehicle(vehicle_id)
	if vehicle and vehicle.ammo[ammo_type]==0 then
		announce('Out of ammo.', peer_id)
		return
	end

	server.setCharacterItem(character_id, 1, equipment_id, true, amount)

	if vehicle then
		local remain_ammo=vehicle.ammo[ammo_type]-1
		if remain_ammo>=0 then
			vehicle.ammo[ammo_type]=remain_ammo
			announce('Ammo here! (Remain:'..tostring(remain_ammo)..')', peer_id)
			return
		end
	end
	announce('Ammo here!', peer_id)
end

function onPlayerSit_(peer_id, vehicle_id, seat_name)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	local player=g_players[peer_id]
	if not player or not player.alive then
		return
	end

	local vehicle=registerVehicle(vehicle_id)
	if vehicle and vehicle.alive then
		player.vehicle_id=vehicle_id
	end
	g_player_status_dirty=true
end
function onCharacterSit(object_id, vehicle_id, seat_name)
	local peer_id=findPeerIdByCharacterId(object_id)
	onPlayerSit_(peer_id, vehicle_id, seat_name)
end
function findPeerIdByCharacterId(object_id)
	for i,p in ipairs(server.getPlayers()) do
		if object_id==server.getPlayerCharacterID(p.id) then
			return p.id
		end
	end
end


function onVehicleDespawn(vehicle_id, peer_id)
	vehicle_id=vehicle_id//1|0
	peer_id=peer_id//1|0
	unregisterVehicle(vehicle_id)
end

function onVehicleDamaged(vehicle_id, damage_amount, voxel_x, voxel_y, voxel_z, body_index)
	vehicle_id=vehicle_id//1|0
	if not g_in_game then return end
	if damage_amount<=0 then return end

	local vehicle=findVehicle(vehicle_id)
	if not vehicle then return end

	if vehicle.hp then
		vehicle.damage_in_frame=vehicle.damage_in_frame+damage_amount
		g_player_status_dirty=true
	end
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth, command, one, two, three, four, five)
	peer_id=peer_id//1|0
	if command~='?mm' then return end

	if not one then
		showHelp(peer_id, is_admin, is_auth)
		showSettings(peer_id)
		return
	end

	local command_define=findCommand(one)
	if not command_define then
		announce('Command "'..one..'" not found.', peer_id)
		return
	end
	if not checkAuth(command_define, is_admin, is_auth) then
		announce('Permission denied.', peer_id)
		return
	end

	local args={two, three, four, five}
	if command_define.args and not validateArgs(command_define, args, peer_id) then
		return
	end
	command_define.action(peer_id, is_admin, is_auth, table.unpack(args))
end

-- Player Functions --

function join(peer_id, team, force)
	if g_in_game and not force then return end
	local name, is_success=server.getPlayerName(peer_id)
	if not is_success then return end
	local player={
		name=name,
		team=team,
		alive=true,
		ready=g_in_game,
		vehicle_id=-1,
		popup_name='player_status_'..peer_id,
	}
	g_players[peer_id]=player

	local character_id=server.getPlayerCharacterID(peer_id)
	local vehicle_id, is_success=server.getCharacterVehicle(character_id)
	if is_success then
		local vehicle=registerVehicle(vehicle_id)
		if vehicle and vehicle.alive then
			player.vehicle_id=vehicle_id
		end
	end

	g_team_status_dirty=true
	g_player_status_dirty=true

	announce('You joined to '..team..'.', peer_id)

	stopCountdown()
end

function leave(peer_id)
	local player=g_players[peer_id]
	if not player then return end
	unregisterPopup(player.popup_name)
	g_players[peer_id]=nil
	g_team_status_dirty=true
	g_player_status_dirty=true

	announce('You leaved from '..player.team..'.', peer_id)

	if g_in_game then
		g_finish_dirty=true
	else
		if player.ready then
			stopCountdown()
		else
			startCountdown()
		end
	end
end

function shuffle(team_count, exec_peer_id)
	local peer_ids={}
	for peer_id,player in pairs(g_players) do
		player.ready=false
		table.insert(peer_ids, peer_id)
	end

	if #peer_ids<1 then
		announce('Player not enough.', exec_peer_id)
		return
	end

	for i=1,#peer_ids do
		local pick=math.random(1, #peer_ids)
		local peer_id=peer_ids[pick]
		local team=g_default_teams[1+(i-1)%team_count]
		g_players[peer_id].team=team
		announce('You joined to '..team..'.', peer_id)
		table.remove(peer_ids, pick)
	end

	stopCountdown()
	g_team_status_dirty=true
	g_player_status_dirty=true
end

function kill(peer_id)
	if not g_in_game then return end
	local player=g_players[peer_id]
	if not player or not player.alive then return end
	local vehicle_id=player.vehicle_id
	player.alive=false
	player.vehicle_id=-1
	g_player_status_dirty=true

	if vehicle_id>=0 then
		for _,p in pairs(g_players) do
			if p.alive and p.vehicle_id==vehicle_id then
				vehicle_id=-1
				break
			end
		end
		if vehicle_id>=0 then
			findVehicle(vehicle_id).alive=false
		end
	end

	notify('Kill Log', player.name..' is dead.', 9, -1)
	g_finish_dirty=true
end

function ready(peer_id)
	if g_in_game then return end
	local player=g_players[peer_id]
	if not player then return end
	if not player.alive then
		player.alive=true
		g_player_status_dirty=true
	end
	if not player.ready then
		player.ready=true
		startCountdown()
		g_player_status_dirty=true
	end
end

function readyAll(peer_id)
	if g_in_game then return end
	for peer_id,player in pairs(g_players) do
		if player.alive and not player.ready then
			player.ready=true
		end
	end
	startCountdown(true, peer_id)
	g_player_status_dirty=true
end

function wait(peer_id)
	if g_in_game then return end
	local player=g_players[peer_id]
	if not player then return end
	if not player.alive then
		player.alive=true
		g_player_status_dirty=true
	end
	if player.ready then
		player.ready=false
		g_player_status_dirty=true
		stopCountdown()
	end
end

-- Vehicle Functions --

function findVehicle(vehicle_id)
	for i=1,#g_vehicles do
		local vehicle=g_vehicles[i]
		if vehicle.vehicle_id==vehicle_id then
			return vehicle,i
		end
	end
end

function registerVehicle(vehicle_id)
	local vehicle=findVehicle(vehicle_id)
	if vehicle then return vehicle end

	local data,is_success=server.getVehicleData(vehicle_id)
	if not is_success then return end

	vehicle={
		vehicle_id=vehicle_id,
		group_id=data.group_id,
		alive=true,
		ammo={
			mg=g_savedata.ammo_mg//1|0,
			la=g_savedata.ammo_la//1|0,
			ra=g_savedata.ammo_ra//1|0,
			ha=g_savedata.ammo_ha//1|0,
			bs=g_savedata.ammo_bs//1|0,
			as=g_savedata.ammo_as//1|0,
		},
		gc_time=600,
		damage_in_frame=0,
		reload_check_time=0,
		reload_mag=nil,
	}

	local vehicle_hp
	if g_savedata.vehicle_class then
		for class_name,class in pairs(g_classes) do
			local sign_data, is_success = server.getVehicleSign(vehicle_id, class_name)
			if is_success then
				vehicle_hp=class.hp
				break
			end
		end
	else
		vehicle_hp=g_savedata.vehicle_hp
	end

	if vehicle_hp then
		vehicle.hp=math.max(vehicle_hp//1|0,1)
		table.insert(g_vehicles, vehicle)
		return vehicle
	end
end

function unregisterVehicle(vehicle_id)
	local vehicle,index=findVehicle(vehicle_id)
	if not vehicle then return end
	table.remove(g_vehicles,index)

	for peer_id,player in pairs(g_players) do
		if player.vehicle_id==vehicle_id then
			player.vehicle_id=-1
			if g_in_game then
				kill(peer_id)
			end
		end
	end

	g_player_status_dirty=true
end

function reregisterVehicles()
	for i=1,#g_vehicles do
		local vehicle=g_vehicles[i]
		if vehicle.alive then
			vehicle.hp=nil
			local vehicle_hp=g_savedata.vehicle_hp
			if vehicle_hp and vehicle_hp>0 then
				vehicle.hp=math.max(vehicle_hp//1|0,1)
			end

			vehicle.remain_ammo=g_savedata.supply_ammo//1|0

			g_player_status_dirty=true
		end
	end
end

function updateVehicle(vehicle)
	if not vehicle.alive then
		if vehicle.gc_time>0 then
			vehicle.gc_time=vehicle.gc_time-1
		elseif g_savedata.gc_vehicle then
			server.despawnVehicle(vehicle.vehicle_id, true)
		end
		return
	end

	local vehicle_id=vehicle.vehicle_id

	-- auto reloading
	if not g_savedata.mg_auto_reload then
	elseif vehicle.reload_check_time<g_savedata.mg_reload_time*60 then
		vehicle.reload_check_time=vehicle.reload_check_time+1
	else
		vehicle.reload_check_time=0
		local reload_mag=vehicle.reload_mag
		vehicle.reload_mag=nil

		for i=1,#g_mag_names do
			local mag_name=g_mag_names[i]
			local data, is_success=server.getVehicleWeapon(vehicle_id, mag_name)
			if not is_success then break end
			if data.capacity==50 and data.ammo==0 then
				if mag_name==reload_mag then
					if vehicle.ammo.mg~=0 then
						if vehicle.ammo.mg>0 then
							vehicle.ammo.mg=vehicle.ammo.mg-1
						end
						server.setVehicleWeapon(vehicle_id, mag_name, 50)
					end
				elseif not vehicle.reload_mag then
					vehicle.reload_mag=mag_name
				end
			end
		end
	end

	if vehicle.hp and vehicle.damage_in_frame>0 then
		local damage_in_frame=math.min(vehicle.damage_in_frame, g_savedata.max_damage)//1|0
		vehicle.hp=math.max(vehicle.hp-damage_in_frame, 0)

		if vehicle.hp==0 then
			vehicle.alive=false
		end
	end

	if vehicle.damage_in_frame>0 then
		for peer_id,player in pairs(g_players) do
			if player.vehicle_id==vehicle_id then
				local popup=findPopup(player.popup_name)
				if popup then
					popup.shake=17
				end
			end
		end
	end

	vehicle.damage_in_frame=0

	if vehicle.alive then
		return
	end

	-- explode
	local vehicle_matrix, is_success=server.getVehiclePos(vehicle_id)
	if is_success then
		server.spawnExplosion(vehicle_matrix, 0.17)
	end

	-- kill
	for peer_id,player in pairs(g_players) do
		if player.vehicle_id==vehicle_id then
			-- force getout
			local player_matrix, is_success=server.getPlayerPos(peer_id)
			if is_success then
				server.setPlayerPos(peer_id, player_matrix)
			end

			player.vehicle_id=-1
			kill(peer_id)
		end
	end

	server.setVehicleTooltip(vehicle_id, 'Destroyed')
	g_player_status_dirty=true
end

-- System Functions --

function updateTeamStatus()
	-- gen map
	local team_map={}
	for _,player in pairs(g_players) do
		local team_list=team_map[player.team]
		if not team_list then
			team_list={player}
			team_map[player.team]=team_list
		else
			table.insert(team_list, player)
		end
	end

	-- remove
	local i=#g_team_stats
	while i>0 do
		local team_status=g_team_stats[i]
		if not team_map[team_status.name] then
			unregisterPopup(team_status.popup_name)
			table.remove(g_team_stats, i)
		end
		i=i-1
	end

	-- add
	for team_name,player_list in pairs(team_map) do
		local team_status,idx=registerTeamStatus(team_name)

		local popup_x=-1.04+idx*0.18
		local popup_y=0.9
		registerPopup(team_status.popup_name, popup_x, popup_y)

		for i,player in ipairs(player_list) do
			local player_popup_y=popup_y-i*0.19
			registerPopup(player.popup_name, popup_x, player_popup_y)
		end
	end
end

function registerTeamStatus(name)
	for i,team_status in ipairs(g_team_stats) do
		if team_status.name==name then
			return team_status,i
		end
	end
	local popup_name='team_status_'..name
	registerPopup(popup_name, 0, 0)
	setPopup(popup_name, true, '* '..name..' *')
	local team_status={
		name=name,
		popup_name=popup_name,
	}
	table.insert(g_team_stats, team_status)
	return team_status,#g_team_stats
end

function updatePlayerStatus()
	for _,player in pairs(g_players) do
		local hp=nil
		if player.vehicle_id>=0 then
			local vehicle=findVehicle(player.vehicle_id)
			if vehicle then
				hp=vehicle.hp
			end
		end

		setPopup(player.popup_name, true, playerToString(player.name,player.alive,player.ready,hp))
	end
end

function playerToString(name, alive, ready, hp)
	local stat_text=alive and (g_in_game and 'Alive' or (ready and 'Ready' or 'Wait')) or 'Dead'
	local hp_text=hp and string.format('\nHP:%.0f',hp) or ''
	return name..'\nStat:'..stat_text..hp_text
end

function startCountdown(force, peer_id)
	if g_in_game or g_in_countdown then return end
	local ready=true
	local teams={}
	for peer_id,player in pairs(g_players) do
		ready=ready and player.ready
		teams[player.team]=true
	end
	if not ready then
		if force then
			announce('There is unready player(s).', peer_id)
		end
		return
	end

	local team_count=getTableCount(teams)
	if team_count<1 or (team_count<2 and not force) then
		if force then
			announce('There are not enough registered teams.', peer_id)
		end
		return
	end
	announce('Countdown start.', -1)
	g_timer=600
	g_in_countdown=true
	g_player_status_dirty=true
end

function stopCountdown()
	if g_in_game or not g_in_countdown then return end
	announce('Countdown stop.', -1)
	setPopup('countdown', false)
	g_in_countdown=false
	g_player_status_dirty=true
end

function checkFinish()
	if not g_in_game then return end
	local team_aliver_counts={}
	local any=false
	for _,player in pairs(g_players) do
		local add=player.alive and 1 or 0
		local count=team_aliver_counts[player.team]
		team_aliver_counts[player.team]=count and (count+add) or add
		any=true
	end
	if not any then
		finishGame()
		notify('Game End', 'No player. Game is interrupted.', 6, -1)
		return
	end
	local alive_team_count=0
	local alive_team_name=''
	for team_name,team_aliver_count in pairs(team_aliver_counts) do
		if team_aliver_count>0 then
			alive_team_count=alive_team_count+1
			alive_team_name=team_name
		end
	end
	if alive_team_count>1 then return end

	finishGame()
	if alive_team_count==1 then
		notify('Game End', 'Team '..alive_team_name..' Win!', 9, -1)
	else
		notify('Game End', 'Draw Game!', 9, -1)
	end
end

function startGame()
	g_in_game=true
	g_in_countdown=false
	g_pause=false
	g_player_status_dirty=true
	g_timer=g_savedata.game_time*60*60//1|0
	g_remind_interval=g_timer//4

	for _,player in pairs(g_players) do
		player.ready=false
	end

	setPopup('countdown', false)
	clearSupplies()
	setSettingsToBattle()

	local settings=server.getGameSettings()
	announce('- Infinitie Electric:'..tostring(settings.infinite_batteries), -1)
	announce('- Infinitie Fuel:'..tostring(settings.infinite_fuel), -1)
	announce('- Infinitie Ammo:'..tostring(settings.infinite_ammo), -1)
	announce('- Player Damage:'..tostring(settings.player_damage), -1)
	announce('- Disable Weapons:'..tostring(settings.ceasefire), -1)
end

function finishGame()
	g_in_game=false
	g_in_countdown=false
	g_pause=false
	g_player_status_dirty=true
	setPopup('game_time', false)

	for i,player in pairs(server.getPlayers()) do
		local peer_id=player.id
		local object_id, is_success=server.getPlayerCharacterID(peer_id)
		if is_success then
			server.reviveCharacter(object_id)
			server.setCharacterData(object_id, 100, false, false)
		end
	end

	if g_savedata.auto_standby then
		for _,p in pairs(g_players) do
			p.alive=true
			p.ready=false
		end
	end

	setSettingsToStandby()
end

function setSettingsToBattle()
	local tps_enabled=g_savedata.tps_enabled
	local player_damage=g_savedata.player_damage
	server.setGameSetting('third_person', tps_enabled)
	server.setGameSetting('third_person_vehicle', tps_enabled)
	server.setGameSetting('vehicle_damage', true)
	server.setGameSetting('player_damage', player_damage)
	server.setGameSetting('map_show_players', false)
	server.setGameSetting('map_show_vehicles', false)
end

function setSettingsToStandby()
	server.setGameSetting('third_person', true)
	server.setGameSetting('third_person_vehicle', true)
	server.setGameSetting('vehicle_damage', false)
	server.setGameSetting('player_damage', false)
	server.setGameSetting('map_show_players', true)
	server.setGameSetting('map_show_vehicles', true)
end

-- UI

function registerPopup(name, x, y)
	local popup=findPopup(name)
	if popup then
		popup.x=x
		popup.y=y
		popup.is_dirty=true
		return
	end
	table.insert(g_popups, {
		name=name,
		x=x,
		y=y,
		ox=0,
		oy=0,
		shake=-1,
		ui_id=server.getMapID(),
		is_show=false,
		text='',
		is_dirty=true,
	})
end

function unregisterPopup(name)
	for i,popup in ipairs(g_popups) do
		if popup.name==name then
			server.removeMapID(-1, popup.ui_id)
			table.remove(g_popups, i)
			return
		end
	end
end

function findPopup(name)
	for i,popup in ipairs(g_popups) do
		if popup.name==name then
			return popup
		end
	end
end

function setPopup(name, is_show, text)
	local popup=findPopup(name)
	if not popup then return end
	if popup.is_show~=is_show then
		popup.is_show=is_show
		popup.is_dirty=true
	end
	if popup.text~=text then
		popup.text=text
		popup.is_dirty=true
	end
end

function updatePopups()
	for i,popup in ipairs(g_popups) do
		local shake=popup.shake
		if shake>=0 then
			popup.shake=shake-1
			if shake%4==0 then
				popup.ox=(math.random()-0.5)*0.002*shake
				popup.oy=(math.random()-0.5)*0.002*shake
				popup.is_dirty=true
			end
		end
		if popup.is_dirty then
			popup.is_dirty=false
			server.setPopupScreen(-1, popup.ui_id, popup.name, popup.is_show, popup.text, popup.x+popup.ox, popup.y+popup.oy)
		end
	end
end

function clearPopups()
	for i,popup in ipairs(g_popups) do
		server.removeMapID(-1, popup.ui_id)
	end
	g_popups={}
end

function renewUiIds()
	for i,popup in ipairs(g_popups) do
		server.removeMapID(-1, popup.ui_id)
		popup.ui_id=server.getMapID()
		popup.is_dirty=true
	end

	for peer_id,supply in pairs(g_savedata.supply_vehicles) do
		local vehicle_matrix, is_success = server.getVehiclePos(supply.vehicle_id)
		if is_success then
			server.removeMapID(-1, supply.ui_id)
			supply.ui_id=server.getMapID()
			local x,y,z = matrix.position(vehicle_matrix)
			server.addMapLabel(-1, supply.ui_id, 1, 'supply', x, z)
		end
	end

	for name,flag in pairs(g_savedata.flag_vehicles) do
		local vehicle_matrix, is_success = server.getVehiclePos(flag.vehicle_id)
		if is_success then
			server.removeMapID(-1, flag.ui_id)
			flag.ui_id=server.getMapID()
			local x,y,z = matrix.position(vehicle_matrix)
			local r,g,b,a=getColor(name)
			server.addMapObject(-1, flag.ui_id, 1, 9, x, z, 0, 0, flag.vehicle_id, 0, name, 30, name, r, g, b, a)
		end
	end
end

-- Support vehicle

function spawnSupply(peer_id)
	despawnSupply(peer_id)
	local vehicle_matrix=getAheadMatrix(peer_id, 1, 8)
	local vehicle_id=spawnAddonVehicle('supply', vehicle_matrix)
	if vehicle_id then
		local ui_id=server.getMapID()
		local x,y,z=matrix.position(vehicle_matrix)
		server.addMapLabel(-1, ui_id, 1, 'supply', x, z)
		g_savedata.supply_vehicles[peer_id]={
			vehicle_id=vehicle_id,
			ui_id=ui_id,
		}
	end
end

function despawnSupply(peer_id)
	local supply=g_savedata.supply_vehicles[peer_id]
	if supply then
		server.despawnVehicle(supply.vehicle_id, true)
		server.removeMapID(-1, supply.ui_id)
		g_savedata.supply_vehicles[peer_id]=nil
	end
end

function clearSupplies()
	for peer_id,supply in pairs(g_savedata.supply_vehicles) do
		if type(supply)=='table' then
			server.despawnVehicle(supply.vehicle_id, true)
			server.removeMapID(-1, supply.ui_id)
		else
			-- for backward compertibility
			server.despawnVehicle(supply, true)
		end
	end
	g_savedata.supply_vehicles={}
end

function isSupply(vehicle_id)
	for peer_id,supply in pairs(g_savedata.supply_vehicles) do
		if supply.vehicle_id==vehicle_id then
			return true
		end
	end
	return false
end

function spawnFlag(peer_id, name)
	despawnFlag(peer_id, name)
	local vehicle_matrix=getAheadMatrix(peer_id, 9, 8)
	local vehicle_id=spawnAddonVehicle('flag', vehicle_matrix)

	if vehicle_id then
		server.setVehicleTooltip(vehicle_id, name)
		local ui_id=server.getMapID()
		local x,y,z=matrix.position(vehicle_matrix)
		local r,g,b,a=getColor(name)
		server.addMapObject(-1, ui_id, 1, 9, x, z, 0, 0, vehicle_id, 0, name, 30, name, r, g, b, a)
		g_savedata.flag_vehicles[name]={
			vehicle_id=vehicle_id,
			ui_id=ui_id,
		}
	end
end

function despawnFlag(peer_id, name)
	local flag=g_savedata.flag_vehicles[name]
	if flag then
		server.despawnVehicle(flag.vehicle_id, true)
		server.removeMapID(-1, flag.ui_id)
		g_savedata.flag_vehicles[name]=nil
	end
end

function clearFlags()
	for name,flag in pairs(g_savedata.flag_vehicles) do
		server.despawnVehicle(flag.vehicle_id, true)
		server.removeMapID(-1, flag.ui_id)
	end
	g_savedata.flag_vehicles={}
end

-- Utility Functions --

function announce(text, peer_id)
	server.announce('[Matchmaker]', text, peer_id)
end

function notify(title, text, type, peer_id)
	server.notify(-1, title, text, type)
	announce(title..'\n'..text, peer_id)
end

function getTableCount(table)
	local count=0
	for idx,p in pairs(table) do
		count=count+1
	end
	return count
end

function clamp(x,a,b)
	return x<a and a or x>b and b or x
end

function convert(value, type)
	local converter=g_converters[type]
	if converter then
		return converter(value)
	end
	return value
end

g_converters={
	integer=function(v)
		v=tonumber(v)
		return v and v//1|0
	end,
	number=function(v)
		return tonumber(v)
	end,
	boolean=function(v)
		if v=='true' then return true end
		if v=='false' then return false end
	end,
}

function getAheadMatrix(peer_id, y, z)
	local look_x, look_y, look_z=server.getPlayerLookDirection(peer_id)
	local position=server.getPlayerPos(peer_id)
	local offset=matrix.translation(0, y, -z)
	local rotation=matrix.rotationToFaceXZ(-look_x, -look_z)
	return matrix.multiply(position, matrix.multiply(rotation, offset))
end

function spawnAddonVehicle(name, transform_matrix)
	local addon_index, is_success = server.getAddonIndex()
	if not is_success then return end

	local search_tag='name='..name
	local addon_data=server.getAddonData(addon_index)
	for location_index=0,addon_data.location_count-1 do
		local location_data=server.getLocationData(addon_index, location_index)
		for component_index=0,location_data.component_count-1 do
			local component_data= server.getLocationComponentData(addon_index, location_index, component_index)
			if component_data.type=='vehicle' then
				for _,tag_pair in pairs(component_data.tags) do
					if tag_pair==search_tag then
						return server.spawnAddonVehicle(transform_matrix, addon_index, component_data.id)
					end
				end
			end
		end
	end
end

function findEmptySlot(object_id, slot)
	local equipment_id=server.getCharacterItem(object_id, slot)
	if equipment_id==0 then
		return slot
	end
	if slot>=2 and slot<9 then
		return findEmptySlot(object_id, slot+1)
	end
end

function getColor(name)
	local color=g_colors[name]
	if color then
		return table.unpack(color)
	end
	return 255,127,39,255
end

g_colors={
	red		={255,0  ,0,  255},
	green	={0,  255,0,  255},
	blue	={0,  0,  255,255},
	yellow	={255,255,0,  255},
	ylw		={255,255,0,  255},
	pink	={255,0,  255,255},
	white	={255,255,255,255},
	black	={0,  0,  0,  255},
}

function validateArgs(command_define, args, peer_id)
	if command_define.args then
		for i,arg_define in ipairs(command_define.args) do
			if #args < i then
				if arg_define.require then
					announce('Argument not enough. Except ['..arg_define.name..'].', peer_id)
					return false
				end
				break
			end
			local value, is_success=validateArg(arg_define, args[i])
			if not is_success then return false end
			args[i]=value
		end
	end
	return true
end

function validateArg(arg_define, arg, peer_id)
	local value=convert(arg, arg_define.type)
	if value==nil then
		announce('Except '..arg_define.type..' to ['..arg_define.name..'].', peer_id)
		return nil, false
	end
	if arg_define.type=='integer' or arg_define.type=='number' then
		if arg_define.min and value<arg_define.min then
			announce(arg_define.name ..'cannot be set to less than '..tostring(arg_define.min), peer_id)
			return nil, false
		end
		if arg_define.max and value>arg_define.max then
			announce(arg_define.name ..'cannot be set to greater than '..tostring(arg_define.max), peer_id)
			return nil, false
		end
	end
	return value, true
end
