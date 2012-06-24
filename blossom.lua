-- Blossom

local BLOSSOM_CHANCE = 1
local BLOSSOM_DELAY = 600
local APPLE_SPAWN_CHANCE = 20

minetest.register_node("nature:blossom", {
    description = "Blossom",
    drawtype = "allfaces_optional",
    tiles = { "default_leaves.png^nature_blossom.png" },
    paramtype = "light",
    groups = { snappy = 3, leafdecay = 3, flammable=3 },
    sounds = default.node_sound_leaves_defaults(),
    drop = {
         max_items = 1,
         items = {
			{
				-- player will get sapling with 1/20 chance
				items = {'default:sapling'},
				rarity = 20,
			},
			{
				-- player will get leaves only if he get no saplings,
				-- this is because max_items is 1
                                -- drop the name of the item to destroy it utterly (see default/leafdecay.lua)
				items = {'nature:blossom'},
			}                        
                 }                     
    }
})

minetest.register_craft({
    type = "fuel",
    recipe = "nature:blossom",
    burntime = 1,
})

-- Apples growing
minetest.register_abm({
    nodenames = { "nature:blossom" },
    interval = BLOSSOM_DELAY,
    chance = BLOSSOM_CHANCE,

    action = function(pos, node, active_object_count, active_object_count_wider)
        minetest.env:remove_node(pos)
        minetest.env:add_node(pos, { name = "default:leaves" })
	-- Drop and apple
	if (math.random (1, 100) > APPLE_SPAWN_CHANCE) then
	    return
	end
	local below = {
	    x = pos.x,
	    y = pos.y - 1,
	    z = pos.z,
	}
	if minetest.env:get_node(below).name == "air" then
	    minetest.env:add_node(below, { name = "default:apple" })
	end
    end
})
