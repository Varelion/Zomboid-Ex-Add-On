--[[
�������� "������" ��� ���������� ���� � ���������.
�������� �������� ������� ��������� ������ ��������� (������), �� �������� ������ ��� API � ������.

"$" � ����� ����� ���������, ����� �� ��� ��������� �������� ������ ������ ������ ����.
--]]
if not STAR_MODS then
	STAR_MODS = {}
end
if Excrementum then
	error('ERROR EXC: another "excrementum" mod is enabled!')
end

--[[if not SandboxVars_Excrementum then
    SandboxVars_Excrementum = {}
end
setmetatable(SandboxVars_Excrementum, {
    __index = function (table, key)
        return 1.0
    end
})--]]

local SandboxVars_Excrementum = SandboxVars.Excrementum
local _empty_fn = function() return 0 end
Excrementum = {
	defecate_fns = {},
	urinate_fns = {},
	update_fns = {},
	DEBUG = getActivatedMods():contains('Excrementum41old'), --getDebug(),
	urine = 0, -- � �����������
	Ms = 0.3, -- ���������� ����
	feces = 0, -- � ��������� (1 = 100%)
	feces_threshold = SandboxVars_Excrementum.ColonBaseThreshold * 0.01,
	ColonPain = 0, -- ���� � ������� ��������� �� ����������� (������� ����)
	UrinePain = 0, -- exactly 19
	StomachPain = 0, -- ����� ������� �� 100 �� 500, ���� �������� �� 0 �� 100.
	tm_GameStarted = 0,
	tm_LastSleep = 0,
	now = 0,
	--last_thirst = nil,
	StomachTotalV = 0, -- will set after stomach pain update
	p = false, -- false if falsy, also it's ~= nil, so (player ~= p) will be true
	green_stomach = 0,
	found_MinimalDisplayBars = getActivatedMods():contains("MinimalDisplayBars"),
	VERSION = 'v1.5.3',
	is_urine_update = true, -- to lock changes
	UpdateVehicleWindow = _empty_fn,
	IsShownGroin = _empty_fn,
	IsShownBreast = _empty_fn,
	smell = 0,
	room_smell = 0,
	nearestPlayers = {},
	shame = 0,
	is_topless = false,
	is_groinless = 0,
	--MiniHealthOption = nil,
	GameTime = nil,
	mh_limbs = {},
	_tm_task = {},
	_hash = 0, -- catch steam workshop issues
	ZoneLevel = 4, --jj: save
	LastAnim_tm = 0,
}
STAR_MODS.Excrementum = Excrementum
local MAX_CHECK_HASH = 131072; -- z_ExcHealth_Inject
print('Excrementum defined: ', Excrementum.VERSION)

local IS_RETEXTURE_MOD = nil

--local INTESTINE_TIME = SandboxVars_Excrementum.DefecateIntMinutes -- ����� ����������� ��� �� ������� ��������� (������ ���� 5 �����)
--local COLON_TIME = SandboxVars_Excrementum.ColonMinutes -- ������� ������� ��� ����� ������ ��������� �� ����, ��� ����� ������ ��������� (-10% ������ ���).
--print('COLON_TIME = ',COLON_TIME)
local CELL; --getCell()
local _last_room = nil; -- ������ �� ��������� �������, � ������� ��� ���� (��������, ��� ������)

if Excrementum.DEBUG then
	--INTESTINE_TIME = INTESTINE_TIME / 10 -- 30 ����� � ����� ������������. �� ����� ����� � ������ �������� ���� �� ������.
end

--local function OnApplyInGame(self, val)
--  self:resetLua()
--end
local IS_HUMAN_FECES = {
	HumanFeces1=true, HumanFeces2=true, HumanFeces3=true,
}

-- These are the default options.
local OPTIONS = {
	poo_sound_types = 1,
	pee_sound_types = 1,
  flush_sound = true,
	extract_sound = true,
	growl_sound = 1,
	stomach_moodle = 1,
	colon_moodle = 2,
	urine_moodle = 2,
	smell_moodle = true,
	overlay = 3,
}
local SETTINGS = {
  options = OPTIONS,
  names = {
    poo_sound_types = getText("UI_Exc_Option_PooSoundTypes"),
    pee_sound_types = getText("UI_Exc_Option_PeeSoundTypes"),
    flush_sound = getText("UI_Exc_Option_FlushSound"),
    extract_sound = getText("UI_Exc_Option_ExtractSound"),
    growl_sound = getText("UI_Exc_Option_GrowlSound"),
    stomach_moodle = getText("UI_Exc_Option_StomachMoodle"),
    colon_moodle = getText("UI_Exc_Option_ColonMoodle"),
    urine_moodle = getText("UI_Exc_Option_UrineMoodle"),
    smell_moodle = getText("UI_Exc_Option_SmellMoodle"),
		overlay = getText("UI_Exc_Option_Overlay"),
  },
  mod_id = "Excrementum41",
  mod_shortname = "Exc",
	mod_fullname = "Excrementum",
}
Excrementum.OPTIONS = OPTIONS;

-- Connecting the options to the menu
if ModOptions and ModOptions.getInstance then
	if Excrementum.DEBUG then
		OPTIONS.clothes_blue_parts = false -- by default
	end
  ModOptions:getInstance(SETTINGS)

  local poo = SETTINGS:getData("poo_sound_types")
  poo[1] = getText("UI_Exc_Option_PooSoundTypes_All")
  poo[2] = getText("UI_Exc_Option_PooSoundTypes_NoDefecateProcess")
  poo[3] = getText("UI_Exc_Option_PooSoundTypes_NoFart")
  poo[4] = getText("UI_Exc_Option_PooSoundTypes_OnlyOutdoors")
  poo[5] = getText("UI_Exc_Option_PooSoundTypes_OnlyToilet")
  poo[6] = getText("UI_Exc_Option_PooSoundTypes_None")
  poo[7] = getText("UI_Exc_Option_PooSoundTypes_NoneButPooSelf")
  --poo[8] = getText("UI_Exc_Option_PooSoundTypes_NoneButClothes")
  poo.tooltip = "UI_Exc_Option_PooSoundTypes_Tooltip"

  local pee = SETTINGS:getData("pee_sound_types")
  pee[1] = getText("UI_Exc_Option_PeeSoundTypes_All")
  pee[2] = getText("UI_Exc_Option_PeeSoundTypes_OnlyOutdoors")
  pee[3] = getText("UI_Exc_Option_PeeSoundTypes_OnlyToilet")
  pee[4] = getText("UI_Exc_Option_PeeSoundTypes_None")
  pee[5] = getText("UI_Exc_Option_PeeSoundTypes_NoneButPeeSelf")
  --pee[6] = getText("UI_Exc_Option_PeeSoundTypes_NoneButZip")
  pee.tooltip = "UI_Exc_Option_PeeSoundTypes_Tooltip"

  local growl = SETTINGS:getData("growl_sound")
  growl[1] = getText("UI_Exc_Option_GrowlSound_Always")
  growl[2] = getText("UI_Exc_Option_GrowlSound_Never")
  growl[3] = getText("UI_Exc_Option_GrowlSound_OnlyOnce")
  growl[4] = getText("UI_Exc_Option_GrowlSound_OnlyOnceOnEachStage")
  growl.tooltip = "UI_Exc_Option_GrowlSound_Tooltip"

  local st = SETTINGS:getData("stomach_moodle")
  st[1] = getText("UI_Exc_Option_StomachMoodle_ShowAny")
  st[2] = getText("UI_Exc_Option_StomachMoodle_ShowOnlyRed")
  st[3] = getText("UI_Exc_Option_StomachMoodle_Hide")
	st.tooltip = "UI_Exc_Option_NoAffectGameplay_Tooltip"

  local colon = SETTINGS:getData("colon_moodle")
  colon[1] = getText("UI_Exc_Option_ColonMoodle_ShowAny")
  colon[2] = getText("UI_Exc_Option_ColonMoodle_NoSmallIntestine")
  colon[3] = getText("UI_Exc_Option_ColonMoodle_NoGreen")
  colon[4] = getText("UI_Exc_Option_ColonMoodle_Hide")
	colon.tooltip = "UI_Exc_Option_NoAffectGameplay_Tooltip"

  local urine = SETTINGS:getData("urine_moodle")
  urine[1] = getText("UI_Exc_Option_UrineMoodle_ShowAny")
  urine[2] = getText("UI_Exc_Option_UrineMoodle_ShowOnlyRed")
  urine[3] = getText("UI_Exc_Option_UrineMoodle_ShowOnlyPain")
  urine[4] = getText("UI_Exc_Option_UrineMoodle_Hide")
	urine.tooltip = "UI_Exc_Option_NoAffectGameplay_Tooltip"

	local smell_moodle = SETTINGS:getData("smell_moodle")
	smell_moodle.tooltip = "UI_Exc_Option_NoAffectGameplay_Tooltip"

  local overlay = SETTINGS:getData("overlay")
  overlay[1] = getText("UI_Exc_Option_Overlay_AlwaysOnTop")
  overlay[2] = getText("UI_Exc_Option_Overlay_NearStomachIfPossible")
  overlay[3] = getText("UI_Exc_Option_Overlay_NearStomachOnly")  -- default
  overlay[4] = getText("UI_Exc_Option_Overlay_OnlyIfSickVisible")
  overlay[5] = getText("UI_Exc_Option_Overlay_Off")
  overlay[6] = getText("UI_Exc_Option_Overlay_HealthPanel")
	overlay.tooltip = "UI_Exc_Option_Overlay_Tooltip"


end





--[[
	����� ������� ���������, � ������� ����������� �� �� ������� �� ���������� ����������.
]]


--known food types
local DEFAULT_SPEED = 59.5 -- one ingame hour
local FOOD_SPEED = { -- ����� ������������� � ������� (��� 50 ��. �������).
	-- 0 = ������������ �������������; -1 = �� ��������� ����������.
	--LIQUIDS
	--���
	Juice = 20,
	--����������� ����� � ������ = 30,
	--���������
	SoftDrink = 40,

	--FRUITS - 30 min by default
	Berry = 20,
	Fruits = 30,
	Citrus = 30,
	["Base.Watermelon"] = 20,
	["Base.WatermelonSmashed"] = 20,
	["Base.WatermelonSliced"] = 20,
	["Base.Apple"] = 40,
	["Base.Pear"] = 40,
	["Base.CannedPeachesOpen"] = 40,
	["Base.Peach"] = 40,
	["Base.Cherry"] = 40,
	["Base.Mango"] = 90,
	["Base.Banana"] = 50,
	["Base.Grapes"] = 30, --��������
	["Base.CannedPineappleOpen"] = 50,
	["Base.Pineapple"] = 50,

	--�����. ������� = 50 ���, ������������ = 60 ���. �������������� = 40
	Vegetables = 50,
	["Base.Pumpkin"] = 60,
	["Base.HalloweenPumpkin"] = 60,
	["farming.Potato"] = 60,
	["Base.CannedPotatoOpen"] = 60,
	["Base.CannedPotato"] = 60,
	["Base.CannedPotato2"] = 60,
	["Base.CannedCornOpen"] = 60,
	["Base.Corn"] = 60,
	["Base.CornFrozen"] = 60,
	["farming.RedRadish"] = 20,
	--������� - 40
	["farming.Cabbage"] = 40,
	["Base.Broccoli"] = 40,
	["farming.BloomingBroccoli"] = 40,
	--�����������: �����, ������, �����, ��������
	["Base.Lettuce"] = 30,
	["Base.Pickles"] = 30,
	["Base.CannedTomatoOpen"] = 30,
	["Base.Tomat"] = 30,
	["Base.BellPepper"] = 30,

	--GRAINS & BEANS
	--������
	Bean = 120,
	Seed = 120, --������ ���������� (1 �������)
	Nut = 150,
	Rice = 80,
	["Base.Peas"] = 150, -- �����
	["Base.CannedPeasOpen"] = 150,
	["Base.DriedSplitPeas"] = 150,
	["Base.DriedLentils"] = 90, --��������
	["Base.DriedChickpeas"] = 90, --���
	["Base.DriedKidneyBeans"] = 90, --������� ������
	["Base.OatsRaw"] = 80, --�������
	["Base.WaterSaucepanRice"] = 80,
	["Base.WaterPotRice"] = 80,
	["Base.RicePan"] = 80,
	["Base.RicePot"] = 80,
	["Base.Peanuts"] = 180, --������

	--�����
	Mushroom = 330,

	--�������
	Milk = 120,
	Cheese = 300, --������ ���� 5 �����
	["Base.Processedcheese"] = 120,
	["Base.Yoghurt"] = 120,
	["Base.Icecream"] = 130, --���������
	["Base.ConeIcecream"] = 130,
	["Base.IcecreamMelted"] = 130,
	["Base.ConeIcecreamMelted"] = 130,
	["Base.ConeIcecreamToppings"] = 130,

	--ANIMAL PROTEINS
	Egg = 45,
	["Base.EggOmelette"] = 120,
	["Base.OmeletteRecipe"] = 120,
	Seafood = 30,
	["Base.Catfish"] = 30,
	Fish = 50, -- ������ ���� 60 (������, �������, ������ � �.�); �� ������=30 (������, ���, ������, ������������)
	["Base.Salmon"] = 50,
	["Base.CannedSardinesOpen"] = 50,
	["Base.CannedSardines"] = 50,
	["Base.Trout"] = 50,
	Poultry = 90, --������ (1 �������)
	["Base.ChickenFried"] = 90,
	["Base.ChickenNuggets"] = 90,
	["Base.Chicken"] = 90,
	["Base.ChickenFoot"] = 90,
	Game = 120, -- ���� (������� �� ������ ���� ������ ��������)
	Beef = 240, -- ��������, �������� = 240; ������� = 280
	Meat = 240, -- ������ ����, ������� ���-���
	Bacon = 240, --�����
	["Base.PorkChop"] = 280,

	-- ���������� � ����� ���������� +20 ���
	Oil = 180,
	["Base.Lard"] = 360,


	--�������, �������, (���������)
	Sausage=180,

	--����
	Bread = 180,

	Chocolate = 120,
	["Base.Chocolate"] = 120,
	Sugar = 0, --������ ����� �� ����������� � ������� � ����� ��� ������ (���� �����)
	["Base.Honey"] = 70,
	-- ������ �������� - ����� ��������, ����� �������. ����=210, ���������=130(� �������),
	["Base.CakeChocolate"] = 30,
	Candy = 20,


	Coffee = 90,
	Tea = 90,
	Cocoa = 90,


	Beer=80, Liquor=80, Wine=80,

	--������
	Flower = -1,
	--����������, �����-���
	Greens = -1,
	--�����, ������� ������ ��� � ��������
	Herb = -1,
	--��������, ���������
	HotPepper = -1,
	--��������� ����� (1 �������)
	Stock = -1,

	--����� �����
	Pasta = 180,


	--���������� �����������, �� ���� ��� ����������
	Herbal=-1, Sauce=-1, Pepper=-1,


	--���������, �� �������������, ������� ���������� �����, ������� ������, ������, ���. ����, ���������� ����, �������, �������� � �.�.
	--���������� ��������� �� ���������� ����
	--NoExplicit
	["Base.Butter"] = 180, --���������
	["Base.PeanutButter"] = 150, --����������
}

-- ��������� ��� ����� (���), �.�. ��������� ������������ �������
local DEFAULT_VISC = 0.999 -- �� ���������
local FOOD_VISC = { -- X + .....
	Vegetables = 0.3,

	Fruits = 0.4,
	Berry = 0.4,
	Mushroom = 0.4,
	Greens = 0.4,
	Bean = 0.4,
	Nut = 0.4,

	Seed = 0.6,
	Pasta = 0.6,
	Bread = 0.6,

	Rice = 1.5,
	["Base.CannedPotato"] = 1.5,
	["Base.CannedPotato2"] = 1.5,
	["Base.CannedPotatoOpen"] = 1.5,
	["farming.Potato"] = 1.5,
}

if not ZombRand then
	return FOOD_SPEED
end

---------- utils ------------


local IS_SINGLEPLAYER = not isClient() and not isServer()

local function isInvisible(player) -- not zombie!
	return player:isInvisible() -- player:getAccessLevel() == "Admin" or  or player:isGodMod()
end


local function round3(num)
	return math.floor(num*1000) / 1000
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

-- ������� ���� FIFO, ������� �������
local QList; QList = {
	pushright = function(list, value)
		local last = list.last + 1
		list.last = last
		list[last] = value
	end,

	optimize = function(list)
		if list.first > list.last then -- reset on empty
			list.first = 1
			list.last = 0
		end
	end,

	popleft = function(list)
		local first = list.first
		local last = list.last
		if first > last then return print("ERROR EXC: list is empty") end
		local value = list[first]
		list[first] = nil        -- to allow garbage collection
		list.first = first + 1
		if first == last then -- reset on empty
			list.first = 1
			list.last = 0
		elseif first > 50 then -- repack (move) ??
			for i=first+1,last do
				list[i-first] = list[i]
				list[i] = nil
			end
			list.first = 1
			list.last = last-first
		end
		return value
	end,

	getleft = function(list)
		local first = list.first
		if first > list.last then return nil end
		return list[first]
	end,

	getLength = function(list)
		return 1 + list.last - list.first
	end,

	init = function()
		return {
			first = 1,
			last = 0,
		}
	end,

	reinit = function(list)
		table.wipe(list)
		list.first = 1
		list.last = 0
	end,
}


-- ���������� ���� ���������� ������ � �������� �� ����� � ��������
-- b - ����������� �������
local pi = math.pi
local pi2 = pi * 2
local atan2 = math.atan2
local abs = math.abs
function MathCanSee(dx,dy,b)
	local a = atan2(dy,dx)
	local r = abs(a-b);
	while r > pi do
		r = r - pi2
	end
	return abs(r); -- ���� ����� ������������ ������� � �������� � ����� (dx;dy)
end

--xx1=10887
--yy1=10000
--fn=function() return MathCanSee(xx1-p:getX(), yy1-p:getY(), p:getLookAngleRadians()) end DebugTrace(fn)


local meta_SqProxyOfs = {
	getX = function(self)
		return self._sq:getX() + self.offset_x
	end,
	getY = function(self)
		return self._sq:getY() + self.offset_y
	end,
	__index = function(self, key)
		return function(self, ...)
			return self._sq[key](self._sq, ...)
		end
	end,
}

-- proxy for a square to add x,y offset
local function SqProxyOfs(sq, offset_x, offset_y)
	--print('MAKE PROXY:',offset_x, ' ',offset_y)
	local proxy = {
		_sq = sq,
		offset_x = offset_x,
		offset_y = offset_y,
	}
	setmetatable(proxy, meta_SqProxyOfs)
	return proxy
end
Excrementum.SqProxyOfs = SqProxyOfs


-- �������� ������ �� num (�� ����� ��� �� plus), ����������/�������� ������ �� �������
local function StressUpTo(num, player, plus)
	local stats = player:getStats()
	local real = stats:getStress() -- �������� = base + cig
	if real >= num then
		return -- ���� ��� ��������, �� ��
	end
	local cig = stats:getStressFromCigarettes() -- ������ �� ���
	local base = real - cig;
	if plus == nil then
		stats:setStress(num - cig) -- ������ ������ �������. ������� � num ����� ����������� ������ �� ���.
		return
	end
	--print('plus = ',tostring(plus))
	if real + plus + 0.001 >= num  then
		stats:setStress(num - cig)
		return
	end
	-- �� ������� �� �����, ������ ����� ������ ���������
	stats:setStress(base + plus)
end
Excrementum.StressUpTo = StressUpTo



local function GetActionName(player, action_num)
	action_num = action_num or 1
	local q = ISTimedActionQueue.getTimedActionQueue(player)
	local current = q and q.queue[action_num]
	if current then
		return current.Type
	end
end

-- Excrementum.AddTask(30, function() print("test") end)
function Excrementum.AddTask(ticks, fn)
	table.insert(Excrementum._tm_task, {
		ticks = ticks,
		fn = fn,
	})
end
local function UpdateTasks() -- jj: should be optimized!
	local arr = Excrementum._tm_task
	for i = #arr,1,-1 do
		local task = arr[i]
		task.ticks = task.ticks - 1
		if task.ticks <= 0 then
			table.remove(arr, i)
			task.fn()
		end
	end
end

--client only (75-100 tiles away from me)
NEIGHBOR_BY_NAME = {}
local function getNearestVisiblePlayers(me) --, ignore_gender)
	local result = Excrementum.nearestPlayers
	table.wipe(result)
	table.wipe(NEIGHBOR_BY_NAME)
	if not me then
		return result
	end

	--[[if Excrementum.DEBUG then -- debug in sp. Tempry!!!
		local z = CELL:getNearestVisibleZombie(0)
		if z and z:CanSee(me) then
			result[z] = true;
			NEIGHBOR_BY_NAME[z:getFullName()] = z
		end
		return result
	end--]]

	local online = getOnlinePlayers()
	local cnt1 = online and online:size() or 0
	local objects = CELL:getObjectList()
	local cnt2 = objects:size()
	--local gender = not ignore_gender and me:isFemale()

	--fn=function() return MathCanSee(xx1-p:getX(), yy1-p:getY(), p:getLookAngleRadians())

	if cnt1 > 0 and cnt1 < cnt2 then -- survivors compatible?
		for i=0,cnt1-1 do
			local obj = online:get(i)
			if obj:getCurrentSquare() and obj ~= me and not obj:isDead() and not obj:isInvisible() and obj:CanSee(me) then -- and (ignore_gender or obj:isFemale() ~= gender)
				result[obj] = true
				NEIGHBOR_BY_NAME[obj:getFullName()] = obj
			end
		end
	elseif cnt2 > 0 then
		for i=0,cnt2-1 do
			local obj = objects:get(i)
			if instanceof(obj, 'IsoPlayer') and obj ~= me and not obj:isDead() and not obj:isInvisible() and obj:CanSee(me) then
				result[obj] = true
				NEIGHBOR_BY_NAME[obj:getFullName()] = obj
			end
		end
	end

	return result
end
Excrementum.getNearestVisiblePlayers = getNearestVisiblePlayers





local function ShameIsEnabled(player)
	local opt = SandboxVars_Excrementum.Shame
	return opt == 4 or not player:isGodMod() and (opt == 3 or opt == 2 and IS_RETEXTURE_MOD)
end

local SHAME_TIMES = { -- ingame minutes
	1440, -- 1 day, � ����� ��
	1440, -- ��� �� ������
	1440*2, -- ��� ��� ������
	60, -- ������ �����
	10, -- ������ ������ ��
	60, -- ���������
}
local SHAME_LEVELS = { 1, 2, 3, 0.5, 0.25, -1 }
local SHAME_ADD_LEVELS = { 0, 0.25, 0.5, 0, 0, -0.5 }
local SHAME_HIDES = { 120, 120, 120, 999, 999, 999 }
local SHAME_AMOUNTS = { 240, 360, 360, -180, 999, 999 } -- ����� ��������, ��� �������� �� �����������, ��� ���� ������
local MAX_SHAMES = #SHAME_LEVELS

--��������� ���� ���� typ �� ��������� � ����� � ������ name. ��� ������������.
local function ApplyShame(name, typ)
	if typ == 6 then
		local bd = Excrementum.bd
		if bd:getFoodSicknessLevel() < 33 then
			bd:setFoodSicknessLevel(33)
		end
		return
	end

	local rel = Excrementum.exc.rel
	local user = rel[name]
	if user then
		--user.e = true
	else
		user = { e = true, c = 0}
		rel[name] = user
	end
	local data = user[typ];
	--[[for i,v in ipairs(user) do
		if v.t == typ then
			data = v
			break
		end
	end]]
	if data then
		if data.a >= 0 then
			data.l = data.l + SHAME_ADD_LEVELS[typ]
			data.b = Excrementum.now + SHAME_TIMES[typ]
			data.h = Excrementum.now + SHAME_HIDES[typ]
			data.a = SHAME_AMOUNTS[typ]
		end
	else
		data = {
			l = SHAME_LEVELS[typ],
			b = Excrementum.now + SHAME_TIMES[typ],
			h = Excrementum.now + SHAME_HIDES[typ],
			a = SHAME_AMOUNTS[typ],
		}
		--table.insert(user, data)
		user[typ] = data
	end
end
Excrementum.ApplyShame = ApplyShame

-- ��������� �������� �����, ����������� �� ���.
-- is_change=true, ������ ������ ������
local function UpdateShame(me, is_change)
	local shame = 0
	local shame_max = 0
	local now = Excrementum.now
	local rel = Excrementum.exc.rel
	local voyeur = 0 -- ���� ����� ���� ������������ ���������
	local exhibitionist = 0 -- ���� ����� ���� ������������ ���������

	-- Check relations
	if ShameIsEnabled(me) then
		for name,user in pairs(rel) do
			local _shame = 0
			local is_reduce = nil
			for i=1,MAX_SHAMES do
				local data = user[i]
				if data then
					if data.a == 0 or now >= data.b then
						user[i] = nil
						if i == 4 then -- ���������� � ������ ����
							user.c = user.c + 1
						end
					else
						if now < data.h then
							--shame = shame + data.l
							if data.l > 0 then
								_shame = math.max(_shame, data.l) -- �� ��������� �������������
							else
								voyeur = voyeur + data.l
							else
								exhibitionist = exhibitionist - data.l
							end
						end
						if is_change then
							if is_reduce == nil then
								is_reduce = false
								local p = NEIGHBOR_BY_NAME[name]
								if p and not p:isInvisible() and ShameIsEnabled(p) then
									local dist = p:DistTo(me)
									if dist < 10 or dist < 25 and p:CanSee(me) then -- ��������� ������ ��� � ������ ���������
										is_reduce = true
									end
								end
							end
							if is_reduce then
								data.a = data.a + (data.a < 0 and 1 or -1)
							end
						end
					end
				end
			end
			if _shame > 0 then
				shame_max = math.max(shame_max, _shame)
				shame = shame + math.min(1, _shame)
				if is_change and user.c == 0 and is_reduce == nil then
					rel[name] = nil
				end
			end
		end
		if shame_max > 1 then
			shame = shame + (shame_max - 1)
		end
	end

	if voyeur < 0 and -voyeur * 2 >= shame then
		shame = voyeur
	end

	if exhibitionist < 0 and -exhibitionist * 2 >= shame then
		shame = exhibitionist -- ����������� ���������� ����������� ������� ���� �� ��
	end

	-- Check awaitings
	--[[for name,usr in pairs(Excrementum.WaitToApplyShame) do
		if rel[name] then
			for i=1,MAX_SHAMES do
				local data = usr[i]
				if data then
					shame = shame + (rel[name][i] and SHAME_ADD_LEVELS[i] or SHAME_LEVELS[i] or 0)
				end
			end
		else
			for i=1,MAX_SHAMES do
				local data = usr[i]
				if data then
					shame = shame + SHAME_LEVELS[i]
				end
			end
		end
	end]]

	--[[if shame ~= 0 then
		shame = math.floor(shame)
		if shame == 0 then
			shame = 1
		elseif shame > 4 then
			shame = 4
		elseif shame < -2 then
			shame = -2
		end
	end]]

	--�������� �� ���������� ���������
	if shame > 0 then
		if shame < 1 then
			shame = 1
		else
			shame = math.min(4, shame) -- �� ������ 4, ��������
		end
	elseif shame < 0 then -- ���������
		if shame > -1 then
			shame = -1
		else
			shame = math.max(-4, shame)
		end
	end

	Excrementum.shame = shame
	if Excrementum.m_shame then
		Excrementum.m_shame:setValue(-shame)
	end
	return shame
end
Excrementum.UpdateShame = UpdateShame


-- �������� ��������� ���� ���������� ���� ���� ������� �����.
-- ���� ����� ������ ���������, �� ��� ������� �������� (��� �����������) ��������� ��������.
local _cache_done_players = {{},{},{},{},{},{}} -- ����������� ��� ��� ������� ���� �����
local function SendShameMomentToNearest(player, typ, ignore_gender) --print('SendShame = ',typ,', ignore=',ignore_gender)
	--print('SendShameMomentToNearest ',typ,' ',ignore_gender)
	if player:isInvisible() then
		return -- No shame if you are invisible!
	end
	if not ShameIsEnabled(player) then
		return
	end
	--������ ���
	local cache = _cache_done_players[typ]
	if not cache then
		return print('EXC ERR: no cache for sending shame moment!')
	end
	local tm_now = os.time()
	for k,v in pairs(cache) do
		if tm_now > v then
			cache[k] = nil
		end
	end
	local send_arr;
	--local players = getNearestVisiblePlayers(player)
	local gender = not ignore_gender and player:isFemale()
	local x0,y0 = player:getX(),player:getY()
	for p in pairs(Excrementum.nearestPlayers) do -- ��������� ���� ������� ����� ������.
		-- ������ ��� ������ 10 ��� (������ ��� ������ ���� ���������, �� �� 10 ��� �� �� ��������)
		--print(cache[p],' ',ignore_gender,' ',p:isFemale(),' ',gender)
		if not cache[p] and (ignore_gender or p:isFemale() ~= gender) then
			local x1,y1=p:getX(),p:getY()
			local dist = player:DistTo(p)
			--print('dist = ' .. round(dist,1) .. ', visible_at = ' .. round(MathCanSee(x0-x1, y0-y1, p:getLookAngleRadians()),2))
			if dist < 0.1 or MathCanSee(x0-x1, y0-y1, p:getLookAngleRadians()) < 1.5 then -- ����������� �������
				if typ == 4 then
					local angle = MathCanSee(x1-x0, y1-y0, player:getLookAngleRadians()) -- ���� ����������� ������
					--print('see_at ' .. round(angle,2))
					if Excrementum.is_topless and angle < 2
						or Excrementum.is_groinless >= 3 and angle < 1.5 -- ����
						or is_sitting and Excrementum.is_groinless >= 1 and angle < 0.7 -- ����, ������ ��� �����
					then
						-- nothing
					else
						p = nil
					end
				end
				if p then
					cache[p] = tm_now + 10
					local id = p:getOnlineID()
					if id then
						send_arr = send_arr or {typ}
						if id >=0 then
							table.insert(send_arr, id)
						end
						ApplyShame(p:getFullName(), typ)
					end
				end
			end
		end
	end
	--print('FOUND = ',send_arr)
	if send_arr then
		sendClientCommand(player, 'Exc', 'Shame', send_arr)
		UpdateShame(player) -- ��������� ��������� ��� �������.
	end
end
Excrementum.SendShameMomentToNearest = SendShameMomentToNearest

-- �������� ����, ���� ����� � ��� �����. ���� ����!
-- is_moment ������ ��������� ����������, ����� �������� � ������ ������ � ����� ������������� (��� ������ ���� �����)
--[[local function CheckShame(shameTyp, is_moment, ignore_gender)
	shameTyp = shameTyp or Excrementum.nearestPlayers_monitor_type
	local player = Excrementum.p
	local sq0 = player:getCurrentSquare()
	if not sq0 then
		return print('ERROR EXC: no current square')
	end
	for v,typ in pairs(_nearest_players) do
		if typ >= 0 and typ ~= shameTyp then
			local sq = v:getCurrentSquare() -- the player exists and isValid
			if sq and player:CanSee(v) and player:DistTo(v) < 18 and (ignore_gender or player:isFemale() ~= v:isFemale()) then

				_nearest_players[v] = shameTyp -- �������������, ����� �������� �� ���������
				--AddShame
				local name = v:getFullName()
				if name then
					if is_moment then
						ApplyShame(name, shameTyp)
					else
						local usr = Excrementum.WaitToApplyShame[name]
						if not usr then
							usr = {}
							Excrementum.WaitToApplyShame[name] = usr
						end
						usr[shameTyp] = {
							typ = shameTyp,
							expire = os.time() + 10,
						}
					end
					--local t = (shameTyp == 2 or shameTyp == 3) and 1 or shameTyp
					sendClientCommand(player, 'Exc', 'moment', {shameTyp, name, is_moment, ignore_gender})
				end
			end
		end
	end
end
Excrementum.CheckShame = CheckShame]]





--Get zombies count in area 3x3
local function GetZombiesCountSq(sq)
	if not sq then
		return 0
	end
	local res = 0
	for i=0,sq:getMovingObjects():size()-1 do
		local o = sq:getMovingObjects():get(i);
		if instanceof(o, "IsoZombie") then
			res = res + 1
		end
	end
	local sq2 = sq:getN()
	if sq2 then --N
		for i=0,sq2:getMovingObjects():size()-1 do
			local o = sq2:getMovingObjects():get(i);
			if instanceof(o, "IsoZombie") then
				res = res + 1
			end
		end
	end
	sq2 = sq:getS()
	if sq2 then --S
		for i=0,sq2:getMovingObjects():size()-1 do
			local o = sq2:getMovingObjects():get(i);
			if instanceof(o, "IsoZombie") then
				res = res + 1
			end
		end
	end
	local sq3 = sq:getE()
	if sq3 then --E
		for i=0,sq3:getMovingObjects():size()-1 do
			local o = sq3:getMovingObjects():get(i);
			if instanceof(o, "IsoZombie") then
				res = res + 1
			end
		end
		sq2 = sq3:getN()
		if sq2 then --NE
			for i=0,sq2:getMovingObjects():size()-1 do
				local o = sq2:getMovingObjects():get(i);
				if instanceof(o, "IsoZombie") then
					res = res + 1
				end
			end
		end
		sq2 = sq3:getS()
		if sq2 then --SE
			for i=0,sq2:getMovingObjects():size()-1 do
				local o = sq2:getMovingObjects():get(i);
				if instanceof(o, "IsoZombie") then
					res = res + 1
				end
			end
		end
	end
	sq3 = sq:getW()
	if sq3 then --W
		for i=0,sq3:getMovingObjects():size()-1 do
			local o = sq3:getMovingObjects():get(i);
			if instanceof(o, "IsoZombie") then
				res = res + 1
			end
		end
		sq2 = sq3:getN()
		if sq2 then --NW
			for i=0,sq2:getMovingObjects():size()-1 do
				local o = sq2:getMovingObjects():get(i);
				if instanceof(o, "IsoZombie") then
					res = res + 1
				end
			end
		end
		sq2 = sq3:getS()
		if sq2 then --SW
			for i=0,sq2:getMovingObjects():size()-1 do
				local o = sq2:getMovingObjects():get(i);
				if instanceof(o, "IsoZombie") then
					res = res + 1
				end
			end
		end
	end
	return res
end



---------- Excrementum utils ----------

--p:getModData().exc = nil
local function CreateModData(data)
	local exc = data.exc
	if not exc then
		exc = {
			st = {}, -- stomach queue, like FIFO/FIRO
			ch = {h=0, w=0, P=0, L=0, C=0, v=0, ps=0, d=0}, --chyme values: �������, ����, PLC=���, ��������, ps=��, d=����������
			int = QList.init(), --intestine queue
			col = { --colon values
				V = 0, -- ����� ����� ����
				visc = 1, -- "��������"
				og = 0, -- ����������� ��� � ������ (��� �� ����������� � �����). ������ 10 ��� ���� ������ 30%. ���� ������ 1.2 �������, �� ����� ��.
				tf = nil, -- time first, ����� �������, ����� �������� ����������.
				td = nil, -- time defecate, ����� ������� ������ �������
			},
			urine = 0, -- ����
			ss = 0, -- ��������� ������ � �������� ���� (�� ��� �� +0-100%)
			sc = 0, -- ���������� ������� ������� � ������.
			-- 1/2 = norm/mini, ����� ������ [x,y,visible] ��� norm, def_mini, urin_mini
			layout = {1, 50,500,false, 5,450,false, 25,450,false},
			da = false, --dirty ass
			dh = false, --dirty hands
			df = false, --dirty feet
			hg = 0, -- ���� ������
			rel = {}, -- relations
			swt = 0, -- ���������� ����, ������� ������ ����� � ��� (�� ������ ����������� � ������� ������). ������ ����� �� ������ ������.
			uTm = 0,
			bk = 0, -- ����� ���������� ������ �����
			bkp = 1, -- ���������� ����������� ������� � ������� ���
		}
		data.exc = exc
	end
	exc.hg = exc.hg or 0
	exc.rel = exc.rel or {}
	exc.swt = exc.swt or 0
	exc.uTm = exc.uTm or 0
	exc.bk = exc.bk or 0
	exc.bkp = exc.bkp or 0
	Excrementum.urine = exc.urine
	Excrementum.feces = exc.col.V
	-----------
	exc.ch.d = exc.ch.d or 0
end
--[[
{ -- ������� ���� ���������
    ['full_name'] = { -- ���� = ���, � ��� ���������
        e = true, -- (eye) ��� �� ����� ������ ������� ��� ��������� �������� (���� ��, �� ��� ������ ������ ���-����).
        c = 0, -- (cnt) ���������� ���, ����� ������� ����� �����. ����� 10 ���� ��� �����.
        {
            t = 0, -- (type) ��� ���������. 1) � ����� �� 2) ��� �� ������ 3) ��� ��� ������ 4) ������ ����� 5) ������ ������ ��
            l = 1, -- (level) ������� ������. ��������� ������ = +0.5
            b = 0, -- (burn) ����� �������, � ������� ��������� ���������� ������������ (���� �� ��������).
            h = 0, -- (hide) ����� �������, � ������� ��������� ��������� �������� (�� ��������� �������).
            a = 0, -- (amount) ��������� �����, ������� ����� �������� �����, ����� ��������� �������. ���� ��� ���������� �����.
        },
        -- ..... ������ ���������
    },
    -- ..... ������ ����
}
� ������� �������� ��� = 0
--]]


local FEMALE_DIRS = { N='N', E='E', S='S', W='W', }
local MALE_DIRS = { N='S', S='N', E='W', W='E', }
function Excrementum.GetDir(is_female, object)
	if not object then
		return
	end
	local facing = object:getProperties():Val("Facing")
	--print('Object Facing = ' .. tostring(facing))
	if is_female then
		return FEMALE_DIRS[facing]
	else
		return MALE_DIRS[facing]
	end
end



-- ����� �� ����� "������ �����", ����� ��� �� �������� ��������� �������.
local function IsBusyNow(player)
	local act_now = GetActionName(player,1)
	if act_now == 'UrinateDropPantsAction' or act_now == 'InvoluntaryUrinate'
		or act_now == 'DefecateDropPantsAction' or act_now == 'InvoluntaryDefecate'
	then
		return true
	end
end



--Extract food properties
--print(Excrementum.getFoodTypeSpeedVisc('Base.Sugar'))
local  getF_cache, getV_cache = {}, {}
local function getFoodTypeSpeedVisc(full_type) --print('full_type = ',full_type)-- ������ �� id
	if not full_type then
		return DEFAULT_SPEED, DEFAULT_VISC
	end
	local food_cache = getF_cache[full_type]
	if food_cache then
		return food_cache, getV_cache[full_type]
	end
	local f,v = FOOD_SPEED[full_type], FOOD_VISC[full_type]
	local food_type = nil
	if not (f and v) then
		local food = InventoryItemFactory.CreateItem(full_type);
		food_type = food and food:getFoodType() --or nil
		f = f or FOOD_SPEED[food_type] or DEFAULT_SPEED
		v = v or FOOD_VISC[food_type] or DEFAULT_VISC
	end
	getF_cache[full_type] = f
	getV_cache[full_type] = v
	return f,v,food_type
end
Excrementum.getFoodTypeSpeedVisc = getFoodTypeSpeedVisc

--print(Excrementum.getFoodSpeedVisc(g('sugar')))
local function getFoodSpeedVisc(food) -- ������ ��� �� ����� ��� (������ ����������, ��� ������ ������ ��� ����� ���� ������)
	local extra = food:getExtraItems()
	local extra_cnt = extra and extra:size() or 0
	local spices = food:getSpices()
	local spices_cnt = spices and spices:size() or 0
	local base_s, base_v = getFoodTypeSpeedVisc(food:getFullType()) --print('base: ',base_s, base_v)
	if extra_cnt == 0 and spices_cnt == 0 then
		return base_s, base_v
	end

	local _ings = Excrementum.DEBUG and {} or nil

	-- ��������� ���� ������������ � ������
	local cnt_s, cnt_v, sum_s, sum_v = 0,0,0,0
	for i=0,extra_cnt-1 do
		local ing_name = extra:get(i)
		local s,v = getFoodTypeSpeedVisc(ing_name)
		if Excrementum.DEBUG then
			--print(ing_name,s,v)
			_,__,food_type = getFoodTypeSpeedVisc(ing_name)
			table.insert(_ings, tostring(ing_name)..(food_type and "["..food_type.."]" or "") .. ", " .. tostring(s) )--.. ", " .. tostring(v))
		end
		if s ~= -1 then
			sum_s = sum_s + s
			cnt_s = cnt_s + 1
		end
		if v ~= -1 then
			sum_v = sum_v + v
			cnt_v = cnt_v + 1
		end
	end
	for i=0,spices_cnt-1 do
		local ing_name = spices:get(i)
		local s,v = getFoodTypeSpeedVisc(ing_name)
		if Excrementum.DEBUG then
			--print(ing_name,s,v)
			_,__,food_type = getFoodTypeSpeedVisc(ing_name)
			table.insert(_ings, tostring(ing_name)..(food_type and "["..food_type.."]" or "") .. ", " .. tostring(s) )--.. ", " .. tostring(v))
		end
		if s ~= -1 then
			sum_s = sum_s + s
			cnt_s = cnt_s + 1
		end
		if v ~= -1 then
			sum_v = sum_v + v
			cnt_v = cnt_v + 1
		end
	end

	--��������� ��� "����������" � ������ ������������ � ���
	if base_s ~= DEFAULT_SPEED then
		sum_s = sum_s + base_s
		cnt_s = cnt_s + 1
	end
	if base_v ~= DEFAULT_VISC then
		sum_v = sum_v + base_s
		cnt_v = cnt_v + 1
	end

	-- ���������� sum_s, ���� ����������� ������ ����, ����� ������� �������� ������ ���
	if cnt_s > 0 then
		base_s = sum_s / cnt_s
	end
	if cnt_v > 0 then
		base_v = sum_v / cnt_v
	end
	return base_s, base_v, (_ings and #_ings > 0 and ". . "..table.concat(_ings,"\n. . ") or nil)
end
Excrementum.getFoodSpeedVisc = getFoodSpeedVisc


-- ��������� � ����� ���, �������������� �������� (� ������� �� ������� �� �������).
-- cavity - ������� (�������, ��� �������), ������ ��� ������
-- row - ������ �� �������� �����
local function AddToChyme(chyme, row, cavity, idx)
	chyme.P = chyme.P + row.P
	chyme.L = chyme.L + row.L
	chyme.C = chyme.C + row.C
	chyme.w = chyme.w + row.w
	if row.ps then
		--chyme.ps = chyme.ps + row.ps
	end
	local sum = chyme.h + row.h -- ����� ����� ������ (���� ���� ����������� ���� ����)
	if chyme.h == 0 then
		chyme.v = row.v
	else -- ������ �������� �� "�������" ����� ���, ��� ���� � ��� ����������.
		chyme.v = lerp(chyme.v, row.v, row.h / sum)
	end
	if row.ps then -- ��
		chyme.v = chyme.v * 0.5
	end
	chyme.h = sum
	if idx then
		table.remove(cavity, idx)
		--return true
	end
end

--��������� ���� � �����
local URINE_DRINK = 0.75 -- �����������, ������� �������� ��������� � ����.
local function AddWaterToChyme(chyme, w)
	chyme.w = chyme.w + w * URINE_DRINK
end



-- ����� ������������� �������� ����� � ������������ � ����� ������� �������
local function GetStomachTime(row, V)
	local sum = row.P + row.L + row.C
	local p = 1 -- "��������������" (��� "������" �������� ��� �����������)
	if sum ~= 0 then
		p = row.C / sum
	end
	return (1 + (V - 50) * lerp(0.43, 0.17, p) / 50) * row.s * SandboxVars_Excrementum.StomachMultiplier
end
Excrementum.GetStomachTime = GetStomachTime

--������� ������ ������� (�������, ������ � �.�.) �� ��������� h � w
local function GetStomachV(stomach)
	local h_sum, w_sum = (stomach.h or 0), (stomach.w or 0)
	for _,v in ipairs(stomach) do
		h_sum = h_sum + v.h
		w_sum = w_sum + v.w
	end
	return h_sum+w_sum, h_sum, w_sum
end
Excrementum.GetStomachV = GetStomachV

--������� ������������ ��������: ��� ������, ��� ������ �������� ���������.
local function GetOsmoticP(cavity)
	local sum = (cavity.P + cavity.L + cavity.C)
	if sum == 0 then
		return 1
	end
	local p = cavity.P * 3 / sum
	if p > 1 then p = 1 end
	if p < 0 then p = 0 end
	return p
end
Excrementum.GetOsmoticP = GetOsmoticP


-- ���������� ����� ������� ��� �������� �����
local function ResetRowTime(now, v, old_V, new_V)
	new_V = new_V or old_V
	local tm_left = v.tt - now
	if tm_left > 0  then
		local tm = GetStomachTime(v, old_V)
		if tm_left > tm + 0.1 then
			print('ERROR EXC: tm_left > tm ',tm_left,tm); --������������ ���
			tm_left = tm
		end
		v.s = v.s * (tm_left / tm)
		v.tt = now + GetStomachTime(v, new_V)
	end
end

-- ���������� ��������� ����� ������� �� ������� ��� ������� ������ �������
local function ResetStomachTime(now, stomach, old_V, new_V)
	new_V = new_V or old_V
	for _,v in ipairs(stomach) do
		local tm_left = v.tt - now
		if tm_left > 0  then
			local tm = GetStomachTime(v, old_V)
			if tm_left > tm + 0.1 then
				print('ERROR EXC: tm_left > tm ',tm_left,tm); --������������ ���
				tm_left = tm
			end
			v.s = v.s * (tm_left / tm)
			--v.te = now
			v.tt = now + GetStomachTime(v, new_V)
		end
	end
end


--��������� �������� � Excrementum, ����������� �� exc
local function UpdateColonValues(exc)
	local now = Excrementum.now
	local colon = exc.col
	Excrementum.feces = colon.V
	Excrementum.feces_threshold = colon.visc * SandboxVars_Excrementum.ColonBaseThreshold * 0.01
	if colon.tf then -- ����� 22 ���� ����� ��� �������� ���������.
		local delta = now - colon.tf
		if delta >= SandboxVars_Excrementum.ColonMinutes then
			Excrementum.feces_threshold = Excrementum.feces_threshold - (delta-SandboxVars_Excrementum.ColonMinutes) * 0.00166667 -- / 60) * 0.1
		end
	end
end

local STOMACH_V = SandboxVars_Excrementum.StomachVolume * 0.01
--local STOMACH_V_ADD = SandboxVars_Excrementum.AdditionalStomachVolume
local STOMACH_MIN = math.min(STOMACH_V, 0.31)
local is_HeaMods = false
local function UpdateStomachPain(exc, player)
	STOMACH_V = SandboxVars_Excrementum.StomachVolume * 0.01
	STOMACH_MIN = math.min(STOMACH_V, 0.31)
	local total_V, total_H, total_W = GetStomachV(exc.st)
	do
		local a,b,c = GetStomachV(exc.ch)
		total_V = total_V + a
		total_H = total_H + b
		total_W = total_W + c
	end
	Excrementum.StomachTotalV = total_V
	Excrementum.StomachTotalH = total_H
	Excrementum.StomachTotalW = total_W
	--print('UpdateStomachPain(); total_V = ',total_V)
	local is_credit;
	if total_V > STOMACH_V then -- ������� ����� ����
		Excrementum.StomachPain = (total_V - STOMACH_V) / SandboxVars_Excrementum.AdditionalStomachVolume * 9000 -- * 100 * 90
		-- ����� ������ �����
		is_credit = true
	else
		Excrementum.StomachPain = 0
		is_credit = total_V > STOMACH_MIN
	end
	if is_credit then -- ���� ������� "� ����"
		player = player or getSpecificPlayer(0)
		local stats = player:getStats()
		local hunger = stats:getHunger()
		if hunger > 0.14 then
			exc.hg = exc.hg + (hunger - 0.14) -- ���������� �����, ������� �������� (����� �������!)
			stats:setHunger(0.14) -- ������, ����� ����� ��� ��� ����������� �������
		end
	elseif exc.hg > 0 then -- ���������� �����
		player = player or getSpecificPlayer(0)
		local stats = player:getStats()
		local hunger = stats:getHunger()
		if hunger < 1 then
			hunger = hunger + exc.hg
			stats:setHunger(hunger)
		end
		exc.hg = 0
	end

	-- ������������� � ������ �� Hea (SOTO � More Simple Traits)
	if is_HeaMods and (player:HasTrait("SensitiveDigestion") or player:HasTrait("SensitiveStomach")) then --print('inside')
		local credit = exc.sdt or 0
		local level = Excrementum.StomachPain >= 30 and 2 or Excrementum.StomachPain > 0 and 1 or 0 --print('level = ',level)
		if level > 0 then
			local need_sickness = level == 2 and 62.5 or 37.5 -- ������� � ����� �������
			local bd = Excrementum.bd
			local sickness = bd:getFoodSicknessLevel() --print('sick/need = ',sickness,' ',need_sickness)
			if sickness < need_sickness then -- ���� � ����
				bd:setFoodSicknessLevel(need_sickness)
				exc.sdt = math.min(need_sickness, credit + (need_sickness - sickness)) -- ������ �� ����� ���� ������ ���������
			elseif sickness > 82.5 and credit > 0 then -- ������� �����������
				local refund = sickness - 82.5 -- ������� ���� �������
				if refund > credit then -- ������� ���� ������, ��� ������
					bd:setFoodSicknessLevel(sickness - credit)
					exc.sdt = 0
				else -- ���������� ����� �����
					bd:setFoodSicknessLevel(sickness - refund)
					exc.sdt = credit - refund
				end
			elseif level == 1 and sickness > 37.5 and credit > 0 then
				--�������� ��������, � ������� ���� �� ������� ����� �������, �� �� ����
				local extra = sickness - 37.5
				if credit > extra then
					bd:setFoodSicknessLevel(37.5)
					exc.sdt = credit - extra
				else
					bd:setFoodSicknessLevel(sickness - credit)
					exc.sdt = 0
				end
			end
		elseif credit > 0 then -- ��������� ����� ������
			local bd = Excrementum.bd
			local sickness = bd:getFoodSicknessLevel()
			bd:setFoodSicknessLevel(sickness - credit)
			exc.sdt = 0
		end
	end

end

-- ���������� ������ ���, ����� ����� �������� ��������� � ���� ��������� ���������� ������� �������
local STOMACH_MED = (STOMACH_V - STOMACH_MIN) / 2 + STOMACH_MIN;
local function DoUpdate(player, ignore_changes) --print('DoUpdate()')
	STOMACH_MED = (STOMACH_V - STOMACH_MIN) * 0.5 + STOMACH_MIN;
	local exc = player:getModData().exc
	if exc then --GetActionName
		--if GetActionName(player) ~= 'InvoluntaryUrinate'
		if Excrementum.is_urine_update then
			Excrementum.urine = exc.urine
		end
		UpdateColonValues(exc)
		local green_stomach = 0 -- may be negative
		if Excrementum.StomachPain > 0 then
			green_stomach = -Excrementum.StomachPain
		elseif Excrementum.StomachTotalV > 0 then
			if Excrementum.StomachTotalV < STOMACH_MIN then
				local is_h = exc.ch.h > 0 or exc.st[1] or exc.ch[1]
				if not is_h and exc.ch.w < 0.1 then
					green_stomach = 0
					Excrementum.is_green_stomach = false
				else
					local hunger = player:getStats():getHunger()
					if hunger > 0.147 then
						green_stomach = 1
					else
						green_stomach = 2
					end
				end
			elseif Excrementum.StomachTotalV < STOMACH_MED then
				green_stomach = 3
			else
				green_stomach = 4
			end
		end
		Excrementum.green_stomach = green_stomach
		if Excrementum.m_stomach then
			if player:isDead() then -- or player:isGodMod() then
				Excrementum.m_stomach:setValue(0)
				Excrementum.m_colon:setValue(0)
				Excrementum.m_urine:setValue(0)
				Excrementum.m_stomachW:setValue(0)
				Excrementum.m_shame:setValue(0)
				Excrementum.m_smell:setValue(0)
			else
				local st_moodle = OPTIONS.stomach_moodle
				if st_moodle == 1 or st_moodle == 2 and green_stomach < 0 then
					local w = Excrementum.StomachTotalW
					if w > 0 and Excrementum.StomachTotalH / w < 0.29 then
						Excrementum.m_stomachW:setValue(green_stomach)
						Excrementum.m_stomach:setValue(0)
					else
						Excrementum.m_stomachW:setValue(0)
						Excrementum.m_stomach:setValue(green_stomach)
					end
				else
					Excrementum.m_stomach:setValue(0)
					Excrementum.m_stomachW:setValue(0)
				end
				local d = -Excrementum.ColonPain
				if d >= 0 then
					if exc.col.td then
						d = 3
					elseif QList.getLength(exc.int) > 0 then
						d = 1
					end
				end
				local col_moodle = OPTIONS.colon_moodle
				if col_moodle == 1
					or exc.col.td -- 2
					or col_moodle == 3 and d < 0
				then
					Excrementum.m_colon:setValue(d)
				else
					Excrementum.m_colon:setValue(0)
				end
				local u = Excrementum.urine
				local X = 0.3 + Excrementum.Ms
				local Y = X + 0.15
				if u < 0.2 then
					u = 0
				elseif u < 0.3 then
					u = 1
				elseif u < X then
					u = -1
				elseif u < Y then
					u = -3
				else
					u = -4
				end
				local ur_moodle = OPTIONS.urine_moodle
				if ur_moodle == 1 or ur_moodle == 2 and u < 0 or ur_moodle == 3 and u < -2 then
					Excrementum.m_urine:setValue(u)
				else
					Excrementum.m_urine:setValue(0)
				end
			end
		end
	end
	for fn in pairs(Excrementum.update_fns) do --print(' ----- >> fn() ',fn)
		fn(player, exc)
	end
end
Excrementum.DoUpdate = DoUpdate

function Excrementum.EmptyStomach(exc)
	for i=#exc.st,1,-1 do
		exc.st[i] = nil
	end
	for i=#exc.ch,1,-1 do
		exc.ch[i] = nil
	end
	exc.ch.h = 0
	exc.ch.w = 0
	exc.ch.ps = 0
	exc.ch.d = 0
end


local function GetColonPain(delta)
	local pain = (delta - 240) * 0.167
	return pain
end


function Excrementum.SendClientCommand(com, obj, param, player, a, b)
	player = player or Excrementum.p
	local index = obj:getObjectIndex()
	local args = {x=obj:getX(), y=obj:getY(), z=obj:getZ(), param=param, idx=index, a, b}
	sendClientCommand(player, 'Exc', com, args)
end

-- ���������, ������ �� ������. ���� ��, �� ������� ����� ����� � ������. �������
function Excrementum.CheckCleanItem(item)
	if not (instanceof(item, "Clothing") and item:hasModData() and item:getDirtyness() == 0) then
		return
	end
	local data = item:getModData()
	if data.feces then
		data.feces = nil
	end
	if data.urine then
		data.urine = nil
	end
end


--vanilla setDirtyness has cosmetic effect. We still must set it but before we need to recalc all parts
-- ����������� ����� ������� ����� ������� �������! ������ +0.1 �����, � �������, +0.02, � ����������� �� ������.
function Excrementum.AddDirtyness(item, dirt, target_part) --Excrementum.AddDirtyness(g('shorts'),0.1)
	local visual = item:getVisual()
	if not visual then
		item:setDirtyness(item:getDirtyness() + dirt * 100)
		return
	end
	-- change the target part
	if target_part then
		local d = visual:getDirt(target_part)
		if d < 1 then
			local sum = d + dirt
			if sum > 1 then
				visual:setDirt(target_part, 1)
				dirt = sum - 1
			else
				visual:setDirt(target_part, sum)
				dirt = 0
			end
		end
	end
	-- if dirt is left, change all other parts
	local parts = item:getCoveredParts() -- array of userdata
	local cnt = parts:size()
	if cnt == 0 then
		item:setDirtyness(item:getDirtyness() + dirt * 100)
		return
	end
	local sum = 0
	if dirt == 0 then  -- ������ ���������
		for i=0,cnt-1 do
			local part = parts:get(i)
			sum = sum + visual:getDirt(part)
		end
	else -- ���������� �����������
		local micro_dirt = dirt / cnt
		for i=0,cnt-1 do
			local part = parts:get(i)
			local d = math.min(visual:getDirt(part) + micro_dirt, 1)
			sum = sum + d
			visual:setDirt(part, d)
		end
	end
	item:setDirtyness(sum / cnt * 100)
end

--������������� ���� ������ ���������� �������.
--���� ��� ������������ ��� ���������
function Excrementum.SetDirtyness(item, dirt) --Excrementum.SetDirtyness(g('shorts'),0.5)
	--dirt = dirt or 0
	local visual = item:getVisual()
	local parts = item:getCoveredParts() -- no covered parts in weapon!
	if visual and parts then
		for i=0,parts:size()-1 do
			local part = parts:get(i)
			visual:setDirt(part, dirt)
		end
	end
	item:setDirtyness(dirt*100)
end



local function VanillaGreenStomach_InjectOnce(md, fed_idx)
	-- md may be changed on death
	local m = getmetatable(md).__index
	local old_fn = m.getMoodleLevel
	m.getMoodleLevel = function(self, idx, ...)
		if idx ~= fed_idx or self ~= Excrementum.md then
			return old_fn(self, idx, ...)
		end
		if Excrementum.green_stomach > 0 then
			return Excrementum.green_stomach
		end
		return 0
	end
end


-- over 80 is critical
function Excrementum:Laziness()
	if not self.p then
		return 0
	end
	local laziness = self.stats:getPanic() + self.bd:getUnhappynessLevel()
	if self.p:HasTrait("Disorganized") then
		laziness = laziness + 70
	end
	if self.p:HasTrait("AllThumbs") then
		laziness = laziness + 30
	end
	return laziness
end


function Excrementum.LowerUnhappiness(uh)
	local level = Excrementum.ZoneLevel
	if level > 2 then --civilization
		if level > 3 then
			return uh
		elseif uh > 1 then
			uh = math.floor(uh * 0.66)
			uh = math.max(1, uh)
		end
	elseif level > 1 then
		uh = math.min(0, uh)
	else
		uh = math.min(-1, uh)
	end
	return uh
end

--[[
Hand_L      0
Hand_R      1
ForeArm_L   2
ForeArm_R   3
UpperArm_L  4
UpperArm_R  5
Torso_Upper 6
Torso_Lower 7
Head        8
Neck        9
Groin      10
UpperLeg_L 11
UpperLeg_R 12
LowerLeg_L 13
LowerLeg_R 14
Foot_L     15
Foot_R     16
MAX        17
uh_mult - ������������ ��������� ������������ ��� 100% ���������.
min_part, max_part - �������� ������, ������������, ����� �������� ����������;
���� min_part - ������ ��������, � max_part - ����������� ��������� ���� ���� (�� ��������� 1:1);
���� �� ��, �� min_part - ������ ��������, � �� ������.
temp - ��������� �� ����� ��������� (�� ��������� ��)
--]]
function Excrementum.adjustMaxTime(maxTime, uh_mult, min_part, max_part, temp) -- action independent
	if maxTime == -1 then
		return maxTime
	end

	--unhappiness
	if uh_mult then
		maxTime = math.floor(lerp(maxTime, maxTime * uh_mult, Excrementum.bd:getUnhappynessLevel() / 100))
	end

	-- add more time if the character have wounded parts
	--Hand_L, ForeArm_R
	if min_part then
		local typ = type(min_part)
		if typ == 'string' then
			local part = Excrementum.bd:getBodyPart(BodyPartType[min_part]);
			maxTime = maxTime + part:getPain() * (max_part or 1)
		elseif typ == 'table' then
			local added = 0
			for _,v in pairs(min_part) do
				local part = Excrementum.bd:getBodyPart(BodyPartType[v]);
				added = added + part:getPain();
			end
			maxTime = maxTime + added * (max_part or 1)
		else
			if not max_part then
				max_part = min_part
			end
			for i=BodyPartType.ToIndex(BodyPartType[min_part]), BodyPartType.ToIndex(BodyPartType[max_part]) do
				local part = Excrementum.bd:getBodyPart(BodyPartType.FromIndex(i));
				maxTime = maxTime + part:getPain();
			end
		end
	end

	-- Apply a multiplier based on body temperature.
	if temp ~= false then
		maxTime = maxTime * Excrementum.p:getTimedActionTimeModifier();
	end
	return math.floor(maxTime);
end


------------------------------------------------------  ON EAT -------------------------------------------------

local OLD_THIRST = nil
local SWEAT_SUM = 0
--��� ��� ������ �� �������� ����������� � ����� ��������, ������������ � "onEat"
do
	-- self.character:Eat(self.item, percentage);
	local Sandbox_Drink = SandboxVars_Excrementum.UrinateIncreaseMultiplier
	local old_Eat = nil
	local abs = math.abs
	local RETEXTURE_MODS = {
		SimpleRetexturesFemaleNude = 'female',
		SimpleRetexturesMaleNude = 'male',
		rasBodyMod = true,
		SlavRetex = true,
		TEDSKINFIX = true,
		['TED BEER`s Player Skin Retexture'] = 'female',
		['TED BEER`s Male Player Skin Retexture'] = 'male',
		PYZomboid_nude = true,
		["Michael's Female Skin Retexture"] = 'female',
		["Michael's Female Skin Retexture Without Tattoo"] = 'female',
		["Michael's Female Skin Retexture AIO"] = 'female',
		FxSlavsTextures = true,
		['Fantasy Workshop VS'] = 'female',
		['Fantasy warehouse'] = 'female',
		['Variable skin'] = 'female',
		['SlimBodyAndRealFace'] = 'female',
		['SlimBodyAndRealFace c'] = 'female',
		['Skin Retexture5'] = 'female',
		StacyFemaleSkins = 'female',
		D7x = 'female',
	}

	function Excrementum.EnableRetextureMod(mod_id, new_val)
		if not mod_id then
			IS_RETEXTURE_MOD = true
		else
			RETEXTURE_MODS[mod_id] = new_val
		end
	end

	-- perc - ��� ������� �� BaseHunger, � �� �� ��������� ������� �������.
	local function OnEat(player, food, perc, ...)
		if not food then
			return -- no error even if there is a bug in another mod
		end
		if player ~= Excrementum.p then print("WRONG PLAYER")
			return old_Eat(player, food, perc, ...)
		end
		Sandbox_Drink = SandboxVars_Excrementum.UrinateIncreaseMultiplier
		local mod_data = player:getModData();
		--if not mod_data.exc then
		--	CreateModData(mod_data)
		--end
		local stomach = mod_data.exc.st

		--print('PERC EATEN: ',food:getType(),'; ',round3(perc))
		local real_hunger = -food:getHungerChange() -- �������� ������� �������
		local virt_hunger = -food:getHungChange() -- ������� ������� ��� ������� �������
		local base_hunger = -food:getBaseHunger() -- ��������� ������ (��� ������� � ����� �����������)
		local h = 0
		if real_hunger ~= 0 then
			h = (real_hunger/virt_hunger) * base_hunger * perc -- ������� ������� �������
			local max_food = (SandboxVars_Excrementum.StomachVolume + SandboxVars_Excrementum.AdditionalStomachVolume) * 0.01
			if h > max_food then --150 -- ������ �� �������� ��� +100500 �������
				perc = perc * (max_food / h)
				h = max_food
			end
		end
		local w = -food:getThirstChange() * perc
		local P,L,C = food:getProteins()*perc, food:getLipids()*perc, food:getCarbohydrates()*perc
		if abs(h) > abs(real_hunger) then
			h = real_hunger
		end
		--print('HUNGER EATEN: ',food:getType(),'; ',round3(h))
		--print('PLC EATEN: ',P,L,C)



		local time_eaten = player:getHoursSurvived() * 60

		local speed, visc, _ings = getFoodSpeedVisc(food)
		if h < 0 then -- ������������� �������� �� �����
			h = 0
		end

		local diuretic = 0 -- ����������
		if food:isAlcoholic() then --and w >= 0 then
			local happy = -food:getUnhappyChange() * 0.01 * perc
			diuretic = (h + ((happy > 0) and happy or 0)) * 0.5
		end

		local fat = food:getFatigueChange()
		if fat < 0 then
			if w < 0 then -- ��������� �����
				diuretic = diuretic - w * 0.5 -- �������� ����������� � ����������� �������
			else
				fat = -fat * perc
				local base = math.min(fat, h) -- ��� ��������� ����� 0
				diuretic = diuretic + base
			end
		end

		if diuretic > 0 then --print('DIURETIC = ',diuretic)
			local ch = mod_data.exc.ch
			ch.d = ch.d + diuretic * 2 * Sandbox_Drink
		end


		local stats = Excrementum.stats
		local thirst1 = stats:getThirst()
		local bd = player:getBodyDamage()
		local poison1 = bd:getPoisonLevel()

		-- remove vanilla moodle
		if h > 0 then
			local hunger = stats:getHunger() --print('HUNGER = ', hunger)
			if hunger - h < 0 then
				stats:setHunger(h + 0.00001) --print('setHunger( ' .. (h + 0.00001) .. ' )')
				--stats:setHunger(0.5)
				--print('getHunger = ',stats:getHunger())
			end
		end



		old_Eat(player, food, perc, ...) --==========> THIS!!! <===========--

		--print('PLC AFTER: ', food:getProteins()*perc, food:getLipids()*perc, food:getCarbohydrates()*perc)
		--OLD_THIRST = stats:getThirst() -- �� ��������� ���������
		local thirst_delta = thirst1 - stats:getThirst()
		--print("DRINKED: ",round(thirst_delta,2))
		w = w - thirst_delta -- ��� ���� ����������� � ������ ��������
		local posion_delta = bd:getPoisonLevel() - poison1

		if w < 0 then -- ��������� ����� ������ �������� � �����, ��� � ��.
			w = 0
		end



		--print('HW = ',h,w)
		if h + w > 0 and not player:isGodMod() then

			local V = GetStomachV(stomach)

			--local delta = speed * h * 2, -- ����� 0.5 ��������� ���������� ����� ���, ������� *2
			local data = {
				--te=time_eaten,
				tt=0, -- target time, �������� ������ ��� ��������� ������ �������
				s=speed,
				v=visc,
				h=h,
				w=w*Sandbox_Drink,
				P=P,
				L=L,
				C=C,
			}
			data.tt = time_eaten + GetStomachTime(data, V)
			if posion_delta > 0 then
				data.ps = posion_delta
			end

			if w == 0 or h > w then -- to queue
				if Excrementum.DEBUG then
					data.name = food:getFullType()
					data.ings = _ings
				end
				table.insert(stomach, data)
				ResetStomachTime(time_eaten, stomach, V, V + h + w)
				-- ����� �������, ��� ����� ��� � ������� �����: h > 0
			else -- to chyme
				AddToChyme(mod_data.exc.ch, data)
			end

			UpdateStomachPain(mod_data.exc, player)

			if Excrementum.DEBUG then
				ExcrementumDebugWindow:updateText()
			end
		end


		--getHungerChange() --3
		--getBaseHunger --12


		--�� ����, ��� �� ������ � �����, ��������� � ������� ��������
		--if
		DoUpdate(player)
	end -- OnEat

	-------------- injection ON_CREATE_PLAYER -----------------
	Events.OnCreatePlayer.Add(function(int, player)
		local p = getSpecificPlayer(0)
		if p ~= player then
			print('EXC ERROR: Wrong player')
			return
		end
		Excrementum.GameTime = getGameTime()
		CELL = getCell()

		-- Weel Fed moodle mod compatibility. Any other mod will check green stomach correctly.
		local md = player:getMoodles()
		Excrementum.md = md
		if not Excrementum.is_Player_Injected then
			Excrementum.is_Player_Injected = true
			-- ���� ���� �������
			local found_idx = nil
			for i=md:getNumMoodles()-1,0,-1 do -- ��� ����� � �����
				local name = md:getMoodleType(i):name()
				if name == 'FoodEaten' then
					found_idx = i
					break
				end
			end
			if found_idx then
				VanillaGreenStomach_InjectOnce(md, found_idx)
			end
		end

		Excrementum.p = p
		Excrementum.female = p:isFemale()
		Excrementum.bd = p:getBodyDamage()
		Excrementum.stats = p:getStats()
		OLD_THIRST = Excrementum.stats:getThirst()
		local data = player:getModData()
		CreateModData(data)
		Excrementum.exc = data.exc
		SWEAT_SUM = data.exc.swt
		UpdateStomachPain(data.exc, player)
		if not old_Eat then
			local m = getmetatable(player).__index
			old_Eat = m.Eat
			m.Eat = OnEat
		end

		if MF and MF.ISMoodle then
			if Excrementum.DEBUG and MF and MF.ISMoodle and not Excrementum.is_DebugMoodleInjected then
				Excrementum.is_DebugMoodleInjected = true
				local old_children = MF.ISMoodle.createChildren
				MF.ISMoodle.createChildren = function(self)
					if old_children then
						old_children(self)
					end
					local overlay = ISPanel:new(0,0,self.width,self.height)
					self.overlay = overlay
					overlay:initialise()
					overlay.backgroundColor.r = 0
					overlay.backgroundColor.g = 1
					overlay.backgroundColor.b = 0
					overlay.backgroundColor.a = 0.15
					overlay.borderColor.a = 0.5
					self:addChild(overlay)
				end



				--[[local old_moodle = MF.ISMoodle.new
				MF.ISMoodle.new = function(...) --print('new_moodle')
					local old_fn = ISUIElement.new
					ISUIElement.new = function(_, ...) --print('new_element')
						ISUIElement.new = old_fn
						return ISPanel:new(...)
					end
					local o = old_moodle(...)
					o.backgroundColor.r = 0
					o.backgroundColor.g = 1
					o.backgroundColor.b = 0
					o.backgroundColor.a = 0.5
					o.borderColor.a = 0.5

					ISUIElement.new = old_fn
					return o
				end--]]
			end


			local m_stomach = MF.ISMoodle:new('exc-stomach',player)
			Excrementum.m_stomach = m_stomach
			m_stomach:setThresholds(-90,-60,-30,-Double.MIN_VALUE,1,2,3,4)

			--m_stomach:setTitle(1,1,getText("Moodles_foodeaten_lvl1"))
			--m_stomach:setDescritpion(1,1,getText("Moodles_foodeaten_lvl1"))
			--m_stomach:setDescritpion(1,2,getText("Moodles_foodeaten_lvl4"))

			MF.ISMoodle:new('exc-stomach-w',player)
			Excrementum.m_stomachW = MF.getMoodle('exc-stomach-w')
			Excrementum.m_stomachW:setThresholds(-90,-60,-30,-Double.MIN_VALUE,1,2,3,4)

			MF.ISMoodle:new('exc-colon',player)
			Excrementum.m_colon = MF.getMoodle('exc-colon')
			Excrementum.m_colon:setThresholds(-90,-60,-30,-Double.MIN_VALUE,1,2,3,4)

			MF.ISMoodle:new('exc-urine',player)
			Excrementum.m_urine = MF.getMoodle('exc-urine')
			Excrementum.m_urine:setThresholds(-4,-3,-2,-1,1,2,3,4)

			MF.ISMoodle:new('exc-smell',player)
			Excrementum.m_smell = MF.getMoodle('exc-smell')
			Excrementum.m_smell:setThresholds(-4,-3,-2,-Double.MIN_VALUE,1,2,3,4)
			Excrementum.m_smell._desc_cache = {}

			MF.ISMoodle:new('exc-shame',player)
			Excrementum.m_shame = MF.getMoodle('exc-shame')
			Excrementum.m_shame:setThresholds(-4,-3,-2,-Double.MIN_VALUE,1,2,nil,nil)

		end


		Excrementum.tm_GameStarted = player:getHoursSurvived() * 60 -- ����� ����� � ���� (25 ��� �����)
		--Excrementum.last_thirst = nil
		if Excrementum.DEBUG then
			exc = player:getModData().exc
			function Excrementum:EnableAllMoodles()
				self.m_stomach:setValue(1)
				self.m_stomachW:setValue(1)
				self.m_colon:setValue(1)
				self.m_urine:setValue(1)
				self.m_smell:setValue(1)
				self.m_shame:setValue(1)
			end
		end
		local exc = Excrementum.exc
		UpdateStomachPain(exc, player)
		Excrementum.now = player:getHoursSurvived() * 60
		if exc.col.td and exc.col.td > 240 then
			Excrementum.ColonPain = GetColonPain(Excrementum.now - exc.col.td)
		end
		Excrementum.OnClothingUpdate() -- topless etc
		UpdateShame(player)
		DoUpdate(player)
	end)

	Events.OnPlayerDeath.Add(function(player)
		if player == Excrementum.p then
			Excrementum.p = nil
			Excrementum.exc = nil
			Excrementum.bd = nil
			Excrementum.stats = nil
		end
		if Excrementum.DEBUG then
			ExcrementumDebugWindow:setVisible(false);
		end
	end)

	local HEA_MODS = {
		SimpleOverhaulTraitsAndOccupations = true,
		MoreSimpleTraits = true,
		--MoreSimpleTraitsMini = true,
		MoreSimpleTraitsVanilla = true,
	}
	Events.OnGameStart.Add(function()
		--Sandbox_ColonT = SandboxVars_Excrementum.ColonBaseThreshold / 100
		--INTESTINE_TIME = SandboxVars_Excrementum.DefecateIntMinutes
		--COLON_TIME = SandboxVars_Excrementum.ColonMinutes

		local player = Excrementum.p

		--if SandboxVars_Excrementum.Shame == 2 then
		local activeModIDs = getActivatedMods() --getActivatedMods():contains('Excrementum41old')
		if activeModIDs then
			for i=0,activeModIDs:size()-1 do
				local modID = activeModIDs:get(i)
				--print("TEST CHECK MOD: ",modID)
				if RETEXTURE_MODS[modID] then --print('retexture')
					IS_RETEXTURE_MOD = true
					--break
				end
				if HEA_MODS[modID] then --print('Hea!')
					is_HeaMods = true
				end
				--if modID == 'realisticinventory' then
				--	is_RealisticInventory = true
				--end
			end
			if SandboxVars_Excrementum.Shame == 2 then
				UpdateShame(player)
			end
		end


		local RI = STAR_MODS.RealisticInventory
		if RI and RI.AddSounds then
			local effect = RI.AddSoundEffect{ name = 'Exc_DropFeces', radius = 12 }
			RI.AddSounds{
				HumanFeces1 = effect,
				HumanFeces2 = effect,
				HumanFeces3 = effect,
				--BathTowelDirty = 1,
				--DishClothDirty = 1,
				PaintTinDefecate = 12, -- bucket sound
				BucketDefecatedFull = 12,
				BucketDefecatedDirty = 12,
				PaintTinDefecatedDirty = 12,
				PaintTinDefecate = 12,
				BucketFullDefecate = 12,
				BucketDefecatedDirty = 12,
				PaintTinDefecatedDirty = 12,
			}
		end




		--print('SANDBOX_PASSIVE_X = ',SandboxVars_Excrementum.UrinatePassiveMultiplier)

		local need_hash = MAX_CHECK_HASH * 2 - 1
		if Excrementum._hash == need_hash then -- check steam workshop issues
			print('Excrementum loaded successfully.')
		else
			print('Excrementum loading error: ' .. tostring(Excrementum._hash) .. " / " .. tostring(need_hash))
		end
		--local player = getSpecificPlayer(0)
		--Excrementum.tm_GameStarted = player and player:getHoursSurvived() * 60 or 0 -- ����� ����� � ���� (25 ��� �����)

		--tempry fix ra's
		Excrementum.TempryFix()

		Excrementum.OnPlayerMove(player)


	end)
end -- Eating injection


------------------ EVERY 1 MINUTES ----------------
-- ������� ��������� �����, ����, ����������� � �����, �� ������.



local FOOD_TIME_LIQUID_SURE = 50 -- ����� ������� ����� ��� ��������� � ����� ���� �� �������� �������
local KNOWN_ZONES = {
	DeepForest = 2,
	Forest = 3,
	FarmLand = 3,
	Farm = 3,
	TownZone = 4,
	Vegitation = 4, Vegetation = 4,
	TrailerPark = 4,
	Nav = 4, -- !!!
}
local need_fartnose = false; -- ����� �� ������ �����

local function CheckFoodEveryMinute() -- every 1 minute
	--print('EXC EVERY 1 min')
	--print_r(p:getMoodles():getMoodleLevel(MoodleType.Zombie))
	local player = getSpecificPlayer(0) if not player then return end
	local now = player:getHoursSurvived() * 60;	Excrementum.now = now
	if now-Excrementum.tm_GameStarted < 1.5 then
		return -- ������ ������ 1.5 ������� ����� � ������� ������� ����.
	end

	local data = player:getModData()
	local exc = data.exc
	local stomach = exc.st
	local chyme = exc.ch
	local is_god = player:isGodMod()

	if is_god then
		exc.urine = 0
		Excrementum.urine = 0

		exc.col.V = 0
		exc.col.visc = 1
		exc.col.og = 0
		exc.col.tf = nil
		exc.col.td = nil
		Excrementum.feces = 0

		table.wipe(stomach)
		chyme.h = 0
		chyme.w = 0
		chyme.P = 0
		chyme.L = 0
		chyme.C = 0
		chyme.v = 0
		chyme.ps = 0
		chyme.d = 0

		--exc.ss = 0
		--exc.sc = 0

		--table.wipe(exc.rel)
	elseif player:isDead() then
		if player:getMoodles():getMoodleLevel(MoodleType.Zombie) > 0 then
			if exc.urine > 0 then
				exc.urine = exc.urine - 0.00021
				if exc.urine < 0 then exc.urine = 0 end
				Excrementum.urine = exc.urine
			end
			if exc.col.V > 0 then
				exc.col.V = exc.col.V - 0.01
				if exc.col.V < 0 then exc.col.V = 0 end
				Excrementum.feces = exc.col.V
			end
			return DoUpdate(player)
		end
		return
	end

	--������� ����� �������
	local V = GetStomachV(stomach)
	--���������, ����� �� �����-�� ��� ������������� � �����
	local i = 1
	local v = stomach[i]
	local need_reset = false
	while v do
		local t = v.tt -- target_tm
		local T = t -- short target time
		if v.w > 0 then
			local tm = GetStomachTime(v, V)
			T = v.tt + tm * ((v.h - v.w ) / v.h - 1)
		end
		if now >= T + FOOD_TIME_LIQUID_SURE then -- ��������� ������, ��� �������
			if now >= t then -- ����������
				AddToChyme(chyme, v, stomach, i);
			else -- �� ����������
				table.insert(chyme, v)
				table.remove(stomach, i)
				ResetRowTime(now, v, V)
			end
			need_reset = true
			i = i - 1
		elseif now >= t then -- ���� ��������� (����������)
			if i == 1 then --queue is free
				AddToChyme(chyme, v, stomach, i);
				need_reset = true
				i = i - 1
			end
		elseif now >= T then -- ���� ���������, �� ����� �� ����������
			if i == 1 then
				table.insert(chyme, v)
				table.remove(stomach, i)
				ResetRowTime(now, v, V)
				need_reset = true
				i = i - 1
			end
		end
		i = i + 1
		v = stomach[i]
	end
	if need_reset then
		ResetStomachTime(now, stomach, V, GetStomachV(stomach))
	end

	-- �������� ������
	V = GetStomachV(chyme)
	for i,v in ipairs(chyme) do
		local t = v.tt
		if now >= t then
			--check if queue is free
			AddToChyme(chyme, v, chyme, i)
			need_reset = true
			break
		end
	end
	if need_reset then
		ResetStomachTime(now, chyme, V, GetStomachV(chyme))
	end


	--�������� �������� � ��
	local w = chyme.w
	if w > 0 then
		local h = chyme.h
		local E_food = h > 0.5 and 0.5 or h -- ��������� �������� 100 �������
		local stomach_absorption = lerp(0.003, 0.0005, E_food * 2) --���������� ���� � �������

		local p = GetOsmoticP(chyme)
		local max_amount = lerp(0.001, 0.005, p) -- ��, ��� ��� � �����; 0.01 = 10 ��

		local sum = max_amount + stomach_absorption


		--print(round(stomach_absorption,3)..' + '..round(max_amount,3)..' = '..round(sum,3))
		if sum > w then
			sum = w
		end
		if sum > 0.010 then
			sum = 0.010
		end

		exc.urine = exc.urine + sum
		chyme.w = chyme.w - sum
		--if Excrementum.StomachPain > 0 then
		--	UpdateStomachPain(exc, player)
		--end
	end

	-- ����������
	if chyme.d > 0 then -- ��������� ���������� ������
		--local delta = math.min(chyme.d, 0.010, sum)
		local delta = math.min(chyme.d, 0.005) -- ��������� �� +5 ��
		chyme.d = chyme.d - delta
		exc.urine = exc.urine + delta
		--if Excrementum.StomachPain > 0 then
		--	UpdateStomachPain(exc, player)
		--end
	end

	UpdateStomachPain(exc, player)


	--passive
	if not is_god then
		exc.urine = exc.urine + 0.00021 * SandboxVars_Excrementum.UrinatePassiveMultiplier
		if Excrementum.is_urine_update then
			Excrementum.urine = exc.urine
		end
	end

	--������� "���������� ����"
	local stats = player:getStats()
	exc.ss = exc.ss + stats:getStress() + stats:getPanic() * 0.01
	exc.sc = exc.sc + 1
	Excrementum.Ms = 0.3 * (1 - exc.ss * 0.5 / exc.sc)

	--���� ���������
	do
		local X = 0.3 + Excrementum.Ms
		local Y = X + 0.15
		local pee = false

		if exc.urine > X then
			Excrementum.UrinePain = 19
		else
			Excrementum.UrinePain = 0 -- just ignore
		end


		if exc.urine >= 0.8 then
			pee = true
		elseif IS_SINGLEPLAYER and exc.urine >= 0.75 and player:isAsleep() then
			pee = nil
			player:forceAwake()
			Excrementum.tm_peeAwaked = now
		elseif now - Excrementum.tm_GameStarted < 30 then
			pee = nil
		elseif now - Excrementum.tm_LastSleep < 30 then
			pee = nil
		elseif exc.urine >= Y then
			pee = ZombRand(10000) < 1100  -- ~ 50% �� 10 ���.
		elseif exc.urine > X then
			local r = (exc.urine - X) * 6.666666667 --/ 0.15,
			pee = ZombRand(10000) < 600 * r -- �� 0 �� 30% �� 10 ���, ��������
		end
		if pee and not IsBusyNow(player) then
			--ISTimedActionQueue.add(InvoluntaryUrinate:new(player, 0, false, false, true, false, nil))
			Excrementum:InvoluntaryUrinate()
		end
	end

	if Excrementum.DEBUG then
		ExcrementumDebugWindow:updateText()
	end

	-- Check relations

	--[[
	local tm_now = os.time()
	for name,usr in pairs(Excrementum.WaitToApplyShame) do --expire awaitings
		for i=1,MAX_SHAMES do
			local v = usr[i]
			if v and tm_now > v.expire then
				usr[i] = nil
			end
		end
	end]]
	UpdateShame(player, true)

	if Excrementum.is_P4LoveAndPerfume and data.P4LoveAndPerfume then
		local remaining = data.P4LoveAndPerfume.remainingTime or 0
		if remaining > 0 and Excrementum.smell > 0 then -- ������������ �������� ���� �������� ���������
			local bd = player:getBodyDamage()
			local unhappy = bd:getUnhappynessLevel()
			bd:setUnhappynessLevel(unhappy + 0.1)
		end
	end

	-- Count zone level
	do
		local zone_now
		local sq = player:getSquare()
		if sq then
			local room = sq:getRoom()
			if room then
				zone_now = 4
			else --Zones
				local zones = getWorld():getMetaGrid():getZonesAt(player:getX(), player:getY(), 0);
				if zones then
					for i=0,zones:size()-1 do
						local zone = zones:get(i)
						local name = zone:getName()
						local typ = zone:getType()
						--print(name,'/',typ,' ',Excrementum.ZoneLevel)
						if KNOWN_ZONES[typ] then
							zone_now = KNOWN_ZONES[typ]
							break
						end
					end
				end
			end
		end
		if not zone_now then
			zone_now = 0
		end
		if Excrementum.ZoneLevel ~= zone_now then
			if zone_now > Excrementum.ZoneLevel then
				Excrementum.ZoneLevel = zone_now
			else
				Excrementum.ZoneLevel = Excrementum.ZoneLevel-0.03125 -- �������� 80 ��� �� ��������� ������ �� ������� �������� ���� (5 ��� �� ��������).
			end
		end
	end

	-- �������� �� ������
	if now - Excrementum.LastAnim_tm > 0.5 then
		local is_free_lefthand = false
		do
			local item2 = player:getSecondaryHandItem()
			if not item2 or item2:getCategory() ~= "Weapon" then
				is_free_lefthand = true
			else
				local item1 = player:getPrimaryHandItem()
				if item1 == item2 then
					is_free_lefthand = true
				end
			end
		end
		if Excrementum.test_emote then
			-- Excrementum.test_emote = "fartpainleftarm" -- ���� ����� �� �����
			-- Excrementum.test_emote = "peedefself"
			-- Excrementum.test_emote = "pinchednose" -- �� ��������
			-- Excrementum.test_emote = "fartnose"
			player:playEmote(Excrementum.test_emote)
			Excrementum.LastAnim_tm = now
		end
		if is_free_lefthand then
			if need_fartnose and Excrementum.room_smell > 0 then
				need_fartnose = false
				player:playEmote("fartnose")
			elseif Excrementum.ColonPain > 0 then -- ����� �� �������� ���� � ������
				--player:playEmote("fartpainleftarm")
			end
		end
	end

	--��������� ������� � ������� � ��� ����� �� ����� ��������
	if player:isPlayerMoving() then
		local boots = player:getClothingItem_Feet()
		local data = boots and boots:hasModData() and boots:getModData()
		local feces = data and data.feces
		if feces then
			if feces > 0 then
				Excrementum.boots_feces_cnt = 32
				data.feces = feces - 0.0078125 -- ~ 1/128 ~ 5 min standard speed
				Excrementum.PutWorldUrine(player, 0.00390625)
			else -- == 0
				if not Excrementum.boots_feces_cnt then
					Excrementum.boots_feces_cnt = 32
				end
				if Excrementum.boots_feces_cnt < 1 then
					data.feces = nil
				else
					Excrementum.boots_feces_cnt = Excrementum.boots_feces_cnt - 1
				end
			end
		end
	end

	--ExcrementumWindow.updateWindow()
	DoUpdate(player)
end
Events.EveryOneMinute.Add(CheckFoodEveryMinute) -- every 1 minute




--------------------- EVERY 10 MINUTES --------------------


local tm_last_growl = 0
local _last_room_calc_tm = 0
local last_sound_typ
local function CheckIntestineEveryTenMinutes() -- every 10 minutes
	--print('EXC EVERY 10 MIN')
	local player = Excrementum.p if not player then return end
	local now = player:getHoursSurvived() * 60;	Excrementum.now = now
	if now-Excrementum.tm_GameStarted < 3 then
		DoUpdate(player)
		return -- ������ ������ 3 ������� ����� � ������� ������� ����.
	end
	local exc = player:getModData().exc
	local intestine = exc.int
	local colon = exc.col
	local stomach = exc.st
	local chyme  = exc.ch

	if player:isAsleep() then
		Excrementum.tm_LastSleep = now -- ���������
	end

	local os_now = os.time()
	if os_now - _last_room_calc_tm > 15 then
		Excrementum.AddTask(7, Excrementum.ResetOnPlayerMove)
	end

	--���������� ���
	exc.swt = SWEAT_SUM

	-- �������� ��� ������, �����
	local is_god = player:isGodMod()
	if is_god then
		QList.reinit(intestine)
		return DoUpdate(player)
		-- �� ���� ��
	end

	--�������� ������� ���������
	local ints = QList.getleft(intestine) -- {time, V, visc, poison? }
	while ints do
		--print('T = ' .. (now - ints[1]) .. ' ; INTESTINE_TIME = ' .. INTESTINE_TIME)
		if now - ints[1] >= SandboxVars_Excrementum.DefecateIntMinutes - 5 then
			QList.popleft(intestine) -- ints
			if colon.V == 0 then
				colon.og = ints[2]
				colon.visc = ints[3]
				--colon.tf = now
			else
				local sum = colon.og + ints[2]
				local total = colon.V + sum
				colon.og = sum
				--colon.V = sum
				--print('Check visc: ',ints[3], colon.visc, ints[2] / sum, sum)
				colon.visc = lerp(colon.visc, ints[3], ints[2] / total)
			end
			--ints = QList.getleft(intestine)
		end
		break -- ������ �� ������ ����� ������ 10 ���
	end

	--�������� �������� ��������� � ��

	-- ��������� �� og � V
	local og = colon.og
	if og > 0 then
		local old_V = colon.V
		if og < 0.007 then
			colon.V = colon.V + og
			colon.og = 0
		else
			local delta = og * 0.3
			colon.V = colon.V + delta
			colon.og = og - delta
		end
		if old_V < 0.1 and colon.V >= 0.1 then -- ������ ����� �������, �������� �����
			colon.tf = now
		end
	end

	-- ����� ���� ��������� ����� ��
	UpdateColonValues(exc)

	-- ����� ������� ������ �������
	if Excrementum.feces > .1 and Excrementum.feces >= Excrementum.feces_threshold then
		if not colon.td then
			colon.td = now
		end
	elseif colon.td then
		colon.td = nil --jj
	end

	-- ����� ����� �������, ��������� ����������
	if colon.td then
		local sound, is_last_sound_changed;
		local delta = now - colon.td
		if delta >= 240 then -- 4 ���� � �����, ���� � ������
			sound = "Exc_Growl3"
			local add_pain = GetColonPain(delta)
			Excrementum.ColonPain = add_pain
		elseif delta >= 120 then
			sound = "Exc_Growl2"
		else
			sound = "Exc_Growl1"
		end
		if OPTIONS.growl_sound ~= 1 then
			if OPTIONS.growl_sound == 2 then
				sound = nil
			elseif OPTIONS.growl_sound == 3 then
				if delta > 15 then
					sound = nil
				end
			elseif OPTIONS.growl_sound == 4 then
				is_last_sound_changed = last_sound_type ~= sound
				if is_last_sound_changed then
					sound = last_sound_type
				end
			end
		end
		if delta >= 120 then -- 2 ���� � �����, �������, ����������
			StressUpTo(lerp(0.251, 0.501, (delta - 120) * 0.004166667), player) -- �������� 4 ����, �� ��������������� �����������
		end
		if delta > 21 and colon.visc < 0.3 then -- �����
			--sound = "Exc_Growl4"
			local plus_delta = colon.visc > 0 and lerp(0, 80, colon.visc) or 0 --print('plus_delta = ',plus_delta)
			if delta > 21 + plus_delta and not IsBusyNow(player) then --print('not busy')
				if now - Excrementum.tm_GameStarted < 30 or now - Excrementum.tm_LastSleep < 30 then
					--print('skip')
				else
					ISTimedActionQueue.add(InvoluntaryDefecate:new(player, 0, false, false, true, false, nil))
					sound = nil
				end
			end
		end
		if sound and (delta < 25 or ZombRand(100) < 10 or is_last_sound_changed) then
			local tm = os.time() -- ��� ����� ������� �������� ����� (�.�. �� ����� ��� ��� ����������)
			local delta = tm - tm_last_growl
			if delta < 60 then -- 3 ���� ������ ������
				delta = nil -- ����� ����, ��� ���� ����� �������������
				-- �����, ��� ��������� ������ �� ����� ���
			end
			if delta ~= nil then
				tm_last_growl = tm
				getSoundManager():PlayWorldSound(sound , player:getCurrentSquare(), 0, 3, 0, false)
			end
		end
	end

	--�������� ���
	if player:getBodyDamage():getPoisonLevel() > 0 then
		chyme.v = chyme.v * 0.9
		for _,v in ipairs(stomach) do
			v.v = v.v * 0.9
		end
	end

	--�������� �������� ������ � ������ ��������
	if chyme[1] == nil then -- ���� ���� ����� ���������
		local V, h, w = GetStomachV(chyme)
		if h > 0 then
			local P = GetOsmoticP(chyme)
			local max_amount = lerp(0.05, 0.15, P) -- 0.01 = 10 ��
			if w > 0 then
				max_amount = max_amount * (h / V) -- ��� ������ ������� ���, ��� ������ ������ ������ ���
			end
			local amount = math.min(h, math.max(0.02, max_amount)) * SandboxVars_Excrementum.ChymeMultiplier * 0.1
			QList.pushright(intestine, {now, amount, chyme.v})
			local leftPerc = (h - amount) / h
			chyme.P = chyme.P * leftPerc
			chyme.L = chyme.L * leftPerc
			chyme.C = chyme.C * leftPerc
			chyme.h = chyme.h - amount
		end
		if Excrementum.StomachPain > 0 then
			UpdateStomachPain(exc, player)
		end
	end


	--�������� ���������. ���� = 100% �� ���� �����. ����� ����� = 100% �� �����. ������� (�2 �� ��������� � �������) = 100% �� 0.5 �����
	local mood = Excrementum.UpdateSmellMoodle(player) + UpdateShame(player)
	if mood > 0 then
		local bd = player:getBodyDamage()
		local unhappy = bd:getUnhappynessLevel()
		if unhappy < 100 then
			--unhappy = unhappy + mood * 0.695
			if not Excrementum._last_ev_tm or Excrementum.now - Excrementum._last_ev_tm > 5 then -- �� ����� �������� � ����� ����� ����� �� �������.
				--local koef = 0.695
				local koef = 0.3
				Excrementum.AddUnhappyness(player, mood * koef, 55, nil, true) -- ��������, ������ � ������� ������� (����� ����� ������������ ��� ������� �� ��������� �������)
			end
		end
	end


	DoUpdate(player)
end
Events.EveryTenMinutes.Add(CheckIntestineEveryTenMinutes) -- every 10 minutes



local function setPainTorsoLower(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Torso_Lower)
	part:setAdditionalPain(pain)
end

local function setPainGroin(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Groin)
	part:setAdditionalPain(pain)
end

local function setPainTorsoUpper(player, pain)
	local part = player:getBodyDamage():getBodyPart(BodyPartType.Torso_Upper)
	part:setAdditionalPain(pain)
end


local _shame_cnt = 0
function Excrementum.ResetShameCounter(new_val)
	_shame_cnt = new_val or 80
end




local showOverlay, screenY, redOverlay = false
local _last_involuntary_tm = 0
local _tick_is_sitting = nil
local _th = 0
Events.OnTick.Add(function()
	local tm_now = os.time()
	--if Excrementum.ColonPain == 0 and Excrementum.UrinePain == 0 and Excrementum.StomachPain == 0 and Excrementum.StomachTotalV == 0 then
	--	return
	--end
	local player = Excrementum.p; if not player then return end

	-- ��������� ���� ��������� � �������� ����� � ����
	do
		local thirst = Excrementum.stats:getThirst()
		local thirstm = player:getThirstMultiplier()
		local delta = thirst - OLD_THIRST
		OLD_THIRST = thirst
		if delta > 0 then
			if thirstm > 1 and delta < 0.0004 then      -- 0.000032 is vanilla maximum with all factors
				SWEAT_SUM = SWEAT_SUM + delta * (1 - 1 / thirstm)
			end
		elseif delta < 0 then -- �������� �����
			local w = -delta
			if SWEAT_SUM > 0 then -- ��������������� ��������� ���������� ��-�� ����(?) �����
				if w > SWEAT_SUM then
					w = w - SWEAT_SUM
					SWEAT_SUM = 0
				else
					SWEAT_SUM = SWEAT_SUM - w
					w = 0
				end
				Excrementum.exc.swt = SWEAT_SUM -- backup
			end
			if w > 0 then
				AddWaterToChyme(Excrementum.exc.ch, w) -- ���� ����� �������� � ������ ����� ������� �� �������.
				DoUpdate(player)
			end
		end
	end

	if Excrementum.ColonPain > 0 then
		setPainTorsoLower(player, Excrementum.ColonPain)
	end
	if Excrementum.UrinePain > 0 then
		setPainGroin(player, Excrementum.UrinePain)
	end
	if Excrementum.StomachPain > 0 then
		setPainTorsoUpper(player, Excrementum.StomachPain)
	end
	local bd = Excrementum.bd
	local hp = bd:getOverallBodyHealth()
	local m = Excrementum.md
	local sick = m:getMoodleLevel(MoodleType.Sick)
	local is_negative = m:getMoodleLevel(MoodleType.Bleeding) >= 1 or m:getMoodleLevel(MoodleType.Hyperthermia) == 4
		or m:getMoodleLevel(MoodleType.Hypothermia) == 4 or m:getMoodleLevel(MoodleType.Thirst) == 4
	local opt = OPTIONS.overlay
	local overlayDisabledByServer = not SandboxVars_Excrementum.OverlayIsAllowed
	if overlayDisabledByServer or opt >= 5 or opt == 4 and sick == 0 then --5,6
		showOverlay = false
	else --1,2,3,4(sick)
		showOverlay = true
		screenY = 95
		if opt ~= 1 then -- 2,3,4 - check stomach moodle
			local st = Excrementum.m_stomach
			if st then
				if st:getValue() == 0 then
					st = Excrementum.m_stomachW
					if st:getValue() == 0 then
						st = nil
					end
				end
			end
			if st then
				screenY = st.y + 5
			end
			if showOverlay then
				if opt == 3 and not st then
					showOverlay = false
				elseif hp>95 then -- opt ~= 1
					showOverlay = false
				elseif MainScreen.instance and MainScreen.instance:isReallyVisible() then
					showOverlay = false
				end
			end
		end
	end
	local basic = 0.00084

	if Excrementum.green_stomach > 0 then -- green stomach moodle
		local added = 0.012 -- vanilla value (more or less)
		redOverlay = false
		if sick == 4 or hp < 10 then -- Fever at high speed, ignoring other Sick status
			-- max recovery to compensate
		elseif hp == 100 then
			added = 0
		elseif is_negative then
			-- Dying of Thirst, Hypothermic, Hyperthermic and especially Bleeding
			added = 0
			redOverlay = true
		else
			added = lerp(added, added*0.1, (hp - 10) * 0.01) -- 100%..19% from base
			if hp > 50 and m:getMoodleLevel(MoodleType.HeavyLoad) >= 2 then -- Heavy Load limit is 75%
				if hp > 75 then
					added = 0
				else
					added = added * 0.5
				end
			end
			if Excrementum.green_stomach <= 2 then
				added = added * 0.5
			end
		end
		if added ~= 0 then
			bd:AddGeneralHealth(added)
		elseif sick then
			redOverlay = true
		end
		--overlay stuff
		Excrementum._g_added = hp==100 and 0 or basic + added
	else
		Excrementum._g_added = hp==100 and 0 or basic
		if showOverlay then
			redOverlay = is_negative or sick
		end
	end
	--g_showOverlay = showOverlay
	--g_screenY = screenY

	-- ������ �� ������
	if Excrementum.stats:getNumChasingZombies() > 14 and ZombRand(300) == 1 -- chance
		and os.time()-_last_involuntary_tm > 10 and m:getMoodleLevel(MoodleType.Panic) == 4
	then
		-- ���������, ������� �� ������� ���� �� 3
		local z = CELL:getNearestVisibleZombie(0)
		if z and player:DistTo(z) < 2.84 then
			local num_attack = player:getSurroundingAttackingZombies()
			if num_attack >= 2 then
				local num_near = GetZombiesCountSq(player:getCurrentSquare())
				if num_near >= 8 then
					if Excrementum.feces >= 0.3 then
						Excrementum:InvoluntaryDefecate()
						_last_involuntary_tm = os.time()
					elseif Excrementum.urine >= 0.15 then
						Excrementum:InvoluntaryUrinate()
						_last_involuntary_tm = os.time()
					end
				end
			end
		end
	end
	--DEBUG_STR = tostring(player:getSurroundingAttackingZombies()) .. ' / ' .. tostring(Excrementum.stats:getNumChasingZombies())

	--��������� ������� ��������, ���� ����� ��� �����������
	--[[for name,data in pairs(SHAME_TASKS) do
		if tm_now > data.finish then
			SHAME_TASKS[name] = nil
			break -- ������� ��������. ��� �������� �� ����������� �� �����.
		end
		local p = data.player
		if p:getCurrentSquare() and player:CanSee(p) then -- ���������
			-- getForwardDirection - ������� ����������� ��� ����� �������� (�.�. ������������).
			if data.is_prepare then
				sendClientCommand(player, 'Exc', 'seen1', {data.ID})
			end
		end
	end]]

	--Process possible shame
	if _shame_cnt >= 40 then
		local act_name = _shame_cnt > 90 and (
			_shame_cnt == 91 and 'InvoluntaryUrinate' or
			(_shame_cnt == 92 and 'InvoluntaryDefecate' or 0)
		) or GetActionName(player);
		_shame_cnt = 0
		local opt_shame = SandboxVars_Excrementum.Shame
		--print('-----------shame process----------- ',act_name,' ',opt_shame)
		if ShameIsEnabled(player) then
			local is_naked = Excrementum.is_groinless > 0 or Excrementum.is_topless and player:isFemale()
			local ignore_gender = (act_name == 'InvoluntaryDefecate')
			local is_process = ignore_gender or act_name == 'InvoluntaryUrinate'
			if is_naked or is_process then
				--print('naked = ',is_naked,' is_process = ',is_process)
				getNearestVisiblePlayers(player)
				SendShameMomentToNearest(player, is_process and 2 or 4, ignore_gender)
				if is_process and not player:isInvisible() then
					local z = CELL:getNearestVisibleZombie(0)
					if z and z:DistTo(player) < 10 and z:CanSee(player) then
						ApplyShame(0, 5) -- name=0, typ=5
					end
				end
			end
		end
	end
	_shame_cnt = _shame_cnt + 1

	--Check sit status change
	local is_sitting = player:isSitOnGround()
	if _tick_is_sitting ~= is_sitting then
		_tick_is_sitting = is_sitting
		Excrementum.OnClothingUpdate()
	end

	if Excrementum.tm_transfer and not Excrementum.is_transfer_lock and tm_now - Excrementum.tm_transfer > 0.5 then
		Excrementum.UpdateSmellMoodle(player)
	end

	UpdateTasks()
end)


do -------------------- OVERLAY ------------------
	local TM = getTextManager();
	--screenX, screenY, screenXT, screenYT

	local core = getCore()

	local function ShowRegen()
		if not showOverlay then
			return
		end
		local screenX = core:getScreenWidth() - 58
		local s = nil;
		local mx = getMouseX()
		if mx > screenX - 150 then -- � ������� ����.
			local my = getMouseY()
			if my < screenY+80 and my > screenY-60  then -- � ���� ���������
				s = true
				if mx > screenX + 2 -- � ���� ������ � ���� ��������
					and my < screenY+35 and my > screenY-15  -- ����� �� ������ �������
				then
					return -- ��������� �� ��������� ����, ���������� ������ �������
				end
			end
		end
		local num = Excrementum._g_added or 0
		num = math.floor((num / 0.01284) * 1000) / 10

		if s then -- �������� ����
			s = "Regen: " .. num .. "%"
		else
			s = tostring(num) .. "%"
		end

		local r,g,b = 0.1, 0.8, 0.4
		if redOverlay or num < 0 then r,g,b = 1, 0.5, 0 -- impossible
		elseif num == 0 then r,g,b = 0.4, 0.4, 0.4
		end


		TM:DrawStringRight(UIFont.Large, screenX, screenY, s, r, g, b, 0.5); --font, x, y, str, r, g, b, a
		--textManager:DrawString(UIFont.Large, screenX, screenY + 20, cache_zone, 0.1, 0.8, 1, 1);
		--print_r(MF.Moodles['exc-stomach'].disable) .y
	end


	--onStart
	Events.OnGameStart.Add(function()
		--screenX, screenY = getCore():getScreenWidth() - 190, 95
		--screenXT, screenYT = :getScreenWidth() - 56, 133
		Events.OnPostUIDraw.Add(ShowRegen);

		---Love and Perfume compatibility
		if P4UsePerfumeAction then
			Excrementum.is_P4LoveAndPerfume = true

		end

		--Excrementum.GameTime = getGameTime()


	end)

	function _GAdded(x,y)
		screenX,screenY = getCore():getScreenWidth()-x,y
	end
end


--------------------------- REAL ACTIONS ----------------------------
-- ���� ����������� ������� ����� "��" � "�����".

function Excrementum.DoDefecate(player)
	local exc = player:getModData().exc
	local colon = exc.col
	Excrementum.ColonPain = 0
	if ZombRand(100) < 30 and colon.V > 0.1 then -- ������ ������� ������� ���� (1-10% �����)
		colon.V = ZombRand(99) * 0.001
	else
		colon.V = 0
		colon.visc = 1
	end
	colon.tf = nil
	colon.td = nil
	Excrementum.feces = colon.V
	setPainTorsoLower(player, 0)
	for _,fn in pairs(Excrementum.defecate_fns) do
		fn()
	end
	--DoUpdate(player)
	Excrementum.DoUrinate(player)
end

function Excrementum.DoUrinate(player) --print('DoUrinate()')
	local exc = player:getModData().exc
	exc.urine = 0
	exc.ss = 0
	exc.sc = 0
	exc.uTm = Excrementum.now
	Excrementum.Ms = 300
	Excrementum.urine = 0
	--setPainGroin(player, 0) -- ���� �������� ���� ����������
	for _,fn in pairs(Excrementum.urinate_fns) do
		fn()
	end
	DoUpdate(player)
end

local _veh_urine = {urine=true}
function Excrementum.DoUrinateVehicle(player)
	sendClientCommand(player, 'Exc', 'Vehicle', _veh_urine)
end

local _veh_feces = {feces=1}
function Excrementum.DoDefecateVehicle(player)
	sendClientCommand(player, 'Exc', 'Vehicle', _veh_feces)
end


-- ����������� �������, ������� ���������� �����
function Excrementum.OnDefecate(fn)
	table.insert(Excrementum.defecate_fns, fn)
end
function Excrementum.OnUrinate(fn)
	table.insert(Excrementum.urinate_fns, fn)
end
Excrementum.OnUpdate = {
	Add = function(fn)
		Excrementum.update_fns[fn] = true
	end,
	Remove = function(fn)
		if Excrementum.update_fns[fn] then
			Excrementum.update_fns[fn] = nil
		end
	end,
}

function Excrementum.GetRandomFeces()
	local r = ZombRand(3)
	return InventoryItemFactory.CreateItem(
		r == 0 and "Defecation.HumanFeces1"
		or (r == 1 and "Defecation.HumanFeces2" or "Defecation.HumanFeces3")
	);
end

function Excrementum.PutWorldUrine(player, val)
	if player:isSeatedInVehicle() then
		return
	end
	local sq = player:getCurrentSquare()
	if not sq then
		return
	end
	local room = sq:getRoom()
	if room then
		val = val or 0.25
		local list = room:getSquares()
		if list and list:size() > 0 then
			local sq0 = list:get(0)
			sendClientCommand(player, 'Exc', 'WorldUrine', {sq0:getX(), sq0:getY(), sq0:getZ(), val})
			Excrementum.AddTask(30, function()
				Excrementum.ResetOnPlayerMove()
				--Excrementum.OnPlayerMove(player)
			end)
		end
	end
end


function Excrementum.PutWorldFeces(player)
	if player:isSeatedInVehicle() then
		return Excrementum.DoDefecateVehicle(player)
	end

	local fecesItem = Excrementum.GetRandomFeces()
	--local defecationmodel = DefTable(math.random(#DefTable)}
	if fecesItem then
		player:getCurrentSquare():AddWorldInventoryItem(fecesItem, ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0)
		--Excrementum.PutWorldUrine(player, 0.5)
	end
end


local function countVehicleFeces(vehicle)
	local cnt = 0
	while vehicle:isSeatInstalled(cnt) do
		cnt = cnt + 1
	end
	return cnt
end

--������ ���� � ������� ������� ������� ������
local _upd_smell = 0 -- ��� ��� ������ �� ����� (������ + ����)
local _upd_smell_desc = nil -- ��� ��� ���������
local _old_smell_desc = nil
function Excrementum.UpdateSmellMoodle(player, upd_type)
	--if player:isAsleep() then
	--	Excrementum.smell = 0
	--	Excrementum.m_smell:setValue(0)
	--	return 0
	--end
	local smell
	local _desc = {}
	if upd_type == -1 then -- ���������� ����������, ������ ����� �������, ��� ���������� ������
		smell = _upd_smell
		table.insert(_desc, _upd_smell_desc)
	else
		Excrementum.tm_transfer = nil

		--������� ��������� �� ������ ������
		local cloth_defecated, cloth_urinated = 0,0
		local inv = player:getInventory()
		local list = inv:getAllCategory('Clothing')
		for i=0,list:size()-1 do
			local item = list:get(i)
			if item:hasModData() then
				local data = item:getModData()
				if data.feces or data.urine then
					table.insert(_desc, item:getDisplayName())
					if data.feces then
						cloth_defecated = cloth_defecated + 1 + data.feces
					elseif data.urine then
						cloth_urinated = cloth_urinated + 0.5
					end
				end
			end
		end
		local wiping = 0
		inv:getCountTagEval('DryWiping', function(item)
			local data = item:getModData()
			if data.feces or data.urine then
				table.insert(_desc, item:getDisplayName())
				if data.feces then
					wiping = wiping + 1 + data.feces
				elseif data.urine then
					wiping = wiping + 0.5
				end
			end
			return false
		end)
		local count_feces = inv:getCountTag('Feces')
		if count_feces > 0 then
			table.insert(_desc, getText("UI_Exc_HumanFeces"))
		end
		cloth_defecated = cloth_defecated * 0.5
			+ count_feces
			+ wiping * 0.5

		--������� ���� �� ����
		--local v_smell = 0
		local v = player:getVehicle()
		if v then
			local is_bad_seats = false
			local w_open = v:windowsOpen()
			--isSeatInstalled(0),
			for i=0,v:getPartCount()-1 do
				local part = v:getPartByIndex(i)
				if part:getCategory() == "seat" then
					local item = part:getInventoryItem()
					if item and item:hasModData() then
						local data = item:getModData()
						if data.feces or data.urine then
							is_bad_seats = true
							if data.feces then
								cloth_defecated = cloth_defecated + 2
							elseif data.urine then
								cloth_urinated = cloth_urinated + 1
							end
						end
					end
				end
			end
		end
		if is_bad_seats then
			table.insert(_desc, getText("UI_Exc_Seats"))
		end

		local body_smell = (player:getModData().exc.ass or 0)
		if body_smell > 0 then
			table.insert(_desc, getText("UI_Exc_YourBody"))
		end

		smell = (cloth_defecated + cloth_urinated) * 0.5
			+ math.min(2, body_smell * 0.25)
		_upd_smell = smell
		_upd_smell_desc = #_desc > 0 and table.concat(_desc, "\n") or nil
		--table.wipe(_desc)
		--table.insert(_desc, _upd_smell_desc)
	end


	-- ��������� ������ ����
	if (Excrementum.room_smell ~= 0) then
		smell = smell + Excrementum.room_smell
		table.insert(_desc, getText("UI_Exc_Room"))
	end
	smell = math.min(4, smell) -- �� ������� �� ����� ���������
	Excrementum.smell = smell
	local m_smell = Excrementum.m_smell
	if smell > 0 and OPTIONS.smell_moodle then
		--local moodle_val = math.max(math.floor(-smell),-4) -- (-0.1 =>> -1)
		m_smell:setValue(-smell)
	else
		m_smell:setValue(0)
	end

	local lvl = m_smell:getLevel()
	if lvl > 0 then
		_desc = table.concat(_desc, "\n")
		if _desc ~= m_smell._desc_cache[lvl] then
			m_smell._desc_cache[lvl] = _desc;
			m_smell:setDescritpion(2, lvl, getText("Moodles_exc-smell_Bad_desc_lvl" .. lvl) .. "\n" .. _desc)
		end
	end


	return smell
end
Events.OnEnterVehicle.Add(function(player)
	if player and player ~= Excrementum.p then
		return
	end
	Excrementum.UpdateSmellMoodle(player)
end)
Events.OnExitVehicle.Add(function(player)
	if player and player ~= Excrementum.p then
		return
	end
	Excrementum.UpdateSmellMoodle(player)
end)


local mh_txt = nil
local ras_hidden = nil
function Excrementum.OnClothingUpdate()
	local player = Excrementum.p
	if player == nil then
		return
	end
	local list = player:getWornItems()
	if not list then
		return
	end
	local is_male = not player:isFemale()
	local is_topless, is_groinless = not is_male, 4 -- ������� ����������
	local ShownGroin = Excrementum.IsShownGroin
	local ShownBreast = Excrementum.IsShownBreast
	local show_all = OPTIONS.clothes_blue_parts; --Excrementum.MiniHealthOption.value
	local limbs = Excrementum.mh_limbs
	table.wipe(Excrementum.mh_limbs)
	for i=0,list:size()-1 do
		local item = list:get(i):getItem()
		if instanceof(item, "Clothing") and item:isEquipped() then
			local loc = item:getBodyLocation()
			local typ = item:getType()
			if is_groinless ~= 0 then
				local shown = ShownGroin(item, typ, loc)
				if shown < is_groinless then
					is_groinless = shown
				end
			end
			if is_topless ~= false then
				is_topless = ShownBreast(item, typ, loc)
			end
			if show_all then
				if loc == 'UnderwearBottom' then
					limbs[10] = true
				elseif loc == 'UnderwearTop' then
					limbs[6] = true
				elseif loc == 'Underwear' then
					limbs[10] = true
					limbs[6] = true
				end
				local parts = item:getCoveredParts()
				if parts then
					for i=0,parts:size()-1 do
						local idx = parts:get(i):index()
						limbs[idx] = true
					end
				end
			end
			if is_groinless == 0 and (is_topless == false or is_male) and not show_all then
				break
			end
		end
	end
	Excrementum.is_topless = is_topless
	Excrementum.is_groinless1 = is_groinless
	Excrementum.is_groinless = is_groinless


	if Excrementum.DEBUG and ras_hidden and is_groinless > 0 then
		if ras_hidden(player, "Default") then
			if ras_hidden(player, "Sitting") then
				--is_groinless = 0
				Excrementum.is_groinless1 = -2 -- red
			else
				--is_groinless = 1
				if is_groinless >= 3 then
					Excrementum.is_groinless1 = -3 -- red
				end
			end
		end
	end

	if is_groinless == 1 or is_groinless == 2 then -- ������� �����
		local is_sitting = player:isSitOnGround()
		if is_sitting then
			Excrementum.is_groinless1 = 4
		end
	end
	if Excrementum.DEBUG then
		if Excrementum.is_groinless1 >= 0 then
			for k in pairs(Excrementum.GROIN_SHOW_EXTRA) do
				if player:getWornItem(k) then
					Excrementum.is_groinless1 = -1 -- yellow
					break
				end
			end
		end
		print('OnClothingUpdated: topless='..tostring(is_topless)..', groinless='..tostring(is_groinless))
		if mh_txt then
			local txt = tostring(is_groinless)
			if is_groinless >= 3 then
				--txt = '<RGB:1,0,0>' .. txt
			end
			if mh_txt.text ~= txt then
				mh_txt:setText(txt)
				mh_txt:paginate()
			end
		end
	end
end
if OPTIONS.clothes_blue_parts ~= nil then -- debug mode, mod options on
	local mh_opt = SETTINGS:getData("clothes_blue_parts")
	mh_opt.OnApplyInGame = Excrementum.OnClothingUpdate
end


Events.OnClothingUpdated.Add(function(player)
	if player ~= Excrementum.p then
		return
	end
	Excrementum.UpdateSmellMoodle(player)
	Excrementum.OnClothingUpdate()
end)




------------ ���������� � ����� Mini Health Panel -----------------
Events.OnPreMapLoad.Add(function()


	if RasBodyModManageClothingIG and RasBodyModManageClothingIG.WearsExceptionalClothingIG then
		ras_hidden = RasBodyModManageClothingIG.WearsExceptionalClothingIG
		local R = RasExceptionalClothingDefault
		if R then
			R["AuthenticZLite.PonchoBlack"] = true
			R["AuthenticZLite.PonchoBlackDOWN"] = true
			R["AuthenticZLite.PonchoCamoDesert"] = true
			R["AuthenticZLite.PonchoCamoDesertDOWN"] = true
			R["AuthenticZLite.PonchoCamoForest"] = true
			R["AuthenticZLite.PonchoCamoForestDOWN"] = true
			R["AuthenticZLite.PonchoCamoForest2"] = true
			R["AuthenticZLite.PonchoCamoForest2DOWN"] = true
			R["AuthenticZLite.PonchoUrbanForest"] = true
			R["AuthenticZLite.PonchoUrbanForestDOWN"] = true
			R["AuthenticZLite.PonchoOliveDrab"] = true
			R["AuthenticZLite.PonchoOliveDrabDOWN"] = true
			R["AuthenticZLite.PonchoOrangePunch"] = true
			R["AuthenticZLite.PonchoOrangePunchDOWN"] = true
			R["AuthenticZLite.PonchoWhiteTINT"] = true
			R["AuthenticZLite.PonchoWhiteTINTDOWN"] = true
			R["AuthenticZLite.Jacket_Bateman"] = true
			R["AuthenticZLite.Jacket_Trenchcoat"] = true
			R["AuthenticZLite.Jacket_StraightJacket"] = true

		end
	end

	-- inject into mini health panel
	--mhpHandle.limbs[1].color=col_lightblue
	--mhpHandle:update()
	--print(mhpHandle.limbs[7]._prop)
	if not (ISMiniHealth and ISMiniHealth.setPlayerIsDead) then
		return
	end
	--local mh_opt = Excrementum.MiniHealthOption

	local rewrite = {color=Color.new(0.4,1,1,1), alpha=0.7} -- light blue
	local rewrite2 = {color=Color.new(0.5,0.5,1,1), alpha=0.5} -- dark blue
	local rewrite3 = {color=Color.new(0.15,0.7,1,1), alpha=0.5} -- blue
	local rewrite4 = {color=Color.new(1,1,0,1), alpha=0.9} -- yellow
	local rewrite5 = {color=Color.new(1,0,0,1), alpha=0.6} -- red
	local m = {
		__newindex = function(t,k,v) -- ������� ���� ������������� ��������
			if rewrite[k] ~= nil then
				t._save[k] = v
			else
				rawset(t,k,v)
			end
	 end,
		__index = function(t,k) -- ������� ������� �� ������ ��� � ������
			if OPTIONS.clothes_blue_parts then
				if t._save.alpha ~= 0 then -- �� ���������
					return t._save[k]
				end
				-- ���� alpha == 0, �� ���������� ������, ���� ����
				if t._prop ~= 0 then
					local val = Excrementum[t._prop]
					if val then
						if val == true or val >= 3 then
							return rewrite[k] -- light blue
						elseif val >= 1 then
							return rewrite3[k] -- blue
						elseif val == -1 then
							return rewrite4[k] -- yellow
						elseif val < -1 then
							return rewrite5[k] -- red
						end
					end
				end
				if t._idx ~= nil and Excrementum.mh_limbs[t._idx] then
					return rewrite2[k]
				end --print(bodyParts :get(0)) print_r(bodyParts:get(10):getType():name()) print_r(g('tro'):getCoveredParts():get(0):name())
			end
			return t._save[k]
		end,
	}

	local old_initialize = ISMiniHealth.initialize
	function ISMiniHealth:initialize(...)
		old_initialize(self,...)
		if self.mhpBodyParts and not self.limbs then
			self.limbs = self.mhpBodyParts
		end
		if self.limbs then
			local function Save(obj, prop, idx)
				obj._prop = prop
				obj._idx = idx
				obj._save = {}
				for k,v in pairs(rewrite) do
					obj._save[k] = obj[k]
					obj[k] = nil
				end
				setmetatable(obj, m)
			end
			for i,v in ipairs(self.limbs) do
				if i == 7 then
					Save(self.limbs[7], 'is_topless', i-1)
				elseif i == 11 then
					Save(self.limbs[11], 'is_groinless1', i-1)
				else
					Save(self.limbs[i], 0, i-1)
				end
			end
			ISMiniHealth.__inst = self
		end
	end

	--��������� �����
	if Excrementum.DEBUG then
		local old_children = ISMiniHealth.createChildren
		function ISMiniHealth:createChildren()
			old_children(self)
			--print(ISMiniHealth.__inst.exc_txt:setHight(125))
			mh_txt = ISRichTextPanel:new(56, 147, 20, 8)
			mh_txt:initialise()
			mh_txt:noBackground()
			mh_txt.marginLeft = 0
			mh_txt.marginRight = 0
			mh_txt.marginTop = 0
			mh_txt:instantiate()
			self:addChild(mh_txt)
			self.exc_txt = mh_txt
		end
	end
end)



--��������� �����.
--������ ��������� ��������, �� ��������� ������� ������ ������.
function Excrementum.AddBoredom(player, delta, t_min, t_max)
	local bd = player:getBodyDamage()
	local b = bd:getBoredomLevel()
	if delta > 0 then
		t_max = t_max or 100
		if b < t_max then
			b = b + delta
			if b > t_max then
				delta = delta + (t_max - b)
				b = t_max
			end
		else
			delta = 0
		end
	else -- delta <= 0
		t_min = t_min or 0
		if b > t_min then
			b = b + delta
			if b < t_min then
				delta = delta + (t_min - b)
				b = t_min
			end
		else
			delta = 0
		end
	end
	if delta ~= 0 then
		bd:setBoredomLevel(b)
		delta = math.floor(delta + 0.5)
		if delta < 0 then
			player:setHaloNote(getText("UI_Exc_BoredomChange", delta), 200)
		elseif delta > 0 then
			player:setHaloNote(getText("UI_Exc_BoredomChangeP", delta), 255,255,255, 200)
		end
	end
end
function Excrementum.AddUnhappyness(player, delta, t_min, t_max, is_silent)
	local bd = player:getBodyDamage()
	local old_b = bd:getUnhappynessLevel()
	local b = old_b
	if delta > 0 then
		t_max = t_max or 100
		if b < t_max then
			b = b + delta
			if b > t_max then
				delta = delta + (t_max - b)
				b = t_max
			end
		else
			delta = 0
		end
	else -- delta <= 0
		t_min = t_min or 0
		if b > t_min then
			b = b + delta
			if b < t_min then
				delta = delta + (t_min - b)
				b = t_min
			end
		else
			delta = 0
		end
	end
	if delta ~= 0 then
		bd:setUnhappynessLevel(b) --print('Unhappyness changed: ',delta,' ',b)
		if not is_silent then
			if delta >= 1 then
				delta = math.floor(delta + 0.5)
			else
				delta = math.floor(b) - math.floor(old_b) -- ����� ����� ���������
			end
			if delta < 0 then
				player:setHaloNote(getText("UI_Exc_UnhappynessChange", delta), 200)
			elseif delta > 0 then
				player:setHaloNote(getText("UI_Exc_UnhappynessChangeP", delta), 255,255,255, 200)
			end
		end
	end
	return b
end
function Excrementum.AddFatigue(player, delta, t_min, t_max)
	local stats = player:getStats()
	local b = stats:getFatigue()
	if delta > 0 then
		t_max = t_max or 1
		if b < t_max then
			b = b + delta
			if b > t_max then
				delta = delta + (t_max - b)
				b = t_max
			end
		else
			delta = 0
		end
	else -- delta <= 0
		t_min = t_min or 0
		if b > t_min then
			b = b + delta
			if b < t_min then
				delta = delta + (t_min - b)
				b = t_min
			end
		else
			delta = 0
		end
	end
	if delta ~= 0 then
		stats:setFatigue(b)
		delta = math.floor(delta * 100 + 0.5)
		if delta < 0 then
			player:setHaloNote(getText("UI_Exc_FatigueChange", delta), 200)
		elseif delta > 0 then
			player:setHaloNote(getText("UI_Exc_FatigueChangeP", delta), 255,255,255, 200)
		end
	end
	return delta
end


function Excrementum.AddToiletDirt(player, toilet)
	Excrementum.SendClientCommand('AddExc', toilet, toilet:getTextureName(), player)
end

function Excrementum.UseToiletWater(player, toilet, units, is_cleaning)
	if toilet:getWaterAmount() < units then
		-- try add dirt
		--local data = toilet:getModData()
		--if data.exc_dirt and data.exc_dirt >= Excrementum.MAX_DIRT_TOILET then
		--	return false -- fail
		--end
		--data.exc_dirt = data.exc_dirt + 10
		return false
	end
	Excrementum.SendClientCommand('TakeWater', toilet, units, player, is_cleaning)
	if OPTIONS.flush_sound then
		getSoundManager():PlayWorldSound("Exc_Flush1", player:getCurrentSquare(), 0, 15, 0, false)
	end
	addSound(player, player:getX(), player:getY(), player:getZ(), 15 , 10)
	return true
end

local IS_GLASSES = {
	Glasses_Normal = true,
	Glasses_Reading = true,
	Glasses_ReadingBlack = true,
	CBX_OHI_2 = true,
	CBX_OHI_3 = true,
	CBX_OHI_4 = true,
	CBX_OHI_5 = true,
	CBX_OHI_7 = true,
	CBX_OHI_8 = true,
	CBX_Glasses_2 = true,
	CBX_Glasses_3 = true,
}
local function HasGlasses(player)
	local item = player:getWornItem("Eyes")
	if item and IS_GLASSES[item:getType()] then
		return true
	end
	return false
end
--Excrementum.HasGlasses = HasGlasses

local _step_sq = {}
local _last_step_in = 0
local _step_check = false -- ��������������� � true, ���� ���� "��������" ��� ����� � ����.
local step_X, step_Y
local function CheckStepInShit(player,x1,y1)
	local is_sneak = player:isAiming() or player:isSneaking()
	if is_sneak then
		return
	end
	local is_run = player:IsRunning() or player:isSprinting()
	local radius = is_run and 0.5 or 0.3
	for i=1,#_step_sq,3 do
		local w_item = _step_sq[i]
		if w_item:getWorldObjectIndex() ~= -1 then -- still exists
			local x2,y2 = _step_sq[i+1], _step_sq[i+2]
			--print('dist = ',math.max(math.abs(x1-x2),math.abs(y1-y2)),' / ',radius)
			if math.abs(x1-x2) < radius and math.abs(y1-y2) < radius then -- ����� � ������

				_last_step_in = os.time()
				_step_check = false
				step_X = math.floor(x1) --x0
				step_Y = math.floor(y1) --y0
				local sq = player:getCurrentSquare()
				getSoundManager():PlayWorldSound('Exc_StepShit' , sq, 0, 15, 0, false)
				addSound(player, x1, y1, player:getZ(), 12, 10)
				local boots = player:getWornItem("Shoes") or player:getWornItem("Socks")
				if not boots then -- ������������ ������
				end
				if boots then
					local data = boots:getModData()
					if (not data.feces or data.feces < 3) then
						data.feces = (data.feces or 0) + 1
						--feces = feces - 1
						Excrementum.AddDirtyness(boots, 0.8) -- ��� ������� ������� �������, ��� ���� �����
						--sendClientCommand(player, 'Exc', 'RemoveFeces', {x0,y0,z1})
						sq:transmitRemoveItemFromSquare(w_item);
						w_item:removeFromWorld()
						w_item:removeFromSquare()
						w_item:setSquare(nil)
						Excrementum.room_smell = Excrementum.room_smell - 1
						Excrementum.UpdateSmellMoodle(player) -- �������� ������
						return true
					end
				else
					-- ��������� ����� �� ����
					--local vis = player:getVisual()
					--vis:setDirt(BloodBodyPartType.Foot_L, 1) -- max
					--vis:setDirt(BloodBodyPartType.Foot_R, 1)
					--player:resetModel()
					player:addDirt(BloodBodyPartType.Foot_L, 50, false)
					player:addDirt(BloodBodyPartType.Foot_R, 50, false)
					return false -- �� ������� ���� �����
				end

			end
		end
	end
end



--������� ��������� ��� ������.
--������ ��� ��������, ��������� ��������� ��������� � �� ����� �������� �� �������.
--����� ������ ������, �� � �������� "����".
local function SearchRoomCorner(room, sq)
	local dx,dy=0,0
	local s1,dist1,s = sq,0
	while true do
		if dx==dy then
			s = s1:getE()
			if not s then
				break
			end
			dx = dx + 1
		else
			s = s1:getN()
			if s then
				dy = dy + 1
			else
				s = s1:getE()
				if not s then
					break
				end
				dx = dx + 1
			end
		end
		if s:getRoom() ~= room then
			return
		end
		s1 = s
		dist1 = dist1 + 1
	end
	local s2,dist2 = sq,0
	dx,dy=0,0
	while true do
		if dx==dy then
			s = s2:getN()
			if not s then
				break
			end
			dy = dy + 1
		else
			s = s2:getE()
			if s then
				dx = dx + 1
			else
				s = s2:getN()
				if not s then
					break
				end
				dy = dy + 1
			end
		end
		if s:getRoom() ~= room then
			return
		end
		s2 = s
		dist2 = dist2 + 1
	end
	return (dist1 > dist2) and s1 or s2
end



local old_X, old_Y
function Excrementum.OnPlayerMove(player)
	if player and player ~= Excrementum.p then -- �� ��� �����
		return
	end
	if player:getVehicle() then -- � ������ ������ ���������
		return
	end
	local x1,y1 = player:getX(), player:getY()
	local x0,y0 = math.floor(x1), math.floor(y1)
	if x0 == old_X and y0 == old_Y then -- �� ���� ����� �����
		if _step_check then
			CheckStepInShit(player,x1,y1)
		end
		return
	end
	local z1 = player:getZ()
	if math.floor(z1) ~= math.ceil(z1) then -- ����� �������
		return
	end
	--print("New Coords: ",x0,' ',y0)
	old_X = x0
	old_Y = y0
	table.wipe(_step_sq)
	_step_check = false
	local sq = player:getCurrentSquare()
	if not sq then -- �� �� ��� ������, ������ �� ����� ����, �� �� ��
		return
	end
	Excrementum.room_smell_days = nil
	local old_smell = Excrementum.room_smell
	local feces = 0
	-- check room
	local room = sq:getRoom()
	if room then
		if _last_room ~= room then
			need_fartnose = true
		end
		local all = room:getSquares()
		local size = all:size()
		local sq0 = size > 0 and all:get(0)
		if sq0 and sq0:hasModData() then -- ������� (������) ���� �������. � ���� � ��������� ��� ������ � �������, � �������, ��� �� �� ���������.
			local data = sq0:getModData()
			if data then
				local ur = data.ex_sml or 0
				if ur > 0 then
					local now = Excrementum.GameTime:getMinutesStamp()
					local tm = data.ex_tm or now
					local d = (now - tm) * 0.0006944444 --0.0022916666666667
					Excrementum.room_smell_days = d
					feces = 18/(size+6) - 1.5 + d*0.33 + ur
					if feces < 0 then
						feces = 0 -- "�������������" ����� �� ����� ���� ��������.
					end
				end
			end
		end
	else
		need_fartnose = false
	end
	_last_room = room
	-- check feces directly
	-- 0.2 if walking, 0.4 if running
	-- ������� ����. ���� �� ��������, �� ����� �����
	_last_room_calc_tm = os.time()
	local delta_tm = _last_room_calc_tm - _last_step_in
	if delta_tm > 60 then -- 60 ������ ��������� � ����� �� �����
		local rnd = ZombRand(100)
		--local MAX_CHANCE = 68
		if rnd < 68 then
			local tired = Excrementum.md:getMoodleLevel(MoodleType.Tired)
			local chance = tired * 5
			local drunk = Excrementum.md:getMoodleLevel(MoodleType.Drunk)
			if drunk >= 3 then
				chance = chance + 15
			end
			if rnd < 33 + chance then
				if player:HasTrait("Clumsy") then
					chance = chance + 10
				elseif player:HasTrait("Graceful") then
					chance = chance - 10
				end
				if player:HasTrait("Unlucky") then
					chance = chance + 5
				elseif player:HasTrait("Lucky") then
					chance = chance - 5
				end
				if player:HasTrait("ShortSighted") then
					chance = chance + 8
					if HasGlasses(player) then
						chance = chance - 6
					end
				end
				if rnd < 10 + chance then --print('SUCCESS!')
					_step_check = x0 ~= step_X and y0 ~= step_Y -- ������ �������� ��������� � ��� �� ����.
					--CheckStepInShit(player,x1,y1)
				end
			end
		end
	end
	-- � ����� ������ ����������, ����� ���������� �����
	local items = sq:getWorldObjects()
	local cnt = items:size()
	for i=cnt-1, math.max(0,cnt-10), -1 do -- ���������� � ����� �� ����� 10 ���������. (����� � ���� ����� �� �������� ��� ��)
		local w = items:get(i)
		local item = w:getItem()
		if item:hasTag("Feces") then
			feces = feces + 1
			if _step_check and IS_HUMAN_FECES[item:getType()] then
				--:getWorldObjectIndex()
				table.insert(_step_sq, w)
				table.insert(_step_sq, w:getWorldPosX())
				table.insert(_step_sq, w:getWorldPosY())
			end
		end
	end
	if _step_check then
		if CheckStepInShit(player,x1,y1) then
			feces = feces - 1
			if feces < 0 then -- ������ �� ����� ����, �� �� ������ ������ ����� ����� ������������
				feces = 0
			end
		end
	end
	if old_smell ~= feces then
		Excrementum.room_smell = feces
		Excrementum.UpdateSmellMoodle(player, -1) -- �� �������� ������
	end
end
Events.OnPlayerMove.Add(Excrementum.OnPlayerMove)

function Excrementum.ResetOnPlayerMove()
	old_X = nil
	Excrementum.OnPlayerMove(Excrementum.p)
end

-------- SERVE TO CLIENT COMMUNICATION ------------



local function onServerCommand(mod, com, args)
	if mod ~= "Exc" then
		return
	end
	local player = Excrementum.p
	if not player then
		return
	end
	--print("GOT COMMAND " .. com)
	if com == "Mechanics" then
		Excrementum.AddTask(40, Excrementum.UpdateVehicleWindow)
		--print("TASK CREATED")
	elseif com == "Shame" then
		local p = getPlayerByOnlineID(args[2])
		if p then
			local typ = args[1]
			if typ == 2 or typ == 3 then
				typ = 1
			elseif typ == 4 and player:HasTrait("Voyeuristic") then
				typ = 6 -- ����� ������ ������
			elseif typ == 4 and player:HasTrait("Exhibitionist") then
				typ = 6 -- ����� ������ ������
			end
			if ShameIsEnabled(player) then
				ApplyShame(p:getFullName(), typ)
			end
		end
	elseif com == "UrineSmell" then
		Excrementum.ResetOnPlayerMove()
		--Excrementum.OnPlayerMove(player)
	elseif com == "AddBucket" then -- {typ, new_delta}
		local item = InventoryItemFactory.CreateItem(args[1])
		if item then
			if args[2] then
				item:setUsedDelta(args[2])
			end
			player:getInventory():AddItem(item);
		end
	end
end
Events.OnServerCommand.Add(onServerCommand);


------------------- TRAITS ---------

local isSinglePlayer = not isClient()

Events.OnGameBoot.Add(function()
	-- id, name, cost, desc, b_profession, b_removeInMP
	--if not isSinglePlayer then
		TraitFactory.addTrait("Voyeuristic", getText("UI_trait_ExcVoyeuristic"), 2, getText("UI_trait_VoyeuristicDesc"), false);
		TraitFactory.addTrait("Exhibitionist", getText("UI_trait_ExcExhibitionist"), 2, getText("UI_trait_ExhibitionistDesc"), false);

	--end
end);




---------------------- DEBUG INFO -------------------
if not Excrementum.DEBUG then
	return
end


local function ExDebug(keynum)
	local player = getSpecificPlayer(0)
	if not player then
		return
	end
	if keynum ~= 53 then
		return
	end
	if ExcrementumDebugWindow:getIsVisible() then -- KEY "/"
		ExcrementumDebugWindow:setVisible(false)
	else
		ExcrementumDebugWindow:setVisible(true)
		ExcrementumDebugWindow:updateText()
	end
end
Events.OnKeyPressed.Add(ExDebug)

do
	local old_setActionAnim =  ISBaseTimedAction.setActionAnim
	function ISBaseTimedAction:setActionAnim(_action, ...)
		old_setActionAnim(self, _action, ...)
		self.__anim = _action
	end
end

--Excrementum.AnimTest()
--Excrementum.AnimTest(200, "")
function Excrementum.AnimTest(time, anim)
	time = time or 200
	local player = getSpecificPlayer(0)
	if anim then
		ISTimedActionQueue.add(ExcActionDebug:new(player, time, anim))
		return
	end
	ISTimedActionQueue.add(ExcActionDebug:new(player, time, "unzipmale"))
	ISTimedActionQueue.add(ExcActionDebug:new(player, time, "unzipFemale"))
	ISTimedActionQueue.add(ExcActionDebug:new(player, time, "urinate_Male"))
	ISTimedActionQueue.add(ExcActionDebug:new(player, time, "defecate_toilet"))
	ISTimedActionQueue.add(ExcActionDebug:new(player, time, "defecate_outside"))
end


doLua = function(s)
	Excrementum.SendClientCommand('DebugLua',Excrementum.p,s,Excrementum.p)
end


--����������� ������, ������� ����� ����� �����.
function Excrementum.DebugShowDrop(p, is_male_pee, is_any)
	local res = Excrementum.GetAllPantsGroin(p, is_male_pee, is_any)
	if type(res) ~= 'table' then
		return --print(tostring(res))
	end
	local s = 'Found: ' .. #res
	for i,v in ipairs(res) do
		s = s .. "\n\t" ..  v:getType() .. " | " .. v:getBodyLocation()
	end
	print(s)
	g_res = res -- global
	return res
end

function Excrementum.DebugSetRoom(val, days)
	local room = sq:getRoom() -- debug mod needed
	if not room then
		return print('No room')
	end
	local sq0 = room:getSquares():get(0)
	local data = sq0:getModData()
	local now = Excrementum.GameTime:getMinutesStamp()
	local old_days = data.ex_tm and round((now - data.ex_tm)/1440,2)
	print("\nOld values: " .. tostring(data.ex_sml and round(data.ex_sml,2)) .. ', ' .. tostring(old_days)
		.. "\nNew values: " .. tostring(val and round(val,2)) .. ' ' .. tostring(days and round(days,2))
	)
	data.ex_sml = val
	if days then
		data.ex_tm = now - days * 1440
	else
		--data.ex_tm = nil
	end
end

Excrementum.GetActionName = GetActionName


