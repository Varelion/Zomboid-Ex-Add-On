--[[

Improvements to MoodleFramework

by star

--]]
do return end

if not Excrementum then
	return
end


if not (MF and MF.ISMoodle) then
	return
end


do
	local old_new = MF.ISMoodle.new
	MF.ISMoodle.new = function(...)
		local o = old_new(...)
		o.___is_vis = true
		return o
	end
end


Events.OnGameStart.Add(function()




function MF.ISMoodle:_updateVisibility()
	local status = self:getGoodBadNeutral()
	if status == 0 then
		if self.___is_vis then
			self.___is_vis = nil
			self:setVisible(false)
		end
	elseif not self.___is_vis then
		self.___is_vis = true
		self:setVisible(true)
	end
end

for _,v in pairs(MF.Moodles) do v:_updateVisibility() end


local old_setValue = MF.ISMoodle.setValue
function MF.ISMoodle:setValue(...)
	local result = old_setValue(self, ...)
	self:_updateVisibility()
	return result
end





end)




