-- copied from madblocks beh! but with nature:
PLANTLIKE = function(nodeid, nodename,type,option)
	if option == nil then option = false end

	local params ={ description = nodename, drawtype = "plantlike", tile_images = {"nature_"..nodeid..'.png'}, 
	inventory_image = "nature_"..nodeid..'.png',	wield_image = "nature_"..nodeid..'.png', paramtype = "light",	}
		
	if type == 'veg' then
		params.groups = {snappy=2,dig_immediate=3,flammable=2}
		params.sounds = default.node_sound_leaves_defaults()
		if option == false then params.walkable = false end
	elseif type == 'met' then			-- metallic
		params.groups = {cracky=3}
		params.sounds = default.node_sound_stone_defaults()
	elseif type == 'cri' then			-- craft items
		params.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3}
		params.sounds = default.node_sound_wood_defaults()
		if option == false then params.walkable = false end
	elseif type == 'eat' then			-- edible
		params.groups = {snappy=2,choppy=2,oddly_breakable_by_hand=2,flammable=3}
		params.sounds = default.node_sound_wood_defaults()
		params.walkable = false
		params.on_use = minetest.item_eat(option)
	end
	minetest.register_node("nature:"..nodeid, params)
end

-- PLANTLIKE and hydroponics, are why we need to depend on madblocks

-- ***********************************************************************************
--		SEASONAL CHANGES					**************************************************
-- ***********************************************************************************
local SEASON_FILE = minetest.get_worldpath()..'/nature.season'

-- copied from madblocks... damn circular dependencies!
-- also power plants, because identifying jungle grass sucks T_T
NATURE_PLANTS = { 'nature:hydroponics_cyanflower','nature:hydroponics_magentaflower','nature:hydroponics_yellowflower',
                  'nature:dandylions','nature:mushroom', "mesecons_powerplant:power_plant" }

local CURRENT_SEASON = 2

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
   [4]= "fall"
}

function switch_seasons()
   if paused then 
      print('season paused at '..seasons[CURRENT_SEASON])
   else
      set_season(CURRENT_SEASON%4+1)
      print('changing to '..seasons[CURRENT_SEASON])
   end
   minetest.after(SEASON_LENGTH,switch_seasons)
end

minetest.after(SEASON_LENGTH,switch_seasons)

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
   return "nature:"..name.."_"..seasons[which]
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

function portfromMad(ns) 
   local ms = {}
   local lookup = {}
   for i,n in ipairs(ns) do
      local m = 'madblocks:'..string.sub(n,8)
      table.insert(ms,m)
      lookup[m] = n
      minetest.register_node(m,{
                                description = "DEAD",
                                tile_images = {"unknown.png"},
                                is_ground_content = true,
                                groups = {snappy=2,choppy=3},
                                sounds = default.node_sound_stone_defaults(),
                             })
   end
   
   minetest.register_abm(
      { nodenames = ms,
        interval = 1,
        chance = 100,
        action = function(pos, node, active_object_count, active_object_count_wider)
                    print("porting at pos " .. pos.x .. "," .. pos.y .. "," .. pos.z)
                    minetest.env:add_node(pos,{type="node",name=lookup[node.name]})
                 end
     })
end

local ns = {}
for season = 1,4,1 do
   table.insert(ns,seasonal("grass",season))
   table.insert(ns,seasonal("leaves",season))
end
table.insert(ns,'nature:cactus_winter')
table.insert(ns,'nature:ice_flowing')
table.insert(ns,'nature:ice_source')
table.insert(ns,'nature:dandylions')
table.insert(ns,'nature:mushroom')
portfromMad(ns)

function add_node(pos,old,new) 
   if old == new then return end
   minetest.env:add_node(pos,{type="node",name=new})
end

minetest.register_abm(
   {
      nodenames = { "group:dirt", "group:leaves","group:water","group:cactus","group:sand", "group:grass", "group:dhmo" },
      interval = WEATHER_CHANGE_INTERVAL,
      chance = 6,
		
      action = function(pos, node, active_object_count, active_object_count_wider)
                  if grasslike[node.name] then
                     add_node(pos,node.name,seasonal('grass'))
                  elseif leafish[node.name] then
                     add_node(po,node.name,seasonal('leaves'))
                  elseif sandy[node.name] then
                     above = minetest.env:get_node_or_nil({x=pos.x,y=pos.y+1,z=pos.z})                     
                     if above ~= nil and above.name == 'air' then
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
                            interval = NATURE_GROW_INTERVAL,
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
                            interval = NATURE_GROW_INTERVAL,
                            chance = 2,
                            action = function(pos, node, active_object_count, active_object_count_wider)
                                        minetest.env:remove_node(pos)
                                        bird_stop(pos)
                                     end
                         })
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

-- ***********************************************************************************
--		NATURE_GROW			**************************************************
-- ***********************************************************************************
minetest.register_abm({
		nodenames = { "default:dirt_with_grass",'nature:grass_spring' },
		interval = NATURE_GROW_INTERVAL,
		chance = 200,
		action = function(pos, node, active_object_count, active_object_count_wider)
			local air = { x=pos.x, y=pos.y+1,z=pos.z }
			local is_air = minetest.env:get_node_or_nil(air)
			if is_air ~= nil and is_air.name == 'air' then
				local count = table.getn(NATURE_PLANTS)
				local random_plant = math.random(1,count)
				minetest.env:add_node({x=pos.x,y=pos.y+1,z=pos.z},{type="node",name=NATURE_PLANTS[random_plant]})
			end
		end
})

minetest.register_abm(
   {
      nodenames = NATURE_PLANTS,
      interval = NATURE_GROW_INTERVAL,
      chance = 2,
      action = function(pos, node, active_object_count, active_object_count_wider)
                  minetest.env:remove_node({x=pos.x,y=pos.y,z=pos.z})
               end
})

-- ***********************************************************************************
--		SLIMTREES							**************************************************
-- ***********************************************************************************
minetest.register_abm({
		nodenames = { "nature:slimtree" },
		interval = 60,
		chance = 1,
		
		action = function(pos, node, active_object_count, active_object_count_wider)
			minetest.env:add_node({x=pos.x,y=pos.y,z=pos.z},{type="node",name="nature:slimtree_wood"})
			minetest.env:add_node({x=pos.x,y=pos.y+1,z=pos.z},{type="node",name="nature:slimtree_wood"})
			minetest.env:add_node({x=pos.x,y=pos.y+2,z=pos.z},{type="node",name="nature:slimtree_wood"})

			minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z},{type="node",name="nature:slimtree_wood"})			
			minetest.env:add_node({x=pos.x+1,y=pos.y+3,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x-1,y=pos.y+3,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z+1},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+3,z=pos.z-1},{type="node",name="default:leaves"})			


			minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x+1,y=pos.y+4,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x-1,y=pos.y+4,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z+1},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+4,z=pos.z-1},{type="node",name="default:leaves"})			


			minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x+1,y=pos.y+5,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x-1,y=pos.y+5,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z+1},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+5,z=pos.z-1},{type="node",name="default:leaves"})			

			minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x+1,y=pos.y+6,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x-1,y=pos.y+6,z=pos.z},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z+1},{type="node",name="default:leaves"})			
			minetest.env:add_node({x=pos.x,y=pos.y+6,z=pos.z-1},{type="node",name="default:leaves"})			
		end
})

-- ***********************************************************************************
--		NODES									**************************************************
-- ***********************************************************************************
PLANTLIKE('slimtree','Slimtree Sapling','veg')
PLANTLIKE('bird','Bird','veg')
PLANTLIKE('dandylions','Dandylions','veg')
PLANTLIKE('mushroom','Wild Mushroom','veg')
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
	description = "Dirt with snow",
	tile_images = {"nature_grass_spring.png", "default_dirt.png", "default_dirt.png^nature_grass_spring_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,grass=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})
minetest.register_node("nature:grass_autumn", {
	description = "Dirt with snow",
	tile_images = {"nature_grass_autumn.png", "default_dirt.png", "default_dirt.png^nature_grass_autumn_side.png"},
	is_ground_content = true,
	groups = {crumbly=3,grass=1},
	drop = 'default:dirt',
	sounds = default.node_sound_dirt_defaults({
		footstep = {name="default_grass_footstep", gain=0.4},
	}),
})
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

