--аддон для ролов на MS, OS, Трансмог
--По всем вопросам аддона обращайтесь к Casta\Madarra ("Going to Death" | WOW-Turtle)

GTDR_GLOBALS = CreateFrame("Frame")
GTDR_GLOBALS:RegisterEvent("ADDON_LOADED")
GTDR_GLOBALS:SetScript("OnEvent", function()
    if event then
        if event == 'ADDON_LOADED' and arg1 == 'gtdroll' then            
            return GTDR_GLOBALS.init()
        end
    end    
end)

function GTDR_GLOBALS.init()
	DEFAULT_CHAT_FRAME:AddMessage(GTDR_NAME_ADDON.." loaded.")
	GTDR_GLOBALS.GTDR_GetOfficerNote(nil)
end

SLASH_GTDROLL1 = "/gtdroll";--help
SLASH_GTDROLLHELP1 = "/gtdrollhelp";--help
SLASH_GTDRRMS1 = "/rms";--roll ms
SLASH_GTDRROS1 = "/ros";--roll os
SLASH_GTDRRXMG1 = "/rxmg";--roll transmog
--перезагрузка интерфейса
SLASH_GRTDRRELOAD1 = "/reload"
SlashCmdList["GRTDRRELOAD"] = ReloadUI;
--перезагрузка инстансов
SLASH_GTDRRESET1 = "/reset";
SLASH_GTDRRESET2 = "/resetinstance";
SLASH_GTDRRESET3 = "/resetinstances";
SlashCmdList["GTDRRESET"] = ResetInstances;
local text_access_error = "К сожалению у вас |cffff0000нет доступа|r для просмотра офицерской заметки. ГМ гильдии может предоставить эти права."
local color_prefix_white = "|cffffffff"
GTDR_GLOBALS.color_prefix_orange = "|cffffaa00"
local SortField = "pp"--сортировка по умолчанию по progress-points все гильдии
local P_SortField = "pp"--сортировка по умолчанию по progress-points рейда\пати
local THE_BLACK_MORASS = "The Black Morass"
local ZUL_GURUB = "Zul'Gurub"
GTDR_ARCANE_ESSENCE = "Arcane Essence"
GTDR_HAKKARI_BIJOU = "Hakkari Bijou"
GTDR_CORRUPTED_SAND = "Corrupted Sand"
GTDR_COIN = "Coin"
GTDR_SCARAB = "Scarab"
GTDR_NAME_ADDON = "GTD"..GTDR_GLOBALS.color_prefix_orange.."ROLL|r"
GTDR_ADDON_VER = "1.0.14"
GTDR_DEFAULT_ROS_COEF = 0.5

--инициализация списка доступных рейдов
GTDR_AccessInstances = {}

--мини-фрейм
function GTDR_MiniInit()
	if CanViewOfficerNote() then
		local _roll = GTDR_GetMyRoll(nil)
		FieldProgressPointsHelper:SetText(GTDR_GetMyOfficerNote())
		FieldRollIntervalHelper:SetText(_roll)		
		ButtonRollMs:SetScript("OnEnter", function() 	
			GTDR_GLOBALS.GTDR_ButtonRollOnLoad("Roll MS: " .. _roll, this)			
		end)
		ButtonRollOs:SetScript("OnEnter", function()
			GTDR_GLOBALS.GTDR_ButtonRollOnLoad("Roll OS: " .. GTDR_GetMyRoll(true), this)
		end)		
	else
		FieldProgressPointsHelper:SetText("...")
	end
end

--основной фрейм
function GTDR_OnLoad()	
	this:RegisterEvent("VARIABLES_LOADED")
	this:RegisterEvent("PLAYER_LOGIN");
	this:RegisterEvent("ADDON_LOADED");		
	this:RegisterEvent("PLAYER_ENTERING_WORLD");		
	NickNameField:SetText(UnitName("player"))	  
	fieldAutoNeedZG:SetText(string.format("Автосбор |cffffffff%s|r и |cffffffff%s|r в ZG:", GTDR_HAKKARI_BIJOU, GTDR_COIN))
	fieldAutoNeedAQ:SetText(string.format("Автосбор |cffffffff%s|r в AQ20:", GTDR_SCARAB))
	fieldAutoNeedKara:SetText(string.format("Автосбор |cffffffff%s|r в Kara-10:", GTDR_ARCANE_ESSENCE))
	fieldAutoNeedBM:SetText(string.format("Автосбор |cffffffff%s|r и |cffffffff%s|r в BM:", GTDR_CORRUPTED_SAND, GTDR_ARCANE_ESSENCE))	
	titleAddon:SetText(GTDR_NAME_ADDON .. " v."..GTDR_ADDON_VER)
end

function GTDR_OnShow()
		GTDR_Init();		
end

function GTDR_Init()
	ButtonOpenMiniFrame:SetScript("OnClick", function()
		if FrameRollxml:IsShown() then
			GTDR_ShowMiniFrame = 0
			FrameRollxml:Hide()
		else
			GTDR_MiniInit()
			GTDR_ShowMiniFrame = 1
			FrameRollxml:Show()
		end
	end)	
	GTDR_IsZG:SetText(GTDR_GetTitleValue(GTDR_ZG_AUTONEED))
	GTDR_IsAQ:SetText(GTDR_GetTitleValue(GTDR_AQ_AUTONEED))
	GTDR_IsKara:SetText(GTDR_GetTitleValue(GTDR_KARA_AUTONEED))
	GTDR_IsBM:SetText(GTDR_GetTitleValue(GTDR_BM_AUTONEED))
	rmsInfo:SetText(string.format("|cffaaaaaa/rms|r ролл на мейн-спек (|cffaaaaaa%s|r)", GTDR_GetMyRoll(nil)))	
	rosInfo:SetText(string.format("|cffaaaaaa/ros|r ролл на офф-спек (|cffaaaaaa%s|r)", GTDR_GetMyRoll(true)))	
	if CanViewOfficerNote() then
		FieldAccessError:Hide()			
		GTDR_SetFieldMyPP()
		GTDR_SetFieldMyRoll()
		GTDR_SetFieldFormula()				
		--скроем рейтинг группы\рейда если не в пати\рейде
		if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
			ButtonRatingParty:Disable()
		else
			ButtonRatingParty:Enable()
		end
	else
		FieldAccessError:Show()
		FieldAccessError:SetText(text_access_error)
	end
end

function GTDR_GetMyRoll(isRos)
	local _fDigits = GTDR_GLOBALS.GTDR_GetDigitsF();
	local _note = GTDR_GLOBALS.GTDR_GetOfficerNote(UnitName("player")) or 0
	if isRos then
		_note = tonumber(_note) * GTDR_GLOBALS.GTDR_GetCoefRos()
	end
	if _note then
		local _min = math.floor(_note * _fDigits[1])
		local _max = math.floor(_note * _fDigits[2] + 100)					
		if _min < 1 then
			_min = 1;
		end	
		return _min .. "-".._max
	else
		return "1-100"
	end
end

function GTDR_SetFieldMyPP()
	FieldProgressPoints:SetText("Мои progress-points: ".. color_prefix_white .. GTDR_GetMyOfficerNote() .."|r")
end

function GTDR_GetMyOfficerNote()
	local _mynote = GTDR_GLOBALS.GTDR_GetOfficerNote(UnitName("player"))
	if _mynote then
		return math.floor(_mynote)
	end
	return ""
end

function GTDR_SetFieldMyRoll()
	FieldRollInterval:SetText("Мои интервалы рола MS/OS: ".. color_prefix_white .. GTDR_GetMyRoll(nil) .. "|r/|cffaaaaaa"..GTDR_GetMyRoll(true).."|r")
end

function GTDR_SetFieldFormula()
	local _pp = math.floor(GTDR_GLOBALS.GTDR_GetOfficerNote(UnitName("player")))
	local _fDigits = GTDR_GLOBALS.GTDR_GetDigitsF();
	local _text = string.format("|cffaaaaaamin:|r%d*%s,  |cffaaaaaamax:|r%d*%s+100", _pp, _fDigits[1], _pp, _fDigits[2])
	FieldFormula:SetText("Расчет по формуле: " .. _text  .. "")
end

function GTDR_GLOBALS.GTDR_GetOfficerNote(nickname)		
	if not nickname then
		return nil
	else
		for y = 1, GetNumGuildMembers(1) do
			local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(y);
			if type(tonumber(officernote)) == "number" and name == nickname then
				--table.insert(players, {name, tonumber(officernote), rank})		
				return tonumber(officernote)
			end			
		end
	end
end

function GTDR_Split(inputstr, sep)  
  if sep == nil then
    sep = "%s"
  end
  local t={}
  local _string_find = --[[string.gmatch or]] string.gfind
  local _searchedSplit = _string_find(inputstr, "([^"..sep.."]+)") 
  for str in _searchedSplit do
    table.insert(t, str)
  end
  return t
end

function GTDR_SetZones()		
	local _allZones = {		
		"Onyxia's Lair",--1
		"Molten Core",--2
		"Emerald Sanctum",--3
		"Blackwing Lair",--4
		"Ahn'Qiraj",--5
		"Naxxramas",--6
		"The Barrens",--7 debug only
		"The Upper Necropolis",--8 (Сапфирон и Кель)
		"Tower of Karazhan", -- 9 кара-40
	}
	
  local i = GetGuildInfoText()

  if i then
    if i == "" then
      return nil
    else    	
    	local _string_find = --[[string.gmatch or]] string.find
    	local _, _, _ids = _string_find(i, "=(%d+[,]?.*)=");
			if _ids == nil then
   			DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FFОтсутствует информация о доступных подземельях!|r")
   			return nil
			end
	  	local _asd = GTDR_Split(_ids,",")
		  local _countArray = table.getn(_asd);	 	  		  	
		  for x = 1, _countArray do	  	 	
		   	table.insert(GTDR_AccessInstances, _allZones[tonumber(_asd[x])])	  	 	
	  	end  		  	
		end		
	end
end   

function GTDR_IsZone()
	local _accessInstances = GTDR_AccessInstances	
	for x = 1, table.getn(_accessInstances) do		
		if _accessInstances[x] == GetRealZoneText() then
			return true
		end
	end
	return nil
end

function GTDR_GLOBALS.GTDR_GetDigitsF()
  i = GetGuildInfoText()    
  if i then
    if i == "" then
      return {0, 0}
    else      
	  local _, _, _min, _max = string.find(i, ":(%d+[.]%d+)[,]+(%d+[.]%d+):");
    if _min and _max then
        return {tonumber(_min), tonumber(_max)}
	  else 
		  return {0, 0}
      end
    end
  else 
	  return {0,0}
  end
end

function GTDR_GLOBALS.GTDR_GetCoefRos()
  i = GetGuildInfoText()    
  if i then
    if i == "" then
      return GTDR_DEFAULT_ROS_COEF
    else      
	  local _, _, _min = string.find(i, "@(%d+[.]%d+)@");
    if _min then
        return tonumber(_min)
	  else 
		  return GTDR_DEFAULT_ROS_COEF
      end
    end
  else 
	  return GTDR_DEFAULT_ROS_COEF
  end
end

function GTDR_SetZGAutoneed()  
  local v = this:GetText()    
  if not GTDR_CheckValue(v) then    
    GTDR_ZG_AUTONEED = 1   
  else    
    GTDR_ZG_AUTONEED = 0   
  end
  this:SetText(GTDR_GetTitleValue(GTDR_ZG_AUTONEED)) 
end

function GTDR_SetAQAutoneed()  
  local v = this:GetText()    
  if not GTDR_CheckValue(v) then    
    GTDR_AQ_AUTONEED = 1   
  else    
    GTDR_AQ_AUTONEED = 0   
  end
  this:SetText(GTDR_GetTitleValue(GTDR_AQ_AUTONEED)) 
end

function GTDR_SetKaraAutoneed()  
  local v = this:GetText()    
  if not GTDR_CheckValue(v) then    
    GTDR_KARA_AUTONEED = 1   
  else    
    GTDR_KARA_AUTONEED = 0   
  end
  this:SetText(GTDR_GetTitleValue(GTDR_KARA_AUTONEED)) 
end

function GTDR_SetBMAutoneed()  
  local v = this:GetText()    
  if not GTDR_CheckValue(v) then    
    GTDR_BM_AUTONEED = 1   
  else    
    GTDR_BM_AUTONEED = 0   
  end
  this:SetText(GTDR_GetTitleValue(GTDR_BM_AUTONEED)) 
end

function GTDR_CheckValue(value)  
  if not value or value == "off" then   
    return nil 
  end 
  return true
end

function GTDR_GetTitleValue(value)
  if value == 1 then
    return "on"
  else
    return "off"
  end
end

function GTDR_ShowHelp()
	DEFAULT_CHAT_FRAME:AddMessage("Аддон `gtdroll` гильдии \"Going to Death\". Предназначен для модифицированного рола (MS,OS,Transmg) с учетом progress-points в рейдах на 40 человек.",1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("Список команд:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage(string.format("/rms - рол на мейн-спек (%s).", GTDR_GetMyRoll(nil)),1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ros - рол на офф-спек (1-70).",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rxmg - рол на трансмог (1-50).",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reload - перезагрузка интерфейса.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reset, /resetinstance, /resetinstances - перезагрузка подземелий.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/gtdroll - основное окно аддона.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/gtdroll mini - вызов мини-фрейма.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/gtdroll help - вызов справки.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Об ошибках этого аддона, пожалуйста, сообщите Casta (гильдия \"Going to Death\").",1,1,0);
end

function SlashCmdList.GTDROLL(msg, editbox)	
	if msg == "mini" then  -- мини-фрейм
		FrameRollxml:Show()
		GTDR_ShowMiniFrame = 1 
	elseif msg ==  "help" then -- помощь
		GTDR_ShowHelp()
	else
		GtdRollFrame:Show()	-- основное окно настроек
	end
end

function SlashCmdList.GTDROLLHELP(msg, editbox)	
		GTDR_ShowHelp()	
end

function SlashCmdList.GTDRRMS(msg, editbox)		
	GTDR_Roll(nil)
end

function GTDR_RollMSorOSWithoutPP(isRos)
	if isRos then
		RandomRoll(1,70);
	else
		RandomRoll(1,100);
	end
end 

--МС или ОС ролы
function GTDR_Roll(isRos)
	GTDR_SetZones()
	local _realNameZone = GetRealZoneText()
	local _guildName, _guildRankName, _guildRankIndex = GetGuildInfo("Player");
	local _playerName = UnitName("Player");

	if GTDR_IsZone() then					
		for i = 1, GetNumGuildMembers(1) do
			local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);			
			officernote = tonumber(officernote)	
			if name == _playerName then				
				if type(officernote) == "number" then
					if isRos then -- если бросок на офф-спек, то пп рейдера умножаем на модификатор, указанный в настройках гильд-инфо (по умолчанию 0.5)
						officernote = officernote * GTDR_GLOBALS.GTDR_GetCoefRos()
					end
					local _fDigits = GTDR_GLOBALS.GTDR_GetDigitsF();
					local _min = math.floor(officernote * _fDigits[1])
					local _max = math.floor(officernote * _fDigits[2] + 100)					
					if _min < 1 then
						_min = 1;
					end
					RandomRoll(_min,_max);
				else
					GTDR_RollMSorOSWithoutPP(isRos)
				end
			end
		end	
	else	
		GTDR_AnnoErrorRms()
		GTDR_RollMSorOSWithoutPP(isRos)
	end
end

function GTDR_AnnoErrorRms()
	DEFAULT_CHAT_FRAME:AddMessage("["..GTDR_NAME_ADDON.."]: |cFFFF8080Команда `/rms` работает только в рейдовых подземельях указанных в настройках гильдии!|r");
end

function SlashCmdList.GTDRROS(msg, editbox)
	GTDR_Roll(true)
end

function SlashCmdList.GTDRRXMG(msg, editbox)
	RandomRoll(1,50);
end

--функция авторола NEED в подземельях
function GTDR_AutoRoll(id)
	local  inInstance, instanceType = IsInInstance()
	local inRaidInstance  = (instanceType == 'raid');	
	if inRaidInstance then	
		local _, name, _, quality = GetLootRollItemInfo(id);			
		if (string.find(name , GTDR_HAKKARI_BIJOU) and GTDR_ZG_AUTONEED == 1)
		or (string.find(name , GTDR_COIN) and GTDR_ZG_AUTONEED == 1)
		or (string.find(name , GTDR_SCARAB) and GTDR_AQ_AUTONEED ==1)
		or (name == GTDR_ARCANE_ESSENCE and GTDR_KARA_AUTONEED ==1) then		
			RollOnLoot(id, 1);						
		end
	elseif GetRealZoneText() == THE_BLACK_MORASS and GTDR_BM_AUTONEED == 1 then
		local _, name, _, quality = GetLootRollItemInfo(id);		
		--if string.find(name , GTDR_CORRUPTED_SAND) or name == GTDR_ARCANE_ESSENCE then
		if name == GTDR_CORRUPTED_SAND or name == GTDR_ARCANE_ESSENCE then
			RollOnLoot(id, 1);			
			if StaticPopup1Button1 then 
				StaticPopup1Button1:Click()
			end			
		end		
	end	
end

--авторолы в инстах
local gtdrEvents = CreateFrame("frame")
gtdrEvents:RegisterEvent("START_LOOT_ROLL")
gtdrEvents:RegisterEvent("LOOT_BIND_CONFIRM")
gtdrEvents:RegisterEvent("PLAYER_LOGIN")
gtdrEvents:RegisterEvent("ZONE_CHANGED_NEW_AREA")
gtdrEvents:SetScript("OnEvent", function()	
	if event == "PLAYER_LOGIN" and (GTDR_ShowMiniFrame == 1 or GTDR_ShowMiniFrame == nil) then			
		FrameRollxml:Show()		
	end
	if event == "START_LOOT_ROLL" and not UnitIsDead("player") then
		GTDR_AutoRoll(arg1)
	elseif event == "ZONE_CHANGED_NEW_AREA"	then
		local zoneName = GetRealZoneText()
		--message("Zone Name: "..zoneName)
		if zoneName == THE_BLACK_MORASS and GTDR_BM_AUTONEED == 1 then
			GTDR_AutoLootAnnounce(THE_BLACK_MORASS, "'"..GTDR_CORRUPTED_SAND .. "' и '" .. GTDR_ARCANE_ESSENCE.."'")
		elseif zoneName == ZUL_GURUB and GTDR_ZG_AUTONEED == 1 then
			GTDR_AutoLootAnnounce(ZUL_GURUB, "'"..GTDR_HAKKARI_BIJOU .. "' и '" .. GTDR_COIN.."'")
		end
	end
end)

function GTDR_AutoLootAnnounce(zoneName, textOfLoot)
	DEFAULT_CHAT_FRAME:AddMessage("[GTD"..GTDR_GLOBALS.color_prefix_orange.."Roll|r]: Вы зашли в подземелье '"..zoneName.."' для автолута "..textOfLoot..". Для отключения этой настройки в окне аддона используйте команду: '/gtdroll'.")
end

--блок инициализации фрейма рейтинга для гильдии
GTDR_G_RatingFrame = CreateFrame("Frame", "GTDR_G_RatingFrame", GtdRollFrame)
GTDR_G_RatingFrame:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
	  tile=1, tileSize=32, edgeSize=32, 
	  insets={left=11, right=12, top=12, bottom=11}
})
--заголовок 1
local RaitingGuildHeader = CreateFrame("Frame", "raitingHeader", GTDR_G_RatingFrame)
RaitingGuildHeader:SetPoint("TOP", GTDR_G_RatingFrame, "TOP", 0, 12)
RaitingGuildHeader:SetWidth(350)
RaitingGuildHeader:SetHeight(64)
RaitingGuildHeader:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Header"
})
local RaitingGuildHeaderString = RaitingGuildHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
RaitingGuildHeaderString:SetPoint("CENTER", RaitingGuildHeader, "CENTER", 0, 12)
RaitingGuildHeaderString:SetText("Рейтинг гильдии")
RaitingGuildHeaderString:SetFont("Fonts\\ARIALN.TTF", 12)

--GTDR_G_RatingFrame:SetMovable(true)
GTDR_G_RatingFrame:EnableMouse(true)
GTDR_G_RatingFrame:RegisterForDrag("LeftButton")
--GTDR_G_RatingFrame:SetScript("OnDragStart", function() this:StartMoving() end)
GTDR_G_RatingFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing()end)
GTDR_G_RatingFrame:Hide()

-- Create the scrolling parent frame and size it to fit inside the texture
local ScrollFrame = CreateFrame("ScrollFrame", "scrollFrame", GTDR_G_RatingFrame, "UIPanelScrollFrameTemplate")
ScrollFrame:SetPoint("TOPLEFT", 14, -27)
ScrollFrame:SetPoint("BOTTOM", 0, 14)
ScrollFrame:SetPoint("BOTTOMRIGHT", -37, 4)

local eb = CreateFrame("Editbox", nil, ScrollFrame)
eb:SetMultiLine(true)
eb:SetFontObject(GameFontHighlightSmall)
eb:SetWidth(280)
eb:SetAutoFocus(false)
eb:SetFont("Fonts\\ARIALN.TTF", 11)
scrollFrame:SetScrollChild(eb)
--конец фрейма

--блок инициализации фрейма рейтинга для пати\рейда
GTDR_P_RatingFrame = CreateFrame("Frame", "GTDR_P_RatingFrame", GtdRollFrame)
GTDR_P_RatingFrame:SetBackdrop({
	  bgFile="Interface\\DialogFrame\\UI-DialogBox-Background", 
	  edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", 
	  tile=1, tileSize=32, edgeSize=32, 
	  insets={left=11, right=12, top=12, bottom=11}
})
--заголовок 2
local RaitingRaidHeader = CreateFrame("Frame", "raitingHeader", GTDR_P_RatingFrame)
RaitingRaidHeader:SetPoint("TOP", GTDR_P_RatingFrame, "TOP", 0, 12)
RaitingRaidHeader:SetWidth(420)
RaitingRaidHeader:SetHeight(64)
RaitingRaidHeader:SetBackdrop({
	bgFile = "Interface\\DialogFrame\\UI-DialogBox-Header"
})
local RaitingRaidHeaderString = RaitingRaidHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
RaitingRaidHeaderString:SetPoint("CENTER", RaitingRaidHeader, "CENTER", 0, 12)
RaitingRaidHeaderString:SetText("Рейтинг вашего рейда или группы")
RaitingRaidHeaderString:SetFont("Fonts\\ARIALN.TTF", 12)
--GTDR_P_RatingFrame:SetMovable(true)
GTDR_P_RatingFrame:EnableMouse(true)
GTDR_P_RatingFrame:RegisterForDrag("LeftButton")
--GTDR_P_RatingFrame:SetScript("OnDragStart", function() this:StartMoving() end)
GTDR_P_RatingFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing()end)
GTDR_P_RatingFrame:Hide()
-- Create the scrolling parent frame and size it to fit inside the texture
local scrollFrameParty = CreateFrame("ScrollFrame", "scrollFrameParty", GTDR_P_RatingFrame, "UIPanelScrollFrameTemplate")
scrollFrameParty:SetPoint("TOPLEFT", 14, -27)
scrollFrameParty:SetPoint("BOTTOM", 0, 14)
scrollFrameParty:SetPoint("BOTTOMRIGHT", -37, 4)
local eb2 = CreateFrame("Editbox", nil, scrollFrameParty)
eb2:SetMultiLine(true)
eb2:SetAutoFocus(false)
eb2:SetFontObject(GameFontHighlightSmall)
eb2:SetWidth(280)
eb2:SetFont("Fonts\\ARIALN.TTF", 11)
scrollFrameParty:SetScrollChild(eb2)
--конец фрейма

--открытие или закрытие окна рейтинга гильдии или рейда
function GTDR_OpenRatingScrollFrame(frame, checkRaid)	
	if frame and frame:IsShown() then
		frame:Hide()
	else
		GTDR_GetListRaiting(frame, checkRaid)		
		frame:Show()
	end	
end

--формирование данных рейтинга игроков гильдии
function GTDR_GetListRaiting(frame, checkRaid)
	local formula = GTDR_GLOBALS.GTDR_GetDigitsF()
	local coefRos = GTDR_GLOBALS.GTDR_GetCoefRos()
	local f, _, _ = GameFontNormal:GetFont() 	
	local players = {}
	local textRating = ""
	local tempPlayers = {}

	if not checkRaid then
		frame:SetPoint("TOPLEFT", GtdRollFrame, -329, 0)
	else
		frame:SetPoint("TOPRIGHT", GtdRollFrame, 329, 0)
	end
	frame:SetWidth(335)
	frame:SetHeight(333)
	
	for y = 1, GetNumGuildMembers(1) do		
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(y);
		if not checkRaid and type(tonumber(officernote)) == "number" then
			table.insert(players, {name, tonumber(officernote), rank})--вся гильдия
		elseif checkRaid and type(tonumber(officernote)) == "number" and GTDR_UnitIsRaid(name) then
			table.insert(players, {name, tonumber(officernote), rank})--только рейд
		elseif checkRaid and type(tonumber(officernote)) == "number" and (GTDR_UnitIsParty(name) or (UnitInParty("player") and UnitName("player") == name)) then
			table.insert(players, {name, tonumber(officernote), rank})--только пати
		end	
	end
	
	tempPlayers = players
	if SortField == nil or SortField == "pp" then
		table.sort(tempPlayers, function(a, b) return a[2] < b[2] end)	-- 1pp < 40pp	
	elseif SortField == "name" then
		table.sort(tempPlayers, function(a, b) return a[1] > b[1] end)	-- A > Z
	end
    
	local countString = table.getn(tempPlayers)
	
	eb:SetHeight(countString*13)--установим высоту скролла для гильдии	
	eb2:SetHeight(countString*13)--установим высоту скролла для пати\рейда
	
	local _min, _max
	for x = 1, countString do 
		_min = math.floor(tempPlayers[x][2]*formula[1])
		_minRos = math.floor((tempPlayers[x][2] * coefRos) * formula[1])
		if _min < 1 then
			_min = 1			
		end
		if _minRos < 1 then			
			_minRos = 1
		end
		_max = math.floor(tempPlayers[x][2]*formula[2]+100)
		_maxRos = math.floor((tempPlayers[x][2] * coefRos) * formula[2]+100)

		if SortField == "pp" then 
			textRating = string.format("|cff00ff7f%s|r |cff5e5e5e- - ->|r %s (%s)   |cffFFF569(%s-%s)|r / |cffaaaaaa(%s-%s)|r\r", tempPlayers[x][2], tempPlayers[x][1], tempPlayers[x][3], tostring(_min), tostring(_max), tostring(_minRos), tostring(_maxRos)) .. textRating
		elseif SortField == "name" then
			textRating = string.format("|cff00ff7f%s (%s)|r |cff5e5e5e<- - -|r %s   |cffFFF569(%s-%s)|r / |cffaaaaaa(%s-%s)|r\r", tempPlayers[x][1], tempPlayers[x][3], tempPlayers[x][2], tostring(_min), tostring(_max), tostring(_minRos), tostring(_maxRos)) .. textRating			
		end		
	end

	if SortField == "pp" then
		SortField = "name"
	else 
		SortField = "pp"
	end
	
	--запись рейтинга во фрейм скроллинга
	if not checkRaid then
		eb:SetText(textRating)
	else
		eb2:SetText(textRating)
	end		
end

function GTDR_UnitIsRaid(name)
	for i = 1, GetNumRaidMembers() do
		local unit = 'raid' .. i;
		local who = UnitName(unit);
		if who == name then
			return true
		end					
	end
	return nil			
end

function GTDR_UnitIsParty(name)
	for i = 0, GetNumPartyMembers() do
		local unit = 'party' .. i;
		local who = UnitName(unit);
		if who == name then
			return true
		end					
	end
	return nil			
end

function GTDR_GLOBALS.GTDR_ButtonRollOnLoad(text, this)	
	GameTooltip:SetOwner(this, "ANCHOR_CURSOR"); 
  --GameTooltip:ClearLines();
  if text then
  	GameTooltip:SetText(text, 1,1,1,0.75)  
	end
  this:SetFont("Fonts\\ARIALN.TTF", 11)
  GameTooltip:Show()
end

function GTDR_GLOBALS.GTDR_ButtonRollOnLeave()
	 GameTooltip:Hide() 
end

function GTDR_HelpTextCloseMiniFrame()
	DEFAULT_CHAT_FRAME:AddMessage("GTD"..GTDR_GLOBALS.color_prefix_orange.."ROLL|r]: Вы скрыли окно мини-фрейма и он больше не покажется. Чтобы его включить заново, используйте команду |cffffcc00/gtdroll mini|r",1,1,1)
    
end