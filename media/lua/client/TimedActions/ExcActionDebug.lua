require "TimedActions/ISBaseTimedAction"

-- ISTimedActionQueue.add(ExcActionDebug:new(p, 85, "washaway", 0.8));
-- ISTimedActionQueue.add(ExcActionDebug:new(p, 85, "wipingtoilet", nil, nil, "Base.ToiletPaper"));
-- ISTimedActionQueue.add(ExcActionDebug:new(p, 85, "spinthepipe", nil, "Base.Wrench"));
-- ISTimedActionQueue.add(ExcActionDebug:new(p, 85, "toilet_book", nil, "Base.Book"));

ExcActionDebug = ISBaseTimedAction:derive("ExcActionDebug");

function ExcActionDebug:isValid()
	return true;
end

function ExcActionDebug:update()
	--if not self.done and self:getJobDelta() > 0.75 then
	--	self.done = true
	--	Excrementum.UseToiletWater(self.character, wobject, 5, true)
	--end
end

function ExcActionDebug:start()
	self.character:setVariable("AnimSpeed", self.AnimSpeed)
	self:setActionAnim(self.anim_name)
	print('ANIMATION = ' .. tostring(self.anim_name))
	self.character:Say('ANIM = ' .. tostring(self.anim_name))
	self:setOverrideHandModels(self.right_override, self.left_override); --
end

function ExcActionDebug:stop()
	ISBaseTimedAction.stop(self);
end

function ExcActionDebug:perform()
	ISBaseTimedAction.perform(self);
end

function ExcActionDebug:new(character, time, anim_name, default_anim_scale, right_override, left_override)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = character;
	--o.item = item;
	o.anim_name = anim_name
	o.stopOnWalk = false;
	o.stopOnRun = false;
	o.maxTime = time;
	o.right_override = right_override
	o.left_override = left_override
	default_anim_scale = default_anim_scale or 1.0
	if time > 1  then
		o.AnimSpeed = default_anim_scale * time / o:adjustMaxTime(time)
	else
		o.AnimSpeed = 1.0
	end
	return o;
end
