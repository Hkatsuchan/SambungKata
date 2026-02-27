-- SAMBUNG KATA HUB (AUTO UPDATE + AUTO SAVE)

local SCRIPT_VERSION = "1.0"
local UPDATE_URL = "https://raw.githubusercontent.com/Hkatsuchan/SambungKata/main/version.txt"
local SCRIPT_URL = "https://raw.githubusercontent.com/Hkatsuchan/SambungKata/main/script.lua"

-- CONFIG SYSTEM
local CONFIG_FILE = "SambungKataConfig.json"

local HttpService = game:GetService("HttpService")

getgenv().Config = {
    AutoWin = false,
    Mode = "FAST"
}

-- LOAD CONFIG
local function loadConfig()
    if isfile and isfile(CONFIG_FILE) then
        local data = readfile(CONFIG_FILE)
        local decoded = HttpService:JSONDecode(data)
        for k,v in pairs(decoded) do
            getgenv().Config[k] = v
        end
    end
end

-- SAVE CONFIG
local function saveConfig()
    if writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(getgenv().Config))
    end
end

loadConfig()

-- AUTO UPDATE SYSTEM
task.spawn(function()
    pcall(function()
        local latest = game:HttpGet(UPDATE_URL)
        if latest and latest ~= SCRIPT_VERSION then
            warn("Script update ditemukan:", latest)

            loadstring(game:HttpGet(SCRIPT_URL))()
        end
    end)
end)

-- VARIABLES
local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local submitEvent = nil

-- DETECT REMOTE
for _,v in pairs(rs:GetDescendants()) do
    if v:IsA("RemoteEvent") then
        local name = v.Name:lower()
        if name:find("kata") or name:find("word") or name:find("submit") then
            submitEvent = v
        end
    end
end

-- SUBMIT WORD
local function submitWord(word)
    pcall(function()
        if submitEvent then
            submitEvent:FireServer(word)
        else
            rs.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(word,"All")
        end
    end)
end

-- WORD DATABASE
local words = {
"kamu","makan","ikan","nasi","indah","hutan","negara","air",
"rumah","hari","kuda","api","ayam","tanah","laut","jalan"
}

local usedWords = {}

-- AUTO LOOP
task.spawn(function()
    while task.wait(0.3) do
        if getgenv().Config.AutoWin then
            for _,word in ipairs(words) do
                if not usedWords[word] then
                    usedWords[word] = true
                    submitWord(word)

                    if getgenv().Config.Mode == "LEGIT" then
                        task.wait(2)
                    else
                        task.wait(0.3)
                    end
                end
            end
        end
    end
end)

-- UI
local gui = Instance.new("ScreenGui")
gui.Parent = playerGui
gui.Name = "SambungKataHub"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,240,0,150)
frame.Position = UDim2.new(0,20,0,200)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)

-- DRAG
local dragging
local dragInput
local dragStart
local startPos

frame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
    end
end)

frame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- TITLE
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Text = "Sambung Kata Hub"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.new(1,1,1)

-- AUTO BUTTON
local autoBtn = Instance.new("TextButton", frame)
autoBtn.Position = UDim2.new(0,0,0,40)
autoBtn.Size = UDim2.new(1,0,0,40)
autoBtn.Text = "Auto Win: "..(getgenv().Config.AutoWin and "ON" or "OFF")

autoBtn.MouseButton1Click:Connect(function()
    getgenv().Config.AutoWin = not getgenv().Config.AutoWin
    autoBtn.Text = "Auto Win: "..(getgenv().Config.AutoWin and "ON" or "OFF")
    saveConfig()
end)

-- MODE BUTTON
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Position = UDim2.new(0,0,0,90)
modeBtn.Size = UDim2.new(1,0,0,40)
modeBtn.Text = "Mode: "..getgenv().Config.Mode

modeBtn.MouseButton1Click:Connect(function()
    if getgenv().Config.Mode == "FAST" then
        getgenv().Config.Mode = "LEGIT"
    else
        getgenv().Config.Mode = "FAST"
    end
    modeBtn.Text = "Mode: "..getgenv().Config.Mode
    saveConfig()
end)

warn("Sambung Kata Hub Loaded (Auto Update + Config)")