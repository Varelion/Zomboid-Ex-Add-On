if Excrementum then
	Excrementum._hash = Excrementum._hash + 64
else
	return
end

ExcTearABook = ISBaseTimedAction:derive("ExcTearABook");

function ExcTearABook:isValid()
	return self.inv:contains(self.item)
end

function ExcTearABook:update()
	self.item:setJobDelta(self:getJobDelta());
	self.item:setJobType(getText("ContextMenu_ExTearingABook"));
end

function ExcTearABook:start()
	self.sound = self.character:playSound("ClothesRipping");
	self:setActionAnim("Loot");
end

function ExcTearABook:stop()
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.stop(self);
end

function ExcTearABook:perform()
	for i=1, self.pages do
		local sheet = InventoryItemFactory.CreateItem("Base.SheetPaper2");
		self.inv:AddItem(sheet)
	end
	if self.pages > 0 then
		self.inv:Remove(self.item)
	end

	Excrementum.AddBoredom(self.character, -15)
	
	--getSoundManager():PlayWorldSound("Exc_ExcractFeces", self.character:getCurrentSquare(), 0, 10, 0, false)
	self.item:setJobDelta(0.0);
	ISBaseTimedAction.perform(self);
end

function ExcTearABook:new(character, item, time, sheets)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.inv = character:getInventory()
	o.item = item;
	o.stopOnWalk = false;
	o.stopOnRun = true;
	o.maxTime = time;
	o.pages = sheets or 0
	return o;
end
