throwing = {}

throwing.arrows = {}

throwing.target_object = 1
throwing.target_node = 2
throwing.target_both = 3

throwing.modname = minetest.get_current_modname()

--------- Arrows functions ---------
local function shoot_arrow(itemstack, player)
	for _,arrow in ipairs(throwing.arrows) do
		if player:get_inventory():get_stack("main", player:get_wield_index()+1):get_name() == arrow then
			local playerpos = player:getpos()
			local pos = {x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}
			local obj = minetest.add_entity(pos, arrow.."_entity")

			local luaentity = obj:get_luaentity()
			luaentity.player = player:get_player_name()

			if luaentity.on_throw then
				if luaentity.on_throw(pos, player, luaentity) == false then
					return false
				end
			end

			local dir = player:get_look_dir()
			local velocity_factor = tonumber(minetest.setting_get("throwing.velocity_factor")) or 19
			local horizontal_acceleration_factor = tonumber(minetest.setting_get("throwing.horizontal_acceleration_factor")) or -3
			local vertical_acceleration = tonumber(minetest.setting_get("throwing.vertical_acceleration")) or -10

			obj:setvelocity({x=dir.x*velocity_factor, y=dir.y*velocity_factor, z=dir.z*velocity_factor})
			obj:setacceleration({x=dir.x*horizontal_acceleration_factor, y=vertical_acceleration, z=dir.z*horizontal_acceleration_factor})
			obj:setyaw(player:get_look_horizontal()-math.pi/2)

			if luaentity.on_throw_sound ~= "" then
				minetest.sound_play(luaentity.on_throw_sound or "throwing_sound", {pos=playerpos, gain = 0.5})
			end

			if not minetest.setting_getbool("creative_mode") then
				player:get_inventory():remove_item("main", arrow)
			end

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
					return false
				end
			end
		end

		local player = minetest.get_player_by_name(self.player)
		if not player then -- Possible if the player disconnected
			return
		end

		local function put_arrow_back()
			if not minetest.setting_getbool("creative_mode") then
				player:get_inventory():add_item("main", self.node)
			end
		end

		if not self.last_pos then
			logging("hitted a node during its first call to the step function")
			put_arrow_back()
			return
		end

		if node and minetest.is_protected(pos, self.player) then -- Forbid hitting nodes in protected areas
			minetest.record_protection_violation(pos, self.player)
			logging("hitted a node into a protected area")
			return
		end

		local ret, reason = self.on_hit(pos, self.last_pos, node, obj, player, self)
		if ret == false then
			if reason then
				logging(": on_hit function failed for reason: "..reason)
			else
				logging(": on_hit function failed")
			end

			put_arrow_back()
			return
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
		if self.target ~= throwing.target_object then -- throwing.target_both, nil, throwing.target_node, or any invalid value
			if hit(pos, node, nil) ~= false then
				self.object:remove()
			end
		else
			self.object:remove()
		end
		return
	end

	-- Collision with an object
	local objs = minetest.get_objects_inside_radius(pos, 1)
	for k, obj in pairs(objs) do
		if obj:get_luaentity() then
			if obj:get_luaentity().name ~= self.name and obj:get_luaentity().name ~= "__builtin:item" then
				if self.target ~= throwing.target_node then -- throwing.target_both, nil, throwing.target_object, or any invalid value
					if hit(pos, nil, obj) ~= false then
						self.object:remove()
					end
				else
					self.object:remove()
				end
			end
		else
			if self.target ~= throwing.target_node then -- throwing.target_both, nil, throwing.target_object, or any invalid value
				if hit(pos, nil, obj) ~= false then
					self.object:remove()
				end
			else
				self.object:remove()
			end
		end
	end


	self.last_pos = pos -- Used by the build arrow
end

--[[
on_hit(pos, last_pos, node, object, hitter)
Either node or object is nil, depending whether the arrow collided with an object (luaentity or player) or with a node.
No log message is needed in this function (a generic log message is automatically emitted), except on error or warning.
Should return false or false, reason on failure.

on_throw(pos, hitter)
Unlike on_hit, it is optional.
]]
function throwing.register_arrow(name, def)
	table.insert(throwing.arrows, throwing.modname..":"..name)

	local groups = {dig_immediate = 3}
	if def.groups then
		for k, v in pairs(def.groups) do
			groups[k] = v
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
		tiles = def.tiles,
		inventory_image = def.tiles[1],
		description = def.description,
		groups = groups,
		on_place = function(itemstack, placer, pointed_thing)
			if minetest.setting_getbool("throwing.allow_arrow_placing") and pointed_thing.above then
				local playername = placer:get_player_name()
				if not minetest.is_protected(pointed_thing.above, playername) then
					minetest.log("action", "Player "..playername.." placed arrow "..throwing.modname..":"..name.." at ("..pointed_thing.above.x..","..pointed_thing.above.y..","..pointed_thing.above.z..")")
					minetest.set_node(pointed_thing.above, {name = throwing.modname..":"..name})
					itemstack:take_item()
					return itemstack
				else
					minetest.log("warning", "Player "..playername.." tried to place arrow "..throwing.modname..":"..name.." into a protected area at ("..pointed_thing.above.x..","..pointed_thing.above.y..","..pointed_thing.above.z..")")
					minetest.record_protection_violation(pointed_thing.above, playername)
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
		on_hit = def.on_hit,
		on_hit_sound = def.on_hit_sound,
		on_throw_sound = def.on_throw_sound,
		on_throw = def.on_throw,
		target = def.target,
		node = throwing.modname..":"..name,
		player = "",
		on_step = arrow_step
	})

	if def.itemcraft then
		minetest.register_craft({
			output = throwing.modname..":"..name.." "..tostring(def.craft_quantity or 1),
			recipe = {
				{def.itemcraft, "default:stick", "default:stick"}
			}
		})
		minetest.register_craft({
			output = throwing.modname..":"..name.." "..tostring(def.craft_quantity or 1),
			recipe = {
				{ "default:stick", "default:stick", def.itemcraft}
			}
		})
	end
end


---------- Bows -----------
function throwing.register_bow(name, def)
	minetest.register_tool(throwing.modname..":"..name, {
		description = def.description,
		inventory_image = def.texture,
		on_use = function(itemstack, user, pointed_thing)
			if shoot_arrow(itemstack, user, pointed_thing) then
				if not minetest.setting_getbool("creative_mode") then
					itemstack:add_wear(65535/30)
				end
			end
			return itemstack
		end,
		groups = def.groups
	})

	if def.itemcraft then
		minetest.register_craft({
			output = throwing.modname..":"..name,
			recipe = {
				{"farming:cotton", def.itemcraft, ""},
				{"farming:cotton", "", def.itemcraft},
				{"farming:cotton", def.itemcraft, ""},
			}
		})
	end
end


dofile(minetest.get_modpath(throwing.modname).."/registration.lua")
