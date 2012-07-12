local inspect = minetest.require("__builtin","inspect")

local plants = {}
local growingPlants = {}
local willGrows = {}

local M = {
   add = function(name,growCondition)
            if growingPlants[name] == true then return end
            table.insert(plants,name)
            growingPlants[name] = true
            willGrows[name] = willGrow
         end,
   grows = function(name)
              return growingPlants[name] == true
           end,
   growInterval = 600,
   abiochance = 60,
   deathchance = 120,
   perlin = nil,
}

local function wild(pos) 
   return true
--   return minetest.env:get_meta(pos):get_int('wild')==1
end

local function start()
   print("growing plants are")
   for i,n in ipairs(plants) do
      print("  "..n)
   end
   minetest.register_abm(
      {
         nodenames = { "default:dirt_with_grass",'nature:grass_spring' },
         interval = M.growInterval,
         chance = 10,
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
               local offset = (M.perlin:getnoise2d({x=pos.x,y=pos.z})+1)/2
               local wobble = (math.random() - 0.5) * 0.1 + 1
               local period = M.growInterval
               local status = math.sin((os.time()/period + offset)*math.pi*2*wobble)
               local probability = math.abs(status)
               if(math.random()<probability) then
                  local dead = status < 0
                  local abovepos = { x=pos.x, y=pos.y+1,z=pos.z }
                  local above = minetest.env:get_node_or_nil(abovepos)
                  if above and dead then
                     if growingPlants[above.name] and wild(abovepos) then
                        -- kill it!
                        minetest.env:remove_node(abovepos)
                     end
                  elseif above == nil or above.name == 'air' then
                     local count = table.getn(plants)
                     local random_plant = math.floor(
                        (M.perlin:get3d(pos)+1) / 2 * count)
                     if random_plant <= 0 then
                        random_plant = 1
                     elseif random_plant > count then
                        random_plant = count
                     end
                     random_plant = plants[random_plant]
                     local wg = willGrows[random_plant]
                     if wg == nil or wg(abovepos) then
                        minetest.env:add_node(abovepos,{type="node",name=random_plant})
                        minetest.env:get_meta(abovepos):set_int('wild',1)
                     end
                  end
               end
            end
      })

   minetest.register_abm(
      {
         nodenames = { "nature:grass_winter" },
         interval = M.growInterval,
         chance = 5,
         action = function(pos, node, active_object_count, active_object_count_wider)
                     -- everything dies in the winter
                     local abovepos = { x=pos.x, y=pos.y+1,z=pos.z }
                     local above = minetest.env:get_node_or_nil(abovepos)
                     if above and wild(abovepos) then
                        minetest.env:remove_node(abovepos)
                     end
                  end
      })
end

local postinit = minetest.require("__builtin","postinit")
postinit.push(start,"growing")

return M