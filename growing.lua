local inspect = minetest.require("__builtin","inspect")

local plants = {}
local growingPlants = {}

local M = {
   add = function(name) 
            if growingPlants[name] == true then return end
            table.insert(plants,name)
            growingPlants[name] = true
         end,
   grows = function(name)
              return growingPlants[name] == true
           end,
   growInterval = 600,
   abiochance = 60,
   deathchance = 100,
   perlin = nil,
}

local function start()
   print("growing plants are")
   for i,n in ipairs(plants) do
      print("  "..n)
   end
   minetest.register_abm(
      {
         nodenames = { "default:dirt_with_grass",'nature:grass_spring' },
         interval = M.growInterval,
         chance = M.abiochance,
         action = 
            function(pos, node, active_object_count, active_object_count_wider)
               if M.perlin == nil then
                  -- can't use minetest.env outside of handlers...
                  M.perlin = minetest.env:get_perlin(
                     math.random(100000000), 
                     3, 
                     0.7, 
                     20)
               end
               local air = { x=pos.x, y=pos.y+1,z=pos.z }
               local is_air = minetest.env:get_node_or_nil(air)
               if is_air ~= nil and is_air.name == 'air' then
                  local count = table.getn(plants)
                  local random_plant = math.floor((M.perlin:get3d(pos)+1) / 2 * count)
                  if random_plant <= 0 then
                     random_plant = 1
                  elseif random_plant > count then
                     random_plant = count
                  end
                  minetest.env:add_node({x=pos.x,y=pos.y+1,z=pos.z},{type="node",name=plants[random_plant]})
               end
            end
      })

   minetest.register_abm(
      {
         nodenames = plants,
         interval = M.growInterval,
         chance = M.deathchance,
         action = function(pos, node, active_object_count, active_object_count_wider)
                     minetest.env:remove_node({x=pos.x,y=pos.y,z=pos.z})
                  end
      })
end

local postinit = minetest.require("__builtin","postinit")
postinit.push(start,"growing")

return M