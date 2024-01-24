local addonName, ns = ...

local Masque = LibStub("Masque", true)

local function MakeCompatibleAnimation(anim)
    if anim:GetObjectType() == "Scale" and anim.SetScaleFrom then
        return anim
    else
        anim.SetScaleFrom = anim.SetFromScale
        anim.SetScaleTo = anim.SetToScale
    end
    return anim
end

function NugKeyFeedback:CreateFeedbackButton(autoKeyup)
    local db = self.db

    local mirror = CreateFrame("Button", "NugKeyFeedbackMirror", self, "ActionButtonTemplate")
    mirror:SetHeight(db.mirrorSize)
    mirror:SetWidth(db.mirrorSize)
    mirror.NormalTexture = mirror:GetNormalTexture()
    mirror.NormalTexture:ClearAllPoints()
    mirror.NormalTexture:SetPoint("TOPLEFT", -15, 15)
    mirror.NormalTexture:SetPoint("BOTTOMRIGHT", 15, -15)
    
    mirror.icon = mirror:CreateTexture(nil, "BACKGROUND")
    mirror.icon:SetAllPoints()
    -- mirror.NormalTexture:SetSize(db.mirrorSize, db.mirrorSize)
    -- mirror.NormalTexture:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    -- mirror:GetPushedTexture():SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    -- mirror:GetPushedTexture():SetSize(db.mirrorSize, db.mirrorSize)

    mirror.cooldown = CreateFrame("Cooldown", nil, mirror, "CooldownFrameTemplate")
    mirror.cooldown:SetAllPoints()
    -- mirror.cooldown:SetEdgeTexture("Interface\\Cooldown\\edge");
    -- mirror.cooldown:SetSwipeColor(0, 0, 0);
    -- mirror.cooldown:SetHideCountdownNumbers(false);

    if Masque then
        local mg = Masque:Group(addonName, "Feedback Button")
        mg:AddButton(mirror)
        mirror.masqueGroup = mg
    end
    mirror:Show()
    mirror._elapsed = 0

    local glow = CreateFrame("Frame", nil, mirror)
    glow:SetPoint("TOPLEFT", -16, 16)
    glow:SetPoint("BOTTOMRIGHT", 16, -16)
    local gtex = glow:CreateTexture(nil, "OVERLAY")
    gtex:SetTexture([[Interface\AddOns\NugKeyFeedback\SpellActivationOverlay\IconAlert]])
    gtex:SetTexCoord(0, 66/128, 136/256, 202/256)
    gtex:SetVertexColor(0,1,0)
    gtex:SetAllPoints(glow)
    mirror.glow = glow
    glow:Hide()

    local ag = glow:CreateAnimationGroup()
    glow.blink = ag

    -- local a1 = ag:CreateAnimation("Alpha")
    -- a1:SetFromAlpha(0)
    -- a1:SetToAlpha(1)
    -- a1:SetDuration(0.14)
    -- a1:SetOrder(1)

    local a2 = ag:CreateAnimation("Alpha")
    a2:SetChange(-1)
    a2:SetSmoothing("OUT")
    a2:SetDuration(0.3)
    a2:SetOrder(2)

    ag:SetScript("OnFinished", function(self)
        self:GetParent():Hide()
    end)

    if db.enablePushEffect then
        local pushedCircle = CreateFrame("Frame", nil, mirror)
        local size = db.mirrorSize
        pushedCircle:SetSize(size, size)
        pushedCircle:SetPoint("CENTER", 0, 0)
        local pctex = pushedCircle:CreateTexture(nil, "OVERLAY")
        pctex:SetTexture([[Interface\AddOns\NugKeyFeedback\ff14_pressed.tga]])
        pctex:SetBlendMode("ADD")
        pctex:SetAllPoints(pushedCircle)
        mirror.pushedCircle = pushedCircle
        pushedCircle:Hide()

        local gag = pushedCircle:CreateAnimationGroup()
        pushedCircle.grow = gag

        local ga1 = MakeCompatibleAnimation(gag:CreateAnimation("Scale"))
        ga1:SetScale(0.1, 0.1)
        ga1:SetDuration(0.3)
        ga1:SetOrder(2)

        local ga2 = gag:CreateAnimation("Alpha")
        ga2:SetChange(-0.5)
        ga2:SetDuration(0.2)
        ga2:SetStartDelay(0.1)
        ga2:SetOrder(2)

        gag:SetScript("OnFinished", function(self)
            self:GetParent():Hide()
        end)
    end

    mirror.BumpFadeOut = function(self, modifier)
        modifier = modifier or 1.5
        if -modifier < self._elapsed then
            self._elapsed = -modifier
        end
    end

    if autoKeyup then
        mirror:SetScript("OnUpdate", function(self, elapsed)
            self._elapsed = self._elapsed + elapsed

            local timePassed = self._elapsed

            if timePassed >= 0.1 and self.pushed then
                mirror:SetButtonState("NORMAL");
                self.pushed = false
            end

            if timePassed >= 1 then
                local alpha = 2 - timePassed
                if alpha <= 0 then
                    alpha = 0
                    self:Hide()
                end
                self:SetAlpha(alpha)
            end
        end)
    else
        mirror:SetScript("OnUpdate", function(self, elapsed)
            self._elapsed = self._elapsed + elapsed

            local timePassed = self._elapsed
            if timePassed >= 1 then
                local alpha = 2 - timePassed
                if alpha <= 0 then
                    alpha = 0
                    self:Hide()
                end
                self:SetAlpha(alpha)
            end
        end)
    end

    mirror:EnableMouse(false)

    mirror:SetPoint("CENTER", self, "CENTER")

    mirror:Hide()

    return mirror
end

local PoolIconCreationFunc = function(pool)
    local db = NugKeyFeedback.db

    local hdr = pool.parent
    local id = pool.idCounter
    pool.idCounter = pool.idCounter + 1
    local f = CreateFrame("Button", "NugKeyFeedbackPoolIcon"..id, hdr, "ActionButtonTemplate")
    f.icon = f:CreateTexture(nil, "BACKGROUND")
    f.icon:SetAllPoints()

    if pool.masqueGroup then
        pool.masqueGroup:AddButton(f)
    end

    f:EnableMouse(false)
    f:SetHeight(db.lineIconSize)
    f:SetWidth(db.lineIconSize)
    f:SetPoint("BOTTOM", hdr, "BOTTOM",0, -0)

    local t = f.icon
    f:SetAlpha(0)

    t:SetTexture("Interface\\Icons\\Ability_BackStab")

    local ag = f:CreateAnimationGroup()
    f.ag = ag

    local scaleOrigin = "RIGHT"
    local translateX = -100
    local translateY = 0


    local s1 = MakeCompatibleAnimation(ag:CreateAnimation("Scale"))
    s1:SetScale(0.01,1)
    s1:SetDuration(0)
    s1:SetOrigin(scaleOrigin,0,0)
    s1:SetOrder(1)

    local s2 = MakeCompatibleAnimation(ag:CreateAnimation("Scale"))
    s2:SetScale(100,1)
    s2:SetDuration(0.5)
    s2:SetOrigin(scaleOrigin,0,0)
    s2:SetSmoothing("OUT")
    s2:SetOrder(2)

    local a1 = ag:CreateAnimation("Alpha")
    a1:SetChange(1)
    a1:SetDuration(0.1)
    a1:SetOrder(2)

    local t1 = ag:CreateAnimation("Translation")
    t1:SetOffset(translateX,translateY)
    t1:SetDuration(1.2)
    t1:SetSmoothing("IN")
    t1:SetOrder(2)

    local a2 = ag:CreateAnimation("Alpha")
    a2:SetChange(-1)
    a2:SetSmoothing("OUT")
    a2:SetDuration(0.5)
    a2:SetStartDelay(0.6)
    a2:SetOrder(2)

    ag.s1 = s1
    ag.s2 = s2
    ag.t1 = t1

    ag:SetScript("OnFinished", function(self)
        local icon = self:GetParent()
        icon:Hide()
        if icon then
            -- pool:Release(icon)
        end
    end)

    return f
end

local function PoolIconResetterFunc(pool, f)
    local db = NugKeyFeedback.db

    f:SetHeight(db.lineIconSize)
    f:SetWidth(db.lineIconSize)

    f.ag:Stop()

    local scaleOrigin, revOrigin, translateX, translateY
    -- local sx1, sx2, sy1, sy2
    if db.lineDirection == "RIGHT" then
        scaleOrigin = "LEFT"
        revOrigin = "RIGHT"
        -- sx1, sx2, sy1, sy2 = 0.01, 100, 1, 1
        translateX = 100
        translateY = 0
    elseif db.lineDirection == "TOP" then
        scaleOrigin = "BOTTOM"
        revOrigin = "TOP"
        -- sx1, sx2, sy1, sy2 = 1,1, 0.01, 100
        translateX = 0
        translateY = 100
    elseif db.lineDirection == "BOTTOM" then
        scaleOrigin = "TOP"
        revOrigin = "BOTTOM"
        -- sx1, sx2, sy1, sy2 = 1,1, 0.01, 100
        translateX = 0
        translateY = -100
    else
        scaleOrigin = "RIGHT"
        revOrigin = "LEFT"
        -- sx1, sx2, sy1, sy2 = 0.01, 100, 1, 1
        translateX = -100
        translateY = 0
    end
    local ag = f.ag
    -- ag.s1:SetScale(sx1, sy1)
    ag.s1:SetOrigin(scaleOrigin, 0,0)

    -- ag.s1:SetScale(sx2, sy2)
    ag.s2:SetOrigin(scaleOrigin, 0,0)
    ag.t1:SetOffset(translateX, translateY)

    f:ClearAllPoints()
    local parent = pool.parent
    f:SetPoint(scaleOrigin, parent, revOrigin, 0,0)
end

function NugKeyFeedback:CreateLastSpellIconLine(parent)
    local template = nil
    local resetterFunc = PoolIconResetterFunc
    local iconPool = ns.CreateFramePool("Frame", parent, template, resetterFunc)
    iconPool.creationFunc = PoolIconCreationFunc
    iconPool.resetterFunc  = PoolIconResetterFunc
    iconPool.idCounter = 1
    
    if Masque then
        iconPool.masqueGroup = Masque:Group(addonName, "Spell Line Icons")
    end

    return iconPool
end

--[[
function NugKeyFeedback:CreateFlashTexture(parent)
    local flash = parent:CreateTexture(nil, "ARTWORK")
    flash:SetAtlas("collections-newglow")
    flash:SetVertexColor(1,1,0)
    -- flash:SetRotation(math.rad(90))
    flash:SetSize(85, 25)
    flash:SetPoint("CENTER", self.mirror, NKFDB.direction,0,0)
    flash:SetAlpha(0)

    local ag = flash:CreateAnimationGroup()

    local a1 = ag:CreateAnimation("Alpha")
    a1:SetFromAlpha(0)
    a1:SetToAlpha(1)
    a1:SetDuration(0.1)
    a1:SetOrder(1)

    local a2 = ag:CreateAnimation("Alpha")
    a2:SetFromAlpha(1)
    a2:SetToAlpha(0)
    a2:SetSmoothing("OUT")
    a2:SetDuration(0.5)
    a2:SetStartDelay(0.6)
    a2:SetOrder(2)

    flash.ag = ag

    return flash
end
]]

function NugKeyFeedback:CreateAnchor()
    local f = CreateFrame("Frame","NugThreatAnchor",UIParent)
    f:SetHeight(20)
    f:SetWidth(20)
    f:SetPoint(NugKeyFeedback.db.point,"UIParent",NugKeyFeedback.db.point, NugKeyFeedback.db.x, NugKeyFeedback.db.y)

    f:RegisterForDrag("LeftButton")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:Hide()

    local t = f:CreateTexture(f:GetName().."Icon1","BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0,0.25,0,1)
    t:SetAllPoints(f)

    t = f:CreateTexture(f:GetName().."Icon","BACKGROUND")
    t:SetTexture("Interface\\Buttons\\UI-RadioButton")
    t:SetTexCoord(0.25,0.49,0,1)
    t:SetVertexColor(1, 0, 0)
    t:SetAllPoints(f)

    f:SetScript("OnDragStart",function(self) self:StartMoving() end)
    f:SetScript("OnDragStop",function(self)
        self:StopMovingOrSizing();
        local db = NugKeyFeedback.db
        db.point, db.x, db.y = select(3, self:GetPoint(1)) -- skip first 2 values
    end)
    return f
end
