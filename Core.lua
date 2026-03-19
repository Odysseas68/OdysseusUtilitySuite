local addonName, OUS = ...
_G[addonName] = OUS 

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        OdysseusDB = OdysseusDB or {}
        OdysseusDB.modules = OdysseusDB.modules or { flightMaster = true, fasterLoot = true, fishingTracker = true }
        OdysseusDB.flightSettings = OdysseusDB.flightSettings or {}
        
        -- Initialize the brand new Fishing Database!
        OdysseusDB.fishingSettings = OdysseusDB.fishingSettings or { history = {} }
    end
end)

SLASH_ODYSSEUS1 = "/ous"
SlashCmdList["ODYSSEUS"] = function(msg)
    local cmd = string.lower(strtrim(msg))
    if cmd == "fish" then
        if OUS.ToggleFishingTracker then OUS.ToggleFishingTracker() end
    elseif OUS.ConfigFrame then
        if OUS.ConfigFrame:IsShown() then OUS.ConfigFrame:Hide() else OUS.ConfigFrame:Show() end
    end
end

_G.Odysseus_ToggleConfig = function()
    if OUS.ConfigFrame:IsShown() then OUS.ConfigFrame:Hide() else OUS.ConfigFrame:Show() end
end