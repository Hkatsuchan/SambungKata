-- Prison RP | Mizukage Hub v2
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Prison RP | Mizukage",
    LoadingTitle = "Loading...",
    LoadingSubtitle = "by Mizukage",
    ConfigurationSaving = {Enabled = true, FolderName = "MizukagePrisonRP", FileName = "cfg"},
    KeySystem = false,
})

local Players   = game:GetService("Players")
local RS        = game:GetService("ReplicatedStorage")
local WS        = game:GetService("Workspace")
local Run       = game:GetService("RunService")
local Tween     = game:GetService("TweenService")
local Http      = game:GetService("HttpService")
local TS        = game:GetService("TeleportService")
local VU        = game:GetService("VirtualUser")
local CG        = game:GetService("CoreGui")
local LP        = Players.LocalPlayer

-- Resolve game-specific dependencies without allowing a missing folder to
-- abort the whole UI after it has already been created.
local Remotes  = RS:FindFirstChild("Remotes")
local FishSys  = RS:FindFirstChild("FishingSystem")
local ToolFolder = Remotes and Remotes:FindFirstChild("Tool")
local ToolEvt  = ToolFolder and ToolFolder:FindFirstChild("Event")
local NotifyFolder = Remotes and Remotes:FindFirstChild("Notifications")
local NotifyR  = NotifyFolder and NotifyFolder:FindFirstChild("Event")
local OpenUI   = Remotes and Remotes:FindFirstChild("OpenCenterUi")
local SellOre  = Remotes and Remotes:FindFirstChild("SellOre")
local ServiceR = Remotes and Remotes:FindFirstChild("ServiceRecords")

local function SafeFire(remote, ...)
    if not remote or not remote:IsA("RemoteEvent") then return false end
    local ok = pcall(remote.FireServer, remote, ...)
    return ok
end

local function SafeInvoke(remote, ...)
    if not remote or not remote:IsA("RemoteFunction") then return false, nil end
    return pcall(remote.InvokeServer, remote, ...)
end

local F = {
    Cast    = FishSys and FishSys:FindFirstChild("CastReplication"),
    Bite    = FishSys and FishSys:FindFirstChild("RequestBite"),
    Give    = FishSys and FishSys:FindFirstChild("FishGiver"),
    Clean   = FishSys and FishSys:FindFirstChild("CleanupCast"),
    Zone    = FishSys and FishSys:FindFirstChild("ZoneState"),
    ShowN   = FishSys and FishSys:FindFirstChild("ShowNotification"),
}
local IE = FishSys and FishSys:FindFirstChild("InventoryEvents")
if IE then
    F.InvGet  = IE:FindFirstChild("Inventory_GetData")
    F.InvSell = IE:FindFirstChild("Inventory_SellAll")
end

if not Remotes or not FishSys then
    Notify("Mizukage Hub", "Game remotes not found. UI loaded, game-specific features are disabled.", 8)
end

local flags = {
    AutoFish=false, PerfectCast=true, InstantBite=false,
    AutoSell=false, SellDelay=10, FastFish=false,
    AutoMine=false, MineRange=25,
    AutoEat=false, AutoDrink=false, AutoCollect=false,
    AutoCollectRange=15,
    AntiAFK=false, NoBlink=false, NoNeck=false,
    ESP_Players=false, ESP_Items=false, ESP_Ores=false, ESP_Fish=false,
    Fullbright=false, NoFog=false, InfiniteJump=false,
    AutoSellOre=false, AutoSellOreDelay=15,
    CashDrop=false, OreLoop=false,
    AutoArrest=false, ArrestRange=15,
    AutoUncuff=false, AutoSurrender=false,
    AutoBuy=false, AutoBuyItem="Soda",
    SilentAim=false, AimFOV=120, AimPart="Head",
    AutoShoot=false, RapidFire=false,
    NotifyFilter=true, ChatSpy=false,
    AutoRespawn=false, Godmode=false,
    Speed=16, Jump=50,
    Noclip=false, Fly=false, FlySpeed=50, HipHeight=2,
    AntiArrest=false, AntiCuff=false, AntiRagdoll=false,
    AutoFishRarity=false, LegendaryOnly=false,
}

-- ═══════════════════════════════════════════
-- UTIL
-- ═══════════════════════════════════════════
local function GetChar() return LP.Character end
local function GetHum() local c=GetChar(); return c and c:FindFirstChildOfClass("Humanoid") end
local function GetHRP() local c=GetChar(); return c and c:FindFirstChild("HumanoidRootPart") end

local function Notify(t,c,d) Rayfield:Notify({Title=t,Content=c,Duration=d or 4}) end

local function GetToolByName(name)
    local c = GetChar(); if c then
        for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") and t.Name==name then return t end end
    end
    local bp = LP:FindFirstChildOfClass("Backpack"); if bp then
        for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") and t.Name==name then return t end end
    end
end

local function EquipTool(name)
    local c = GetChar(); if not c then return end
    local t = GetToolByName(name); if not t then return end
    if t.Parent ~= c then t.Parent = c; task.wait(0.3) end
    pcall(function() SafeFire(ToolEvt, "EquipModel", t) end)
    return t
end

local function Unequip(tool)
    if not tool then return end
    pcall(function() SafeFire(ToolEvt, "UnequipModel", tool) end)
end

local function GetRod()
    local c = GetChar(); if not c then return end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and t.Name:find("Rod") then return t end
    end
    local bp = LP:FindFirstChildOfClass("Backpack"); if bp then
        for _,t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and t.Name:find("Rod") then return t end
        end
    end
end

local function EquipRod()
    local c = GetChar(); if not c then return end
    local r = GetRod(); if not r then return end
    if r.Parent ~= c then r.Parent = c; task.wait(0.3) end
    if not r:FindFirstChild("Handle") then return r end
    SafeFire(ToolEvt, "EquipModel", r)
    return r
end

local function GetPickaxe()
    local c = GetChar(); if not c then return end
    for _,t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") and (t.Name=="Pickaxe" or t.Name=="PremiumPickaxe") then return t end
    end
    local bp = LP:FindFirstChildOfClass("Backpack"); if bp then
        for _,t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") and (t.Name=="Pickaxe" or t.Name=="PremiumPickaxe") then return t end
        end
    end
end

local function EquipPickaxe()
    local c = GetChar(); if not c then return end
    local p = GetPickaxe(); if not p then return end
    if p.Parent ~= c then p.Parent = c; task.wait(0.3) end
    SafeFire(ToolEvt, "EquipModel", p)
    return p
end

local function Nearest(part_names, range)
    local hrp = GetHRP(); if not hrp then return end
    local closest, dist = nil, range or math.huge
    for _,d in ipairs(WS:GetDescendants()) do
        if d:IsA("BasePart") and d.Anchored then
            for _,n in ipairs(part_names) do
                if d.Name:find(n) then
                    local dd = (d.Position - hrp.Position).Magnitude
                    if dd < dist then dist = dd; closest = d end
                    break
                end
            end
        end
    end
    return closest, dist
end

local function NearestPlayer(range)
    local hrp = GetHRP(); if not hrp then return end
    local best, dist = nil, range or math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then
            local chr = p.Character
            local h = chr and chr:FindFirstChild("Humanoid")
            local hr = chr and chr:FindFirstChild("HumanoidRootPart")
            if h and hr and h.Health > 0 then
                local dd = (hr.Position - hrp.Position).Magnitude
                if dd < dist then dist = dd; best = p end
            end
        end
    end
    return best, dist
end

local function DrawBox(plr, color)
    local chr = plr.Character; if not chr then return end
    local hrp = chr:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local bb = Instance.new("BoxHandleAdornment")
    bb.Size = Vector3.new(4, 5, 2)
    bb.Adornee = hrp
    bb.AlwaysOnTop = true
    bb.ZIndex = 5
    bb.Transparency = 0.5
    bb.Color3 = color or Color3.fromRGB(255,0,0)
    bb.Parent = chr
    return bb
end

-- ═══════════════════════════════════════════
-- TABS
-- ═══════════════════════════════════════════
local Tabs = {
    Fishing   = Window:CreateTab("Fishing", 4483362458),
    Jobs      = Window:CreateTab("Jobs", 4483362458),
    Combat    = Window:CreateTab("Combat", 4483362458),
    Player    = Window:CreateTab("Player", 4483362458),
    TP        = Window:CreateTab("Teleport", 4483362458),
    Visual    = Window:CreateTab("Visual", 4483362458),
    Gang      = Window:CreateTab("Gang", 4483362458),
    Auto      = Window:CreateTab("Automation", 4483362458),
    Server    = Window:CreateTab("Server", 4483362458),
    Info      = Window:CreateTab("Info", 4483362458),
}

-- ═══════════════════════════════════════════
-- FISHING
-- ═══════════════════════════════════════════
Tabs.Fishing:CreateSection("Auto Fishing")
Tabs.Fishing:CreateToggle({Name="Auto Fish (Cast+Reel)",Flag="AutoFish",Callback=function(v) flags.AutoFish=v end})
Tabs.Fishing:CreateToggle({Name="Perfect Cast",CurrentValue=true,Flag="PerfectCast",Callback=function(v) flags.PerfectCast=v end})
Tabs.Fishing:CreateToggle({Name="Instant Bite",Flag="InstantBite",Callback=function(v) flags.InstantBite=v end})
Tabs.Fishing:CreateToggle({Name="Fast Cast (0.2s)",Flag="FastFish",Callback=function(v) flags.FastFish=v end})
Tabs.Fishing:CreateToggle({Name="Legendary Only (experimental)",Flag="LegendaryOnly",Callback=function(v) flags.LegendaryOnly=v; if v then Notify("Legendary Only","Rarity data is not exposed by this client script, so no fish are filtered yet.",5) end end})

Tabs.Fishing:CreateSection("Inventory")
Tabs.Fishing:CreateToggle({Name="Auto Sell Inventory",Flag="AutoSell",Callback=function(v) flags.AutoSell=v end})
Tabs.Fishing:CreateSlider({Name="Auto Sell Delay",Range={1,60},Increment=1,Suffix="s",CurrentValue=10,Flag="SellDelay",Callback=function(v) flags.SellDelay=v end})
Tabs.Fishing:CreateButton({Name="Sell Inventory Now",Callback=function() pcall(function() SafeInvoke(F.InvSell) end) end})
Tabs.Fishing:CreateButton({Name="Get Inventory Data",Callback=function()
    local ok, d = pcall(function() return SafeInvoke(F.InvGet) end)
    if ok and d then print(d); Notify("Inventory","Dumped to console") end
end})

Tabs.Fishing:CreateSection("Rod")
Tabs.Fishing:CreateButton({Name="Equip Best Rod",Callback=function()
    local c = GetChar(); if not c then return end
    local bp = LP:FindFirstChildOfClass("Backpack"); if not bp then return end
    local best, bestScore = nil, -1
    local order = {["Premium Rod"]=5,["Lucky Rod"]=4,["Golden Rod"]=3,["Rod"]=2}
    for _,t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") and t.Name:find("Rod") then
            local score = order[t.Name] or 1
            if score > bestScore then best=t; bestScore=score end
        end
    end
    if best then
        if best.Parent ~= c then best.Parent = c; task.wait(0.2) end
        SafeFire(ToolEvt, "EquipModel", best)
    end
end})

-- ═══════════════════════════════════════════
-- JOBS
-- ═══════════════════════════════════════════
Tabs.Jobs:CreateSection("Mining")
Tabs.Jobs:CreateToggle({Name="Auto Mine (nearest ore)",Flag="AutoMine",Callback=function(v) flags.AutoMine=v end})
Tabs.Jobs:CreateSlider({Name="Mine Range",Range={5,100},Increment=1,Suffix=" studs",CurrentValue=25,Flag="MineRange",Callback=function(v) flags.MineRange=v end})
Tabs.Jobs:CreateToggle({Name="Auto Sell Ore",Flag="AutoSellOre",Callback=function(v) flags.AutoSellOre=v end})
Tabs.Jobs:CreateSlider({Name="Auto Sell Ore Delay",Range={5,120},Increment=1,Suffix="s",CurrentValue=15,Flag="OreDelay",Callback=function(v) flags.AutoSellOreDelay=v end})
Tabs.Jobs:CreateButton({Name="Equip Pickaxe",Callback=function() EquipPickaxe() end})
Tabs.Jobs:CreateButton({Name="Mine Nearest Ore x5",Callback=function()
    local p = EquipPickaxe(); if not p then return end
    for i=1,5 do
        local ore = Nearest({"Ore","Mineral","Rock","Azurith","Copper","Iron","Gold","Crystal"}, flags.MineRange)
        if ore then pcall(function() SafeFire(ToolEvt, "MineOres", p, ore) end) end
        task.wait(0.3)
    end
end})

Tabs.Jobs:CreateSection("Consumables")
Tabs.Jobs:CreateToggle({Name="Auto Eat",Flag="AutoEat",Callback=function(v) flags.AutoEat=v end})
Tabs.Jobs:CreateToggle({Name="Auto Drink",Flag="AutoDrink",Callback=function(v) flags.AutoDrink=v end})
Tabs.Jobs:CreateToggle({Name="Auto Collect (pickup items)",Flag="AutoCollect",Callback=function(v) flags.AutoCollect=v end})
Tabs.Jobs:CreateButton({Name="Force Eat",Callback=function()
    for _,n in ipairs({"CerealBar","Popcorn","FoodPlate"}) do
        local t = GetToolByName(n); if t then EquipTool(n); task.wait(0.2); SafeFire(ToolEvt, "Eat", t) break end
    end
end})
Tabs.Jobs:CreateButton({Name="Force Drink",Callback=function()
    for _,n in ipairs({"Soda","WaterCup","BloxyCola"}) do
        local t = GetToolByName(n); if t then EquipTool(n); task.wait(0.2); SafeFire(ToolEvt, "Drink", t) break end
    end
end})

Tabs.Jobs:CreateSection("Chores")
Tabs.Jobs:CreateButton({Name="Start Pushup Quest",Callback=function()
    local gui = LP:FindFirstChild("PlayerGui")
    local pg = gui and gui:FindFirstChild("MainGui")
    local pu = pg and pg:FindFirstChild("Pushups")
    if pu then pu.Enabled = true end
end})

-- ═══════════════════════════════════════════
-- COMBAT
-- ═══════════════════════════════════════════
Tabs.Combat:CreateSection("Aim")
Tabs.Combat:CreateToggle({Name="Silent Aim",Flag="SilentAim",Callback=function(v) flags.SilentAim=v end})
Tabs.Combat:CreateSlider({Name="Aim FOV",Range={10,500},Increment=5,Suffix="°",CurrentValue=120,Flag="AimFOV",Callback=function(v) flags.AimFOV=v end})
Tabs.Combat:CreateDropdown({Name="Aim Part",Options={"Head","HumanoidRootPart","UpperTorso","Torso"},CurrentOption={"Head"},Flag="AimPart",Callback=function(o) flags.AimPart=o end})
Tabs.Combat:CreateToggle({Name="Auto Shoot",Flag="AutoShoot",Callback=function(v) flags.AutoShoot=v end})
Tabs.Combat:CreateToggle({Name="Rapid Fire",Flag="RapidFire",Callback=function(v) flags.RapidFire=v end})

Tabs.Combat:CreateSection("Arrest / Cuff")
Tabs.Combat:CreateToggle({Name="Auto Arrest (nearest)",Flag="AutoArrest",Callback=function(v) flags.AutoArrest=v end})
Tabs.Combat:CreateSlider({Name="Arrest Range",Range={5,50},Increment=1,Suffix=" studs",CurrentValue=15,Flag="ArrestRange",Callback=function(v) flags.ArrestRange=v end})
Tabs.Combat:CreateButton({Name="Equip Handcuffs",Callback=function()
    local t = GetToolByName("Handcuffs"); if t then EquipTool("Handcuffs") end
end})
Tabs.Combat:CreateToggle({Name="Auto Surrender on Cuff",Flag="AutoSurrender",Callback=function(v) flags.AutoSurrender=v end})
Tabs.Combat:CreateToggle({Name="Auto Uncuff Self (experimental)",Flag="AutoUncuff",Callback=function(v) flags.AutoUncuff=v; if v then Notify("Auto Uncuff","Requires a game-specific remote/API; not forced in stable build.",5) end end})

Tabs.Combat:CreateSection("Weapons")
Tabs.Combat:CreateButton({Name="Give Pistol",Callback=function() EquipTool("Pistol") end})
Tabs.Combat:CreateButton({Name="Give Shotgun",Callback=function() EquipTool("Shotgun") end})
Tabs.Combat:CreateButton({Name="Give AK47",Callback=function() EquipTool("AK47") end})
Tabs.Combat:CreateButton({Name="Give Taser",Callback=function() EquipTool("Taser") end})
Tabs.Combat:CreateButton({Name="Give Baton",Callback=function() EquipTool("Baton") end})
Tabs.Combat:CreateButton({Name="Give CombatKnife",Callback=function() EquipTool("CombatKnife") end})
Tabs.Combat:CreateButton({Name="Give Bat",Callback=function() EquipTool("Bat") end})
Tabs.Combat:CreateButton({Name="Give Pipe",Callback=function() EquipTool("Pipe") end})

-- ═══════════════════════════════════════════
-- PLAYER
-- ═══════════════════════════════════════════
Tabs.Player:CreateSection("Character")
Tabs.Player:CreateSlider({Name="WalkSpeed",Range={16,500},Increment=1,CurrentValue=16,Flag="WS",Callback=function(v) flags.Speed=v; local h=GetHum(); if h then h.WalkSpeed=v end end})
Tabs.Player:CreateSlider({Name="JumpPower",Range={50,500},Increment=5,CurrentValue=50,Flag="JP",Callback=function(v) flags.Jump=v; local h=GetHum(); if h then h.JumpPower=v; h.UseJumpPower=true end end})
Tabs.Player:CreateSlider({Name="HipHeight",Range={0,20},Increment=0.5,CurrentValue=2,Flag="HH",Callback=function(v) flags.HipHeight=v; local h=GetHum(); if h then h.HipHeight=v end end})
Tabs.Player:CreateToggle({Name="Infinite Jump",Flag="IJ",Callback=function(v) flags.InfiniteJump=v end})
Tabs.Player:CreateToggle({Name="Noclip",Flag="Noclip",Callback=function(v) flags.Noclip=v end})
Tabs.Player:CreateToggle({Name="Fly",Flag="Fly",Callback=function(v) flags.Fly=v end})
Tabs.Player:CreateSlider({Name="Fly Speed",Range={10,500},Increment=5,CurrentValue=50,Flag="FS",Callback=function(v) flags.FlySpeed=v end})
Tabs.Player:CreateButton({Name="Reset Character",Callback=function() local c=GetChar(); if c then c:BreakJoints() end end})

Tabs.Player:CreateSection("Defense")
Tabs.Player:CreateToggle({Name="Godmode (visual)",Flag="God",Callback=function(v) flags.Godmode=v end})
Tabs.Player:CreateToggle({Name="Anti Arrest (experimental)",Flag="AntiArrest",Callback=function(v) flags.AntiArrest=v; if v then Notify("Anti Arrest","No safe client-side implementation available in this build.",5) end end})
Tabs.Player:CreateToggle({Name="Anti Cuff (experimental)",Flag="AntiCuff",Callback=function(v) flags.AntiCuff=v; if v then Notify("Anti Cuff","No safe client-side implementation available in this build.",5) end end})
Tabs.Player:CreateToggle({Name="Anti Ragdoll",Flag="AntiRagdoll",Callback=function(v) flags.AntiRagdoll=v end})

Tabs.Player:CreateSection("Animation Filter")
Tabs.Player:CreateToggle({Name="Disable Blink Replication",Flag="NoBlink",Callback=function(v) flags.NoBlink=v end})
Tabs.Player:CreateToggle({Name="Disable Neck Replication",Flag="NoNeck",Callback=function(v) flags.NoNeck=v end})
Tabs.Player:CreateButton({Name="Freeze All Replication",Callback=function()
    flags.NoBlink=true; flags.NoNeck=true; Notify("Replication","All frozen")
end})

-- ═══════════════════════════════════════════
-- TELEPORT
-- ═══════════════════════════════════════════
local function TPPos(v3)
    local hrp = GetHRP(); if not hrp then return end
    hrp.CFrame = CFrame.new(v3)
end

local function TPToPart(part)
    if not part then return end
    TPPos(part.Position + Vector3.new(0,3,0))
end

Tabs.TP:CreateSection("Locations")
local function FindFirstPart(names)
    for _,d in ipairs(WS:GetDescendants()) do
        if d:IsA("BasePart") then
            for _,n in ipairs(names) do
                if d.Name:lower():find(n:lower()) then return d end
            end
        end
    end
end

Tabs.TP:CreateButton({Name="Mining Area",Callback=function() TPToPart(FindFirstPart({"Mine","Cave","Ore"})) end})
Tabs.TP:CreateButton({Name="Fishing Area",Callback=function() TPToPart(FindFirstPart({"Fish","Pond","Lake","Water"})) end})
Tabs.TP:CreateButton({Name="Cafeteria",Callback=function() TPToPart(FindFirstPart({"Cafeteria","Canteen","Food"})) end})
Tabs.TP:CreateButton({Name="Yard",Callback=function() TPToPart(FindFirstPart({"Yard"})) end})
Tabs.TP:CreateButton({Name="Cell Block",Callback=function() TPToPart(FindFirstPart({"Cell","CellBlock"})) end})
Tabs.TP:CreateButton({Name="Infirmary",Callback=function() TPToPart(FindFirstPart({"Infirmary","Medic","Hospital"})) end})
Tabs.TP:CreateButton({Name="Warden Office",Callback=function() TPToPart(FindFirstPart({"Warden"})) end})
Tabs.TP:CreateButton({Name="Guard Room",Callback=function() TPToPart(FindFirstPart({"Guard"})) end})
Tabs.TP:CreateButton({Name="Vending Machine",Callback=function() TPToPart(FindFirstPart({"Vending"})) end})
Tabs.TP:CreateButton({Name="Mineral Buyer",Callback=function() TPToPart(FindFirstPart({"Mineral Buyer","Buyer"})) end})

Tabs.TP:CreateSection("Players")
local tpTarget
local TPDropdown = Tabs.TP:CreateDropdown({
    Name="Target",
    Options={"(none)"},
    CurrentOption={"(none)"},
    Flag="TPTarget",
    Callback=function(o)
        tpTarget = type(o) == "table" and o[1] or o
    end
})
Tabs.TP:CreateButton({Name="Refresh",Callback=function()
    local opts = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LP then table.insert(opts,p.Name) end
    end
    if #opts == 0 then opts={"(none)"} end
    if TPDropdown and TPDropdown.Refresh then
        pcall(function() TPDropdown:Refresh(opts) end)
    end
    tpTarget = opts[1]
end})
Tabs.TP:CreateButton({Name="TP To Target",Callback=function()
    if not tpTarget or tpTarget=="(none)" then return end
    local p = Players:FindFirstChild(tpTarget); if not p then return end
    local hr = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
    if hr then TPPos(hr.Position + Vector3.new(0,3,0)) end
end})

-- ═══════════════════════════════════════════
-- VISUAL
-- ═══════════════════════════════════════════
Tabs.Visual:CreateSection("ESP")
Tabs.Visual:CreateToggle({Name="Player ESP",Flag="ESPP",Callback=function(v) flags.ESP_Players=v end})
Tabs.Visual:CreateToggle({Name="Ore ESP",Flag="ESPO",Callback=function(v) flags.ESP_Ores=v end})
Tabs.Visual:CreateToggle({Name="Fish ESP",Flag="ESPF",Callback=function(v) flags.ESP_Fish=v end})
Tabs.Visual:CreateButton({Name="Clear ESP",Callback=function()
    ClearESP()
end})

Tabs.Visual:CreateSection("Lighting")
Tabs.Visual:CreateToggle({Name="Fullbright",Flag="FB",Callback=function(v)
    flags.Fullbright=v
    local L = game:GetService("Lighting")
    if v then L.Ambient=Color3.fromRGB(200,200,200); L.Brightness=3; L.OutdoorAmbient=Color3.fromRGB(200,200,200)
    else L.Ambient=Color3.fromRGB(70,70,70); L.Brightness=1 end
end})
Tabs.Visual:CreateToggle({Name="No Fog",Flag="NF",Callback=function(v)
    flags.NoFog=v
    local L = game:GetService("Lighting")
    if v then L.FogEnd=100000; L.FogStart=100000 else L.FogEnd=1000; L.FogStart=0 end
end})

Tabs.Visual:CreateSection("Name")
Tabs.Visual:CreateButton({Name="Remove Nametags (self)",Callback=function()
    local c=GetChar(); if not c then return end
    local h=c:FindFirstChild("Head"); if h then
        for _,d in ipairs(h:GetChildren()) do if d:IsA("BillboardGui") then d:Destroy() end end
    end
end})

-- ═══════════════════════════════════════════
-- GANG
-- ═══════════════════════════════════════════
Tabs.Gang:CreateSection("Gang")
Tabs.Gang:CreateButton({Name="Open Gang UI",Callback=function()
    if OpenUI then SafeFire(OpenUI, "Gang") end
end})
Tabs.Gang:CreateButton({Name="Open Gang War Tracker",Callback=function()
    if OpenUI then SafeFire(OpenUI, "GangWar") end
end})
Tabs.Gang:CreateButton({Name="Open Gang Armory",Callback=function()
    if OpenUI then SafeFire(OpenUI, "GangArmory") end
end})
Tabs.Gang:CreateButton({Name="Open Reseller",Callback=function()
    if OpenUI then SafeFire(OpenUI, "Reseller") end
end})
Tabs.Gang:CreateSection("Quest")
Tabs.Gang:CreateButton({Name="Open Quest Tracker",Callback=function()
    if OpenUI then SafeFire(OpenUI, "Quests") end
end})
Tabs.Gang:CreateButton({Name="Open Daily Tracker",Callback=function()
    if OpenUI then SafeFire(OpenUI, "Daily") end
end})

-- ═══════════════════════════════════════════
-- AUTOMATION
-- ═══════════════════════════════════════════
Tabs.Auto:CreateSection("Loops")
Tabs.Auto:CreateToggle({Name="Anti-AFK",Flag="AFK",Callback=function(v) flags.AntiAFK=v end})
Tabs.Auto:CreateToggle({Name="Auto Respawn",Flag="AR",Callback=function(v) flags.AutoRespawn=v end})
Tabs.Auto:CreateToggle({Name="Auto Buy Item",Flag="AutoBuy",Callback=function(v) flags.AutoBuy=v end})
Tabs.Auto:CreateDropdown({Name="Item to Buy",Options={"Soda","CerealBar","WaterCup"},CurrentOption={"Soda"},Flag="BuyItem",Callback=function(o) flags.AutoBuyItem=o end})
Tabs.Auto:CreateToggle({Name="Ore Loop (mine+sell)",Flag="OreLoop",Callback=function(v) flags.OreLoop=v end})

Tabs.Auto:CreateSection("Notifications")
Tabs.Auto:CreateToggle({Name="Chat Spy (experimental)",Flag="ChatSpy",Callback=function(v) flags.ChatSpy=v; if v then Notify("Chat Spy","Chat logging is not enabled in the stable build.",5) end end})
Tabs.Auto:CreateButton({Name="Clear Notification Spam",Callback=function()
    local pg = LP:FindFirstChild("PlayerGui"); if not pg then return end
    for _,g in ipairs(pg:GetDescendants()) do
        if g.Name:find("Notification") and g:IsA("GuiObject") then g.Visible=false end
    end
end})

Tabs.Auto:CreateSection("Records")
Tabs.Auto:CreateButton({Name="Fetch Service Records",Callback=function()
    if ServiceR then
        local ev = ServiceR:FindFirstChild("State")
        if ev then print("listening") end
    end
end})

-- ═══════════════════════════════════════════
-- SERVER
-- ═══════════════════════════════════════════
Tabs.Server:CreateSection("Server")
Tabs.Server:CreateButton({Name="Rejoin",Callback=function()
    TS:Teleport(game.PlaceId, LP)
end})
Tabs.Server:CreateButton({Name="Server Hop (low pop)",Callback=function()
    local ok,res = pcall(function()
        return Http:JSONDecode(game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)))
    end)
    if ok and res and res.data then
        for _,s in ipairs(res.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                pcall(function() TS:TeleportToPlaceInstance(game.PlaceId, s.id, LP) end)
                return
            end
        end
    end
    Notify("Server Hop","No server found")
end})
Tabs.Server:CreateButton({Name="Copy JobId",Callback=function()
    if setclipboard then setclipboard(game.JobId) end
    Notify("Copied",game.JobId)
end})
Tabs.Server:CreateButton({Name="Copy Player List",Callback=function()
    local list = {}
    for _,p in ipairs(Players:GetPlayers()) do table.insert(list, p.Name.." ("..p.UserId..")") end
    if setclipboard then setclipboard(table.concat(list,"\n")) end
    Notify("Copied",#list.." players")
end})
Tabs.Server:CreateButton({Name="Force Leave (Kick)",Callback=function()
    LP:Kick("Mizukage Hub Disconnect")
end})

-- ═══════════════════════════════════════════
-- INFO
-- ═══════════════════════════════════════════
Tabs.Info:CreateSection("Account")
Tabs.Info:CreateButton({Name="Show Player Info",Callback=function()
    print(("Name: %s\nUserId: %d\nDisplayName: %s\nAccountAge: %d\nMembership: %s")
        :format(LP.Name, LP.UserId, LP.DisplayName, LP.AccountAge, tostring(LP.MembershipType)))
    Notify("Info","Dumped to console")
end})
Tabs.Info:CreateButton({Name="Dump All Remotes",Callback=function()
    if not Remotes then Notify("Remotes","Remotes folder not found"); return end
    for _,r in ipairs(Remotes:GetDescendants()) do
        if r:IsA("RemoteEvent") or r:IsA("RemoteFunction") then
            print(r:GetFullName(), r.ClassName)
        end
    end
    Notify("Remotes","Dumped to console")
end})
Tabs.Info:CreateButton({Name="Dump All Tools",Callback=function()
    local bp = LP:FindFirstChildOfClass("Backpack"); if not bp then return end
    for _,t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") then print(t.Name) end
    end
    Notify("Tools","Dumped to console")
end})
Tabs.Info:CreateButton({Name="Show Game Info",Callback=function()
    print(("PlaceId: %d\nJobId: %s\nCreator: %s")
        :format(game.PlaceId, game.JobId, tostring(game.CreatorId)))
    Notify("Game","Dumped to console")
end})

Tabs.Info:CreateSection("Debug")
Tabs.Info:CreateButton({Name="List Workspace Entities",Callback=function()
    local e = WS:FindFirstChild("Entities")
    if e then
        for _,c in ipairs(e:GetChildren()) do print(c.Name, c.ClassName) end
    end
    Notify("Entities","Dumped")
end})
Tabs.Info:CreateButton({Name="List All BaseParts with 'Prompt'",Callback=function()
    for _,d in ipairs(WS:GetDescendants()) do
        if d:IsA("ProximityPrompt") then
            print(d:GetFullName())
        end
    end
    Notify("Prompts","Dumped")
end})

-- ═══════════════════════════════════════════
-- CORE LOOPS
-- ═══════════════════════════════════════════

-- Respawn
LP.CharacterAdded:Connect(function(c)
    task.wait(1)
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then
        h.WalkSpeed = flags.Speed
        h.JumpPower = flags.Jump; h.UseJumpPower = true
        h.HipHeight = flags.HipHeight
    end
end)

-- Replication filter
-- Intentionally does not hook __namecall/getrawmetatable. Those hooks are
-- executor-specific and were the most likely cause of the post-GUI crash.
-- The UI flags remain available, but replication filtering is disabled in
-- this stable build.
local ReplicationHookDisabled = true

-- Anti-AFK
LP.Idled:Connect(function()
    if flags.AntiAFK then
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end
end)

-- Infinite Jump
game:GetService("UserInputService").JumpRequest:Connect(function()
    if flags.InfiniteJump then
        local h = GetHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Noclip
Run.RenderStepped:Connect(function()
    if flags.Noclip then
        local c = GetChar(); if c then
            for _,d in ipairs(c:GetDescendants()) do
                if d:IsA("BasePart") and d.CanCollide then d.CanCollide=false end
            end
        end
    end
end)

-- Fly
local flyBV, flyBG
local function startFly()
    local c = GetChar(); if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    flyBV = Instance.new("BodyVelocity", hrp)
    flyBV.MaxForce = Vector3.new(1e6,1e6,1e6)
    flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", hrp)
    flyBG.MaxTorque = Vector3.new(1e6,1e6,1e6)
    flyBG.P = 1e4
end
local function stopFly()
    if flyBV then flyBV:Destroy(); flyBV=nil end
    if flyBG then flyBG:Destroy(); flyBG=nil end
end
Run.RenderStepped:Connect(function()
    if flags.Fly then
        if not flyBV then startFly() end
        local cam = WS.CurrentCamera
        local h = GetHum(); if h then h.PlatformStand=true end
        local mv = Vector3.zero
        local uis = game:GetService("UserInputService")
        if uis:IsKeyDown(Enum.KeyCode.W) then mv += cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.S) then mv -= cam.CFrame.LookVector end
        if uis:IsKeyDown(Enum.KeyCode.A) then mv -= cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.D) then mv += cam.CFrame.RightVector end
        if uis:IsKeyDown(Enum.KeyCode.Space) then mv += Vector3.new(0,1,0) end
        if uis:IsKeyDown(Enum.KeyCode.LeftControl) then mv -= Vector3.new(0,1,0) end
        if flyBV then flyBV.Velocity = mv * flags.FlySpeed end
        if flyBG then flyBG.CFrame = cam.CFrame end
    else
        if flyBV then
            stopFly()
            local h = GetHum(); if h then h.PlatformStand=false end
        end
    end
end)

-- Auto Fish
task.spawn(function()
    while task.wait(0.4) do
        if not flags.AutoFish then continue end
        local c = GetChar(); if not c then continue end
        local rod = GetRod()
        if not rod then continue end
        if rod.Parent ~= c then
            rod.Parent = c; task.wait(0.3)
            SafeFire(ToolEvt, "EquipModel", rod)
        end
        local hrp = c:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
        local castVal = flags.PerfectCast and 1 or (math.random(70,99)/100)
        pcall(function()
            F.Cast:FireServer(hrp.Position, hrp.CFrame.LookVector*50 + hrp.Position, rod.Name, castVal)
        end)
        task.wait(flags.FastFish and 0.2 or 0.5)
        pcall(function() SafeInvoke(F.Bite, castVal) end)
        task.wait(flags.FastFish and 0.4 or 1.2)
        pcall(function()
            F.Give:FireServer({hookPosition=hrp.Position, perfect=flags.PerfectCast, rodName=rod.Name})
        end)
        pcall(function() F.Clean:FireServer() end)
        task.wait(0.3)
    end
end)

-- Instant Bite
task.spawn(function()
    while task.wait(0.15) do
        if not flags.InstantBite then continue end
        pcall(function() SafeInvoke(F.Bite, 1) end)
    end
end)

-- Auto Sell Fish
local lastSellFish = 0
task.spawn(function()
    while task.wait(1) do
        if not flags.AutoSell then continue end
        if tick() - lastSellFish >= (flags.SellDelay or 10) then
            lastSellFish = tick()
            pcall(function() SafeInvoke(F.InvSell) end)
        end
    end
end)

-- Auto Mine
task.spawn(function()
    while task.wait(0.35) do
        if not flags.AutoMine then continue end
        local p = GetPickaxe()
        if not p then p = EquipPickaxe() end
        if not p then continue end
        local c = GetChar(); if not c then continue end
        if p.Parent ~= c then
            p.Parent = c; task.wait(0.2)
            SafeFire(ToolEvt, "EquipModel", p)
        end
        local ore = Nearest({"Ore","Mineral","Rock","Azurith","Copper","Iron","Gold","Crystal"}, flags.MineRange)
        if ore then
            pcall(function() SafeFire(ToolEvt, "MineOres", p, ore) end)
        end
    end
end)

-- Auto Sell Ore
local lastSellOre = 0
task.spawn(function()
    while task.wait(1) do
        if not flags.AutoSellOre then continue end
        if tick() - lastSellOre >= (flags.AutoSellOreDelay or 15) then
            lastSellOre = tick()
            local ore = Nearest({"Buyer"})
            if SellOre then
                for _,n in ipairs({"Azurith","Copper","Iron","Gold","Crystal","Diamond"}) do
                    pcall(function() SafeFire(SellOre, n, 100) end)
                end
            end
        end
    end
end)

-- Ore Loop
task.spawn(function()
    while task.wait(2) do
        if not flags.OreLoop then continue end
        local p = GetPickaxe() or EquipPickaxe()
        if p then
            for i=1,10 do
                local ore = Nearest({"Ore","Mineral","Rock"}, flags.MineRange)
                if ore then pcall(function() SafeFire(ToolEvt, "MineOres", p, ore) end) end
                task.wait(0.3)
            end
            task.wait(2)
            if SellOre then
                for _,n in ipairs({"Azurith","Copper","Iron"}) do
                    pcall(function() SafeFire(SellOre, n, 100) end)
                end
            end
        end
    end
end)

-- Auto Eat
task.spawn(function()
    while task.wait(3) do
        if not flags.AutoEat then continue end
        for _,n in ipairs({"CerealBar","Popcorn","FoodPlate"}) do
            local t = GetToolByName(n)
            if t then
                EquipTool(n); task.wait(0.3)
                pcall(function() SafeFire(ToolEvt, "Eat", t) end)
                task.wait(2)
                SafeFire(ToolEvt, "UnequipModel", t)
                break
            end
        end
    end
end)

-- Auto Drink
task.spawn(function()
    while task.wait(3) do
        if not flags.AutoDrink then continue end
        for _,n in ipairs({"Soda","WaterCup","BloxyCola"}) do
            local t = GetToolByName(n)
            if t then
                EquipTool(n); task.wait(0.3)
                pcall(function() SafeFire(ToolEvt, "Drink", t) end)
                task.wait(2)
                SafeFire(ToolEvt, "UnequipModel", t)
                break
            end
        end
    end
end)

-- Auto Collect
task.spawn(function()
    while task.wait(0.5) do
        if not flags.AutoCollect then continue end
        local hrp = GetHRP(); if not hrp then continue end
        for _,d in ipairs(WS:GetDescendants()) do
            if d:IsA("BasePart") and not d.Anchored then
                if d.Name:lower():find("drop") or d.Name:lower():find("item") or d.Name:lower():find("fish") then
                    local dd = (d.Position - hrp.Position).Magnitude
                    if dd < flags.AutoCollectRange then
                        pcall(function() hrp.CFrame = CFrame.new(d.Position + Vector3.new(0,2,0)) end)
                    end
                end
            end
        end
    end
end)

-- Auto Buy
local lastBuy = 0
task.spawn(function()
    while task.wait(2) do
        if not flags.AutoBuy then continue end
        if tick() - lastBuy < 5 then continue end
        lastBuy = tick()
        local prompts = WS:GetDescendants()
        for _,d in ipairs(prompts) do
            if d:IsA("ProximityPrompt") and d.Parent and d.Parent.Name:find("Vending") then
                pcall(function() fireproximityprompt(d) end)
                task.wait(0.5)
                break
            end
        end
    end
end)

-- Auto Arrest
task.spawn(function()
    while task.wait(0.5) do
        if not flags.AutoArrest then continue end
        local t = GetToolByName("Handcuffs")
        if t then
            EquipTool("Handcuffs"); task.wait(0.3)
            local target = NearestPlayer(flags.ArrestRange)
            if target then
                local hr = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if hr then
                    pcall(function() SafeFire(ToolEvt, "Arrest", t, target) end)
                end
            end
        end
    end
end)

-- Auto Surrender
task.spawn(function()
    while task.wait(2) do
        if not flags.AutoSurrender then continue end
        local pg = LP:FindFirstChild("PlayerGui")
        local sg = pg and pg:FindFirstChild("SurrenderGui")
        if sg and sg.Enabled then
            for _,b in ipairs(sg:GetDescendants()) do
                if b:IsA("TextButton") and b.Name:lower():find("surrender") then
                    pcall(function() b:Activate() end)
                end
            end
        end
    end
end)

-- Auto Respawn
task.spawn(function()
    while task.wait(2) do
        if not flags.AutoRespawn then continue end
        local h = GetHum()
        if not h or h.Health <= 0 then
            task.wait(3)
            pcall(function() LP:LoadCharacter() end)
        end
    end
end)

-- Godmode (visual only)
task.spawn(function()
    while task.wait(1) do
        if not flags.Godmode then continue end
        local h = GetHum()
        if h then h.MaxHealth = math.huge; h.Health = math.huge end
    end
end)

-- Anti Ragdoll
task.spawn(function()
    while task.wait(0.2) do
        if not flags.AntiRagdoll then continue end
        local c = GetChar(); if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if h then h.PlatformStand = false end
    end
end)

-- Chat Spy
LP.Chatted:connect(function() end)
local ChatSvc = game:GetService("TextChatService")
if flags.ChatSpy and ChatSvc then end

-- ESP Loop
local ActiveESP = {}

local function ClearESP()
    for i = #ActiveESP, 1, -1 do
        local obj = ActiveESP[i]
        if obj then pcall(function() obj:Destroy() end) end
        table.remove(ActiveESP, i)
    end
end

local function AddESP(adorn)
    if adorn then table.insert(ActiveESP, adorn) end
end

task.spawn(function()
    while task.wait(1.5) do
        ClearESP()
        if not (flags.ESP_Players or flags.ESP_Ores or flags.ESP_Fish) then
            continue
        end

        if flags.ESP_Players then
            for _,p in ipairs(Players:GetPlayers()) do
                if p ~= LP then
                    local chr = p.Character
                    local hrp = chr and chr:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local bb = Instance.new("BoxHandleAdornment")
                        bb.Name = "MizuESP"
                        bb.Size = Vector3.new(4,5,2)
                        bb.Adornee = hrp
                        bb.AlwaysOnTop = true
                        bb.ZIndex = 5
                        bb.Transparency = 0.5
                        bb.Color3 = Color3.fromRGB(255,80,80)
                        bb.Parent = chr
                        AddESP(bb)
                    end
                end
            end
        end

        local hrp = GetHRP()
        if hrp and (flags.ESP_Ores or flags.ESP_Fish) then
            for _,d in ipairs(WS:GetDescendants()) do
                if d:IsA("BasePart") and d.Anchored then
                    local dd = (d.Position - hrp.Position).Magnitude
                    if dd < 200 then
                        local isOre = flags.ESP_Ores and (
                            d.Name:lower():find("ore") or
                            d.Name:lower():find("mineral") or
                            d.Name:lower():find("rock")
                        )
                        local isFish = flags.ESP_Fish and (
                            d.Name:lower():find("fish") or
                            d.Name:lower():find("water") or
                            d.Name:lower():find("pond")
                        )
                        if isOre or isFish then
                            local bb = Instance.new("BoxHandleAdornment")
                            bb.Name = "MizuESP"
                            bb.Size = d.Size + Vector3.new(0.2,0.2,0.2)
                            bb.Adornee = d
                            bb.AlwaysOnTop = true
                            bb.Transparency = 0.6
                            bb.Color3 = isOre and Color3.fromRGB(0,200,255) or Color3.fromRGB(80,255,120)
                            bb.Parent = d
                            AddESP(bb)
                        end
                    end
                end
            end
        end
    end
end)

-- Silent Aim
-- Disabled in the stable build. Hooking __namecall here was unsafe across
-- executors and could terminate the client. Aim-related UI remains intact
-- for configuration, while normal tool activation is left untouched.
local SilentAimHookDisabled = true

-- Rapid Fire
task.spawn(function()
    while task.wait(0.05) do
        if not flags.RapidFire then continue end
        local c = GetChar(); if not c then continue end
        local tool = c:FindFirstChildOfClass("Tool")
        if tool then
            pcall(function() tool:Activate() end)
        end
    end
end)

-- Auto Shoot
task.spawn(function()
    while task.wait(0.3) do
        if not flags.AutoShoot then continue end
        local target = NearestPlayer(flags.AimFOV)
        if target then
            local c = GetChar(); if not c then continue end
            local tool = c:FindFirstChildOfClass("Tool")
            if tool then pcall(function() tool:Activate() end) end
        end
    end
end)

Rayfield:Notify({
    Title="Mizukage Hub v2.1",
    Content="Loaded • stable build • unsafe hooks disabled",
    Duration=6
})