if Excrementum then
	Excrementum._hash = Excrementum._hash + 8
else
	return
end
--local OPTIONS = Excrementum.OPTIONS
local _empty = {}

UrinateDropPantsAction = ISBaseTimedAction:derive("UrinateDropPantsAction")
function UrinateDropPantsAction:isValid()
	return true
end



function UrinateDropPantsAction:update()
	if self.useToilet and self.character_dir then --print('TURN: ',self.character_dir)
		self.character:setDir(IsoDirections[self.character_dir])
	end
end

function UrinateDropPantsAction:waitToStart()
	--print("WAIT: ",self.character:getDir():name() == self.character_dir,self.character:getDir():name(), self.character_dir)
	if self.useToilet and self.character_dir then
		self.character:setDir(IsoDirections[self.character_dir])
		return self.character:getDir():name() ~= self.character_dir
	end
	return false
end

function UrinateDropPantsAction:start()
	self.character:setIgnoreAimingInput(true)
	self:setOverrideHandModels(nil,nil)
	if self.is_zipMaleSound then
		self:setActionAnim("unzipmale")
		return
	end
	if self.useToilet then
		self:setActionAnim("unzipFemale") 
	else
		self:setActionAnim("unzipFemale")
	end
end

function UrinateDropPantsAction:stop()
	self.character:setIgnoreAimingInput(false)
	ISBaseTimedAction.stop(self)
	ExcrementumWindow.updateWindow()
end

function UrinateDropPantsAction:perform()
	local player = self.character
	player:setIgnoreAimingInput(false)

	local arr_pants;
	if self.is_fem then
		arr_pants = Excrementum.GetAllPantsGroin(player)
	else
		arr_pants = Excrementum.GetAllPantsGroin(player, true)
	end
	if self.is_zipMaleSound then
		getSoundManager():PlayWorldSound("PZ_CloseBagQ", self.character:getCurrentSquare(), 0, 2, 0, true)
	else
		getSoundManager():PlayWorldSound("PutItemInBag", player:getCurrentSquare(), 0, 2, 0, true)
	end
		
	
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
		ISInventoryPage.renderDirty = true
		triggerEvent("OnClothingUpdated", self.character)
	end

	Excrementum.WearAll(player, arr_pants, self)
	ISTimedActionQueue.addAfter(self, InvoluntaryUrinate:new(player, 200, true, true, false, self.useToilet, self.toiletObject, self.pastToilet, self.is_alpha))

	ISBaseTimedAction.perform(self)
end

function UrinateDropPantsAction:adjustMaxTime(x)
	return x
end

function UrinateDropPantsAction:new(character, time, useToilet, toiletObject, pastToilet, is_alpha)
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
	o.is_fem = character:isFemale()
	o.pastToilet = pastToilet
	o.is_alpha = is_alpha
	
	if not o.is_fem then
		o.is_zipMaleSound = not Excrementum.GetAllPantsGroin(character, true)
		if o.is_zipMaleSound then
			o.maxTime = 40
		end
	end
	
	if useToilet then --print('use_toilet')
		o.character_dir = Excrementum.GetDir(o.is_fem, toiletObject)
		--print('dir = ',o.character_dir)
	end
	
	return o
end