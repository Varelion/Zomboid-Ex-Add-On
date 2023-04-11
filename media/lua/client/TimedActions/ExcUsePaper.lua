if Excrementum then
	Excrementum._hash = Excrementum._hash + 32
else
	return
end

ExcUsePaper = ISBaseTimedAction:derive("ExcUsePaper");

function ExcUsePaper:isValid()
	return self.inv:contains(self.item) --and not self.item:isEquipped()
		and self.mod_data and self.mod_data.ass and true
end

function ExcUsePaper:update()
	self.item:setJobDelta(self:getJobDelta());
	self.item:setJobType(getText("ContextMenu_ExWiping"));
end

function ExcUsePaper:waitToStart() -- true == wait, костыль
	--if self.item:isEquipped() then
	--	
	--	return true
	--end
	return false
end

function ExcUsePaper:start()
	self.character:setIgnoreAimingInput(true)
	self.sound = self.character:playSound("Exc_Wiping");
	self:setActionAnim("wipingstand");
end

function ExcUsePaper:stop()
	self.character:setIgnoreAimingInput(false)
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ExcUsePaper:perform()
	local player = self.character
	player:setIgnoreAimingInput(false)
	--print('perform: ',self.item)
	local is_recent = Excrementum.now - (Excrementum.exc.ass_tm or 0) < 120
	if Excrementum.UseToiletPaper(player, self.item) then
		if is_recent then
			Excrementum.AddUnhappyness(player, -10) --сразу
		else
			Excrementum.AddUnhappyness(player, -5) --прошло 2 часа
		end
	end


	--getSoundManager():PlayWorldSound("Exc_ExcractFeces", self.character:getCurrentSquare(), 0, 10, 0, false)
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.perform(self);
end

function ExcUsePaper:new(character, time, item)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.inv = character:getInventory()
	o.item = item;
	o.stopOnWalk = false;
	o.stopOnRun = true;
	o.maxTime = time;
	o.mod_data = character:getModData().exc
	return o;
end
