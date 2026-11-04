local _, FC = ...
local module = {}
FC.modules[#FC.modules + 1] = module
local hooked = setmetatable({}, { __mode = "k" })

local function hookChatFrame(frame)
    if not frame or hooked[frame] then return end
    hooked[frame] = true
    frame:EnableMouse(true)
    local overLink, pressedLink = false, false
    frame:HookScript("OnHyperlinkEnter", function() overLink = true end)
    frame:HookScript("OnHyperlinkLeave", function() overLink = false end)
    frame:HookScript("OnHide", function() overLink, pressedLink = false, false end)
    frame:HookScript("OnMouseDown", function(_, button)
        if button == "RightButton" then pressedLink = overLink end
    end)
    frame:HookScript("OnMouseUp", function(_, button)
        if button ~= "RightButton" then return end
        local isLink = overLink or pressedLink
        pressedLink = false
        if not isLink then FC:OpenSettings() end
    end)
end

function module:Initialize()
    local function hookWindows()
        for _, name in pairs(CHAT_FRAMES or {}) do hookChatFrame(_G[name]) end
    end
    hookWindows()
    -- Newly created chat tabs and pop-out whisper windows need the same shortcut.
    if hooksecurefunc then
        if FCF_OpenNewWindow then hooksecurefunc("FCF_OpenNewWindow", hookWindows) end
        if FCF_OpenTemporaryWindow then hooksecurefunc("FCF_OpenTemporaryWindow", hookWindows) end
    end
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:SetScript("OnEvent", hookWindows)
end
