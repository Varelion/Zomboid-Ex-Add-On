if Excrementum then
	Excrementum._hash = Excrementum._hash + 32768
else
	return
end


do return end


--Сигареты не снимают весь стресс, а снимает лишь стресс от самих сигарет.
if not (STAR_MODS and STAR_MODS.SmallFixes and STAR_MODS.SmallFixes.is_HonestCigarettes) then

	local old_perform = ISEatFoodAction.perform
	function ISEatFoodAction:perform()
		local item = self.item
		if not (item and item:getFullType()=="Base.Cigarettes") then
			return old_perform(self)
		end
		--Cigarettes
		local stats = self.character:getStats()
		local stress_sig = stats:getStressFromCigarettes()
		local real_stress = stats:getStress() - stress_sig
		old_perform(self) -- stress=0
		stats:setStress(real_stress)
	end

end