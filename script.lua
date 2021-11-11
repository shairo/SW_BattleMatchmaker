-- Battle Matchmaker
-- Version 1.3.3

g_players={}
g_ui_id=0
g_status_text=nil
g_vehicles={}
g_players={}
g_bombs={}
g_status_dirty=false

g_supply_buttons={
	MG_K={42,50},
	MG_AP={45,50},
	MG_I={46,50},

	LA_K={47,50},
	LA_HE={48,50},
	LA_F={49,50},
	LA_AP={50,50},
	LA_I={51,50},

	RA_K={52,25},
	RA_HE={53,25},
	RA_F={54,25},
	RA_AP={55,25},
	RA_I={56,25},

	HA_K={57,10},
	HA_HE={58,10},
	HA_F={59,10},
	HA_AP={60,10},
	HA_I={61,10},

	BS_K={62,1},
	BS_HE={63,1},
	BS_F={64,1},
	BS_AP={65,1},
	BS_I={66,1},

	AS_HE={68,1},
	AS_F={66,1},
	AS_AP={70,1},
}

g_default_savedata={
	base_hp=property.slider('Default Vehicle HP', 0, 5000, 100, 2000),
	battery_name='killed',
	supply_ammo_amount=property.slider('Default Ammo Supply', 0, 100, 1, 40),
	order_command=true,
}

-- Commands --

g_commands={
	{
		name='join',
		auth=true,
		action=function(peer_id, is_admin, is_auth, team_name, target_peer_id)
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			join(target_peer_id or peer_id, team_name)
		end,
		args={
			{name='team_name', type='string', require=true},
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
			if not checkTargetPeerId(target_peer_id, peer_id, is_admin) then return end
			kill(target_peer_id or peer_id)
		end,
		args={
			{name='peer_id', type='integer', require=false},
		},
	},
	{
		name='order',
		auth=true,
		action=function(peer_id, is_admin, is_auth)
			local player=g_players[peer_id]
			if not g_savedata.order_command then
				announce('Order command is not available.', peer_id)
				return
			end
			if player.vehicle_id <= 0 then
				announce('Vehicle not found.', peer_id)
				return
			end
			local m=server.getPlayerPos(peer_id)
			local x, y, z=server.getPlayerLookDirection(peer_id)
			local m2=matrix.translation(x*8,0,z*8)
			server.setVehiclePos(player.vehicle_id, matrix.multiply(m2, m))
			local name=server.getPlayerName(peer_id)
			announce('Vehicle orderd by '..name..'.', -1)
		end,
	},
	{
		name='reset',
		admin=true,
		action=function(peer_id, is_admin, is_auth)
			g_players={}
			g_vehicles={}
			g_status_dirty=true
			announce('Reset game.', -1)
		end,
	},
	{
		name='sethp',
		admin=true,
		action=function(peer_id, is_admin, is_auth, hp)
			g_savedata.base_hp=hp
			reregisterVehicles()
			announce('Set base vehicle hp to '..tostring(g_savedata.base_hp), -1)
		end,
		args={
			{name='hp', type='integer', require=true},
		},
	},
	{
		name='setbattery',
		admin=true,
		action=function(peer_id, is_admin, is_auth, two)
			if not two then
				announce('except battery name.', peer_id)
				return
			end
			g_savedata.battery_name=two
			reregisterVehicles()
			announce('Set lifeline battery name to '..tostring(g_savedata.battery_name), -1)
		end,
		args={
			{name='battery_name', type='string', require=true},
		},
	},
	{
		name='setammo',
		admin=true,
		action=function(peer_id, is_admin, is_auth, supply_ammo_amount)
			g_savedata.supply_ammo_amount=supply_ammo_amount
			reregisterVehicles()
			announce('Set supply ammo count to '..tostring(g_savedata.supply_ammo_amount), -1)
		end,
		args={
			{name='supply_ammo_amount', type='integer', require=true},
		},
	},
	{
		name='setorder',
		admin=true,
		action=function(peer_id, is_admin, is_auth, enabled)
			if enabled then
				announce('order command enabled.', -1)
				g_savedata.order_command=true
			else
				announce('order command disabled.', -1)
				g_savedata.order_command=false
			end
		end,
		args={
			{name='true|false', type='boolean', require=true},
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

function showHelp(peer_id, is_admin, is_auth)
	local commands_help='Commands:\n'
	local any_commands=false
	for i,command in ipairs(g_commands) do
		if checkAuth(command, is_admin, is_auth) then
			local args=''
			if command.args then
				for i,arg in ipairs(command.args) do
					if arg.require then
						args=args..' ['..arg.name..']'
					else
						args=args..' ('..arg.name..')'
					end
				end
			end
			commands_help=commands_help..'  - ?mm '..command.name..args..'\n'
			any_commands=true
		end
	end
	if any_commands then
		announce(commands_help, peer_id)
	else
		announce('Permitted command is not found.', peer_id)
	end
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
	g_ui_id=server.getMapID()

	for k,v in pairs(g_default_savedata) do
		if not g_savedata[k] then
			g_savedata[k]=v
		end
	end
end

function onDestroy()
	server.removePopup(-1, g_ui_id)
end

function onTick()
	for i=1,#g_vehicles do
		updateVehicle(g_vehicles[i])
	end

	if g_status_dirty then
		g_status_dirty=false
		updateStatus()
	end

	updateBomb()
end

function onPlayerJoin(steam_id, name, peer_id, is_admin, is_auth)
	showStatus(true)
end

function onPlayerLeave(steam_id, name, peer_id, admin, auth)
	leave(peer_id)
end

function onPlayerDie(steam_id, name, peer_id, is_admin, is_auth)
	kill(peer_id)
end

function onPlayerRespawn(peer_id)
	local player=g_players[peer_id]
	if not player then return end

	player.character_id=server.getPlayerCharacterID(peer_id)
end

function onButtonPress(vehicle_id, peer_id, button_name)
	if not peer_id or peer_id<0 then return end
	if g_savedata.supply_ammo_amount<=0 then return end

	local equipment_data=g_supply_buttons[button_name]
	if not equipment_data then return end
	local equipment_id=equipment_data[1]
	local equipment_amount=equipment_data[2]

	local character_id=server.getPlayerCharacterID(peer_id)
	local current_equipment_id=server.getCharacterItem(character_id, 1)
	if current_equipment_id>0 then
		if current_equipment_id~=equipment_id then
			announce('Your large inventory is full.', peer_id)
		end
		return
	end

	announce(tostring(vehicle_id), peer_id)
	local vehicle=findVehicle(vehicle_id)
	if vehicle and vehicle.remain_ammo<=0 then
		announce('Out of ammo.', peer_id)
		return
	end

	server.setCharacterItem(character_id, 1, equipment_id, true, equipment_amount)

	if vehicle then
		vehicle.remain_ammo=vehicle.remain_ammo-1
		announce('Ammo here! (Remain:'..tostring(vehicle.remain_ammo)..')', peer_id)
	else
		announce('Ammo here!', peer_id)
	end
end

function onPlayerSit(peer_id, vehicle_id, seat_name)
	local player=g_players[peer_id]
	if not player or not player.alive then return end

	local vehicle=registerVehicle(vehicle_id)
	if vehicle and vehicle.alive then
		player.vehicle_id=vehicle_id
	end
	g_status_dirty=true
end

function onVehicleDespawn(vehicle_id, peer_id)
	unregisterVehicle(vehicle_id)
end

function onVehicleDamaged(vehicle_id, damage_amount, voxel_x, voxel_y, voxel_z)
	if damage_amount<=0 then return end

	local vehicle=findVehicle(vehicle_id)
	if not vehicle then return end

	if vehicle.hp then
		vehicle.hp=math.max(vehicle.hp-damage_amount,0)
		g_status_dirty=true
	end
end

function onCustomCommand(full_message, peer_id, is_admin, is_auth, command, one, two, three, four, five)
	if command~='?mm' then return end

	if not one then
		showHelp(peer_id, is_admin, is_auth)
		announce(
			'Current settings:\n'..
			'  - base hp:'..tostring(g_savedata.base_hp)..'\n'..
			'  - battery name:'..g_savedata.battery_name..'\n'..
			'  - ammo amount:'..tostring(g_savedata.supply_ammo_amount)..'\n'..
			'  - order command enabled:'..tostring(g_savedata.order_command),
			peer_id)
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
	if command_define.args then
		for i,arg_define in ipairs(command_define.args) do
			if #args < i then
				if arg_define.require then
					announce('Argument not enough. Except ['..arg_define.name..'].', peer_id)
					return
				end
				break
			end
			local value=convert(args[i], arg_define.type)
			if value==nil then
				announce('Except '..arg_define.type..' to ['..arg_define.name..'].', peer_id)
				return
			end
			args[i]=value
		end
	end

	command_define.action(peer_id, is_admin, is_auth, table.unpack(args))
end

-- Player Functions --

function join(peer_id, team)
	local name, is_success=server.getPlayerName(peer_id)
	if not is_success then return end
	local character_id=server.getPlayerCharacterID(peer_id)
	local player={
		name=name,
		team=team,
		alive=true,
		character_id=character_id,
		vehicle_id=-1,
	}
	g_players[peer_id]=player

	local vehicle_id, is_success=server.getCharacterVehicle(character_id)
	if is_success then
		local vehicle=registerVehicle(vehicle_id)
		if vehicle and vehicle.alive then
			player.vehicle_id=vehicle_id
		end
	end

	g_status_dirty=true

	announce('You joined to '..team..'.', peer_id)
end

function leave(peer_id)
	local data=g_players[peer_id]
	if not data then return end
	g_players[peer_id]=nil
	g_status_dirty=true

	announce('You leaved from '..data.name..'.', peer_id)
end

function kill(peer_id)
	local player=g_players[peer_id]
	if not player or not player.alive then return end
	player.alive=false
	g_status_dirty=true
	server.notify(-1, 'Kill Log', player.name..' is dead.', 9)
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

	vehicle={
		vehicle_id=vehicle_id,
		alive=true,
		remain_ammo=g_savedata.supply_ammo_amount//1|0,
	}

	local base_hp=g_savedata.base_hp
	if base_hp and base_hp>0 then
		vehicle.hp=math.max(base_hp//1|0,1)
	end

	local battery_name=g_savedata.battery_name
	if battery_name then
		local battery, is_success=server.getVehicleBattery(vehicle_id, battery_name)
		if is_success and battery.charge>0 then
			vehicle.battery_name=battery_name
		end
	end

	if vehicle.hp or vehicle.battery_name then
		table.insert(g_vehicles, vehicle)
		return vehicle
	end
end

function unregisterVehicle(vehicle_id)
	local vehicle,index=findVehicle(vehicle_id)
	if not vehicle then return end
	table.remove(g_vehicles,index)

	for _,player in pairs(g_players) do
		if player.vehicle_id==vehicle_id then
			player.vehicle_id=-1
		end
	end

	g_status_dirty=true
end

function reregisterVehicles()
	for i=1,#g_vehicles do
		local vehicle=g_vehicles[i]
		if vehicle.alive then
			vehicle.hp=nil
			local base_hp=g_savedata.base_hp
			if base_hp and base_hp>0 then
				vehicle.hp=math.max(base_hp//1|0,1)
			end

			vehicle.battery_name=nil
			local battery_name=g_savedata.battery_name
			if battery_name then
				local battery, is_success=server.getVehicleBattery(vehicle.vehicle_id, battery_name)
				if is_success and battery.charge>0 then
					vehicle.battery_name=battery_name
				end
			end

			vehicle.remain_ammo=g_savedata.supply_ammo_amount//1|0

			g_status_dirty=true
		end
	end
end

function updateVehicle(vehicle)
	if not vehicle.alive then return end

	local vehicle_id=vehicle.vehicle_id

	if vehicle.battery_name then
		local battery, is_success=server.getVehicleBattery(vehicle_id, vehicle.battery_name)
		if is_success and battery.charge<=0 then
			vehicle.alive=false
		end
	end

	if vehicle.hp==0 then
		vehicle.alive=false
	end

	if vehicle.alive then
		return
	end

	-- explode
	spawnBomb(vehicle_id)

	-- kill
	for peer_id,player in pairs(g_players) do
		if player.vehicle_id==vehicle_id then
			-- force getout
			local player_matrix, is_success=server.getObjectPos(player.character_id)
			if is_success then
				server.setObjectPos(player.character_id, player_matrix)
			end

			player.vehicle_id=-1
			kill(peer_id)
		end
	end

	server.setVehicleTooltip(vehicle_id, 'Destroyed')
	g_status_dirty=true
end

-- System Functions --

function updateStatus()
	local team_stats={}
	local any=false
	for _,player in pairs(g_players) do
		local stat=team_stats[player.team]
		if not stat then
			stat=''
		end

		local hp=nil
		local battery_name=nil
		if player.vehicle_id>=0 then
			local vehicle=findVehicle(player.vehicle_id)
			if vehicle then
				hp=vehicle.hp
				battery_name=vehicle.battery_name
			end
		end

		team_stats[player.team]=stat..'\n'..playerToString(player.name,player.alive,hp,battery_name)
		any=true
	end

	if any then
		g_status_text=''
		local first=true
		for team,stat in pairs(team_stats) do
			if not first then g_status_text=g_status_text..'\n\n' end
			g_status_text=g_status_text..'* Team '..team..' *'..stat
			first=false
		end
		showStatus()
	else
		g_status_text=nil
		server.removePopup(-1, g_ui_id)
	end
end

function playerToString(name, alive, hp, b)
	local stat_text=alive and 'Alive' or 'Dead'
	local hp_text=hp and string.format('\nHP:%.0f',hp) or ''
	local battery_text=b and '\n(B)' or ''
	return name..'\nStat:'..stat_text..hp_text..battery_text
end

function showStatus(regenerate)
	if regenerate then
		server.removePopup(-1, g_ui_id)
		server.removeMapID(-1, g_ui_id)
		g_ui_id=server.getMapID()
	end
	if g_status_text then
		server.setPopupScreen(-1,g_ui_id,'',true,g_status_text,-0.9,0.2)
	end
end

function spawnBomb(vehicle_id)
	local vehicle_matrix, is_success=server.getVehiclePos(vehicle_id)
	if not is_success then return end

	local object_id, is_success=server.spawnObject(vehicle_matrix, 67)
	if is_success then
		table.insert(g_bombs,{
			vehicle_id=vehicle_id,
			object_id=object_id,
			time=100,
		})
	end
end

function updateBomb()
	local i=#g_bombs
	while i>0 do
		local bomb=g_bombs[i]
		if bomb.time<=0 then
			local vehicle_matrix, is_success=server.getVehiclePos(bomb.vehicle_id)
			if is_success then
				server.setObjectPos(bomb.object_id, vehicle_matrix)
			end
		else
			bomb.time=bomb.time-1
		end
		i=i-1
	end
end

-- Utility Functions --

function announce(text, peer_id)
	server.announce('[Matchmaker]', text, peer_id)
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
