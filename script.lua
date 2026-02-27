-- RENN LOADER V2
-- owner: renn

local cloneref = cloneref or function(x) return x end
local game = cloneref(game)

local Players = cloneref(game:GetService("Players"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local HttpService = cloneref(game:GetService("HttpService"))

local VERSION = "2.0.0"
local OWNER = "renn"

local CONFIG_FILE = "renn_loader_config.json"

-- default config
local default_config = {
    typing_delay = 1.2,
    random_delay = true,
    min_delay = 0.8,
    max_delay = 1.8
}

local config = default_config

-- load config
pcall(function()
    if isfile and isfile(CONFIG_FILE) then
        config = HttpService:JSONDecode(readfile(CONFIG_FILE))
    else
        writefile(CONFIG_FILE, HttpService:JSONEncode(default_config))
    end
end)

-- save config
local function save_config()
    if writefile then
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end
end

-- notify
local function notify(title, text)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- loader list
local loaders = {
    [130342654546662] = {
        name = "Sambung Kata",
        url = "https://api.luarmor.net/files/v4/loaders/4b4c6f8fb300d59c59b1f0ce609397e2.lua"
    },

    [129866685202296] = {
        name = "Last Letter",
        url = "https://api.luarmor.net/files/v4/loaders/ac23c180bd5691977221910e04ff2aa4.lua"
    }
}

local default_loader = {
    name = "Unsupported Game",
    url = ""
}

-- human delay system
local function get_delay()
    if config.random_delay then
        return math.random() * (config.max_delay - config.min_delay) + config.min_delay
    else
        return config.typing_delay
    end
end

-- send word with delay
function _G.SendWordWithDelay(callback, word)
    local delay_time = get_delay()
    task.wait(delay_time)
    callback(word)
end

-- load script
local function load_script(url)
    if url == "" then
        notify("RENN Loader", "Game tidak didukung")
        return
    end

    local success, err = pcall(function()
        local script = game:HttpGet(url)
        local func = loadstring(script)
        func()
    end)

    if not success then
        warn("Loader error:", err)
        notify("Loader Error", "Script gagal dijalankan")
    end
end

-- simple UI
task.spawn(function()
    pcall(function()
        local ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "RENN_UI"
        ScreenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

        local Frame = Instance.new("Frame")
        Frame.Size = UDim2.new(0,200,0,120)
        Frame.Position = UDim2.new(0,20,0,200)
        Frame.BackgroundTransparency = 0.2
        Frame.Parent = ScreenGui

        local Title = Instance.new("TextLabel")
        Title.Text = "RENN LOADER"
        Title.Size = UDim2.new(1,0,0,30)
        Title.Parent = Frame

        local Button = Instance.new("TextButton")
        Button.Text = "Toggle Random Delay"
        Button.Size = UDim2.new(1,0,0,40)
        Button.Position = UDim2.new(0,0,0,40)
        Button.Parent = Frame

        Button.MouseButton1Click:Connect(function()
            config.random_delay = not config.random_delay
            save_config()
            notify("Config Updated", "Random Delay: "..tostring(config.random_delay))
        end)
    end)
end)

-- main
local placeId = game.PlaceId
local selected = loaders[placeId] or default_loader

notify("RENN Loader", "Loading "..selected.name)

load_script(selected.url)

print("====== RENN LOADER V2 ======")
print("Owner:", OWNER)
print("Version:", VERSION)
print("Delay Mode:", config.random_delay and "Random" or "Fixed")