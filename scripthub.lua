-- Rayfield Setup
Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "EpicFace Script Hub",
    Icon = 112697863135968,
    LoadingTitle = "EpicFace Interface Suite",
    LoadingSubtitle = "Made By Hkayy",
    Theme = "Ocean",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "EpicFaceFolder",
        FileName = "EpicFace Hub"
    },
    Discord = {
        Enabled = true,
        Invite = "rWrARV9FsZ",
        RememberJoins = true
    },
    KeySystem = true,
    KeySettings = {
        Title = "EpicFace Key System",
        Subtitle = "Join discord.gg/epicface",
        Note = "Key Is Found In Our Discord",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"EpicFaceMarket"}
    }
})

-- Tabs
local PlayerTab = Window:CreateTab("Player", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- Player Sliders
PlayerTab:CreateSlider({
    Name = "WalkSpeed Slider",
    Range = {0, 100},
    Increment = 10,
    Suffix = "Speed",
    CurrentValue = 10,
    Flag = "Slider1",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end,
})

PlayerTab:CreateSlider({
    Name = "JumpHeight Slider",
    Range = {0, 100},
    Increment = 10,
    Suffix = "Height",
    CurrentValue = 10,
    Flag = "Slider2",
    Callback = function(Value)
        game.Players.LocalPlayer.Character.Humanoid.JumpHeight = Value
    end,
})

-- ESP Core
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local camera = workspace.CurrentCamera
local localPlayer = Players.LocalPlayer

local espEnabled = false
local aimbotEnabled = false
local aiming = false
local aimKey = Enum.UserInputType.MouseButton2 -- Right-click
local beams = {}
local skeletons = {}

-- FOV Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 1
fovCircle.Radius = 200
fovCircle.Transparency = 0.4
fovCircle.Filled = false
fovCircle.Visible = false

-- Create Billboard
function createBillboard(player)
    local head = player.Character and player.Character:FindFirstChild("Head")
    if not head then return nil end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_Billboard"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel", billboard)
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.5
    label.Font = Enum.Font.SourceSansBold
    label.TextScaled = true

    billboard.Parent = head
    return label
end

-- Beam
function createBeam(targetHRP)
    local myHRP = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myHRP or not targetHRP then return end

    local a0 = Instance.new("Attachment", myHRP)
    local a1 = Instance.new("Attachment", targetHRP)

    local beam = Instance.new("Beam")
    beam.Attachment0 = a0
    beam.Attachment1 = a1
    beam.Width0 = 0.1
    beam.Width1 = 0.1
    beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
    beam.FaceCamera = true
    beam.Parent = myHRP

    return {beam = beam, attachment0 = a0, attachment1 = a1}
end

-- Viewport
local function worldToViewport(position)
    local vector, onScreen = camera:WorldToViewportPoint(position)
    return vector, onScreen
end

-- Clear ESP
local function clearESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            local head = player.Character:FindFirstChild("Head")
            if head then
                local billboard = head:FindFirstChild("ESP_Billboard")
                if billboard then billboard:Destroy() end
            end
        end

        if beams[player] then
            for _, obj in pairs(beams[player]) do
                if obj and obj.Parent then obj:Destroy() end
            end
            beams[player] = nil
        end

        if skeletons[player] then
            for _, line in pairs(skeletons[player]) do
                if line then line:Remove() end
            end
            skeletons[player] = nil
        end
    end
end

-- Skeleton ESP
local function drawSkeleton(player)
    local char = player.Character
    if not char then return end

    local parts = {
        Head = char:FindFirstChild("Head"),
        Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso"),
        LowerTorso = char:FindFirstChild("LowerTorso"),
        LeftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm"),
        RightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm"),
        LeftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg"),
        RightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")
    }

    if not skeletons[player] then skeletons[player] = {} end
    local s = skeletons[player]

    local function lineBetween(a, b, index)
        if a and b then
            local aPos, aOnScreen = worldToViewport(a.Position)
            local bPos, bOnScreen = worldToViewport(b.Position)
            if aOnScreen and bOnScreen then
                s[index] = s[index] or Drawing.new("Line")
                local line = s[index]
                line.Visible = true
                line.From = Vector2.new(aPos.X, aPos.Y)
                line.To = Vector2.new(bPos.X, bPos.Y)
                line.Color = Color3.new(1, 1, 1)
                line.Thickness = 1
                line.Transparency = 0.8
                return
            end
        end
        if s[index] then s[index].Visible = false end
    end

    lineBetween(parts.Head, parts.Torso, 1)
    lineBetween(parts.Torso, parts.LowerTorso, 2)
    lineBetween(parts.Torso, parts.LeftArm, 3)
    lineBetween(parts.Torso, parts.RightArm, 4)
    lineBetween(parts.LowerTorso, parts.LeftLeg, 5)
    lineBetween(parts.LowerTorso, parts.RightLeg, 6)
end

-- ESP Update
local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")

            local label = head:FindFirstChild("ESP_Billboard") and head.ESP_Billboard:FindFirstChildOfClass("TextLabel")
            if not label then label = createBillboard(player) end

            local dist = localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and
                math.floor((humanoidRootPart.Position - localPlayer.Character.HumanoidRootPart.Position).Magnitude) or 0

            local tool = "None"
            for _, item in ipairs(player.Backpack:GetChildren()) do
                if item:IsA("Tool") then
                    tool = item.Name
                    break
                end
            end

            label.Text = string.format("%s\nTool: %s\nDist: %d", player.Name, tool, dist)

            if not beams[player] then
                beams[player] = createBeam(humanoidRootPart)
            end

            drawSkeleton(player)
        end
    end
end

-- Aimbot
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == aimKey then
        aiming = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == aimKey then
        aiming = false
    end
end)

local function getClosestTarget()
    local shortestDistance = math.huge
    local targetPlayer = nil
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local head = player.Character.Head
            local screenPos, onScreen = camera:WorldToViewportPoint(head.Position)
            if onScreen then
                local distance = (Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                if distance < shortestDistance and distance < fovCircle.Radius then
                    shortestDistance = distance
                    targetPlayer = player
                end
            end
        end
    end
    return targetPlayer
end

local function aimAt(target)
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    local predicted = head.Position + head.Velocity * 0.05
    camera.CFrame = CFrame.new(camera.CFrame.Position, predicted)
end

-- Rayfield Toggles
MiscTab:CreateToggle({
    Name = "Toggle ESP with Beams + Skeleton",
    CurrentValue = false,
    Flag = "ESP_Toggle",
    Callback = function(state)
        espEnabled = state
        fovCircle.Visible = state or aimbotEnabled
        if not state then clearESP() end
    end,
})

MiscTab:CreateToggle({
    Name = "Enable Aimbot (Hold RMB)",
    CurrentValue = false,
    Flag = "Aimbot_Toggle",
    Callback = function(state)
        aimbotEnabled = state
        fovCircle.Visible = state or espEnabled
    end,
})

-- Main Loop
RunService.RenderStepped:Connect(function()
    if espEnabled then
        updateESP()
    end

    if aimbotEnabled and aiming then
        local target = getClosestTarget()
        if target then
            aimAt(target)
        end
    end

    -- FOV Circle follow mouse
    local mousePos = UserInputService:GetMouseLocation()
    fovCircle.Position = Vector2.new(mousePos.X, mousePos.Y + 36)
end)
