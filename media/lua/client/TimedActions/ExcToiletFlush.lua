ExcToiletFlush = ISBaseTimedAction:derive("ExcToiletFlush");

function ExcToiletFlush:isValid()
	return true
end

function ExcToiletFlush:update()
	if self.character_dir then
		self.character:setDir(IsoDirections[self.character_dir])
	end
end

function ExcToiletFlush:start()
	self.character:setVariable("AnimSpeed", self.AnimSpeed)
	self:setActionAnim("washaway")
	local left_hand = self.character:getSecondaryHandItem()
	if left_hand and left_hand:isTwoHandWeapon() then
		left_hand = nil
	end
	self:setOverrideHandModels(nil, left_hand); -- убираем что бы то ни было из правой руки
end

function ExcToiletFlush:stop()
	if self.is_dirt_on_fail then
		Excrementum.AddToiletDirt(self.character, self.toilet)
	end
	ISBaseTimedAction.stop(self);
end

function ExcToiletFlush:perform()
	ISBaseTimedAction.perform(self);
	if not Excrementum.UseToiletWater(self.character, self.toilet, self.units, true) then
		if self.is_dirt_on_fail then
			Excrementum.AddToiletDirt(self.character, self.toilet)
		end
		self.character:Say(getText("ContextMenu_ExToiletNeedWater"))
	end
end

function ExcToiletFlush:new(character, toilet, units, is_dirt_on_fail)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.toilet = toilet
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.units = units or 5;
	o.maxTime = 80;
	o.AnimSpeed = 0.8 * o.maxTime / o:adjustMaxTime(o.maxTime)
	o.character_dir = Excrementum.GetDir(false, toilet)
	o.is_dirt_on_fail = is_dirt_on_fail
	return o;
end
