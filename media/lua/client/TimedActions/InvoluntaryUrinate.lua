if Excrementum then
	Excrementum._hash = Excrementum._hash + 2
else
	return
end
local OPTIONS = Excrementum.OPTIONS
local _empty = {}

InvoluntaryUrinate = ISBaseTimedAction:derive("InvoluntaryUrinate")
function InvoluntaryUrinate:isValid()
	if self.veh then
		return self.character:isSeatedInVehicle()
	end
	return true
end

function InvoluntaryUrinate:IsSoundUrinate()
	local opt = OPTIONS.pee_sound_types
	return opt == 1 or self.useToilet and opt == 3 or not self.useToilet and opt == 2
end
function InvoluntaryUrinate:IsSoundPeeSelf()
	local opt = OPTIONS.pee_sound_types
	return opt == 5 or self:IsSoundUrinate()
end


function InvoluntaryUrinate:update()	
	local delta = self:getJobDelta()
	if self.is_alpha and self.toiletObject then
		self.toiletObject:setAlpha(0.5)
	end
	if self.useToilet then
		if self.character_dir then
			self.character:setDir(IsoDirections[self.character_dir])
		end
	end
	local new_urine = (1 - delta) * self._urine
	Excrementum.urine = new_urine
	Excrementum.DoUpdate(self.character)
	if self.is_started then
		Excrementum.CheckShame(2)
	end
	
	if self.skip_perc and delta >= self.skip_perc then
		self.skip_perc = nil
		local player = self.character
		if (self.useToilet and self.pastToilet ~= true) then -- звонкий звук писания в воду
			if self:IsSoundUrinate() then
				self.world = getSoundManager():PlayWorldSound("Exc_UrinateProcess", player:getCurrentSquare(), 0, 15, 0, false)
			end
			addSound(player, player:getX(), player:getY(), player:getZ(), 10, 10) -- radius 10
		else -- глухой звук на землю
			if self:IsSoundUrinate() then
				self.world = getSoundManager():PlayWorldSound("Exc_UrinateOutside", player:getCurrentSquare(), 0, 15, 0, false)
			end
			addSound(player, player:getX(), player:getY(), player:getZ(), 5, 10)
		end
	end
	
	
	
end


function InvoluntaryUrinate:start()
	if self.pastToilet == true then
		self.useToilet = false
	end
	self.character:setIgnoreAimingInput(true)
	self:setOverrideHandModels(nil,nil)
	if Excrementum.urine < 0.1 then
		self:forceStop()
	end
	Excrementum._last_ev_tm = Excrementum.now
	self._urine = Excrementum.urine
	Excrementum.is_urine_update = false
	local player = self.character
	if not self.peeSelf then
		Excrementum.ResetShameCounter()
	end
	local is_veh = player:isSeatedInVehicle()
	if is_veh then
		self.veh = player:getVehicle()
		Excrementum.DoUrinateVehicle(player)
	end
	if not self.peeSelf or Excrementum.stats:getNumChasingZombies() < 2 then
		if player:isFemale() then
			self:setActionAnim(self.useToilet and "defecate_toilet" or "defecate_outside") --женское приседание
		else
			self:setActionAnim("urinate_Male") -- мужское приседание
		end
	end
end

function InvoluntaryUrinate:stop()
	local player = self.character
	player:setIgnoreAimingInput(false)
	Excrementum._last_ev_tm = Excrementum.now
	Excrementum.is_urine_update = true
	ISBaseTimedAction.stop(self)
	if Excrementum.urine >= 0.1 and self.skip_perc == nil then
		self:PeeSelf()
	end
end


function InvoluntaryUrinate:PeeSelf()
	local player = self.character
	Excrementum.nearestPlayers_monitor_type = false
	sendClientCommand(player, 'Exc', 'stop', {true})
	player:Say(getText(player:isFemale() and "UI_Exc_Say_Urinated_F" or "UI_Exc_Say_Urinated_M"))
	if self:IsSoundPeeSelf() then
		getSoundManager():PlayWorldSound("Exc_PeeSelf", player:getCurrentSquare(), 0, 15, 0, false)
	end

	--player:getStats():setStress(1)
	Excrementum.StressUpTo(0.6, player)
	local bd = player:getBodyDamage()
	Excrementum.AddUnhappyness(player, 11, 15)
	Excrementum.UrinateBottoms(player) -- double shame
	Excrementum.PutWorldUrine(player, 0.25)
	Excrementum.DoUrinate(player) -- vehicle, shame
	Excrementum.SendShameMomentToNearest(player, 3, true)
end

function InvoluntaryUrinate:perform()
	local player = self.character
	player:setIgnoreAimingInput(false)
	Excrementum._last_ev_tm = Excrementum.now
	Excrementum.is_urine_update = true
	local urinate = Excrementum.urine

	if self.peeSelf then
		return self:PeeSelf()
	end
	Excrementum.ResetShameCounter(91)

	if self.useToilet then -- унитаз
		if self.pastToilet == 1 then -- нет воды, но не переполнен
			--Excrementum.AddUnhappyness(player, 1, 0, 50)
		elseif self.pastToilet == true then -- мимо унитаза
			Excrementum.AddUnhappyness(player, 1, 0, 50)
			Excrementum.PutWorldUrine(player, 0.25)
		else
		--addSound(player, player:getX(), player:getY(), player:getZ(), 15, 10)
			local passed = Excrementum.now - Excrementum.exc.uTm
			local hours = math.floor(passed * 0.0166666667)
			Excrementum.AddUnhappyness(player, -math.max(1,math.min(5, hours))) -- не менее 1 и не более 5
		end
		if self.pastToilet ~= true and Excrementum:Laziness() < 80 and not Excrementum.URINAL_TEXTURES[self.toiletObject:getTextureName()] then
			--Excrementum.UseToiletWater(player, self.toiletObject, 5)
			local queue,action = Excrementum.WalkStandFace(player, self.toiletObject, nil, nil, true, self)
			if action then
				ISTimedActionQueue.addAfter(action, ExcToiletFlush:new(player,  self.toiletObject, 5));
			end
		end
	else
		--getSoundManager():PlayWorldSound("", player:getCurrentSquare(), 0, 15, 0, false)
		addSound(player, player:getX(), player:getY(), player:getZ(), 15, 10)
		if self.pastToilet then
			Excrementum.AddUnhappyness(player, 1, 0, 50) -- недостижимый код?
		else
			Excrementum.AddUnhappyness(player, Excrementum.LowerUnhappiness(4), 0, 50)
		end
		Excrementum.PutWorldUrine(player, 0.25)
	end
	ISBaseTimedAction.perform(self)
	
	ExcrementumWindow.updateWindow()
	
	--self:setActionAnim("zipfemale")
	Excrementum.DoUrinate(player, self.toiletObject)
end

-- довйной штраф за депрессию
function InvoluntaryUrinate:adjustMaxTime(maxTime)
	--(maxTime, uh_mult, min_part, max_part, temp)
	return Excrementum.adjustMaxTime(maxTime, 2)
end

function InvoluntaryUrinate:new(character, time, stopWalk, stopRun, peedSelf, useToilet, toiletObject, pastToilet, is_alpha)	
	--print("URINATE: ",useToilet,pastToilet,toiletObject)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = stopWalk
	o.stopOnRun = stopRun
	o.maxTime = time
	o.peeSelf = peedSelf
	o.pastToilet = pastToilet -- true=снаружи, 1=без спуска воды
	if toiletObject then
		o.useToilet = useToilet
		o.toiletObject = toiletObject
	end
	o.is_alpha = is_alpha

	if useToilet then
		o.character_dir = Excrementum.GetDir(character:isFemale(), toiletObject) -- true means "pee"
	end
	
	local adj = o:adjustMaxTime(time)
	if adj > time then
		o.skip_perc = (adj - time) / adj;
	else
		o.skip_perc = 0 -- nil означает, что действие уже началось и точка невозврата пройдена
	end

	return o
end

function Excrementum:InvoluntaryUrinate(is_forced)
	local player = Excrementum.p
	if not player or (Excrementum.urine < 0.1 and not is_forced) then
		return false
	end
	ISTimedActionQueue.clear(player)
	ISTimedActionQueue.add(InvoluntaryUrinate:new(player, 0, false, false, true))
	return true
end