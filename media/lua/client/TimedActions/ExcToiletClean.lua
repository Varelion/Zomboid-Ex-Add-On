ExcToiletClean = ISBaseTimedAction:derive("ExcToiletClean");

function ExcToiletClean:isValid()
	return true
end

--function ExcToiletClean:waitToStart()
--	self.character:faceThisObject(self.generator)
--	return self.character:shouldBeTurning()
--end

function ExcToiletClean:update()
	if self.character_dir then
		self.character:setDir(IsoDirections[self.character_dir])
	end
end

function ExcToiletClean:start() --print('---START---')
	self.character:setIgnoreAimingInput(true)
	self:setActionAnim("flushclean")
	self.sound = getSoundManager():PlayWorldSound("Exc_Plunger", self.character:getCurrentSquare(), 0, 10, 0, true)
end

function ExcToiletClean:stop()
	self.character:setIgnoreAimingInput(false)
	if self.sound and self.sound:isPlaying() then
		self.sound:stop()
	end
  ISBaseTimedAction.stop(self);
end

function ExcToiletClean:waitToStart() --print('---WAIT_TO---')
	self.character:faceThisObjectAlt(self.toilet)
	return self.character:shouldBeTurning()
end

function ExcToiletClean:perform()
	self.character:setIgnoreAimingInput(false)
	--Excrementum.SendClientCommand("CleanToilet", self.toilet, 5, self.character)
	if self.sound and self.sound:isPlaying() then
		self.sound:stop()
	end
	Excrementum.UseToiletWater(self.character, self.toilet, 5, true)
	if self.plunger then
		self.plunger:Use()
	end
	ISBaseTimedAction.perform(self);
end

function ExcToiletClean:new(player, toilet, plunger)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = player
	o.toilet = toilet;
	o.plunger = plunger
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = 300;
	o.character_dir = Excrementum.GetDir(false, toilet) -- male/obj
	if o.character:isTimedActionInstant() then o.maxTime = 50; end
	return o;
end
