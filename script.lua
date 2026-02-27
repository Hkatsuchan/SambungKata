-- Anti double execute
if getgenv().SambungKataHubV3 then return end
getgenv().SambungKataHubV3 = true

local SCRIPT_VERSION = "3.0"
local SCRIPT_URL = "https://raw.githubusercontent.com/Hkatsuchan/SambungKata/main/script.lua"
local UPDATE_URL = SCRIPT_URL .. "?v=" .. tostring(math.random(1000,9999))

local CONFIG_FILE = "SambungKata_Config.json"

local HttpService = game:GetService("HttpService")
local UIS = game:GetService("UserInputService")

-- Default config
getgenv().Config = {
    Mode = "LEGIT",
    AutoPlay = true
}

-- Load config
pcall(function()
    if isfile and readfile and isfile(CONFIG_FILE) then
        local data = readfile(CONFIG_FILE)
        local decoded = HttpService:JSONDecode(data)
        for i,v in pairs(decoded) do
            getgenv().Config[i] = v
        end
    end
end)

-- Save config
local function SaveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().Config))
        end
    end)
end

-- Auto update
task.spawn(function()
    pcall(function()
        local latest = game:HttpGet(UPDATE_URL)
        if latest and not latest:find(SCRIPT_VERSION) then
            warn("Update found, reloading...")
            task.wait(1)
            loadstring(latest)()
        end
    end)
end)

-- Database kata (lebih banyak)
local words = {
"aku","kamu","makan","minum","lari","rumah","hujan","jalan","ikan",
"ular","roti","indah","harimau","udang","gajah","hutan","nasi",
"susu","ularan","naga","api","ikanan","nanas","sate","elang",
"garam","mata","angin","negara","ayam","malam","motor","radio",
"orang","gula","laut","tanah","hijau","usaha","anak","kapal",
"pintu","ulari","ikanmu","ularmu","makanmu","rumahku","langit",
"tikus","sepatu","ularapi","ikanlaut","sambung","kata","kertas",
"senja","apiun","negri","indonesia","taman","malas","singa"
}

local usedWords = {}

-- Cari kata
local function GetWord(letter)
    for _,w in pairs(words) do
        if not usedWords[w] then
            if not letter or w:sub(1,1) == letter then
                usedWords[w] = true
                return w
            end
        end
    end

    usedWords = {}
    return words[math.random(1,#words)]
end

-- Remote scan
local Remote = nil

local function ScanRemote()
    for _,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            local n = string.lower(v.Name)
            if n:find("kata") or n:find("word") or n:find("submit") or n:find("answer") then
                return v
            end
        end
    end
end

task.spawn(function()
    while not Remote do
        Remote = ScanRemote()
        task.wait(1)
    end
end)

-- AUTO SCAN HURUF (FITUR BARU)
local LastLetter = nil

-- Scan dari GUI
local function ScanLetterGUI()
    for _,v in pairs(game:GetDescendants()) do
        if v:IsA("TextLabel") then
            local text = string.lower(v.Text)
            if #text == 1 then
                LastLetter = text
                return
            end
        end
    end
end

-- Scan dari remote (lebih akurat)
local function HookRemote()
    for _,v in pairs(game:GetDescendants()) do
        if v:IsA("RemoteEvent") then
            v.OnClientEvent:Connect(function(data)
                if typeof(data) == "string" then
                    local txt = string.lower(data)
                    if #txt == 1 then
                        LastLetter = txt
                    end
                end
            end)
        end
    end
end

HookRemote()

-- Delay system
local function GetDelay()
    if getgenv().Config.Mode == "FAST" then
        return math.random(2,4) / 10
    else
        return math.random(12,18) / 10
    end
end

-- Main loop
task.spawn(function()
    while task.wait(GetDelay()) do
        if getgenv().Config.AutoPlay and Remote then

            if not LastLetter then
                ScanLetterGUI()
            end

            local word = GetWord(LastLetter)

            pcall(function()
                Remote:FireServer(word)
            end)
        end
    end
end)

-- UI
local ScreenGui = Instance.new("ScreenGui")
local Frame = Instance.new("Frame")
local Toggle = Instance.new("TextButton")
local Mode = Instance.new("TextButton")
local Info = Instance.new("TextLabel")

ScreenGui.Parent = game.CoreGui

Frame.Parent = ScreenGui
Frame.Size = UDim2.new(0,220,0,140)
Frame.Position = UDim2.new(0,20,0,200)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)

Toggle.Parent = Frame
Toggle.Size = UDim2.new(1,0,0,40)
Toggle.Text = "Auto: ON"

Mode.Parent = Frame
Mode.Size = UDim2.new(1,0,0,40)
Mode.Position = UDim2.new(0,0,0,40)
Mode.Text = "Mode: LEGIT"

Info.Parent = Frame
Info.Size = UDim2.new(1,0,0,40)
Info.Position = UDim2.new(0,0,0,80)
Info.Text = "Scan: Active"

Toggle.MouseButton1Click:Connect(function()
    getgenv().Config.AutoPlay = not getgenv().Config.AutoPlay
    Toggle.Text = "Auto: " .. (getgenv().Config.AutoPlay and "ON" or "OFF")
    SaveConfig()
end)

Mode.MouseButton1Click:Connect(function()
    if getgenv().Config.Mode == "LEGIT" then
        getgenv().Config.Mode = "FAST"
    else
        getgenv().Config.Mode = "LEGIT"
    end
    Mode.Text = "Mode: " .. getgenv().Config.Mode
    SaveConfig()
end)

-- Drag UI
local dragging
local dragInput
local dragStart
local startPos

Frame.InputBegan:Connect(function(input)
    if input.UserInputType.Name == "MouseButton1" then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position
    end
end)

Frame.InputChanged:Connect(function(input)
    if input.UserInputType.Name == "MouseMovement" then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType.Name == "MouseButton1" then
        dragging = false
    end
end)

print("Sambung Kata V3 Loaded | Auto Scan Active")