local Players = game:GetService("Players")
local TeleportCheck = false

local function missing(t, f, fallback)
    if type(f) == t then return f end
    return fallback
end
local queueteleport = missing("function", queue_on_teleport)

Players.LocalPlayer.OnTeleport:Connect(function(State)
    if not TeleportCheck and queueteleport then
        TeleportCheck = true
        -- Used [[ ]] to prevent string escape issues with the inner double quotes
        queueteleport([[loadstring(game:HttpGet("https://jace01b-web.github.io/initials-and-voices/Initials%20Untitled%20Melee%20RNG.lua"))()]])
    end
end)

-- [ORIGINAL SCRIPT BEGINS HERE]
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Zombie TP & Auto Toolkit [V2]",
   LoadingTitle = "Initializing Systems...",
   LoadingSubtitle = "Scanning Workspace Folders...",
   ConfigurationSaving = {Enabled = true, FolderName = nil, FileName = "Untitled Melee RNG Config" }
})

local MainTab = Window:CreateTab("Combat", 4483362458)
local UtilityTab = Window:CreateTab("Utility", 4483362458)
local TeleportTab = Window:CreateTab("Teleports", 4483362458)

local TPToggled = false
local EquipToggled = false

-- [ANTI-AFK: Infinite Yield Logic]
local VirtualUser = game:GetService("VirtualUser")
game:GetService("Players").LocalPlayer.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- [ANTI-LAG: Extreme Transparency]
local function ActivateExtremeAntiLag()
    settings().Rendering.QualityLevel = 1
    for _, v in pairs(game:GetDescendants()) do
        if v:IsA("BasePart") or v:IsA("Decal") or v:IsA("Texture") or v:IsA("MeshPart") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") or v:IsA("Light") then
            v.Enabled = false
        end
    end
    game:GetService("Lighting").GlobalShadows = false
    Rayfield:Notify({Title = "Anti-Lag", Content = "Extreme FPS Mode Active", Duration = 3})
end

-- [REMOTE FINDER]
local function GetRemote(name)
    local RS = game:GetService("ReplicatedStorage")
    local folder = RS:FindFirstChild("Remotes") or RS:FindFirstChild("Removes")
    if folder then
        local target = folder:FindFirstChild(name)
        if target then return target end
    end
    return RS:FindFirstChild(name, true)
end

-- [UTILITY: Dynamic Folder Scanner]
local function GetChildrenNames(folderPath)
    local list = {}
    local folder = folderPath
    if folder then
        for _, item in pairs(folder:GetChildren()) do
            table.insert(list, item.Name)
        end
    end
    table.sort(list)
    return list
end

-- [TELEPORT EXECUTION]
local function SafeTeleport(targetInstance)
    local player = game.Players.LocalPlayer
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    
    if targetInstance and root then
        local targetPos
        if targetInstance:IsA("Model") then
            targetPos = targetInstance:GetPivot()
        else
            targetPos = targetInstance.CFrame
        end
        root.CFrame = targetPos + Vector3.new(0, 3, 0)
    end
end

-- [COMBAT: AUTO FARM]
MainTab:CreateToggle({
   Name = "Auto Farm (Anti-AFK Bring)",
   CurrentValue = false,
   Flag = "BringFarm",
   Callback = function(Value)
      TPToggled = Value
      if TPToggled then
         task.spawn(function()
            while TPToggled do
               pcall(function()
                  VirtualUser:CaptureController()
                  VirtualUser:ClickButton2(Vector2.new())
                  
                  local player = game.Players.LocalPlayer
                  local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                  local mobsFolder = workspace:FindFirstChild("Mobs")
                  
                  if root and mobsFolder then
                     for _, mob in pairs(mobsFolder:GetChildren()) do
                        local mobRoot = mob:FindFirstChild("HumanoidRootPart") or mob:FindFirstChild("Torso") or mob:FindFirstChild("UpperTorso")
                        local hum = mob:FindFirstChildOfClass("Humanoid")
                        
                        if mobRoot and (not hum or hum.Health > 0) then
                           local dist = (root.Position - mobRoot.Position).Magnitude
                           if dist < 600 then
                              if mobRoot.CanCollide then mobRoot.CanCollide = false end
                              mobRoot.CFrame = root.CFrame * CFrame.new(0, 0, -5)
                           end
                        end
                     end
                  end
               end)
               task.wait(0.05)
            end
         end)
      end
   end,
})

-- [UTILITY TAB]
UtilityTab:CreateButton({
   Name = "Activate Anti-Lag (Invisible)",
   Callback = ActivateExtremeAntiLag
})

UtilityTab:CreateToggle({
   Name = "Auto Equip Best",
   CurrentValue = false,
   Flag = "EquipBestLoop",
   Callback = function(Value)
      EquipToggled = Value
      if EquipToggled then
         task.spawn(function()
            while EquipToggled do
               local remote = GetRemote("EquipBest")
               if remote then remote:FireServer() end
               task.wait(3) 
            end
         end)
      end
   end,
})

-- [TELEPORT TAB: AREAS, MACHINES, BOSSES]

-- 1. World Areas
TeleportTab:CreateDropdown({
   Name = "Teleport to Area",
   Options = GetChildrenNames(workspace:FindFirstChild("Areas")),
   CurrentOption = "",
   Callback = function(Option)
      local area = workspace.Areas:FindFirstChild(Option[1])
      if area then
         local spawn = area:FindFirstChild("SafeAreaSpawn") or area:FindFirstChild("PortalPart") or area:FindFirstChildWhichIsA("BasePart")
         SafeTeleport(spawn)
      end
   end,
})

-- 2. Machines
TeleportTab:CreateDropdown({
   Name = "Teleport to Machine",
   Options = GetChildrenNames(workspace:FindFirstChild("Machines")),
   CurrentOption = "",
   Callback = function(Option)
      local machine = workspace.Machines:FindFirstChild(Option[1])
      if machine then
         -- Prioritize Padlock or the Model pivot
         local target = machine:FindFirstChild("Padlock") or machine
         SafeTeleport(target)
      end
   end,
})

-- 3. Boss Areas
TeleportTab:CreateDropdown({
   Name = "Teleport to Boss Area",
   Options = GetChildrenNames(workspace:FindFirstChild("BossAreas")),
   CurrentOption = "",
   Callback = function(Option)
      local bossFolder = workspace.BossAreas:FindFirstChild(Option[1])
      if bossFolder then
         -- Prioritize PlayerSpawn as shown in your hierarchy
         local target = bossFolder:FindFirstChild("PlayerSpawn") or bossFolder:FindFirstChild("BossArea") or bossFolder
         SafeTeleport(target)
      end
   end,
})

-- 4. Time Trials
local AutoTimeTrialsToggled = false

MainTab:CreateToggle({
   Name = "Auto Time Trials (Full Loop)",
   CurrentValue = false,
   Flag = "AutoTimeTrials",
   Callback = function(Value)
      AutoTimeTrialsToggled = Value
      if AutoTimeTrialsToggled then
         task.spawn(function()
            while AutoTimeTrialsToggled do
               pcall(function()
                  local player = game.Players.LocalPlayer
                  local playerGui = player:FindFirstChild("PlayerGui")
                  
                  -- 1. FORCE THE LOBBY GUI & START
                  -- Firing remotes found in your ReplicatedStorage.Remotes folder
                  local updateRemote = GetRemote("UpdateTimeTrialLobby")
                  local startRemote = GetRemote("StartTimeTrial")
                  
                  -- This remote is often responsible for pulling up the UI menu
                  if updateRemote then 
                      updateRemote:FireServer() 
                  end
                  
                  -- 2. AUTOMATIC GUI INTERACTION
                  if playerGui then
                     -- Navigation path: MainGUI -> GeneralUI -> TimeTrialsLobbyFrame -> StartBtn
                     local mainGui = playerGui:FindFirstChild("MainGUI")
                     local generalUI = mainGui and mainGui:FindFirstChild("GeneralUI")
                     local lobbyFrame = generalUI and generalUI:FindFirstChild("TimeTrialsLobbyFrame")
                     local startBtn = lobbyFrame and lobbyFrame:FindFirstChild("StartBtn")

                     -- Automatically clicks the "Start Run" button if it's visible on screen
                     if lobbyFrame and lobbyFrame.Visible and startBtn and startBtn.Visible then
                        for _, connection in pairs(getconnections(startBtn.MouseButton1Click)) do
                            connection:Fire()
                        end
                     end
                  end
                  
                  -- Direct start command to ensure match entry even if UI doesn't load
                  if startRemote then 
                      startRemote:FireServer() 
                  end

                  -- 3. AUTO-TELEPORT TO NEWEST DUNGEON ROOM
                  local dungeonFolder = workspace:FindFirstChild("GeneratedDungeon")
                  if dungeonFolder then
                     local newestRoom = nil
                     local highestNum = -1

                     -- Scans all generated rooms to find the one with the highest index
                     for _, room in pairs(dungeonFolder:GetChildren()) do
                        local numStr = string.match(room.Name, "%d+")
                        if numStr then
                           local num = tonumber(numStr)
                           if num > highestNum then
                              highestNum = num
                              newestRoom = room
                           end
                        end
                     end

                     -- Teleports player to the 'BASE' part of the latest room generation
                     if newestRoom then
                        local target = newestRoom:FindFirstChild("BASE") or newestRoom
                        SafeTeleport(target)
                     end
                  end
               end)
               task.wait(0.5) -- Regulated delay to prevent server-side lag or kicks
            end
         end)
      end
   end,
})

Rayfield:Notify({Title = "Loaded", Content = "All Areas, Machines, and Bosses mapped.", Duration = 5})
Rayfield:LoadConfiguration()
