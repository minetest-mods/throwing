# Throwing

## Developped by the Mynetest team

This mod is a new rewrite of the original throwing mod by PilzAdam. Compatible replacement for it.

## Configuration

The settings are the following:
```
throwing.enable_arrow = true
throwing.enable_golden_arrow = true
throwing.enable_fire_arrow = true
throwing.enable_teleport_arrow = true
throwing.enable_dig_arrow = true
throwing.enable_dig_arrow_admin = true
throwing.enable_build_arrow = true

throwing.velocity_factor = 19
throwing.horizontal_acceleration_factor = -3
throwing.vertical_acceleration = -10
```

## API

There are two available functions in the mod API:
```lua
function throwing.register_bow(name, itemcraft, description, texture[, groups])
--[[
Name: Bow name (in second part of the itemstring).
Itemcraft: item used to craft the bow (nil if uncraftable).
Description: Description of the bow.
Texture: Texture of the bow, shown in inventory.
Groups: optional groups.
]]

-- Example:
throwing.register_bow("bow_stone", "default:cobble", "Stone Bow", "throwing_bow_stone.png")


function throwing.register_arrow(name, itemcraft, craft_quantity, description, tiles, on_hit_sound, on_hit[, groups])
--[[
Name: Arrow name (in second part of the itemstring).
Itemcraft: item used to craft the arrow (nil if uncraftable).
Craft_quantity: quantity of arrows in the craft output.
Tiles: tiles of the arrow.
On_hit_sound: sound played when the arrow hits a node or an object (nil if no sound).
On_hit: callback function: on_hit(pos, last_pos, node, object, hitter) where:
   * Pos: the position of the hitted node or object
   * Last_pos: the last air node where the arrow was (used by the build_arrow, for example)
   * Node and object: hitted node or object. Either node or object is nil, depending
     whether the arrow hitted a node or an object (you should always check for that).
     An object can be a player or a luaentity.
   * Hitter: the ObjectRef of the player who throwed the arrow.
]]

-- Examples:
throwing.register_arrow("arrow_gold", "default:gold_ingot", 16, "Golden Arrow",
{"throwing_arrow_gold.png", "throwing_arrow_gold.png", "throwing_arrow_gold_back.png", "throwing_arrow_gold_front.png", "throwing_arrow_gold_2.png", "throwing_arrow_gold.png"}, "throwing_arrow",
function(pos, last_pos, node, object, hitter)
	if not object then
		return
	end
	object:punch(minetest.get_player_by_name(hitter), 1, {
		full_punch_interval = 1,
		damage_groups = {fleshy = 5}
	})
end)
throwing.register_arrow("arrow_build", "default:obsidian_glass", 1, "Build Arrow",
{"throwing_arrow_build.png", "throwing_arrow_build.png", "throwing_arrow_build_back.png", "throwing_arrow_build_front.png", "throwing_arrow_build_2.png", "throwing_arrow_build.png"}, "throwing_build_arrow",
function(pos, last_pos, node, object, hitter)
	if not node then
		return
	end
	minetest.set_node(last_pos, {name="default:obsidian_glass"})
end)
```
