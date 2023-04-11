if Excrementum then
	Excrementum._hash = Excrementum._hash + 4
else
	return
end
--local OPTIONS = Excrementum.OPTIONS
local _empty = {}

DefecateDropPantsAction = ISBaseTimedAction:derive("DefecateDropPantsAction")
function DefecateDropPantsAction:isValid()
	return true
end

function DefecateDropPantsAction:update()
	if self.useToilet and self.character_dir then --print('TURN: ',self.character_dir)
		self.character:setDir(IsoDirections[self.character_dir])
	end
end

function DefecateDropPantsAction:waitToStart() -- true == wait
	--print("WAIT: ",self.character:getDir():name() == self.character_dir,self.character:getDir():name(), self.character_dir)
	if self.useToilet and self.character_dir then
		self.character:setDir(IsoDirections[self.character_dir])
		return self.character:getDir():name() ~= self.character_dir
	end
	return false
end

function DefecateDropPantsAction:start()
	self.character:setIgnoreAimingInput(true)
	self:setOverrideHandModels(nil,nil)
	if self.character:getModData().exc.col.td == nil then
		self:forceStop()
	end
	
	
	if (self.useToilet) then
		self:setActionAnim("unzipFemale") 
	else
		self:setActionAnim("unzipFemale")
	end 
end

function DefecateDropPantsAction:stop()
	self.character:setIgnoreAimingInput(false)
	if Excrementum.stats:getNumChasingZombies() == 0 then
		if (self.useToilet) then
			--self:setActionAnim("zipFemale") 
		else
			--self:setActionAnim("zipFemale")
		end 
	end
	ISBaseTimedAction.stop(self)
end

function DefecateDropPantsAction:perform()
	local player = self.character
	player:setIgnoreAimingInput(false)

	--self.character:setPrimaryHandItem(nil)
	--self.character:setSecondaryHandItem(nil)

	getSoundManager():PlayWorldSound("PutItemInBag", player:getCurrentSquare(), 0, 2, 0, true)

	local arr_pants = Excrementum.GetAllPantsGroin(player)
	if Excrementum.DEBUG then
		local s = "DROPPED PANTS = " .. (arr_pants and #arr_pants or 0) .. "\n"
		if arr_pants then
			for i,v in ipairs(arr_pants) do
				s = s .. "\t" .. v:getType()
			end
		end
		print(s)
	end
	if arr_pants then
		for _,v in pairs(arr_pants) do
			player:removeWornItem(v)
		end
	end
	ISInventoryPage.renderDirty = true
	triggerEvent("OnClothingUpdated", self.character)

	
	Excrementum.WearAll(player, arr_pants, self)
	ISTimedActionQueue.addAfter(self, InvoluntaryDefecate:new(player, 200, true, true, false, self.useToilet, self.toiletObject, self.paper, self.is_alpha))

	ISBaseTimedAction.perform(self)
end

function DefecateDropPantsAction:adjustMaxTime(x)
	return x
end

function DefecateDropPantsAction:new(character, time, useToilet, toiletObject, paper, is_alpha)
	--print('DropPants: { time='..tostring(time)..', useToilet='..tostring(useToilet)..', object='..tostring(toiletObject).. ' }')
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character
	o.stopOnWalk = true
	o.stopOnRun = true
	o.maxTime = time
	o.useToilet = useToilet
	o.toiletObject = toiletObject
	o.paper = paper
	o.is_alpha = is_alpha
	
	local arr_pants = Excrementum.GetAllPantsGroin(character)
	if arr_pants and #arr_pants == 1 and arr_pants[1]:getBodyLocation() == 'UnderwearBottom' then
		o.maxTime = 20 --трусы оч. быстро
	end

	if useToilet then --print('use_toilet')
		o.character_dir = Excrementum.GetDir(true, toiletObject)
		--print('dir = ',o.character_dir)
	end
	
	return o
end 
