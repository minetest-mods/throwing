throwing.register_bow(":throwing:bow_wood", {
	itemcraft = "default:wood",
	description = "Wooden Bow",
	texture = "throwing_bow_wood.png",
	uses = 50
})
throwing.register_bow(":throwing:bow_stone", {
	itemcraft = "default:cobble",
	description = "Stone Bow",
	texture = "throwing_bow_stone.png",
	uses = 100
})
throwing.register_bow(":throwing:bow_steel", {
	itemcraft = "default:steel_ingot",
	description = "Steel Bow",
	texture = "throwing_bow_steel.png",
	uses = 150
})
throwing.register_bow(":throwing:bow_bronze", {
	itemcraft = "default:bronze_ingot",
	description = "Bronze Bow",
	texture = "throwing_bow_bronze.png",
	uses = 200
})
throwing.register_bow(":throwing:bow_gold", {
	itemcraft = "default:gold_ingot",
	description = "Gold Bow",
	texture = "throwing_bow_gold.png",
	uses = 250
})
throwing.register_bow(":throwing:bow_mese", {
	itemcraft = "default:mese_crystal",
	description = "Mese Bow",
	texture = "throwing_bow_mese.png",
	uses = 300
})
throwing.register_bow(":throwing:bow_diamond", {
	itemcraft = "default:diamond",
	description = "Diamond Bow",
	texture = "throwing_bow_diamond.png",
	uses = 320
})

local function get_setting(name)
	local value = minetest.settings:get_bool("throwing.enable_"..name)
	if value == true or value == nil then
		return true
	else
		return false
	end
end

if get_setting("arrow") then
	throwing.register_arrow("throwing:arrow", {
		itemcraft = "default:steel_ingot",
		craft_quantity = 16,
		description = "Arrow",
		tiles = {"throwing_arrow.png", "throwing_arrow.png", "throwing_arrow_back.png", "throwing_arrow_front.png", "throwing_arrow_2.png", "throwing_arrow.png"},
		target = throwing.target_both,
		allow_protected = true,
		on_hit_sound = "throwing_arrow",
		on_hit = function(self, pos, _, node, object, hitter)
			if object then
				object:punch(hitter, 1, {
					full_punch_interval = 1,
					damage_groups = {fleshy = 3}
				})
			elseif node then
				if node.name == "mesecons_button:button_off" and minetest.get_modpath("mesecons_button") and minetest.get_modpath("mesecons") then
					minetest.registered_items["mesecons_button:button_off"].on_rightclick(vector.round(pos), node)
				end
			end
		end
	})
end

if get_setting("golden_arrow") then
	throwing.register_arrow("throwing:arrow_gold", {
		itemcraft = "default:gold_ingot",
		craft_quantity = 16,
		description = "Golden Arrow",
		tiles = {"throwing_arrow_gold.png", "throwing_arrow_gold.png", "throwing_arrow_gold_back.png", "throwing_arrow_gold_front.png", "throwing_arrow_gold_2.png", "throwing_arrow_gold.png"},
		target = throwing.target_object,
		allow_protected = true,
		on_hit_sound = "throwing_arrow",
		on_hit = function(self, pos, _, _, object, hitter)
			object:punch(hitter, 1, {
				full_punch_interval = 1,
				damage_groups = {fleshy = 5}
			})
		end
	})
end

if get_setting("dig_arrow") then
	throwing.register_arrow("throwing:arrow_dig", {
		itemcraft = "default:pick_wood",
		description = "Dig Arrow",
		tiles = {"throwing_arrow_dig.png", "throwing_arrow_dig.png", "throwing_arrow_dig_back.png", "throwing_arrow_dig_front.png", "throwing_arrow_dig_2.png", "throwing_arrow_dig.png"},
		target = throwing.target_node,
		on_hit_sound = "throwing_dig_arrow",
		on_hit = function(self, pos, _, node, _, hitter)
			return minetest.dig_node(pos)
		end
	})
end

if get_setting("dig_arrow_admin") then
	throwing.register_arrow("throwing:arrow_dig_admin", {
		description = "Admin Dig Arrow",
		tiles = {"throwing_arrow_dig.png", "throwing_arrow_dig.png", "throwing_arrow_dig_back.png", "throwing_arrow_dig_front.png", "throwing_arrow_dig_2.png", "throwing_arrow_dig.png"},
		target = throwing.target_node,
		on_hit = function(self, pos, _, node, _, _)
			minetest.remove_node(pos)
		end,
		groups = {not_in_creative_inventory = 1}
	})
end

if get_setting("teleport_arrow") then
	throwing.register_arrow("throwing:arrow_teleport", {
		itemcraft = "default:diamond",
		description = "Teleport Arrow",
		tiles = {"throwing_arrow_teleport.png", "throwing_arrow_teleport.png", "throwing_arrow_teleport_back.png", "throwing_arrow_teleport_front.png", "throwing_arrow_teleport_2.png", "throwing_arrow_teleport.png"},
		allow_protected = true,
		on_hit_sound = "throwing_teleport_arrow",
		on_hit = function(self, _, last_pos, _, _, hitter)
			if minetest.get_node(last_pos).name ~= "air" then
				minetest.log("warning", "[throwing] BUG: node at last_pos was not air")
				return
			end

			if minetest.setting_getbool("throwing.allow_teleport_in_protected") == false then
				return false
			end

			hitter:moveto(last_pos)
		end
	})
end

if get_setting("fire_arrow") then
	throwing.register_arrow("throwing:arrow_fire", {
		itemcraft = "default:torch",
		description = "Torch Arrow",
		tiles = {"throwing_arrow_fire.png", "throwing_arrow_fire.png", "throwing_arrow_fire_back.png", "throwing_arrow_fire_front.png", "throwing_arrow_fire_2.png", "throwing_arrow_fire.png"},
		on_hit_sound = "default_place_node",
		on_hit = function(self, pos, last_pos, _, _, hitter)
			if minetest.get_node(last_pos).name ~= "air" then
				minetest.log("warning", "[throwing] BUG: node at last_pos was not air")
				return
			end

			local r_pos = vector.round(pos)
			local r_last_pos = vector.round(last_pos)
			-- Make sure that only one key is different
			if r_pos.y ~= r_last_pos.y then
				r_last_pos.x = r_pos.x
				r_last_pos.z = r_pos.z
			elseif r_pos.x ~= r_last_pos.x then
				r_last_pos.y = r_pos.y
				r_last_pos.z = r_pos.z
			end
			minetest.registered_items["default:torch"].on_place(ItemStack("default:torch"), hitter,
					{type="node", under=r_pos, above=r_last_pos})
		end
	})
end

if get_setting("build_arrow") then
	throwing.register_arrow("throwing:arrow_build", {
		itemcraft = "default:obsidian_glass",
		description = "Build Arrow",
		tiles = {"throwing_arrow_build.png", "throwing_arrow_build.png", "throwing_arrow_build_back.png", "throwing_arrow_build_front.png", "throwing_arrow_build_2.png", "throwing_arrow_build.png"},
		on_hit_sound = "throwing_build_arrow",
		on_hit = function(self, pos, last_pos, _, _, hitter)
			if minetest.get_node(last_pos).name ~= "air" then
				minetest.log("warning", "[throwing] BUG: node at last_pos was not air")
				return
			end

			local r_pos = vector.round(pos)
			local r_last_pos = vector.round(last_pos)
			-- Make sure that only one key is different
			if r_pos.y ~= r_last_pos.y then
				r_last_pos.x = r_pos.x
				r_last_pos.z = r_pos.z
			elseif r_pos.x ~= r_last_pos.x then
				r_last_pos.y = r_pos.y
				r_last_pos.z = r_pos.z
			end
			minetest.registered_items["default:obsidian_glass"].on_place(ItemStack("default:obsidian_glass"), hitter,
					{type="node", under=r_pos, above=r_last_pos})
		end
	})
end

if get_setting("drop_arrow") then
	throwing.register_arrow("throwing:arrow_drop", {
		itemcraft = "default:copper_ingot",
		craft_quantity = 16,
		description = "Drop Arrow",
		tiles = {"throwing_arrow_drop.png", "throwing_arrow_drop.png", "throwing_arrow_drop_back.png", "throwing_arrow_drop_front.png", "throwing_arrow_drop_2.png", "throwing_arrow_drop.png"},
		on_hit_sound = "throwing_build_arrow",
		allow_protected = true,
		on_throw = function(self, _, thrower, _, index, data)
			local inventory = thrower:get_inventory()
			if index >= inventory:get_size("main") or inventory:get_stack("main", index+1):get_name() == "" then
				return false, "nothing to drop"
			end
			data.itemstack = inventory:get_stack("main", index+1)
			data.index = index+1
			thrower:get_inventory():set_stack("main", index+1, nil)
		end,
		on_hit = function(self, _, last_pos, _, _, hitter, data)
			minetest.item_drop(ItemStack(data.itemstack), hitter, last_pos)
		end,
		on_hit_fails = function(self, _, thrower, data)
			if not minetest.setting_getbool("creative_mode") then
				thrower:get_inventory():set_stack("main", data.index, data.itemstack)
			end
		end
	})
end
