-- vim: ts=4 sw=4 ai et enc=utf8 fenc=utf8
local NAME = "AlgalonObserver"
AlgalonObserver = LibStub ("AceAddon-3.0"):NewAddon (NAME, "AceConsole-3.0", "AceEvent-3.0", "AceComm-3.0", "AceSerializer-3.0")
local AO = AlgalonObserver

local options = {
    type = 'group',
    handler = AO,
    get = "GetVal",
    set = "SetVal",
    childGroups = 'tab',
    args = {
        warnings = {
            type = 'group',
            order = 1,
            name = "Warnings",
            args = {
                bigbang = {
                    type = 'group',
                    inline = true,
                    order = 10,
                    name = "Big Bang",
                    args = {
                        countdownbb = { type = 'toggle', order = 1, name = "Enable countdown", desc = "Enable Big Bang countdown monitoring" },
                        bbvisuals = { type = 'toggle', order = 2, name = "Show countdown", desc = "Show Big Bang count down overlay", disabled = function () return not AO.db.profile.countdownbb end },
                        bbsounds = { type = 'toggle', order = 5, name = "Warning sound", desc = "Play warning sound when Big Bang is casting", disabled = function () return not AO.db.profile.countdownbb end },
                        preview = { type = 'execute', order = 10, name = "Preview", desc = "Preview these settings (activates AlgalonObserver, '/algalon off' to stop it", func = function () AO:do_enable() AO:test_bb() end },
                    }
                },
                cosmicsmash = {
                    type = 'group',
                    inline = true,
                    order = 20,
                    name = "Cosmic Smash",
                    args = {
                        countdowncs = { type = 'toggle', order = 1, name = "Enable countdown", desc = "Enable Cosmic Smash countdown monitoring" },
                        csvisuals = { type = 'toggle', order = 2, name = "Show countdown", desc = "Show Cosmic Smash count down overlay", disabled = function () return not AO.db.profile.countdowncs end },
                        cssounds = { type = 'toggle', order = 5, name = "Warning sound", desc = "Play warning sound when Big Bang is casting", disabled = function () return not AO.db.profile.countdowncs end },
                        preview = { type = 'execute', order = 10, name = "Preview", desc = "Preview these settings (activates AlgalonObserver, '/algalon off' to stop it", func = function () AO:do_enable() AO:test_cs() end },
                    }
                },
                stars = {
                    type = 'group',
                    inline = true,
                    order = 30,
                    name = "Collapsing Stars",
                    args = {
                        starvisuals = { type = 'toggle', order = 1, name = "Health frame", desc = "Show health frame for known Collapsing Stars",
                            set = function (info, v) local f = AO.frames.starframe if v then f:Show() else f:Hide() end AO:SetVal(info, v) end },
                        locked = { type = 'toggle', order = 2, name = "Unlock", desc = "Unlock the Health frame to allow positioning. Lock when done to save position",
                            disabled = function () return not AO.db.profile.starvisuals end,
                            set = function (info, v) local f = AO.frames.starframe f:Show() if v then f:AO_Lock() else f:AO_Unlock () end AO.db.profile.locked = v end },
                        starsounds = { type = 'toggle', order = 10, name = "Warning sound", desc = "Sound a warning when a known star is close to collapsing" },
                        lowhealth = { type = 'range', order = 11, min = 1, max = 100, step = 1, name = "Low health threshold", desc = "Point at which to start sounding the low health warning",
                            disabled = function () return not AO.db.profile.starsounds end },
                        starcolor = { type = 'color', order = 12, name = "Bar color", desc = "Bar color for untargeted Collapsing Stars", get = "GetColor", set = "SetColor" },
                        starcolort = { type = 'color', order = 13, name = "Targeted color", desc = "Bar color for targeted Collapsing Stars", get = "GetColor", set = "SetColor" },
                        preview = { type = 'execute', order = 50, name = "Preview", desc = "Preview these settings (activates AlgalonObserver, '/algalon off' to stop it", func = function () AO:do_enable() AO:test_star() end }
                    }
                },
            }
        },
        about = {
            type = 'group',
            order = 99,
            name = "About",
            desc = "About " .. NAME,
            args = {
                __ = {
                    type = 'header',
                    name = NAME .. " " .. GetAddOnMetadata (NAME, "Version"),
                    order = 1,
                },
                _1 = {
                    type = 'description',
                    name = GetAddOnMetadata (NAME, "Notes"),
                    order = 10,
                },
                _2 = {
                    type = 'description',
                    name = "By " .. GetAddOnMetadata(NAME, "Author"),
                    order = 20,
                },
                _3 = { type = 'description', name = "", order = 30, },
                _4 = {
                    type = 'description',
                    name = "Copyright(C) 2009 Johny Mattsson",
                    order = 40,
                },
                _5 = { type = 'description', name = "", order = 50, },
                _99 = { type = 'execute', order = 99, name = "Stop", desc = "Stop AlgalonObserver if it is running (same as '/algalon off')", func = function () AO:do_disable() end },
            }
        }
    },
}

local defaults = {
    profile = {
        countdownbb = true,
        bbsounds = true,
        bbvisuals = true,
        countdowncs = true,
        cssounds = true,
        csvisuals = true,
        starvisuals = true,
        starsounds = true,
        lowhealth = 15,

        locked = true,
        width = 180,
        maxstars = 4,
        x = 300,
        y = 300,
        starhealth = 88200,
        starcolor = { r = 1, g = 1, b = 0, a = 1},
        starcolort = { r = 1, g = 0, b = 0, a = 1 },
    }
}

-- Config manipulators
function AO:GetVal (info)
    self:do_initialize ()
    return self.db.profile[info[#info]]
end
function AO:SetVal (info, v)
    self.db.profile[info[#info]] = v
end
function AO:GetColor (info)
  local c = self.db.profile[info[#info]]
  return c.r, c.g, c.b, (c.a or 1)
end
function AO:SetColor (info, r, g, b, a)
  local c = { r = r, g = g, b = b, a = a }
  self.db.profile[info[#info]] = c
end

function AO:OnProfileChanged ()
    -- NYI
end

-- Constants
local STAR = "Collapsing Star"
local HOLE = "Black Hole"
local BIGAL = "Algalon the Observer"
local BB_ID = 64443
local CS_ID = 62301
local BHE_ID = 64122

-- Star bar support
local function take_first_free_bar ()
    for i = 1, AO.db.profile.maxstars
    do
        local b = AO.frames.bars[i]
        if b and b.AO_free then
            b.AO_free = nil
            return b
        end
    end
    return nil
end

local function release_bar (bar)
    bar:Hide ()
    bar.AO_free = true
end

-- Debug aids
function AO:test_cs ()
    self:COMBAT_LOG_EVENT_UNFILTERED ("", 0, "SPELL_CAST_SUCCESS",0xF13000806712FAC4,"Algalon the Observer",0x10a28,0x0000000000000000,nil,0x80000000,62301,"Cosmic Smash",0x40)
end

function AO:test_bb ()
    self:COMBAT_LOG_EVENT_UNFILTERED ("", 0, "SPELL_CAST_START",0xF13000806713022D,"Algalon the Observer",0xa28,0x0000000000000000,nil,0x80000000,64443,"Big Bang",0x1)
end

function AO:test_hole ()
    self:COMBAT_LOG_EVENT_UNFILTERED ("", 0, "SPELL_CAST_SUCCESS",0xF1300080B912FCC0,"Black Hole",0xa48,0x0000000000000000,nil,0x80000000,64122,"Black Hole Explosion",0x20)
end

function AO:test_p2 ()
    self:CHAT_MSG_MONSTER_YELL ("", "Behold the tools of creation!", BIGAL, "", "", "")
end

function AO:test_star ()
    local id = GetTime ()
    local bar = take_first_free_bar ()
    if not bar then return end
    bar:SetValue (self.db.profile.starhealth)
    bar:Show ()
    self.stars[id] = bar
end

-- Count downs
local elapsed = 0 -- managed by the OnUpdate handler

local function count_down_big_bang ()
    local secs = 0
    if AO.db.profile.bbsounds then PlaySoundFile ("Sound\\Spells\\PVPFlagTaken.wav") end
    for i = 8, 0, -1 do
        if AO.db.profile.bbvisuals then UIFrameFlash (AO.frames.bb[i], 0.1, 0.9, 0.95, false, 0, 0) end
        if AO.db.profile.bbsounds then PlaySoundFile ("Interface\\AddOns\\AlgalonObserver\\Sounds\\heartbeat.mp3") end
        while secs < 1 do
            coroutine.yield (true)
            secs = secs + elapsed
        end
        secs = secs -1
    end
end

local function count_down_cosmic_smash ()
    local secs = 0
    if AO.db.profile.cssounds then PlaySoundFile ("Sound\\Doodad\\BellTollNightElf.wav") end
    for i = 5, 0, -1 do
        if AO.db.profile.csvisuals then UIFrameFlash (AO.frames.cs[i], 0.1, 0.9, 0.95, false, 0, 0) end
        while secs < 1 do
            coroutine.yield (true)
            secs = secs + elapsed
        end
        secs = secs -1
    end
end

local function count_down_star_health ()
    local secs = 0
    while true do
        AO:OnStarHealthUpdate (true)
        while secs < 1 do
            if coroutine.yield (true) then return end -- exit request
            secs = secs + elapsed
        end
        secs = secs -1
    end
end


-- High-level event handling
function AO:OnBigBang ()
    if self.db.profile.countdownbb then
        self.countdownbb = coroutine.create (count_down_big_bang)
    end
end

function AO:OnCosmicSmash ()
    if self.db.profile.countdowncs then
        self.countdowncs = coroutine.create (count_down_cosmic_smash)
    end
end

function AO:OnStarHealthUpdate ()
    local percent = self.db.profile.starhealth / 100
    for id, bar in pairs (self.stars )
    do  -- subtract 882 health from each star we know about
        local health = bar:GetValue ()
        health = health - percent
        bar:SetValue (health)
        bar.AO_targeted = false
    end

    -- scan raid members' targets, if any is a star, grab the health info from it
    for i = 1, GetNumRaidMembers ()
    do
        local target = "raid"..i.."target"
        local name = UnitName (target)
        if name and name == STAR then
            local id = UnitGUID (target)
            local bar = self.stars[id]
            if bar then
                -- Can get exact value
                bar:SetValue (UnitHealth (target))
            else
                -- new star!
                bar = take_first_free_bar ()
                if bar then -- this should hopefully always be the case
                    bar:SetValue (UnitHealth (target))
                    bar:Show ()
                    self.stars[id] = bar
                else
                    self:Print ("debug: could not get free bar for star id "..id)
                end
            end
            -- Allow different color on targeted stars
            if bar then bar.AO_targeted = true end
        end
    end

    for id, bar in pairs (self.stars)
    do
        -- Set bar color based on if a star is targeted or not
        local c
        if bar.AO_targeted then
            c = self.db.profile.starcolort
        else
            c = self.db.profile.starcolor
        end
        bar:SetStatusBarColor (c.r, c.g, c.b, c.a)

        -- if health drops below n%, trigger warning beeps
        local health = bar:GetValue ()
        if health < (percent * self.db.profile.lowhealth) then
            if self.db.profile.starsounds then
                PlaySoundFile ("Interface\\AddOns\\AlgalonObserver\\Sounds\\biips.mp3")
            end
        end

        -- If health has gone flat we must've missed the BHE and should free this bar
        if health == 0 then
            self.stars[id] = nil
            release_bar (bar)
        end
    end
end

function AO:OnBlackHoleExplosion ()
    local id = 0
    local health = 100000000
    for i, bar in pairs (self.stars)
    do
        local h = bar:GetValue ()
        if h < health then
            id = i
            health = h
        end
    end
    -- Remove the star with the lowest health
    local bar = self.stars[id]
    self.stars[id] = nil
    if not bar then return end -- Mr Justin Case
    release_bar (bar)
end



-- Low-level event handling
function AO:COMBAT_LOG_EVENT_UNFILTERED(eventName, time, event, srcId, srcName, srcFlags, dstID, dstName, dstFlags, spellID, spellName)
    if spellID == BB_ID and event == "SPELL_CAST_START" and srcName == BIGAL
    then
        self:OnBigBang ()
    elseif spellID == CS_ID and event == "SPELL_CAST_SUCCESS" and srcName == BIGAL
    then
        self:OnCosmicSmash ()
    elseif spellID == BHE_ID and event == "SPELL_CAST_SUCCESS"
    then
        self:OnBlackHoleExplosion ()
    end
end

function AO:CHAT_MSG_MONSTER_YELL(eventName, msg, sender, lang, channel, target)
    if sender == BIGAL and msg == "Behold the tools of creation!" then
        -- p2 just began, dismiss star tracking
        self:dismiss_star_tracking ()
        self:Print ("entering phase2 - further star tracking disabled")
    end
end

function AO:OnUpdate (t)
    elapsed = t
    if self.countdownbb then
        if not coroutine.resume (self.countdownbb) then
            self.countdownbb = nil
        end
    end
    if self.countdowncs then
        if not coroutine.resume (self.countdowncs) then
            self.countdowncs = nil
        end
    end
    if self.starhealth then
        coroutine.resume (self.starhealth)
    end

    local mtarget = UnitName ("mouseover")
    if mtarget and mtarget == STAR then
        local id = UnitGUID ("mouseover")
        if not self.stars[id] then
            local health = UnitHealth ("mouseover")
            local bar = take_first_free_bar ()
            if not bar then return end -- urgh
            bar:SetValue (health)
            self.stars[id] = bar
            bar:Show ()
            self:SendCommMessage (NAME, self:Serialize ("s1", id, health), "RAID", nil, "NORMAL")
        end
    end
end

function AO:OnComm (prefix, message, distribution, sender)
    if prefix ~= NAME then return end
    local success, msgtype, id, health = self:Deserialize (message)
    if not success then return end
    if self.stars[id] then return end

    local bar = take_first_free_bar ()
    if not bar then return end
    bar:SetValue (health)
    self.stars[id] = bar
    bar:Show()
end

-- Enabling triggers - either targeting Algalon or walking into the planetarium
function AO:PLAYER_TARGET_CHANGED ()
    local target = UnitName ("target")
    if target == BIGAL then
        if UnitCanAttack ("player", "target") then
            self:do_enable ()
        else
            self:do_disable () -- woot, he's green!
        end
    end
end

function AO:OnZoneChange ()
    self:do_disable ()
    local TCP = "The Celestial Planetarium"
    if GetMinimapZoneText () == TCP or GetSubZoneText () == TCP then
        self:do_enable ()
    end
end

function AO:ZONE_CHANGED ()
    self:OnZoneChange ()
end

function AO:ZONE_CHANGED_INDOORS ()
    self:OnZoneChange ()
end

function AO:ZONE_CHANGED_NEW_AREA ()
    self:OnZoneChange ()
end

-- Initialisation related stuff
function AO:dismiss_star_tracking ()
    self.frames.starframe:Hide()
    for i = 1, self.db.profile.maxstars
    do
        local bar = self.frames.bars[i]
        release_bar (bar)
    end
    if self.starhealth then coroutine.resume (self.starhealth, true) end -- ask it to exit
    self.starhealth = nil
    self.stars = nil
end

function AO:do_enable ()
    if self.enabled then return end

    self:do_initialize ()

    self:RegisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
    self:RegisterEvent ("CHAT_MSG_MONSTER_YELL")
    self:RegisterComm (NAME, "OnComm")
    self.stars = {}
    self.starhealth = coroutine.create (count_down_star_health)
    self.frames.main:SetScript ("OnUpdate", function (_, t) AO:OnUpdate (t) end)
    if self.db.profile.starvisuals then
        if not self.db.profile.locked then
            self.frames.starframe:AO_Unlock ()
        end
        self.frames.starframe:Show ()
    end

    self:Print ("now active")
    self.enabled = true
end

function AO:do_disable ()
    if not self.enabled then return end

    self.frames.main:SetScript ("OnUpdate", nil)
    self:UnregisterEvent ("COMBAT_LOG_EVENT_UNFILTERED")
    self:UnregisterEvent ("CHAT_MSG_MONSTER_YELL")
    self:dismiss_star_tracking ()

    self:Print ("now inactive")
    self.enabled = false
end

function AO:do_initialize ()
    if self.initialized then return end

    self.frames:Initialize ()

    self.initialized = true
end


-- Addon events
function AO:OnChatCmd (arg)
    if not arg or arg == "" then
        self:Print ("/algalon <config|on|off|status>");   
    elseif arg == "config" then
        InterfaceOptionsFrame_OpenToCategory (self.cfgdlg.BlizOptions[NAME].frame)
    elseif arg == "on" then
        self:do_enable ()
    elseif arg == "off" then
        self:do_disable ()
    elseif arg == "status" then
        if self.enabled then
            self:Print ("currently active")
        else
            self:Print ("currently inactive")
        end
        if self.initialized then
            self:Print ("fully initialized")
        else
            self:Print ("not yet initialized (will happen on-demand)")
        end
    else
        self:Print ("unknown command: "..arg)
    end
end

function AO:OnInitialize ()
    -- Set up configuration panel
    LibStub ("AceConfigRegistry-3.0"):RegisterOptionsTable (NAME, options)
    self.cfgdlg = LibStub ("AceConfigDialog-3.0")
    self.cfgdlg:AddToBlizOptions (NAME, GetAddOnMetadata (NAME, "Title"))
    
    self:RegisterChatCommand ("algalon", "OnChatCmd")

    -- Prepare config db
    self.db = LibStub ("AceDB-3.0"):New ("AlgalonObserverDB", defaults)
    self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged") 
    options.args.profiles = LibStub ("AceDBOptions-3.0"):GetOptionsTable (self.db)
end

function AO:OnEnable ()
    -- Set up the triggers to do the actual initialisation if/when needed
    self:RegisterEvent ("PLAYER_TARGET_CHANGED")
    self:RegisterEvent ("ZONE_CHANGED")
    self:RegisterEvent ("ZONE_CHANGED_INDOORS")
    self:RegisterEvent ("ZONE_CHANGED_NEW_AREA")
end

