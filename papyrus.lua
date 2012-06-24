-- Papyrus growing

local PAPYRUS_GROW_CHANCE = 90

local waterNear = function(pos) 
  for dx = -1,1,1 do
    for dz = -1,1,1 do
      local water = minetest.env:get_node({x = pos.x + dx, y = pos.y, z = pos.z + dz}).name
      if water == "default:water_source" or water == "default:water_flowing" then
        return true
      end
    end
  end
  return false
end

minetest.register_abm({
    nodenames = { "default:papyrus" },
    interval = 10,
    chance = PAPYRUS_GROW_CHANCE,

    action = function(pos, node, active_object_count, active_object_count_wider)

        -- less likely to grow if taller (2/3 chance per level)

        for dy = 1,32,1 do
          if (minetest.env:get_node({x = pos.x, y = pos.y - dy; z = pos.z})=="default:papyrus") then
            if(math.random(3)<=2) then
              return
            end
          else
            if(not waterNear({x = pos.x, y = pos.y - dy, z = pos.z})) then
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

minetest.register_abm({
        nodenames = { "default:dirt", "default:dirt_with_grass", "madblocks:grass_spring", "madblocks:grass_summer" },
        interval = 6000,
        chance = 1,
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
          if (waterNear(pos)) then
            minetest.env:add_node({x = pos.x, y = pos.y + 1, z = pos.z}, {name = "default:papyrus"})
          end
        end
})