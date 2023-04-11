if Excrementum then
	Excrementum._hash = Excrementum._hash + 8192
else
	return
end
local _empty = {}

local function newToolTip(desc)
	local toolTip = ISToolTip:new();
	toolTip:initialise();
	toolTip:setVisible(false);
	if desc then
		toolTip.description = desc
	end
	return toolTip;
end


local BODY_SHIT_PARTS = {	Groin=true, UpperLeg_L=true, UpperLeg_R=true, LowerLeg_L=true, LowerLeg_R=true, Foot_L=true, Foot_R=true, }
local BODY_SHIT_PARTS_ORDER = {	"Groin",
	"UpperLeg_L", "UpperLeg_R",
	"LowerLeg_L", "LowerLeg_R",
	"Foot_L", "Foot_R",
}

local BODY_LOCATIONS_ORDER = { --for defecation
	UnderwearBottom=1, Underwear=2, Torso1Legs1=3, Legs1=4, Pants=5,
	Skirt=6, Dress=7, BathRobe=8, FullSuit=9, FullSuitHead=10, FullTop=11, BodyCostume=12, Boilersuit=13,
}
local BODY_LOCATIONS_IDX = {
	"UnderwearBottom", "Underwear", "Torso1Legs1", "Legs1", "Pants",
	"Skirt", "Dress", "BathRobe", "FullSuit", "FullSuitHead", "FullTop", "BodyCostume", "Boilersuit",
}

function Excrementum.GetPants(player)
	for i=#BODY_LOCATIONS_IDX,1,-1 do
		local pants = player:getWornItem(BODY_LOCATIONS_IDX[i])
		if pants then
			return pants
		end
	end
	return nil
end


--CBX_PAN_5

local ITEM_TYPE_EXCLUDE = {
	Skirt_Nurse = true,
	Skirt_Office = true,
}
local ITEM_TYPE_INCLUDE = { -- добавить для снятия, по id. false = исключить полностью
	
}

-- сюда дополнительно включаем без учёта действия штанов для муж.
local PEE_TYPES = { 
	LongCoat_Bathrobe = "pee_silent",
	Trousers_Scrubs = "pee_silent",
	CBX_Kurtk_3 = "pee_silent",
}
local PEE_LOCS = {
	Jacket = "pee_silent",
	LongJacket = "pee_silent",
}

-- включаем в действие снятия штанов. false = исключаем
local ITEM_TYPES = {
	HazmatSuit = true,
	SpiffoSuit = "pee",
	Dress_Short = false,
	HospitalGown = true,
	Skirt_Mini = false,
	CBX_Kurtk_1 = false,
}
local ITEM_LOCS = { -- true включить в снятие, "string" - также включить в снятие
	UnderwearBottom = "pee_silent",
	Underwear = "pee_silent",
	--UnderwearExtra1 = "pee_silent", -- чулки
	UnderwearInner = false, -- игнорируем декорации
	Pants = "pee",
	Legs1 = "pee_silent",
	Torso1Legs1 = "pee_silent",
	Boilersuit = "pee",
	JacketHat = false, TorsoExtra = false,
	RasSkin=false, RasMalePrivatePart=false, RasArmpitHair=false, RasChestHair=false, RasPubicHair=false, RasLegHair=false, -- ra's Body Mod compatibility
	["101"] = false, -- если здесь false, то выше pee_silent не обязателен
	Shirt = false, Sweater=false,
}


local LOC_INCLUDE = { -- добавляем к учёту, потому что по разным причинам не попадает в рассматриваемое (например, не прикрывает пах)
}

local LOC_EXCLUDE = { -- снимает всё, кроме юбок
	Skirt = "only_long", Dress = "only_long", 
	["101"] = "pee_silent",
	Shirt = true, Sweater=true,
} 
local LOC_EXCLUDE_MALE_PEE = {
	JacketHat = true, TorsoExtra = true, 
	Torso1Legs1 = "pee_silent", Legs1 = "pee_silent", BathRobe = true, Jacket = true, Pants = "pee", UnderwearBottom = "pee_silent", UnderwearExtra1 = "pee_silent",
	RasSkin=true, RasMalePrivatePart=true, RasArmpitHair=true, RasChestHair=true, RasPubicHair=true, RasLegHair=true, -- ra's Body Mod compatibility
	["101"] = "pee_silent",
	Shirt = true, Sweater=true,
}
function Excrementum.TempryFix()
	--tempry fix ra's mod
	local player = Excrementum.p
	if not player then
		return
	end
	local list = player:getInventory():getAllCategory('Clothing')
	for i=0,list:size()-1 do
		local item = list:get(i)
		if item:getModData().feces and LOC_EXCLUDE[item:getBodyLocation()] then
			item:getModData().feces = nil
		end
	end
end
Excrementum.API_AddIgnoreBodyLocation = function(name, val)
	if name then
		if val ~= 'pee' then
			LOC_EXCLUDE[name] = val or true
		end
		if val ~= 'only_long' then
			LOC_EXCLUDE_MALE_PEE[name] = val or true
		end
	end
end
Excrementum.API_AddIncludeBodyLocation = function(name, val)
	if name then
		if val ~= 'pee' then
			LOC_EXCLUDE[name] = val or true
		end
		if val ~= 'only_long' then
			LOC_EXCLUDE_MALE_PEE[name] = val or true
		end
	end
end
local groin = BloodBodyPartType.Groin
local _arr_pants = {}
-- is_male_pee=true только для писающих мужчин
-- is_any=true для возврата любой шмотки (определение, что надо снять штаны и что можно описаться)
--    Нужно для звука ширинки, снятия штанов. Так что здесь срабатывает то, что не попадает в массив (т.е. что реально не надо снимать).
function Excrementum.GetAllPantsGroin(player, is_male_pee, is_any)
	table.wipe(_arr_pants)
	local EXCL = is_male_pee and LOC_EXCLUDE_MALE_PEE or LOC_EXCLUDE
	local list = player:getWornItems()
	for i=0,list:size()-1 do
		local item = list:get(i):getItem()
		if instanceof(item, "Clothing") then
			local typ = item:getType()
			local loc = item:getBodyLocation()
			local incl = ITEM_TYPES[typ]
			if incl == nil then
				incl = ITEM_LOCS[loc]
			end
			-- быстрая проверка особых настроек муж. АМ
			if is_male_pee then
				local pee = PEE_TYPES[typ]
				if pee == nil then
					pee = PEE_LOCS[loc]
					if pee == nil then
						pee = incl
					end
				end
				if is_any and pee and pee ~= "pee_silent" then
					return true
				elseif pee == "pee_silent" or pee == "pee" then -- исключаем
					incl = false
				end
			end
			-- далее проверяем по основным таблицам
			if incl ~= false then
				if incl ~= nil then
					if is_any then
						return true
					end
					if incl == "only_long" and not is_male_pee then
						local covers_lower = parts and (parts:contains(BloodBodyPartType.LowerLeg_L) or parts:contains(BloodBodyPartType.LowerLeg_R))
						if not covers_lower then
							incl = false -- исключаем короткие юбки
						end
					end
				end
				if incl == nil then
					-- переадресуем к видимой части
					local shown = Excrementum.IsShownGroin(item, typ, loc)
					if is_male_pee then
						incl = shown < 3
					else
						incl = shown == 3 or shown < 2
					end
				end
				if incl then
					table.insert(_arr_pants, item)
				end
			end
		end
	end
	return #_arr_pants > 0 and _arr_pants or nil
end



function Excrementum.WearAll(player, arr_pants, action)
	if not arr_pants or #arr_pants == 0 then
		return
	end
	local time = 225 / #arr_pants
	if time > 90 then
		time = 90
	end
	for i=#arr_pants,1,-1 do
		local v= arr_pants[i]
		local is_Underwear = v:getBodyLocation() == 'UnderwearBottom'
		ISTimedActionQueue.addAfter(action, ISWearClothing:new(player, v, is_Underwear and 20 or time))
	end
end

local _cache_bottoms = {} -- сюда попадает то, что мы уже рассмотрели
function Excrementum.UrinateBottoms(player) --print('UrinateBottoms()')
	local items_needed = 1
	table.wipe(_cache_bottoms)
	
	-- Трусы - первая линия защиты.
	local underpants = nil
	for k in pairs(LOC_INCLUDE) do
		underpants = player:getWornItem(k) -- "UnderwearBottom"
		if underpants then break end
	end
	if underpants then
		local data = underpants:getModData()
		if not data.urine then
			data.urine = true
			items_needed = items_needed - 1
			Excrementum.AddDirtyness(underpants, 0.5)
			--underpants:setDirtyness(50)
			underpants:setWetness(100)
		end
	end
	
	-- Мочим всю одежду в области паха и ниже.
	if items_needed > 0 then
		local list = player:getWornItems()
		for _,v in ipairs(BODY_SHIT_PARTS_ORDER) do
			local part = BloodBodyPartType[v] --print('part = ',part)
			for i=0,list:size()-1 do
				local item = list:get(i):getItem() --print('\titem = ',item)
				local is_groin = (part == groin) and (item:getBodyLocation() == 'UnderwearBottom') -- костыль для трусов
				if _cache_bottoms[item] == nil then
					if instanceof(item, "Clothing") then --print('\t\tclothing')
						local parts = item:getCoveredParts()
						if is_groin or parts:contains(part) then --urinate
							_cache_bottoms[item] = true
							item:setWetness(100)
							Excrementum.AddDirtyness(item, 0.5, part)
							local data = item:getModData()
							if not data.urine then
								data.urine = true
								items_needed = items_needed - 1
							end
						end
					else -- not clothes
						_cache_bottoms[item] = true
					end
				end
			end
			if items_needed <= 0 then
				break
			end
		end
	end
	-- не добавляем грязь на персонажа, ибо это просто моча, а грязь выглядит, как дерьмо
	
	player:resetModel()
	sendClothing(player)
	triggerEvent("OnClothingUpdated", player)
end

local function cmp_defecate(a,b)
	local b_loc = BODY_LOCATIONS_ORDER[b:getBodyLocation()]
	if b_loc then
		local a_loc = BODY_LOCATIONS_ORDER[a:getBodyLocation()]
		if a_loc then
			return a_loc < b_loc
		end
	end
	return false
end

local CLOTH_MAX_FECES_DEFAULT = 3
local CLOTH_MAX_FECES = {
	UnderwearBottom = 2, Underwear = 3, UnderwearInner = 2,
	BathRobe = 0,
	Dress = 0, Skirt = 0, --юбки
	Jacket = 0, JacketHat = 0, --куртки
	Legs1 = 4, Torso1Legs1 = 4,
	Shoes = 1,
	Socks = 1,
	Pants = 3,
	TorsoExtra = 0,
}

local _arr_defecate = {}
Excrementum._arr_defecate = _arr_defecate
function Excrementum.DefecateBottoms(player)
	local items_needed = 1
	table.wipe(_cache_bottoms)

	local vis = player:getVisual()


	-- Обсираем всю одежду в области паха и ниже.
	-- Здесь уже важен порядок. Всё неизвестное сверху.
	local list = player:getWornItems()
	for _,v in ipairs(BODY_SHIT_PARTS_ORDER) do -- перебираем части тела сверху вниз
		table.wipe(_arr_defecate)
		local part = BloodBodyPartType[v]
		
		-- добавляем дерьмо на игрока
		local old_dirt = vis:getDirt(part)
		vis:setDirt(part, old_dirt + ZombRand(30, 50) * 0.01)
		-- получаем одежду, которая прикрывает эту часть тела, чтобы отложить личинку
		for i=0,list:size()-1 do
			local item = list:get(i):getItem()
			local loc = item:getBodyLocation()
			if LOC_EXCLUDE[loc] ~= true then
				local is_groin = (part == groin) and LOC_INCLUDE[loc]; -- == 'UnderwearBottom'
				if _cache_bottoms[item] == nil then
					if instanceof(item, "Clothing") then
						local parts = item:getCoveredParts()
						if is_groin or parts:contains(part) then -- potential defecate
							_cache_bottoms[item] = true
							table.insert(_arr_defecate, item)
						end
					else -- not clothes
						_cache_bottoms[item] = true
					end
				end
			end
		end
		-- сортируем одежду в порядке от тела к поверхности
		table.sort(_arr_defecate, cmp_defecate) --print('LIST:') --print_r(_arr_defecate)
		-- откладываем личинку в одежду, где её нет
		for i,v in ipairs(_arr_defecate) do
			local d = v:getDirtyness()
			if d < 100 then
				Excrementum.AddDirtyness(v, 0.9, part) -- это сильно покроет целевую часть.
				--v:setDirtyness(100)
				-- добавляем дерьмо визуально (и не важно, открыт ли слой)
				--local visual = v:getVisual()
				--visual:setDirt(part, 1)
			end
			local data = v:getModData()
			local max = CLOTH_MAX_FECES[v:getBodyLocation()] or CLOTH_MAX_FECES_DEFAULT
			if not data.feces then
				if max == 0 then
					data.feces = 0 -- штаны становятся говняными, но без какашек
				else
					data.feces = 1
					items_needed = items_needed - 1
				end
			elseif data.feces < max then -- максимум 3 (по умолчанию) какашки в шмотке.
				data.feces = (data.feces or 0) + 1;
				items_needed = items_needed - 1
			end
			if items_needed <= 0 then
				break
			end
		end
		if items_needed <= 0 then
			break
		end
	end
	
	while items_needed > 0 do
		Excrementum.PutWorldFeces(player)
		items_needed = items_needed - 1
	end
	
	player:resetModel()
	sendClothing(player)
	triggerEvent("OnClothingUpdated", player)

	--item:setRunSpeedModifier(.7)
	--player:addDirt(BloodBodyPartType.UpperLeg_R, ZombRand(20, 50), false)
end



--------------------- Inventory Actions ---------------




-- Пачкаем руки
do
	local last_dirt_tm = 0
	function Excrementum.MakeDirtHands(player)
		local tm = os.time()
		if tm - last_dirt_tm > 2 then
			last_dirt_tm = tm
			--jj: грязь рук
			--getSoundManager():PlayWorldSound("sound" , player:getCurrentSquare(), 0, 3, 0, false) 
			--local inv = player:getInventory()
			local primary = player:getPrimaryHandItem()
			local shovel = primary and primary:getType():find("Shovel",1,true) and primary;
			if shovel then
				--Excrementum.SetDirtyness(shovel, 1) -- not clothes
				--shovel:getModData().feces = 0
			else
				local gloves = player:getWornItem("Hands")
				if gloves then
					--gloves:setDirtyness(100)
					Excrementum.SetDirtyness(gloves, 1)
					gloves:getModData().feces = 0
				end
				-- put visual dirt on gloves/hands:
				player:addDirt(BloodBodyPartType.Hand_L, ZombRand(20, 50), false)
				player:addDirt(BloodBodyPartType.Hand_R, ZombRand(20, 50), false)
			end
			--player:resetModel()
			--sendClothing(player)
			--triggerEvent("OnClothingUpdated", player)
		end
	end
end


local function TryExtractFeces(player, item, cnt)
	local is_bucket = nil
	if cnt == true then -- a bucket
		is_bucket = true
		cnt = math.floor(item:getUsedDelta() / item:getUseDelta() + 0.5)
		cnt = cnt * 0.3333333 -- much faster than clothes
	elseif cnt < 1 then
		cnt = 1
	end
	if item:isEquipped() then
		ISTimedActionQueue.add(ISUnequipAction:new(player, item, 50)); -- стандартное время
	end
	ISTimedActionQueue.add(ExctractFeces:new(player, item, 300*cnt, is_bucket))
	if item:isEquipped() then
		ISTimedActionQueue.add(ISWearClothing:new(player, item, 50))
	end
end



local SHEET_WEIGHT = 0.01 -- 10г, условность


local function BookCountSheets(item)
	local sheets = 1;
	local pages = item:getNumberOfPages();
	if pages >= 200 then -- для 200+ страниц
		-- за каждые доп. 80 страниц +1 лист
		sheets = sheets + math.floor((pages - 200) * 0.0125) + 1;
		-- курсы: 2, 2, 3, 3, 4
	else
		local list = item:getTeachedRecipes();
		if list and list:size() > 0 then
			-- журнал с рецептом: +1 лист
			sheets = sheets + 1;
		end
		local weight = item:getWeight();
		local add_w = math.floor(weight * 3.3 - 0.5);
		if add_w > 0 then
			-- за каждые 0.3 доп.веса свыше 0.45: +1 лист (не для курсов)
			sheets = sheets + add_w;
			-- 0.45, 0.75, 1.06 и т.д.
		end
	end
	return sheets
end
Excrementum.BookCountSheets = BookCountSheets
local function TryTearABook(player, item)
	ISInventoryPaneContextMenu.transferIfNeeded(player, item)
	ISTimedActionQueue.add(ExcTearABook:new(player, item, 100, BookCountSheets(item)))
end



local function TryGetItemSmellOut(player, victim)

	local data = victim:getModData()
	if not (data.feces or data.urine) then
		return
	end

	local inv = player:getInventory()
	--local list = ArrayList.new()
	--inv:getAllTagRecurse("Cleaning", list")
	
	local mop
	if victim:hasTag("Cleaning") then -- вещица почистит саму себя. Нужно только моющее средство
		mop = victim
	else
		mop = inv:getFirstTagRecurse("DryWiping")
		if not mop then
			return
		end
	end

	local item = inv:getFirstTagRecurse("Cleaning")
	if not item then
		return
	end

	
	--ContextMenu_ExNeedDetergent
	--CleaningLiquid2
	--print_r(g('clean'):getScriptItem():getTags():size())
	--print_r(g('clean'):hasTag("asd2"))
	--print(inv:getCountTagRecurse("asd"))
	
	ISInventoryPaneContextMenu.transferIfNeeded(player, item)
	ISInventoryPaneContextMenu.transferIfNeeded(player, mop)
	ISInventoryPaneContextMenu.transferIfNeeded(player, victim)
	ISTimedActionQueue.add(ExcCleanFloor:new(player, 800, nil, item, mop, victim))
	
end



--========================== Inventory Context Menu =========================



local function checkInvItem(player, context, worldobjects, item)
	local typ = item:getType();
	if not typ then
		return
	end
	local exc = player:getModData().exc
	--[[if tpOptionsKey[name] then
		local save = player:getModData();
		if save.playerAss and save.playerAss > 2 then
			context:addOption(getText("ContextMenu_Def_WipeYourAss"), player, WipeYourAss, item, tpOptionsKey[name]);
		elseif save.playerAss and save.playerAss == 1 then
			context:addOption(getText("ContextMenu_Def_WipeYourAssLight"), player, WipeYourAss, item, tpOptionsKey[name]);
		elseif save.playerFeet == 2 then
			context:addOption(getText("ContextMenu_Def_WipeFeet"), player, WipeFeet, item, tpOptionsKey[name]);
		elseif save.playerHands == 2 then
			context:addOption(getText("ContextMenu_Def_WipeHands"), player, WipeHands, item, tpOptionsKey[name]);
		end
	end--]]
	if instanceof(item, "Clothing") then
		local data = item:getModData()
		if data.feces then
			if data.feces >= 0.21 then
				context:addOption(getText("ContextMenu_ExExtractFeces"), player, TryExtractFeces, item, data.feces);
			end
		elseif exc.ass and Excrementum.CheckTPClothes(item) and not exc.col.td then
			local option = context:addOption(getText("ContextMenu_ExWipeMyself"), player, Excrementum.TryUseToiletPaper, item);
			if item:getModData().feces then
				option.notAvailable = true
				local tooltip = ISWorldObjectContextMenu.addToolTip()
				tooltip.description = getText("ContextMenu_ExContainsFeces")
				option.toolTip = tooltip
			end
		end
		return
	elseif Excrementum.CheckTPLiterature(typ) then
		if exc.ass then
			context:addOption(getText("ContextMenu_ExWipeMyself"), player, Excrementum.TryUseToiletPaper, item);
		elseif instanceof(item, "Literature") and typ ~= 'SheetPaper2' and BookCountSheets(item) > 1 then
			context:addOption(getText("ContextMenu_TryTearABook"), player, TryTearABook, item);
		end
	elseif instanceof(item, "Literature") then
		context:addOption(getText("ContextMenu_TryTearABook"), player, TryTearABook, item);
	elseif typ == 'BucketFullDefecate' or typ == 'PaintTinDefecate' then
		context:addOption(getText("ContextMenu_ExExtractFeces"), player, TryExtractFeces, item, true); -- is_bucket
		--даже если ноль, нужно "очистить" ведро.
	elseif item:hasModData() then
		local data = item:getModData()
		if data.urine or data.feces then
			if data.feces and data.feces > 0 then
				context:addOption(getText("ContextMenu_ExExtractFeces"), player, TryExtractFeces, item, data.feces);
			else
				local option = context:addOption(getText("ContextMenu_ExScrub"), player, TryGetItemSmellOut, item);
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
	end
end
local invContextMenu = function(_player, context, worldobjects, test)
	local player = getSpecificPlayer(_player);
	
	for i,k in pairs(worldobjects) do
	-- inventory item list
		if instanceof(k, "InventoryItem") then
			checkInvItem(player, context, worldobjects, k);			
		elseif k.items and #k.items > 1 then
			checkInvItem(player, context, worldobjects, k.items[1]);
		end
	end
end
Events.OnFillInventoryObjectContextMenu.Add(invContextMenu);



--=============================== INJECTS ============================



if Excrementum.is_injectedInvMenu then
	return -- avoid RELOAD
end

--Внедряемся в трусы (функция hasDirt).
--Нужно сделать, чтобы трусы рассматривались как одежда для стирки.
Events.OnGameStart.Add(function()
	if Excrementum.is_injectedInvMenu then
		return
	end
	Excrementum.is_injectedInvMenu = true
	local item = InventoryItemFactory.CreateItem("Base.Underpants_White")
	if not item then
		return print("ERROR EXC: Can't inject into clothes item!")
	end
	
	--print('Exc: clothes permanent injection')
	local m = getmetatable(item).__index
	local old_fn = m.hasDirt
	m.hasDirt = function(self)
		--if self:getDirtyness() > 0 then
		--	return true
		--end
		local data = self:getModData()
		if data.feces or data.urine then
			return true -- и не важно, какая там грязь
		end
		return old_fn(self)
	end
	
	
	-- Стирка удаляет говно и мочу полностью.
	local old_ISWashClothing_perform = ISWashClothing.perform
	function ISWashClothing:perform()
		local item = self.item
		if item and item:hasModData() then
			data = item:getModData()
			if data.feces then
				data.feces = nil
			end
			if data.urine then
				data.urine = nil
			end
		end
		return old_ISWashClothing_perform(self)
	end
	
	-- Пороги времени для мочи - 1100, для каках - 1900 (обычно 1500)
	local old_washNew = ISWashClothing.new
	function ISWashClothing:new(character, sink, soapList, item, bloodAmount, dirtAmount, noSoap, ...)
		local o = old_washNew(self, character, sink, soapList, item, bloodAmount, dirtAmount, noSoap, ...)
		if instanceof(item, "Clothing") and item:hasModData() then
			local tm = ((bloodAmount + dirtAmount) * 15);
			local data = item:getModData()
			if data.feces then
				if tm > 1900 then
					tm = 1900
				end
			elseif data.urine then
				if tm > 1100 then
					tm = 1100
				end
			end
			if tm > o.maxTime then
				o.maxTime = tm
			end
		end
		return o
	end



----------Patch tooltips---------


local LOC_KEY = {
	Cotton = "IGUI_SM_Cotton",
	Denim = "IGUI_SM_Denim",
	Leather = "IGUI_SM_Leather",
}

local _brown = {1,.4,0}
local _dark_brown = {.8,.4,0}
local TYPE_COLOR = {
	_brown,
	_brown,
	_brown,
	[0] = _dark_brown,
	[true] = {.7,.7,0}, -- yellow
	RED_UNKNOWN = {1,.4,.4}, 
}
Excrementum.test = function(r,g,b) _brown[1]=r _brown[2]=g _brown[3]=b end

local cache_render_item = nil
local cache_render_text = nil
local cache_render_type = nil

local old_render = ISToolTipInv.render
function ISToolTipInv:render()
	if self.item ~= cache_render_item then
		cache_render_item = self.item
		cache_render_text = nil
		if cache_render_item and cache_render_item:hasModData() then
			local data = cache_render_item:getModData()
			if data.feces then
				cache_render_type = round(data.feces,2)
				if cache_render_type == 0 then -- optimization
					cache_render_text = getText("UI_Exc_InvTooltip_HasFeces")
				else
					cache_render_text = getText("UI_Exc_InvTooltip_Feces", cache_render_type)
				end
			elseif data.urine then
				cache_render_type = data.urine
				cache_render_text = getText("UI_Exc_InvTooltip_Urine")
			end
			-- проверка одежды на вшивость и очистка. Костыль
			if cache_render_text and instanceof(cache_render_item, "Clothing") and cache_render_item:getDirtyness() == 0 then
				Excrementum.CheckCleanItem(cache_render_item)
				cache_render_text = nil
			end
		end
	end
	if not cache_render_text then --small item (or error?)
		return old_render(self)
	end
	-- Ninja double injection in injection!
	local stage = 1
	local save_th = 0
	local old_setHeight = self.setHeight
	self.setHeight = function(self, num, ...)
		if stage == 1 then
			stage = 2
			save_th = num
			num = num + 18
		else 
			stage = -1 --error
		end
		return old_setHeight(self, num, ...)
	end
	local old_drawRectBorder = self.drawRectBorder
	self.drawRectBorder = function(self, ...)
		if stage == 2 then
			local col; -- {r,g,b}
			if cache_render_type then
				local col
				if type(cache_render_type) == 'number' then
					col = cache_render_type == 0 and _brown or _dark_brown
				else
					col = TYPE_COLOR[cache_render_type] or TYPE_COLOR.RED_UNKNOWN;
				end
				local font = UIFont[getCore():getOptionTooltipFont()];
				self.tooltip:DrawText(font, cache_render_text, 5, save_th-5, col[1], col[2], col[3], 1);
			end
			stage = 3
		else
			stage = -1 --error
		end
		return old_drawRectBorder(self, ...)
	end
	old_render(self)
	self.setHeight = old_setHeight
	self.drawRectBorder = old_drawRectBorder
end


-- inject into the washing context menu

do

	local tooltip;
	local old_addOption = nil
	local function _addOption(self, txt, player, fn, sink, soapList, washList, item, ...)
		--print('_addOption = ', txt)
		local new_list;
		if washList and type(washList) == 'table' then -- проверяем все шмотки, а не говняные ли они.
			-- Мы НЕ МОЖЕМ менять этот список напрямую, потому что будет далее использован. Но мы можем его нагло скопировать и подменить.
			for i,item in ipairs(washList) do
				local ok = true
				if item:hasModData() then
					local feces = item:getModData().feces
					if feces and feces >= 0.21 then
						ok = false
					end
				end
				if ok then
					if new_list then
						table.insert(new_list, item)
					end
				else
					if not new_list then
						-- тогда создаём новый список и добавляем туда всё уже проверенное до этого.
						new_list = {}
						for j=1,i-1 do
							table.insert(new_list, washList[j])
						end
					end
				end
			end
			if new_list then
				washList = new_list -- вырезали всё говняное.
			end
		end
		
		local option = old_addOption(self, txt, player, fn, sink, soapList, washList, item, ...)
		
		if new_list then
			-- А что если список пустой? Тогда делаем команду красной.
			if #new_list == 0 and not option.notAvailable then
				option.notAvailable = true
				-- Подсказка не обязательна. Все шмотки, которые были в списке - говняные. Они же будут и далее по списку видны красным.
			end
		elseif item and instanceof(item, "Clothing") and item:hasModData() then
			local data = item:getModData()
			if data.feces then
				if data.feces >= 0.21 then
					option.notAvailable = true
					if tooltip then
						tooltip.description = tooltip.description .. " <LINE> <RGB:1,0,0> " .. getText("ContextMenu_ExContainsFeces")
					end
				elseif tooltip then
					tooltip.description = tooltip.description .. " <LINE> <RGB:0.7,0.4,0> " .. getText("UI_Exc_InvTooltip_HasFeces")
				end
			elseif data.urine and tooltip then
				tooltip.description = tooltip.description .. " <LINE> <RGB:0.7,0.7,0> " .. getText("UI_Exc_InvTooltip_Urine")
			end
		end
		return option
	end

	local old_submenu = nil
	local _WASH_NAME = getText("ContextMenu_Wash")
	local _WASH_ALL = getText("ContextMenu_WashAllClothing")
	local save_mainSubMenu = nil -- also was_once
	local function _getNew(self, ctx, ...)
		local mainSubMenu = old_submenu(self, ctx, ...)
		if save_mainSubMenu then
			return mainSubMenu
		end
		if not ctx.options then
			return mainSubMenu
		end
		local last = ctx.options[#ctx.options]
		if not last then
			return mainSubMenu
		end
		if last.name == _WASH_NAME then
			if mainSubMenu.addOption == _addOption then
				print('ERROR EXC: ":getNew" inject failed.')
				return mainSubMenu
			end
			old_addOption = mainSubMenu.addOption
			mainSubMenu.addOption = _addOption -- ticket to one side
			save_mainSubMenu = mainSubMenu
		end
		return mainSubMenu
	end
	
	local old_addToolTip = nil
	local function _addToolTip(...)
		tooltip = old_addToolTip(...)
		return tooltip
	end


	--[[local m_inventory = __classmetatables[zombie.inventory.ItemContainer.class].__index
	local old_FromCategory = nil
	local function new_getItemsFromCategory(self, cat_name, ...)
		local list = old_FromCategory(self, cat_name, ...)
		if cat_name ~= "Clothing" then
			return list
		end
		local new_list = ArrayList.new()
		
	end--]]


	local old_doMenu = ISWorldObjectContextMenu.doWashClothingMenu
	ISWorldObjectContextMenu.doWashClothingMenu = function(...) -- permanent
		if old_submenu then
			print('ERROR EXC: previous ninja inject failed; recovery...')
			ISContextMenu.getNew = old_submenu
			ISWorldObjectContextMenu.addToolTip = old_addToolTip
		end
		save_mainSubMenu = nil
		old_submenu = ISContextMenu.getNew
		ISContextMenu.getNew = _getNew
		old_addToolTip = ISWorldObjectContextMenu.addToolTip
		ISWorldObjectContextMenu.addToolTip = _addToolTip
		--old_FromCategory = m_inventory.getItemsFromCategory
		--m_inventory.getItemsFromCategory = new_getItemsFromCategory
		
		pcall(old_doMenu, ...)
		
		--m_inventory.getItemsFromCategory = old_FromCategory
		ISContextMenu.getNew = old_submenu
		ISWorldObjectContextMenu.addToolTip = old_addToolTip
		old_submenu = nil
		if save_mainSubMenu and old_addOption then
			save_mainSubMenu.addOption = old_addOption
		end
	end
end


------- Меню "Слить на землю" ----------
if not ISDumpContentsAction then
	print("ERROR EXC: No ISDumpContentsAction action!")
else
	local old_perform = ISDumpContentsAction.perform
	ISDumpContentsAction.perform = function(self, ...)
		old_perform(self, ...)
		if self.item:getType() == 'BucketFullDefecate' then
			Excrementum.PutWorldUrine(self.character, 0.5)
		end
	end
	
	local old_start = ISDumpContentsAction.start
	ISDumpContentsAction.start = function(self)
		if self.item:getType() ~= 'BucketFullDefecate' then
			return old_start(self)
		end
		--local _temp = CharacterActionAnims.Pour
		--CharacterActionAnims.Pour = "PourBucket"
		pcall(old_start, self)
		--CharacterActionAnims.Pour = _temp
	end
end





------------ Очищаем одежду, доставая из стиралки или сушилки-------------
do

	--clothingwasher  clothingdryer clothingdryerbasic combowasherdryer
	local _tm_last_check = 0

	local old_start = ISInventoryTransferAction.start
	function ISInventoryTransferAction:start()
		old_start(self)
		Excrementum.is_transfer_lock = true
		local src = self.srcContainer
		if not src then
			return
		end
		local typ = src:getType()
		--print('typ = ',typ)
		if typ ~= 'clothingwasher' and typ ~= 'combowasherdryer' then
			return
		end
		local now = os.time()
		if now - _tm_last_check < 5 then
			return -- не чаще, чем каждые 5 сек
		end
		_tm_last_check = now -- client only
		local list = src:getItemsFromCategory("Clothing")
		for i=0,list:size()-1 do
			local item = list:get(i)
			Excrementum.CheckCleanItem(item)
		end	
	end

end



---------- Пачкаем руки или одежду при манипуляции с фекалиями -----------
local FECES_ITEM_TYPES = { HumanFeces1=true, HumanFeces2=true, HumanFeces3=true, }
do

	local old_fn = ISInventoryTransferAction.perform
	function ISInventoryTransferAction:perform()
		old_fn(self)
		Excrementum.is_transfer_lock = false
		Excrementum.tm_transfer = os.time()
		if self.maxTime ~= 0 and FECES_ITEM_TYPES[self.item:getType()] then
			Excrementum.MakeDirtHands(self.character)
		end
	end
	
	local old_drop = ISDropWorldItemAction.perform
	function ISDropWorldItemAction:perform()
		old_drop(self)
		if self.maxTime ~= 0 and FECES_ITEM_TYPES[self.item:getType()] then
			Excrementum.MakeDirtHands(self.character)
		end
	end
end

----------- Внедряемся в готовку еды (нужно добавить яд) ----------

do
	local old_fn = ISAddItemInRecipe.perform
	function ISAddItemInRecipe:perform()
		old_fn(self)
		local item = self.usedItem
		if item and FECES_ITEM_TYPES[item:getType()] then
			local base = self.baseItem
			base:setUnhappyChange(base:getUnhappyChange() + 20)
			base:setBoredomChange(base:getBoredomChange() - 60)
			Excrementum.MakeDirtHands(self.character)
		end
	end
end




--------- Меняем интерфейс механики автомобиля -----------

do
	--category = "seat"
	--vehiclePart[category].parts = {name=, part=}
	--self.listbox ... {name=, cat=true} / {name=, part=}
	local SEATS_CAT_NAME = getText("IGUI_VehiclePartCatseat")
	

	local COL_YELLOW = {r=.7,g=.7,b=0,a=1}
	local COL_BROWN = {r=.7,g=.4,b=0,a=1}
	
	-- self.vehiclePart["seat"].parts.part  (.name --> visible)
	local function CheckParts(self)
		if not self.vehiclePart or not self.vehiclePart.seat then --print('NO CAT')
			return
		end
		local found_idx = nil
		for i=1,#self.listbox.items do
			local i = self.listbox.items[i]
			local v = i.item
			if found_idx == nil then -- режим поиска категории сидений
				if v.name == SEATS_CAT_NAME then -- seat category begins
					found_idx = i
				end
			elseif v.cat then --next category begins
				break
			else -- внутри категории сидений. Рассматриваем одно из.
				local item = v.part and v.part:getInventoryItem()
				if not i._is_exc then
					i._exc_backup = i.tooltip
				end
				if item and item:hasModData() then
					local data = item:getModData() --print('data=',data)
					if data.feces then
						i.tooltip = data.feces==0 and getText("UI_Exc_InvTooltip_HasFecesRGB") or getText("UI_Exc_InvTooltip_FecesRGB", data.feces)
						i._exc_col = COL_BROWN
						i._is_exc = true
					elseif data.urine then
						i.tooltip = getText("UI_Exc_InvTooltip_UrineRGB")
						i._exc_col = COL_YELLOW
						i._is_exc = true
					else
						i.tooltip = i._exc_backup --immutable
						i._exc_col = nil
						i._is_exc = false
					end
				else
					i.tooltip = i._exc_backup
					i._exc_col = nil
					i._is_exc = false
				end
			end
		end
	end
	Excrementum.UpdateVehicleWindow = function()
		local window = getPlayerMechanicsUI(0)
		if window and window:isReallyVisible() then
			CheckParts(window)
		end
	end
	
	local old_initParts = ISVehicleMechanics.initParts
	function ISVehicleMechanics:initParts(...) --print('init parts')
		old_initParts(self, ...)
		CheckParts(self)
	end
	
	--апдейтим каждый раз на успешной установке или снятии. jj: будут проблемы в мультиплеере при одновременном монтаже
	local old_green = ISVehicleMechanics.startFlashGreen
	ISVehicleMechanics.startFlashGreen = function(self, ...)
		old_green(self, ...)
		CheckParts(self)
		if isClient() then
			sendClientCommand(Excrementum.p, 'Exc', 'UpdateVeh', _empty)
		end
	end
	
	--- оверлей куда пересесть
	local old_drawTextCentre = ISVehicleSeatUI.drawTextCentre
	ISVehicleSeatUI.drawTextCentre = function(self, str, x, y, ...)
		old_drawTextCentre(self, str, x, y, ...)
		local seat = tonumber(str)
		if not seat or x < 70 or x > 190 or seat > 10 then
			return
		end
		local part = self.vehicle:getPartForSeatContainer(seat-1)
		local item = part and part:getInventoryItem()
		if not item then
			return
		end
		local data = item:getModData()
		if not (data.feces or data.urine) then
			return
		end
		local r,g,b = 1,1,0
		if data.feces then
			r,g = 0.7,0.3
		end
		if self.vehicle:isSeatOccupied(seat-1) then
			r,g,b = 0,0,0
		end
		if data.feces then
			old_drawTextCentre(self, getText("UI_Exc_HumanFecesShort"), x, y+18, r,g,b,0.9, UIFont.Small)
		else
			old_drawTextCentre(self, getText("UI_Exc_HumanUrineShort"), x, y+18, r,g,b,0.9, UIFont.Small)
		end
	end

	local p_txt_f = getText("UI_Exc_HumanFecesMicro")
	local p_txt_u = getText("UI_Exc_HumanUrineMicro")

	-- контекстное меню на сиденье
	local old_contextMenu = ISVehicleMechanics.doPartContextMenu
	function ISVehicleMechanics:doPartContextMenu(...)
		local old = ISContextMenu.addOption -- ninja injection
		function ISContextMenu:addOption(txt, t, o, a, b, ...)
			if b and type(b) == 'userdata' and b.hasModData and b:hasModData() then
				local data = b:getModData()
				if data.feces then
					txt = txt .. p_txt_f
				elseif data.urine then
					txt = txt .. p_txt_u
				end
			end	
			return old(self, txt, t, o, a, b, ...)
		end
		pcall(old_contextMenu, self, ...)
		ISContextMenu.addOption = old
	end
	

end


--Из говняных шмоток иногда падают чистые тряпки. Нужно убрать этот шанс.
do
	local old_ZombRand
	local FakeZombRand = function(num, ...)
		if num == 100 then
			return 0
		end
		return old_ZombRand(num, ...)
	end

	local old_perform = ISRipClothing.perform
	function ISRipClothing:perform()
		if not (instanceof(self.item, "Clothing") and self.item:hasModData() and self.item:getModData().feces) then
			return old_perform(self)
		end
		old_ZombRand = ZombRand
		ZombRand = FakeZombRand
		pcall(old_perform, self)
		ZombRand = old_ZombRand
	end
end





	
end)


do -- Замена функции, нужно сделать заранее.
	-- getPlayerMechanicsUI(0).listbox.items[2]
	local old_part_col
	local old_doDrawItem = ISVehicleMechanics.doDrawItem -- функция, которой заменяется одноименная в ISScrollingListBox
	ISVehicleMechanics.doDrawItem = function(self, y, item, ...)
		if not item.item.part then --print('check1')
			return old_doDrawItem(self, y, item, ...)
		end
		--local i = item.item.part:getInventoryItem()
		--if not i then --print('check2')
		--	return old_doDrawItem(self, y, item, ...)
		--end
		--local data = i:getModData() --print('ok')
		local col = item._exc_col
		if col then --print("CHANGE RGB!!!")
			old_part_col = self.parent.partRGB
			self.parent.partRGB = col
			local y = old_doDrawItem(self, y, item, ...)
			self.parent.partRGB = old_part_col
			return y
		end
		return old_doDrawItem(self, y, item, ...)
	end
end

--function setCol(c,r,g,b,a)c.r=r or c.r;c.g = g or c.g;c.b=b or c.b;c.a = a or c.a end
