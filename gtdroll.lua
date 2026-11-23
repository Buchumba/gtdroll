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

-- ====================================================================== --
-- ====== БЛОК ИНИЦИАЛИЗАЦИИ ГИЛЬДЕЙСКОГО РОСТЕРА ПРИ ЗАХОДЕ В ИГРУ ===== --
-- ====================================================================== --
local GTDR_InitFrame = CreateFrame("Frame")
GTDR_InitFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
GTDR_InitFrame:RegisterEvent("PLAYER_LOGIN")
GTDR_InitFrame:SetScript("OnEvent", function()
    -- Можно дополнительно принудительно запросить обновление гильдии при входе
    if event == "PLAYER_LOGIN" then
        GuildRoster() 
    end

    -- Когда данные гильдии подгрузились (GetNumGuildMembers(1) станет больше 0)
    if event == "GUILD_ROSTER_UPDATE" then
        local count = GetNumGuildMembers(1)
        if count > 0 then
            -- Данные загружены! Выполняем инициализацию
            if GTDR_GLOBALS and GTDR_GLOBALS.init then
                GTDR_GLOBALS.init()
            end
            -- Отписываемся от события, чтобы оно не срабатывало лишний раз при каждом изменении в гильдии
            this:UnregisterEvent("GUILD_ROSTER_UPDATE")
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

-- Определение локализации клиента (enUS / ruRU и др.)
local locale = GetLocale()
local isRU = (locale == "ruRU")

-- Двуязычные константы предметов и зон
local ITEMS = {
    ArcaneEssence = { en = "Arcane Essence", ru = "Arcane Essence" },
    HakkariBijou  = { en = "Hakkari Bijou",  ru = "брелок Хаккари" },
    CorruptedSand = { en = "Corrupted Sand", ru = "Corrupted Sand" },
    Coin          = { en = "Coin",           ru = "Монета" },
    Scarab        = { en = "Scarab",         ru = "Скарабей" },
}

local ZONES = {
    Onyxia         = { en = "Onyxia's Lair",        ru = "Логово Ониксии" },
    MoltenCore     = { en = "Molten Core",          ru = "Огненные Недра" },
    EmeraldSanctum = { en = "Emerald Sanctum",      ru = "Изумрудное Святилище" },
    BlackwingLair  = { en = "Blackwing Lair",       ru = "Логово Крыла Тьмы" },
    AhnQiraj       = { en = "Ahn'Qiraj",            ru = "Храм Ан'Киража" },
    Naxxramas      = { en = "Naxxramas",            ru = "Наксрамас" },
    Barrens        = { en = "The Barrens",          ru = "Степные земли" },
    UpperNecropolis= { en = "The Upper Necropolis", ru = "Верхний некрополь" },
    Karazhan       = { en = "Tower of Karazhan",    ru = "Башня Каражана" },
    ZulGurub       = { en = "Zul'Gurub",            ru = "Зул'Гуруб" },
    AQ20           = { en = "Ruins of Ahn'Qiraj",   ru = "Руины Ан'Киража" },
    BlackMorass    = { en = "The Black Morass",     ru = "Черные Топи" },
}

THE_BLACK_MORASS = ZONES.BlackMorass
ZUL_GURUB = ZONES.ZulGurub
AQ20 = ZONES.AQ20

GTDR_ARCANE_ESSENCE = ITEMS.ArcaneEssence
GTDR_HAKKARI_BIJOU  = ITEMS.HakkariBijou
GTDR_CORRUPTED_SAND = ITEMS.CorruptedSand
GTDR_COIN           = ITEMS.Coin
GTDR_SCARAB         = ITEMS.Scarab

GTDR_NAME_ADDON = "GTD"..GTDR_GLOBALS.color_prefix_orange.."ROLL|r"
GTDR_ADDON_VER = "1.2"
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
	fieldAutoNeedZG:SetText(string.format("Автосбор |cffffffff%s|r и |cffffffff%s|r в ZG:", GTDR_HAKKARI_BIJOU[locale == "ruRU" and "ru" or "en"], GTDR_COIN[locale == "ruRU" and "ru" or "en"]))
	fieldAutoNeedAQ:SetText(string.format("Автосбор |cffffffff%s|r в AQ20:", GTDR_SCARAB[locale == "ruRU" and "ru" or "en"]))
	fieldAutoNeedKara:SetText(string.format("Автосбор |cffffffff%s|r в Kara-10:", GTDR_ARCANE_ESSENCE[locale == "ruRU" and "ru" or "en"]))
	fieldAutoNeedCS_BM:SetText(string.format("Автосбор |cffffffff%s|r в Black Morass:", GTDR_CORRUPTED_SAND[locale == "ruRU" and "ru" or "en"]))	
	fieldAutoNeedAE_BM:SetText(string.format("Автосбор |cffffffff%s|r в Black Morass:", GTDR_ARCANE_ESSENCE[locale == "ruRU" and "ru" or "en"]))	
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
	GTDR_IsCS_BM:SetText(GTDR_GetTitleValue(GTDR_CSBM_AUTONEED))
	GTDR_IsAE_BM:SetText(GTDR_GetTitleValue(GTDR_AEBM_AUTONEED))
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
	local _officerNote = GTDR_GLOBALS.GTDR_GetOfficerNote(UnitName("player")) or 0
	local _pp = math.floor(_officerNote) 
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
  local _string_find = string.gfind
  local _searchedSplit = _string_find(inputstr, "([^"..sep.."]+)") 
  for str in _searchedSplit do
    table.insert(t, str)
  end
  return t
end

function GTDR_SetZones()		
	-- Сохраняем числовые ключи 1-11 для совместимости с guild info
	local _allZones = {		
		ZONES.Onyxia,         -- 1
		ZONES.MoltenCore,     -- 2
		ZONES.EmeraldSanctum, -- 3
		ZONES.BlackwingLair,  -- 4
		ZONES.AhnQiraj,       -- 5
		ZONES.Naxxramas,      -- 6
		ZONES.Barrens,        -- 7 debug only
		ZONES.UpperNecropolis,-- 8 (Сапфирон и Кель)
		ZONES.Karazhan,       -- 9 кара-40
		ZONES.ZulGurub,       -- 10
		ZONES.AQ20,           -- 11
	}
	
  local i = GetGuildInfoText()

  if i then
    if i == "" then
      return nil
    else    	
    	local _string_find = string.find
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
	local currentZone = GetRealZoneText()
	for x = 1, table.getn(_accessInstances) do		
		local zoneData = _accessInstances[x]
		if type(zoneData) == "table" then
			if zoneData.en == currentZone or zoneData.ru == currentZone then
				return true
			end
		elseif zoneData == currentZone then
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

function GTDR_SetCSBMAutoneed()  
  local v = this:GetText()    
  if not GTDR_CheckValue(v) then    
    GTDR_CSBM_AUTONEED = 1   
  else    
    GTDR_CSBM_AUTONEED = 0   
  end
  this:SetText(GTDR_GetTitleValue(GTDR_CSBM_AUTONEED)) 
end

function GTDR_SetAEBMAutoneed()  
  local v = this:GetText()    
  if not GTDR_CheckValue(v) then    
    GTDR_AEBM_AUTONEED = 1   
  else    
    GTDR_AEBM_AUTONEED = 0   
  end
  this:SetText(GTDR_GetTitleValue(GTDR_AEBM_AUTONEED)) 
end

function GTDR_CheckValue(value)  
  if not value or value == "off" then   
    return nil 
  end 
  return true
end

function GTDR_GetTitleValue(value)
  if value == 1 then
    return "|cff84ff00on|r"
  else
    return "off"
  end
end

function GTDR_ShowHelp()
	DEFAULT_CHAT_FRAME:AddMessage("Аддон `gtdroll` гильдии \"Going to Death\". Предназначен для модифицированного рола (MS,OS,Transmg) с учетом progress-points в рейдах на 40 человек.",1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("Список команд:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage(string.format("/rms - рол на мейн-спек (%s).", GTDR_GetMyRoll(nil)),1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ros - рол на офф-спек (1-99).",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rxmg - рол на трансмог (1-98).",1,1,1);
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
		RandomRoll(1,99);
	else
		RandomRoll(1,100);
	end
end 

--МС или ОС ролы
function GTDR_Roll(isRos)
	GTDR_SetZones()
	local _guildName, _guildRankName, _guildRankIndex = GetGuildInfo("Player");
	local _playerName = UnitName("Player");  
	if GTDR_IsZone() then		
		for i = 1, GetNumGuildMembers(1) do			
			local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(i);
			officernote = tonumber(officernote)	
			if name == _playerName then				
				if type(officernote) == "number" then
					if isRos then
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
	RandomRoll(1,98);
end

-- Приводим латиницу и кириллицу к нижнему регистру для поиска предметов.
local GTDR_CYRILLIC_LOWER = {
    ["А"] = "а", ["Б"] = "б", ["В"] = "в", ["Г"] = "г",
    ["Д"] = "д", ["Е"] = "е", ["Ё"] = "ё", ["Ж"] = "ж",
    ["З"] = "з", ["И"] = "и", ["Й"] = "й", ["К"] = "к",
    ["Л"] = "л", ["М"] = "м", ["Н"] = "н", ["О"] = "о",
    ["П"] = "п", ["Р"] = "р", ["С"] = "с", ["Т"] = "т",
    ["У"] = "у", ["Ф"] = "ф", ["Х"] = "х", ["Ц"] = "ц",
    ["Ч"] = "ч", ["Ш"] = "ш", ["Щ"] = "щ", ["Ъ"] = "ъ",
    ["Ы"] = "ы", ["Ь"] = "ь", ["Э"] = "э", ["Ю"] = "ю",
    ["Я"] = "я",
}

local function GTDR_LowerString(value)
    if not value then return nil end

    -- string.lower обрабатывает латиницу, а кириллицу переводим отдельно.
    value = string.lower(value)

    for upper, lower in pairs(GTDR_CYRILLIC_LOWER) do
        value = string.gsub(value, upper, lower)
    end

    return value
end

-- Универсальная вспомогательная функция проверки совпадения предмета (для EN и RU)
local function ItemMatch(itemName, itemTable)
    if not itemName then return false end

    local lowerItemName = GTDR_LowerString(itemName)
    local lowerEn = GTDR_LowerString(itemTable.en)
    local lowerRu = GTDR_LowerString(itemTable.ru)

    return (lowerEn and string.find(lowerItemName, lowerEn, 1, true))
        or (lowerRu and string.find(lowerItemName, lowerRu, 1, true))
        or false
end

local function ExactItemMatch(itemName, itemTable)
    if not itemName then return false end

    local lowerItemName = GTDR_LowerString(itemName)
    return (lowerItemName == GTDR_LowerString(itemTable.en)
        or lowerItemName == GTDR_LowerString(itemTable.ru))
end

local function ZoneMatch(zoneName, zoneTable)
    if not zoneName then return false end
    return (zoneName == zoneTable.en or zoneName == zoneTable.ru)
end

--функция авторола NEED в подземельях
function GTDR_AutoRoll(id)
	local inInstance, instanceType = IsInInstance()
	local inRaidInstance  = (instanceType == 'raid');	
	if inRaidInstance then	
		local _, name, _, quality = GetLootRollItemInfo(id);			
		if (ItemMatch(name, GTDR_HAKKARI_BIJOU) and GTDR_ZG_AUTONEED == 1)
		or (ItemMatch(name, GTDR_COIN) and GTDR_ZG_AUTONEED == 1)
		or (ItemMatch(name, GTDR_SCARAB) and GTDR_AQ_AUTONEED == 1)
		or (ExactItemMatch(name, GTDR_ARCANE_ESSENCE) and GTDR_KARA_AUTONEED == 1) then		
			RollOnLoot(id, 1);						
		end
	elseif ZoneMatch(GetRealZoneText(), THE_BLACK_MORASS) then
		local _, name, _, quality = GetLootRollItemInfo(id);		
		if ExactItemMatch(name, GTDR_CORRUPTED_SAND) and GTDR_CSBM_AUTONEED == 1 then
			RollOnLoot(id, 1);			
			if StaticPopup1Button1 then 
				StaticPopup1Button1:Click()
			end			
		elseif ExactItemMatch(name, GTDR_ARCANE_ESSENCE) and GTDR_AEBM_AUTONEED == 1 then
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
		local currentZoneName = isRU and ZONES.BlackMorass.ru or ZONES.BlackMorass.en
		local zgZoneName = isRU and ZONES.ZulGurub.ru or ZONES.ZulGurub.en
		
		if ZoneMatch(zoneName, THE_BLACK_MORASS) and GTDR_BM_AUTONEED == 1 then
			local sandName = isRU and GTDR_CORRUPTED_SAND.ru or GTDR_CORRUPTED_SAND.en
			local arcaneName = isRU and GTDR_ARCANE_ESSENCE.ru or GTDR_ARCANE_ESSENCE.en
			GTDR_AutoLootAnnounce(zoneName, "'"..sandName .. "' и '" .. arcaneName.."'")
		elseif ZoneMatch(zoneName, ZUL_GURUB) and GTDR_ZG_AUTONEED == 1 then
			local bijouName = isRU and GTDR_HAKKARI_BIJOU.ru or GTDR_HAKKARI_BIJOU.en
			local coinName = isRU and GTDR_COIN.ru or GTDR_COIN.en
			GTDR_AutoLootAnnounce(zoneName, "'"..bijouName .. "' и '" .. coinName.."'")
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

GTDR_G_RatingFrame:EnableMouse(true)
GTDR_G_RatingFrame:RegisterForDrag("LeftButton")
GTDR_G_RatingFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing()end)
GTDR_G_RatingFrame:Hide()

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

GTDR_P_RatingFrame:EnableMouse(true)
GTDR_P_RatingFrame:RegisterForDrag("LeftButton")
GTDR_P_RatingFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing()end)
GTDR_P_RatingFrame:Hide()

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

function GTDR_OpenRatingScrollFrame(frame, checkRaid)	
	if frame and frame:IsShown() then
		frame:Hide()
	else
		GTDR_GetListRaiting(frame, checkRaid)		
		frame:Show()
	end	
end

function GTDR_GetListRaiting(frame, checkRaid)
	local formula = GTDR_GLOBALS.GTDR_GetDigitsF()
	local coefRos = GTDR_GLOBALS.GTDR_GetCoefRos()
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
			table.insert(players, {name, tonumber(officernote), rank})
		elseif checkRaid and type(tonumber(officernote)) == "number" and GTDR_UnitIsRaid(name) then
			table.insert(players, {name, tonumber(officernote), rank})
		elseif checkRaid and type(tonumber(officernote)) == "number" and (GTDR_UnitIsParty(name) or (UnitInParty("player") and UnitName("player") == name)) then
			table.insert(players, {name, tonumber(officernote), rank})
		end	
	end
	
	tempPlayers = players
	if SortField == nil or SortField == "pp" then
		table.sort(tempPlayers, function(a, b) return a[2] < b[2] end)	
	elseif SortField == "name" then
		table.sort(tempPlayers, function(a, b) return a[1] > b[1] end)	
	end
    
	local countString = table.getn(tempPlayers)
	
	eb:SetHeight(countString*13)	
	eb2:SetHeight(countString*13)	
	
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