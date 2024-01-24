local addonName, ns = ...

local NugKeyFeedback = CreateFrame("Frame", "NugKeyFeedback", UIParent)
NugKeyFeedback:SetScript("OnEvent", function(self, event, ...)
    return self[event](self, event, ...)
end)

NugKeyFeedback:RegisterEvent("PLAYER_LOGIN")
NugKeyFeedback:RegisterEvent("PLAYER_LOGOUT")

local defaults = {
    point = "CENTER",
    x = 0, y = 0,
    enableCastLine = true,
    enableCooldown = true,
    enablePushEffect = true,
    enableCast = true,
    enableCastFlash = true,
    lineIconSize = 38,
    mirrorSize = 50,
    lineDirection = "LEFT",
    forceUseActionHook = false,
}

local APILevel = math.floor(select(4,GetBuildInfo())/10000)
local isClassic = APILevel < 5 --WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
local dummy = function() end
-- local UnitCastingInfo = CastingInfo
-- local UnitChannelInfo = ChannelInfo

local firstTimeUse = false

local function GetSpellID(spellName)
    local link = GetSpellLink(spellName)
    local spellID = tonumber(link:match("spell:(%d+)"))
    return spellID
end

function NugKeyFeedback:PLAYER_LOGIN(event)

    if not _G.NugKeyFeedbackDB then
        _G.NugKeyFeedbackDB = {}
        firstTimeUse = true
    end
    -- Create a DB using defaults and using a shared default profile
    -- self.db = LibStub("AceDB-3.0"):New("NugKeyFeedbackDB", defaults, true)
    self.db = _G.NugKeyFeedbackDB
    ns.SetupDefaults(self.db, defaults)

    local usingActionBarAddons = IsAddOnLoaded("Bartender4") or
        IsAddOnLoaded("Neuron") or
        IsAddOnLoaded("ElvUI") or
        IsAddOnLoaded("TukUI")

    if self.db.forceUseActionHook or usingActionBarAddons then
        self.mirror = self:CreateFeedbackButton(true)
        self:HookUseAction()
        NugKeyFeedback.autoDetectHookMode = usingActionBarAddons
    else
        self.mirror = self:CreateFeedbackButton()
        self:HookDefaultBindings()
    end

    local GetActionSpellID = function(action)
        local actionType, id, subType = GetActionInfo(action)
        if actionType == "spell" then
            return id
        elseif actionType == "macro" then
            return GetMacroSpell(id)
        end
    end
    
    self.mirror.UpdateAction = function(self, fullUpdate)
        local action = self.action
        if not action then return end

        local tex = GetActionTexture(action)
        if not tex then return end
        self.icon:SetTexture(tex)

        if fullUpdate then
            self:UpdateCooldownOrCast()
        end
    end

    self.mirror.UpdateCooldownOrCast = function(self)
        local action = self.action
        if not action then return end

        local isCastingLastSpell = self.castSpellID == GetActionSpellID(action)
        local cooldownStartTime, cooldownDuration, enable, modRate = GetActionCooldown(action)
        local castDuration = self.castDuration or 0

        local cooldownFrame = self.cooldown

        if NugKeyFeedback.db.enableCast and self.castSpellID and self.castSpellID == GetActionSpellID(action) and castDuration > cooldownDuration then
            cooldownFrame:SetDrawEdge(true)
            cooldownFrame:SetReverse(self.castInverted)
            -- CooldownFrame_SetTimer(cooldownFrame, self.castStartTime, castDuration, true, true, 1)
            CooldownFrame_SetTimer(cooldownFrame, self.castStartTime, castDuration, true)
        elseif NugKeyFeedback.db.enableCooldown and cooldownDuration > 0 and cooldownDuration <= castDuration then
            cooldownFrame:SetDrawEdge(true)
            cooldownFrame:SetReverse(false)
            -- CooldownFrame_SetTimer(cooldownFrame, cooldownStartTime, cooldownDuration, enable, false, modRate)
            CooldownFrame_SetTimer(cooldownFrame, cooldownStartTime, cooldownDuration, enable)
        else
            cooldownFrame:Hide()
        end
    end

    self:SetSize(30, 30)

    self.anchor = self:CreateAnchor()
    self:SetPoint("BOTTOMLEFT", self.anchor, "TOPRIGHT", 0, 0)
    if firstTimeUse then self.anchor:Show() end

    self:RefreshSettings()

    self:HookOptionsFrame()

    SLASH_NUGKEYFEEDBACK1= "/nugkeyfeedback"
    SLASH_NUGKEYFEEDBACK2= "/nkf"
    SlashCmdList["NUGKEYFEEDBACK"] = self.SlashCmd
end
function NugKeyFeedback:PLAYER_LOGOUT(event)
    ns.RemoveDefaults(self.db, defaults)
end


function NugKeyFeedback.UNIT_SPELLCAST_START(self,event, unit, _castID)
    if unit ~= "player" then
        return
    end
    local name, _, _, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitCastingInfo(unit)
    if not startTime then return end -- With heavy lags it's nil sometimes
    local mirror = self.mirror
    mirror.castInverted = false
    mirror.castID = castID
    mirror.castSpellID = GetSpellID(_castID)
    mirror.castStartTime = startTime /1000
    mirror.castDuration = (endTime - startTime) /1000
    mirror:BumpFadeOut(mirror.castDuration)
    mirror:UpdateCooldownOrCast()
    -- self:UpdateCastingInfo(name,texture,startTime,endTime)
end
NugKeyFeedback.UNIT_SPELLCAST_DELAYED = NugKeyFeedback.UNIT_SPELLCAST_START
function NugKeyFeedback.UNIT_SPELLCAST_CHANNEL_START(self,event, unit, _castID, spellID)
    if unit ~= "player" then
        return
    end
    local name, _, _, texture, startTime, endTime, isTradeSkill, castID, notInterruptible = UnitChannelInfo(unit)
    local mirror = self.mirror
    mirror.castInverted = true
    mirror.castID = castID
    mirror.castSpellID = GetSpellID(_castID)
    mirror.castStartTime = startTime /1000
    mirror.castDuration = (endTime - startTime) /1000
    mirror:BumpFadeOut(mirror.castDuration)
    mirror:UpdateCooldownOrCast()
    -- self:UpdateCastingInfo(name,texture,startTime,endTime)
end
NugKeyFeedback.UNIT_SPELLCAST_CHANNEL_UPDATE = NugKeyFeedback.UNIT_SPELLCAST_CHANNEL_START
function NugKeyFeedback.UNIT_SPELLCAST_STOP(self,event, unit, castID, spellID)
    if unit ~= "player" then
        return
    end
    local mirror = self.mirror
    mirror.castSpellID = nil
    mirror.castDuration = nil
    mirror:UpdateCooldownOrCast()
end
function NugKeyFeedback.UNIT_SPELLCAST_FAILED(self, event, unit,castID)
    if unit ~= "player" then
        return
    end
    if self.mirror.castID == castID then
        NugKeyFeedback.UNIT_SPELLCAST_STOP(self, event, unit, nil)
    end
end
NugKeyFeedback.UNIT_SPELLCAST_INTERRUPTED = NugKeyFeedback.UNIT_SPELLCAST_STOP
NugKeyFeedback.UNIT_SPELLCAST_CHANNEL_STOP = NugKeyFeedback.UNIT_SPELLCAST_STOP


function NugKeyFeedback:SPELL_UPDATE_COOLDOWN(event)
    self.mirror:UpdateAction(true)
end

local MirrorActionButtonDown = function(action)
    if not HasAction(action) then return end
    
    local mirror = NugKeyFeedback.mirror

    if mirror.action ~= action then
        mirror.action = action
        mirror:UpdateAction(true)
    else
        mirror:UpdateAction()
    end

    mirror:Show()
    mirror._elapsed = 0
    mirror:SetAlpha(1)
    mirror:BumpFadeOut()
    mirror.pushed = true
    if mirror:GetButtonState() == "NORMAL" then
        if mirror.pushedCircle then
            if mirror.pushedCircle.grow:IsPlaying() then
                mirror.pushedCircle.grow:Stop()
            end
            mirror.pushedCircle:Show()
            mirror.pushedCircle.grow:Play()
        end
        mirror:SetButtonState("PUSHED");
    end
end

local MirrorActionButtonUp = function(action)
    local mirror = NugKeyFeedback.mirror

    if mirror:GetButtonState() == "PUSHED" then
        mirror:SetButtonState("NORMAL");
    end
end

function NugKeyFeedback:HookDefaultBindings()
    hooksecurefunc("ActionButtonDown", function(id)
        local button = _G["ActionButton" .. id]
        if button then
            return MirrorActionButtonDown(button.action)
        end
    end)
    hooksecurefunc("ActionButtonUp", MirrorActionButtonUp)
    hooksecurefunc("MultiActionButtonDown", function(bar, id)
        local button = _G[bar .. "Button" .. id]
        return MirrorActionButtonDown(button.action)
    end)
    hooksecurefunc("MultiActionButtonUp", MirrorActionButtonUp)
end

function NugKeyFeedback:HookUseAction()
    hooksecurefunc("UseAction", function(action)
        return MirrorActionButtonDown(action)
    end)
end



function NugKeyFeedback:UNIT_SPELLCAST_SUCCEEDED(event, unit, spellName)
    if unit ~= "player" then
        return
    end
    
    local spellID = GetSpellID(spellName)
    if IsSpellKnown(spellID, BOOKTYPE_SPELL) or IsSpellKnown(spellID, BOOKTYPE_PET) then
        if spellID == 75 then return end -- Autoshot

        if self.db.enableCastLine then
            local frame, isNew = self.iconPool:Acquire()
            local texture = select(3,GetSpellInfo(spellID))
            frame.icon:SetTexture(texture)
            frame:Show()
            frame.ag:Play()
        end

        if self.db.enableCastFlash then
            self.mirror.glow:Show()
            self.mirror.glow.blink:Play()
        end
    end
end

function NugKeyFeedback:RefreshSettings()
    local db = self.db
    self.mirror:SetSize(db.mirrorSize, db.mirrorSize)
    if self.mirror.masqueGroup then
        self.mirror.masqueGroup:ReSkin()
    end

    self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    if db.enableCastLine then
        if not self.iconPool then
            self.iconPool = self:CreateLastSpellIconLine(self.mirror)
        end

        local pool = self.iconPool
        pool:ReleaseAll()
        for i,f in pool:EnumerateInactive() do
            -- f:SetHeight(db.lineIconSize)
            -- f:SetWidth(db.lineIconSize)
            pool:resetterFunc(f)
        end
        if pool.masqueGroup then
            pool.masqueGroup:ReSkin()
        end
    end

    if db.enableCooldown then
        self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
    else
        self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
    end

    if db.enableCast then
        self:RegisterEvent("UNIT_SPELLCAST_START")
        self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
        self:RegisterEvent("UNIT_SPELLCAST_STOP")
        self:RegisterEvent("UNIT_SPELLCAST_FAILED")
        self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    else
        self:UnregisterEvent("UNIT_SPELLCAST_START")
        self:UnregisterEvent("UNIT_SPELLCAST_DELAYED")
        self:UnregisterEvent("UNIT_SPELLCAST_STOP")
        self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
        self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_START")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
        self:UnregisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
    end
end


function NugKeyFeedback.SlashCmd(msg)
    if not NugKeyFeedback.optionsPanel then
        NugKeyFeedback.optionsPanel = NugKeyFeedback:CreateGUI()
    end
    InterfaceOptionsFrame_OpenToCategory("NugKeyFeedback")
    InterfaceOptionsFrame_OpenToCategory("NugKeyFeedback")
end


function ns.SetupDefaults(t, defaults)
    for k,v in pairs(defaults) do
        if type(v) == "table" then
            if t[k] == nil then
                t[k] = CopyTable(v)
            else
                ns.SetupDefaults(t[k], v)
            end
        else
            if t[k] == nil then t[k] = v end
        end
    end
end
function ns.RemoveDefaults(t, defaults)
    for k, v in pairs(defaults) do
        if type(t[k]) == 'table' and type(v) == 'table' then
            ns.RemoveDefaults(t[k], v)
            if next(t[k]) == nil then
                t[k] = nil
            end
        elseif t[k] == v then
            t[k] = nil
        end
    end
    return t
end
