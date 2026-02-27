-- SAMBUNG KATA AUTO DETECT HUB

getgenv().AutoWin = false
getgenv().Mode = "FAST"

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rs = game:GetService("ReplicatedStorage")

local submitEvent = nil
local chatSystem = nil

-- DETECT REMOTE
local function detectRemote()
    for _,v in pairs(rs:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local name = string.lower(v.Name)
            if string.find(name,"word") 
            or string.find(name,"kata") 
            or string.find(name,"submit") 
            or string.find(name,"answer") then
                submitEvent = v
                print("Remote ditemukan:", v.Name)
                return
            end
        end
    end
end

-- DETECT CHAT SYSTEM
local function detectChat()
    if game:GetService("TextChatService") then
        chatSystem = "new"
    else
        chatSystem = "old"
    end
end

detectRemote()
detectChat()

-- SUBMIT WORD
local function submitWord(word)
    if submitEvent then
        pcall(function()
            submitEvent:FireServer(word)
        end)
    else
        if chatSystem == "new" then
            game:GetService("TextChatService").TextChannels.RBXGeneral:SendAsync(word)
        else
            game.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest:FireServer(word,"All")
        end
    end
end

-- WORD LIST
local words = {
    "kamu","makan","ikan","nasi","indah","hutan","negara","air",
    "rumah","hari","ikan","kuda","api","indonesia","ayam"
}

local usedWords = {}
local lastWord = nil

-- AUTO LOOP
task.spawn(function()
    while task.wait(0.2) do
        if getgenv().AutoWin then
            for _,word in ipairs(words) do
                if not usedWords[word] then
                    usedWords[word] = true
                    lastWord = word
                    submitWord(word)

                    if getgenv().Mode == "LEGIT" then
                        task.wait(2)
                    else
                        task.wait(0.2)
                    end
                end
            end
        end
    end
end)

-- UI HUB
local gui = Instance.new("ScreenGui", playerGui)
gui.Name = "SambungKataHub"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0,220,0,140)
frame.Position = UDim2.new(0,20,0,200)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)

local autoBtn = Instance.new("TextButton", frame)
autoBtn.Size = UDim2.new(1,0,0,40)
autoBtn.Text = "Auto Win: OFF"

autoBtn.MouseButton1Click:Connect(function()
    getgenv().AutoWin = not getgenv().AutoWin
    autoBtn.Text = "Auto Win: "..(getgenv().AutoWin and "ON" or "OFF")
end)

local modeBtn = Instance.new("TextButton", frame)
modeBtn.Position = UDim2.new(0,0,0,50)
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

-- PLAYER INFO (Avatar + Name)
local info = Instance.new("Frame", gui)
info.Position = UDim2.new(0,20,1,-90)
info.Size = UDim2.new(0,200,0,70)
info.BackgroundTransparency = 0.2

local avatar = Instance.new("ImageLabel", info)
avatar.Size = UDim2.new(0,50,0,50)
avatar.Position = UDim2.new(0,10,0,10)
avatar.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..player.UserId.."&width=420&height=420&format=png"

local nameLabel = Instance.new("TextLabel", info)
nameLabel.Position = UDim2.new(0,70,0,20)
nameLabel.Size = UDim2.new(0,120,0,30)
nameLabel.Text = player.Name
nameLabel.TextColor3 = Color3.new(1,1,1)
nameLabel.BackgroundTransparency = 1