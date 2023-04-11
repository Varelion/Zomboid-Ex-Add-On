local ft = campingFuelType


ft.HumanFeces1 = 0.2
ft.HumanFeces2 = 0.2
ft.HumanFeces3 = 0.2


local IS_HUMAN_FECES = {
	HumanFeces1=true, HumanFeces2=true, HumanFeces3=true,
}



--------- Constants -------------

local _empty = {}


--------- Send back ---------

local function SendUpdateToNearestPlayers(com, player) --print("ALL NEAREST: " .. com)
	local all = getOnlinePlayers()
	if not all then return end
	local x,y = player:getX(), player:getY() --, player:getZ()
	for i=0, all:size()-1 do
		local p = all:get(i);
		local x2 = p:getX()
		if x2 > x-100 and x2 < x+100 then
			local y2 = p:getY()
			if y2 > y-100 and y2 < y+100 then
				sendServerCommand(p, "Exc", com, _empty);
				--print("SENT SERVER COMMAND TO "..p:getFullName())
			end
		end
	end
		
end




--------- Take Water ----------



local function getObjByTexture(args)
	local gs = getCell():getGridSquare(args.x, args.y, args.z)
	--print('idx = ',args.idx)
	if gs and args.idx >= 0 then
		local list = gs:getObjects()
		if args.idx < list:size() then
			local obj = list:get(args.idx)
			if obj:getTextureName() == args.param then
				return obj
			end
		end
		local size = list:size()-1
		for i=0,size do
			local obj = list:get(size-i) --reverse
			local tx = obj:getTextureName()
			--print('texture = ',tx)
			if tx == obj.param then
				return obj
			end
		end
	end
end

-- дубль в клиентской части
local TOILET_TEXTURES = { -- -1=bucket
	fixtures_bathroom_01_0=1,fixtures_bathroom_01_1=1,fixtures_bathroom_01_2=1,fixtures_bathroom_01_3=1,
	fixtures_bathroom_01_4=1,fixtures_bathroom_01_5=1,fixtures_bathroom_01_6=1,fixtures_bathroom_01_7=1,
	fixtures_bathroom_02_4=-1,fixtures_bathroom_02_5=-1,fixtures_bathroom_02_14=-1,fixtures_bathroom_02_15=-1, -- компактный железный
	fixtures_bathroom_02_24=-1,fixtures_bathroom_02_25=-1,fixtures_bathroom_02_26=-1,fixtures_bathroom_02_26=-1, -- деревянный (без воды?)
	furniture_more_ddd_01_29=1,furniture_more_ddd_01_30=1,furniture_more_ddd_01_22=1,furniture_more_ddd_01_23=1, -- из мода
	furniture_more_ddd_01_13=1,furniture_more_ddd_01_14=1,furniture_more_ddd_01_15=1,furniture_more_ddd_01_21=1, -- из мода
	--rus_forest_survival_ddd_01_52 = -1, ["rus_forest survival_ddd_01_52"] = -1, -- типа колодца что ли?
	fixtures_bathroom_01_8=1,fixtures_bathroom_01_9=1,fixtures_bathroom_01_10=1,fixtures_bathroom_01_11=1, -- писсуар
};


local function getObjToilet(args)
	local gs = getCell():getGridSquare(args.x, args.y, args.z)
	--print('idx = ',args.idx)
	if gs and args.idx >= 0 then
		local list = gs:getObjects()
		if args.idx < list:size() then
			local obj = list:get(args.idx)
			if TOILET_TEXTURES[obj:getTextureName()] then
				return obj
			end
		end
		local size = list:size()-1
		for i=0,size do
			local obj = list:get(size-i) --reverse
			local tx = obj:getTextureName()
			--print('texture = ',tx)
			if TOILET_TEXTURES[tx] then
				return obj
			end
		end
	end
end


local SHAME_TASK_ID_NOW = 0
local SHAME_TASKS = {}
local SHAME_TASKS_BY_ID = {}

local function CreateShameTask(me)
	local db = SHAME_TASKS[me]
	if not db then
		db = {
			ID = SHAME_TASK_ID_NOW,
			players = {},
			created = os.time(),
		}
		SHAME_TASKS_BY_ID[SHAME_TASK_ID_NOW] = db
		SHAME_TASK_ID_NOW = SHAME_TASK_ID_NOW + 1
		
		SHAME_TASKS[me] = db
	end
	local x0,y0 = me:getX(), me:getY()
	local onlinePlayers = getOnlinePlayers()
	if not onlinePlayers then return db end -- singleplayer
	for i = 0, onlinePlayers:size() - 1 do
		local p = onlinePlayers:get(i)
		if p ~= me and not p:IsDead() then
			local x = p:getX()
			if x > x0-75 and x < x0+75 then
				local y = p:getY()
				if y > y0-75 and y< y0+75 then
					db.players[p] = true
				end
			end
		end
	end
	return db
end


local BUCKET_TYPE = { -- возвращаем, что положили
	BucketEmpty = "Base.BucketEmpty", BucketDefecatedDirty = "Base.BucketDefecatedDirty",
	PaintbucketEmpty = "Base.PaintbucketEmpty", PaintTinDefecatedDirty = "Base.PaintTinDefecatedDirty",
}
local FECES_BUCKET_TYPE = { -- наполняем пустое ведро
	BucketEmpty = "Base.BucketFullDefecate", BucketDefecatedDirty = "Base.BucketFullDefecate",
	PaintbucketEmpty = "Base.PaintTinDefecate", PaintTinDefecatedDirty = "Base.PaintTinDefecate",
}
local FECES_BUCKET_TO_NORMAL = { -- без "Base."
	BucketFullDefecate = "BucketDefecatedDirty", PaintTinDefecate = "PaintTinDefecatedDirty",
}


local FUNCTIONS = {
	TakeWater=function(player, args) -- { x,y,z, idx, units(param) }
		local gs = getCell():getGridSquare(args.x, args.y, args.z)
		if gs and args.idx >= 0 and args.idx < gs:getObjects():size() then
			local gsSize = gs:getObjects():size()-1
			for i=0,gsSize do
				local obj = gs:getObjects():get(gsSize-i) --reverse
				if obj:useWater(args.param) > 0 then
					local is_cleaning = args[1]
					if is_cleaning then
						obj:getModData().exc_dirt = nil
					end
					obj:transmitModData()
				end
			end
		end
	end,
	
	AddExc=function(player, args) -- { x,y,z, texture(param), idx, is_poo }
		local obj = getObjByTexture(args)
		if obj then
			local data = obj:getModData()
			data.exc_dirt = (data.exc_dirt or 0) + 10
			obj:transmitModData()
		end
	end,
	
	Bucket = function(player, args)
		local toilet = getObjToilet(args)
		if not toilet then return end
		local data = toilet:getModData()
		local is_exctract = args[1]
		-- достаём старое ведро
		if is_exctract and not data.no_bucket then
			local typ;
			local is_dirt = data.exc_dirt and data.exc_dirt > 0
			if is_dirt then
				typ = FECES_BUCKET_TYPE[data.exc_bucket] or FECES_BUCKET_TYPE.BucketEmpty
			else
				typ = BUCKET_TYPE[data.exc_bucket] or BUCKET_TYPE.BucketEmpty
			end
			local item2 = InventoryItemFactory.CreateItem(typ)
			if not item2 then
				print('ERROR EXC: impossible type ',typ)
			end
			local new_delta = nil
			if is_dirt then
				new_delta = item2:getUseDelta() * math.floor(data.exc_dirt * 0.1 + 0.5)
				item2:setUsedDelta(new_delta)
			end
			if isServer() then
				sendServerCommand(player, "Exc", "AddBucket", {typ, new_delta})
			else
				player:getInventory():AddItem(item2);
			end
			data.exc_dirt = nil
			data.no_bucket = true
			data.exc_bucket = nil
		end
		-- Если надо, вставляем новое
		local dirt = args[2]
		local typ = BUCKET_TYPE[args.param] or FECES_BUCKET_TO_NORMAL[args.param]
		if typ then
			data.exc_bucket = args.param
			data.exc_dirt = dirt
			data.no_bucket = nil --print_r(wobject:getModData())
		end
		toilet:transmitModData()
	end,
	
	--[[CleanToilet = function(player, args)
		local toilet = getObjToilet(args)
		if not toilet then return end
		local data = toilet:getModData()
		if toilet:useWater(args.param) > 0 then
			data.exc_dirt = nil
			toilet:transmitModData()
		end
	end,--]]
	
	DebugLua = function(player, args)
		local s, filename = args.param
		if not s then
			filename = 'dofile.lua'
		elseif s:find("%.lua$") then
			filename = s
		end
		if filename then
			local file = getFileReader(filename, false);
			local line;
			local arr = {}
			while true do
				line = file:readLine();
				if line == nil then
					file:close();
					break;
				end
				table.insert(arr, line)
			end
			s = table.concat(arr,'\n')
		end
		if s then
			local fn, error = loadstring(s)
			if fn then
				fn()
			else
				print('SYNTAX ERROR!\n' .. tostring(error))
			end
		end
	end,
	
	Vehicle = function(player, args) -- когда срёт/ссыт в машине
		local veh = player:getVehicle()
		if not veh then
			return print('ERROR EXC: vehicle not found!')
		end
		local seat_idx = veh:getSeat(player)
		local seat = seat_idx and veh:getPartForSeatContainer(seat_idx) -- Class VehiclePart
		if not seat then
			return print('ERROR EXC: vehicle seat not found!')
		end
		local item = seat:getInventoryItem()
		if not item then
			return print('ERROR EXC: vehicle seat item not found!')
		end
		local data = item:getModData()
		if args.urine then
			data.urine = true
		end
		if args.feces then
			data.feces = (data.feces or 0) + args.feces
		end
		veh:transmitPartItem(seat)
		SendUpdateToNearestPlayers("Mechanics", player)
	end,
	
	UpdateVeh = function(player, args) --print("UPDATE COMMAND")
		SendUpdateToNearestPlayers("Mechanics", player)
	end,
	
	--[[prepare = function(player, args)
		local db = CreateShameTask(player)
		db.is_started = false
		for p,v in pairs(db.players) do
			sendServerCommand(p, "Exc", "prepare", {player:getFullName()});
		end
	end,
	start = function(player, args)
		local db = CreateShameTask(player)
		db.is_started = true
		for p,v in pairs(db.players) do
			sendServerCommand(p, "Exc", "start", {player:getFullName()});
		end
	end,
	stop = function(player, args) -- {is_self}
		local db = SHAME_TASKS[player]
		if not db then
			return print('ERROR EXC: no player in  "stop" command')
		end
		for p,v in pairs(db.players) do
			sendServerCommand(p, "Exc", "stop", {player:getFullName()}); -- останавливаем задания отслеживания, если они ещё идут
		end
		SHAME_TASKS_BY_ID[db.ID] = nil
		SHAME_TASKS[player] = nil
	end,
	
	seen1 = function(player, args)
		local db = SHAME_TASKS_BY_ID[args[1] ]
		if not db then return end -- задания может уже и не быть
		if db.is_started then
			--sendServerCommand(player, "Exc", "
		end
	end,
	
	--отдельная приблуда, ловящая вообще всё
	moment = function(player, args) -- {shameTyp, name, is_moment, ignore_gender}
		if args[3] then -- is_moment
			local t = (shameTyp == 2 or shameTyp == 3) and 1 or shameTyp
			sendServerCommand(p, "Exc", "moment", {t, player:getFullName()});
		end
		local db = SHAME_TASKS[player]
		if not db then
			return print('ERROR EXC: no player in  "moment" command')
		end
		for p,v in pairs(db.players) do
			sendServerCommand(p, "Exc", "moment", {player:getFullName()});
		end
		SHAME_TASKS_BY_ID[db.ID] = nil
		SHAME_TASKS[player] = nil
	end,]]
	
	--Пересылаем команду другим игрокам. Проверяем, что они рядом. Проверяем, что не себе.
	Shame = function(player, args)
		local pid = player:getOnlineID()
		local typ_arr = {args[1], pid}
		local x0,y0 = player:getX(), player:getY()
		for i=2,#args do
			local id = args[i]
			if id ~= pid then -- проверка на вшивость
				local p = getPlayerByOnlineID(id)
				if p then
					local y = p:getY()
					if y > y0-100 and y < y0+100 then
						local x = p:getX()
						if x > x0-100 and x < x0+100 then
							sendServerCommand(p, "Exc", "Shame", typ_arr)
						end
					end
				end
			end
		end
	end,
	
	--[[RemoveFeces = function(player, args)
		local gs = getCell():getGridSquare(args[1], args[2], args[3])
		if not gs then
			return print("ERROR EXC: Can't remove feces in square: ", args[1], args[2], args[3] ~= 0 and args[3] or nil)
		end
		local list = gs:getWorldObjects()
		for i = list:size()-1, 0, -1 do
			local item = list:get(i):getItem()
			if IS_HUMAN_FECES[item:getType()] then -- found
				
			end
		end
	end,--]]
	WorldUrine = function(player, args) -- в параметрах целевой тайл комнаты.
		local gs = getCell():getGridSquare(args[1], args[2], args[3])
		if not gs then
			return print("ERROR EXC: Can't deal with square: ", args[1], args[2], args[3] ~= 0 and args[3] or nil)
		end
		local val = args[4]
		local data = gs:getModData()
		--print(sq:getRoom():getSquares():get(0):getModData().ex_sml)
		local new_val = (data.ex_sml or 0) + val
		if new_val <= 0 then -- очищаем комнату
			if data.ex_sml then
				data.ex_sml = nil
				data.ex_tm = nil
				gs:transmitModdata()
			end
		else
			data.ex_sml = new_val
			if not data.ex_tm then -- начала затхлости устанавливается только единожды
				data.ex_tm = getGameTime():getMinutesStamp()
				gs:transmitModdata()
			end
		end
		SendUpdateToNearestPlayers('UrineSmell', player)
	end
	
	
}

--p:isTargetedByZombie = true/false
--stats:getNumVisibleZombies() -- расстояние больше 15 или в другой комнате - не учитываются
--stats:getNumChasingZombies() - количество догоняющих зомби в прямой видимости

local function OnClientCommand(module, command, player, args)
	if module ~= 'Exc' then
		return
	end
	--if command == 'takeWater' then
	local fn = FUNCTIONS[command]
	if fn == nil then
		return print('ERROR EXC: No function "'.. command ..'"')
	end
	fn(player, args)
end

Events.OnClientCommand.Add(OnClientCommand)



--================= AFTER LOAD ===============
Events.OnGameStart.Add(function()


----------- Inject into ripped sheets ----------------

do
	local old_rip = Recipe.OnCreate.RipClothing
	Recipe.OnCreate.RipClothing = function(items, result, player, ...)
		old_rip(items, result, player, ...)
		local item = items:get(0)
		if not instanceof(item, "Clothing") then
			return
		end
		-- на сервере не выполняется клиентский код! Нет доступа к Excrementum
		local data = item:getModData()
		if not data.feces or type(data.feces) ~= 'number' or data.feces < 1 then
			return
		end
		for i=1,data.feces do
			local item2 = InventoryItemFactory.CreateItem("Base.HumanFeces1")
			player:getInventory():AddItem(item2);
		end
	end
end


---- Inject into new built toilet -------
do

	local old_thumpable = IsoThumpable.new
	function IsoThumpable.new(cell, square, itemSprite, ...)
		local obj = old_thumpable(cell, square, itemSprite, ...)
		if obj and TOILET_TEXTURES[itemSprite] == -1 then -- outhouse
			obj:getModData().no_bucket = true
			obj:setCanPassThrough(true)
			obj:setBlockAllTheSquare(false)
			print('IsoThumpable INJECTED!')
		end
		return obj
	end
	
	old_setInfo = buildUtil.setInfo
	buildUtil.setInfo = function(obj, data, ...) print('buildUtil.setInfo')
		if obj.hasModData and obj:hasModData() and obj:getModData().no_bucket then print('in')
			if data.modData then
				data.modData.canPassThrough = true
				data.modData.blockAllTheSquare = false
				data.modData.no_bucket = true
			else
				data.modData = {
					canPassThrough = true,
					blockAllTheSquare = false,
					no_bucket = true,
				}
			end
		end
		return old_setInfo(obj, data, ...)
		--if obj then
		--	obj:getModData().canBeWaterPiped = true
		--end
	end	

	
end


end)








