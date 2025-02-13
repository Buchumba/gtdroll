--блок мониторинга бросков

if not GTDR_GLOBALS then GTDR_GLOBALS = {} end

local rollTable = {}
local sortedTable = {}
local yellowColor= "|cffffcc00"
local redColor = "|cffff6633"
local greenColor = "|cff99ff33"
local grayColor = "|cffcccccc"
local coefRos = GTDR_GLOBALS.GTDR_GetCoefRos()
local fDigits = GTDR_GLOBALS.GTDR_GetDigitsF()

-- Создаем основной фрейм для мониторинга ролов
local GTDR_FrameRollHundler = CreateFrame("Frame")
GTDR_FrameRollHundler:RegisterEvent("CHAT_MSG_SYSTEM")
-- Функция для обработки событий ролов
GTDR_FrameRollHundler:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        local message = arg1
        -- Проверяем, содержит ли сообщение информацию о броске
        local _,_,player, roll, minRoll, maxRoll = string.find(message, "(%a+) rolls (%d+) %((%d+)%-(%d+)%)")
        if player and roll then
            if not GTDR_TableRollFrame:IsShown() and GTDR_ShowRollTracker then
                GTDR_TableRollFrame:Show()
            end
            -- Добавляем информацию о броске в таблицу
            rollTable[player] = {tonumber(roll), tonumber(minRoll), tonumber(maxRoll)}
            -- Обновляем отображение таблицы
            GTDR_UpdateRollTable()
        end
        UpdateTableText()
    end
end)

-- Функция для обновления таблицы бросков
function GTDR_UpdateRollTable()
    -- Очищаем предыдущие данные 
    for i = 1, table.getn(rollTable) do
        message(rollTable[i])
        rollTable[i] = nil
    end
    -- Сортируем таблицу по значению броска
    sortedTable = {}
    for player, rollInfo in pairs(rollTable) do
        table.insert(sortedTable, {player = player, roll = rollInfo[1], minRoll = rollInfo[2], maxRoll = rollInfo[3]})
    end
    table.sort(sortedTable, function(a, b) return a.roll > b.roll end)    
end

-- Создаем фрейм для отображения таблицы
GTDR_TableRollFrame = CreateFrame("Frame", "_GTDR_TableRollFramee", UIParent)
GTDR_TableRollFrame:SetMovable(true)
GTDR_TableRollFrame:EnableMouse(true)
GTDR_TableRollFrame:RegisterForDrag("LeftButton")
GTDR_TableRollFrame:SetScript("OnDragStart", function() this:StartMoving() end)
GTDR_TableRollFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing()end)
GTDR_TableRollFrame:SetWidth(230)
GTDR_TableRollFrame:SetHeight(200)
GTDR_TableRollFrame:SetPoint("CENTER", UIParent, "TOP", 0,-200)
GTDR_TableRollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})

if not GTDR_ShowRollTracker then
    GTDR_TableRollFrame:Hide()
end

--заголовок 1
local GTDR_TableRollFrameHeader = CreateFrame("Frame", "GTDR_TableRollFrameHeader", GTDR_TableRollFrame)
GTDR_TableRollFrameHeader:SetPoint("TOP", GTDR_TableRollFrame, "TOP", 0, 12)
GTDR_TableRollFrameHeader:SetWidth(350)
GTDR_TableRollFrameHeader:SetHeight(64)
GTDR_TableRollFrameHeader:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Header"
})
-- Текст для отображения таблицы
local GTDR_TableRollFrameHeaderText = GTDR_TableRollFrameHeader:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
GTDR_TableRollFrameHeaderText:SetPoint("CENTER", GTDR_TableRollFrameHeader,"CENTER",0,12)
GTDR_TableRollFrameHeaderText:SetText("GTD"..tostring(GTDR_GLOBALS.color_prefix_orange).."ROLL|r: Таблица бросков")

local GTDR_TableScrollFrame = CreateFrame("ScrollFrame", "GTDR_TableScrollFrame", GTDR_TableRollFrame, "UIPanelScrollFrameTemplate")
GTDR_TableScrollFrame:SetPoint("TOPLEFT", 14, -27)
GTDR_TableScrollFrame:SetPoint("BOTTOM", 0, 30)
GTDR_TableScrollFrame:SetPoint("BOTTOMRIGHT", -37, 4)

local eb4 = CreateFrame("Editbox", nil, GTDR_TableScrollFrame)
eb4:SetMultiLine(true)
eb4:SetFontObject(GameFontHighlightSmall)
eb4:SetWidth(230)
eb4:SetAutoFocus(false)
eb4:SetHeight(450)
GTDR_TableScrollFrame:SetScrollChild(eb4)

--кнопка очистки окна ролов
local GTDR_ClearButton = CreateFrame("Button", "GTDR_ClearButton", GTDR_TableRollFrame, "GameMenuButtonTemplate")
GTDR_ClearButton:SetWidth(80)
GTDR_ClearButton:SetHeight(18)
GTDR_ClearButton:SetPoint("BOTTOM", GTDR_TableRollFrame, "BOTTOM", 0, 12)
GTDR_ClearButton:SetText("Очистить")

--кнопка закрытия окна ролов
local GTDR_CloseButton = CreateFrame("Button", "GTDR_CloseButton", GTDR_TableRollFrame, "UIPanelCloseButton")
GTDR_CloseButton:SetWidth(30)
GTDR_CloseButton:SetHeight(30)
GTDR_CloseButton:SetPoint("TOP", GTDR_TableRollFrame, "TOPRIGHT", -18, 6)

GTDR_ClearButton:SetScript("OnClick", function(self, button, down)
    rollTable = {}
    sortedTable = {}  
    eb4:SetText("")  
end)

GTDR_CloseButton:SetScript("OnEnter", function(self, button, down)
   GTDR_GLOBALS.GTDR_ButtonRollOnLoad("Закрыть окно до следующих бросков") 
end)
GTDR_CloseButton:SetScript("OnLeave", function(self, button, down)
   GTDR_GLOBALS.GTDR_ButtonRollOnLeave()
end)

-- Функция для обновления текста таблицы ролов
function UpdateTableText()
    local text = ""
    local _count = table.getn(sortedTable) or 1

    for i, data in ipairs(sortedTable) do
        local _colorText, _typeRoll = SetColorRoll(data.player, data.minRoll, data.maxRoll)
        text = text .. string.format("%s%d. %s: %d (%d-%d)|r %s\n", _colorText, i, data.player, data.roll, data.minRoll, data.maxRoll, _typeRoll)
    end    
    eb4:SetText(text)
end

function SetColorRoll(nickname, _rollMin, _rollMax)
    local _note = GTDR_GLOBALS.GTDR_GetOfficerNote(nickname)
    local _min, _max
    if _note then
        _min = math.floor(_note * fDigits[1])
        _max = math.floor(_note * fDigits[2] + 100)
    else
        _min = 1
        _max = 100
    end    
    if _min < 1 then
        _min = 1;
    end
    if _rollMin == _min and _rollMax == _max and _note then
        return greenColor, "[ms]"
    elseif _note then
        local _minRos = math.floor((_note * coefRos) * fDigits[1])
        local _maxRos = math.floor((_note * coefRos) * fDigits[2] + 100)
        if _minRos < 1 then
            _minRos = 1;
        end
        if _rollMin == _minRos and _rollMax == _maxRos then
            return yellowColor, "[os]"
        elseif (_rollMin ~= _minRos and _rollMin >= 1 ) and (_rollMax ~= _maxRos and _rollMax > 100) then
            GTDR_TableRollFrame:SetWidth(300)
            eb4:SetWidth(300)
            return redColor, "[ ! ], |cffaaaaaaMS: ".. _min.."-".._max..", OS: ".._minRos.."-".._maxRos.."|r"            
        end    
    end
    return "|cffffffff", ""
end
