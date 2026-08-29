local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local COLORS = {
	background = Color3.fromRGB(18, 22, 30),
	panel = Color3.fromRGB(27, 32, 43),
	panelLight = Color3.fromRGB(39, 46, 60),
	text = Color3.fromRGB(236, 240, 246),
	muted = Color3.fromRGB(157, 168, 184),
	accent = Color3.fromRGB(70, 180, 145),
	fruit = Color3.fromRGB(238, 172, 75),
	chest = Color3.fromRGB(113, 164, 231),
	spawned = Color3.fromRGB(178, 116, 210)
}

local SPEED = 300
local CHEST_COOLDOWN = 20 * 60
local chestCooldowns = {}
local activeTween
local collectingChest
local waterPart
local tracked = {}
local spawnedFruitButtons = {}
local spawnedFruitEntries = {}
local playStarted = os.clock()
local state = {
	findChest = false,
	fruitEsp = false,
	chestEsp = false,
	spawnedFruits = false,
	walkOnWater = false,
	antiAfk = false
}

local FAST_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local PANEL_TWEEN = TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GeneralHub"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "MainPanel"
panel.Size = UDim2.fromOffset(280, 500)
panel.Position = UDim2.new(0, -300, 0.5, -250)
panel.BackgroundColor3 = COLORS.background
panel.BackgroundTransparency = 1
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(62, 72, 91)
stroke.Transparency = 0.25
stroke.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 92)
header.BackgroundColor3 = COLORS.panel
header.BackgroundTransparency = 0
header.BorderSizePixel = 0
header.Parent = panel

local headerCorner = panelCorner:Clone()
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 0, 38)
title.Position = UDim2.fromOffset(14, 10)
title.BackgroundTransparency = 1
title.Text = "General Hub"
title.TextColor3 = COLORS.text
title.TextSize = 25
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(32, 32)
closeButton.Position = UDim2.new(1, -44, 0, 13)
closeButton.BackgroundColor3 = COLORS.panelLight
closeButton.AutoButtonColor = false
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = COLORS.text
closeButton.TextSize = 16
closeButton.Parent = header

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

closeButton.Activated:Connect(function()
	if activeTween then
		activeTween:Cancel()
		activeTween = nil
	end
	if waterPart then
		waterPart:Destroy()
		waterPart = nil
	end
	for object, entry in pairs(tracked) do
		entry.gui:Destroy()
		tracked[object] = nil
	end
	screenGui:Destroy()
end)

local playTime = Instance.new("TextLabel")
playTime.Size = UDim2.new(1, -28, 0, 22)
playTime.Position = UDim2.fromOffset(14, 52)
playTime.BackgroundTransparency = 1
playTime.TextColor3 = COLORS.muted
playTime.TextSize = 14
playTime.Font = Enum.Font.Gotham
playTime.TextXAlignment = Enum.TextXAlignment.Left
playTime.Parent = header

local options = Instance.new("Frame")
options.Name = "Options"
options.Size = UDim2.new(1, -24, 0, 180)
options.Position = UDim2.fromOffset(12, 104)
options.BackgroundTransparency = 1
options.Parent = panel

local optionsLayout = Instance.new("UIListLayout")
optionsLayout.Padding = UDim.new(0, 8)
optionsLayout.Parent = options

local function makeToggle(key, label, color)
	local button = Instance.new("TextButton")
	button.Name = key .. "Toggle"
	button.Size = UDim2.new(1, 0, 0, 38)
	button.AutoButtonColor = false
	button.BackgroundColor3 = COLORS.panelLight
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamMedium
	button.TextColor3 = COLORS.text
	button.TextSize = 15
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Parent = options

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local indicator = Instance.new("Frame")
	indicator.Name = "Indicator"
	indicator.Size = UDim2.fromOffset(6, 22)
	indicator.Position = UDim2.fromOffset(9, 8)
	indicator.BorderSizePixel = 0
	indicator.Parent = button

	local indicatorCorner = Instance.new("UICorner")
	indicatorCorner.CornerRadius = UDim.new(1, 0)
	indicatorCorner.Parent = indicator

	local function refresh()
		local enabled = state[key]
		button.Text = "    " .. label .. string.rep(" ", 12) .. (enabled and "ON" or "OFF")
		TweenService:Create(button, FAST_TWEEN, { BackgroundColor3 = enabled and color or COLORS.panelLight }):Play()
		TweenService:Create(indicator, FAST_TWEEN, { BackgroundColor3 = enabled and Color3.new(1, 1, 1) or COLORS.muted }):Play()
	end

	button.Activated:Connect(function()
		state[key] = not state[key]
		refresh()
	end)
	button.MouseEnter:Connect(function()
		if not state[key] then
			TweenService:Create(button, FAST_TWEEN, { BackgroundColor3 = Color3.fromRGB(51, 60, 77) }):Play()
		end
	end)
	button.MouseLeave:Connect(function()
		if not state[key] then
			TweenService:Create(button, FAST_TWEEN, { BackgroundColor3 = COLORS.panelLight }):Play()
		end
	end)
	refresh()
	return button
end

makeToggle("findChest", "Find Chest", COLORS.accent)
makeToggle("fruitEsp", "Fruit ESP", COLORS.fruit)
makeToggle("chestEsp", "Chest ESP", COLORS.chest)
makeToggle("spawnedFruits", "Spawned Fruits", COLORS.spawned)
makeToggle("walkOnWater", "Walk On Water", COLORS.accent)
makeToggle("antiAfk", "Anti AFK", COLORS.accent)

local fruitList = Instance.new("ScrollingFrame")
fruitList.Name = "SpawnedFruitList"
fruitList.Size = UDim2.new(1, -24, 0, 90)
fruitList.Position = UDim2.fromOffset(12, 382)
fruitList.BackgroundColor3 = COLORS.panel
fruitList.BorderSizePixel = 0
fruitList.ScrollBarThickness = 4
fruitList.Visible = false
fruitList.Parent = panel

local listCorner = Instance.new("UICorner")
listCorner.CornerRadius = UDim.new(0, 6)
listCorner.Parent = fruitList

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = fruitList

local function formatTime(seconds)
	local total = math.floor(seconds)
	return string.format("Play time  %02d:%02d:%02d", math.floor(total / 3600), math.floor(total / 60) % 60, total % 60)
end

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function getObjectRoot(object)
	if object:IsA("BasePart") then
		return object
	end
	if object:IsA("Model") then
		return object.PrimaryPart or object:FindFirstChildWhichIsA("BasePart", true)
	end
	return object:FindFirstChildWhichIsA("BasePart", true)
end

local function getChests()
	local chests = {}
	for _, object in ipairs(workspace:GetDescendants()) do
		if object:IsA("BasePart") and object.Name:lower():find("chest", 1, true) then
			table.insert(chests, object)
		end
	end
	return chests
end

local function collectChest(chest)
	local prompt = chest:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt and prompt.Enabled then
		prompt:InputHoldBegin()
		task.wait(prompt.HoldDuration)
		prompt:InputHoldEnd()
	end
end

local function isExcludedObject(object)
	local name = object.Name:lower()
	return name:find("dealer", 1, true)
		or name:find("gacha", 1, true)
		or name:find("fruit dealer", 1, true)
end

local function isFruitObject(object)
	if not (object:IsA("Model") or object:IsA("Tool")) or isExcludedObject(object) then
		return false
	end

	local name = object.Name:lower()
	local itemType = tostring(object:GetAttribute("ItemType")):lower()
	return object:GetAttribute("Fruit") == true
		or object:GetAttribute("IsFruit") == true
		or object:GetAttribute("FruitName") ~= nil
		or CollectionService:HasTag(object, "Fruit")
		or name:find("fruit", 1, true) ~= nil
		or name:find("berry", 1, true) ~= nil
		or itemType == "fruit"
end

local function getEspCategory(object)
	if isExcludedObject(object) then
		return nil
	end
	if object:IsA("BasePart") and object.Name:lower():find("chest", 1, true) then
		return "chestEsp"
	end
	if not (object:IsA("Model") or object:IsA("Tool")) then
		return nil
	end
	local name = object.Name:lower()
	if name:find("chest", 1, true) then
		return "chestEsp"
	end
	if isFruitObject(object) then
		return "fruitEsp"
	end
	return nil
end

local function addEsp(object)
	if tracked[object] then
		return
	end
	local category = getEspCategory(object)
	if not category then
		return
	end
	local root = getObjectRoot(object)
	if not root then
		return
	end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "GeneralHubFruitEsp"
	billboard.Adornee = root
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(170, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.Parent = playerGui
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = COLORS[category == "chestEsp" and "chest" or "fruit"]
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Parent = billboard
	tracked[object] = { gui = billboard, label = label, root = root, category = category }
end

local function removeEsp(object)
	local entry = tracked[object]
	if entry then
		entry.gui:Destroy()
		tracked[object] = nil
	end
end

local function isSpawnedFruit(object)
	return isFruitObject(object)
end

local function getFruitPosition(object)
	local root = getObjectRoot(object)
	return root and root.Position
end

local function refreshFruitList()
	for _, button in ipairs(spawnedFruitButtons) do
		button:Destroy()
	end
	table.clear(spawnedFruitButtons)
	table.clear(spawnedFruitEntries)
	local fruits = {}
	for _, object in ipairs(workspace:GetDescendants()) do
		if isSpawnedFruit(object) then
			table.insert(fruits, object)
		end
	end
	table.sort(fruits, function(left, right)
		return left.Name:lower() < right.Name:lower()
	end)
	for _, fruit in ipairs(fruits) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(1, -8, 0, 25)
		button.BackgroundColor3 = COLORS.panelLight
		button.BorderSizePixel = 0
		button.Font = Enum.Font.Gotham
		button.TextColor3 = COLORS.text
		button.TextSize = 12
		button.Text = "  " .. fruit.Name
		button.TextXAlignment = Enum.TextXAlignment.Left
		button.Parent = fruitList
		button.Activated:Connect(function()
			local currentRoot = getRoot(player.Character)
			local currentPosition = getFruitPosition(fruit)
			if currentRoot and currentPosition and fruit.Parent then
				currentRoot.CFrame = CFrame.new(currentPosition + Vector3.new(0, 3, 0))
			end
		end)
		table.insert(spawnedFruitButtons, button)
		table.insert(spawnedFruitEntries, { fruit = fruit, button = button })
	end
	fruitList.CanvasSize = UDim2.fromOffset(0, listLayout.AbsoluteContentSize.Y + 4)
end

local dragging = false
local dragStart
local panelStart
header.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		panelStart = panel.Position
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		panel.Position = UDim2.new(panelStart.X.Scale, panelStart.X.Offset + delta.X, panelStart.Y.Scale, panelStart.Y.Offset + delta.Y)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

for _, object in ipairs(workspace:GetDescendants()) do
	addEsp(object)
end
workspace.DescendantAdded:Connect(addEsp)
workspace.DescendantRemoving:Connect(removeEsp)
workspace.ChildAdded:Connect(refreshFruitList)
workspace.ChildRemoved:Connect(refreshFruitList)
workspace.DescendantAdded:Connect(function(object)
	if isSpawnedFruit(object) then
		refreshFruitList()
	end
end)
workspace.DescendantRemoving:Connect(function(object)
	if isSpawnedFruit(object) then
		refreshFruitList()
	end
end)
refreshFruitList()

task.defer(function()
	TweenService:Create(panel, PANEL_TWEEN, {
		Position = UDim2.new(0, 24, 0.5, -250),
		BackgroundTransparency = 0
	}):Play()
end)

player.Idled:Connect(function()
	if state.antiAfk then
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end
end)

local lastFruitListState = state.spawnedFruits
RunService.RenderStepped:Connect(function()
	playTime.Text = formatTime(os.clock() - playStarted)
	if state.walkOnWater then
		local root = getRoot(player.Character)
		if root then
			if not waterPart then
				waterPart = Instance.new("Part")
				waterPart.Name = "GeneralHubWaterWalk"
				waterPart.Size = Vector3.new(500, 0.1, 500)
				waterPart.Transparency = 1
				waterPart.Anchored = true
				waterPart.CanCollide = true
				waterPart.CanTouch = false
				waterPart.CanQuery = false
				waterPart.Parent = workspace
			end
			waterPart.Position = Vector3.new(root.Position.X, 0.5, root.Position.Z)
		end
	elseif waterPart then
		waterPart:Destroy()
		waterPart = nil
	end
	if state.spawnedFruits ~= lastFruitListState then
		lastFruitListState = state.spawnedFruits
		if state.spawnedFruits then
			fruitList.Visible = true
		end
		local targetListSize = state.spawnedFruits and UDim2.new(1, -24, 0, 90) or UDim2.new(1, -24, 0, 0)
		local listTween = TweenService:Create(fruitList, FAST_TWEEN, { Size = targetListSize })
		listTween.Completed:Connect(function()
			if not state.spawnedFruits then
				fruitList.Visible = false
			end
		end)
		listTween:Play()
	end
	for object, entry in pairs(tracked) do
		entry.root = getObjectRoot(object)
		if not object:IsDescendantOf(workspace) or not entry.root or not entry.root.Parent then
			removeEsp(object)
		else
			entry.gui.Enabled = state[entry.category]
			local root = getRoot(player.Character)
			local distance = root and (root.Position - entry.root.Position).Magnitude or 0
			entry.label.Text = string.format("%s  %.0f studs", object.Name, distance)
		end
	end
	local root = getRoot(player.Character)
	for _, entry in ipairs(spawnedFruitEntries) do
		if entry.fruit.Parent then
			local fruitPosition = getFruitPosition(entry.fruit)
			local distance = root and fruitPosition and (root.Position - fruitPosition).Magnitude or 0
			entry.button.Text = string.format("  %s  (%.0f studs)", entry.fruit.Name, distance)
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if not state.findChest then
		if activeTween then
			activeTween:Cancel()
			activeTween = nil
		end
		collectingChest = nil
		local root = getRoot(player.Character)
		if root then
			root.Anchored = false
		end
		return
	end

	local root = getRoot(player.Character)
	if not root or activeTween or collectingChest then
		return
	end
	local nearest
	local nearestDistance
	for _, chest in ipairs(getChests()) do
		if not chestCooldowns[chest] or os.clock() >= chestCooldowns[chest] then
			local distance = (root.Position - chest.Position).Magnitude
			if not nearestDistance or distance < nearestDistance then
				nearest, nearestDistance = chest, distance
			end
		end
	end
	if nearest then
		root.Anchored = true
		local target = nearest.Position + Vector3.new(0, 3, 0)
		activeTween = TweenService:Create(root, TweenInfo.new(math.max((root.Position - target).Magnitude / SPEED, 0.05), Enum.EasingStyle.Linear), { CFrame = CFrame.new(target) })
		activeTween:Play()
		activeTween.Completed:Connect(function(result)
			if result == Enum.PlaybackState.Completed and state.findChest then
				collectingChest = nearest
				task.spawn(function()
					collectChest(nearest)
					if state.findChest and nearest.Parent then
						chestCooldowns[nearest] = os.clock() + CHEST_COOLDOWN
					end
					collectingChest = nil
				end)
			end
			activeTween = nil
		end)
	end
end)
