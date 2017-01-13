throwing = {}

throwing.arrows = {}

throwing.modname = minetest.get_current_modname()

--------- Arrows functions ---------
local function shoot_arrow(itemstack, player)
	for _,arrow in ipairs(throwing.arrows) do
		if player:get_inventory():get_stack("main", player:get_wield_index()+1):get_name() == arrow then
			if not minetest.setting_getbool("creative_mode") then
				player:get_inventory():remove_item("main", arrow)
			end
			local playerpos = player:getpos()
			local obj = minetest.add_entity({x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, arrow.."_entity")
			local dir = player:get_look_dir()

			local velocity_factor = tonumber(minetest.setting_get("throwing.velocity_factor")) or 19
			local horizontal_acceleration_factor = tonumber(minetest.setting_get("throwing.horizontal_acceleration_factor")) or -3
			local vertical_acceleration = tonumber(minetest.setting_get("throwing.vertical_acceleration")) or -10

			obj:setvelocity({x=dir.x*velocity_factor, y=dir.y*velocity_factor, z=dir.z*velocity_factor})
			obj:setacceleration({x=dir.x*horizontal_acceleration_factor, y=vertical_acceleration, z=dir.z*horizontal_acceleration_factor})
			obj:setyaw(player:get_look_horizontal()-math.pi/2)
			minetest.sound_play("throwing_sound", {pos=playerpos, gain = 0.5})
			obj:get_luaentity().player = player:get_player_name()
			return true
		end
	end
	return false
end

local function arrow_step(self, dtime)
	self.timer = self.timer + dtime
	local pos = self.object:getpos()
	local node = minetest.get_node(pos)

	local logging = function(message, level)
		minetest.log(level or "action", "[throwing] Arrow "..self.node.." throwed by player "..self.player.." "..tostring(self.timer).."s ago "..message)
	end

	local hit = function(pos, node, obj)
		if obj then
			if obj:is_player() then
				if obj:get_player_name() == self.player then -- Avoid hitting the hitter
					return
				end
			end
		end

		self.object:remove()

		if node and minetest.is_protected(pos, self.player) then -- Forbid hitting nodes in protected areas
			return
		end

		local player = minetest.get_player_by_name(self.player)
		if not player then -- Possible if the player disconnected
			return
		end
		local ret, reason = self.on_hit(pos, self.last_pos, node, obj, player)
		if ret == false then
			if reason then
				logging(": on_hit function failed for reason: "..reason, "warning")
			else
				logging(": on_hit function failed", "warning")
			end

			if not minetest.setting_getbool("creative_mode") then
				player:get_inventory():add_item("main", self.node)
			end
		end

		if self.on_hit_sound then
			minetest.sound_play(self.on_hit_sound, {pos = pos, gain = 0.8})
		end
		if node then
			logging("collided with node "..node.name.." at ("..pos.x..","..pos.y..","..pos.z..")")
		elseif obj then
			if obj:get_luaentity() then
				logging("collided with luaentity "..obj:get_luaentity().name.." at ("..pos.x..","..pos.y..","..pos.z..")")
			elseif obj:is_player() then
				logging("collided with player "..obj:get_player_name().." at ("..pos.x..","..pos.y..","..pos.z..")")
			else
				logging("collided with object at ("..pos.x..","..pos.y..","..pos.z..")")
			end
		end
	end

	-- Collision with a node
	if node.name == "ignore" then
		self.object:remove()
		logging("reached ignore. Removing.")
		return
	elseif node.name ~= "air" then
		hit(pos, node, nil)
		return
	end

	-- Collision with an object
	local objs = minetest.get_objects_inside_radius(pos, 1)
	for k, obj in pairs(objs) do
		if obj:get_luaentity() then
			if obj:get_luaentity().name ~= self.name and obj:get_luaentity().name ~= "__builtin:item" then
				hit(pos, nil, obj)
			end
		else
			hit(pos, nil, obj)
		end
	end


	self.last_pos = pos -- Used by the build arrow
end

--[[
on_hit(pos, last_pos, node, object, hitter)
Either node or object is nil, depending whether the arrow collided with an object (luaentity or player) or with a node.
No log message is needed in this function (a generic log message is automatically emitted), except on error or warning.
Should return false or false, reason on failure.
]]
function throwing.register_arrow(name, itemcraft, craft_quantity, description, tiles, on_hit_sound, on_hit, groups)
	table.insert(throwing.arrows, throwing.modname..":"..name)

	local _groups = {dig_immediate = 3}
	if groups then
		for k, v in pairs(groups) do
			_groups[k] = v
		end
	end
	minetest.register_node(throwing.modname..":"..name, {
		drawtype = "nodebox",
		paramtype = "light",
		node_box = {
			type = "fixed",
			fixed = {
				-- Shaft
				{-6.5/17, -1.5/17, -1.5/17, 6.5/17, 1.5/17, 1.5/17},
				-- Spitze
				{-4.5/17, 2.5/17, 2.5/17, -3.5/17, -2.5/17, -2.5/17},
				{-8.5/17, 0.5/17, 0.5/17, -6.5/17, -0.5/17, -0.5/17},
				-- Federn
				{6.5/17, 1.5/17, 1.5/17, 7.5/17, 2.5/17, 2.5/17},
				{7.5/17, -2.5/17, 2.5/17, 6.5/17, -1.5/17, 1.5/17},
				{7.5/17, 2.5/17, -2.5/17, 6.5/17, 1.5/17, -1.5/17},
				{6.5/17, -1.5/17, -1.5/17, 7.5/17, -2.5/17, -2.5/17},

				{7.5/17, 2.5/17, 2.5/17, 8.5/17, 3.5/17, 3.5/17},
				{8.5/17, -3.5/17, 3.5/17, 7.5/17, -2.5/17, 2.5/17},
				{8.5/17, 3.5/17, -3.5/17, 7.5/17, 2.5/17, -2.5/17},
				{7.5/17, -2.5/17, -2.5/17, 8.5/17, -3.5/17, -3.5/17},
			}
		},
		tiles = tiles,
		inventory_image = tiles[1],
		description = description,
		groups = _groups,
		on_place = function(itemstack, placer, pointed_thing)
			if minetest.setting_getbool("throwing.allow_arrow_placing") and pointed_thing.above then
				local playername = placer:get_player_name()
				if not minetest.is_protected(pointed_thing.above, playername) then
					minetest.log("action", "Player "..playername.." placed arrow "..throwing.modname..":"..name.." into a protected area at ("..pointed_thing.above.x..","..pointed_thing.above.y..","..pointed_thing.above.z..")")
					minetest.set_node(pointed_thing.above, {name = throwing.modname..":"..name})
					itemstack:take_item()
					return itemstack
				else
					minetest.log("warning", "Player "..playername.." tried to place arrow "..throwing.modname..":"..name.." into a protected area at ("..pointed_thing.above.x..","..pointed_thing.above.y..","..pointed_thing.above.z..")")
					return itemstack
				end
			else
				return itemstack
			end
		end
	})

	minetest.register_entity(throwing.modname..":"..name.."_entity", {
		physical = false,
		timer = 0,
		visual = "wielditem",
		visual_size = {x = 0.125, y = 0.125},
		textures = {throwing.modname..":"..name},
		collisionbox = {0, 0, 0, 0, 0, 0},
		on_hit = on_hit,
		on_hit_sound = on_hit_sound,
		node = throwing.modname..":"..name,
		player = "",
		on_step = arrow_step
	})

	if itemcraft then
		minetest.register_craft({
			output = throwing.modname..":"..name.." "..craft_quantity,
			recipe = {
				{itemcraft, "default:stick", "default:stick"}
			}
		})
		minetest.register_craft({
			output = throwing.modname..":"..name.." "..craft_quantity,
			recipe = {
				{ "default:stick", "default:stick", itemcraft}
			}
		})
	end
end


---------- Bows -----------
function throwing.register_bow(name, itemcraft, description, texture, groups)
	minetest.register_tool(throwing.modname..":"..name, {
		description = description,
		inventory_image = texture,
		on_use = function(itemstack, user, pointed_thing)
			if shoot_arrow(itemstack, user, pointed_thing) then
				if not minetest.setting_getbool("creative_mode") then
					itemstack:add_wear(65535/30)
				end
			end
			return itemstack
		end,
		groups = groups
	})

	if itemcraft then
		minetest.register_craft({
			output = throwing.modname..":"..name,
			recipe = {
				{"farming:cotton", itemcraft, ""},
				{"farming:cotton", "", itemcraft},
				{"farming:cotton", itemcraft, ""},
			}
		})
	end
end


dofile(minetest.get_modpath(throwing.modname).."/registration.lua")
