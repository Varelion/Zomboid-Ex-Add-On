if Excrementum then
	Excrementum._hash = Excrementum._hash + 256
else
	return
end

ExcrementumMini = ISPanel:derive("ExcrementumMini")

function ExcrementumMini:initialise()
	ISPanel.initialise(self);
end

function ExcrementumMini:onRightMouseUp(x, y)
	ExcrementumWindow:setVisible(true)
	ExcrementumWindow.updateWindow()
	
	UrinationMini:setVisible(false)
	DefecationMini:setVisible(false)
	
	UrinationMini.tooltip:setVisible(false)
	UrinationMini.tooltip:removeFromUIManager()
	UrinationMini.tooltip.followMouse = false

	DefecationMini.tooltip:setVisible(false)
	DefecationMini.tooltip:removeFromUIManager()
	DefecationMini.tooltip.followMouse = false
	
	Excrementum.OnUpdate.Add(ExcrementumWindow.updateWindow)
	Excrementum.OnUpdate.Remove(DefecationMini.updateWindow)
	Excrementum.OnUpdate.Remove(UrinationMini.updateWindow)
	
	ExcrementumWindow:saveWindow()
end


function ExcrementumMini:MinimalDisplayBarsCompatible()
	self:setWidth(8)
	self:setHeight(150)
	self.innerPanel:setX(2)
	self.innerPanel:setY(147)
	self.innerPanel:setWidth(4)
	self.max_height = 144
	local border = self.borderColor
	--border.r = 0.5
end

local _empty_fn = function()end
function ExcrementumMini:createChildren()
	ISPanel.createChildren(self)

	self.innerPanel = ISPanel:new(1, 101, 10, 96)
	self.innerPanel.backgroundColor = {r=1, g=1, b=0, a=.5}
	self.innerPanel.moveWithMouse = true
	self.innerPanel.onRightMouseUp = ExcrementumWindow.onRightMouseUp
	self.innerPanel.drawRectBorderStatic = _empty_fn
	self.innerPanel:instantiate()
	self:addChild(self.innerPanel)
	
	self.customTooltip = ISToolTip:new()
	self.customTooltip:initialise()
	self.customTooltip.description = "..."
	
	self.tooltip = self.customTooltip
	self.tooltip:setVisible(false)

	if Excrementum.found_MinimalDisplayBars then
		self:MinimalDisplayBarsCompatible()
	end
end

function ExcrementumMini:CheckPosition()
	if (self.x > 8 and self.x < 55 and self.y < 430) then -- left panel
		if self.y > 380 then
			self:setY(430)
		else
			self:setX(self.x > 31 and 55 or 8)
		end
	end
end

function ExcrementumMini:prerender()
	if self:isMouseOver() then
		if self.is_tooltip == nil then
			self.is_tooltip = true
			self.tooltip:setVisible(true)
			self.tooltip:addToUIManager()
			self.tooltip.followMouse = true
		end
	elseif self.is_tooltip then
		self.is_tooltip = nil
		self.tooltip:setVisible(false)
		self.tooltip:removeFromUIManager()
		self.tooltip.followMouse = false
	end
	
	if self.background then
		self:drawRectStatic(0, 0, self.width, self.height, self.backgroundColor.a, self.backgroundColor.r, self.backgroundColor.g, self.backgroundColor.b)
		self:drawRectBorderStatic(0, 0, self.width, self.height, self.borderColor.a, self.borderColor.r, self.borderColor.g, self.borderColor.b)
	end
end

function ExcrementumMini:new(dx, config_offset)
	local x, y, visible = 10+dx, 440, false
	local player = getSpecificPlayer(0)
	if player then
		local exc = player:getModData().exc
		if exc ~= nil then
			local layout = exc.layout
			x = layout[2 + config_offset]
			y = layout[3 + config_offset]
			visible = layout[4 + config_offset] and SandboxVars.Excrementum.EnabledStatusBars and true
		end
	end

	local o = {}
	o = ISPanel:new(x, y, 12, 102)
	
	setmetatable(o, self)
	self.__index = self
	--o.title = ""
	o.pin = false
	--o.borderColor = {r=.82, g=.56, b=.29, a=1} --.borderColor = {r=.6, g=.5, b=0, a=1} .borderColor = {r=.6, g=.3, b=0, a=1}
	o.moveWithMouse = true

	o:addToUIManager()
	o.pin = true
	o.resizable = false
	o.max_height = 100
	o:setVisible(visible)
	return o, visible
end