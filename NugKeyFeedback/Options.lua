local L = setmetatable({}, {
    __index = function(t, k)
        -- print(string.format('L["%s"] = ""',k:gsub("\n","\\n")));
        return k
    end,
    __call = function(t,k) return t[k] end,
})
-- NugKeyFeedback.L = L

function NugKeyFeedback:CreateGUI()
    local opt = {
        type = 'group',
        name = "NugKeyFeedback Settings",
        order = 1,
        args = {
            unlock = {
                name = L"Unlock",
                type = "execute",
                desc = "Unlock anchor for dragging",
                func = function() NugKeyFeedback.anchor:Show() end,
                order = 1,
            },
            lock = {
                name = L"Lock",
                type = "execute",
                desc = "Lock anchor",
                func = function() NugKeyFeedback.anchor:Hide() end,
                order = 2,
            },
            resetToDefault = {
                name = L"Restore Defaults",
                type = 'execute',
                confirm = true,
                confirmText = L"Warning: Requires UI reloading.",
                func = function()
                    NugKeyFeedbackDB = nil
                    ReloadUI()
                end,
                order = 3,
            },

            mirrorSize = {
                name = L"Button Size",
                type = "range",
                width = "full",
                get = function(info) return NugKeyFeedback.db.mirrorSize end,
                set = function(info, v)
                    NugKeyFeedback.db.mirrorSize = tonumber(v)
                    NugKeyFeedback:RefreshSettings()
                end,
                min = 10,
                max = 150,
                step = 1,
                order = 4,
            },
            enableCooldown = {
                name = L"Show Cooldown",
                type = "toggle",
                width = "full",
                order = 4.2,
                get = function(info) return NugKeyFeedback.db.enableCooldown end,
                set = function(info, v)
                    NugKeyFeedback.db.enableCooldown = not NugKeyFeedback.db.enableCooldown
                    NugKeyFeedback:RefreshSettings()
                end
            },
            enableCast = {
                name = L"Show Cast Time",
                type = "toggle",
                width = "full",
                order = 4.3,
                get = function(info) return NugKeyFeedback.db.enableCast end,
                set = function(info, v)
                    NugKeyFeedback.db.enableCast = not NugKeyFeedback.db.enableCast
                    NugKeyFeedback:RefreshSettings()
                end
            },
            enablePushEffect = {
                name = L"FF14 Push Effect",
                type = "toggle",
                width = "full",
                order = 4.4,
                confirm = true,
                confirmText = L"Warning: Requires UI reloading.",
                get = function(info) return NugKeyFeedback.db.enablePushEffect end,
                set = function(info, v)
                    NugKeyFeedback.db.enablePushEffect = not NugKeyFeedback.db.enablePushEffect
                    ReloadUI()
                end
            },
            enableCastLine = {
                name = L"Cast Line",
                type = "toggle",
                width = "full",
                order = 4.5,
                get = function(info) return NugKeyFeedback.db.enableCastLine end,
                set = function(info, v)
                    NugKeyFeedback.db.enableCastLine = not NugKeyFeedback.db.enableCastLine
                    NugKeyFeedback:RefreshSettings()
                end
            },
            enableCastFlash = {
                name = L"Cast Flash",
                type = "toggle",
                width = "full",
                order = 4.6,
                get = function(info) return NugKeyFeedback.db.enableCastFlash end,
                set = function(info, v)
                    NugKeyFeedback.db.enableCastFlash = not NugKeyFeedback.db.enableCastFlash
                    NugKeyFeedback:RefreshSettings()
                end
            },
            lineIconSize = {
                name = L"Cast Line Icon Size",
                type = "range",
                disabled = function() return not NugKeyFeedback.db.enableCastLine end,
                width = "full",
                get = function(info) return NugKeyFeedback.db.lineIconSize end,
                set = function(info, v)
                    NugKeyFeedback.db.lineIconSize = tonumber(v)
                    NugKeyFeedback:RefreshSettings()
                end,
                min = 10,
                max = 150,
                step = 1,
                order = 5,
            },
            lineDirection = {
                name = L"Cast Line Direction",
                type = 'select',
                order = 8,
                values = {
                    TOP = L"UP",
                    LEFT = L"LEFT",
                    RIGHT = L"RIGHT",
                    BOTTOM = L"DOWN",
                },
                get = function(info) return NugKeyFeedback.db.lineDirection end,
                set = function(info, v)
                    NugKeyFeedback.db.lineDirection = v
                    NugKeyFeedback:RefreshSettings()
                end,
            },


            forceUseActionHook = {
                name = L"Force UseAction hook",
                desc = "Force the alternative hook mode. Only enable this if things do not work in combination with your main action bar addon",
                type = "toggle",
                width = "full",
                order = 10,
                confirm = true,
                confirmText = L"Warning: Requires UI reloading.",
                disabled = function()
                    return NugKeyFeedback.autoDetectHookMode ~= nil
                end,
                get = function(info)
                    if NugKeyFeedback.autoDetectHookMode ~= nil then return NugKeyFeedback.autoDetectHookMode end
                    return NugKeyFeedback.db.forceUseActionHook
                end,
                set = function(info, v)
                    NugKeyFeedback.db.forceUseActionHook = not NugKeyFeedback.db.forceUseActionHook
                    ReloadUI()
                end
            },
            description1 = {
                name = "|cffffaa55"..L"It is highly recommended that you enable 'Cast on Key Down' if using Bartender4/Neuron/ElvUI.".."|r",
                width = "full",
                type = 'description',
                order = 11,
            },

        },
    }

    local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
    AceConfigRegistry:RegisterOptionsTable("NugKeyFeedbackOptions", opt)

    local AceConfigDialog = LibStub("AceConfigDialog-3.0")
    local panelFrame = AceConfigDialog:AddToBlizOptions("NugKeyFeedbackOptions", "NugKeyFeedback")

    return panelFrame
end

function NugKeyFeedback:HookOptionsFrame()
    CreateFrame('Frame', nil, InterfaceOptionsFrame):SetScript('OnShow', function(frame)
        frame:SetScript('OnShow', nil)

        if not self.optionsPanel then
            self.optionsPanel = self:CreateGUI()
        end
    end)
end
