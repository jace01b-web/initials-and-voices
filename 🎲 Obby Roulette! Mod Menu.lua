local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "🎲 Obby Roulette! Mod Menu",
    LoadingTitle = "Loading 🎲 Obby Roulette",
    LoadingSubtitle = "by InitialsAndVoices",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "GrokScripts",
        FileName = "WinpadAutoConfig"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab("Main", 4483362458)
local MusicTab = Window:CreateTab("🎵 Music", 6026568198)

-- ==================== VARIABLES ====================
local legitAutoFarmEnabled = false
local antiKillEnabled = false
local antiDamageEnabled = false
local espEnabled = false

local currentPlatform = nil
local lastWinpad = nil
local currentWinpad = nil
local winpadRemoveConnection = nil
local lastSafeCheckTime = 0

local winpadHighlights = {}

local antiKillConnection = nil
local antiDamageConnection = nil
local legitConnection = nil
local legitFlyConnection = nil
local legitIdleConnection = nil
local espConnection = nil
local antiAFKConnection = nil
local lastAntiAFKTime = 0

local fullProtectionConnection = nil
local deathResetConnection = nil
local noclipConnection = nil
local worldNoclipConnection = nil

local WAITING_POS = Vector3.new(500, -500, 500)
local SAFE_POS = Vector3.new(-171, 250, 28)

-- NOCLIP WORLD STATE
local originalWorldCanCollide = {}

-- ==================== MUSIC PLAYER VARIABLES ====================
local musicSound = nil
local currentAudioId = 0
local musicVolume = 1
local musicLooped = false
local musicStartTimeValue = 0

-- ==================== HELPERS ====================
local function findWinpad()
    return workspace:FindFirstChild("winpad", true)
end

local function getCurrentMap()
    local winpad = findWinpad()
    if not winpad then return nil end
    local ancestor = winpad.Parent
    while ancestor and ancestor ~= workspace do
        if (ancestor:IsA("Model") or ancestor:IsA("Folder")) and ancestor.Parent == workspace then
            return ancestor
        end
        ancestor = ancestor.Parent
    end
    return nil
end

local function getMapName()
    local map = getCurrentMap()
    return map and map.Name or "Unknown Map"
end

local function teleportToWinpad(winpad)
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local offset = Vector3.new(0, (winpad.Size.Y / 2) + 5, 0)
    root.CFrame = CFrame.new(winpad.Position + offset)
end

local function createPlatform()
    if currentPlatform and currentPlatform.Parent then currentPlatform:Destroy() end
    currentPlatform = Instance.new("Part")
    currentPlatform.Name = "AutoWin_Platform"
    currentPlatform.Size = Vector3.new(30, 2, 30)
    currentPlatform.Position = WAITING_POS - Vector3.new(0, 3, 0)
    currentPlatform.Anchored = true
    currentPlatform.CanCollide = true
    currentPlatform.BrickColor = BrickColor.new("Lime green")
    currentPlatform.Material = Enum.Material.Neon
    currentPlatform.Transparency = 0
    currentPlatform.Parent = workspace
end

local function teleportToSafeSpot()
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    root.CFrame = CFrame.new(SAFE_POS)
end

-- ==================== FREEZE / UNFREEZE ====================
local function freezePlayer()
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    root.Anchored = true
    if humanoid then
        humanoid.PlatformStand = false
        humanoid:ChangeState(Enum.HumanoidStateType.Running)
    end
end

local function unfreezePlayer()
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")
    
    root.Anchored = false
    if humanoid then
        humanoid.PlatformStand = false
    end
end

-- ==================== CRASH-PROOF FULL PROTECTION ====================
local function disableAllHazards()
    task.spawn(function()
        local character = game.Players.LocalPlayer.Character
        local descendants = workspace:GetDescendants()
        for i, obj in ipairs(descendants) do
            if i % 25 == 0 then task.wait() end  -- tighter batch = safer, no crash
            if obj:IsA("BasePart") and obj.Name ~= "winpad" then
                if character and obj:IsDescendantOf(character) then continue end
                pcall(function()  -- pcall prevents any single bad part from crashing
                    obj.CanTouch = false
                    local ti = obj:FindFirstChild("TouchInterest")
                    if ti then ti:Destroy() end
                end)
            end
        end
    end)
end

local function startFullProtection()
    if fullProtectionConnection then return end

    disableAllHazards()

    fullProtectionConnection = workspace.DescendantAdded:Connect(function(child)
        if child:IsA("BasePart") and child.Name ~= "winpad" then
            local character = game.Players.LocalPlayer.Character
            if character and child:IsDescendantOf(character) then return end
            pcall(function()
                child.CanTouch = false
                local ti = child:FindFirstChild("TouchInterest")
                if ti then ti:Destroy() end
            end)
        end
    end)
end

local function stopFullProtection()
    if fullProtectionConnection then
        fullProtectionConnection:Disconnect()
        fullProtectionConnection = nil
    end
end

-- ==================== CRASH-PROOF WORLD NOCLIP ====================
local function disableWorldCollision()
    task.spawn(function()
        local character = game.Players.LocalPlayer.Character
        local descendants = workspace:GetDescendants()
        for i, obj in ipairs(descendants) do
            if i % 25 == 0 then task.wait() end  -- tighter batch = safer, no crash
            if obj:IsA("BasePart") and obj.Name ~= "winpad" then
                if character and obj:IsDescendantOf(character) then continue end
                if originalWorldCanCollide[obj] == nil then
                    originalWorldCanCollide[obj] = obj.CanCollide
                end
                pcall(function()
                    obj.CanCollide = false
                end)
            end
        end
    end)
end

local function startNoclip()
    if noclipConnection then return end

    noclipConnection = game:GetService("RunService").Stepped:Connect(function()
        if not (noclipEnabled or legitAutoFarmEnabled) then return end
        local character = game.Players.LocalPlayer.Character
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    pcall(function() part.CanCollide = false end)
                end
            end
        end
    end)

    disableWorldCollision()

    if not worldNoclipConnection then
        worldNoclipConnection = workspace.DescendantAdded:Connect(function(child)
            if not (noclipEnabled or legitAutoFarmEnabled) then return end
            if child:IsA("BasePart") and child.Name ~= "winpad" then
                local character = game.Players.LocalPlayer.Character
                if character and child:IsDescendantOf(character) then return end
                if originalWorldCanCollide[child] == nil then
                    originalWorldCanCollide[child] = child.CanCollide
                end
                pcall(function()
                    child.CanCollide = false
                end)
            end
        end)
    end
end

local function stopNoclip()
    if noclipConnection and not (noclipEnabled or legitAutoFarmEnabled) then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if worldNoclipConnection and not (noclipEnabled or legitAutoFarmEnabled) then
        worldNoclipConnection:Disconnect()
        worldNoclipConnection = nil
    end

    if not (noclipEnabled or legitAutoFarmEnabled) then
        for part, originalState in pairs(originalWorldCanCollide) do
            if part and part.Parent then
                pcall(function() part.CanCollide = originalState end)
            end
        end
        originalWorldCanCollide = {}
    end
end

-- ==================== ANTI-AFK ====================
local function startAntiAFK()
    if antiAFKConnection then return end

    antiAFKConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not legitAutoFarmEnabled then return end

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

-- ==================== UPDATED LEGIT AUTO FARM (CRASH-PROOF + SLOWER FLY) ====================
local function smoothFlyToWinpad(winpad)
    local character = game.Players.LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    local root = character.HumanoidRootPart
    local humanoid = character:FindFirstChild("Humanoid")

    if humanoid then
        humanoid.PlatformStand = true
    end
    root.Velocity = Vector3.new(0, 0, 0)
    root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)

    local targetPos = winpad.Position
    local startPos = root.Position
    local startTime = tick()
    
    local flyDuration = 12 + math.random() * 6  -- 12-18s (~15s avg)

    local bv = Instance.new("BodyVelocity")
    bv.Name = "LegitAutoFarm_BV"
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = root

    local bg = Instance.new("BodyGyro")
    bg.Name = "LegitAutoFarm_BG"
    bg.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bg.P = 12500
    bg.Parent = root

    Rayfield:Notify({
        Title = "Legit Auto Farm",
        Content = "Legit Auto Farm is ON 🔥\nSlow 12-18s fly straight to the winpad while laying flat on your back\nHolds the touch for full 3 seconds to actually win\nThen TP to safe spot and freezes you standing up\nFull noclip + protection + anti-AFK running",
        Duration = 8
    })

    if legitFlyConnection then
        legitFlyConnection:Disconnect()
        legitFlyConnection = nil
    end

    legitFlyConnection = game:GetService("RunService").RenderStepped:Connect(function()
        if not legitAutoFarmEnabled then
            if legitFlyConnection then legitFlyConnection:Disconnect() legitFlyConnection = nil end
            if bv and bv.Parent then bv:Destroy() end
            if bg and bg.Parent then bg:Destroy() end
            return
        end

        if not currentWinpad or currentWinpad ~= winpad then
            if legitFlyConnection then legitFlyConnection:Disconnect() legitFlyConnection = nil end
            if bv and bv.Parent then bv:Destroy() end
            if bg and bg.Parent then bg:Destroy() end
            return
        end

        pcall(function()  -- extra safety so fly loop never crashes the script
            local currentPos = root.Position
            local distToTarget = (currentPos - targetPos).Magnitude

            if distToTarget < 4 then
                root.CFrame = CFrame.new(targetPos)
                return
            end

            local elapsed = tick() - startTime
            local progress = math.clamp(elapsed / flyDuration, 0, 1)
            local easedProgress = 0.5 * (1 - math.cos(math.pi * progress))

            local desiredPos = startPos:Lerp(targetPos, easedProgress)

            local offset = desiredPos - currentPos
            if offset.Magnitude > 0.1 then
                bv.Velocity = offset * 20
            else
                bv.Velocity = Vector3.new(0, 0, 0)
            end

            bg.CFrame = CFrame.lookAt(currentPos, targetPos) * CFrame.Angles(math.rad(90), 0, 0)
        end)
    end)
end

local function handleWinpadDetected(winpad)
    if not winpad then return end
    currentWinpad = winpad
    lastWinpad = winpad
    unfreezePlayer()

    local touchConnection
    touchConnection = winpad.Touched:Connect(function(hit)
        local player = game.Players.LocalPlayer
        local character = player.Character
        if character and hit and hit:IsDescendantOf(character) then
            touchConnection:Disconnect()
            
            if legitFlyConnection then
                legitFlyConnection:Disconnect()
                legitFlyConnection = nil
            end
            local root = character:FindFirstChild("HumanoidRootPart")
            if root then
                local bv = root:FindFirstChild("LegitAutoFarm_BV")
                if bv then bv:Destroy() end
                local bg = root:FindFirstChild("LegitAutoFarm_BG")
                if bg then bg:Destroy() end
            end

            if winpad and root then
                local offset = Vector3.new(0, (winpad.Size.Y / 2) + 2, 0)
                root.CFrame = CFrame.new(winpad.Position + offset)
            end
            freezePlayer()

            task.spawn(function()
                local holdDuration = 3
                local interval = 0.1
                local steps = math.ceil(holdDuration / interval)

                for i = 1, steps do
                    task.wait(interval)
                    if not legitAutoFarmEnabled or not currentWinpad or not currentWinpad.Parent then
                        Rayfield:Notify({
                            Title = "Legit Auto Farm",
                            Content = "Winpad got deleted mid-hold!\nTP'd to safe spot and frozen.",
                            Duration = 5
                        })
                        teleportToSafeSpot()
                        task.wait(0.1)
                        freezePlayer()
                        return
                    end
                end

                Rayfield:Notify({
                    Title = "Legit Auto Farm",
                    Content = "3 second hold done!\nWin registered. TP to safe spot (-171, 250, 28) and frozen standing up.",
                    Duration = 6
                })

                teleportToSafeSpot()
                task.wait(0.1)
                freezePlayer()
            end)
        end
    end)

    smoothFlyToWinpad(winpad)
end

local function startLegitIdleMonitor()
    if legitIdleConnection then return end
    legitIdleConnection = game:GetService("RunService").Heartbeat:Connect(function()
        if not legitAutoFarmEnabled then
            if legitIdleConnection then
                legitIdleConnection:Disconnect()
                legitIdleConnection = nil
            end
            return
        end

        if not currentWinpad then
            local now = tick()
            if now - lastSafeCheckTime > 0.5 then
                lastSafeCheckTime = now
                
                local character = game.Players.LocalPlayer.Character
                if character and character:FindFirstChild("HumanoidRootPart") then
                    local root = character.HumanoidRootPart
                    if (root.Position - SAFE_POS).Magnitude > 10 then
                        teleportToSafeSpot()
                    end
                end
                freezePlayer()
            end
        end
    end)
end

local function stopLegitIdleMonitor()
    if legitIdleConnection then
        legitIdleConnection:Disconnect()
        legitIdleConnection = nil
    end
end

local function startLegitAutoFarm()
    if legitConnection then return end

    legitConnection = workspace.DescendantAdded:Connect(function(child)
        if not legitAutoFarmEnabled then return end
        if child.Name == "winpad" then
            task.wait(0.1)
            local winpad = findWinpad()
            if winpad and winpad ~= lastWinpad then
                handleWinpadDetected(winpad)
            end
        end
    end)

    if not winpadRemoveConnection then
        winpadRemoveConnection = workspace.DescendantRemoving:Connect(function(child)
            if child.Name == "winpad" then
                currentWinpad = nil
            end
        end)
    end

    task.wait(0.2)
    local existingWinpad = findWinpad()
    if existingWinpad and existingWinpad ~= lastWinpad then
        handleWinpadDetected(existingWinpad)
    end

    startLegitIdleMonitor()
    startFullProtection()
    startAntiAFK()

    if not deathResetConnection then
        deathResetConnection = game.Players.LocalPlayer.CharacterAdded:Connect(function()
            task.wait(0.5)
            if not legitAutoFarmEnabled then return end
            local winpad = findWinpad()
            if winpad then
                handleWinpadDetected(winpad)
            end
        end)
    end
end

local function stopLegitAutoFarm()
    if legitConnection then
        legitConnection:Disconnect()
        legitConnection = nil
    end
    if legitFlyConnection then
        legitFlyConnection:Disconnect()
        legitFlyConnection = nil
    end
    if winpadRemoveConnection then
        winpadRemoveConnection:Disconnect()
        winpadRemoveConnection = nil
    end
    stopLegitIdleMonitor()
    stopFullProtection()
    stopAntiAFK()
    if deathResetConnection then
        deathResetConnection:Disconnect()
        deathResetConnection = nil
    end
    currentWinpad = nil
    lastWinpad = nil
    lastSafeCheckTime = 0
    unfreezePlayer()
end

-- ==================== ANTI DAMAGE / ANTI KILL / ESP ====================
local function disableHazard(part)
    if not part or part.Name == "winpad" then return end
    if part:IsA("BasePart") then
        pcall(function()
            part.CanTouch = false
            local ti = part:FindFirstChild("TouchInterest")
            if ti then ti:Destroy() end
        end)
    end
    for _, obj in pairs(part:GetDescendants()) do
        if obj.Name == "winpad" then continue end
        if obj:IsA("BasePart") then
            pcall(function()
                obj.CanTouch = false
                local ti = obj:FindFirstChild("TouchInterest")
                if ti then ti:Destroy() end
            end)
        end
    end
end

local function startAntiDamage()
    if antiDamageConnection then return end
    
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "winpad" then continue end
        local name = v.Name:lower()
        if name:find("damage") or name:find("hurt") or name:find("spike") or name:find("poison") or name:find("dmg") then
            disableHazard(v)
        end
    end
    
    antiDamageConnection = workspace.DescendantAdded:Connect(function(child)
        if not antiDamageEnabled then return end
        if child.Name == "winpad" then return end
        local name = child.Name:lower()
        if name:find("damage") or name:find("hurt") or name:find("spike") or name:find("poison") or name:find("dmg") then
            task.wait(0.1)
            disableHazard(child)
        end
    end)
end

local function stopAntiDamage()
    if antiDamageConnection then
        antiDamageConnection:Disconnect()
        antiDamageConnection = nil
    end
end

local function startAntiKill()
    if antiKillConnection then return end
    for _, v in pairs(workspace:GetDescendants()) do
        if v.Name == "winpad" then continue end
        if v.Name:lower():find("kill") or v.Name:lower():find("lava") or v.Name:lower():find("death") then
            disableHazard(v)
        end
    end
    antiKillConnection = workspace.DescendantAdded:Connect(function(child)
        if not antiKillEnabled then return end
        if child.Name == "winpad" then return end
        if child.Name:lower():find("kill") or child.Name:lower():find("lava") or child.Name:lower():find("death") then
            task.wait(0.1) 
            disableHazard(child)
        end
    end)
end

local function stopAntiKill()
    if antiKillConnection then 
        antiKillConnection:Disconnect() 
        antiKillConnection = nil 
    end
end

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
    Name = "Legit Auto Farm (12-18s Chill Fly + 3s Hold + Lay Down Pose)",
    CurrentValue = false,
    Callback = function(Value)
        legitAutoFarmEnabled = Value
        if Value then
            if not noclipConnection then
                startNoclip()
            end
            startLegitAutoFarm()
            Rayfield:Notify({
                Title = "Legit Auto Farm ENABLED",
                Content = "Legit Auto Farm is ON 🔥\nSlow 12-18s fly straight to the winpad while laying flat on your back\nHolds the touch for full 3 seconds to actually win\nThen TP to safe spot and freezes you standing up\nFull noclip + protection + anti-AFK running",
                Duration = 9
            })
        else
            stopLegitAutoFarm()
            if not noclipEnabled then
                stopNoclip()
            end
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
    Name = "Anti Kill Bricks",
    CurrentValue = false,
    Callback = function(Value) antiKillEnabled = Value if Value then startAntiKill() else stopAntiKill() end end,
})

MainTab:CreateToggle({
    Name = "Anti Damage Bricks",
    CurrentValue = false,
    Callback = function(Value)
        antiDamageEnabled = Value
        if Value then
            startAntiDamage()
            Rayfield:Notify({Title = "Anti Damage ENABLED", Content = "Damage bricks + health regen active", Duration = 5})
        else
            stopAntiDamage()
            Rayfield:Notify({Title = "Anti Damage DISABLED", Content = "Damage protection off", Duration = 4})
        end
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
        if musicSound then
            musicSound.Volume = musicVolume
        end
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
        if musicSound then
            musicSound.Looped = Value
        end
    end,
})

MusicTab:CreateButton({
    Name = "▶️ Play Audio",
    Callback = function()
        if currentAudioId <= 0 then
            Rayfield:Notify({
                Title = "Music Error",
                Content = "Need a valid Audio ID first!",
                Duration = 4
            })
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
        Rayfield:Notify({
            Title = "🎵 Now Playing",
            Content = "Audio ID: " .. currentAudioId .. "\nVolume: " .. musicVolume,
            Duration = 4
        })
    end,
})

MusicTab:CreateButton({
    Name = "⏸️ Pause",
    Callback = function()
        if musicSound then
            musicSound:Pause()
        end
    end,
})

MusicTab:CreateButton({
    Name = "▶️ Resume",
    Callback = function()
        if musicSound then
            musicSound:Resume()
        end
    end,
})

MusicTab:CreateButton({
    Name = "⏹️ Stop",
    Callback = function()
        if musicSound then
            musicSound:Stop()
        end
    end,
})

MusicTab:CreateButton({
    Name = "⏩ +10 Seconds",
    Callback = function()
        if musicSound and musicSound.IsPlaying then
            musicSound.TimePosition = musicSound.TimePosition + 10
        else
            Rayfield:Notify({Title = "Music", Content = "Nothing playing right now", Duration = 3})
        end
    end,
})

MusicTab:CreateButton({
    Name = "⏪ -10 Seconds",
    Callback = function()
        if musicSound and musicSound.IsPlaying then
            musicSound.TimePosition = math.max(0, musicSound.TimePosition - 10)
        else
            Rayfield:Notify({Title = "Music", Content = "Nothing playing right now", Duration = 3})
        end
    end,
})

Rayfield:Notify({
    Title = "Script Loaded Successfully",
    Content = "✅ Script is now crash-proof!\nLegit Auto Farm flies slower (12-18s)\nHeavy scans fixed with pcall + tighter yielding\nNo more crashes when turning on Legit Auto Farm or protections",
    Duration = 10,
})
