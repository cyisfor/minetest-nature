local growing = minetest.require("nature","growing")
local inspect = minetest.require("__builtin","inspect")
local postinit = minetest.require("__builtin","postinit")
local like = minetest.require("madblocks","like")("nature")

local seasonLength = 12000

-- local inspect = dofile(minetest.get_modpath("nature").."/inspect.lua")
local WEATHER_CHANGE_INTERVAL = 60

-- ***********************************************************************************
--		SEASONAL CHANGES					**************************************************
-- ***********************************************************************************
local SEASON_FILE = minetest.get_worldpath()..'/nature.season'

-- copied from madblocks... damn circular dependencies!
-- also power plants, because identifying jungle grass sucks T_T

local CURRENT_SEASON = 2

function clearPerlin()
   perlin = nil
   -- make it grow in 4 new patterns every spring
   if CURRENT_SEASON==2 then
      minetest.after(seasonLength/4,clearPerlin)
   else
      -- XXX: eh... this might be bad
      minetest.after(seasonLength,clearPerlin)
   end
end
clearPerlin()

local function set_season(t)
   CURRENT_SEASON = t
   -- write to file
   local f = io.open(SEASON_FILE, "w")
   f:write(CURRENT_SEASON)
   io.close(f)
end

local f = io.open(SEASON_FILE, "r")
if f ~= nil then
   CURRENT_SEASON = f:read("*n")
   io.close(f)
else
   print('could not find season file, creating one (setting spring).')
   set_season(2)
end

local paused = false
local seasons = {
   [1]= "winter",
   [2]= "spring",
   [3]= "summer",
   [4]= "autumn"
}

function switch_seasons()
   if paused then 
      print('season paused at '..seasons[CURRENT_SEASON])
   else
      set_season(CURRENT_SEASON%4+1)
      print('changing to '..seasons[CURRENT_SEASON])
   end
   minetest.after(seasonLength,switch_seasons)
end

minetest.after(seasonLength,switch_seasons)

minetest.register_chatcommand("season", {
	params = "<season>",
	description = "set the season",
	func = function(name, param)
		if param == 'winter' or param == 'Winter' then set_season(1)
		elseif param == 'spring' or param == 'Spring' then set_season(2)
		elseif param == 'summer' or param == 'Summer' then set_season(3)
		elseif param == 'fall' or param == 'Fall' then set_season(4)
		elseif param == 'pause' or param == 'Pause' then set_season(0)
                   paused = true
                   minetest.chat_send_player(name, "Season paused.")
                   return
		else
                   minetest.chat_send_player(name, "Invalid paramater '"..param.."', try 'winter','spring','summer' or 'fall'.")
                   return		
		end
		minetest.chat_send_player(name, "Season changed.")
                paused = false
	end,
})

function seasonal(name,which)
   if which == nil then 
      which = CURRENT_SEASON
   end
   local ret = "nature:"..name.."_"..seasons[which]
   return ret
end

-- can't access node.groups from lua because >:( so we'll do this instead
local grasslike = {['default:dirt_with_grass']=true}
local leafish = {['default:leaves']=true}
local sandy = {['default:sand']=true,
               ['default:desert_sand']=true}
local cacti = {['default:cactus']=true,
               ['nature:cactus_winter']=true}
local dhmo = {['default:water_source']=true,
              ['default:water_flowing']=true,
              ['nature:ice_source']=true,
              ['nature:ice_flowing']=true}
for season = 1,4,1 do
   grasslike[seasonal('grass',season)] = true
   leafish[seasonal('leaves',season)] = true
end

function arrayConcat(...) 
   local t = {}
   for ii,o in pairs(arg) do
      if ii ~= "n" then
         for v,ignore in pairs(o) do
            table.insert(t,v)
         end
      end
   end
   return t
end      

function add_node(pos,old,new) 
   -- if old == new then return end
   minetest.env:set_node(pos,{type="node",name=new})
end

function setTurf(pos,node,generate)
   if grasslike[node.name] then
      add_node(pos,node.name,seasonal('grass'))
      if not generate and CURRENT_SEASON == 1 then
         -- winter kills stuff
         local above = {x=pos.x,y=pos.y+1,z=pos.z}
         local aboven = minetest.env:get_node_or_nil(above)
         if aboven ~= nil and growing.grows(aboven.name) then
            minetest.env:remove_node(above)
         else
            if aboven ~= nil and aboven.name ~= "air" then
               -- XXX: for debugging
               print(aboven.name.." survived winter")
            end
         end
      end
   elseif leafish[node.name] then
      add_node(pos,node.name,seasonal('leaves'))
   elseif sandy[node.name] then
      above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})      if above ~= nil and above.name == 'air' then
         local name = "sand"
         if node.name:find('desert') then
            if CURRENT_SEASON == 1 then
               name = "nature:desertsand_winter"
            else
               name = "default:desert_sand"
            end
         else
            if CURRENT_SEASON == 1 then
               name = "nature:sand_winter"
            else
               name = "default:sand"
            end
         end
         add_node(pos,node.name,name)
      end
   elseif cacti[node.name] then
      above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
      if above ~= nil and above.name == 'air' then
         local which = "default:cactus"
         if CURRENT_SEASON == 1 then
            which = "nature:cactus_winter"
         end
         add_node(pos,node.name,which)
      end
   elseif dhmo[node.name] then
      above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})
      if above ~= nil and above.name == 'air' then
         local prefix = "default:water"
         if CURRENT_SEASON==1 then
            prefix = "nature:ice"
         end
         local suffix = "source"
         if node.name:sub(-6) == 'flowing' then
            -- need to set suffix otherwise nature:ice__source :/
            suffix = "flowing"
         end
         local name = prefix .. "_" .. suffix
         add_node(pos,node.name,name)
      end
   end
end

local allTypes = arrayConcat(grasslike,leafish,sandy,cactus,dhmo)
-- print('all types: '..inspect(allTypes))
minetest.register_abm(
   {
      nodenames = allTypes,
      interval = WEATHER_CHANGE_INTERVAL,
      chance = 10,
		
      action = function(pos, node, active_object_count, active_object_count_wider)
                  setTurf(pos,node)
               end
   })

-- ***********************************************************************************
--		BIRDS SPRING/SUMMER				**************************************************
-- ***********************************************************************************
if BIRDS == true then
   local bird = {}
   bird.sounds = {}
   bird_sound = function(p)
                   local wanted_sound = {name="bird", gain=0.6}
                   bird.sounds[minetest.hash_node_position(p)] = {
                      handle = minetest.sound_play(wanted_sound, {pos=p, loop=true}),
                      name = wanted_sound.name, }
                end

   bird_stop = function(p)
                  local sound = bird.sounds[minetest.hash_node_position(p)]
                  if sound ~= nil then
                     minetest.sound_stop(sound.handle)
                     bird.sounds[minetest.hash_node_position(p)] = nil
                  end
               end
   minetest.register_on_dignode(function(p, node)
                                   if node.name == "nature:bird" then
                                      bird_stop(p)

                                   end
                                end)
   minetest.register_abm({
                            nodenames = { "nature:leaves_spring",'default:leaves' },
                            interval = growing.growInterval,
                            chance = 200,
                            action = function(pos, node, active_object_count, active_object_count_wider)
                                        local air = { x=pos.x, y=pos.y+1,z=pos.z }
                                        local is_air = minetest.env:get_node_or_nil(air)
                                        if is_air ~= nil and is_air.name == 'air' then
                                           minetest.env:add_node(air,{type="node",name='nature:bird'})
                                           bird_sound(air)
                                        end
                                     end
                         })
   minetest.register_abm({
                            nodenames = {'nature:bird' },
                            interval = growing.growInterval,
                            chance = 2,
                            action = function(pos, node, active_object_count, active_object_count_wider)
                                        minetest.env:remove_node(pos)
                                        bird_stop(pos)
                                     end
                         })
   like.plant('bird','Bird','veg')
   growing.add('nature:bird')
end

-- Ensure proper nature groups on default: nodes

local rn = minetest.registered_nodes

for i,pair in ipairs({
   {'default:dirt_with_grass','grass'},
   {'default:cactus','cactus'},
   {'default:leaves','leaves'},
   {'default:desert_sand','desert'},
   {'default:desert_stone','desert'},
   {'default:desert_sand','sand'},
   {'default:sand','sand'},
   {'default:water_source','dhmo'},
   {'default:water_flowing','dhmo'},
}) do
   local node = pair[1]
   local group = pair[2]
   rn[node].groups[group] = 1
   if group == 'grass' then
      grasslike[node] = true
   elseif group == 'sand' then
      sandy[node] = true
   elseif group == 'leaves' then
      leafish[node] = true
   elseif group == 'cactus' then
      cacti[node] = true
   elseif group == 'dhmo' then
      dhmo[node] = true
   end
end

--		SLIMTREES							**************************************************
-- ***********************************************************************************
minetest.register_abm({
		nodenames = { "nature:slimtree" },
		interval = growing.growInterval,
		chance = 10/8,
		
		action = function(pos, node, active_object_count, active_object_count_wider)
                            for dy = 0,3,1 do
                               minetest.env:add_node({x=pos.x,y=pos.y+dy,z=pos.z},{type="node",name="nature:slimtree_wood"})
                            end
                            for dx=-1,1,1 do
                               for dz = -1,1,1 do
                                  for dy = 3,6,1 do
                                     if not (dx == 0 and dz == 0 and dy == 3) then                                       
                                        minetest.env:add_node(
                                           {x=pos.x+dx,y=pos.y+dy,z=pos.z+dz},
                                           {type="node",name=seasonal("leaves")})
                                     end
                                  end
                               end
                            end
                         end
             })
-- make sure these tiny trees don't eat the landscape
-- by having their wood die (leaves die on their own)
minetest.register_abm({
		nodenames = { "nature:slimtree_wood" },
		interval = growing.growInterval*2,
		chance = 30/8,
		
		action = function(pos, node, active_object_count, active_object_count_wider)
                            -- make sure to remove the whole tree
                            -- part of a slimtree trunk w/ floating leaves above
                            -- looks silly
                            minetest.env:remove_node(pos)
                            for dy = 1,3 do
                               local npos = {pos.x,pos.y+dy,pos.z}
                               if minetest.env:get_node(npos).name == node.name then
                                  minetest.env:remove_node(npos)
                               else
                                  break
                               end
                            end

                            for dy = 1,3 do
                               local npos = {pos.x,pos.y-dy,pos.z}
                               if minetest.env:get_node(npos).name == node.name then
                                  minetest.env:remove_node(npos)
                               else
                                  break
                               end
                            end
                         end
             })

like.plant('slimtree','Slimtree Sapling','veg')
growing.add('nature:slimtree')
like.plant('dandylions','Dandylions','veg')
growing.add('nature:dandylions')
like.plant('mushroom','Wild Mushroom','veg')
growing.add('nature:mushroom')

minetest.register_node("nature:slimtree_wood", {
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

-- function isGround(pos)
--    local type = minetest.registered_nodes[minetest.env:get_node(pos).name]
--    return type and type.is_ground_content
-- end

-- this is waaaaaaay too expensive. slows initial map loading down to crawl
-- postinit.push(
--    function ()
--       minetest.register_on_generated(
--          function(minp, maxp, seed)
--             if CURRENT_SEASON == 3 then return end
--             for x = minp.x,maxp.x,1 do
--                for z = minp.z,maxp.z,1 do
--                   for y = minp.y,maxp.y,1 do                     
--                      local pos = {x=x,y=y,z=z}
--                      local node =minetest.env:get_node(pos) 
--                      if not node.name == 'default:stone' or node.name == 'default:dirt' or node.name == 'air' then 
--                         if not isGround({x=x,y=y+1,z=z}) then
--                            setTurf(pos,node)
--                         end
--                      end
--                   end
--                end
--                end
--             end)
--    end,"generate winter")

minetest.register_node("nature:ice_source", {
	description = "Ice",
	tile_images = {"nature_ice.png"},
	is_ground_content = true,
	groups = {snappy=2,choppy=3,dhmo=1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_node("nature:ice_flowing", {
	description = "Ice",
	tile_images = {"nature_ice.png"},
	is_ground_content = true,
	groups = {snappy=2,choppy=3,dhmo=1},
	sounds = default.node_sound_stone_defaults(),
})
minetest.register_node("nature:leaves_autumn", {
	description = "Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tile_images = {"nature_leaves_autumn.png"},
	paramtype = "light",
	groups = {snappy=3, leafdecay=3, flammable=2,leaves=1},
	drop = {
		max_items = 1, items = {
			{items = {'default:sapling'},	rarity = 20,},
			{items = {'nature:leaves_autumn'},}
		}},
	sounds = default.node_sound_leaves_defaults(),
})
minetest.register_node("nature:leaves_spring", {
	description = "Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tile_images = {"nature_leaves_spring.png"},
	paramtype = "light",
	groups = {snappy=3, leafdecay=3, flammable=2,leaves=1},
	drop = {
		max_items = 1, items = {
			{items = {'default:sapling'},	rarity = 20,},
			{items = {'nature:leaves_spring'},}
		}},
	sounds = default.node_sound_leaves_defaults(),
})
minetest.register_node("nature:grass_spring", {
	description = "Spring dirt",
	tile_images = {"nature_grass_spring.png", "default_dirt.png", "default_dirt.png^nature_grass_spring_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,grass=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})
minetest.register_node("nature:grass_autumn", {
	description = "Dead grass",
	tile_images = {"nature_grass_autumn.png", "default_dirt.png", "default_dirt.png^nature_grass_autumn_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,grass=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})

minetest.register_alias("nature:grass_summer","default:dirt_with_grass")
minetest.register_alias("nature:leaves_summer","default:leaves")

minetest.register_node("nature:grass_winter", {
	description = "Dirt with snow",
	tile_images = {"nature_snow.png", "default_dirt.png", "default_dirt.png^nature_grass_w_snow_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,grass=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})
minetest.register_node("nature:leaves_winter", {
	description = "Leaves",
	drawtype = "allfaces_optional",
	visual_scale = 1.3,
	tile_images = {"nature_leaves_with_snow.png"},
	paramtype = "light",
	groups = {snappy=3, leafdecay=3, flammable=2, leaves=1},
	drop = {
		max_items = 1, items = {
			{items = {'default:sapling'},	rarity = 20,},
			{items = {'nature:leaves_winter'},}
		}},
	sounds = default.node_sound_leaves_defaults(),
})
minetest.register_node("nature:cactus_winter", {
	description = "Cactus",
	tile_images = {"nature_cactus_wsnow_top.png", "nature_cactus_wsnow_top.png", "nature_cactus_wsnow_side.png"},
	is_ground_content = true,
	groups = {snappy=2,choppy=3,flammable=2, cactus=1},
	sounds = default.node_sound_wood_defaults(),
})
minetest.register_node("nature:sand_winter", {
	description = "Sand with snow",
	tile_images = {"nature_snow.png", "default_sand.png", "default_sand.png^nature_sand_w_snow_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,sand=1},
	drop = 'default:sand',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})
minetest.register_node("nature:desertsand_winter", {
	description = "Desert Sand with snow",
	tile_images = {"nature_snow.png", "default_desert_sand.png", "default_desert_sand.png^nature_desertsand_w_snow_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,sand=1,desert=1},
	drop = 'default:desert_sand',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})