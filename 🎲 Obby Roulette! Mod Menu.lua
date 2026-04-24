local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

if not game:IsLoaded() then 
    game.Loaded:wait()
end

local Window = Rayfield:CreateWindow({
    Name = "🎲 Obby Roulette! Mod Menu",
    LoadingTitle = "Loading 🎲 Obby Roulette",
    LoadingSubtitle = "by InitialsAndVoices and miffy",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "InitialsScripts",
        FileName = "WinpadAutoConfig"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MusicTab = Window:CreateTab("Music", "boom-box")
local VisualTab = Window:CreateTab("Visual", "eye")

-- ==================== VARIABLES ====================
local invisAutoFarmEnabled = false
local antiKillEnabled = false
local espEnabled = false

local winpadHighlights = {}

local antiKillConnection = nil
local espConnection = nil
local antiAFKConnection = nil
local lastAntiAFKTime = 0

local fullProtectionConnection = nil

local WalkSpeedValue = 16

-- ==================== MUSIC PLAYER VARIABLES ====================
local musicSound = nil
local currentAudioId = 0
local musicVolume = 1
local musicLooped = false
local musicStartTimeValue = 0

-- ==================== CUSTOM TAG PERSISTENCE ====================
local customTagText = nil
local customTagColor = nil
local customTagFontName = nil

local LocalPlayer = game.Players.LocalPlayer

local function GetTag()
    local Character = workspace:WaitForChild(LocalPlayer.Name)
    local Head = Character:WaitForChild("Head")
    local CosmeticTag = Head:FindFirstChild("CosmeticTag")
    if not CosmeticTag then return nil end
    local Label = CosmeticTag:FindFirstChild("TextLabel")
    if not Label then return nil end
    return Label
end

local function applyCustomTag()
    local label = GetTag()
    if not label then return end
    if customTagText ~= nil then label.Text = customTagText end
    if customTagColor ~= nil then label.TextColor3 = customTagColor end
    if customTagFontName ~= nil then
        pcall(function() label.Font = Enum.Font[customTagFontName] end)
    end
end

local function setupTagMonitor(character)
    if not character then return end
    local head = character:WaitForChild("Head", 5)
    if not head then return end
    head.DescendantAdded:Connect(function(descendant)
        if descendant.Name == "CosmeticTag" then
            task.wait(0.5)
            applyCustomTag()
        end
    end)
    task.spawn(applyCustomTag)
end

if LocalPlayer.Character then
    setupTagMonitor(LocalPlayer.Character)
end
LocalPlayer.CharacterAdded:Connect(function(character)
    task.wait(1)
    setupTagMonitor(character)
end)

local Fonts = {}
for _, font in ipairs(Enum.Font:GetEnumItems()) do
    table.insert(Fonts, font.Name)
end

-- ==================== HELPERS ====================
local function findWinpad()
    return workspace:FindFirstChild("winpad", true)
end

local function getMapName()
    local winpad = findWinpad()
    if not winpad then return "Unknown Map" end
    local ancestor = winpad.Parent
    while ancestor and ancestor ~= workspace do
        if (ancestor:IsA("Model") or ancestor:IsA("Folder")) and ancestor.Parent == workspace then
            return ancestor.Name
        end
        ancestor = ancestor.Parent
    end
    return "Unknown Map"
end

local function teleportToWinpad(winpad)
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local offset = Vector3.new(0, (winpad.Size.Y / 2) + 5, 0)
    root.CFrame = CFrame.new(winpad.Position + offset)
end

-- ==================== IMPROVED ANTI-KILL (Makes Hazards Do No Damage) ====================
local function isHazard(name)
    if not name then return false end
    name = name:lower()
    return name:find("kill") or name:find("lava") or name:find("death") or name:find("deathzone") or 
           name:find("void") or name:find("fallkill") or name:find("hurt") or name:find("spike") or 
           name:find("poison") or name:find("dmg") or name:find("trap") or name:find("fire") or 
           name:find("acid") or name:find("killbrick") or name:find("killpart")
end

local function disableHazard(part)
    if not part or part.Name == "winpad" or not part:IsA("BasePart") then return end
    
    if not isHazard(part.Name) then return end

    pcall(function()
        part.CanTouch = false
        local ti = part:FindFirstChild("TouchInterest")
        if ti then ti:Destroy() end
        part.CanCollide = false
        part.CanQuery = false
    end)

    -- Disable all child parts that are also hazards
    for _, obj in ipairs(part:GetDescendants()) do
        if obj:IsA("BasePart") and obj.Name ~= "winpad" and isHazard(obj.Name) then
            pcall(function()
                obj.CanTouch = false
                local ti2 = obj:FindFirstChild("TouchInterest")
                if ti2 then ti2:Destroy() end
                obj.CanCollide = false
                obj.CanQuery = false
            end)
        end
    end
end

local function startFullProtection()
    if fullProtectionConnection then return end

    local function protectAll()
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") then
                local char = LocalPlayer.Character
                if char and obj:IsDescendantOf(char) then continue end
                disableHazard(obj)
            end
        end
    end

    protectAll()

    fullProtectionConnection = workspace.DescendantAdded:Connect(function(child)
        if child:IsA("BasePart") then
            local char = LocalPlayer.Character
            if char and child:IsDescendantOf(char) then return end
            disableHazard(child)
        end
    end)
end

local function stopFullProtection()
    if fullProtectionConnection then
        fullProtectionConnection:Disconnect()
        fullProtectionConnection = nil
    end
end

local function startAntiKill()
    if antiKillConnection then return end

    -- Initial scan for all hazards
    for _, v in ipairs(workspace:GetDescendants()) do
        if isHazard(v.Name) then
            disableHazard(v)
        end
    end

    antiKillConnection = workspace.DescendantAdded:Connect(function(child)
        if not antiKillEnabled then return end
        if isHazard(child.Name) then
            task.wait(0.05)
            disableHazard(child)
        end
    end)

    startFullProtection()
end

local function stopAntiKill()
    if antiKillConnection then
        antiKillConnection:Disconnect()
        antiKillConnection = nil
    end
    stopFullProtection()
end

-- ==================== ANTI-AFK ====================
local function startAntiAFK()
    if antiAFKConnection then return end
    antiAFKConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not invisAutoFarmEnabled then return end
        local now = tick()
        if now - lastAntiAFKTime >= 30 then
            lastAntiAFKTime = now
            pcall(function()
                local vu = game:GetService("VirtualUser")
                vu:CaptureController()
                vu:ClickButton1(Vector2.new(0, 0))
            end)
        end
    end)
end

local function stopAntiAFK()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
    lastAntiAFKTime = 0
end

-- ==================== INVIS AUTO FARM (unchanged) ====================
local inv_trans = 0.75
local seat_pos = Vector3.new(-25.95, 400, 3537.55) 
local void_y = -50 
local cur_seat = nil

local function fix_invis()
    if cur_seat then pcall(function() cur_seat:Destroy() end) cur_seat = nil end
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
            if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
                v.Transparency = 0 
            end
        end
    end
end

local function run_invis(c)
    if not c or not invisAutoFarmEnabled then return end
    local hrp = c:WaitForChild("HumanoidRootPart", 5) 
    if not hrp then return end
    local old_cf = hrp.CFrame
    task.wait(0.05)
    pcall(function() c:MoveTo(seat_pos) end) 
    task.wait(0.05)
    if not c:FindFirstChild("HumanoidRootPart") or hrp.Position.Y < void_y then
        pcall(function() c:MoveTo(old_cf) end) 
        return
    end
    for _, p in pairs(c:GetDescendants()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            p.Transparency = inv_trans 
        end
    end
    local s = Instance.new('Seat', workspace)
    s.Anchored = false
    s.CanCollide = false
    s.Name = 'invischair'
    s.Transparency = 1
    s.Position = seat_pos 
    local w = Instance.new("Weld", s)
    w.Part0 = s
    local t = c:FindFirstChild("Torso") or c:FindFirstChild("UpperTorso")
    if t then
        w.Part1 = t
        task.wait()
        s.CFrame = old_cf 
        cur_seat = s
    else
        s:Destroy()
    end
end

local function apply_permanent_idle(character)
    local animateScript = character:WaitForChild("Animate", 5)
    if not animateScript then return end
    animateScript.Disabled = true
    local idleFolder = animateScript:FindFirstChild("idle")
    if not idleFolder then animateScript.Disabled = false return end
    local idleAnim = idleFolder:FindFirstChildOfClass("Animation")
    if not idleAnim then animateScript.Disabled = false return end
    local targetId = idleAnim.AnimationId
    local statesToOverride = {"run", "walk", "jump", "fall", "climb", "swim"}
    for _, stateName in pairs(statesToOverride) do
        local stateFolder = animateScript:FindFirstChild(stateName)
        if stateFolder then
            for _, obj in pairs(stateFolder:GetChildren()) do
                if obj:IsA("Animation") then
                    obj.AnimationId = targetId
                end
            end
        end
    end
    animateScript.Disabled = false
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        task.spawn(function()
            while character and character.Parent and animateScript.Parent do
                pcall(function()
                    if animateScript:FindFirstChild("walk") then animateScript.walk.Weight.Value = 0 end
                    if animateScript:FindFirstChild("run") then animateScript.run.Weight.Value = 0 end
                    if animateScript:FindFirstChild("idle") then animateScript.idle.Weight.Value = 1 end
                end)
                task.wait(1)
            end
        end)
    end
end

local function start_pad(obj)
    if obj.Name == "winpad" or obj.Name == " winpad " then
        task.delay(15, function()
            local rs = game:GetService("RunService").RenderStepped:Connect(function()
                if not obj or not obj.Parent or not LocalPlayer.Character then return end
                local target = LocalPlayer.Character:FindFirstChild("Torso") 
                               or LocalPlayer.Character:FindFirstChild("UpperTorso") 
                               or LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not target then return end
                if obj:IsA("BasePart") then
                    obj.CanCollide = false
                    obj.CFrame = target.CFrame 
                elseif obj:IsA("Model") then
                    for _, part in pairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then part.CanCollide = false end
                    end
                    obj:PivotTo(target.CFrame) 
                end
            end)
            obj.AncestryChanged:Connect(function()
                if not obj.Parent then rs:Disconnect() end
            end)
        end)
    end
end

local function startInvisAutoFarm()
    workspace.DescendantAdded:Connect(function(child)
        if not invisAutoFarmEnabled then return end
        if child.Name == "winpad" then
            task.wait(0.1)
            start_pad(child)
        end
    end)

    task.wait(0.2)
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "winpad" then start_pad(v) end
    end

    LocalPlayer.CharacterAdded:Connect(function(newChar)
        task.wait(0.5)
        if invisAutoFarmEnabled then
            run_invis(newChar)
            apply_permanent_idle(newChar)
        end
    end)

    if LocalPlayer.Character then
        run_invis(LocalPlayer.Character)
        apply_permanent_idle(LocalPlayer.Character)
    end

    startFullProtection()
    startAntiAFK()
end

local function stopInvisAutoFarm()
    fix_invis()
    stopFullProtection()
    stopAntiAFK()
end

-- ==================== ESP ====================
local function applyGreenESP(part)
    if not part or not part:IsA("BasePart") or winpadHighlights[part] then return end
    local highlight = Instance.new("Highlight")
    highlight.Name = "FinishESP"
    highlight.Adornee = part
    highlight.FillColor = Color3.fromRGB(0, 255, 0)
    highlight.OutlineColor = Color3.fromRGB(0, 255, 100)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = part
    winpadHighlights[part] = highlight
end

local function removeAllESP()
    for _, hl in pairs(winpadHighlights) do 
        if hl and hl.Parent then hl:Destroy() end 
    end
    winpadHighlights = {}
end

local function startESP()
    if espConnection then return end
    local current = findWinpad()
    if current then applyGreenESP(current) end
    espConnection = workspace.DescendantAdded:Connect(function(child)
        if not espEnabled then return end
        if child.Name == "winpad" then 
            task.wait(0.1) 
            applyGreenESP(child) 
        end
    end)
end

local function stopESP()
    if espConnection then espConnection:Disconnect() end
    espConnection = nil
    removeAllESP()
end

-- WalkSpeed
task.spawn(function()
    while true do
        task.wait(0.2)
        local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = WalkSpeedValue
        end
    end
end)

-- ==================== UI ====================
MainTab:CreateSection("Winpad Features")

MainTab:CreateButton({Name = "Teleport To Finish", Callback = function()
    local winpad = findWinpad()
    if winpad then
        Rayfield:Notify({Title = "Teleporting", Content = "Map: " .. getMapName(), Duration = 3})
        teleportToWinpad(winpad)
    else
        Rayfield:Notify({Title = "Error", Content = "No winpad found!", Duration = 5})
    end
end})

MainTab:CreateToggle({
    Name = "Auto Win [15 Seconds Win Time, and Invis]",
    CurrentValue = false,
    Callback = function(Value)
        invisAutoFarmEnabled = Value
        if Value then
            startInvisAutoFarm()
            Rayfield:Notify({Title = "Invis Auto Farm ENABLED", Content = "15 Seconds Win Time + Invis active!", Duration = 8})
        else
            stopInvisAutoFarm()
            Rayfield:Notify({Title = "Invis Auto Farm DISABLED", Content = "", Duration = 5})
        end
    end,
})

MainTab:CreateToggle({
    Name = "Finish Part ESP (Green Chams)",
    CurrentValue = false,
    Callback = function(Value) espEnabled = Value if Value then startESP() else stopESP() end end,
})

MainTab:CreateSection("Protection")

MainTab:CreateToggle({
    Name = "Anti Kill/Damage Bricks [Patched]",
    CurrentValue = false,
    Callback = function(Value)
        antiKillEnabled = Value
        if Value then
            startAntiKill()
            Rayfield:Notify({Title = "Anti-Kill ENABLED", Content = "All kill & damage bricks now do NO damage", Duration = 6})
        else
            stopAntiKill()
            Rayfield:Notify({Title = "Anti-Kill DISABLED", Content = "Hazards restored • Collisions normal", Duration = 5})
        end
    end,
})

MainTab:CreateSection("Player")

MainTab:CreateSlider({
    Name = "Walk Speed",
    Range = {16, 50},
    Increment = 1,
    CurrentValue = 16,
    Callback = function(Value)
        WalkSpeedValue = Value
    end,
})

-- ==================== MUSIC TAB ====================
MusicTab:CreateSection("🎵 Roblox Music Player")

MusicTab:CreateInput({
    Name = "Audio ID",
    CurrentValue = "",
    PlaceholderText = "Paste Roblox Audio ID here (numbers only)",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        currentAudioId = tonumber(Value) or 0
    end,
})

MusicTab:CreateInput({
    Name = "Volume (0.5 - 5)",
    CurrentValue = "1",
    PlaceholderText = "Default: 1",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        musicVolume = math.clamp(tonumber(Value) or 1, 0.5, 5)
        if musicSound then musicSound.Volume = musicVolume end
    end,
})

MusicTab:CreateInput({
    Name = "Start Time (seconds)",
    CurrentValue = "0",
    PlaceholderText = "0 = beginning",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        musicStartTimeValue = tonumber(Value) or 0
    end,
})

MusicTab:CreateToggle({
    Name = "Loop Audio",
    CurrentValue = false,
    Callback = function(Value)
        musicLooped = Value
        if musicSound then musicSound.Looped = Value end
    end,
})

MusicTab:CreateButton({Name = "▶️ Play Audio", Callback = function()
    if currentAudioId <= 0 then
        Rayfield:Notify({Title = "Music Error", Content = "Need a valid Audio ID first!", Duration = 4})
        return
    end
    if not musicSound then
        musicSound = Instance.new("Sound")
        musicSound.Name = "ObbyMusicPlayer"
        musicSound.Parent = workspace
    end
    musicSound.SoundId = "rbxassetid://" .. currentAudioId
    musicSound.Volume = musicVolume
    musicSound.Looped = musicLooped
    musicSound.TimePosition = musicStartTimeValue
    musicSound:Play()
    Rayfield:Notify({Title = "🎵 Now Playing", Content = "Audio ID: " .. currentAudioId, Duration = 4})
end})

MusicTab:CreateButton({Name = "⏸️ Pause", Callback = function() if musicSound then musicSound:Pause() end end})
MusicTab:CreateButton({Name = "▶️ Resume", Callback = function() if musicSound then musicSound:Resume() end end})
MusicTab:CreateButton({Name = "⏹️ Stop", Callback = function() if musicSound then musicSound:Stop() end end})

-- ==================== VISUAL TAB ====================
VisualTab:CreateInput({
    Name = "Custom Tag",
    CurrentValue = "",
    PlaceholderText = "Tag Text",
    RemoveTextAfterFocusLost = false,
    Callback = function(Text)
        customTagText = Text
        applyCustomTag()
    end,
})

VisualTab:CreateColorPicker({
    Name = "Tag Color",
    Color = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        customTagColor = Value
        applyCustomTag()
    end,
})

VisualTab:CreateDropdown({
    Name = "Fonts",
    Options = Fonts,
    CurrentOption = {},
    MultipleOptions = false,
    Callback = function(Options)
        if Options and Options[1] then
            customTagFontName = Options[1]
            applyCustomTag()
        end
    end,
})

VisualTab:CreateSection("Note: You need a tag equipped to use custom tag")

Rayfield:Notify({
    Title = "Script Loaded Successfully",
    Content = "✅ Anti-Kill updated!\nAll kill & damage bricks now do NO damage when enabled.",
    Duration = 8,
})
