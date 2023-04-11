-- if Excrementum then -- not defined yet in shared!


local GROIN_SHOW = { --Одежда, обнажающая пах (в качестве исключений из общего правила)
	Jacket_CoatArmy = 3, -- JacketSuit / LongJacket
	Ghillie_Top = 1, -- FullTop / Jacket
	WeddingJacket = 3, -- особый вид оголённости, когда попа всё же прикрыта
	Suit_Jacket = 3,
	Suit_JacketTINT = 3,
	--Jacket_Varsity = 4,
	JacketLong_Doctor = 0,
	JacketLong_Random = 0,
	JacketLong_Santa = 0,
	JacketLong_SantaGreen = 0,
	Jacket_ArmyCamoDesert = 4,
	Jacket_ArmyCamoGreen = 4,
	Jacket_Black = 4,
	Jacket_Chef = 4,
	Jacket_Fireman = 4,
	HospitalGown = 1,
	Male_Undies = 0,
	Apron_Black = 2,
	Apron_IceCream = 2,
	Apron_Jay = 2,
	Apron_PileOCrepe = 2,
	Apron_PizzaWhirled = 2,
	Apron_Spiffos = 2,
	Apron_White = 2,
	Apron_WhiteTEXTURE = 2,
	CBX_Kurtk_3 = 3,
	CBX_Kurtk_1 = 3,
	PonchoBlack=0, PonchoBlackDOWN=0, PonchoCamoDesert=0, PonchoCamoDesertDOWN=0,
	PonchoCamoForest=0, PonchoCamoForestDOWN=0, PonchoCamoForest2=0, PonchoCamoForest2DOWN=0,
	PonchoUrbanForest=0, PonchoUrbanForestDOWN=0, PonchoOliveDrab=0, PonchoOliveDrabDOWN=0,
	PonchoOrangePunch=0, PonchoOrangePunchDOWN=0, PonchoWhiteTINT=0, PonchoWhiteTINTDOWN=0,
	Jacket_Hunter = 3, Jacket_PostalDude = 3,
	Jacket_StraightJacket = 0,
}
local GROIN_SHOW_LOC = {
	UnderwearBottom = 0,
	Underwear = 0,
	--[[
	Torso1Legs1 = 0,
	Legs1 = 0,
	Pants = 0,
	FullSuit = 0,
	FullSuitHead = 0,
	BathRobe = 0,
	Boilersuit = 0,]]
	---
	Eyes = 4,
	Hands = 4,
	RightEye = 4,
	LeftEye = 4,
	Neck = 4,
	Scarf = 4,
	MakeUp_FullFace = 4,
	MakeUp_Eyes = 4,
	MakeUp_EyesShadow = 4,
	MakeUp_Lips = 4,
}
local GROIN_SHOW_EXTRA = {}

--- TORSO -----
local TORSO_SHOW = {
	Bikini_TINT = false,
	Bikini_Pattern01 = false,
	SwimTrunks_Blue = true,
	SwimTrunks_Green = true,
	SwimTrunks_Red = true,
	SwimTrunks_Yellow = true,
	Swimsuit_TINT = false,
	BunnySuitPink = false,
	BunnySuitBlack = false,
	Corset_Medical = true,
	CBX_Kurtk_3 = true, CBX_Kurtk_1 = true,
	CBX_Vest_Hunting_OrangeOPEN = true, CBX_Vest_Hunting_GreyOPEN = true, CBX_Vest_Hunting_CamoOPEN = true,
	CBX_Vest_Hunting_CamoGreenOPEN = true, CBX_Vest_HighVizOPEN = true, CBX_Vest_ForemanOPEN = true,
	CBX_SP1OP = true, CBX_Kurtk_5OP=true, CBX_RUBOP=true, CBX_Kurtk_7OP = true, CBX_Kurtk_7_1OP = true,
	CBX_Kurtk_8OP = true, CBX_Kurtk_9OP = true, CBX_Kurtk_10OP = true, CBX_PAN_4 = true, CBX_SK1 = false,
}



do -- inject into ra's definitions
	local m = __classmetatables[zombie.characters.WornItems.BodyLocationGroup.class].__index
	local old_fn = m.setHideModel
	m.setHideModel = function(self, s1, s2, ...)
		if s2 == "RasMalePrivatePart" then
			GROIN_SHOW_EXTRA[s1] = 0
		end
		return old_fn(self, s1, s2, ...)
	end
end


--Jacket_Bulky, Jacket
--print(p:getAnimAngleTwistDelta()) 0.89
--getAnimAngleStepDelta
--getDirectionAngle 135
--getAnimAngle -137
--getLookAngleRadians


-- 4 = голый со всех сторон, 3 = голый снизу и спереди, (2) = голый сзади и снизу, 1 = голый снизу, 0 = закрыт везде (по умолчанию)
local groin = BloodBodyPartType.Groin
local lower = BloodBodyPartType.Torso_Lower
local lower_leg = BloodBodyPartType.LowerLeg_L
local function IsShownGroin(item, typ, loc)
	typ = typ or item:getType()
	loc = loc or item:getBodyLocation()
	if GROIN_SHOW[typ] ~= nil then
		return GROIN_SHOW[typ]
	elseif GROIN_SHOW_LOC[loc] ~= nil then
		return GROIN_SHOW_LOC[loc]
	--elseif GROIN_SHOW_EXTRA[loc] ~= nil then
		--return GROIN_SHOW_EXTRA[loc]
	end
	local parts = item:getCoveredParts()
	if not parts then
		return 4
	end
	if parts:contains(groin) then -- пах прикрыт, это false или 1
		if parts:contains(lower_leg) then -- голень прикрыта, что-то длинное
			return 0
		end
		-- далее только короткие юбки, куртки и пр.
		if loc == 'Skirt' then -- короткие юбки (голень не прикрыта)
			return 1
		elseif parts:contains(lower) then -- живот прикрыт, значит типа куртки
			return 1
		end
		-- юбки (вряд ли), штаны
		return 0
	end
	return 4
end

local torso_upper = BloodBodyPartType.Torso_Upper
local function IsShownBreast(item, typ, loc)
	if TORSO_SHOW[typ] ~= nil then
		return TORSO_SHOW[typ]
	elseif loc == 'UnderwearTop' or loc == 'Underwear' then
		return false
	end
	local parts = item:getCoveredParts()
	if not parts then
		return false
	end
	return not parts:contains(torso_upper)
end


------ Fix mods ---------
local FIX_BLOOD = {
	["Base.CBX_Kurtk_4"] = "Jacket",
	["Base.CBX_PAN"] = "Groin",
	["Base.CBX_ST4"] = "Groin",
	["Base.CBX_SHO1"] = "Shoes;LowerLegs;UpperLegs",
	["Base.CBX_ST5"] = "Groin",
	--["Base.CBX_PAN_2"] = "Groin",
	["Base.CBX_kupalnuk"] = "LowerBody", --"ShirtNoSleeves",
	["Base.CBX_CropTop"] = "UpperBody",
	["Base.CBX_CropTop_White"] = "UpperBody",
	["Base.CBX_SK1"] = "LowerBody",
	["AuthenticZLite.PonchoBlack"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoBlackDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoCamoDesert"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoCamoDesertDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoCamoForest"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoCamoForestDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoCamoForest2"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoCamoForest2DOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoUrbanForest"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoUrbanForestDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoOliveDrab"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoOliveDrabDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoOrangePunch"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoOrangePunchDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.PonchoWhiteTINT"] = "Shirt;ShortsShort;FullHelmet",
	["AuthenticZLite.PonchoWhiteTINTDOWN"] = "Shirt;ShortsShort",
	["AuthenticZLite.Jacket_Bateman"] = "LongJacket",
	["AuthenticZLite.Jacket_CoatNavy"] = "Jacket",
	["AuthenticZLite.Jacket_Trenchcoat"] = "LongJacket",
	["AuthenticZLite.Jersey_BlueStar"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker1"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker2"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker3"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker4"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker5"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker6"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker7"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker8"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker9"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_GreenBayPacker0"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs1"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs2"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs3"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs4"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs5"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs6"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs7"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs8"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs9"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_KCChiefs0"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots1"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots2"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots3"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots4"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots5"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots6"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots7"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots8"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots9"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_NEPatriots0"] = "Shirt;Neck",
	["AuthenticZLite.Jersey_RedSkull"] = "Shirt;Neck",
	["AuthenticZLite.Jacket_StraightJacket"] = "Jacket;Groin",
}

local FIX_LOC = {
	["Base.CBX_ST4"] = "Skirt",
	["Base.CBX_ST5"] = "Skirt",
	["Base.CBX_PAN_5"] = "UnderwearBottom",
	["Base.CBX_PAN_6"] = "UnderwearBottom",
	["Base.CBX_PAN_7"] = "UnderwearBottom",
	["Base.CBX_KOF1"] = "Sweater",
	--["Base.CBX_KOF2"] = "Sweater",
	["Base.CBX_PAN_2"] = "UnderwearBottom",
	["Base.CBX_PAN_3"] = "UnderwearBottom",
	["Base.CBX_PAN_4"] = "UnderwearBottom",
}

local SM = ScriptManager.instance
for k,v in pairs(FIX_BLOOD) do
	local item = SM:getItem(k)
	if item then
		--item:setBodyLocation("Skirt")
		item:DoParam("BloodLocation = " .. v)
		local loc = FIX_LOC[k]
		if loc then
			item:setBodyLocation(loc)
			FIX_LOC[k] = nil
		end
	end
end
for k,v in pairs(FIX_LOC) do
	local item = SM:getItem(k)
	if item then
		item:setBodyLocation(v)
	end
end


Events.OnPreMapLoad.Add(function()
	-- после инициализации в OnClient
	if Excrementum then
		Excrementum._hash = Excrementum._hash + 131072
	else
		print('ERROR EXC: shared folder not connected to client!')
	end
	Excrementum.GROIN_SHOW = GROIN_SHOW -- error maybe here
	Excrementum.GROIN_SHOW_LOC = GROIN_SHOW_LOC
	Excrementum.GROIN_SHOW_EXTRA = GROIN_SHOW_EXTRA
	Excrementum.TORSO_SHOW = TORSO_SHOW
	Excrementum.IsShownGroin = IsShownGroin
	Excrementum.IsShownBreast = IsShownBreast
end)

do -- change sheet weight
	local item = SM:getItem("Base.SheetPaper2")
	if item then
		item:DoParam("Weight = 0.01")
  end
	item = SM:getItem("Base.ToiletPaper")
	if item then
		item:DoParam("UseDelta = 0.125")
	end
end

-- blind patches to other mods
do
	local rec = SM:getRecipe("Packing.Pack 4 Toilet Paper")
	if rec then
		rec:getSource():get(0):setCount(32) -- toilet paper
	end
end




