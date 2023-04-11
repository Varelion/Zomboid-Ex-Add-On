if Excrementum then
	Excrementum._hash = Excrementum._hash + 65536
else
	return
end

-------------- Inject into Mini Health Mod ----------
--[[
DEAD CODE. WE DON'T INTEGRATE OPTIONS IN OTHER MODS.

local mh_opt = {
	name = "UI_MiniHealth_ExcShowClothes",
	tooltip = "UI_MiniHealth_ExcShowClothesTooltip",
	default = true,
	value = true,
}
Excrementum.MiniHealthOption = mh_opt

if ISMiniHealth and ISMiniHealth.setPlayerIsDead then
	if ModOptions and ModOptions.OPTIONS_CHUNKS then
		local mh_data
		for i,v in ipairs(ModOptions.OPTIONS_CHUNKS) do
			if v.mod_id == 'MiniHealth' then
				mh_data = v
			end
		end
		if mh_data then
			local data = mh_data.options_data.show_clothes_mini_health
			if data then
				mh_opt = data -- impossible code (option is added by this mod only)
			else
				--print('WARNING EXC: No clothes options in Mini Health.')
				mh_data.options_data.show_clothes_mini_health = mh_opt
				mh_opt.id = 'show_clothes_mini_health'
				mh_opt.settings = mh_data
				mh_opt.OnApplyInGame = Excrementum.OnClothingUpdate
				mh_data.is_ini_loaded = nil -- reset loaded status, to reinitialize chunk from loaded data
				mh_data.is_prepared = false
				ModOptions:prepareCustomData()
				--ModOptions:saveIniData()
			end
		else
			print('ERROR EXC: Mini Health options data not found!')
		end
		if not getmetatable(mh_opt) then
			mh_opt.value = false
		end
	end
	-- true! (by default) if MiniHealth but not ModOptions
else
	mh_opt.value = false
end

--]]

------------- Pain in Health Panel ------------

do
	local function lerp(a, b, t)
		return a + (b - a) * t
	end

	local old_children = ISHealthPanel.createChildren
	function ISHealthPanel:createChildren()
		if Excrementum.DEBUG then
			self.test_txt = ISRichTextPanel:new(280,0,125,50)
			self.test_txt:noBackground()
			self:addChild(self.test_txt)
		end

		old_children(self)
		
		local texture = getTexture("media/textures/Exc_RedBodyPain.png")
		
		self.exc_pain_1 = ISImage:new(27, 73, 72, 72, texture)
		self.exc_pain_1:initialise()
		self.exc_pain_1.background = false
		self.ecol1 = self.exc_pain_1.backgroundColor
		self.exc_pain_1:setVisible(false)
		self:addChild(self.exc_pain_1)
		
		self.exc_pain_2 = ISImage:new(27, 108, 72, 72, texture)
		self.exc_pain_2:initialise()
		self.exc_pain_2.background = false
		self.ecol2 = self.exc_pain_2.backgroundColor
		self.exc_pain_2:setVisible(false)
		self:addChild(self.exc_pain_2)
		
		self.exc_pain_3 = ISImage:new(27, 130, 72, 72, texture)
		self.exc_pain_3:initialise()
		self.exc_pain_3.background = false
		self.ecol3 = self.exc_pain_3.backgroundColor
		self.exc_pain_3:setVisible(false)
		self:addChild(self.exc_pain_3)
		
		
		--ISHealthPanel.instance.exc_pain_1.backgroundColor
	end

	local old_prerender
	local new_prerender = function(self)
		old_prerender(self)
		local player = self.character
		if self.test_txt then
			--local num = self.playerNum -- always 0
			local is_local_player = player == getSpecificPlayer(0)
			self.test_txt:setText(is_local_player and 'Local player' or 'Survivor')
			self.test_txt:paginate()
			if not is_local_player then
				gw_player = player
			end
		end
		local pain1,pain2,pain3 = 0,0,0
		if player == Excrementum.p then
			pain1 = Excrementum.StomachPain
			pain2 = Excrementum.ColonPain
			pain3 = Excrementum.UrinePain
		else --print_r(ISHealthPanel.instance.listbox.items[7].item.bodyPart:getAdditionalPain())
			local items = self.listbox and self.listbox.items
			if self.listbox and self.listbox.items then
				local p1,p2,p3 = items[7],items[8],items[11]
				p1 = p1 and p1.item and p1.item.bodyPart
				if p1 and p1.getAdditionalPain and p2 and p3 then
					pain1 = p1:getAdditionalPain()
					pain2 = p2.item.bodyPart:getAdditionalPain()
					pain3 = p3.item.bodyPart:getAdditionalPain()
					if Excrementum.DEBUG then
						other_player = self.character
					end
				end
			end
		end
		
		if pain1 > 0 then
			if not self.epic1 then
				self.epic1 = true
				self.exc_pain_1:setVisible(true)
			end
			-- 0.3 .. 1
			self.ecol1.a = lerp(0.3, 1, math.min(pain1 * 0.01, 1))
		elseif self.epic1 then
			self.epic1 = false
			self.exc_pain_1:setVisible(false)
		end
		if pain2 > 0 then
			if not self.epic2 then
				self.epic2 = true
				self.exc_pain_2:setVisible(true)
			end
			-- 0.2 .. 1
			self.ecol2.a = lerp(0.2, 1, math.min(pain2 * 0.01, 1))
		elseif self.epic2 then
			self.epic2 = false
			self.exc_pain_2:setVisible(false)
		end
		if pain3 > 0 then
			if not self.epic3 then
				self.epic3 = true
				self.exc_pain_3:setVisible(true)
			end
			-- 0.3 .. 1
			self.ecol3.a = lerp(0.2, 1, math.min(pain3 * 0.01, 1))
		elseif self.epic3 then
			self.epic3 = false
			self.exc_pain_3:setVisible(false)
		end
	end


	
	Events.OnGameStart.Add(function()
		old_prerender = ISHealthPanel.prerender
		ISHealthPanel.prerender = new_prerender
	end)
end
	
	
-- Cleaning Tag in items
do
	local CLEANING = { -- сколько делать :Use() ---> сколько примерно раз получится на ваниле
		["Base.CleaningLiquid2"] = 8, -- 7
		["Base.Bleach"] = 0.3, -- 2
		["Base.Vinegar"] = 2, -- 5
		["Base.RiceVinegar"] = 0.05, -- 4
		["Base.BakingSoda"] = 3.34, -- 3
		["Base.Soap2"] = 5, -- ~ 4
	}
	Excrementum.CLEANING = CLEANING
	local SM = ScriptManager.instance
	for k in pairs(CLEANING) do
		local item = SM:getItem(k)
		if item then
			item:getTags():add("Cleaning")
		end
	end
	
	local HOUSEHOLD = {
		["Base.BathTowel"] = "Base.BathTowelDirty",
		["Base.BathTowelWet"] = "Base.BathTowelDirty",
		["Base.DishCloth"] = "Base.DishClothDirty",
		["Base.DishClothWet"] = "Base.DishClothDirty",
		["Base.Mop"] = true,
		["Base.Sponge"] = true,
	}
	Excrementum.HOUSEHOLD = HOUSEHOLD
	for k in pairs(HOUSEHOLD) do
		local item = SM:getItem(k)
		if item then
			item:getTags():add("DryWiping")
		end
	end
	
	
	
end


