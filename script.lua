
g_players={}
g_ui_id=0
g_status_text=nil
g_update_timer=0
g_vehicles={}
g_players={}
g_bombs={}
g_status_dirty=false

button_names={
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
	hp=1000,
	battery_name='killed',
}

function onCreate(is_world_create)
	g_ui_id = server.getMapID()

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
	g_update_timer=(g_update_timer+1)%1200
	if g_update_timer==0 then
		showStatus()
	end

	for i=1,#g_vehicles do
		updateVehicle(g_vehicles[i])
	end

	if g_status_dirty then
		g_status_dirty=false
		updateStatus()
	end

	updateBomb()
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
	if not g_savedata.ammosupply then return end

	local equipment_data=button_names[button_name]
	if not equipment_data then return end
	local equipment_id=equipment_data[1]
	local equipment_amount=equipment_data[2]

	local character_id=server.getPlayerCharacterID(peer_id)
	local current_equipment_id=server.getCharacterItem(character_id, 1)
	if current_equipment_id>0 then
		if current_equipment_id~=equipment_id then
			server.announce('[Matchmaker]', 'your large inventory is full.', peer_id)
		end
		return
	end

	server.setCharacterItem(character_id, 1, equipment_id, true, equipment_amount)
	server.announce('[Matchmaker]', 'Ammo here!', peer_id)
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
	if not is_admin and not is_auth then return end

	if command~='?mm' then
	elseif one=='join' then
		peer_id=parsePeerId(three, peer_id, is_admin)
		if not peer_id then return end
		join(peer_id, two)
	elseif one=='leave' then
		peer_id=parsePeerId(two, peer_id, is_admin)
		if not peer_id then return end
		leave(peer_id)
	elseif one=='die' then
		peer_id=parsePeerId(two, peer_id, is_admin)
		if not peer_id then return end
		kill(peer_id)
	elseif one=='reset' then
		if not is_admin then
			server.announce('[Matchmaker]', 'permission denied.', peer_id)
			return
		end
		g_players={}
		g_vehicles={}
		g_status_dirty=true
	elseif one=='sethp' then
		if not is_admin then
			server.announce('[Matchmaker]', 'permission denied.', peer_id)
			return
		end
		if not two then
			server.announce('[Matchmaker]', 'except hp.', peer_id)
			return
		end
		local hp=tonumber(two)
		if not hp then
			server.announce('[Matchmaker]', 'except number to hp.', peer_id)
			return
		end
		g_savedata.base_hp=hp
		server.announce('[Matchmaker]', 'set base vehicle hp to '..tostring(g_savedata.base_hp), -1)
	elseif one=='setbattery' then
		if not is_admin then
			server.announce('[Matchmaker]', 'permission denied.', peer_id)
			return
		end
		if not two then
			server.announce('[Matchmaker]', 'except battery name.', peer_id)
			return
		end
		g_savedata.battery_name=two
		server.announce('[Matchmaker]', 'set lifeline battery name to '..tostring(g_savedata.battery_name), -1)
	elseif one=='ammosupply' then
		if two=='true' then
			g_savedata.ammosupply=true
			server.announce('[Matchmaker]', 'ammo supply enabled.', -1)
		elseif two=='false' then
			g_savedata.ammosupply=false
			server.announce('[Matchmaker]', 'ammo supply disabled.', -1)
		else
			server.announce('[Matchmaker]', 'except "true" or "false".', peer_id)
		end
	else
		if is_admin then
			server.announce('[Matchmaker]',
				'Commands:\n'..
				'  - ?mm join [team_name] (peer_id)\n'..
				'  - ?mm leave (peer_id)\n'..
				'  - ?mm die (peer_id)\n'..
				'  - ?mm reset\n'..
				'  - ?mm sethp [hp]\n'..
				'  - ?mm setbattery [battery_name]\n'..
				'  - ?mm ammosupply [true|false]',
				peer_id)
		else
			server.announce('[Matchmaker]',
				'Commands:\n'..
				'  - ?mm join [team_name]\n'..
				'  - ?mm leave\n'..
				'  - ?mm die',
				peer_id)
		end
	end
end

function parsePeerId(arg, peer_id, is_admin)
	if not arg then return peer_id end
	if not is_admin then
		server.announce('[Matchmaker]', 'permission denied.', peer_id)
		return nil
	end
	local parsed_peer_id=tonumber(arg)
	if not parsed_peer_id then
		server.announce('[Matchmaker]', 'invalid peer_id.', peer_id)
		return nil
	end
	return parsed_peer_id
end

function join(peer_id, team)
	if not team or #team<1 then
		server.announce('[Matchmaker]', 'except team name.', peer_id)
		return
	end

	local name, is_success = server.getPlayerName(peer_id)
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

	local vehicle_id, is_success = server.getCharacterVehicle(character_id)
	if is_success then
		local vehicle=registerVehicle(vehicle_id)
		if vehicle and vehicle.alive then
			player.vehicle_id=vehicle_id
		end
	end

	g_status_dirty=true

	server.announce('[Matchmaker]', 'you joined to '..team..'.', peer_id)
end

function leave(peer_id)
	local data=g_players[peer_id]
	if not data then return end
	g_players[peer_id]=nil
	g_status_dirty=true

	server.announce('[Matchmaker]', 'you leaved from '..data.name..'.', peer_id)
end

function kill(peer_id)
	local player=g_players[peer_id]
	if not player or not player.alive then return end
	player.alive=false
	g_status_dirty=true
	server.notify(-1, 'Kill Log', player.name..' is dead.', 9)
end

function updateStatus()
	local teamStats={}
	local any=false
	for _,player in pairs(g_players) do
		local stat=teamStats[player.team]
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

		teamStats[player.team]=stat..playerToString(player.name,player.alive,hp,battery_name)
		any=true
	end

	if any then
		g_status_text=''
		local first=true
		for team,stat in pairs(teamStats) do
			if not first then g_status_text=g_status_text..'\n\n' end
			g_status_text=g_status_text..'* Team '..team..' *\n'..stat
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

function showStatus()
	if g_status_text then
		server.setPopupScreen(-1,g_ui_id,'',true,g_status_text,-0.9,0.2)
	end
end

function clamp(x,a,b)
	return x<a and a or x>b and b or x
end

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
	}

	local base_hp=g_savedata.base_hp
	if base_hp and base_hp>0 then
		vehicle.hp=math.max(base_hp,1)
	end

	local battery_name=g_savedata.battery_name
	if battery_name then
		local battery, is_success = server.getVehicleBattery(vehicle_id, battery_name)
		if is_success and battery.charge>0 then
			vehicle.battery_name=battery_name
		end
	end

	if vehicle.hp or vehicle.battery_name then
		table.insert(g_vehicles, vehicle)
		return vehicle
	end
end

function updateVehicle(vehicle)
	if not vehicle.alive then return end

	local vehicle_id=vehicle.vehicle_id

	if vehicle.battery_name then
		local battery, is_success = server.getVehicleBattery(vehicle_id, vehicle.battery_name)
		if not is_success or battery.charge<=0 then
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
			local player_matrix, is_success = server.getObjectPos(player.character_id)
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

function spawnBomb(vehicle_id)
	local vehicle_matrix, is_success = server.getVehiclePos(vehicle_id)
	if not is_success then return end

	local object_id, is_success=server.spawnObject(vehicle_matrix, 67)
	if is_success then
		table.insert(g_bombs,{
			vehicle_id=vehicle_id,
			object_id=object_id,
			time=58,
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
