if Excrementum then
	Excrementum._hash = Excrementum._hash + 512
else
	return
end

if not Excrementum.DEBUG then
	return
end


ExcrementumDebugWindow = ISCollapsableWindow:derive("ExcrementumDebugWindow");
ExcrementumDebugWindow.compassLines = {}
--Excrementum.DebugWindow = ExcrementumDebugWindow


function ExcrementumDebugWindow:initialise()
	ISCollapsableWindow.initialise(self);
end

function ExcrementumDebugWindow:new(x, y, width, height, player) --print('Exc new: ',player)
	local o = {};
	o = ISCollapsableWindow:new(x, y, width, height);
	setmetatable(o, self);
	self.__index = self;
	o.title = "Excrementum Debug Window " .. Excrementum.VERSION;
	o.pin = true;
	--o:noBackground();
	o.player = player;
	ExcrementumDebugWindow.inst = o
	return o;
end

function ExcrementumDebugWindow:setText(newText)
	ExcrementumDebugWindow.HomeWindow.text = newText;
	ExcrementumDebugWindow.HomeWindow:paginate();
	local rich_height = self.HomeWindow:getHeight()
	if rich_height < 240 then
		rich_height = 240
	end
	if rich_height > 500 then
		rich_height = 500
	end
	self:setHeight(rich_height + 25)
end

local function round3(num)
	return math.floor(num*1000) / 1000
end

function ExcrementumDebugWindow:updateText() --print('Exc update: ',self.player)
	local player = self.player or getPlayer()
	local exc = player:getModData().exc
	if not exc then
		return self:setText("No data!")
	end
	local x,y = ExcrementumDebugWindow:getX(),ExcrementumDebugWindow:getY()
	if exc.layout[11] ~= x or exc.layout[12] ~= y then
		exc.layout[11] = x
		exc.layout[12] = y
	end
	local stomach = player:getModData().exc.st
	local chyme = player:getModData().exc.ch
	--if #stomach == 0 and #chyme == 0 and chyme.h + chyme.w == 0 then
	--	return self:setText("Empty stomach.")
	--end
	local now = player:getHoursSurvived() * 60
	local V, h_sum, w_sum = Excrementum.GetStomachV(stomach)
	local Vq, h_sumq, w_sumq = Excrementum.GetStomachV(chyme)
	local arr = {}
	local poison = player:getBodyDamage():getPoisonLevel()
	local foodsick = player:getBodyDamage():getFoodSicknessLevel()
	if poison > 0 or foodsick > 0 or exc.hg > 0 then
		local a = {}
		if foodsick > 0 then table.insert(a, 'FoodSick = ' .. round(foodsick,2) .. '%') end
		if poison > 0 then table.insert(a, 'Poison = '..round(poison,2)) end
		if exc.hg > 0 then table.insert(a, 'hg = ' .. round(exc.hg,2)) end
		table.insert(arr,table.concat(a,', '))
	end
	table.insert(arr,'----- STOMACH ('..#stomach..') sumV = '.. math.floor((V + Vq)*1000)/10 ..' -----') -- {sp=speed, h=hunger, te=time_eaten, name=, ings=}
	if Excrementum.StomachPain > 0 then
		table.insert(arr,"Pain = " .. tostring(round(Excrementum.StomachPain,2)))
	end
	if V > 0 then
		table.insert(arr, 'V = '..round(V*100,2) .. ', h = ' .. round(h_sum*100,2) .. ', w = ' .. round(w_sum*100,2))
	elseif #stomach == 0 then
		table.insert(arr,'(empty stomach)')
	end
	for i=#stomach,1,-1 do
		local v = stomach[i]
		local tm = Excrementum.GetStomachTime(v, V)
		local t = v.tt -- target_tm
		local T = t
		if v.w > 0 then
			T = v.tt + tm * ((v.h - v.w ) / v.h - 1)
		end
		local s = tostring(v.name) .. " (" .. round(v.h*100, 2)
			.. (v.w > 0 and ", "..round(v.w*100,2) or "")
			.. (round(v.v,2) ~= 1 and "; visc="..round(v.v,2) or "")
			.. "), T=" .. tostring(round(T-now))
		if v.ings then
			s = s .. "\n" .. v.ings
		end
		table.insert(arr,s)
	end
	
	table.insert(arr,'----- CHYME ('..(#chyme)..') -----')
	V, h_sum, w_sum = Vq, h_sumq, w_sumq
	if V ~= 0 or chyme.P~=0 or chyme.L~=0 or chyme.C~=0 or h_sum~=0  or w_sum~=0 or chyme.d~=0 then
		table.insert(arr, 'V = '..round(V*100,2) .. ', h = ' .. round(h_sum*100,2) .. ', w = ' .. round(w_sum*100,2) .. ', v = ' .. round(chyme.v,2))
		table.insert(arr, 'PLC = '..round(chyme.P,1)..", "..round(chyme.L,1)..", "..round(chyme.C,1)
			.."; p = "..round(Excrementum.GetOsmoticP(chyme),2))
		if chyme.d > 0 then
			table.insert(arr, 'diuretic = ' .. round(chyme.d*100, 2))
		end
	elseif #chyme == 0 then
		table.insert(arr,'(no chyme)')
	end
	for i,v in ipairs(chyme) do
		local tm = Excrementum.GetStomachTime(v, V)
		local t = v.tt -- target_tm
		--local T = t
		--if v.w > 0 then
		--	T = v.te + tm * (v.h - v.w) / v.h
		--end
		local s = tostring(v.name) .. " (" .. round(v.h*100, 2) .. (v.w > 0 and ", "..round(v.w*100,2) or "") .. "), T=" .. tostring(round(t-now))
		if v.ings then
			s = s .. "\n" .. v.ings
		end
		table.insert(arr,s)
	end
	
	local intestine = player:getModData().exc.int
	if not intestine then
		return self:setText(table.concat(arr,"\n"))
	end
	table.insert(arr,'----- INTESTINE{h,V,visc} ('..(intestine.last - intestine.first + 1)..') -----')
	local ss = ''
	for i=intestine.first,intestine.last do
		local v = intestine[i]
		if not v then
			ss = ss .. 'nil; '
		else
			ss = ss .. '{' .. round(now-v[1]) .. ', ' .. round(v[2]*100,1) .. (round(v[3],2)~=1 and ', '..round(v[3],2) or '') .. '}; '
		end
	end
	if ss == '' then ss = '(empty)' end
	table.insert(arr,ss)
	
	local colon = player:getModData().exc.col
	table.insert(arr,'----- COLON -----')
	if Excrementum.ColonPain > 0 then
		table.insert(arr, "Pain = "..round(Excrementum.ColonPain,2))
	end
	local smell_val = Excrementum.m_smell and Excrementum.m_smell:getValue() or 0
	if colon.V == 0 and exc.ass == nil and not (colon.tf or colon.td) and smell_val == 0 then
		table.insert(arr,'(empty)')
	else
		table.insert(arr,'V = '..round(colon.V*100,1)
			..'; visc = ' .. round(colon.visc,2)
			..'; og = ' .. round(colon.og*100,2)
		)
		if colon.tf or colon.td then
			local a = {'TR = ' .. round(Excrementum.feces_threshold*100,1)}
			a[2] = colon.tf and ('tf = '..round(now-colon.tf)) or nil
			table.insert(a, colon.td and ('td = '..round(now-colon.td)) or nil)
			--table.insert(a, Excrementum.ColonPain > 0 and "Pain = "..round(Excrementum.ColonPain,3) or nil)
			table.insert(arr,table.concat(a,'; '))
		end
		if exc.ass then
			table.insert(arr,'ass = ' .. tostring(exc.ass))
		end
		if smell_val ~= 0 then
			table.insert(arr,'smell = ' .. round(smell_val,2))
		end
	end
	
	table.insert(arr,'----- URINE -----')
	local avg = exc.sc ~= 0 and exc.ss * 0.5 / exc.sc or 0
	table.insert(arr,'u = '..round(exc.urine*1000,1)..'; ss = '..round(exc.ss,1)..'; sc = '..exc.sc..'; AvgStress = '..round(avg,2))
	local X = 0.3 + Excrementum.Ms
	local Y = X + 0.15
	table.insert(arr, 'X = '..round(X*1000,1)..'; Y = '..round(Y*1000,1))
	if Excrementum.room_smell ~= 0 then
		table.insert(arr, 'room_smell = ' .. round(Excrementum.room_smell,2)
			.. (Excrementum.room_smell_days and "; Days = "..round(Excrementum.room_smell_days,1) or '')
		)
	end
	
	--if Excrementum.shame ~= 0 then
	local found_shame = 0
	for name, user in pairs(exc.rel) do
		if name == 0 then
			name = 'Zombie'
		end
		local s = name .. ': ';
		local a = {}
		for i=1,7 do
			local data = user[i]
			if data then
				table.insert(a, 'T' .. i .. '[' .. data.a .. ']='..data.l..'('.. math.ceil(data.b - Excrementum.now)
					.. (data.h < data.b and ',' .. math.ceil(data.h - Excrementum.now) or '')
					..')'
				)
			end
		end
		if #a > 0 then
			if found_shame ~= 2 then
				found_shame = 1
			end
			s = s .. table.concat(a, ';')
		else
			s = s .. 'No Relations'
		end
		if found_shame == 1 then
			found_shame = 2
			table.insert(arr,'----- SHAME = '.. Excrementum.shame ..' -----')
		end
		table.insert(arr,s)
	end
	
	
	self:setText(table.concat(arr,"\n"))
end


function ExcrementumDebugWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	
	self.HomeWindow = ISRichTextPanel:new(0, 15, 320, 250);
	self.HomeWindow:initialise();
	self.HomeWindow.autosetheight = true
	self.HomeWindow:ignoreHeightChange()
	self:addChild(self.HomeWindow)
	
	
	self.button_urine = ISButton:new(310, 20, 50, 15, getText("UI_Exc_HumanUrineShort"), self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_urine.internal = "URINE";
	self.button_urine:initialise();
	self.button_urine:instantiate();
	--self.button_urine.borderColor = self.buttonBorderColor;
	self:addChild(self.button_urine);
	--self.button_urine.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");

	self.button_feces = ISButton:new(310, 40, 50, 15, getText("UI_Exc_HumanFecesShort"), self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_feces.internal = "FECES";
	self.button_feces:initialise();
	self.button_feces:instantiate();
	--self.button_feces.borderColor = self.buttonBorderColor;
	self:addChild(self.button_feces);
	--self.button_feces.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");

	self.button_feces = ISButton:new(310, 60, 50, 15, "Empty", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_feces.internal = "EMPTY";
	self.button_feces:initialise();
	self.button_feces:instantiate();
	--self.button_feces.borderColor = self.buttonBorderColor;
	self:addChild(self.button_feces);
	--self.button_feces.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");

	self.button_feces = ISButton:new(310, 80, 50, 15, "Pee", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_feces.internal = "PEE";
	self.button_feces:initialise();
	self.button_feces:instantiate();
	--self.button_feces.borderColor = self.buttonBorderColor;
	self:addChild(self.button_feces);
	--self.button_feces.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");

	self.button_feces = ISButton:new(310, 100, 50, 15, "Poo", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_feces.internal = "POO";
	self.button_feces:initialise();
	self.button_feces:instantiate();
	--self.button_feces.borderColor = self.buttonBorderColor;
	self:addChild(self.button_feces);
	--self.button_feces.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");
	
	self.button_feces = ISButton:new(310, 120, 50, 15, "Anim", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_feces.internal = "TEST_ANIM";
	self.button_feces:initialise();
	self.button_feces:instantiate();
	--self.button_feces.borderColor = self.buttonBorderColor;
	self:addChild(self.button_feces);
	--self.button_feces.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");
	
	self.button_stomach = ISButton:new(310, 140, 50, 15, "Stom.", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_stomach.internal = "STOMACH";
	self.button_stomach:initialise();
	self.button_stomach:instantiate();
	self:addChild(self.button_stomach);
	
	self.button_feces = ISButton:new(310, 160, 50, 15, "+Paper", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_feces.internal = "PAPER";
	self.button_feces:initialise();
	self.button_feces:instantiate();
	--self.button_feces.borderColor = self.buttonBorderColor;
	self:addChild(self.button_feces);
	--self.button_feces.tooltip = getText("IGUI_AdminPanel_TooltipAdminPower");

	self.button_food = ISButton:new(310, 180, 50, 15, "+Food", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_food.internal = "FOOD";
	self.button_food:initialise();
	self.button_food:instantiate();
	self:addChild(self.button_food);

	self.button_drink = ISButton:new(310, 200, 50, 15, "+Drink", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_drink.internal = "DRINK";
	self.button_drink:initialise();
	self.button_drink:instantiate();
	self:addChild(self.button_drink);

	self.button_shame = ISButton:new(310, 220, 50, 15, "NoShame", self, ExcrementumDebugWindow.onPushMouseDown);
	self.button_shame.internal = "SHAME";
	self.button_shame:initialise();
	self.button_shame:instantiate();
	self:addChild(self.button_shame);


	--нет места для кнопок (макс. высоат окна)
	
end


local _last_paper_tm = 0
local _last_paper
local _last_item
function ExcrementumDebugWindow:onPushMouseDown(button, x, y)
	--print('BUTTON ' .. tostring(button and button.internal))
	local player = Excrementum.p
	local exc = Excrementum.exc
	if button.internal == "URINE" then
		if exc.urine < 0.2001 then
			exc.urine = 0.2001
		else
			exc.urine = exc.urine + 0.1
		end
		Excrementum.DoUpdate(player)
	elseif button.internal == "FECES" then
		local colon = exc.col
		if colon.V < 1 then
			colon.V = 1
		else
			colon.V = colon.V + 0.1
		end
		Excrementum.feces = colon.V
		if Excrementum.feces > .1 and Excrementum.feces >= Excrementum.feces_threshold then
			if not colon.td then
				colon.td = Excrementum.now
			end
		end
		Excrementum.DoUpdate(player)
	elseif button.internal == "EMPTY" then
		Excrementum.DoDefecate(player)
	elseif button.internal == "PAPER" or button.internal == "FOOD" or button.internal == "DRINK" then
		local prefab, mess
		if button.internal == "PAPER" then
			prefab = "Base.SheetPaper2"
			mess = " paper"
		elseif button.internal == "FOOD" then
			prefab= "Base.OatsRaw"
			mess = " food"
		else
			prefab= "Base.PopBottle"
			mess = " drink"
		end
		local sheet = InventoryItemFactory.CreateItem(prefab)
		player:getInventory():AddItem(sheet)
		local num = 1
		if os.time() - _last_paper_tm < 3 and prefab == _last_item then
			num = _last_paper + 1
		end
		player:setHaloNote("+" .. num .. mess, 255,100,255, 200)
		_last_paper_tm = os.time()
		_last_paper = num
		_last_item = prefab
	elseif button.internal == "PEE" then
		Excrementum:InvoluntaryUrinate()
	elseif button.internal == "POO" then
		Excrementum:InvoluntaryDefecate()
	elseif button.internal == "TEST_ANIM" then
		Excrementum.AnimTest()
	elseif button.internal == "STOMACH" then
		local V = Excrementum.GetStomachV(exc.st) + Excrementum.GetStomachV(exc.ch)
		if V > 0 then --очищаем
			--print("V = ",V)
			for i=#exc.st,1,-1 do
				exc.st[i] = nil
			end
			for i=#exc.ch,1,-1 do
				exc.ch[i] = nil
			end
			--print('old = ',exc.ch.w)
			exc.ch.h = 0
			exc.ch.w = 0
			--print('new = ',exc.ch.w)
		else -- кладём нечто неперевариваемое
			--print("ALREADY EMPTY STOMACH. ADD FOOD...")
			exc.st[1] = {
				--te=time_eaten,
				tt=99999999999999, -- target time, меняется только при изменении объёма желудка
				s=9999,
				v=1,
				h=SandboxVars.Excrementum.StomachVolume / 100 - 0.00001,
				w=0,
				P=1,
				L=1,
				C=1,
				ps = 0,
				name = 'Debug Food',
			}
		end
		Excrementum.DoUpdate(player)
	elseif button.internal == "SHAME" then
		table.wipe(Excrementum.exc.rel)
		Excrementum.UpdateShame(Excrementum.p)
		self:updateText()
	--elseif button.internal == "DRINK" then
	end
end

local function ExcrementumDebugWindowCreate(id)
	local player = getSpecificPlayer(0)  --print('Exc Create ',player,id)
	if Excrementum.p ~= player then
		return
	end
	local exc = player:getModData().exc
	local x,y = exc.layout[11],exc.layout[12]
	ExcrementumDebugWindow = ExcrementumDebugWindow:new(x or 330, y or 330, 365, 240, player)
	ExcrementumDebugWindow:addToUIManager();
	ExcrementumDebugWindow:setVisible(true);
	ExcrementumDebugWindow.pin = true;
	ExcrementumDebugWindow:setResizable(true);
	ExcrementumDebugWindow:updateText()
	Excrementum.OnUpdate.Add(function()
		ExcrementumDebugWindow:updateText()
	end)
end
Events.OnGameStart.Add(ExcrementumDebugWindowCreate);