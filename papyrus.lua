local growing = minetest.require("nature","growing")
-- Papyrus growing

papyrusPlague = false

if papyrusPlague then
   minetest.register_abm(
      {
         nodenames = { "default:papyrus" },
         interval = 10,
         chance = 1,
         action = 
            function(pos, node, active_object_count, active_object_count_wider)
               minetest.env:remove_node(pos)
            end
      })
else

   local function waterNear(pos) 
      local count = 0
      for dx = -1,1,1 do
         for dz = -1,1,1 do
            local water = minetest.env:get_node({x = pos.x + dx, y = pos.y, z = pos.z + dz}).name
            if water == "default:water_source" or water == "default:water_flowing" then
               count = count + 1
            end
         end
      end
      return count
   end

   minetest.register_abm(
      {
         nodenames = { "default:papyrus" },
         interval = growing.growInterval,
         chance = growing.abiochance/2,

         action = function(pos, node, active_object_count, active_object_count_wider)

                     -- less likely to grow if taller (2/3 chance per level)

                     for dy = 1,32,1 do
                        if (minetest.env:get_node({x = pos.x, y = pos.y - dy; z = pos.z})=="default:papyrus") then
                           if(math.random(3)<=2) then
                              return
                           end
                        else
                           if dy == 1 then
                              -- young papyrus doesn't survive as much
                              if math.random(10)<9 then
                                 minetest.env:remove_node(pos)
                              end
                           end
                           local wn = waterNear({x = pos.x, y = pos.y - dy, z = pos.z})
                           if wn == 0 or wn == 8 then
                              -- papyrus dies if not connected to water
                              -- or flooded
                              minetest.env:remove_node(pos)
                              return
                           end
                           break
                        end
                     end

                     -- Grow up
                     local above = {
                        x = pos.x,
                        y = pos.y + 1,
                        z = pos.z
                     }
                     local light = minetest.env:get_node_light(above, nil)
                     if (light and light < 4) then
                        return
                     end

                     if(minetest.env:get_node(above).name == "air") then
                        minetest.env:add_node(above, {name = "default:papyrus"})
                        minetest.log('[nature] A papyrus has grown at (' .. above.x .. ',' .. above.y .. ',' .. above.z .. ')')
                     end
                  end
      })

   minetest.register_abm(
      {
         nodenames = { "default:dirt", "default:dirt_with_grass", "nature:grass_spring", "nature:grass_summer" },
         interval = growing.growInterval,
         chance = growing.abiochance*2,
         action = function(pos, node, active_object_count, active_object_count_wider)
                     local air = minetest.env:get_node({x = pos.x, y = pos.y + 1, z = pos.z})
                     if (air.name == "air") then
                        air = true
                     else
                        if (air.name == "default:water_source") then
                           if (minetest.env:get_node({x = pos.x, y = pos.y+2,z=pos.z}).name=="air") then
                              air = true
                           else
                              air = false
                           end
                        else
                           air = false
                        end
                     end
                     if (air == false) then 
                        return
                     end
                     local light = minetest.env:get_node_light({x = pos.x, y = pos.y+1, z = pos.z}, nil)
                     if (light < 6) then
                        return
                     end
                     local wn = waterNear(pos)
                     if wn > 0 and wn < 8 then
                        minetest.env:add_node({x = pos.x, y = pos.y + 1, z = pos.z}, {name = "default:papyrus"})
                     end
                  end
      })
end