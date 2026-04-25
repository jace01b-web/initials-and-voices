local p = game.Players.LocalPlayer
local g = Instance.new("ScreenGui", p:WaitForChild("PlayerGui") or game:GetService("CoreGui"))
g.ResetOnSpawn = false

local f = Instance.new("Frame")
f.Size = UDim2.new(0, 220, 0, 120)
f.Position = UDim2.new(0.5, -110, 0.4, 0)
f.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
f.BorderSizePixel = 0
f.Parent = g

-- Corner + Stroke for modern look
Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
local s = Instance.new("UIStroke", f)
s.Color = Color3.fromRGB(0, 170, 255)
s.Thickness = 1.5

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "PlaceId Copier"
title.TextColor3 = Color3.new(1,1,1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = f

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(0.9, 0, 0, 50)
btn.Position = UDim2.new(0.05, 0, 0.45, 0)
btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
btn.Text = "Copy PlaceId"
btn.TextColor3 = Color3.new(1,1,1)
btn.TextScaled = true
btn.Font = Enum.Font.GothamSemibold
btn.Parent = f
Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

-- Make the whole frame draggable (short & smooth)
local dragging, dragInput, dragStart, startPos
f.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = f.Position
	end
end)

f.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		dragInput = input
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

game:GetService("RunService").Heartbeat:Connect(function()
	if dragging and dragInput then
		local delta = dragInput.Position - dragStart
		f.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- Copy function
btn.MouseButton1Click:Connect(function()
	local id = game.PlaceId
	setclipboard(tostring(id))
	btn.Text = "Copied: " .. id
	task.wait(1.5)
	btn.Text = "Copy PlaceId"
end)
