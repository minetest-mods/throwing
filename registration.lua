throwing.register_bow("bow_wood", "default:wood", "Wooden Bow", "throwing_bow_wood.png")
throwing.register_bow("bow_stone", "default:cobble", "Stone Bow", "throwing_bow_stone.png")
throwing.register_bow("bow_steel", "default:steel_ingot", "Steel Bow", "throwing_bow_steel.png")
throwing.register_bow("bow_bronze", "default:bronze_ingot", "Bronze Bow", "throwing_bow_bronze.png")
throwing.register_bow("bow_mese", "default:mese_crystal", "Mese Bow", "throwing_bow_mese.png")
throwing.register_bow("bow_diamond", "default:diamond", "Diamond Bow", "throwing_bow_diamond.png")

local function get_setting(name)
	local value = minetest.setting_getbool("throwing.enable_"..name)
	if value == true or value == nil then
		return true
	else
		return false
	end
end

if get_setting("arrow") then
	throwing.register_arrow("arrow", "default:steel_ingot", 16, "Arrow",
	  {"throwing_arrow.png", "throwing_arrow.png", "throwing_arrow_back.png", "throwing_arrow_front.png", "throwing_arrow_2.png", "throwing_arrow.png"}, "throwing_arrow",
	  function(pos, _, _, object, hitter)
		if not object then
			return
		end
		object:punch(hitter, 1, {
			full_punch_interval = 1,
			damage_groups = {fleshy = 3}
		})
	end)
end

if get_setting("golden_arrow") then
	throwing.register_arrow("arrow_gold", "default:gold_ingot", 16, "Golden Arrow",
	  {"throwing_arrow_gold.png", "throwing_arrow_gold.png", "throwing_arrow_gold_back.png", "throwing_arrow_gold_front.png", "throwing_arrow_gold_2.png", "throwing_arrow_gold.png"}, "throwing_arrow",
	  function(pos, _, _, object, hitter)
		if not object then
			return
		end
		object:punch(hitter, 1, {
			full_punch_interval = 1,
			damage_groups = {fleshy = 5}
		})
	end)
end

if get_setting("dig_arrow") then
	throwing.register_arrow("arrow_dig", "default:pick_wood", 1, "Dig Arrow",
	  {"throwing_arrow_dig.png", "throwing_arrow_dig.png", "throwing_arrow_dig_back.png", "throwing_arrow_dig_front.png", "throwing_arrow_dig_2.png", "throwing_arrow_dig.png"}, "throwing_dig_arrow",
	  function(pos, _, node, _, _)
		if not node then
			return
		end
		if minetest.is_protected(pos) then
			return false, "Area is protected"
		end
		return minetest.dig_node(pos)
	end)
end

if get_setting("dig_arrow_admin") then
	throwing.register_arrow("arrow_dig_admin", nil, nil, "Admin Dig Arrow",
	  {"throwing_arrow_dig.png", "throwing_arrow_dig.png", "throwing_arrow_dig_back.png", "throwing_arrow_dig_front.png", "throwing_arrow_dig_2.png", "throwing_arrow_dig.png"}, nil,
	  function(pos, _, node, _, _)
		if not node then
			return
		end
		minetest.remove_node(pos)
	end, {not_in_creative_inventory = 1})
end

if get_setting("teleport_arrow") then
	throwing.register_arrow("arrow_teleport", "default:diamond", 1, "Teleport Arrow",
	  {"throwing_arrow_teleport.png", "throwing_arrow_teleport.png", "throwing_arrow_teleport_back.png", "throwing_arrow_teleport_front.png", "throwing_arrow_teleport_2.png", "throwing_arrow_teleport.png"}, "throwing_teleport_arrow",
	  function(_, last_pos, node, _, hitter)
		if not node then
			return
		end
		if minetest.get_node(last_pos).name ~= "air" then
			minetest.log("warning", "[throwing] BUG: node at last_pos was not air")
			return
		end

		hitter:moveto(last_pos)
	end)
end

if get_setting("fire_arrow") then
	throwing.register_arrow("arrow_fire", "default:torch", 1, "Torch Arrow",
	  {"throwing_arrow_fire.png", "throwing_arrow_fire.png", "throwing_arrow_fire_back.png", "throwing_arrow_fire_front.png", "throwing_arrow_fire_2.png", "throwing_arrow_fire.png"}, "default_place_node",
	  function(_, last_pos, node, _, hitter)
		if not node then
			return
		end
		if minetest.get_node(last_pos).name ~= "air" then
			minetest.log("warning", "[throwing] BUG: node at last_pos was not air")
			return
		end

		local under_node_name = minetest.get_node({x = last_pos.x, y = last_pos.y-1, z = last_pos.z}).name
		if under_node_name ~= "air" and name ~= "ignore" then
			minetest.place_node(last_pos, {name="default:torch"})
		else
			return false, "Attached node default:torch can not be placed"
		end
	end)
end

if get_setting("build_arrow") then
	throwing.register_arrow("arrow_build", "default:obsidian_glass", 1, "Build Arrow",
	  {"throwing_arrow_build.png", "throwing_arrow_build.png", "throwing_arrow_build_back.png", "throwing_arrow_build_front.png", "throwing_arrow_build_2.png", "throwing_arrow_build.png"}, "throwing_build_arrow",
	  function(_, last_pos, node, _, _)
		if not node then
			return
		end
		if minetest.get_node(last_pos).name ~= "air" then
			minetest.log("warning", "[throwing] BUG: node at last_pos was not air")
			return
		end
		if minetest.is_protected(last_pos) then
			return false, "Area is protected"
		end
		return minetest.place_node(last_pos, {name="default:obsidian_glass"})
	end)
end
