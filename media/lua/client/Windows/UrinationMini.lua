if Excrementum then
	Excrementum._hash = Excrementum._hash + 2048
else
	return
end

UrinationMini = ExcrementumMini:derive("UrinationMini")

local COL_RED_STR = '<RGB:1,0,0>'
local COL_GREEN_STR = '<RGB:0,1,0>'
local COL_YELLOW_STR = '<RGB:1,1,0>'
local COL_RED = {r=1, g=0, b=0, a=.5}
local COL_GREEN = {r=0, g=1, b=0, a=.5}
local COL_YELLOW = {r=1, g=1, b=0, a=.5}

function UrinationMini:updateStatus()
	if not UrinationMini:isVisible() then
		return
	end

	local player = getSpecificPlayer(0)
	local urinate = Excrementum.urine
	
	local col, col_s;
	
	local X = 0.3 + Excrementum.Ms
	local Y = X + 0.15
	
	if (urinate <= .3) then
		col = COL_GREEN
		col_s = COL_GREEN_STR
	elseif (urinate <= X) then
		col = COL_YELLOW
		col_s = COL_YELLOW_STR
	else
		col = COL_RED
		col_s = COL_RED_STR
	end

	self.tooltip.description = getText("UI_Exc_UrinationMini", col_s, math.floor(urinate * 1000))
	
	local urinate = urinate * 1.333333 -- пытаемся масштабировать, чтобы 750мл (0.75) было 100%.
	if urinate > 1 then
		urinate = 1
	end
	self.innerPanel.height = -math.floor(urinate * self.max_height)
	self.innerPanel.backgroundColor = col
	
end


function UrinationMini.updateWindow()
	UrinationMini:updateStatus()
	ExcrementumWindow:saveWindow()
	UrinationMini:CheckPosition()
end

function UrinationMini:initialise()
	ExcrementumMini.initialise(self);
end

function UrinationMini:new(dx, offset)
	local _visible;
	local o, _visible = ExcrementumMini:new(dx, offset)
	setmetatable(o, self)
	self.__index = self
	UrinationMini = o
	o.borderColor = {r=.6, g=.5, b=0, a=1}
	if _visible then
		Excrementum.OnUpdate.Add(UrinationMini.updateWindow)
		--UrinationMini:updateStatus()
	end
	return o
end

Events.OnGameStart.Add(function()
	UrinationMini:new(20, 6)
end)