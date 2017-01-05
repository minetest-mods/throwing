throwing = {}

throwing.arrows = {}

local modname = minetest.get_current_modname()

--------- Arrows functions ---------
local function shoot_arrow(itemstack, player)
	for _,arrow in ipairs(throwing.arrows) do
		if player:get_inventory():get_stack("main", player:get_wield_index()+1):get_name() == arrow then
			if not minetest.setting_getbool("creative_mode") then
				player:get_inventory():remove_item("main", arrow[1])
			end
			local playerpos = player:getpos()
			local obj = minetest.add_entity({x=playerpos.x,y=playerpos.y+1.5,z=playerpos.z}, arrow.."_entity")
			local dir = player:get_look_dir()
			obj:setvelocity({x=dir.x*19, y=dir.y*19, z=dir.z*19})
			obj:setacceleration({x=dir.x*-3, y=-10, z=dir.z*-3})
			obj:setyaw(player:get_look_yaw()+math.pi)
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
		self.object:remove()

		if obj then
			if obj:is_player() then
				if self.timer > 0.2 and obj:get_playername() == self.player then -- Avoid hitting the hitter
					return
				end
			end
		end

		if node and minetest.is_protected(pos, self.player) then -- Forbid hitting nodes in protected areas
			return
		end

		local player = minetest.get_player_by_name(self.player)
		if not player then -- Possible if the player disconnected
			return
		end
		self.on_hit(pos, self.last_pos, node, obj, player)
		if self.on_hit_sound then
			minetest.sound_play(self.on_hit_sound, {pos = pos, gain = 0.8})
		end
		if node then
			logging("collided with node "..node.name.." at ("..pos.x..","..pos.y..","..pos.z..")")
		elseif obj then
			if obj:get_luaentity() then
				logging("collided with luaentity "..obj:get_luaentity().name.." at ("..pos.x..","..pos.y..","..pos.z..")")
			elseif obj:is_player() then
				logging("collided with player "..obj:get_playername().." at ("..pos.x..","..pos.y..","..pos.z..")")
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
]]
function throwing.register_arrow(name, itemcraft, craft_quantity, description, tiles, on_hit_sound, on_hit, groups)
	table.insert(throwing.arrows, modname..":"..name)

	minetest.register_node(modname..":"..name, {
		drawtype = "nodebox",
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
		groups = groups
	})

	minetest.register_entity(modname..":"..name.."_entity", {
		physical = false,
		timer = 0,
		visual = "wielditem",
		visual_size = {x = 0.125, y = 0.125},
		textures = {modname..":"..name},
		collisionbox = {0, 0, 0, 0, 0, 0},
		on_hit = on_hit,
		on_hit_sound = on_hit_sound,
		node = modname..":"..name,
		player = "",
		on_step = arrow_step
	})

	if itemcraft then
		minetest.register_craft({
			output = modname..":"..name.." "..craft_quantity,
			recipe = {
				{itemcraft, "default:stick", "default:stick"}
			}
		})
		minetest.register_craft({
			output = modname..":"..name.." "..craft_quantity,
			recipe = {
				{ "default:stick", "default:stick", itemcraft}
			}
		})
	end
end


---------- Bows -----------
function throwing.register_bow(name, itemcraft, description, texture, groups)
	minetest.register_tool(modname..":"..name, {
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
			output = modname..":"..name,
			recipe = {
				{"farming:cotton", itemcraft, ""},
				{"farming:cotton", "", itemcraft},
				{"farming:cotton", itemcraft, ""},
			}
		})
	end
end


dofile(minetest.get_modpath(modname).."/registration.lua")
