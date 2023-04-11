if Excrementum then
	Excrementum._hash = Excrementum._hash + 1
else
	return
end
local OPTIONS = Excrementum.OPTIONS
local _empty = {}

InvoluntaryDefecate = ISBaseTimedAction:derive("InvoluntaryDefecate")

function InvoluntaryDefecate:isValid()
	if not (self.done or Excrementum.feces >= 0.1) then
		return false
	end
	if self.veh then
		return self.character:isSeatedInVehicle()
	end
	return true
end

function InvoluntaryDefecate:IsSoundDefecate(is_fart, is_self)
	local opt = OPTIONS.poo_sound_types
	if opt == 1 then
		return true
	end
	if opt >= 6 then
		if is_self and opt == 7 then
			return true
		end
		return false
	end
	if opt == 2 then
		return is_fart
	elseif opt == 3 then
		return not is_fart
	end
	return opt == 5 and self.useToilet or opt == 4 and not self.useToilet
end



-- get how much % of the book we already read, then we apply a multiplier depending on the book read progress
InvoluntaryDefecate.checkBookMultiplier = function(player, book)
	local trainedStuff = SkillBook[book:getSkillTrained()];
	if not trainedStuff then
		return
	end

	local lvl_skill = book:getLvlSkillTrained()
	local maxMultiplier = 1
	if lvl_skill == 1 then
		maxMultiplier = trainedStuff.maxMultiplier1;
	elseif lvl_skill == 3 then
		maxMultiplier = trainedStuff.maxMultiplier2;
	elseif lvl_skill == 5 then
		maxMultiplier = trainedStuff.maxMultiplier3;
	elseif lvl_skill == 7 then
		maxMultiplier = trainedStuff.maxMultiplier4;
	elseif lvl_skill == 9 then
		maxMultiplier = trainedStuff.maxMultiplier5;
	else
		print("ERROR: bad skill or book!")
	end

	-- every 10% we add 10% of the max multiplier
	local readPercent = (book:getAlreadyReadPages() / book:getNumberOfPages()) * 100;
	if readPercent > 100 then
		readPercent = 100;
	end
	-- apply the multiplier to the skill
	local multiplier = (math.floor(readPercent/10) * (maxMultiplier/10));
	if multiplier > player:getXp():getMultiplier(trainedStuff.perk) then
		player:getXp():addXpMultiplier(trainedStuff.perk, multiplier, book:getLvlSkillTrained(), book:getMaxLevelTrained());
	end
end


local sound_outside = {"Exc_fart1", "Exc_fart2", "Exc_fart3", "Exc_fart5"}
local sound_fart = {"Exc_fart4", "Exc_fart6", "Exc_fart7"}
function InvoluntaryDefecate:update()
	if self.is_alpha and self.useToilet then
		self.toiletObject:setAlpha(0.5)
	end
	if self.character_dir then
		--if self.useToilet then
		self.character:setDir(IsoDirections[self.character_dir])
	end
	local delta = self:getJobDelta() --print('delta ',delta)
	if delta >= self.skip_perc then -- игнорируем задержку
		delta = (delta - self.skip_perc) * self.mult_perc -- переводим в проценты реального действия
		--print('new_delta ',delta)
		if not self.pooSelf and not self.done and delta > 0.5 - (self.useToilet and 0.25 or 0) then -- половина прогресса
			local player = self.character
			self.done = true
			--print("POO DONE !!!!")
			if (self.useToilet) then
				if self:IsSoundDefecate(false, false) then
					self:RndSound("Exc_DefecateProcess1", 15, true)
				end
			else
				if self:IsSoundDefecate(false, false) then
					self:RndSound(sound_outside, 15, true)
				end
			end
			if self.book then
				Excrementum.exc.bk = Excrementum.now
				local num = self.book:getNumberOfPages()
				local already = self.character:getAlreadyReadPages(self.book:getFullType())
				local new = math.floor(already + self.book_pages)
				if new > num then
					new = num
				end
				local delta = math.floor(new - already) print('Delta: ',delta)
				if delta > 0 then
					player:setHaloNote(getText("UI_Exc_PagesChange", delta), 255,100,255, 200)
				end
				self.book:setAlreadyReadPages(new)
				self.character:setAlreadyReadPages(self.book:getFullType(), new)
				self.checkBookMultiplier(self.character, self.book)
			end
			if not self.useToilet then
				Excrementum.PutWorldFeces(player)
			end
			Excrementum.DoDefecate(player)
		end
	end
	if self.is_started then
		Excrementum.CheckShame(2, false, true)
	end
end

function InvoluntaryDefecate:start()
	local player = self.character
	player:setIgnoreAimingInput(true)
	self:setOverrideHandModels(nil,nil)
	Excrementum._last_ev_tm = Excrementum.now
	if not self.pooSelf then
		Excrementum.ResetShameCounter()
	end
	if player:getModData().exc.col.td == nil then
		self:forceStop()
	end
	
	if not self.pooSelf or Excrementum.stats:getNumChasingZombies() < 2 then
		if (self.useToilet) then
			
			if self.book then
				--self:setAnimVariable("ReadType", "book")
				self:setActionAnim("defecate_book");
				self:setOverrideHandModels(nil, self.book);
			else
				self:setActionAnim("defecate_toilet")
			end
		else
			self:setActionAnim("defecate_outside") 
		end
	end
	
end

function InvoluntaryDefecate:RndSound(arr, radius, attract)
	local player = self.character
  radius = radius or 15
	local sound = type(arr) == 'string' and arr or arr[ZombRand(#arr)+1]
	self.sound = getSoundManager():PlayWorldSound(sound, player:getCurrentSquare(), 0, radius , 0, false)
	if attract then
		addSound(player, player:getX(), player:getY(), player:getZ(), radius , 10)
	end
end

function InvoluntaryDefecate:stop() --print('STOPPED at ', self:getJobDelta())
	local player = self.character
	player:setIgnoreAimingInput(false)
	Excrementum._last_ev_tm = Excrementum.now
	if self.sound and self.sound:isPlaying() then
		self.sound:stop()
	end
	ISBaseTimedAction.stop(self)
	if self.done then -- личинка уже вышла, прерывать нельзя
		self:PooSelf()
		ExcrementumWindow.updateWindow()
	end
end

function InvoluntaryDefecate:PooSelf()
	local player = self.character
	player:Say(getText(player:isFemale() and "UI_Exc_Say_Defecated_F" or "UI_Exc_Say_Defecated_M"))

	--player:getStats():setStress(1)
	Excrementum.StressUpTo(0.6, player)
	local bd = player:getBodyDamage()
	Excrementum.CheckAss(player, 2)
	local uh = Excrementum.AddUnhappyness(player, 20, 21)
	if uh > 99 then -- Пока обосраться можно только на толчке
		Excrementum.AddFatigue(player, 0.02)
	end
	if not self.done then
		if self:IsSoundDefecate(false, true) then
			self:RndSound(sound_outside, 15, true)
		end
		--Excrementum.PutWorldFeces(player)
		Excrementum.DoDefecate(player)
	else
		if self:IsSoundDefecate(true, true) then
			self:RndSound(sound_fart, 5, false)
		end
	end

	Excrementum.DefecateBottoms(player)
	Excrementum.SendShameMomentToNearest(player, 3, true)
end

function InvoluntaryDefecate:perform()
	Excrementum._last_ev_tm = Excrementum.now
	--if self.sound and self.sound:isPlaying() then
	--	self.sound:stop()
	--end
	
	local player = self.character
	player:setIgnoreAimingInput(false)
	
	if (self.pooSelf) then
		return self:PooSelf()
		--self:setActionAnim("zipfemale")
	end
	Excrementum.ResetShameCounter(92)
	
	local paper = self.paper

	
	if (self.useToilet) then -- на унитазе
		--addSound(player, player:getX(), player:getY(), player:getZ(), 15 , 10)
		
		if Excrementum.UseToiletPaper(player, paper) then -- смог подтереться
			Excrementum.AddUnhappyness(player, -10)
			--Excrementum.CheckAss(player, false) -- удалить грязь (если есть)
		else -- не смог, попа грязная теперь
			--Excrementum.AddUnhappyness(player, 0)
			Excrementum.CheckAss(player, true) -- добавить говно-грязь на попу
		end
		
		local is_outhouse = Excrementum.TOILET_TEXTURES[self.toiletObject:getTextureName()]
		is_outhouse = type(is_outhouse) == 'table' and is_outhouse[1] == -1 or is_outhouse == -1
		
		if is_outhouse then
			-- do nothing
		elseif Excrementum:Laziness() >= 80 then
			Excrementum.AddToiletDirt(player, self.toiletObject)
		else
			local queue,action = Excrementum.WalkStandFace(player, self.toiletObject, nil, nil, true, self)
			if not action then
				Excrementum.AddToiletDirt(player, self.toiletObject)
			else
				ISTimedActionQueue.addAfter(action, ExcToiletFlush:new(player,  self.toiletObject, 5, true));
			end
		end

	else -- в поле
		--print('OUTSIDE')
		if not self.done then
			Excrementum.PutWorldFeces(player)
		end

		if Excrementum.UseToiletPaper(player, paper) then -- смог подтереться листом
			local uh = Excrementum.AddUnhappyness(player, Excrementum.LowerUnhappiness(5), 0, 70)
			if uh > 80 then
				Excrementum.AddFatigue(player, 0.01)
			end
			--Excrementum.CheckAss(player, false)
		else -- не смог, попа грязная теперь
			local uh = Excrementum.AddUnhappyness(player, 10 + Excrementum.LowerUnhappiness(5), 21, 70)
			Excrementum.CheckAss(player, true)
			if uh >= 70 then
				Excrementum.AddFatigue(player, uh > 80 and 0.02 or 0.01)
			end
		end
		
	end
	ISBaseTimedAction.perform(self)
	--getSoundManager():PlayWorldSound("Exc_fart4", player:getCurrentSquare(), 0, 5 , 0, false) -- вишенка на торте

	if self:IsSoundDefecate(true, false) then
		self:RndSound(sound_fart, 5, false)
	end

	--self:setActionAnim("zipfemale")
	if not self.done then
		Excrementum.DoDefecate(self.character, self.toiletObject)
	end
end


-- тройной штраф за депрессию и боль в животе, но не более x6
function InvoluntaryDefecate:adjustMaxTime(maxTime)
	--(maxTime, uh_mult, min_part, max_part, temp)
	return math.min(maxTime*6, Excrementum.adjustMaxTime(maxTime, 3, "Torso_Lower", 3))
end


local PERKS = STAR_MODS.PERKS
if not PERKS then
	PERKS = {}
	for i=0,PerkFactory.PerkList:size()-1 do
		local perk=PerkFactory.PerkList:get(i)
		PERKS[perk:getId()] = perk
	end
	STAR_MODS.PERKS = PERKS
	--player:getPerkLevel(perk?) getType
end

local function findBookToRead(player) --print("recurse find")
	local found, foundCanRead = nil --первая найденная
	local inv = player:getInventory()
	--local exc = Excrementum.exc
	local max_read = 50 --pages
	local list = inv:getItemsFromCategory("Literature")
	--print("SIZE: ",list:size()," - ",inv)
	for i=0,list:size()-1 do
		local book = list:get(i)
		local data = SkillBook[book:getSkillTrained()]
		local typ = data and data.perk:getId()
		--print(typ, ' ',book:getFullType(),' - ',typ)
		if typ ~= "" then
			local perk = PERKS[typ]
			if perk then
				local level = player:getPerkLevel(perk:getType())
				if level >= book:getLvlSkillTrained()-1 and level <= book:getMaxLevelTrained()-1
					--and CheckBookIsNeeded(player, book)
				then
					--print('Found: ',book:getType())
					--table.insert(books, book) -- for sorting
					local num_pages = book:getNumberOfPages()
					local delta = num_pages - player:getAlreadyReadPages(book:getFullType())
					local can_read = math.min(max_read, delta)
					if can_read > 0 then
						if book:isFavorite() then
							return book, can_read
						end
						if found then
							if can_read > foundCanRead then
								found = book
								foundCanRead = can_read
							end
						else
							found = book
							foundCanRead = can_read
						end
					end
				end
			end
		end
	end
	return found, foundCanRead
end


function InvoluntaryDefecate:new(character, time, stopWalk, stopRun, poopSelf, useToilet, toiletObject, paper, is_alpha)	
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.pooSelf = poopSelf
	if toiletObject then
		o.useToilet = useToilet
		o.toiletObject = toiletObject
		if useToilet and Excrementum.now-Excrementum.exc.bk > 5 * 60 then
			o.book, o.book_pages = findBookToRead(character)
		end
	end
	o.paper = paper
	o.is_alpha = is_alpha
	o.done = false
	--o.book = character:getInventory():FindAndReturnCategory("Literature")
	
	if useToilet then
		o.character_dir = Excrementum.GetDir(true, toiletObject)
	end
	
	local adj = o:adjustMaxTime(time)
	if adj > time then
		o.skip_perc = (adj - time) / adj;
	else
		o.skip_perc = 0 -- nil означает, что действие уже началось и точка невозврата пройдена
	end
	o.mult_perc = 1 / (1 - o.skip_perc); -- множитель для возврата к нормальным процентам
	
	return o
end

function Excrementum:InvoluntaryDefecate(is_forced)
	local player = Excrementum.p
	if not player or (Excrementum.feces < 0.1 and not is_forced) then
		return false
	end
	ISTimedActionQueue.clear(player)
	ISTimedActionQueue.add(InvoluntaryDefecate:new(player, 0, false, false, true))
	return true
end