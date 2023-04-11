if Excrementum then
	Excrementum._hash = Excrementum._hash + 1024
else
	return
end

DefecationMini = ExcrementumMini:derive("DefecationMini")

local COL_RED_STR = '<RGB:1,0,0>'
local COL_GREEN_STR = '<RGB:0,1,0>'
local COL_YELLOW_STR = '<RGB:1,1,0>'
local COL_RED = {r=1, g=0, b=0, a=.5}
local COL_GREEN = {r=0, g=1, b=0, a=.5}
local COL_YELLOW = {r=1, g=1, b=0, a=.5}



function DefecationMini:updateStatus()
	if not DefecationMini:isVisible() then
		return
	end

	local player = getSpecificPlayer(0)
	local defecate = Excrementum.feces	--player:getModData()["Defecate"]
	local threshold = Excrementum.feces_threshold
	
	local col, col_s;
	local col_g = nil
	local col_b = nil
	
	if defecate < 0.1 then
		col = COL_GREEN
		col_s = COL_GREEN_STR
	elseif player:getModData().exc.col.td then --can defecate
		col = COL_RED
		col_s = COL_RED_STR
	elseif defecate >= 0.33 then
		col = COL_YELLOW
		col_s = COL_YELLOW_STR
	else
		col = COL_GREEN
		col_s = COL_GREEN_STR
	end
	
	if defecate > 1 then
		defecate = 1
	end
	self.innerPanel.height = -math.floor(defecate * self.max_height)
	self.innerPanel.backgroundColor = col
	
	self.tooltip.description = getText("UI_Exc_DefecationMini", col_s, round(defecate * 100, 1))
end



function DefecationMini.updateWindow() --listener
	DefecationMini:updateStatus()
	ExcrementumWindow:saveWindow()
	DefecationMini:CheckPosition()
end

function DefecationMini:initialise()
	ExcrementumMini.initialise(self);
end

function DefecationMini:new(dx, offset)
	local _visible;
	local o, _visible = ExcrementumMini:new(dx, offset)
	setmetatable(o, self)
	self.__index = self
	DefecationMini = o
	o.borderColor = {r=.6, g=.3, b=0, a=1}
	if _visible then
		Excrementum.OnUpdate.Add(DefecationMini.updateWindow)
		--DefecationMini:updateStatus()
	end
	return o
end

Events.OnGameStart.Add(function()
	DefecationMini:new(0, 3)
end)