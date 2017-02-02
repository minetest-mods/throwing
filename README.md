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
throwing.register_bow("bow_wood", {
	itemcraft = "default:wood",
	description = "Wooden Bow",
	texture = "throwing_bow_wood.png"
})

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
  * on_hit(pos, last_pos, node, object, hitter, data, self) (must exist, will crash if nil): callback function:
    - pos: the position of the hit node or object.
    - last_pos: the last air node where the arrow was
    - node and object: hit node or object. Either node or object is nil, depending
      whether the arrow hit a node or an object.
    - hitter: an ObjectRef to the thrower player.
    - data: a data table associated to the entity where you can store what you want
    - self: the arrow entity table (it allows you to hack a lot!)
    - If it fails, it should return:
      false[, reason]
  * on_throw(pos, thrower, next_index, data, self) (optional): callback function: on_throw:
    - pos: the position from where the arrow is throw (which a bit higher than the hitter position)
    - thrower: an ObjectRef to the thrower player
    - next_index: the index next to the arrow in the "main" inventory
    - data: a data table associated to the entity where you can store what you want
    - self: the arrow entity table
    - If the arrow shouldn't be throw, it should return false.
  * on_throw_sound (optional, there is a default sound, specify "" for no sound): sound to be played when the arrow is throw
  * on_hit_fails(pos, thrower, data, self) (optional): callback function called if the hit failed (e.g. because on_hit returned false or because the area was protected)
]]

-- Example:
throwing.register_arrow("arrow", {
	itemcraft = "default:steel_ingot",
	craft_quantity = 16,
	description = "Arrow",
	tiles = {"throwing_arrow.png", "throwing_arrow.png", "throwing_arrow_back.png", "throwing_arrow_front.png", "throwing_arrow_2.png", "throwing_arrow.png"},
	target = throwing.target_object,
	on_hit_sound = "throwing_arrow",
	on_hit = function(pos, _, _, object, hitter)
		object:punch(hitter, 1, {
			full_punch_interval = 1,
			damage_groups = {fleshy = 3}
		})
	end
})
```
