-- vim: ts=4 sw=4 ai et enc=utf8 fenc=utf8
AlgalonObserver.frames = {}
local AO = AlgalonObserver
local AOF = AO.frames

local TEXTURES = "Interface\\AddOns\\AlgalonObserver\\Textures"

function AOF:Initialize ()
    if self.initialized then return end
    self.initialized = true

    -- Frame that we can hook an OnUpdate from
    local f = CreateFrame ("Frame", nil, WorldFrame)
    f:SetClampedToScreen (true)
    f:SetFrameStrata ("BACKGROUND")
    f:SetAllPoints (UIParent)
    f:Show ()
    self.main = f

    self.bb = {}
    local c = AO.db.profile.bbcolor
    local t
    for i = 0, 8 do
        t = f:CreateTexture ("AO-BB" .. i)
        t:SetAlpha (0)
        t:SetBlendMode ("ADD")
        t:SetVertexColor (0.9, 0.9, 0.1)
        t:SetAllPoints (f)
        t:SetTexture (TEXTURES.."\\bb"..i)
        self.bb[i] = t
    end

    self.cs = {}
    for i = 1, 5 do
        t = f:CreateTexture ("AO-CS"..i)
        t:SetAlpha (0)
        t:SetBlendMode ("ADD")
        t:SetVertexColor (0.9, 0.2, 0.1)
        t:SetAllPoints (f)
        t:SetTexture (TEXTURES.."\\cs"..i)
        self.cs[i] = t
    end

    f = CreateFrame ("Frame", "AO_Stars", UIParent)
    f:SetClampedToScreen (true)
    f:SetWidth (AO.db.profile.width)
    f:SetHeight ((20 * AO.db.profile.maxstars) + 6)
    f:SetPoint ("BOTTOMLEFT", UIParent, "BOTTOMLEFT", AO.db.profile.x, AO.db.profile.y)
    f.AO_Unlock = function (f)
            f:EnableMouse (true)
            f:SetMovable (true)
            f:SetUserPlaced (true)
            f:SetScript ("OnMouseDown", function (f) f:StartMoving () end)
            f:SetScript ("OnMouseUp", function (f) f:StopMovingOrSizing () end)
            f:SetBackdropColor (0, 0.5, 0, 0.8)
        end
    f.AO_Lock = function (f)
            f:EnableMouse (false)
            f:SetMovable (false)
            f:SetScript ("OnMouseDown", nil)
            f:SetScript ("OnMouseUp", nil)
            f:SetBackdropColor (0, 0, 0, 0.8)
            AO.db.profile.x = f:GetLeft() - f:GetParent():GetLeft()
            AO.db.profile.y = f:GetBottom() - f:GetParent():GetBottom()
        end
    f:SetBackdrop ({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = 1, tileSize = 10, edgeSize = 10,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })
    f:SetBackdropColor (0, 0, 0, 0.8)
    f:Hide ()

    self.starframe = f

    self.bars = {}
    local anchor = f
    local point = "TOP"
    local yoffs = -3
    local c = AO.db.profile.starcolor
    for i = 1, AO.db.profile.maxstars
    do
        local bar = CreateFrame ("STATUSBAR", "AO-Star"..i, f, "TextStatusBar") 
        bar:SetHeight (20);
        bar:SetPoint ("LEFT", f, "LEFT", 4, 0)
        bar:SetPoint ("RIGHT", f, "RIGHT", -4, 0)
        bar:SetPoint ("TOP", anchor, point, 0, yoffs)
        --bar:SetStatusBarTexture ("Interface\\TargetingFrame\\UI-StatusBar")
        bar:SetStatusBarTexture ("Interface\\AddOns\\AlgalonObserver\\Textures\\bar")
        bar:SetMinMaxValues (0, AO.db.profile.starhealth)
        bar:SetValue (0)
        bar:SetStatusBarColor (c.r, c.g, c.b, c.a)
        bar:EnableMouse (false)
        bar.AO_free = true
        self.bars[i] = bar
        anchor = bar
        point = "BOTTOM"
        yoffs = 0
    end
end



