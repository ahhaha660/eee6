local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

local running = false
local flying = false
local alive = false
local currentTween = nil

-- === Setup alive state on spawn/death ===
local function setupDeathCheck()
    local function onCharacter(char)
        local hum = char:WaitForChild("Humanoid", 5)
        alive = true
        if hum then
            hum.Died:Connect(function()
                alive = false
                if currentTween then
                    currentTween:Cancel()
                end
            end)
        end
    end

    if player.Character then
        onCharacter(player.Character)
    end

    player.CharacterAdded:Connect(onCharacter)
end

setupDeathCheck()

local function isPlayerAlive()
    return alive and player.Character and player.Character:FindFirstChild("HumanoidRootPart")
end

local function isRoundActive()
    local part = workspace:FindFirstChild("RoundTimerPart")
    return part and (part:GetAttribute("Time") or -1) > 0
end

local function isCoinBagFull()
    local gui = player:FindFirstChild("PlayerGui")
    local container = gui and gui:FindFirstChild("CoinContainer")
    local label = container and container:FindFirstChild("TextLabel")
    if not label then return false end
    local current, max = label.Text:match("(%d+)%s*/%s*(%d+)")
    return tonumber(current or 0) >= tonumber(max or 1)
end

local function flyTo(position)
    if flying or not isPlayerAlive() or not isRoundActive() then return end
    flying = true

    local char = player.Character
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then flying = false return end

    local dist = (hrp.Position - position).Magnitude
    local duration = dist / 25

    currentTween = TweenService:Create(
        hrp,
        TweenInfo.new(duration, Enum.EasingStyle.Linear),
        {CFrame = CFrame.new(position + Vector3.new(0, 5, 0))}
    )

    currentTween:Play()

    local start = tick()
    while currentTween.PlaybackState == Enum.PlaybackState.Playing do
        task.wait(0.1)
        if not isPlayerAlive() or not isRoundActive() or not running then
            currentTween:Cancel()
            break
        end
        if tick() - start > 10 then
            currentTween:Cancel()
            break
        end
    end

    flying = false
end

local function getCoinsSorted()
    local char = player.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end

    local coins = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") and obj.Name == "Coin_Server" then
            local dist = (hrp.Position - obj.Position).Magnitude
            table.insert(coins, {coin = obj, distance = dist})
        end
    end

    table.sort(coins, function(a, b)
        return a.distance < b.distance
    end)

    return coins
end

task.spawn(function()
    while true do
        task.wait(1)

        if not running or not isPlayerAlive() or not isRoundActive() or isCoinBagFull() then continue end

        local coins = getCoinsSorted()
        for _, data in ipairs(coins) do
            if not running or not isPlayerAlive() or not isRoundActive() or isCoinBagFull() then break end
            flyTo(data.coin.Position)
            task.wait(0.4)
        end
    end
end)

-- === Bigger GUI ===
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "CoinFarmGUI"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 100) -- bigger size
frame.Position = UDim2.new(0, 100, 0, 100)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
frame.Parent = gui

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 40) -- taller title
title.BackgroundTransparency = 1
title.Text = "Hold's MM2 Autofarm'"
title.TextColor3 = Color3.new(1, 1, 1)
title.Font = Enum.Font.SourceSansBold
title.TextSize = 28

local button = Instance.new("TextButton", frame)
button.Position = UDim2.new(0, 20, 0, 50)
button.Size = UDim2.new(1, -40, 0, 40) -- bigger button
button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
button.TextColor3 = Color3.new(1, 1, 1)
button.Font = Enum.Font.SourceSans
button.TextSize = 22
button.Text = "Start"

button.MouseButton1Click:Connect(function()
    running = not running
    button.Text = running and "Running..." or "Start"
    button.BackgroundColor3 = running and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(50, 50, 50)
end)
