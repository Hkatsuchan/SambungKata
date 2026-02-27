-- SAMBUNG KATA PRO HUB

getgenv().AutoWin = false
getgenv().Mode = "FAST"

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local submitEvent = nil
local chatSystem = nil
local detectedGame = false

-- DETECT GAME
local function detectGame()
    if game.PlaceId then
        detectedGame = true
    end
end

-- DETECT REMOTE LEBIH LUAS
local function detectRemote()
    for _,v in pairs(rs:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n = string.lower(v.Name)
            if string.find(n,"kata")
            or string.find(n,"word")
            or string.find(n,"submit")
            or string.find(n,"answer")
            or string.find(n,"chat") then
                submitEvent = v
                warn("Remote ditemukan:", v.Name)
                return
            end
        end
    end
end

-- DETECT CHAT
local function detectChat()
    if game:FindService("TextChatService") then
        chatSystem = "new"
    else
        chatSystem = "old"
    end
end

detectGame()
detectRemote()
detectChat()

-- SUBMIT WORD
local function submitWord(word)
    pcall(function()
        if submitEvent then
            submitEvent:FireServer(word)
        else
            if chatSystem == "new" then
                game:GetService("TextChatService")
                .TextChannels.RBXGeneral:SendAsync(word)
            else
                rs.DefaultChatSystemChatEvents
                .SayMessageRequest:FireServer(word,"All")
            end
        end
    end)
end

-- WORD DATABASE
local words = {
"kamu","makan","ikan","nasi","indah","hutan","negara","air",
"rumah","hari","ikan","kuda","api","indonesia","ayam",
"mata","tanah","hujan","jalan","laut","tangan","garam"
}

local usedWords = {}

-- AUTO LOOP
task.spawn(function()
    while task.wait(0.25) do
        if getgenv().AutoWin then
            for _,word in ipairs(words) do
                if not usedWords[word] then
                    usedWords[word] = true
                    submitWord(word)

                    if getgenv().Mode == "LEGIT" then
                        task.wait(2)
                    else
                        task.wait(0.25)
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
frame.Size = UDim2.new(0,230,0,150)
frame.Position = UDim2.new(0,20,0,200)
frame.BackgroundColor3 = Color3.fromRGB(25,25,25)

-- DRAG UI
local dragging, dragInput, dragStart, startPos

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
autoBtn.Text = "Auto Win: OFF"

autoBtn.MouseButton1Click:Connect(function()
    getgenv().AutoWin = not getgenv().AutoWin
    autoBtn.Text = "Auto Win: "..(getgenv().AutoWin and "ON" or "OFF")
end)

-- MODE BUTTON
local modeBtn = Instance.new("TextButton", frame)
modeBtn.Position = UDim2.new(0,0,0,90)
modeBtn.Size = UDim2.new(1,0,0,40)
modeBtn.Text = "Mode: FAST"

modeBtn.MouseButton1Click:Connect(function()
    if getgenv().Mode == "FAST" then
        getgenv().Mode = "LEGIT"
    else
        getgenv().Mode = "FAST"
    end
    modeBtn.Text = "Mode: "..getgenv().Mode
end)

-- PLAYER INFO
local info = Instance.new("Frame", gui)
info.Position = UDim2.new(0,20,1,-90)
info.Size = UDim2.new(0,200,0,70)
info.BackgroundTransparency = 0.3

local avatar = Instance.new("ImageLabel", info)
avatar.Size = UDim2.new(0,50,0,50)
avatar.Position = UDim2.new(0,10,0,10)
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="
..player.UserId.."&width=420&height=420&format=png"

local nameLabel = Instance.new("TextLabel", info)
nameLabel.Position = UDim2.new(0,70,0,20)
nameLabel.Size = UDim2.new(0,120,0,30)
nameLabel.Text = player.Name
nameLabel.TextColor3 = Color3.new(1,1,1)
nameLabel.BackgroundTransparency = 1

warn("Sambung Kata Hub Loaded")