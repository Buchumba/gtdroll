--аддон для ролов на MS, OS, Трансмог
--По всем вопросам аддона обращайтесь к Casta\Madarra ("Going to Death" | WOW-Turtle)

SLASH_GTDROLL1 = "/gtdroll";--help
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
local text_access_error = "К сожалению у вас нет доступа для просмотра офицерской заметки. ГМ гильдии может предоставить эти права."
local color_prefix = "|cffffffff"

--инициализация списка доступных рейдов
GTDR_AccessInstances = {}

function GTD_Frame_OnLoad()	
	this:RegisterEvent("VARIABLES_LOADED")	
	NickNameField:SetText(UnitName("player"))	  
	if CanViewOfficerNote() then
		GTDR_SetFieldMyPP()
		GTDR_SetFieldMyRoll()
		GTDR_SetFieldFormula()
	else
		FieldAccessError:SetText(text_access_error)
	end
end

function GTDR_GetMyRoll()
	local _fDigits = GTDR_GetDigitsF();
	local _note = GTDR_GetOfficerNote(UnitName("player"))
	local _min = math.floor(_note * _fDigits[1])
	local _max = math.floor(_note * _fDigits[2] + 100)					
	if _min < 1 then
		_min = 1;
	end
	return _min .. "-".._max
end

function GTDR_SetFieldMyPP()
	local _myName = UnitName("player")   	
	local _text = GTDR_GetOfficerNote(_myName)	
	FieldProgressPoints:SetText("Мои progress-points: ".. color_prefix .. _text.."|r")
end

function GTDR_SetFieldMyRoll()
	FieldRollInterval:SetText("Мой интервал рола: ".. color_prefix .. GTDR_GetMyRoll() .. "|r")
end

function GTDR_SetFieldFormula()
	local _pp = math.floor(GTDR_GetOfficerNote(UnitName("player")))
	local _text = string.format("%d*0.25 - %d*0.25+100", _pp, _pp)
	FieldFormula:SetText("Расчет по формуле: " .. color_prefix .. _text  .. "|r")
end


function GTDR_GetOfficerNote(nickname)		
	for y = 1, GetNumGuildMembers(1) do
		local name, rank, rankIndex, level, class, zone, note, officernote, online, status = GetGuildRosterInfo(y);
		if type(tonumber(officernote)) == "number" and name == nickname then
			--table.insert(players, {name, tonumber(officernote), rank})		
			return tonumber(officernote)
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
		"Tel'Abim",--7 debug only
		"The Upper Necropolis"--8 (Сапфирон и Кель)
	}
	
  local i = GetGuildInfoText()

  if i then
    if i == "" then
      return nil
    else    	
    	local _string_find = --[[string.gmatch or]] string.find
    	local _, _, _ids = _string_find(i, "[=]+(%d+[,]+.*)");
			if _ids == nil then
  			_, _, _ids = _string_find(i, "[=]+(%d+)");
  			if _ids == nil then
   				DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FFОтсутствует информация о доступных подземельях!|r")
   				return nil
  			end
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

function GTDR_GetDigitsF()
  i = GetGuildInfoText()    
  if i then
    if i == "" then
      return {0, 0}
    else      
	  local _, _, _min, _max = string.find(i, "[:](%d+[.]%d+)[,]+(%d+[.]%d+)");
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

--помощь
function SlashCmdList.GTDROLL(msg, editbox)
	gtdrollFrame:Show()
	DEFAULT_CHAT_FRAME:AddMessage("Аддон `gtdroll` гильдии \"Going to Death\". Предназначен для модифицированного рола (MS,OS,Transmg) с учетом progress-points в рейдах на 40 человек.",1,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("Список команд:",0,1,0);
	DEFAULT_CHAT_FRAME:AddMessage("/rms - рол на мейн-спек.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/ros - рол на офф-спек (1-70).",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/rxmg - рол на трансмог (1-50).",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reload - перезагрузка интерфейса.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/reset, /resetinstance, /resetinstances - перезагрузка подземелий.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("/gtdroll - вызов справки.",1,1,1);
	DEFAULT_CHAT_FRAME:AddMessage("Об ошибках этого аддона, пожалуйста, сообщите Casta (гильдия \"Going to Death\").",1,1,0);
end

function SlashCmdList.GTDRRMS(msg, editbox)		
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
					local _fDigits = GTDR_GetDigitsF();
					local _min = math.floor(officernote * _fDigits[1])
					local _max = math.floor(officernote * _fDigits[2] + 100)					
					if _min < 1 then
						_min = 1;
					end
					RandomRoll(_min,_max);
				else
					RandomRoll(1,100);
				end
			end
		end
	elseif _guildName == _guild and not GTDR_IsZone() then
		DEFAULT_CHAT_FRAME:AddMessage("|cFFFF8080Команда `/rms` работает только в рейдовых подземельях указанных в настройках гильдии!|r");
		RandomRoll(1,100);	
	else		 
		RandomRoll(1,100);
	end
end

function SlashCmdList.GTDRROS(msg, editbox)
	RandomRoll(1,70);
end

function SlashCmdList.GTDRRXMG(msg, editbox)
	RandomRoll(1,50);
end

--функция авторола
function GTDR_AutoRoll(id)
	local  inInstance, instanceType = IsInInstance()
	notInInstance   = (instanceType == 'none');
	inPartyInstance = (instanceType == 'party');
	inRaidInstance  = (instanceType == 'raid');
	inArenaInstance = (instanceType == 'arena');
	inPvPInstance   = (instanceType == 'pvp');
	isLeader = IsRaidLeader();
	class = UnitClass("Player");
	
	RollReturn = function()
		local txt = ""
		if isLeader then
			txt = "NEED"
		elseif not isLeader then
			txt = "PASS"
		end
		return txt
	end
	if inRaidInstance then	
		local _, name, _, quality = GetLootRollItemInfo(id);
		if string.find(name ,"Hakkari Bijou") or string.find(name ,"Coin") or string.find(name ,"Scarab") then
			RollOnLoot(id, 1);
			local _, _, _, hex = GetItemQualityColor(quality)
			DEFAULT_CHAT_FRAME:AddMessage("GTD: Auto NEED "..hex..GetLootRollItemLink(id))
			return
		end
	elseif GetRealZoneText() == "The Black Morass" then
		local _, name, _, quality = GetLootRollItemInfo(id);
		local nameItem = "Corrupted Sand"
		if string.find(name , nameItem) then
			RollOnLoot(id, 1);
			ConfirmBindOnUse();
			ConfirmLootRoll(id, 1);
			local _, _, _, hex = GetItemQualityColor(quality)
			DEFAULT_CHAT_FRAME:AddMessage("GTD: Auto NEED "..hex..GetLootRollItemLink(id))
			return
		end		
	end	
end

--авторолы в инстах
local gtdrEvents = CreateFrame("frame")
gtdrEvents:RegisterEvent("START_LOOT_ROLL")
gtdrEvents:SetScript("OnEvent", function()
	if event == "START_LOOT_ROLL" then
		GTDR_AutoRoll(arg1)
	end
end)
