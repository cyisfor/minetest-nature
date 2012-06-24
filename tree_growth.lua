-- Tree growing

dofile(minetest.get_modpath("nature") .. "/trees.lua")
dofile(minetest.get_modpath("nature") .. "/seasons.lua")

local ABM_DELAY = 7200
local ABM_CHANCE = 20

local TREE_GROW_DELAY = ABM_DELAY
local DENSITY = 3 -- allow <number> trunks in the radius
local MINIMUM_LIGHT = 8 -- light needed for the trees to grow

function groundIsClose(pos) 
   -- 8 trunks tall max
   for y = 3,8,1 do
      local node = minetest.env:get_node({x=pos.x,y=pos.y-y,z=pos.z})
      if math.random(2)==1 then 
         -- a chance for trees to fail to grow even if ground is within limit
         -- 1/2 at 3 (1/2)**2 at 4, etc.
         return false
      end
      -- stuff that could be in trees
      if not (node.groups.leaves or
              node.name == "air" or 
              node.name == "default:jungletree" or 
              node.name == "default:tree" or
              node.name == "default:apple" or
              node.name == "default:blossom"
        ) then
         return true
      end
   end
   return false
end

function growTrunk(pos, node, active_object_count, active_object_count_wider)
   if(minetest.env:get_node_light(pos, nil) < MINIMUM_LIGHT) then
      return
   end

   local trunk_found = 0
   local jungle_trunk_found = 0
   
   -- Check for trunks below
   local current_node = {
      x = pos.x    ,
      y = pos.y - 1,
      z = pos.z
   }
   if(minetest.env:get_node(current_node).name == "default:tree") then
      trunk_found = true
   elseif (minetest.env:get_node(current_node).name ==
        "default:jungletree") then
      jungle_trunk_found = true
   end

   if ( trunk_found or jungle_trunk_found ) and groundIsClose(pos) then
      minetest.env:remove_node(pos)
      
      if(trunk_found) then
         minetest.env:add_node(pos, {name = "default:tree"})
      else
         minetest.env:add_node(pos, {name = "default:jungletree"})
      end
      print ('[nature] A trunk has grown at (' .. pos.x .. ',' .. pos.y .. ',' .. pos.z .. ')')
      for i = -1, 1 do
         for j = -1, 1 do
            for k = -1, 1 do
               local current_node = {
                  x = pos.x + i,
                  y = pos.y + j,
                  z = pos.z + k
               }
               if(minetest.env:get_node(current_node).name == "air") then
                  minetest.env:add_node(current_node, {name = seasonal("leaves")})
               end
            end
         end
      end
   end
end

minetest.register_abm(
   {
      nodenames = { "groupx:leaves" },
      interval = TREE_GROW_DELAY,
      chance = ABM_CHANCE,      
      action = growTrunk,
})
