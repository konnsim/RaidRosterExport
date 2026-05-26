local ADDON_NAME = "RaidRosterExport"

local function csvEscape(value)
  value = tostring(value or "")

  if value:find('[,"\n]') then
    value = '"' .. value:gsub('"', '""') .. '"'
  end

  return value
end

local function normaliseRealmName(name, realm)
  if not name or name == "" then
    return nil
  end

  -- GetRaidRosterInfo commonly returns Name-Realm already.
  if name:find("%-") then
    return name
  end

  if realm and realm ~= "" then
    return name .. "-" .. realm:gsub("%s+", "")
  end

  local playerRealm = GetRealmName and GetRealmName() or nil

  if playerRealm and playerRealm ~= "" then
    return name .. "-" .. playerRealm:gsub("%s+", "")
  end

  return name
end

local function buildCsv(rows)
  local lines = {}

  for _, row in ipairs(rows) do
    local escaped = {}

    for i, value in ipairs(row) do
      escaped[i] = csvEscape(value)
    end

    table.insert(lines, table.concat(escaped, ","))
  end

  return table.concat(lines, "\n")
end

local function buildRosterCsv(dateOverride)
  local exportDate =
      dateOverride and dateOverride:match("^%d%d%d%d/%d%d/%d%d$")
      and dateOverride
      or date("%Y/%m/%d")

  local exportTime = date("%H:%M:%S")

  local currentPlayerName, currentPlayerRealm = UnitName("player")
  local exportedBy = normaliseRealmName(currentPlayerName, currentPlayerRealm) or ""

  local rows = {
    { "type",          "raid-attendance" },
    { "date",          exportDate },
    { "time",          exportTime },
    { "source",        ADDON_NAME },
    { "formatVersion", "1" },
    { "exportedBy",    exportedBy },
    {},
    { "player",        "class",          "group" },
  }

  local players = {}

  if IsInRaid and IsInRaid() then
    local count = GetNumGroupMembers()

    for i = 1, count do
      local name, _, subgroup, _, _, classFileName = GetRaidRosterInfo(i)

      if name then
        table.insert(players, {
          player = normaliseRealmName(name),
          class = classFileName or "",
          group = subgroup or "",
        })
      end
    end
  elseif IsInGroup and IsInGroup() then
    local playerName, playerRealm = UnitName("player")
    local _, playerClass = UnitClass("player")

    table.insert(players, {
      player = normaliseRealmName(playerName, playerRealm),
      class = playerClass or "",
      group = 1,
    })

    local partyCount = GetNumSubgroupMembers()

    for i = 1, partyCount do
      local unit = "party" .. i
      local name, realm = UnitName(unit)
      local _, classFileName = UnitClass(unit)

      if name then
        table.insert(players, {
          player = normaliseRealmName(name, realm),
          class = classFileName or "",
          group = 1,
        })
      end
    end
  else
    print("|cffff5555RaidRosterExport: You are not in a raid or party.|r")
    return nil
  end

  table.sort(players, function(a, b)
    local groupA = tonumber(a.group) or 99
    local groupB = tonumber(b.group) or 99

    if groupA == groupB then
      return tostring(a.player) < tostring(b.player)
    end

    return groupA < groupB
  end)

  for _, player in ipairs(players) do
    table.insert(rows, {
      player.player,
      player.class,
      player.group,
    })
  end

  return buildCsv(rows)
end

local exportFrame

local function showCopyBox(text)
  if not text or text == "" then
    return
  end

  if not exportFrame then
    local frame = CreateFrame("Frame", "RaidRosterExportFrame", UIParent, "BackdropTemplate")
    frame:SetSize(700, 500)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true,
      tileSize = 32,
      edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", 0, -16)
    title:SetText("Raid Attendance Export")

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 24, -50)
    scrollFrame:SetPoint("BOTTOMRIGHT", -44, 54)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(true)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(610)
    editBox:SetScript("OnEscapePressed", function()
      frame:Hide()
    end)

    scrollFrame:SetScrollChild(editBox)

    local copyHint = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    copyHint:SetPoint("BOTTOMLEFT", 26, 28)
    copyHint:SetText("Ctrl+C to copy. Esc or Close to dismiss.")

    local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    closeButton:SetSize(90, 24)
    closeButton:SetPoint("BOTTOMRIGHT", -24, 24)
    closeButton:SetText("Close")
    closeButton:SetScript("OnClick", function()
      frame:Hide()
    end)

    frame.editBox = editBox
    exportFrame = frame
  end

  exportFrame.editBox:SetText(text)
  exportFrame.editBox:HighlightText()
  exportFrame.editBox:SetFocus()
  exportFrame:Show()
end

local function exportRoster(msg)
  local dateOverride = msg and msg:match("(%d%d%d%d/%d%d/%d%d)") or nil
  local csv = buildRosterCsv(dateOverride)

  if csv then
    showCopyBox(csv)
    print("|cff00ff00RaidRosterExport: attendance CSV generated.|r")
  end
end

SLASH_RAIDROSTEREXPORT1 = "/roster"

SlashCmdList["RAIDROSTEREXPORT"] = exportRoster
