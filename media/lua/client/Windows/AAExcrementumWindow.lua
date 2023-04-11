if Excrementum then
	Excrementum._hash = Excrementum._hash + 128
else
	return
end

ExcrementumWindow = ISCollapsableWindow:derive("ExcrementumWindow")


local DEFECATE_PIC_WIDTH = 60 -- см. свойства изображения, здесь должно быть также
local URINATE_PIC_WIDTH = 70

local TM = getTextManager()

function ExcrementumWindow:initialise()
	ISCollapsableWindow.initialise(self)
end

function ExcrementumWindow:new(x, y, width, height)
	local o = {}
	o = ISCollapsableWindow:new(x, y, width, height)
	setmetatable(o, self)
	self.__index = self
	o.pin = false
	o.backgroundColor.a = 0.8
	return o
end

local exc_window_cache = {nil,nil,nil,nil,nil,nil,nil,nil,nil,nil,}
function ExcrementumWindow:saveWindow() -- Сохраняем положение окон (только если оно менялось)
	local window_enabled, window_x, window_y = ExcrementumWindow:getIsVisible()
	local mini_emabled, x1, y1, x2, y2 = DefecationMini:getIsVisible()
	local need_save = false
	if window_enabled then
		window_x, window_y = ExcrementumWindow:getX(), ExcrementumWindow:getY()
		if exc_window_cache[4] ~= window_enabled or exc_window_cache[3] ~= window_y or exc_window_cache[2] ~= window_x or exc_window_cache[1] ~= 1 then
			need_save = true
		end
	elseif mini_emabled then
		x1, y1, x2, y2 = DefecationMini:getX(), DefecationMini:getY(), UrinationMini:getX(), UrinationMini:getY()
		if exc_window_cache[7] ~= mini_emabled
			or exc_window_cache[6] ~= y1 or exc_window_cache[5] ~= x1
			or exc_window_cache[8] ~= x2 or exc_window_cache[9] ~= y2
		then
			need_save = true
		end
	else
		if exc_window_cache[4] ~= window_enabled or exc_window_cache[7] ~= mini_emabled then
			need_save = true
		end
	end
	
	if not need_save then
		return
	end
	local player = getSpecificPlayer(0) if not player then return end
	local exc = player:getModData().exc
	if not exc then
		return
	end
	local layout = exc.layout
	
	exc_window_cache[1] = mini_emabled and 2 or window_enabled and 1 or layout[1] or 1
	exc_window_cache[4] = window_enabled
	exc_window_cache[7] = mini_emabled
	exc_window_cache[10] = mini_emabled
	layout[1] = exc_window_cache[1]
	layout[4] = exc_window_cache[4]
	layout[7] = exc_window_cache[7]
	layout[10] = exc_window_cache[10]
	
	if window_enabled then
		exc_window_cache[2] = window_x
		exc_window_cache[3] = window_y
		for i=2,3 do
			layout[i] = exc_window_cache[i]
		end
	elseif mini_emabled then
		exc_window_cache[5] = x1
		exc_window_cache[6] = y1
		exc_window_cache[8] = x2
		exc_window_cache[9] = y2
		for i=5,10 do
			layout[i] = exc_window_cache[i]
		end
	end
	
end

function ExcrementumWindow:onRightMouseUp(x, y)
	--print('TYPE = ', self.Type)
	ExcrementumWindow:setVisible(false)
	if self.is_hint then
		self.is_hint = false
		self.tooltip:setVisible(false)
	end
	
	DefecationMini:setVisible(true)
	UrinationMini:setVisible(true)
	DefecationMini.updateWindow()
	UrinationMini.updateWindow()
	
	Excrementum.OnUpdate.Remove(ExcrementumWindow.updateWindow)
	Excrementum.OnUpdate.Add(DefecationMini.updateWindow)
	Excrementum.OnUpdate.Add(UrinationMini.updateWindow)
	
	ExcrementumWindow:saveWindow()
end

local PIC_DEFECATE = {
	getTexture("media/textures/Exc_Def_1.png"), getTexture("media/textures/Exc_Def_2.png"),
	getTexture("media/textures/Exc_Def_3.png"), getTexture("media/textures/Exc_Def_4.png"),
}
local PIC_URINATE = { -- 1=0%, 4=100%
	getTexture("media/textures/Exc_Urine_1.png"), getTexture("media/textures/Exc_Urine_2.png"),
	getTexture("media/textures/Exc_Urine_3.png"), getTexture("media/textures/Exc_Urine_4.png")
}


function ExcrementumWindow:createChildren()
	ISCollapsableWindow.createChildren(self)
	--self.HomeWindow = ISRichTextPanel:new(0, 16, 400, 250)
	--self.HomeWindow:initialise()
	--self.HomeWindow.background = false
	--self.HomeWindow.autosetheight = false
	--self.HomeWindow:ignoreHeightChange()
	--self.HomeWindow.onRightMouseUp = ExcrementumWindow.onRightMouseUp
	--self:addChild(self.HomeWindow)
	
	local defecateImage = PIC_DEFECATE[1]
	local urinateImage = PIC_URINATE[1]
	local sickImage = getTexture("media/textures/Exc_SickRed.png")

	local function addChild(name, obj, ...)
		local o = obj:new(...)
		o:initialise()
		o.background = false
		o.onRightMouseUp = ExcrementumWindow.onRightMouseUp
		self[name] = o
		if o.marginRight then
			o.marginLeft = 0
			o.marginRight = 0
			o:instantiate()
		end
		self:addChild(o)
		return o
	end
	
	addChild("defecatePic", ISImage, 10, 52, 10, 6, defecateImage)
	addChild("defecatePicRed", ISImage, 5, 47, 10, 6, getTexture("media/textures/Exc_Def_Red.png"))
	addChild("urinatePicRed", ISImage, 80, 48, 4, 2, getTexture("media/textures/Exc_Urine_Red.png"))
	addChild("urinatePic", ISImage, 85, 53, 4, 2, urinateImage)
	addChild("sickPic", ISImage, 10, 52, 10, 6, sickImage)

	--defecation text
	-- ExcrementumWindow.labelDefecate:setX(5)
	-- ExcrementumWindow.labelDefecate.font
	--<SIZE:medium> means width x1.25
	addChild("labelDefecate", ISRichTextPanel, 0, 16, 80, 0.001)
	--self.labelDefecate.backgroundColor = {r=0, g=0, b=1, a=0.5}
	addChild("labelUrinate", ISRichTextPanel, 80, 16, 80, 0.001)
	local ver = addChild("labelVersion", ISRichTextPanel, 4, 90, 2, 130)
	ver.contentTransparency=0.05
	ver:setText(Excrementum.VERSION)
	ver:paginate()
	
	local tooltip = ISToolTip:new()
	self.tooltip = tooltip
	tooltip:initialise()
	tooltip.description = "asd"
	tooltip:setVisible(false)
	
	local up_self = self
	function self.urinatePic:prerender()
		up_self.is_overUrinatePic = self:isMouseOver()
		ISImage.prerender(self)
	end
	function self.defecatePic:prerender()
		up_self.is_overDefecatePic = self:isMouseOver()
		ISImage.prerender(self)
	end

	self:setInfo("test")

end

local COL_RED = '<RGB:1,0,0><SIZE:medium>'
local COL_GREEN = '<RGB:0,1,0><SIZE:medium>'
local COL_YELLOW = '<RGB:1,1,0><SIZE:medium>'

local function getPercStrUrine()
	local urinate = Excrementum.urine
	return tostring(urinate >= 1.1
		and math.floor(urinate * 10) / 10 .. " L"
		or (urinate >= 1.0
			and "1.0 L"
			or math.floor(urinate * 1000) .. " mL"
		)
	);
end

local function getPercStrFeces()
	local defecate = Excrementum.feces
	return tostring((defecate > 0.99499)
		and math.floor(defecate * 100 + 0.5)
		or round(defecate * 100, 1)
	) .. '%'
end

function ExcrementumWindow:updateStatus()
	if not ExcrementumWindow:isVisible() then return end --foolproof

	local player = getSpecificPlayer(0) if not player then return end
	local exc = player:getModData().exc
	local defecate = Excrementum.feces or 0
	local urinate = Excrementum.urine or 0

	
	local UrinationStatusText = getText("UI_optionscreen_binding_UrinationStatus") .. ": "

	local X = 0.3 + Excrementum.Ms
	local Y = X + 0.15
	
	if (urinate <= 0.2) then
		self.urinatePic.texture = PIC_URINATE[1]
	elseif (urinate <= .3) then
		self.urinatePic.texture = PIC_URINATE[2]
	elseif (urinate <= X) then
		self.urinatePic.texture = PIC_URINATE[3]
	else
		self.urinatePic.texture = PIC_URINATE[4]
	end
	
	local col_u;
	if urinate <= 0.3 then
		col_u = COL_GREEN
	elseif urinate <= X  then
		col_u = COL_YELLOW
	else
		col_u = COL_RED
	end
	
	local urinate_perc_str = getPercStrUrine()
	
	local u_width = TM:MeasureStringX(self.labelUrinate.font, urinate_perc_str) --* 1.15
	local u_x = 85 + math.floor((URINATE_PIC_WIDTH - u_width) * 0.5 + 0.5)
	self.labelUrinate:setX(u_x);

	self.labelUrinate.text = col_u .. urinate_perc_str
	self.labelUrinate:paginate()
	
	local showRedU = exc.ch.d > 0
	self.urinatePicRed:setVisible(showRedU)	
	
	------- DEFECATE ---------
	
	local colon = exc.col
	
	if colon.td then --print('COLON TD')
		if defecate <= .1 then
			self.defecatePic.texture = PIC_DEFECATE[1]
		elseif defecate <= .2 then
			self.defecatePic.texture = PIC_DEFECATE[2]
		elseif defecate <= .3 then
			self.defecatePic.texture = PIC_DEFECATE[3]
		else
			self.defecatePic.texture = PIC_DEFECATE[4]
		end
	elseif (defecate <= .1) then
		self.defecatePic.texture = PIC_DEFECATE[1]
	elseif (defecate <= .33) then
		self.defecatePic.texture = PIC_DEFECATE[2]
	elseif (defecate <= .9) then
		self.defecatePic.texture = PIC_DEFECATE[3] --print('NO 3')
	else
		self.defecatePic.texture = PIC_DEFECATE[4]
	end
	
	local col_d;
	--if defecate >= .1 and (defecate >= (Excrementum.feces_threshold or .8)) then
	if colon.td then
		col_d = COL_RED
	elseif defecate >= 0.3 then
		col_d = COL_YELLOW
	else
		col_d = COL_GREEN
	end
	
	local showRed = colon.V > 0 and colon.visc < 0.3
	self.defecatePicRed:setVisible(showRed)
	
	
	local bd = player:getBodyDamage()
	local showSickPic = bd:getPoisonLevel() > 0
	
	local defecate_perc_str = getPercStrFeces()
	
	local d_width = TM:MeasureStringX(self.labelDefecate.font, defecate_perc_str) --* 1.15
	local d_x = 10 + math.floor((DEFECATE_PIC_WIDTH - d_width) * 0.5 + 0.5)
	self.labelDefecate:setX(d_x);
	
	self.labelDefecate.text = col_d .. defecate_perc_str
	self.labelDefecate:paginate()
	
	self.sickPic:setVisible(showSickPic)
end

function ExcrementumWindow:prerender()
	ISCollapsableWindow.prerender(self)
	if self:isMouseOver() then
		local show = false
		if Mouse:getX() > self:getX() + 77 then
			if self.urinatePicRed:getIsVisible() then
				show = 3
			end
		else
			if self.sickPic:getIsVisible() then
				show = 2
			elseif self.defecatePicRed:getIsVisible() then
				show = 1
			end
		end
		if show then
			if not self.is_hint then
				self.tooltip:setVisible(true)
				self.tooltip:addToUIManager()
				self.tooltip.followMouse = true
			end
			if show ~= self.is_hint then
				self.is_hint = show
				self.tooltip.description = 
					(show == 1) and getText("UI_Exc_Diarrhea")
					or (show == 2) and getText("UI_Exc_Poisoning")
					or (show == 3) and getText("UI_Exc_Diuretic")
					or ""
				;
			end
		elseif self.is_hint then
			self.is_hint = false
			self.tooltip:setVisible(false)
			self.tooltip:removeFromUIManager()
			self.tooltip.followMouse = false
		end
	elseif self.is_hint then
		self.is_hint = false
		self.tooltip:setVisible(false)
		self.tooltip:removeFromUIManager()
		self.tooltip.followMouse = false
	end
end

function ExcrementumWindow.updateWindow()
	ExcrementumWindow:updateStatus()
	ExcrementumWindow:saveWindow()
end

local function ExInitWindow()
	local player = getSpecificPlayer(0) if not player then return end

	local exc = player:getModData().exc
	local x, y, visible = 50, 500, false
	if exc ~= nil then
		local layout = exc.layout
		x = layout[2]
		y = layout[3]
		visible = layout[4] and SandboxVars.Excrementum.EnabledStatusBars and true
	end
	
	ExcrementumWindow = ExcrementumWindow:new(x, y , 160, 130)
	ExcrementumWindow:addToUIManager()
	ExcrementumWindow.pin = true
	ExcrementumWindow.resizable = false
	ExcrementumWindow:setVisible(visible)
	if visible then
		ExcrementumWindow:updateStatus()
		Excrementum.OnUpdate.Add(ExcrementumWindow.updateWindow)
	end
end
Events.OnGameStart.Add(ExInitWindow) -- после OnCreatePlayer



local function ExcrementumKeyUp(keynum)
	if keynum ~= getCore():getKey("ExcrementumStatus") then
		return
	end
	if not SandboxVars.Excrementum.EnabledStatusBars then
		return
	end

	local player = getSpecificPlayer(0)
	if not player then
		return
	end
	
	local exc = player:getModData().exc
	if not exc then
		return
	end
	
	
	
	if ExcrementumWindow:getIsVisible() then
		ExcrementumWindow:setVisible(false)
		--ExcrementumWindow.updateWindow()
		Excrementum.OnUpdate.Remove(ExcrementumWindow.updateWindow)
	elseif DefecationMini:getIsVisible() then
		DefecationMini:setVisible(false)
		UrinationMini:setVisible(false)
		Excrementum.OnUpdate.Remove(DefecationMini.updateWindow)
		Excrementum.OnUpdate.Remove(UrinationMini.updateWindow)
	elseif exc.layout[1] == 1 then
		ExcrementumWindow:setVisible(true)
		ExcrementumWindow.updateWindow()
		Excrementum.OnUpdate.Add(ExcrementumWindow.updateWindow)
	else
		DefecationMini:setVisible(true)
		UrinationMini:setVisible(true)
		Excrementum.OnUpdate.Add(DefecationMini.updateWindow)
		Excrementum.OnUpdate.Add(UrinationMini.updateWindow)
	end
	ExcrementumWindow:saveWindow()
	
end
Events.OnKeyPressed.Add(ExcrementumKeyUp)


if Events.OnSandboxOptionsChanged then
	Events.OnSandboxOptionsChanged.Add(function()
		if not SandboxVars.Excrementum.EnabledStatusBars then
			ExcrementumWindow:setVisible(false)
			DefecationMini:setVisible(false)
			UrinationMini:setVisible(false)
		end
	end)
end



--Key Binding
do
	local idx_found = nil
	for i, key in ipairs(keyBinding) do
		if key.value == "Zoom out" then
			idx_found = i
			break
		end
	end
	
	if not idx_found then
		idx_found = #keyBinding
	end
	table.insert(keyBinding, idx_found+1, {value = "ExcrementumStatus", key = 51})
end


--Simple Status Compatibility
local function testStatValueFn(p)
    return round(p:getStats():getEndurance() * 100)
end


--for test purpose

local ss_barConfigs =  SimpleStatus and SimpleStatus.ss_barConfigs or ss_barConfigs
if ss_barConfigs then

	--local info = getModInfoByID("simpleStatus")

	local COL_GREEN = {0,1,0}
	local COL_YELLOW = {1,1,0}
	local COL_RED = {1,0,0}
	
	local ssBar = require("ISSSBar")
	local is_new_version = ssBar and ssBar.getShownCount
	local typ = is_new_version and "custom" or nil
	
	local ss_enabled = false
	
	local tbl_Urine = {
		type = typ,
		name = "Urine",
		title = getText("UI_Exc_HumanUrineShort"), 
		shown = false, -- default value at the first start with Simple Status, won't affect for the second time.
		textFn=getPercStrUrine,
		ivalue = 0,
		percentFn=function()
			return math.min(1, Excrementum.urine * 1.25)
		end,
		colorFn=function()
			local X = 0.3 + Excrementum.Ms
			local Y = X + 0.15

			local u = Excrementum.urine
	
			if u <= 0.3 then
				return COL_GREEN
			elseif u <= X  then
				return COL_YELLOW
			else
				return COL_RED
			end
		end,
		valueFn = function() return math.floor(Excrementum.urine * 100 + 0.9) end,
	}
	local tbl_Feces = {
		type = typ,
		name = "Feces",
		title = getText("UI_Exc_HumanFecesShort"),
		shown = false,
		textFn = getPercStrFeces,
		ivalue = 0,
		percentFn = function()
			return math.min(1, Excrementum.feces)
		end,
		colorFn = function()
			if Excrementum.exc and Excrementum.exc.col.td then
				return COL_RED
			elseif Excrementum.feces >= 0.3 then
				return COL_YELLOW
			end
			return nil
		end,
		valueFn = function() return math.min(100, math.floor(Excrementum.feces * 100)) end,
	}
	table.insert(ss_barConfigs, tbl_Urine)
	table.insert(ss_barConfigs, tbl_Feces)


	local function SimpleStatus_EnableBars()
		tbl_Urine.type = typ
		tbl_Urine.percentFn=function()
			return math.min(1, Excrementum.urine * 1.25)
		end
		tbl_Urine.valueFn = function() return math.floor(Excrementum.urine * 100 + 0.9) end
		tbl_Urine.textFn = nil
		
		tbl_Feces.type = typ
		tbl_Feces.percentFn = function()
			return math.min(1, Excrementum.feces)
		end
		tbl_Feces.valueFn = function() return math.min(100, math.floor(Excrementum.feces * 100)) end
		tbl_Feces.textFn = nil
	end
	SimpleStatus_EnableBars()
	
	local txt_hidden = getText("UI_SimpleStatus_ExcHidden")
	local function SimpleStatus_DisableBars()
		local fn_zero = function() return 0 end
		local fn_forbidden = function() return txt_hidden end
		
		tbl_Urine.type = "custom"
		tbl_Urine.percentFn = nil
		tbl_Urine.valueFn = nil
		tbl_Urine.textFn = fn_forbidden

		tbl_Feces.type = "custom"
		tbl_Feces.percentFn = nil
		tbl_Feces.valueFn = nil
		tbl_Feces.textFn = fn_forbidden
	end
	
	Events.OnGameStart.Add(function()
		if not SandboxVars.Excrementum.EnabledStatusBars then
			SimpleStatus_DisableBars()
		end
	end)
	
	if Events.OnSandboxOptionsChanged then
		Events.OnSandboxOptionsChanged.Add(function()
			if SandboxVars.Excrementum.EnabledStatusBars then
				SimpleStatus_EnableBars()
			else
				SimpleStatus_DisableBars()
			end
		end)
	end
end



