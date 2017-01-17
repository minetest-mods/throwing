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

throwing.allow_arrow_placing = false
```

## API

There are two available functions in the mod API:
```lua
function throwing.register_bow(name, definition)
--[[
Name: Bow name (in second part of the itemstring).
Definition: definition table, containing:
  * itemcraft (optional, you may want to register your own craft or to make the bow uncraftable): item used to craft the bow.
  * description (highly recommended): description of the bow.
  * texture (essential): texture of the bow, shown in inventory.
  * groups (optional): groups of the item.
]]

-- Example:
throwing.register_bow("bow_stone", "default:cobble", "Stone Bow", "throwing_bow_stone.png")

itemcraft, craft_quantity, description, tiles, on_hit_sound, on_hit[, on_throw[, groups]]
function throwing.register_arrow(name, definition table)
--[[
Name: Arrow name (in second part of the itemstring).
Definition: definition table, containing:
  * itemcraft (optional, you may want to register your own craft or to make the arrow uncraftable): item used to craft the arrow.
  * craft_quantity (optional, defaulting to 1 if itemcraft is non-nil, pointless otherwise): quantity of arrows in the craft output.
  * tiles (essential): tiles of the arrow.
  * target (optional, defaulting to throwing.target_both): what the arrow is able to hit (throwing.target_node, throwing.target_object, throwing.target_both).
  * on_hit_sound (optional): sound played when the arrow hits a node or an object.
  * on_hit (must exist, will crash if nil): callback function: on_hit(pos, last_pos, node, object, hitter, self):
    - pos: the position of the hit node or object.
    - last_pos: the last air node where the arrow was
    - node and object: hit node or object. Either node or object is nil, depending
      whether the arrow hit a node or an object.
    - hitter: an ObjectRef to the thrower player.
    - self: the arrow entity table (it allows you to hack a lot!)
    - If it fails, it should return:
      false[, reason]
  * on_throw (optional): callback function: on_throw(pos, thrower, next_itemstack, self):
    - pos: the position from where the arrow is throw (which a bit higher than the hitter position)
    - thrower: an ObjectRef to the thrower player
    - next_itemstack: the ItemStack next to the arrow in the "main" inventory
    - If the arrow shouldn't be throw, it should return false.
  * on_throw_sound (optional, there is a default sound, specify "" for no sound): sound to be played when the arrow is throw
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

        if minetest.is_protected(last_pos) then
                return false, "Area is protected"
        end
        return minetest.place_node(last_pos, {name="default:obsidian_glass"})
end)
```
