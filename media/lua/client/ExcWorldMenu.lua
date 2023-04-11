if Excrementum then
	Excrementum._hash = Excrementum._hash + 4096
else
	return
end

--require "ISUI/ISToolTip" 
local function newToolTip(desc)
	local toolTip = ISToolTip:new();
	toolTip:initialise();
	toolTip:setVisible(false);
	if desc then
		toolTip.description = desc
	end
	return toolTip;
end




local tpOptions = {"SheetPaper2", "ToiletPaper",
'RippedSheets', 'DenimStrips', 'AlcoholRippedSheets', "Tissue",

} --, "Newspaper", "Magazine", "ComicBook"};
local tpOptionsKey = {
	SheetPaper2 = true, ToiletPaper = 'use', 
	RippedSheets = 'use',  DenimStrips = 'use', AlcoholRippedSheets = 'use',
	Tissue = true,
}

Excrementum.tpOptionsKey = tpOptionsKey

local tpOptionsEx = {
	Newspaper = 'mood', Magazine = 'mood', ComicBook = 'mood', -- нельзя использовать автоматически
}
local tpClothes = {
	Hands=true, Scarf=true, Shirt=true, Skirt=true, Socks=true, TankTop=true, Tshirt=true, UnderwearBottom=true,
}

function Excrementum.CheckTPClothes(item)
	return tpClothes[item:getBodyLocation()]
end
function Excrementum.CheckTPLiterature(typ)
	return tpOptionsKey[typ] or tpOptionsEx[typ]
end


--Ищет бумагу в инвентаре.
--Использует, когда use_it=true
--Использует вс подряд, когда is_all=true (включая одежду, книги и журналы)
local function CheckToiletPaper(player, use_it)
	local inv = player:getInventory()
	for i, option in ipairs(tpOptions) do --loop through the options listed above
		if inv:contains(option) then
			local item = inv:FindAndReturn(option);
			if use_it then
				if tpOptionsKey[option] == 'use' then
					item:Use()
				else
					inv:Remove(item)
				end
			end
			return item
		end
	end
end
Excrementum.CheckToiletPaper = CheckToiletPaper


local function GetAllPaperItems(player)
	local inv = player:getInventory()
	local arr = {}
	-- ищем бумажные варианты
	local list = inv:getAllCategory('Literature')
	for i=0,list:size()-1 do
		local item = list:get(i)
		if tpOptionsEx[item:getType()] then
			table.insert(arr, item)
		end
	end
	-- ищем снятую одежду
	local list = inv:getAllCategory('Clothing')
	for i=0,list:size()-1 do
		local item = list:get(i)
		if not item:isEquipped() and tpClothes[item:getBodyLocation()] then
			table.insert(arr, item)
		end
	end
	return arr
end



--gggx,gggy = 0,0.5
--gggx,gggy = 0.5,0.5; p:setX(sq:getX()+gggx); p:setY(sq:getY()+gggy);
--Tiles2x.pack - Tiles2x31
-- дубль в серверной части
local TOILET_TEXTURES = { -- {-1=bucket, offset_x, offset_y, should_be_transparent}
	fixtures_bathroom_01_0={1,0.3,0.7},fixtures_bathroom_01_1={1,0.7,0.3},fixtures_bathroom_01_2={1,0.1,0.4,true},fixtures_bathroom_01_3={1,0.4,0.1,true},
	fixtures_bathroom_01_4={1,0.3,0.7},fixtures_bathroom_01_5={1,0.7,0.3},fixtures_bathroom_01_6={1,0.1,0.4,true},fixtures_bathroom_01_7={1,0.4,0.1,true},
	-- компактный железный
	fixtures_bathroom_02_4={-1,0.3,0.6},fixtures_bathroom_02_5={-1,0.6,0.3},fixtures_bathroom_02_14={-1,0.4,0.3,true},fixtures_bathroom_02_15={-1,0.4,0.4,true},
	 -- деревянный (без воды?)
	fixtures_bathroom_02_24={-1,0.5,0.3},fixtures_bathroom_02_25={-1,0.3,0.5},fixtures_bathroom_02_26={-1,0.3,0.3,true},fixtures_bathroom_02_27={-1,0.3,0.3,true},
	-- из мода Diederiks Tile Palooza
	furniture_more_ddd_01_22={1,0.3,0.7},furniture_more_ddd_01_23={1,0.7,0.3},furniture_more_ddd_01_29={1,0.1,0.4,true},furniture_more_ddd_01_30={1,0.4,0.1,true},
	furniture_more_ddd_01_13={1,0.4,0.7},furniture_more_ddd_01_14={1,0.7,0.4},furniture_more_ddd_01_15={1,0.15,0.4,true},furniture_more_ddd_01_21={1,0.4,0.1,true},
	
	--rus_forest_survival_ddd_01_52 = -1, ["rus_forest survival_ddd_01_52"] = -1, -- типа колодца что ли?
	fixtures_bathroom_01_8=1,fixtures_bathroom_01_9=1,fixtures_bathroom_01_10=1,fixtures_bathroom_01_11=1, -- писсуар
	--fixtures_sinks_01_24=1,fixtures_sinks_01_25=1, --раковина в коридоре
};
Excrementum.TOILET_TEXTURES = TOILET_TEXTURES
for k,v in pairs(TOILET_TEXTURES) do
	if type(v) == 'table' then
		v.texture = k
	end
end
local HAS_TOILET_TANK = {
	fixtures_bathroom_01_0=1,fixtures_bathroom_01_1=1,fixtures_bathroom_01_2=1,fixtures_bathroom_01_3=1,
	fixtures_bathroom_01_4=1,fixtures_bathroom_01_5=1,fixtures_bathroom_01_6=1,fixtures_bathroom_01_7=1,
	-- из мода Diederiks Tile Palooza
	furniture_more_ddd_01_22=1,furniture_more_ddd_01_23=1,furniture_more_ddd_01_29=1,furniture_more_ddd_01_30=1,
	furniture_more_ddd_01_13=1,furniture_more_ddd_01_14=1,furniture_more_ddd_01_15=1,furniture_more_ddd_01_21=1,
}
local _toilet_cache = nil -- последний, на который кликнули

local ACCEPT_FACING = {N="getN", S="getS", W="getW", E="getE"}
local OFFSET_FACING = {S={nil,0.3,0.7}, E={nil,0.7,0.3}, W={nil,0.1,0.4,true}, N={nil,0.4,0.1,true}, }
local OFFSET_FACING_ADJ = {S={nil,0.5,0.1}, E={nil,0.1,0.5}, W={nil,0.9,0.5,true}, N={nil,0.5,0.9,true}, }
local function WalkStandFace(player, object, is_walk_to, is_walk_front, is_walk_through, action_after)
	if not object then
		return true
	end
	local sq = object:getSquare()
	if not sq then
		return false
	end
	if is_walk_to and not luautils.walkAdj(player, sq) then
		return false
	end
	local facing = object:getProperties():Val("Facing")
	if is_walk_front then
		local fn_name = ACCEPT_FACING[facing]
		if fn_name then
			local new_sq = sq[fn_name](sq); -- то же, что и например sq:getN()
			if new_sq then
				-- проверяем, нет ли стены, есть ли пол (на 2-м этаже) и пр.
				-- иначе струя не долетит просто, лол
				local is_adj = AdjacentFreeTileFinder.privTrySquare(sq, new_sq)
				if is_adj then
					-- подойти вплотную к унитазу и встать перед ним
					local ox,oy = OFFSET_FACING_ADJ[facing][2],OFFSET_FACING_ADJ[facing][3]
					if action_after then
						return ISTimedActionQueue.addAfter(action_after, ISWalkToTimedAction:new(player, Excrementum.SqProxyOfs(new_sq,ox,oy)));
					else
						ISTimedActionQueue.add(ISWalkToTimedAction:new(player, Excrementum.SqProxyOfs(new_sq,ox,oy)));
					end
					sq = nil -- отменяем действие встать на унитаз
				end
			end
		end
	end
	if is_walk_through then
		if sq then -- встать на унитаз
			local ox,oy = 0.5,0.5
			--if gggx and gggx ~= 0 then
			--	ox,oy = gggx,gggy
			if type(_toilet_cache) == 'table' then
				ox,oy = _toilet_cache[2],_toilet_cache[3]
			--elseif OFFSET_FACING[facing] then
			--	ox,oy = OFFSET_FACING[facing][2],OFFSET_FACING[facing][3]
			end
			if action_after then
				return ISTimedActionQueue.addAfter(action_after, ISWalkToTimedAction:new(player, Excrementum.SqProxyOfs(sq,ox,oy)));
			else
				ISTimedActionQueue.add(ISWalkToTimedAction:new(player, Excrementum.SqProxyOfs(sq,ox,oy)));
			end
		end
	end
	return true
end
Excrementum.WalkStandFace = WalkStandFace

-- small inject to ISWalkToTimedAction to make it for floats too
do
	local old_start = ISWalkToTimedAction.start
	ISWalkToTimedAction.start = function(self)
		local x = self.location:getX()
		if math.floor(x) == x then
			return old_start(self)
		end
		local beh = self.character:getPathFindBehavior2()
		local m = getmetatable(beh).__index
		local old_path = m.pathToLocation
		m.pathToLocation = m.pathToLocationF
		pcall(old_start, self)
		m.pathToLocation = old_path
	end
end


-- попытаться эвакуировать экскременты в конкретный объект (если задан, иначе на землю). idx=1 poo, idx>=2 pee,
-- idx=3 писсуар, idx=4 засор/деревня (мимо туалета), idx=5 нет воды в обычном (но не переполнен)
local function TryEvacuate(player, action_idx, item_type, object, paper) --print('player = ',player)
	if action_idx == 1 then
		if paper and paper:getContainer() ~= player:getInventory() then -- paper failed
			return
		end
	end

	local is_alpha = type(_toilet_cache) == 'table' and _toilet_cache[4]
	
	if object then
		local is_toilet = item_type == "toilet" 
		local is_sit = is_toilet and action_idx == 2 and not player:isFemale()
		if not WalkStandFace(player, object, true, is_sit, is_toilet) then
			return
		end
	end
	--[[
		local sq = object:getSquare()
		if not sq or not luautils.walkAdj(player, sq) then
			--if object on square is invalid, or player cannot walk adjacent to object
			return
		end
		if item_type == "toilet" then -- если это унитаз
			if action_idx == 2 and not player:isFemale() then
				-- особый случай для писающих мужчин, меняем целевой тайл
				local facing = object:getProperties():Val("Facing")
				local fn_name = ACCEPT_FACING[facing]
				if fn_name then
					local new_sq = sq[fn_name](sq); -- то же, что и например sq:getN()
					if new_sq then
						-- проверяем, нет ли стены, есть ли пол (на 2-м этаже) и пр.
						-- иначе струя не долетит просто, лол
						local is_adj = AdjacentFreeTileFinder.privTrySquare(sq, new_sq)
						if is_adj then
							-- подойти вплотную к унитазу и встать перед ним
							ISTimedActionQueue.add(ISWalkToTimedAction:new(player, new_sq));
							sq = nil -- отменяем действие встать на унитаз
						end
					end
				end
			end
			if sq then -- встать на унитаз
				ISTimedActionQueue.add(ISWalkToTimedAction:new(player, sq));
			end
		end
	end--]]
	local is_past_the_toilet;
	if action_idx > 2 then
		is_past_the_toilet = action_idx == 5 and 1 or true
		if action_idx == 3 and not player:isFemale() then
			is_past_the_toilet = false
		end
		action_idx = 2
	end
	
	local useToilet = item_type == "toilet" -- именно стандартный унитаз аля стул
	local toiletObject = useToilet and object or nil
	
	--local pants = Excrementum.GetPants(player)
	local is_male_pee = action_idx==2 and not player:isFemale()
	local any_pants = Excrementum.GetAllPantsGroin(player, is_male_pee, true)
	if Excrementum.DEBUG then
		print("NEED TO DROP PANTS = " .. tostring(any_pants) .. " (" .. (action_idx == 1 and "poo" or "pee") .. ")")
	end
	if any_pants then
		if action_idx == 1 then
			ISTimedActionQueue.add(DefecateDropPantsAction:new(player, 50, useToilet, toiletObject, paper, is_alpha))
		else
			ISTimedActionQueue.add(UrinateDropPantsAction:new(player, 100, useToilet, toiletObject, is_past_the_toilet, is_alpha))
		end
	else
		if action_idx == 1 then
			ISTimedActionQueue.add(InvoluntaryDefecate:new(player, 200, true, true, false, useToilet, toiletObject, paper, is_alpha))
		else
			--character, time, stopWalk, stopRun, peedSelf, useToilet, toiletObject)
			ISTimedActionQueue.add(InvoluntaryUrinate:new(player, 200, true, true, false, useToilet, toiletObject, is_past_the_toilet, is_alpha))
		end
	end
end


function Excrementum.CheckAss(player, add_dirt)
	local exc = Excrementum.exc --player:getModData().exc
	local old_ass = exc.ass
	if add_dirt == true then
		exc.ass = (exc.ass or 0) + 1
	elseif add_dirt then
		exc.ass = (exc.ass or 0) + add_dirt
	elseif add_dirt == false then
		exc.ass = nil
		exc.ass_tm = nil
	end
	if exc.ass ~= old_ass then
		Excrementum.UpdateSmellMoodle(player)
		if old_ass == nil then -- first dirt
			exc.ass_tm = Excrementum.now
		end
	end
	return exc.ass
end

--Очищает грязь с попы.
--Главным является использование ТБ, поэтому изначальное наличие грязи игнорируется (и это абьюзится при дефекации с бумагой).
local function UseToiletPaper(player, paper)
	local inv = player:getInventory()
	if paper and paper:getContainer() ~= inv then
		paper = nil
		print('ERROR EXC: paper disappeared')
	end
	if not paper then
		return false
	end
	if tpOptionsKey[paper:getType()] == 'use' then
		paper:Use() --print('use')
	elseif instanceof(paper, "Clothing") then
		local data = paper:getModData()
		if data.feces then --print('clothes fail')
			return false -- нельзя подтереться, уже обгажено
		end --print('clothes')
		data.feces = 0 -- просто запах, не содержит фекалий
		paper:setDirtyness(100)
	else -- все остальные предметы - удаляем
		inv:Remove(paper) --print('others')
	end
	
	--[[ здесь оно не плюсуется к действию
	if Excrementum.now - (Excrementum.exc.ass_tm or 0) > 120 then
		Excrementum.AddUnhappyness(player, -5) --прошло 2 часа
	else
		Excrementum.AddUnhappyness(player, -10) --сразу
	end
	--]]

	Excrementum.CheckAss(player, false)
	return true
end
Excrementum.UseToiletPaper = UseToiletPaper

local function TryUseToiletPaper(player, paper)
	local inv = player:getInventory()
	--if paper and paper:getContainer() ~= inv then
--		paper = nil
		--print('ERROR EXC: paper disappeared')
	--end
	if not paper then
		return
	end
	--if paper:isEquipped() then
	--	ISTimedActionQueue.add(ISUnequipAction:new(player, paper, 50)) -- vanilla value is 50 everywhere
	--end
	ISInventoryPaneContextMenu.transferIfNeeded(player, paper)
	ISTimedActionQueue.add(ExcUsePaper:new(player, 80, paper))
end
Excrementum.TryUseToiletPaper = TryUseToiletPaper



local function TryToiletFlush(player, toilet)
	local sq = toilet:getSquare()
	if not sq then
		--if toilet on square is invalid, or player cannot walk adjacent to toilet
		return
	end

	--проверяем, рядом ли. Если да, то моментальное действие, без очереди.
	--[[local player_sq = player:getCurrentSquare()
	if player_sq then
		local is_adj = AdjacentFreeTileFinder.privTrySquare(sq, player_sq)
		if is_adj then -- моментальное действие
			Excrementum.UseToiletWater(player, toilet, 5)
			return
		end
	end--]]-- isSeatedInVehicle isNearVehicle getUseableVehicle getTicksSinceSeenZombie isLocal isAttacking() CanSee(pl)
	--getCell():getNearestVisibleZombie(0) getSurvivorList !! getLuaObjectList --> table , getObjectList
	--water: getWaterMax getWaterAmount setWaterAmount isFloor isTaintedWater getContainer


--getCurrentSquare


	--if not luautils.walkAdj(player, sq) then
	--	return
	--end
	if not WalkStandFace(player, toilet, nil, nil, true) then
		return false
	end
	
	ISTimedActionQueue.add(ExcToiletFlush:new(player, toilet, 5))

end




local function TryToiletClean(player, toilet)
	local inv = player:getInventory()
	local plunger = inv:getItemFromTypeRecurse("Base.Plunger")
	if not plunger then
		return print('ERROR EXC: no plunger')
	end
	if not WalkStandFace(player, toilet, true, false, true) then
		return
	end
	--[[local sq = toilet:getSquare()
	if not sq or not luautils.walkAdj(player, sq) then
		return
	end--]]
	--ISInventoryPaneContextMenu.transferIfNeeded(player, plunger)
	ISInventoryPaneContextMenu.equipWeapon(plunger, true, false, 0)
	ISTimedActionQueue.add(ExcToiletClean:new(player, toilet))
end


local function TryGetBucket(player, toilet, bucket) -- or replace
	local sq = toilet:getSquare()
	if not sq or not luautils.walkAdj(player, sq) then
		return
	end
	if bucket then
		ISInventoryPaneContextMenu.transferIfNeeded(player, bucket)
	end
	ISTimedActionQueue.add(ExcToiletTransferBucket:new(player, toilet, bucket, true))
end

local function TryInsertBucket(player, toilet, bucket)
	if not bucket then
		return
	end
	local sq = toilet:getSquare()
	if not sq or not luautils.walkAdj(player, sq) then
		return
	end
	ISInventoryPaneContextMenu.transferIfNeeded(player, bucket)
	ISTimedActionQueue.add(ExcToiletTransferBucket:new(player, toilet, bucket, false))
end

local function TryGetSmellOut(player)
	if Excrementum.room_smell == 0 then
		return
	end	
	local inv = player:getInventory()
	--local list = ArrayList.new()
	--inv:getAllTagRecurse("Cleaning", list")
	
	local item = inv:getFirstTagRecurse("Cleaning")
	if not item then
		return
	end
	
	local mop = inv:getFirstTagRecurse("DryWiping")
	if not mop then
		return
	end
	
	--ContextMenu_ExNeedDetergent
	--CleaningLiquid2
	--print_r(g('clean'):getScriptItem():getTags():size())
	--print_r(g('clean'):hasTag("asd2"))
	--print(inv:getCountTagRecurse("asd"))
	
	ISInventoryPaneContextMenu.transferIfNeeded(player, item)
	ISInventoryPaneContextMenu.transferIfNeeded(player, mop)
	ISTimedActionQueue.add(ExcCleanFloor:new(player, 800, player:getCurrentSquare(), item, mop))
	
end


local CONTEXT_NAMES = {
	Newspaper = 'ContextMenu_ExDefecate_Newspaper',
	Magazine = 'ContextMenu_ExDefecate_Magazine',
	ComicBook = 'ContextMenu_ExDefecate_ComicBook',
	
	Hands="ContextMenu_ExDefecate_Gloves",
	Scarf="ContextMenu_ExDefecate_Scarf",
	Shirt="ContextMenu_ExDefecate_Shirt",
	Skirt="ContextMenu_ExDefecate_Skirt",
	Socks="ContextMenu_ExDefecate_Socks",
	TankTop="ContextMenu_ExDefecate_TankTop",
	Tshirt="ContextMenu_ExDefecate_Tshirt",
	UnderwearBottom="ContextMenu_ExDefecate_Underwear",
}



--Excrementum.IsToilet(
local IS_SIMPLE_TOILET = {
	fixtures_bathroom_02_4=-1,fixtures_bathroom_02_5=-1,fixtures_bathroom_02_14=-1,fixtures_bathroom_02_15=-1, -- компактный железный
	fixtures_bathroom_02_24=-1,fixtures_bathroom_02_25=-1,fixtures_bathroom_02_26=-1,fixtures_bathroom_02_27=-1, -- деревянный (без воды?)
}
local URINAL_TEXTURES = {
	fixtures_bathroom_01_8=1,fixtures_bathroom_01_9=1,fixtures_bathroom_01_10=1,fixtures_bathroom_01_11=1, -- писсуар
}
Excrementum.URINAL_TEXTURES = URINAL_TEXTURES
local SHOWER_TEXTURES = {
	fixtures_bathroom_01_32=1,fixtures_bathroom_01_33=1,
	fixtures_bathroom_01_31=1,fixtures_bathroom_01_30=1,
	fixtures_bathroom_01_22=1,fixtures_bathroom_01_23=1,
}
local SHOWER_WALL_TEXTURES = { fixtures_bathroom_01_35=1,fixtures_bathroom_01_34=1,fixtures_bathroom_01_36=1, }
local BATHE_TEXTURES = {
	fixtures_bathroom_01_26=27,fixtures_bathroom_01_27=26,
	fixtures_bathroom_01_54=55,fixtures_bathroom_01_55=54,
	fixtures_bathroom_01_52=53,fixtures_bathroom_01_53=52,
	fixtures_bathroom_01_24=25,fixtures_bathroom_01_25=24,
	-- из мода
	furniture_more_ddd_01_0=1,furniture_more_ddd_01_1=1,
	furniture_more_ddd_01_2=1,furniture_more_ddd_01_3=1,
	furniture_more_ddd_01_4=1,furniture_more_ddd_01_5=1,
	furniture_more_ddd_01_6=1,furniture_more_ddd_01_7=1,
};
local WATERWORKS_TEXTURES = { -- фонтаны и пр.
	location_community_park_01_48 = 0,
	location_community_park_01_41 = 0,
}
--local STATUE_TEXTURES = { fixtures_bathroom_02_22-?
--}

local MAX_DIRT_TOILET = 30
Excrementum.MAX_DIRT_TOILET = MAX_DIRT_TOILET;

local toiletClicked, toiletClickedTexture;

--check if there is a toilet or something
local function GroundRightClicked(player_idx, context, worldObjects)
	local player = getSpecificPlayer(player_idx)
	
	local defecate = Excrementum.feces

	local exc = player:getModData().exc
	local can_defecate = exc.col.td
	local can_urinate = Excrementum.urine >= 0.2
	
	local firstObject; -- Pick first object in worldObjects as reference one
	for _, o in ipairs(worldObjects) do
		if not firstObject then firstObject = o; end
		break
	end

	if not firstObject then
		return
	end
	local square = firstObject:getSquare() -- the square this object is in is the clicked square
	local worldObjects = square:getObjects(); -- and all objects on that square will be affected

	
	--Rain Collector Barrel
	--texture=carpentry_02_53, water=400
	--texture=carpentry_02_55, water=160
	--appliances_laundry_01_12
	
	toiletClicked, toiletClickedTexture = nil, nil
	local toilet, shower, wall, sink, is_urinal --, obj;
	
	-- Извлекаем нужные объекты из окружения
	--print("---Right Click---");
	for i = 0, worldObjects:size()-1 do
		local object = worldObjects:get(i);
		local name = object:getTextureName();
		--print("name="..tostring(object:getName()).."/"..tostring(object:getType())
		--	..", texture="..tostring(name)..", water="..tostring(object:getWaterAmount()));
		if not name then
			--print('ERROR: texture = ',tostring(name));
		elseif TOILET_TEXTURES[name] then
			toilet = object;
			toiletClicked = object;
			toiletClickedTexture = name;
			_toilet_cache = TOILET_TEXTURES[name]
			is_urinal = URINAL_TEXTURES[name]
		elseif SHOWER_TEXTURES[name] then
			shower = object;
		elseif SHOWER_WALL_TEXTURES[name] then
			wall = object;
		--elseif BATHE_TEXTURES[name] then
		--elseif not obj and object.getWaterAmount and object:getWaterAmount() >= 10 then
			--obj
		elseif not sink and string.find(name, "fixtures_sinks_") then
			sink = object;
		--[[elseif string.find(name, "fixtures_bathroom_") or string.find(name, "fixtures_sinks_") then
		
			end--]]
		end
	end
	
	-- Для душа особый алгоритм, т.к. клик может быть по стене (т.е. мимо).
	local save = player:getModData().exc;
	if wall and not shower and (save.da or save.dh or save.df) then
		local x0, y0, z0 = wall:getX(), wall:getY(), wall:getZ();
		for x=-1,1 do
			for y=-1,1 do
				local sq = getCell():getGridSquare(x0 + x, y0 + y, z0);
				if sq then
					local objs = sq:getObjects();
					for j = 0, objs:size()-1 do --loop through each tile's objects
						local object = objs:get(j);
						if instanceof(object, "IsoObject") then
							local name = object:getTextureName();
							if SHOWER_TEXTURES[name] then
								shower = object;
								break;
							end
						end
					end
				end
				if shower then
					break;
				end
			end
			if shower then
				break;
			end
		end
	end
	
	
	--упрощенная механика: можно в унитаз или на пол
	if toilet then --print('toilet ',is_urinal)
		if toilet.isBlockAllTheSquare and toilet:isBlockAllTheSquare() then
			--print("SET UNBLOCK!!!")
			toilet:setBlockAllTheSquare(false) -- КОСТЫЛЬ!
		end
		local data = toilet:getModData()
		local is_full, is_dirt
		if data.exc_dirt ~= nil then
			is_full = data.exc_dirt >= MAX_DIRT_TOILET
			is_dirt = data.exc_dirt > 0
		end
		local is_bucket = not data.no_bucket
		if is_urinal then
			can_defecate = false -- опция не доступна на писсуаре
		end
		local water = toilet:getWaterAmount()
		local water_max = toilet:getWaterMax()
		local option;
		if can_defecate then
			local paper = CheckToiletPaper(player)
			if paper then
				option = context:addOption(getText("ContextMenu_ExDefecate_Comfort" or "ContextMenu_ExDefecate_Toilet"), player, TryEvacuate, 1, "toilet", toilet, paper);
			else
				option = context:addOption(getText("ContextMenu_ExDefecate_Toilet"), player, TryEvacuate, 1, "toilet", toilet);
				-- продвинутые опции не доступны для унитаза. Но можно будет подтереться отдельным действием (сразу или потом)
			end
			if is_full then
				option.notAvailable = true
				can_defecate = false
				option.toolTip = newToolTip(getText(water_max > 0 and "ContextMenu_ExToiletDrainClog" or "ContextMenu_ExToiletFull"));
			elseif not is_bucket then
				option.notAvailable = true
				can_defecate = false
				option.toolTip = newToolTip(getText("ContextMenu_ExToiletNoBucket"));
			end
		end
		if can_urinate and not can_defecate then
			if is_urinal then
				option = context:addOption(getText(player:isFemale() and "ContextMenu_ExUrinate_PastUrinal" or "ContextMenu_ExUrinate_Urinal"), player, TryEvacuate, 3, "toilet", toilet);
			elseif is_full or water_max == 0 then
				option = context:addOption(getText("ContextMenu_ExUrinate_PastToilet"), player, TryEvacuate, 4, "toilet", toilet);
			elseif water < 5 then -- обычный туалет без засора, но и без воды
				option = context:addOption(getText("ContextMenu_ExUrinate_Toilet"), player, TryEvacuate, 5, "toilet", toilet);
			else
				option = context:addOption(getText("ContextMenu_ExUrinate_Toilet"), player, TryEvacuate, 2, "toilet", toilet);
			end
			--if water < 5 then
			--	option.notAvailable = true
			--	option.toolTip = newToolTip(getText("ContextMenu_ExToiletNeedWater"));
			--end
		end
		-- Смыть/прочистить
		if water_max > 0 then -- Обычный унитаз
			if is_dirt or Excrementum.DEBUG then -- "Смыть или Прочистить"
				if is_full then -- Засор трубы - "Прочистить"
					option = context:addOption(getText("ContextMenu_DefecateToiletClean"), player, TryToiletClean, toilet);
					if not player:getInventory():containsTypeRecurse("Base.Plunger") then
						option.notAvailable = true
						option.toolTip = newToolTip(getText("ContextMenu_ExToiletNeedPlunger"));
					end
				else -- просто "Смыть"
					option = context:addOption(getText("ContextMenu_DefecateToiletFlush"), player, TryToiletFlush, toilet);
					--jj: если туалет занят, то ничего с ним делать нельзя
				end
				if not option.notAvailable and water < 5 then
					option.notAvailable = true
					option.toolTip = newToolTip(getText("ContextMenu_ExToiletNeedWater"));
				end
			end
			--Долить воды в туалет
			--if water < water_max * 0.5 then
				
			--end
		elseif not is_urinal then -- Деревенский унитаз
			local inv = player:getInventory()
			local bucket = inv:getItemFromTypeRecurse("Base.BucketDefecatedDirty") or inv:getItemFromTypeRecurse("Base.PaintTinDefecatedDirty")
				or inv:getItemFromTypeRecurse("Base.BucketEmpty") or inv:getItemFromTypeRecurse("Base.PaintbucketEmpty")
				or inv:getItemFromType("Base.BucketFullDefecate") or inv:getItemFromType("Base.PaintTinDefecate")
			if bucket and bucket.getUsedDelta and bucket:getUsedDelta() > bucket:getUseDelta() * MAX_DIRT_TOILET * 0.1 - 0.01 then
				bucket = nil -- переполненное ведро дерьма не годится
			end
			if is_bucket then -- достать ведро (не важно, полное или нет)
				option = context:addOption(getText(is_dirt and bucket and "ContextMenu_ExToiletReplaceBucket" or "ContextMenu_ExToiletGetBucket"), player, TryGetBucket, toilet, is_dirt and bucket);
			else -- no bucket
				--BucketEmpty PaintbucketEmpty
				option = context:addOption(getText("ContextMenu_ExToiletInsertBucket"), player, TryInsertBucket, toilet, bucket);
				if not bucket then
					option.notAvailable = true
					option.toolTip = newToolTip(getText("ContextMenu_ExToiletNeedBucket"));
				end
			end
		end
	--[[elseif player:isSeatedInVehicle() then -- в поле, но в машине.
		local veh = player:getVehicle()
		if veh then
		local seat_idx = veh:getSeat(player)
		local seat = seat_idx and veh:getPartForSeatContainer(seat_idx) -- Class VehiclePart
		--veh=p:getVehicle(); seat=veh:getPartForSeatContainer(0); print_r(seat:getInventoryItem():getModData())
			
		end--]]
		
	else --print('outside') -- в поле без машины
		if can_defecate then
			local paper = CheckToiletPaper(player)
			if paper then
				context:addOption(getText("ContextMenu_ExDefecate"), player, TryEvacuate, 1, nil, nil, paper);
			else
				local papers = GetAllPaperItems(player)
				if #papers == 0 then
					context:addOption(getText("ContextMenu_ExDefecate_woPaper"), player, TryEvacuate, 1, nil, nil, nil);
				elseif #papers == 1 and papers[1]:getModData().feces == nil then
					local item = papers[1]
					local name = CONTEXT_NAMES[item:getType()] or CONTEXT_NAMES[item:getBodyLocation()]
					local option = context:addOption(getText(name) or "Defecate", player, TryEvacuate, 1, nil, nil, item);
					if item:getModData().urine then
						local tooltip = ISWorldObjectContextMenu.addToolTip()
						tooltip:setName(item:getName())
						tooltip.description = getText("UI_Exc_InvTooltip_Urine") -- запах мочи
						option.toolTip = tooltip
					end
				else -- submenu
					can_defecate = false -- by default until found
					local option = context:addOption(getText("ContextMenu_ExDefecate"), worldobjects, nil)
					local subMenu = ISContextMenu:getNew(context)
					context:addSubMenu(option, subMenu)
					-- первый элемент: отказ от подтирания при дефекации
					subMenu:addOption(getText("ContextMenu_ExWithoutPaper"), player, TryEvacuate, 1, nil, nil, nil)
					for i,v in ipairs(papers) do
						local option2 = subMenu:addOption(v:getName(), player, TryEvacuate, 1, nil, nil, v)
						if v:hasModData() then
							local data = v:getModData()
							if data.feces or data.urine then
								local tooltip = ISWorldObjectContextMenu.addToolTip()
								tooltip:setName(v:getName())
								if data.feces then
									tooltip.description = getText("UI_Exc_InvTooltip_HasFeces")
									option2.notAvailable = true
								else
									tooltip.description = getText("UI_Exc_InvTooltip_Urine") -- запах мочи
									can_defecate = true
								end
								option2.toolTip = tooltip
							else
								can_defecate = true
							end
						end
					end
				end
			end
		end
		if can_urinate and not can_defecate then
			local option = context:addOption(getText("ContextMenu_ExUrinate"), player, TryEvacuate, 2);
		end
	end
	
	-- Подтираемся
	if not can_defecate and exc.ass then -- Если нет срочных дел, то может подтереться?
		if can_defecate == false then -- невозможно сделать АД с бумагой, потому что её нет (уже проверено)
			local option = context:addOption(getText("ContextMenu_ExWipeMyself"), player, TryUseToiletPaper, nil);
			option.notAvailable = true
			option.toolTip = newToolTip(getText("ContextMenu_ExMissingPaper"));
		else
			-- пробуем найти бумагу
			local paper = CheckToiletPaper(player)
			if paper then
				context:addOption(getText("ContextMenu_ExWipeMyself"), player, TryUseToiletPaper, paper);
			else
				local papers = GetAllPaperItems(player)
				if #papers == 0 then
					local option = context:addOption(getText("ContextMenu_ExWipeMyself"), player, TryUseToiletPaper, paper);
					option.notAvailable = true
					option.toolTip = newToolTip(getText("ContextMenu_ExMissingPaper"));
				else -- submenu
					local option = context:addOption(getText("ContextMenu_ExWipeWith"), worldobjects, nil)
					local subMenu = ISContextMenu:getNew(context)
					context:addSubMenu(option, subMenu)
					for i,v in ipairs(papers) do
						local option2 = subMenu:addOption(v:getName(), player, TryUseToiletPaper, v)
						if v:hasModData() then
							local data = v:getModData()
							if data.feces or data.urine then
								local tooltip = ISWorldObjectContextMenu.addToolTip()
								tooltip:setName(v:getName())
								if data.feces then
									tooltip.description = getText("ContextMenu_ExContainsFeces")
									option2.notAvailable = true
								else
									tooltip.description = getText("UI_Exc_InvTooltip_Urine") -- запах мочи
								end
								option2.toolTip = tooltip
							end
						end
					end
				end
			end
		end
	end
	
	--Выводим запах
	if not can_defecate and Excrementum.room_smell > 0 then
		-- проверяем, что есть, что чистсить
		local room = player:getCurrentSquare():getRoom()
		if room and room:getSquares():get(0):getModData().ex_sml then
			local option = context:addOption(getText("ContextMenu_ExGetSmellOut"), player, TryGetSmellOut, nil);
			local cnt_soaps = player:getInventory():getCountTagRecurse("Cleaning")
			local cnt_cloth = player:getInventory():getCountTagRecurse("DryWiping")
			if cnt_soaps < 1 or cnt_cloth < 1 then
				local tooltip = newToolTip(
					cnt_soaps < 1 and cnt_cloth < 1 and getText("ContextMenu_ExNeedDetergentBigRag")
					or cnt_soaps < 1 and getText("ContextMenu_ExNeedDetergent")
					or getText("ContextMenu_ExNeedBigRag")
				);
				option.toolTip = tooltip
				option.notAvailable = true
			end
		end
	end
	

	do return end -- force exit
	
	--subMenuFuel:addOption(label, worldobjects, ISFireplaceMenu.onAddFuel, v, player, fireplace)
	--function ISFireplaceMenu.onAddFuel(worldobjects, fuelType, player, fireplace)
	if toilet then
		local saveT = toilet:getModData();
		local water = toilet:getWaterAmount();
		if can_defecate then --Defecate
			local tooltip = nil
			local option = context:addOption(getText("ContextMenu_ExDefecate_Toilet"), toilet, ToiletDefecate);
			if (save.Defecate or 0) < 0.4 then
				option.notAvailable = true
				tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NotReady");
				option.toolTip = tooltip;
			elseif saveT.pipeClogging then
				option.notAvailable = true
				tooltip = newToolTip();
				tooltip.description = getText("UI_Def_pipeClogging");
				option.toolTip = tooltip;
			elseif saveT.dirtyAmount then
				tooltip = newToolTip();
				tooltip.description = getText("UI_Def_FecesToilet", tostring(saveT.dirtyAmount));
				option.toolTip = tooltip;
			elseif water < 10 then
				tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NoWater");
				option.toolTip = tooltip;
			end
			if tooltip and can_urinate then -- опция "мочиться" перед дефекацией, если невозможно испражниться, иначе скрыта
				
				local option = context:addOption(getText("ContextMenu_ExUrinate_Toilet"), toilet, ToiletUrinate);
			end
		end
		--Flush the toilet
		if saveT.dirtyAmount then
			local option = context:addOption(getText("ContextMenu_DefecateToiletFlush"), toilet, ToiletFlush);
			if water < 10 then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NoWater");
				option.toolTip = tooltip;
			elseif saveT.pipeClogging then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_pipeClogging");
				option.toolTip = tooltip;
			end
		end
		--Clean the toilet with a plunger
		if saveT.pipeClogging then
			local option = context:addOption(getText("ContextMenu_DefecateToiletClean"), toilet, ToiletCleanWithPlunger);
			local inv = player:getInventory();
			if not inv:contains("SinkPlunger") then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NeedPlunger");
				option.toolTip = tooltip;
			elseif water < 10 then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NoWater");
				option.toolTip = tooltip;
			end
		end
	end
	--Dirty player
	if save.playerAss or save.playerHands or save.playerFeet then
		--bathtub
		if bathe1 and bathe2 then
			local option = context:addOption(getText("ContextMenu_TakeBath"), bathe1, ToiletTakeBath, bathe2, save);
			local water1 = bathe1:getWaterAmount();
			local water2 = bathe2:getWaterAmount();
			if water1 + water2 < 60 then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NoWaterBath");
				option.toolTip = tooltip;
			elseif not player:getInventory():contains("Soap2") then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NeedSoap");
				option.toolTip = tooltip;
			elseif player:getClothingItem_Legs() or player:getClothingItem_Torso() or player:getClothingItem_Feet() then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_Undress");
				option.toolTip = tooltip;
			end
		elseif shower then
			local option = context:addOption(getText("ContextMenu_TakeShower"), shower, ToiletTakeBath, nil, save);
			if not CountAvailableWater(player,60) then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NoWaterPlayer", tostring(availWater));
				option.toolTip = tooltip;
			elseif not player:getInventory():contains("Soap2") then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NeedSoap");
				option.toolTip = tooltip;
			elseif player:getClothingItem_Legs() or player:getClothingItem_Torso() or player:getClothingItem_Feet() then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_Undress");
				option.toolTip = tooltip;
			else
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_EnoughWaterPlayer", tostring(availWater));
				option.toolTip = tooltip;
			end
		elseif save.playerHands and sink then
			local option = context:addOption(getText("ContextMenu_DefWashHands"), sink, ToiletWashHands);
			local water = sink:getWaterAmount();
			if water < 10 then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NoWaterSink", tostring(availWater));
				option.toolTip = tooltip;
			elseif not player:getInventory():contains("Soap2") then
				option.notAvailable = true
				local tooltip = newToolTip();
				tooltip.description = getText("UI_Def_NeedSoap");
				option.toolTip = tooltip;
			end
		end
	end
	tryAddWater(context,player,toilet or bath1 or sink);
end
Events.OnFillWorldObjectContextMenu.Add(GroundRightClicked);






--------- Разовые инжекты после загрузки игры --------------

Events.OnGameStart.Add(function()
	if Excrementum.is_injectedWorldMenu then
		return
	end
	Excrementum.is_injectedWorldMenu = true
	
	-- Увеличенное время стирки
	local old_GetRequiredWater = ISWashClothing.GetRequiredWater
	function ISWashClothing.GetRequiredWater(item)
		local result = old_GetRequiredWater(item) --print('result = ',result,' ',storeWater)
		local data = item:getModData()
		if data.feces or data.urine then
			result = math.max(result, 7) -- не менее 7
			if data.feces then
				result = result * 5
			else
				result = result * 3
			end
		end
		--проверяем, не превышен ли лимит доступной воды.
		--local availWater = self.sink:getWaterAmount()
		if result > 20 and storeWater and storeWater.getWaterMax then
			local max = storeWater:getWaterMax()
			if result > max then
				result = math.max(max, 20)
			end
		end
		return result
	end
	
	--- Убираем говняное из "Стирать всё"
	--(см. ExcInvMenu.lua)
	
	
	------- УМЫТЬCЯ ------
	-- Убираем запах
	local old_washy_perform = ISWashYourself.perform
	function ISWashYourself:perform()
		old_washy_perform(self)
		local exc = self.character:getModData().exc
		if exc.ass then
			exc.ass = nil
			Excrementum.UpdateSmellMoodle(self.character)
		end
	end
	
	
	------ЗАМЕНА ГРЯЗНОГО ВЕДРА ПРИ НАПОЛНЕНИИ ---------
	local old_w_onTakeWater = ISWorldObjectContextMenu.onTakeWater
	
	local function InjectOnTakeWater(obj, fn_name)
		local old_water = obj[fn_name]
		if not old_water then
			return print('ERROR EXC: no water function!')
		end
		obj[fn_name] = function(...)
			local is_active;
			local m = __classmetatables[zombie.inventory.types.ComboItem.class].__index
			local old_fn = m.getReplaceType
			m.getReplaceType = function(self, typ, ...)
				is_active = nil
				if typ == "WaterSource" then
					local orig = self:getType()
					if orig == "BucketDefecatedDirty" or orig == "PaintTinDefecatedDirty" then
						is_active = true --print('IS_ACTIVE!')
					end
				end
				return old_fn(self, typ, ...)
			end
			
			local old_create = InventoryItemFactory.CreateItem
			InventoryItemFactory.CreateItem = function(typ, ...) --print(typ)
				if is_active and (typ == "Base.BucketWaterFull" or typ == "Base.WaterPaintbucket") then
					local item = old_create(typ, ...)
					if item then
						item:setTaintedWater(true) --print('IS_POISON!')
					end
					return item
				end
				return old_create(typ, ...)
			end
			
			pcall(old_water, ...)
			
			InventoryItemFactory.CreateItem = old_create
			m.getReplaceType = old_fn
		end
	end
	InjectOnTakeWater(ISWorldObjectContextMenu, 'onTakeWater')
	
	--Долить воду в унитаз
	do
		--[[ Actually the devs planned it:
		VANILLA: local pourWaterInto = rainCollectorBarrel -- TODO: other IsoObjects too?
		--]]
		local old_from = ISWorldObjectContextMenu.addWaterFromItem
		ISWorldObjectContextMenu.addWaterFromItem = function(...)
			if not rainCollectorBarrel and HAS_TOILET_TANK[toiletClickedTexture] then
				rainCollectorBarrel = toiletClicked
			end
			return old_from(...)
		end
	end
	
	
do
	-- Разрешаем спать сразу после ночного хождения в туалет (влияет только на штраф времени, боль всё также мешает спать)
	local m = __classmetatables[zombie.characters.IsoPlayer.class].__index
	local old_fn = m.getLastHourSleeped
	m.getLastHourSleeped = function(self, ...)
		if not Excrementum.tm_peeAwaked then
			return old_fn(self, ...)
		end
		local val = old_fn(self, ...)
		if Excrementum.now and Excrementum.now - Excrementum.tm_peeAwaked < 61 then
			return 0 -- в течение часа после пробуждения можно будет сразу заснуть
		end
		Excrementum.tm_peeAwaked = nil
		return val
	end
	
	-- Добавляем подсказку в контекстное меню сна
	local TEXT1, TEXT2 = getText("ContextMenu_Sleep"), getText("ContextMenu_SleepOnGround")
	local old_fn = ISWorldObjectContextMenu.doSleepOption
	ISWorldObjectContextMenu.doSleepOption = function(context, ...)
		old_fn(context, ...)
		-- get last option
		local option = context.numOptions and context.options[context.numOptions - 1];
		if option and (option.name == TEXT1 or option.name == TEXT2) then
			local sleepOption = option
			if not sleepOption.notAvailable and Excrementum.exc.urine >= 0.7 then
				local really_tired = (Excrementum.stats:getFatigue() > 0.85)
				if not really_tired then
					sleepOption.notAvailable = true

					local tooltipText = getText("ContextMenu_ExCantSleepUrine")
					local sleepTooltip = sleepOption.toolTip
					if not sleepTooltip then
						sleepTooltip = ISWorldObjectContextMenu.addToolTip();
						sleepTooltip:setName(getText("ContextMenu_Sleeping"));
						sleepTooltip.description = tooltipText;
						sleepOption.toolTip = sleepTooltip;
					else
						sleepTooltip.description = tooltipText; -- TODO: как-то сделать, чтобы качество кровати оставалось в подсказке, которую мы заменяем
					end
				end
			end
		end
	end
	
end
	
	
	
	
end)



