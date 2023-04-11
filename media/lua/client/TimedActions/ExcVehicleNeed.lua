ExcVehicleNeed = ISBaseTimedAction:derive("ExcVehicleNeed");

function ExcVehicleNeed:isValid()
	return self.character:isSeatedInVehicle()
end

--function ExcVehicleNeed:waitToStart()
--	self.character:faceThisObject(self.generator)
--	return self.character:shouldBeTurning()
--end

function ExcVehicleNeed:update()
end

function ExcVehicleNeed:start()
	self:setActionAnim("flushclean")
	getSoundManager():PlayWorldSound("Exc_Plunger", self.character:getCurrentSquare(), 0, 10, 0, true)
end

function ExcVehicleNeed:stop()
  ISBaseTimedAction.stop(self);
end

function ExcVehicleNeed:perform()
	--Excrementum.SendClientCommand("CleanToilet", self.toilet, 5, self.character)
	Excrementum.UseToiletWater(self.character, self.toilet, 5, true)
	if self.plunger then
		self.plunger:Use()
	end
	ISBaseTimedAction.perform(self);
end

function ExcVehicleNeed:new(player, toilet, plunger)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = player
	o.toilet = toilet;
	o.plunger = plunger
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.maxTime = 300;
	if o.character:isTimedActionInstant() then o.maxTime = 50; end
	return o;
end
