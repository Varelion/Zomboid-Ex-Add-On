if Excrementum then
	Excrementum._hash = Excrementum._hash + 16384
else
	return
end

if Excrementum.is_injected_FullStomach then
	return --RELOAD protection
end

-- Нельзя есть больше, когда желудок переполнен (примерно свыше 500%).

local function injectOnce(player)
	local function isFullStomach()
		--return player:getMoodles():getMoodleLevel(MoodleType.FoodEaten) >= 3 and player:getNutrition():getCalories() >= 1000
		return Excrementum.StomachPain >= 90
	end
	
	local function isRealFood(item)
		return instanceof(item, "Food") and item:getCustomMenuOption() == nil
	end

	local old_start = ISEatFoodAction.start
	function ISEatFoodAction:start()
		if isRealFood(self.item) then
			if isFullStomach(self.character) then
				return self:forceStop()
			end
			if self.item:hasTag('Feces') then
				local player = self.character
				if player == Excrementum.p then
					Excrementum.SendShameMomentToNearest(player, 6, true)
					Excrementum.ApplyShame(nil, 6)
				end
			end
		end
		return old_start(self)
	end
	
	local old_isValid = ISEatFoodAction.isValid
	function ISEatFoodAction:isValid()
		if isFullStomach(self.character) and isRealFood(self.item) then
			return false
		end
		return old_isValid(self)
	end
	
	--- inject into the menu
	
	local FoodEaten = MoodleType.FoodEaten
	if not FoodEaten then
		return print('ERROR EXC: No MoodleType.FoodEaten')
	end
	local is_active = nil
	Excrementum.setFoodMenuInjected = function(val)
		is_active = val
	end
	
	local m_class = getmetatable(player:getMoodles()).__index
	local old_getMoodleLevel = m_class.getMoodleLevel
	m_class.getMoodleLevel = function(player, moodle, ...)
		if is_active == nil or moodle ~= FoodEaten or not isFullStomach() then
			return old_getMoodleLevel(player, moodle, ...)
		end
		return 4 -- всегда полный желудок с точки зрения игры, когда игрок в меню
	end
	
	local m_nut = __classmetatables[zombie.characters.BodyDamage.Nutrition.class].__index
	local old_fn = m_nut.getCalories
	m_nut.getCalories = function(self, ...)
		local res = old_fn(self, ...)
		if not is_active then
			return res
		end
		if res < 1001 then
			res = 1001
		end
		return res
	end
	
	local old_createMenu = ISInventoryPaneContextMenu.createMenu
	ISInventoryPaneContextMenu.createMenu = function(...)
		is_active = true
		local context = old_createMenu(...)
		is_active = nil
		return context
	end
	
end


Events.OnCreatePlayer.Add(function(pid, player)
	if Excrementum.is_injected_FullStomach then
		return
	end
	Excrementum.is_injected_FullStomach = true
	
	injectOnce(player)
end)