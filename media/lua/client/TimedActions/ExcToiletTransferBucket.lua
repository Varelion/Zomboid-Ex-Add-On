ExcToiletTransferBucket = ISBaseTimedAction:derive("ExcToiletTransferBucket");

function ExcToiletTransferBucket:isValid()
	if self.bucket then
		return self.inv:contains(self.bucket)
	end
	return true
end


function ExcToiletTransferBucket:update()
	local bucket = self.bucket
	if bucket then
		bucket:setJobDelta(self:getJobDelta());
		bucket:setJobType(getText("ContextMenu_ExWiping"));
	end
end

function ExcToiletTransferBucket:start()
	self.character:setIgnoreAimingInput(true)
	self:setActionAnim("Loot")
	--self.sound = self.character:playSound("GeneratorAddFuel")
	getSoundManager():PlayWorldSound("Exc_Bucket", self.character:getCurrentSquare(), 0, 10, 0, true)
end

function ExcToiletTransferBucket:stop()
	self.character:setIgnoreAimingInput(false)
	--self.character:stopOrTriggerSound(self.sound)
	if self.bucket then
		self.bucket:setJobDelta(0.0);
	end
	ISBaseTimedAction.stop(self);
end

function ExcToiletTransferBucket:perform()
	self.character:setIgnoreAimingInput(false)
	--self.character:stopOrTriggerSound(self.sound)
	local bucket = self.bucket
	local dirt = nil
	if bucket then
		bucket:setJobDelta(0.0);
		if bucket.getUsedDelta then
			dirt = math.floor((bucket:getUsedDelta() + 0.01) / bucket:getUseDelta()) * 10
		end
	end
	Excrementum.SendClientCommand("Bucket", self.toilet, bucket and bucket:getType(), self.character, self.is_exctract, dirt)
	if bucket then
		self.character:getInventory():Remove(bucket)
	end

	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

function ExcToiletTransferBucket:new(player, toilet, bucket, is_exctract)
	local o = {}
	setmetatable(o, self)
	self.__index = self
	o.character = player;
	o.inv = player:getInventory()
	o.toilet = toilet;
	o.bucket = bucket;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.is_exctract = is_exctract
	o.maxTime = 200;
	if o.character:isTimedActionInstant() then o.maxTime = 50; end
	return o;
end
