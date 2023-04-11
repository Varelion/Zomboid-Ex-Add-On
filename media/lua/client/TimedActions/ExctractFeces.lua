if Excrementum then
	Excrementum._hash = Excrementum._hash + 16
else
	return
end
local OPTIONS = Excrementum.OPTIONS

ExctractFeces = ISBaseTimedAction:derive("ExctractFeces");

function ExctractFeces:isValid()
	if not self.inv:contains(self.item) then
		return false
	end
	return self.data and self.data.feces and self.data.feces >= 0.21
end

function ExctractFeces:update()
	self.item:setJobDelta(self:getJobDelta());
	self.item:setJobType(getText("ContextMenu_ExFeces_Short"));
end

function ExctractFeces:start()
	local feces = self:getFecesCount()
	if not feces then
		return self:forceStop()
	end
	self.feces_cnt = feces
	if OPTIONS.extract_sound then
		self.sound = self.character:playSound("Exc_ExcractFeces");
	end
	self:setActionAnim("Loot");
	--self.character:SetVariable("LootPosition", "Low")
	--self.character:SetVariable("LootPosition", "Mid")
	--self:setOverrideHandModels(self.item:getStaticModel(), nil)
	-- Две какашки в руках, если их много вытаскивать.
	self:setOverrideHandModels(feces > 0 and "Base.D_Feces1" or nil, feces > 1 and "Base.D_Feces1" or nil)
	Excrementum.MakeDirtHands(self.character)
end

function ExctractFeces:stop()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ExctractFeces:perform()
	local player = self.character
	if self.sound and player:getEmitter():isPlaying(self.sound) then
		player:stopOrTriggerSound(self.sound);
	end


	local item = self.item
	local feces = 0

	if self.is_bucket then
		feces = math.floor((item:getUsedDelta() + 0.001) / item:getUseDelta())
		item:setUsedDelta(0)
		item:Use()
	else
		local data = item:getModData()
		feces = data.feces or 0
		data.feces = 0 -- запах остаётся, нужно долго отстирывать
		if feces < 0.21 then
			feces = 0 -- если совсем мало, то не достаём вообще
		end
	end

	if feces > 0 then
		Excrementum.AddUnhappyness(player, 15 * feces, 21)

		while feces >= 0.21 do
			local fc = Excrementum.GetRandomFeces()
			self.inv:AddItem(fc)
			feces = feces - 1
		end
	end
	
	--getSoundManager():PlayWorldSound("Exc_ExcractFeces", self.character:getCurrentSquare(), 0, 10, 0, false)
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.perform(self);
	
	--Excrementum.MakeDirtHands(player) -- in start()
end

function ExctractFeces:getFecesCount()
	local item = self.item
	if self.is_bucket then
		return math.floor((item:getUsedDelta() + 0.001) / item:getUseDelta())
	end
	local data = item:getModData()
	return data.feces
end

function ExctractFeces:new(character, item, time, is_bucket)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.inv = character:getInventory()
	o.item = item;
	o.data = item:hasModData() and item:getModData()
	o.stopOnWalk = false;
	o.stopOnRun = true;
	o.maxTime = time;
	o.is_bucket = is_bucket
	return o;
end
