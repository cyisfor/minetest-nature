local like = minetest.require("madblocks","like")("nature")
local growing = minetest.require("nature","growing")
local seasons = minetest.require("nature","seasons")
local inspect = minetest.require("__builtin","inspect")

like.plant('slimtree','Slimtree Sapling','veg')

slimtreePlague = false

if slimtreePlague then
   minetest.register_abm(
      {
         nodenames = { "nature:slimtree_wood", "nature;slimtree" },
         interval = 10,
         chance = 1,
         action = 
            function(pos, node, active_object_count, active_object_count_wider)
               minetest.env:remove_node(pos)
            end
      })
else

   minetest.register_abm(
      {
         nodenames = { "nature:slimtree" },
         interval = growing.growInterval,
         chance = 10,
         
         action = function(pos, node, active_object_count, active_object_count_wider)
                     for dy = 0,3,1 do
                        minetest.env:add_node({x=pos.x,y=pos.y+dy,z=pos.z},{type="node",name="nature:slimtree_wood"})
                     end
                     for dx=-1,1,1 do
                        for dz = -1,1,1 do
                           for dy = 3,6,1 do
                              if not (dx == 0 and dz == 0 and dy == 3) then     

                                 local where = {x=pos.x+dx,y=pos.y+dy,z=pos.z+dz}
                                 local what = minetest.env:get_node_or_nil(where)
                                 if(what == nil or what.name == 'air') then
                                    minetest.env:add_node(
                                       where,
                                       {type="node",name=seasons.seasonal("leaves")})
                                 end
                              end
                           end
                        end
                     end
                  end
      })
   -- make sure these tiny trees don't eat the landscape
   -- by having their wood die (leaves die on their own)
   minetest.register_abm(
      {
         nodenames = { "nature:slimtree_wood" },
         interval = growing.growInterval*2,
         chance = 30,
         
         action = function(pos, node, active_object_count, active_object_count_wider)
                     -- make sure to remove the whole tree
                     -- part of a slimtree trunk w/ floating leaves above
                     -- ...looks silly
                     local name = node.name
                     minetest.env:remove_node(pos)
                     for sy = -1,1,2 do
                        for dy = 1,3 do
                           local where = {x=pos.x,y=pos.y+dy*sy,z=pos.z}
                           local what = minetest.env:get_node_or_nil(where)
                           if what and what.name == name then
                              minetest.env:remove_node(where)
                           else
                              break
                           end
                        end
                     end
                  end
      })

   like.plant('slimtree','Slimtree Sapling','veg')
   growing.add('nature:slimtree')
end

minetest.register_node(
   "nature:slimtree_wood", 
   {
      description = "Slimtree",
      drawtype = "fencelike",
      tile_images = {"nature_tree.png"},
      inventory_image = "nature_tree.png",
      wield_image = "nature_tree.png",
      paramtype = "light",
      is_ground_content = true,
      selection_box = {
         type = "fixed",
         fixed = {-1/7, -1/2, -1/7, 1/7, 1/2, 1/7},
      },
      groups = {tree=1,snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=2},
      sounds = default.node_sound_wood_defaults(),
      drop = 'default:fence_wood',
   })
