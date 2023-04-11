local GAME_PATH = [[C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\media\]];

local LUA_PATH = './media/lua/client/?.lua;'
package.path = LUA_PATH .. package.path
local KNWON_FOOD_TYPES = require('Defecation_new')

local function trim2(s)
	return s:match "^%s*(.-)%s*$"
end


local function ExtractScriptData(filename, data, no_module, sep)
  data = data or {} -- [id] = "trans"
	if not sep then
		sep = '='
	end
	local main_pattern = "^([a-zA-Z_0-9]+)%s*"..sep.."%s*(.*),$"
	local main_pattern2 = "^([a-zA-Z_0-9]+)%s*"..sep.."%s*(.*)$" -- no comma
  local file = io.open(filename, "r")
	if not file then
		print('ERROR: FILE NOT FOUND ' .. filename)
	end
  print("Reading file "..filename.."...")
  local num = 1
	local mode = 0 -- 0=out of item, 1=pre_item, 2=inside item
	local id_now = nil
	local obj = nil
	local data_cnt = 0
	local modname = nil
  for line in file:lines() do 
    --lines[#lines + 1] = line
    --print(line)
    line = line:gsub("/%*.*%*/","") -- remove comments
    line = trim2(line)
    if line == "" or num < 3 then
      if num == 1 then
				modname = line:match("^module%s+(.*)$")
				if not modname then
					print("FATAL ERROR: wrong module name")
					print(line)
					return data
				end
			end
    elseif mode == 0 then
			local id = line:match("^item%s+(.*)$")
			if id then
				id_now = id
				mode = 1
			else
				local recipe = line:match("^recipe%s+(.*)$")
				if recipe then
					mode = 11 -- recipe mode for skipping until "}"
				else
					local imports = line:match("^imports$")
					if imports then
						mode = 11
					else
						local evo = line:match("^evolvedrecipe%s+(.*)$")
						if evo then
							id_now = evo --исключительно для evolvedrecipes.txt
							mode = 1
						end
					end
				end
			end
			if mode == 0 then
				if line == '}' then print('end_of_file')
				else print('ERROR (line '..num..'): item definition not found')
				end
			end
		elseif mode == 1 then
			if line ~= "{" then
				print('ERROR (line '..num..'): item definition not started - '..id_now)
			end
			mode = 2
			local full_id = modname .. "." .. id_now
			if no_module then
				full_id = id_now
			end
			obj = {id=full_id}
			data[full_id] = obj
			data_cnt = data_cnt + 1
		elseif mode == 2 then
			if line == "}" then
				mode = 0 -- end of item
				obj = nil
			else
				local key, val = line:match(main_pattern)
				if not key then
					key, val = line:match(main_pattern2)
					if key then
						print('WARNING (line '..num..'): no comma')
					end
				end
				if not key then
					print('ERROR (line '..num..'): bad string format - '..id_now)
					print(line)
				else
					--key = trim2(key)
					obj[key] = val
				end
			end
		elseif mode == 11 then
			if line == "}" then
				mode = 0 -- back to normal
			end
    end
    num = num + 1
  end
	print('Found: ' .. data_cnt .. ' item definitions.')
  return data, data_cnt
end


local DATA = ExtractScriptData(GAME_PATH .. 'scripts\\' .. 'farming.txt')
ExtractScriptData(GAME_PATH .. 'scripts\\' .. 'items.txt', DATA)
ExtractScriptData(GAME_PATH .. 'scripts\\' .. 'items_food.txt', DATA)
ExtractScriptData(GAME_PATH .. 'scripts\\' .. 'newitems.txt', DATA)
local EVO_DATA = ExtractScriptData(GAME_PATH .. 'scripts\\' .. 'evolvedrecipes.txt', nil, true, ':')

-- translations

local function ExtractTransData(filename)

  local file = io.open(filename, "r")
	if not file then
		print("ERROR: TRANS FILE NOT FOUND!")
		print(filename)
		return
	end
  print("Reading file ...")
  local data = {} -- [id] = "trans"
  local num = 1
  for line in file:lines() do 
    --lines[#lines + 1] = line
    --print(line)
    line = line:gsub("/%*.*%*/","")
    line = line:gsub("ItemName_","")
    line = trim2(line)
    if line == "" or line == "RU = {" or line == "}" then
      -- do nothing
    else
      local mod, key, val = line:match("([a-zA-Z_0-9]+)%.([a-zA-Z%_- 0-9]+)%s*=%s*\"(.*)\"")
      if not mod then
        print('ERROR (line '..num..'): bad string format.')
        print(line)
      else
        key = trim2(key)
        local fullkey = mod.."."..key
        if data[fullkey] then
          print('ERROR (line '..num..'): duplicate '..fullkey)
        end
        data[fullkey] = val
      end
    end
    num = num + 1
  end
  return data

--s=s:gsub("/%*.*%*/","")
end
local TRANS2 = ExtractTransData(GAME_PATH .. [[lua\shared\Translate\RU\ItemName_RU.txt]])

-- За основу берём свой перевод
local TRANS = ExtractTransData([[C:\Users\user\Zomboid\Workshop\RussianLanguagePackMod\Contents\mods\RussianLanguagePack\media\lua\shared\Translate\RU\ItemName_RU.txt]])

local TRANS_NOT_EXIST = {}
-- дополняем официальным лишь недостающие пробелы
for k,v in pairs(TRANS2) do
	if not TRANS[k] then 
		TRANS_NOT_EXIST[k] = true
		TRANS[k] = v
	end
end

--добавляем перевод непосредственно в предметы
for k,v in pairs(TRANS) do
	--local key = k:match("%.(.*)") or k
	local key = k
	if DATA[key] then
		DATA[key].rus = v
	end
end

--проверка на вшивость в русификаторе (не имеет отношения к моду на дефекацию)
local TRANS_DICT = nil
do
	local filename = [[C:\Users\user\Zomboid\Workshop\RussianLanguagePackMod\Contents\mods\RussianLanguagePack\1251.lua]]
	local file = io.open(filename, "r")
	if file then
		TRANS_DICT = {}
		local mode = 0
		for line in file:lines() do
			line = trim2(line)
			if mode == 0 then
				if line == "RUS.TRANS_DICT = {" then
					mode = 1
				end
			elseif mode == 1 then
				if line == '}' then
					break --end of needed file part
				end
				local s = line:match('^%s*%["([^"]+)"%]%s*=%s*{')
				if s then
					TRANS_DICT[s] = true
				end
			end
		end
	end
end
local function CheckTransDict(item)
	if not item.rus or not TRANS_DICT then
		return
	end
	if not TRANS_DICT[item.rus] then
		print("NO TRANS: " .. item.id .. ' = "' .. item.rus .. '",' .. (TRANS_NOT_EXIST[item.id] and '' or '(имеется в ItemName_RU.txt)'))
	end
end


-------------- CHECKING --------
print('CHECKING...')
local ALL_FOOD_TYPES = {}
for id,v in pairs(DATA) do
	if (v.EvolvedRecipe or v.Type == 'Food') and not v.FoodType and v.CantEat ~= 'TRUE' then
		--print('ERROR: no food type - ' .. id)
	end
	if v.Type == 'Food' then
		if not v.HungerChange then
			--print('ERROR: no hunger change - ' .. id)
		elseif not v.Calories then
			--print('WARNING: no calories - ' .. id)
		end
	end
	if v.FoodType then
		if not ALL_FOOD_TYPES[v.FoodType] then
			ALL_FOOD_TYPES[v.FoodType] = {}
		end
		table.insert(ALL_FOOD_TYPES[v.FoodType], v.rus or v.id)
	end
end
for _,v in pairs(ALL_FOOD_TYPES) do
	table.sort(v)
end


----------- Searching Evo ---------
print('SEARCHING EVO...')

local function split(inputstr, sep)
	if sep == nil then
		sep = ";"
	end
	local t={}
	for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
		local s = trim2(str)
		if s ~= '' then
			table.insert(t, s)
		end
	end
	return t
end

EVO_IN = {}
EVO_OUT = {}
for id,item in pairs(DATA) do
	if item.EvolvedRecipe then
		local arr = split(item.EvolvedRecipe)
		for _,v in pairs(arr) do
			local rec = split(v,":")
			if #rec ~= 2 then
				if #rec == 1 then --разрешаем, т.к. нам нужно только имя
					print('WARN in evo: "' .. v .. '" ' .. id)
					--rec[2] = '1'
				else
					print('ERROR in evo: "' .. v .. '" ' .. id)
					break
				end
			end
			local evo_name = rec[1]
			local data = EVO_DATA[evo_name]
			if not data then
				print('ERROR: evo not found - ' .. tostring(evo_name)..', ' .. id)
				break
			else
				local BaseItem = 'Base.' .. (data.BaseItem or '')
				local ResultItem = 'Base.' .. (data.ResultItem or '')
				EVO_IN[BaseItem] = true
				EVO_OUT[ResultItem] = true
				local fix = DATA[BaseItem]
				if fix then
					if not fix.evo_out then
						fix.evo_out = {}
					end
					table.insert(fix.evo_out, item.rus)
					--добавляем подробную инфу про рецепты
					if not fix.evo_out2 then
						fix.evo_out2 = {}
					end
					local food_type = item.FoodType or 'NoExplicit'
					if not fix.evo_out2[food_type] then
						fix.evo_out2[food_type] = {}
					end
					table.insert(fix.evo_out2[food_type], item.rus)
				end
			end
		end
	end
end


---------------- Write file --------------

local function NOT(s)
	if (s == 'FALSE' or s == 'false') then
		return true
	end
	return not s -- i.e.  ~= nil, e.g. TRUE
end

do
	print('WRITING...')
	local file = io.open("food_type.txt", "w")
	if not file then
		return print("ERROR: CAN'T WRITE!")
	end
	
	local function n(s)
		if not s then
			return ""
		end
		return s:gsub("%.",",")
	end
	
	local data_keys = {}
	for k,v in pairs(DATA) do
		table.insert(data_keys, k)
	end
	table.sort(data_keys)

	local arr = {
		"x\tid\tTime\tFoodType\tRUS NAME\tГолод\tЖажда\tCalories\tProteins\tLipids\tCarbohydrates\tCantEat\tCannedFood\tEvolvedRecipe\tevo_out",
	}
	for i ,k in ipairs(data_keys) do
		local v = DATA[k]
		if v.Type == 'Food' or v.EvolvedRecipe then
			if v.EvolvedRecipe then -- NOT(v.CantEat) or
				CheckTransDict(v)
			end
			--print(v.FoodType)
			if v.evo_out then
				table.sort(v.evo_out)
				--print('!!! ', #v.evo_out)
				--for k,v in pairs(v.evo_out) do print(v) end
			end
			local _time = KNWON_FOOD_TYPES[v.id] or KNWON_FOOD_TYPES[v.FoodType]
			local _in_out = (EVO_IN[k] and 1 or 0) + (EVO_OUT[k] and 2 or 0)
			local line = (_in_out > 0 and _in_out or '')
				.. "\t" .. k  .."\t".. (_time or "").."\t" .. (v.FoodType or '').. "\t" .. (v.rus or '')
				.. "\t" .. n(v.HungerChange) .. "\t" .. n(v.ThirstChange)
				.. "\t" .. n(v.Calories) .. "\t" .. n(v.Proteins) .. "\t" .. n(v.Lipids) .. "\t" .. n(v.Carbohydrates)
				.. "\t" .. (v.CantEat or '') .. "\t" .. (v.CannedFood or '')
				.. "\t" .. (v.EvolvedRecipe or '')
				.. "\t" .. (v.evo_out and table.concat(v.evo_out,"; ") or '')
			table.insert(arr,line)
		end
	end
	
	file:write(table.concat(arr,"\n"))
	file:close()
	
	--Записываем подробные данные про рецепты для наглдяности
	arr={}
	local ALL_FOOD_TYPES_arr = {}
	for k,v in pairs(ALL_FOOD_TYPES) do
		table.insert(ALL_FOOD_TYPES_arr, k)
	end
	table.sort(ALL_FOOD_TYPES_arr)
	
	file = io.open("evo_recipes.txt", "w")
	if not file then
		return print("ERROR: CAN'T WRITE!")
	end
	for i ,k in ipairs(data_keys) do
		local v = DATA[k]
		if v.evo_out2 then
			local s = '----------- ' .. (v.rus or v.id) .. ' ------------\n';
			for _,typ in pairs(ALL_FOOD_TYPES_arr) do
				if v.evo_out2[typ] then
					table.sort(v.evo_out2[typ])
					local cache = {}
					local ss = ''
					local cnt1, cnt2 = 0, 0
					for _,v in ipairs(v.evo_out2[typ]) do
						if not cache[v] then
							ss = ss .. "\t" .. v .. "\n"
							cache[v] = true
							cnt1 = cnt1 + 1
						end
					end
					if typ ~= 'NoExplicit' then
						for _,v in ipairs(ALL_FOOD_TYPES[typ]) do
							if not cache[v] then
								ss = ss .. "\t-- " .. v .. "\n"
								cache[v] = true
								cnt2 = cnt2 + 1
							end
						end
					end
					if cnt1+cnt2 > 0 then
						s = s .. typ .. ' ('..cnt1..(cnt2>0 and (' / -'..cnt2)or'')..')\n' .. ss
					end
				end
			end
			s = s .. "\n"
			table.insert(arr,s)
		end
	end

	file:write(table.concat(arr,"\n"))
	file:close()
	
	
	print('DONE.')
end



