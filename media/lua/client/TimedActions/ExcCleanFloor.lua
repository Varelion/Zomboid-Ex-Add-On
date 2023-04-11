ExcCleanFloor = ISBaseTimedAction:derive("ExcCleanFloor");

function ExcCleanFloor:isValid()
	return self.inv:contains(self.soap) and 
		(self.victim and true or self.sq == self.character:getCurrentSquare() and self.dat.ex_sml and self.dat.ex_sml > 0);
end

function ExcCleanFloor:update()
	self.soap:setJobDelta(self:getJobDelta());
	self.soap:setJobType(getText("ContextMenu_Consuming"));

	if self.mop then
		self.mop:setJobDelta(self:getJobDelta());
		self.mop:setJobType(getText("ContextMenu_ExScrub"));
	end
	
	if self.victim then
		self.victim:setJobDelta(self:getJobDelta());
		self.victim:setJobType(getText("ContextMenu_ExScrub"));
	end
end

function ExcCleanFloor:start()
	local item = self.mop
	local player = self.character
	player:setIgnoreAimingInput(true)
	self:setActionAnim("Loot");
	player:SetVariable("LootPosition",
		self.victim and self.victim:getWeight() < 3.001 and "Mid" or "Low"
	)
	player:setHaloNote(self.soap:getDisplayName(), 255,100,255, 200) -- показываем название предмета, который используем
	self.sound = player:playSound("Exc_CleanFloor");
	if item then
		local target = Excrementum.HOUSEHOLD[item:getFullType()]
		if type(target) == 'string' then -- превращение предмета в грязную версию
			item = InventoryItemFactory.CreateItem(target);
			if item then
				self.inv:Remove(self.mop)
				self.inv:AddItem(item)
				self.mop = item
			else
				item = self.mop
			end
		end
	end
	if item:getType() ~= "Sponge" then
		local item_data = item:getModData()
		if self.victim and self.victim:getModData().feces then
			if not item_data.feces then
				item_data.feces = 0
				Excrementum.UpdateSmellMoodle(player)
			end
		else
			if not item_data.urine then
				item_data.urine = true
				Excrementum.UpdateSmellMoodle(player)
			end
		end
	end
	self:setOverrideHandModels(nil, self.soap:getStaticModel()) -- item -- выключено, ибо швабра кривая, остальное невидимое
end

function ExcCleanFloor:stop()
	self.character:setIgnoreAimingInput(false)
	self.soap:setJobDelta(0);
	if self.mop then
		self.mop:setJobDelta(0);
	end
	if self.victim then
		self.victim:setJobDelta(0);
	end
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
	ISBaseTimedAction.stop(self);
end

function ExcCleanFloor:perform()
	self.character:setIgnoreAimingInput(false)
	self.soap:setJobDelta(0);
	if self.mop then
		self.mop:setJobDelta(0);
	end
	if self.victim then
		self.victim:setJobDelta(0);
	end
	if self.sound and self.character:getEmitter():isPlaying(self.sound) then
		self.character:stopOrTriggerSound(self.sound);
	end
	local player = self.character
	--consuming soup
	do
		local item = self.soap
		local val = Excrementum.CLEANING[item:getFullType()] or 1
		if val == true then
			val = 1
		end
		if instanceof(item, "Food") then -- food
			local h = item:getHungChange()
			if h < 0 then
				if -h < val then
					item:Use()
				else
					item:setHungChange(h + val)
					h = item:getHungChange()
					if h > -0.001 then
						item:Use()
					end
				end
			else
				local w = item:getThirstChange()
				if w < 0 then
					if -w < val then
						item:Use()
					else
						item:setThirstChange(w + val)
						w = item:getThirstChange()
						if w > -0.001 then
							item:Use()
						end
					end
				else
					item:Use()
				end
			end
		else -- drainable
			if type(val) == 'number' then
				for i=1,val do
					item:Use()
				end
			end
		end
	end

	--clean
	if self.victim then
		if self.victim:hasTag('ESmell') then
			self.victim:Use()
		else
			local data = self.victim:getModData()
			data.feces = nil
			data.urine = nil
		end
		Excrementum.UpdateSmellMoodle(player)
		Excrementum.AddBoredom(player, 25)
	else
		local val = self.dat.ex_sml
		local new_val = (val - 1) * 0.5
		if new_val < 0 then
			new_val = 0
		end
		local delta = new_val - val
		if delta < 0 then
			Excrementum.PutWorldUrine(self.character, delta) -- чистим пол, выводим запах (кладём отрицательное значение)
			--Excrementum.UpdateSmellMoodle(player, -1)
		end
		Excrementum.AddBoredom(player, 25)
	end

	
	ISBaseTimedAction.perform(self);
end

function ExcCleanFloor:new(character, time, square, soap, mop, victim)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	o.inv = character:getInventory()
	o.square = square
	o.soap = soap
	o.mop = mop
	o.victim = victim
	o.stopOnWalk = true;
	o.stopOnRun = true;
	
	local typ = soap:getType()
	if typ == 'CleaningLiquid2' then
		time = time - 300 -- 500
	elseif typ == 'Bleach' then
		time = time - 500 -- 300
	end
	o.maxTime = time; -- 800?
	
	if not victim then
		local sq = character:getCurrentSquare()
		if sq then
			o.sq = sq
			local room = sq:getRoom()
			if not room then
				o.sq = nil
			else
				local sq0 = room:getSquares():get(0)
				o.dat = sq0:getModData()
				if not o.dat then
					o.sq = nil
				end
			end
		end
	end
	
	return o;
end
