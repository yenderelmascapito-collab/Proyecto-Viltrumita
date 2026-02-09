local highlightColor = Color3.fromRGB(100,0,244)
local autoHighlightColor = Color3.fromRGB(255,80,80)
local hitboxSize = 25
local maxSelectDistance = 120

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

-- Key system
local keyGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
keyGui.ResetOnSpawn = false
local frame = Instance.new("Frame", keyGui)
frame.Size = UDim2.new(0,300,0,150)
frame.Position = UDim2.new(0.5,-150,0.5,-75)
frame.BackgroundColor3 = Color3.fromRGB(30,30,30)
frame.BorderSizePixel = 0
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,30)
title.Position = UDim2.new(0,0,0,0)
title.Text = "Enter Key"
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
local textBox = Instance.new("TextBox", frame)
textBox.Size = UDim2.new(0.8,0,0,30)
textBox.Position = UDim2.new(0.1,0,0.3,0)
textBox.PlaceholderText = "Enter key"
textBox.BackgroundColor3 = Color3.fromRGB(50,50,50)
textBox.TextColor3 = Color3.fromRGB(255,255,255)
textBox.BorderSizePixel = 0
local button = Instance.new("TextButton", frame)
button.Size = UDim2.new(0.8,0,0,30)
button.Position = UDim2.new(0.1,0,0.6,0)
button.Text = "Submit"
button.BackgroundColor3 = Color3.fromRGB(100,100,100)
button.TextColor3 = Color3.fromRGB(255,255,255)
button.BorderSizePixel = 0
local enteredKey = ""
button.MouseButton1Click:Connect(function()
    enteredKey = textBox.Text
    if enteredKey == "admin123" or enteredKey == "goku" then
        keyGui:Destroy()
    else
        textBox.Text = "Invalid Key"
        task.wait(1)
        textBox.Text = ""
    end
end)
repeat task.wait() until enteredKey == "admin123" or enteredKey == "goku"


local highlightEnabled = true
local hitboxEnabled = true
local selectedPlayer = nil
local cameraLockEnabled = false
local originalRootSizes = {}
local selectionBillboard = nil
local lastCameraTarget = nil
local lockConfirm = 0

local espBoxEnabled = false
local espBonesEnabled = false
local espNameEnabled = false

local bunnyEnabled = false
local bunnyLegitEnabled = false
local emoteJumpEnabled = false
local SIDE_POWER = 140
local JUMP_POWER = 90
local COOLDOWN = 0.16
local FREEZE_TIME = 0.15
local holdingSpace = false
local canJump = true
local soundEnabled = true
local toggleSound = Instance.new("Sound")
toggleSound.SoundId = "rbxassetid://12221967"
toggleSound.Parent = workspace

local hideMenuSound = Instance.new("Sound")
hideMenuSound.SoundId = "rbxassetid://12221944"
hideMenuSound.Parent = workspace

local bunnyText = nil

local function playSound()
	if soundEnabled then
		toggleSound:Stop()
		toggleSound:Play()
	end
end

local musicEnabled = false
local currentMusic = nil
local backgroundMusic = Instance.new("Sound")
backgroundMusic.Parent = workspace
backgroundMusic.Looped = true
backgroundMusic.Volume = 0.5

local musicIDs = {
	["Sleeping City"] = "73811397460869",
	["Voce na Mira"] = "120579175218769",
	["Gozalo"] = "126101841412059",
	["HYPNOSAES RENICHT ESPECTRAL"] = "119202700760169",
	["Nuts Lil Peep"] = "98839453510161",
	["Mimosa 2000"] = "137329447492960",
	["Conosco Tu Debilidad"] = "93204353670810",
	["Todos Los Caminos Llevan a Roma"] = "103637998030679"
}

local function playSelectedMusic()
	if currentMusic and musicIDs[currentMusic] then
		backgroundMusic:Stop()
		backgroundMusic.SoundId = "rbxassetid://" .. musicIDs[currentMusic]
		backgroundMusic:Play()
		musicEnabled = true
	end
end

local function stopMusic()
	backgroundMusic:Stop()
	musicEnabled = false
	currentMusic = nil
end

local function detectGameSide()
	local char = LocalPlayer.Character
	if not char then return "No character" end
	local hum = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not hum or not root then return "No humanoid/root" end

	local results = {}
	local originalWS = hum.WalkSpeed
	local originalJP = hum.JumpPower
	local originalSize = root.Size
	local originalCF = root.CFrame

	-- Prueba 1: WalkSpeed
	hum.WalkSpeed = 50
	task.wait(0.05)
	results.walkSpeed = (hum.WalkSpeed == 50)
	hum.WalkSpeed = originalWS

	-- Prueba 2: JumpPower
	hum.JumpPower = 100
	task.wait(0.05)
	results.jumpPower = (hum.JumpPower == 100)
	hum.JumpPower = originalJP

	-- Prueba 3: Root Size
	root.Size = Vector3.new(5,5,5)
	task.wait(0.05)
	results.rootSize = (root.Size == Vector3.new(5,5,5))
	root.Size = originalSize

	-- Prueba 4: AssemblyLinearVelocity
	local originalVel = root.AssemblyLinearVelocity
	root.AssemblyLinearVelocity = Vector3.new(10,0,10)
	task.wait(0.05)
	results.assemblyVel = (root.AssemblyLinearVelocity == Vector3.new(10,0,10))
	root.AssemblyLinearVelocity = originalVel

	-- Prueba 5: HumanoidState
	local originalState = hum:GetState()
	hum:ChangeState(Enum.HumanoidStateType.Physics)
	task.wait(0.05)
	results.humanoidState = (hum:GetState() == Enum.HumanoidStateType.Physics)
	hum:ChangeState(originalState)

	-- Prueba 6: CFrame pequeño
	local newCF = originalCF * CFrame.new(0.1, 0, 0)
	root.CFrame = newCF
	task.wait(0.05)
	results.cframeSmall = (root.CFrame.Position == newCF.Position)
	root.CFrame = originalCF

	-- Prueba 7: Snapback detection (cambio grande y ver si corrige)
	local snapCF = originalCF * CFrame.new(5, 0, 0)
	root.CFrame = snapCF
	task.wait(0.1)
	results.snapback = (root.CFrame.Position ~= snapCF.Position) -- Si cambió, hay snapback
	root.CFrame = originalCF

	-- Calcular resultado final
	local passedCount = 0
	for _, passed in pairs(results) do
		if passed then passedCount = passedCount + 1 end
	end

	local totalTests = 7
	local result
	if passedCount == totalTests then
		result = "Client-Side"
	elseif passedCount >= totalTests / 2 then
		result = "Server-Side Parcial"
	elseif passedCount == 0 then
		result = "Server-Side Estricto"
	else
		result = "Mixto / Mal Protegido"
	end

	-- Reporte detallado
	print("=== REPORTE DETECTOR SERVER-SIDE ===")
	print("WalkSpeed mantenido:", results.walkSpeed)
	print("JumpPower mantenido:", results.jumpPower)
	print("Root Size mantenido:", results.rootSize)
	print("AssemblyLinearVelocity mantenido:", results.assemblyVel)
	print("HumanoidState mantenido:", results.humanoidState)
	print("CFrame pequeño mantenido:", results.cframeSmall)
	print("Snapback detectado:", results.snapback)
	print("Resultado Final:", result)
	print("=====================================")

	return result
end

local hitboxSize = 25

local function getRoot(char)
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function getCharacterFromRay()
	local origin = Camera.CFrame.Position
	local direction = Camera.CFrame.LookVector * 500

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {LocalPlayer.Character}
	params.FilterType = Enum.RaycastFilterType.Blacklist

	local result = workspace:Raycast(origin, direction, params)
	if not result then return nil end

	local model = result.Instance:FindFirstAncestorOfClass("Model")
	if not model then return nil end

	return Players:GetPlayerFromCharacter(model)
end

local function saveSize(char)
	local r = getRoot(char)
	if r and not originalRootSizes[char] then
		originalRootSizes[char] = r.Size
	end
end

local function restore(char)
	local r = getRoot(char)
	if r and originalRootSizes[char] then
		r.Size = originalRootSizes[char]
		r.Transparency = 0
		r.CanCollide = true
		originalRootSizes[char] = nil
	end
end

local function applyHitbox(char)
	local r = getRoot(char)
	if not r then return end
	saveSize(char)
	r.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
	r.Transparency = 1
	r.CanCollide = false
end

local function applyHighlight(char, color)
	if not highlightEnabled then
		local hl = char:FindFirstChild("CustomHighlight")
		if hl then hl:Destroy() end
		return
	end

	local hl = char:FindFirstChild("CustomHighlight")
	if not hl then
		hl = Instance.new("Highlight")
		hl.Name = "CustomHighlight"
		hl.FillTransparency = 1
		hl.Parent = char
	end
	hl.OutlineColor = color
end

local function applyESP(char, player)
	if espNameEnabled then
		local nameGui = char:FindFirstChild("ESPName")
		if not nameGui then
			nameGui = Instance.new("BillboardGui")
			nameGui.Name = "ESPName"
			nameGui.Size = UDim2.new(0, 100, 0, 20)
			nameGui.StudsOffset = Vector3.new(0, 3, 0)
			nameGui.AlwaysOnTop = true
			nameGui.Parent = char:FindFirstChild("Head") or char

			local nameLabel = Instance.new("TextLabel")
			nameLabel.Size = UDim2.new(1, 0, 1, 0)
			nameLabel.BackgroundTransparency = 1
			nameLabel.Text = player.Name
			nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
			nameLabel.TextStrokeTransparency = 0.5
			nameLabel.Font = Enum.Font.GothamBold
			nameLabel.TextScaled = true
			nameLabel.Parent = nameGui
		end
	else
		local nameGui = char:FindFirstChild("ESPName")
		if nameGui then nameGui:Destroy() end
	end

	if espBoxEnabled then
		local box = char:FindFirstChild("ESPBox")
		if not box then
			box = Instance.new("Part")
			box.Name = "ESPBox"
			box.Anchored = true
			box.CanCollide = false
			box.Transparency = 0.7
			box.BrickColor = BrickColor.new("Bright red")
			box.Material = Enum.Material.Plastic
			box.Parent = char
		end
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			box.Size = Vector3.new(4, 6, 2)
			box.CFrame = root.CFrame
		end
	else
		local box = char:FindFirstChild("ESPBox")
		if box then box:Destroy() end
	end

	if espBonesEnabled then
		local bonesFolder = char:FindFirstChild("ESPBones")
		if not bonesFolder then
			bonesFolder = Instance.new("Folder")
			bonesFolder.Name = "ESPBones"
			bonesFolder.Parent = char

			local connections = {
				{"Head", "HumanoidRootPart"},
				{"HumanoidRootPart", "Left Arm"},
				{"HumanoidRootPart", "Right Arm"},
				{"HumanoidRootPart", "Left Leg"},
				{"HumanoidRootPart", "Right Leg"},
				{"Left Arm", "LeftHand"},
				{"Right Arm", "RightHand"},
				{"Left Leg", "LeftFoot"},
				{"Right Leg", "RightFoot"}
			}

			for _, conn in ipairs(connections) do
				local part1 = char:FindFirstChild(conn[1])
				local part2 = char:FindFirstChild(conn[2])
				if part1 and part2 then
					local beam = Instance.new("Beam")
					beam.Name = conn[1] .. "_" .. conn[2]
					beam.Attachment0 = Instance.new("Attachment", part1)
					beam.Attachment1 = Instance.new("Attachment", part2)
					beam.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
					beam.Width0 = 0.1
					beam.Width1 = 0.1
					beam.FaceCamera = true
					beam.Parent = bonesFolder
				end
			end
		end
	else
		local bones = char:FindFirstChild("ESPBones")
		if bones then bones:Destroy() end
	end
end

local function clearBillboard()
	if selectionBillboard then
		selectionBillboard:Destroy()
		selectionBillboard = nil
	end
end

local function showSelectedText(char)
	clearBillboard()
	local head = char:FindFirstChild("Head")
	if not head then return end

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.new(0,80,0,18)
	bb.StudsOffset = Vector3.new(0,2.2,0)
	bb.AlwaysOnTop = true
	bb.Parent = head

	local txt = Instance.new("TextLabel", bb)
	txt.Size = UDim2.new(1,0,1,0)
	txt.BackgroundTransparency = 1
	txt.Text = "SELECCIONADO"
	txt.TextColor3 = Color3.fromRGB(255,100,100)
	txt.TextStrokeTransparency = 0.2
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true
	txt.BorderSizePixel = 2
	txt.BorderColor3 = Color3.fromRGB(0,0,0)

	selectionBillboard = bb
end

local function clearAll()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			restore(p.Character)
			local hl = p.Character:FindFirstChild("CustomHighlight")
			if hl then hl:Destroy() end
			local nameGui = p.Character:FindFirstChild("ESPName")
			if nameGui then nameGui:Destroy() end
			local box = p.Character:FindFirstChild("ESPBox")
			if box then box:Destroy() end
			local bones = p.Character:FindFirstChild("ESPBones")
			if bones then bones:Destroy() end
		end
	end
	clearBillboard()
end

local function applyEffects()
	clearAll()

	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			local color = highlightColor
			if selectedPlayer == p then color = autoHighlightColor end
			applyHighlight(p.Character, color)
			applyESP(p.Character, p)
		end
	end

	if hitboxEnabled and selectedPlayer and selectedPlayer.Character then
		applyHitbox(selectedPlayer.Character)
	end

	if selectedPlayer and selectedPlayer.Character then
		showSelectedText(selectedPlayer.Character)
	end
end

RunService.RenderStepped:Connect(function(dt)
	if not cameraLockEnabled then return end

	local target = getCharacterFromRay()
	if target == lastCameraTarget and target then
		lockConfirm += dt
	else
		lockConfirm = 0
	end

	lastCameraTarget = target

	if lockConfirm > 0.15 and target ~= selectedPlayer then
		selectedPlayer = target
		applyEffects()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.Space then
		holdingSpace = true
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		holdingSpace = false
	end
end)

local function freezeAnimations(humanoid, duration)
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then return end
	for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
		track:AdjustSpeed(0)
	end
	task.delay(duration, function()
		for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
			track:AdjustSpeed(1)
		end
	end)
end

RunService.RenderStepped:Connect(function()
	if (not bunnyEnabled and not bunnyLegitEnabled and not emoteJumpEnabled) or not holdingSpace or not canJump then return end

	local char = LocalPlayer.Character
	if not char then return end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end
	if humanoid.FloorMaterial == Enum.Material.Air then return end

	local moveDir = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir += Camera.CFrame.RightVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir -= Camera.CFrame.RightVector end
	if moveDir.Magnitude == 0 then return end

	moveDir = moveDir.Unit
	canJump = false

	if bunnyLegitEnabled and math.random() < 0.3 then
		task.delay(COOLDOWN, function()
			canJump = true
		end)
		return
	end

	if not emoteJumpEnabled then
		freezeAnimations(humanoid, FREEZE_TIME)
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
		humanoid:ChangeState(Enum.HumanoidStateType.Physics)
	end

	if emoteJumpEnabled then
		root.AssemblyLinearVelocity = Vector3.new(0, JUMP_POWER, 0)
	else
		root.AssemblyLinearVelocity = (moveDir * SIDE_POWER) + Vector3.new(0, JUMP_POWER, 0)
	end

	if not emoteJumpEnabled then
		task.delay(FREEZE_TIME, function()
			humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
			humanoid:ChangeState(Enum.HumanoidStateType.Running)
		end)
	end

	task.delay(COOLDOWN, function()
		canJump = true
	end)
end)

if enteredKey == "admin123" then
	local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
	local Window = Rayfield:CreateWindow({
		Name="PV Hub NEXT",
		ConfigurationSaving={Enabled=true,FileName="PVHub"}
	})
end

if enteredKey == "goku" then
	--// CONFIGURACIÓN BASE
	local highlightColor = Color3.fromRGB(100, 0, 244)
	local autoHighlightColor = Color3.fromRGB(255,80,80)
	-- usar hitboxSize global

	-----------------------------------------------------------
	--// UTILIDADES PARA HITBOX
	-----------------------------------------------------------
	local function saveOriginalRootSize(character)
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and not originalRootSizes[character] then
			originalRootSizes[character] = root.Size
		end
	end

	local function restoreOriginalRootSize(character)
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and originalRootSizes[character] then
			-- intentar restaurar (puede no replicarse al servidor, pero al menos para tu cliente)
			pcall(function()
				root.Size = originalRootSizes[character]
				root.Transparency = 0
				root.CanCollide = true
			end)
			originalRootSizes[character] = nil
		end
	end

	local function applyHitbox(character)
		if not character then return end
		local root = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChildWhichIsA("BasePart")
		if root then
			-- Guardar tamaño original la primera vez
			saveOriginalRootSize(character)
			pcall(function()
				root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
				root.Transparency = 1
				root.CanCollide = false
			end)
		end
	end

	local function removeHitbox(character)
		if not character then return end
		restoreOriginalRootSize(character)
	end

	local function getCharacterFromRay()
		local origin = Camera.CFrame.Position
		local direction = Camera.CFrame.LookVector * 500

		local params = RaycastParams.new()
		params.FilterDescendantsInstances = {LocalPlayer.Character}
		params.FilterType = Enum.RaycastFilterType.Blacklist

		local result = workspace:Raycast(origin, direction, params)
		if not result then return nil end

		local model = result.Instance:FindFirstAncestorOfClass("Model")
		if not model then return nil end

		return Players:GetPlayerFromCharacter(model)
	end

	local function applyHighlight(character, color)
		if not highlightEnabled then
			local hl = character:FindFirstChild("CustomHighlight")
			if hl then hl:Destroy() end
			return
		end

		local hl = character:FindFirstChild("CustomHighlight")
		if not hl then
			hl = Instance.new("Highlight")
			hl.Name = "CustomHighlight"
			hl.FillTransparency = 1
			hl.OutlineColor = color
			hl.OutlineTransparency = 0
			hl.Adornee = character
			hl.Parent = character
		else
			-- actualizar color si ya existe
			pcall(function()
				hl.OutlineColor = color
				hl.OutlineTransparency = 0
			end)
		end
	end

	local function clearBillboard()
		if selectionBillboard then
			selectionBillboard:Destroy()
			selectionBillboard = nil
		end
	end

	local function showSelectedText(char)
		clearBillboard()
		local head = char:FindFirstChild("Head")
		if not head then return end

		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.new(0,80,0,18)
		bb.StudsOffset = Vector3.new(0,2.2,0)
		bb.AlwaysOnTop = true
		bb.Parent = head

		local txt = Instance.new("TextLabel", bb)
		txt.Size = UDim2.new(1,0,1,0)
		txt.BackgroundTransparency = 1
		txt.Text = "SELECCIONADO"
		txt.TextColor3 = Color3.fromRGB(255,100,100)
		txt.TextStrokeTransparency = 0.2
		txt.Font = Enum.Font.GothamBold
		txt.TextScaled = true
		txt.BorderSizePixel = 2
		txt.BorderColor3 = Color3.fromRGB(0,0,0)

		selectionBillboard = bb
	end

	-----------------------------------------------------------

	-----------------------------------------------------------
	--// MANEJO DE JUGADORES / RESTAURAR AL SALIR
	-----------------------------------------------------------
	local function onPlayerAdded(player)
		if player == LocalPlayer then return end

		player.CharacterAdded:Connect(function(char)
			-- cuando reaparezca, aplicar según estado actual
			-- esperar a HumanoidRootPart en caso de que aún no exista
			char:WaitForChild("HumanoidRootPart", 5)
			applyEffects()
		end)

		-- si ya tiene personaje al unirse
		if player.Character then
			applyEffects()
		end
	end

	for _, p in ipairs(Players:GetPlayers()) do
		onPlayerAdded(p)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)

	-- cuando un jugador se va, intentar restaurar tamaño original por si lo modificamos
	Players.PlayerRemoving:Connect(function(player)
		if player and player.Character then
			restoreOriginalRootSize(player.Character)
		end
	end)

	-----------------------------------------------------------
	--// UI
	-----------------------------------------------------------

	local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
	ScreenGui.ResetOnSpawn = false
	ScreenGui.Name = "NZ_GUI_v2"

	-- Panel principal
	local Main = Instance.new("ScrollingFrame", ScreenGui)
	Main.Size = UDim2.new(0, 250, 0, 500)
	Main.Position = UDim2.new(0, 50, 0, 90)
	Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	Main.BorderSizePixel = 0
	Main.Visible = true
	Main.ScrollingDirection = Enum.ScrollingDirection.Y
	Main.ScrollBarThickness = 8
	Main.ScrollBarImageTransparency = 0.5
	Main.CanvasSize = UDim2.new(0, 0, 0, 0)
	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

	-- Layout (orden automático)
	local UIList = Instance.new("UIListLayout", Main)
	UIList.FillDirection = Enum.FillDirection.Vertical
	UIList.Padding = UDim.new(0, 10)
	UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	UIList.SortOrder = Enum.SortOrder.LayoutOrder
	UIList.AutomaticCanvasSize = Enum.AutomaticSize.Y

	-- TÍTULO (container para título + minimizar)
	local TitleFrame = Instance.new("Frame", Main)
	TitleFrame.Size = UDim2.new(1, -20, 0, 44)
	TitleFrame.BackgroundTransparency = 1
	TitleFrame.LayoutOrder = 0

	local Title = Instance.new("TextLabel", TitleFrame)
	Title.Size = UDim2.new(1, -40, 1, 0)
	Title.Position = UDim2.new(0, 0, 0, 0)
	Title.BackgroundTransparency = 1
	Title.Text = "✦ NZ Panel"
	Title.TextColor3 = Color3.new(1,1,1)
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20
	Title.TextXAlignment = Enum.TextXAlignment.Left

	local Minimize = Instance.new("TextButton", TitleFrame)
	Minimize.Size = UDim2.new(0, 34, 0, 34)
	Minimize.Position = UDim2.new(1, -34, 0, 5)
	Minimize.AnchorPoint = Vector2.new(1, 0)
	Minimize.BackgroundTransparency = 0.2
	Minimize.BackgroundColor3 = Color3.fromRGB(60,60,60)
	Minimize.Text = "-"
	Minimize.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", Minimize).CornerRadius = UDim.new(0, 8)

	-- Burbuja NZ (minimizado)
	local Bubble = Instance.new("TextButton", ScreenGui)
	Bubble.Size = UDim2.new(0, 50, 0, 50)
	Bubble.Position = UDim2.new(0, 50, 0, 90)
	Bubble.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
	Bubble.Text = "NZ"
	Bubble.TextColor3 = Color3.new(1,1,1)
	Bubble.Font = Enum.Font.GothamBlack
	Bubble.TextSize = 20
	Bubble.Visible = false
	Bubble.BackgroundTransparency = 0.2
	Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

	Minimize.MouseButton1Click:Connect(function()
		Main.Visible = false
		Bubble.Visible = true
	end)
	Bubble.MouseButton1Click:Connect(function()
		Main.Visible = true
		Bubble.Visible = false
	end)

	-- Drag functionality for mobile
	local dragging = false
	local dragInput
	local dragStart
	local startPos

	TitleFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	TitleFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	RunService.RenderStepped:Connect(function()
		if dragging and dragInput then
			local delta = dragInput.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)

	-- Sección Configuración
	local function newSeparator(title)
		local lbl = Instance.new("TextLabel", Main)
		lbl.Size = UDim2.new(0.95, 0, 0, 26)
		lbl.BackgroundTransparency = 1
		lbl.Text = title
		lbl.TextColor3 = Color3.fromRGB(220,220,220)
		lbl.Font = Enum.Font.GothamBold
		lbl.TextSize = 16
		lbl.LayoutOrder = 1
		return lbl
	end

	newSeparator("Configuración")

	-- Toggle helper que además reaplica a todos los players
	local function newToggle(name, default, callback)
		local btn = Instance.new("TextButton", Main)
		btn.Size = UDim2.new(0.95, 0, 0, 36)
		btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		btn.TextColor3 = Color3.new(1,1,1)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 15
		btn.Text = name .. ": " .. (default and "ON" or "OFF")
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)

		local state = default
		btn.MouseButton1Click:Connect(function()
			state = not state
			btn.Text = name .. ": " .. (state and "ON" or "OFF")
			callback(state)
			-- reaplicar a todos los personajes para reflejar el cambio inmediatamente
			applyEffects()
		end)
		return btn
	end

	local hlToggle = newToggle("Highlight", highlightEnabled, function(s) highlightEnabled = s end)
	local hbToggle = newToggle("Hitbox", hitboxEnabled, function(s) 
		hitboxEnabled = s 
		-- si lo apagamos, restaurar tamaño original de todos los personajes
		if not hitboxEnabled then
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character then restoreOriginalRootSize(p.Character) end
			end
		end
	end)
	local clToggle = newToggle("Camera Lock Detect", cameraLockEnabled, function(s) cameraLockEnabled = s end)

	local invisibleIconToggle = newToggle("Ícono Invisible", false, function(s) 
		Bubble.BackgroundTransparency = s and 1 or 0.2
		Bubble.TextTransparency = s and 1 or 0
	end)

	-- Cambiar color Highlight (botón)
	local ColorButton = Instance.new("TextButton", Main)
	ColorButton.Size = UDim2.new(0.95, 0, 0, 36)
	ColorButton.BackgroundColor3 = Color3.fromRGB(90, 20, 200)
	ColorButton.Text = "Cambiar color Highlight (aleatorio)"
	ColorButton.TextColor3 = Color3.new(1,1,1)
	ColorButton.Font = Enum.Font.Gotham
	ColorButton.TextSize = 15
	Instance.new("UICorner", ColorButton).CornerRadius = UDim.new(0, 10)

	ColorButton.MouseButton1Click:Connect(function()
		highlightColor = Color3.fromHSV(math.random(), 1, 1)
		-- actualizar highlights existentes
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				local hl = p.Character:FindFirstChild("CustomHighlight")
				if hl then
					pcall(function() hl.OutlineColor = highlightColor end)
				end
			end
		end
		applyEffects()
	end)

	-- TextBox para cambiar tamaño + botón aplicar
	local SizeBox = Instance.new("TextBox", Main)
	SizeBox.Size = UDim2.new(0.95, 0, 0, 36)
	SizeBox.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
	SizeBox.PlaceholderText = "Tamaño Hitbox (ej: 20)"
	SizeBox.Text = ""
	SizeBox.TextColor3 = Color3.new(1,1,1)
	SizeBox.Font = Enum.Font.Gotham
	SizeBox.TextSize = 15
	Instance.new("UICorner", SizeBox).CornerRadius = UDim.new(0, 10)

	local ApplyButton = Instance.new("TextButton", Main)
	ApplyButton.Size = UDim2.new(0.95, 0, 0, 36)
	ApplyButton.BackgroundColor3 = Color3.fromRGB(80, 170, 80)
	ApplyButton.Text = "Aplicar tamaño"
	ApplyButton.TextColor3 = Color3.new(1,1,1)
	ApplyButton.Font = Enum.Font.Gotham
	ApplyButton.TextSize = 15
	Instance.new("UICorner", ApplyButton).CornerRadius = UDim.new(0, 10)

	ApplyButton.MouseButton1Click:Connect(function()
		local num = tonumber(SizeBox.Text)
		if num and num > 0 then
			hitboxSize = num
			-- aplicar a todos los personajes (si la función de hitbox está activada)
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character then
					if hitboxEnabled then
						applyHitbox(p.Character)
					end
				end
			end
			SizeBox.Text = "OK ("..tostring(num)..")"
			applyEffects()
		else
			SizeBox.Text = "Inválido"
		end
	end)

	-- Rejoin button
	local Rejoin = Instance.new("TextButton", Main)
	Rejoin.Size = UDim2.new(0.95, 0, 0, 36)
	Rejoin.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
	Rejoin.Text = "Rejoin"
	Rejoin.TextColor3 = Color3.new(1,1,1)
	Rejoin.Font = Enum.Font.GothamBold
	Rejoin.TextSize = 15
	Instance.new("UICorner", Rejoin).CornerRadius = UDim.new(0, 10)

	Rejoin.MouseButton1Click:Connect(function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end)

	-- Aplicar estado inicial a los jugadores ya conectados
	applyEffects()


	-- DASH BUTTON (Q)
	local dashButton = Instance.new("TextButton", ScreenGui)
	dashButton.Size = UDim2.new(0, 60, 0, 60)
	dashButton.Position = UDim2.new(0.8, 0, 0.8, 0)
	dashButton.BackgroundColor3 = Color3.fromRGB(80, 80, 200)
	dashButton.Text = "Q"
	dashButton.TextColor3 = Color3.new(1,1,1)
	dashButton.Font = Enum.Font.GothamBlack
	dashButton.TextSize = 32
	dashButton.Visible = true
	dashButton.BorderSizePixel = 0
	Instance.new("UICorner", dashButton).CornerRadius = UDim.new(1, 0)

	-- Edit mode para mover el botón
	local editDashEnabled = false
	local editDashBtn = Instance.new("TextButton", ScreenGui)
	editDashBtn.Size = UDim2.new(0, 80, 0, 32)
	editDashBtn.Position = UDim2.new(0.8, 70, 0.8, 0)
	editDashBtn.BackgroundColor3 = Color3.fromRGB(200, 180, 60)
	editDashBtn.Text = "Edit: OFF"
	editDashBtn.TextColor3 = Color3.new(0,0,0)
	editDashBtn.Font = Enum.Font.GothamBold
	editDashBtn.TextSize = 16
	editDashBtn.Visible = true
	editDashBtn.BorderSizePixel = 0
	Instance.new("UICorner", editDashBtn).CornerRadius = UDim.new(0, 10)
	
    -- Toggle para mostrar/ocultar Dash y Edit
    local showDashAndEdit = true
    local dashEditToggle = Instance.new("TextButton", Main)
    dashEditToggle.Size = UDim2.new(0.95, 0, 0, 36)
    dashEditToggle.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    dashEditToggle.TextColor3 = Color3.new(1,1,1)
    dashEditToggle.Font = Enum.Font.Gotham
    dashEditToggle.TextSize = 15
    dashEditToggle.Text = "Dash/Edit: ON"
    Instance.new("UICorner", dashEditToggle).CornerRadius = UDim.new(0, 10)
    dashEditToggle.LayoutOrder = 2

    dashEditToggle.MouseButton1Click:Connect(function()
        showDashAndEdit = not showDashAndEdit
        dashEditToggle.Text = "Dash/Edit: " .. (showDashAndEdit and "ON" or "OFF")
        dashButton.Visible = showDashAndEdit
        editDashBtn.Visible = showDashAndEdit
    end)
    -- Estado inicial
    dashButton.Visible = showDashAndEdit
    editDashBtn.Visible = showDashAndEdit

	editDashBtn.MouseButton1Click:Connect(function()
		editDashEnabled = not editDashEnabled
		editDashBtn.Text = editDashEnabled and "Edit: ON" or "Edit: OFF"
	end)

	-- Drag funcionalidad para el botón Dash
	local draggingDash = false
	local dragInputDash, dragStartDash, startPosDash

	dashButton.InputBegan:Connect(function(input)
		if not editDashEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			draggingDash = true
			dragStartDash = input.Position
			startPosDash = dashButton.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					draggingDash = false
				end
			end)
		end
	end)

	dashButton.InputChanged:Connect(function(input)
		if not editDashEnabled then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInputDash = input
		end
	end)

	RunService.RenderStepped:Connect(function()
		if editDashEnabled and draggingDash and dragInputDash then
			local delta = dragInputDash.Position - dragStartDash
			dashButton.Position = UDim2.new(startPosDash.X.Scale, startPosDash.X.Offset + delta.X, startPosDash.Y.Scale, startPosDash.Y.Offset + delta.Y)
		end
	end)

	-- Al presionar el botón Dash, simula la Q
	dashButton.MouseButton1Click:Connect(function()
		if not editDashEnabled then
			-- Simular Input Q
			local virtualInput = game:GetService("VirtualInputManager")
			if virtualInput then
				virtualInput:SendKeyEvent(true, Enum.KeyCode.Q, false, game)
				virtualInput:SendKeyEvent(false, Enum.KeyCode.Q, false, game)
			end
		end
	end)

	-- === FOLLOW MODE ===
	local followEnabled = false
	local followText = Instance.new("TextLabel", ScreenGui)
	followText.Size = UDim2.new(0, 220, 0, 30)
	followText.Position = UDim2.new(0.5, -110, 0.15, 0)
	followText.BackgroundTransparency = 0.4
	followText.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	followText.TextColor3 = Color3.fromRGB(255, 255, 120)
	followText.Font = Enum.Font.GothamBold
	followText.TextSize = 16
	followText.Text = "FOLLOW DESACTIVADO"
	followText.Visible = false
	followText.BorderSizePixel = 0

	-- === TELEPORT G ===
	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.G then
			followEnabled = not followEnabled
			followText.Text = followEnabled and "FOLLOW ACTIVADO" or "FOLLOW DESACTIVADO"
			followText.Visible = true
			task.delay(2, function()
				followText.Visible = false
			end)
			playSound()
		end
	end)

	-- Follow loop
	RunService.RenderStepped:Connect(function()
		if followEnabled and selectedPlayer and selectedPlayer.Character and LocalPlayer.Character then
			local targetRoot = selectedPlayer.Character:FindFirstChild("HumanoidRootPart")
			local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if targetRoot and myRoot then
				myRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, -2)
			end
		end
	end)

if enteredKey == "admin123" then
	-- FPS/Ping display
	local Stats = Instance.new("TextLabel", ScreenGui)
	Stats.Size = UDim2.new(0, 240, 0, 30)
	Stats.Position = UDim2.new(0, 10, 0, 10)
	Stats.BackgroundTransparency = 1
	Stats.TextColor3 = Color3.new(1,1,1)
	Stats.Font = Enum.Font.GothamBold
	Stats.TextSize = 16
	Stats.TextXAlignment = Enum.TextXAlignment.Left

	RunService.RenderStepped:Connect(function(dt)
		local fps = math.floor(1 / dt)
		local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
		Stats.Text = "FPS: "..fps.." | Ping: "..ping.."ms"
	end)
end

else
	local ESP = Window:CreateTab("ESP", 4483362458)
	ESP:CreateToggle({Name="Hitbox",CurrentValue=true,Callback=function(v) hitboxEnabled=v; applyEffects(); playSound() end})
	ESP:CreateInput({
		Name="Tamaño Hitbox",
		PlaceholderText="10-50",
		RemoveTextAfterFocusLost=false,
		Callback=function(v)
			local size = tonumber(v)
			if size and size >= 10 and size <= 50 then
				hitboxSize = size
				applyEffects()
				playSound()
			end
		end
	})
	local Music = Window:CreateTab("Music", 4483362458)
	Music:CreateButton({
		Name="Sleeping City",
		Callback=function()
			currentMusic = "Sleeping City"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Voce na Mira",
		Callback=function()
			currentMusic = "Voce na Mira"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Gozalo",
		Callback=function()
			currentMusic = "Gozalo"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="HYPNOSAES RENICHT ESPECTRAL",
		Callback=function()
			currentMusic = "HYPNOSAES RENICHT ESPECTRAL"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Nuts Lil Peep",
		Callback=function()
			currentMusic = "Nuts Lil Peep"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Mimosa 2000",
		Callback=function()
			currentMusic = "Mimosa 2000"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Conosco Tu Debilidad",
		Callback=function()
			currentMusic = "Conosco Tu Debilidad"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Todos Los Caminos Llevan a Roma",
		Callback=function()
			currentMusic = "Todos Los Caminos Llevan a Roma"
			playSelectedMusic()
			playSound()
		end
	})
	Music:CreateButton({
		Name="Detener Música",
		Callback=function()
			stopMusic()
			playSound()
		end
	})
	local UI = Window:CreateTab("UI", 4483362458)
	UI:CreateButton({
		Name="Toggle UI",
		Callback=function()
			Window.Minimized = not Window.Minimized
			playSound()
		end
	})
end

if enteredKey == "admin123" then
	local Main = Window:CreateTab("Main", 4483362458)
local ESP = Window:CreateTab("ESP/Aiming", 4483362458)
local Movement = Window:CreateTab("Movement", 4483362458)
local Music = Window:CreateTab("Music", 4483362458)
local Explicacion = Window:CreateTab("Explicacion", 4483362458)
local Settings = Window:CreateTab("Settings", 4483362458)

Main:CreateToggle({Name="Camera Lock Detect",CurrentValue=true,Callback=function(v) cameraLockEnabled=v; playSound() end})
Main:CreateButton({
	Name="Rejoin",
	Callback=function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end
})

ESP:CreateToggle({Name="Highlight",CurrentValue=true,Callback=function(v) highlightEnabled=v; applyEffects(); playSound() end})
ESP:CreateToggle({Name="Hitbox",CurrentValue=true,Callback=function(v) hitboxEnabled=v; applyEffects(); playSound() end})
ESP:CreateInput({
	Name="Tamaño Hitbox",
	PlaceholderText="10-50",
	RemoveTextAfterFocusLost=false,
	Callback=function(v)
		local size = tonumber(v)
		if size and size >= 10 and size <= 50 then
			hitboxSize = size
			applyEffects()
			playSound()
		end
	end
})

ESP:CreateToggle({Name="ESP Box",CurrentValue=false,Callback=function(v) espBoxEnabled=v; applyEffects(); playSound() end})
ESP:CreateToggle({Name="ESP Bones",CurrentValue=false,Callback=function(v) espBonesEnabled=v; applyEffects(); playSound() end})
ESP:CreateToggle({Name="ESP Name",CurrentValue=false,Callback=function(v) espNameEnabled=v; applyEffects(); playSound() end})

Movement:CreateToggle({
	Name="Bunny Jump",
	CurrentValue=false,
	Callback=function(v) bunnyEnabled=v; playSound() end
})

Movement:CreateToggle({
	Name="Bunny Jump Legit",
	CurrentValue=false,
	Callback=function(v) bunnyLegitEnabled=v; playSound() end
})

Movement:CreateToggle({
	Name="Emote Jump",
	CurrentValue=false,
	Callback=function(v) emoteJumpEnabled=v; playSound() end
})

Movement:CreateLabel("Recomiendo poner 65 de impulso")

Music:CreateButton({
	Name="Sleeping City",
	Callback=function()
		currentMusic = "Sleeping City"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Voce na Mira",
	Callback=function()
		currentMusic = "Voce na Mira"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Gozalo",
	Callback=function()
		currentMusic = "Gozalo"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="HYPNOSAES RENICHT ESPECTRAL",
	Callback=function()
		currentMusic = "HYPNOSAES RENICHT ESPECTRAL"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Nuts Lil Peep",
	Callback=function()
		currentMusic = "Nuts Lil Peep"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Mimosa 2000",
	Callback=function()
		currentMusic = "Mimosa 2000"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Conosco Tu Debilidad",
	Callback=function()
		currentMusic = "Conosco Tu Debilidad"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Todos Los Caminos Llevan a Roma",
	Callback=function()
		currentMusic = "Todos Los Caminos Llevan a Roma"
		playSelectedMusic()
		playSound()
	end
})

Music:CreateButton({
	Name="Detener Música",
	Callback=function()
		stopMusic()
		playSound()
	end
})

Settings:CreateToggle({Name="Sonido de Toggles",CurrentValue=true,Callback=function(v) soundEnabled=v; playSound() end})
Settings:CreateButton({
	Name="Detectar Side del Juego",
	Callback=function()
		local result = detectGameSide()
		print("Resultado de detección: " .. result)
		playSound()
	end
})
Settings:CreateLabel("Configuraciones generales del script")

Explicacion:CreateLabel("=== GUÍA DE USO DEL SCRIPT ===")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("📍 MAIN TAB:")
Explicacion:CreateLabel("• Camera Lock: Detecta automáticamente al jugador que apuntas")
Explicacion:CreateLabel("• Rejoin: Te lleva a la misma partida")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("👁️ ESP/AIMING TAB:")
Explicacion:CreateLabel("• Highlight: Resalta a los enemigos (azul normal, rojo seleccionado)")
Explicacion:CreateLabel("• Hitbox: Amplía los hitbox de los enemigos")
Explicacion:CreateLabel("• Tamaño Hitbox: Ajusta el tamaño (10-50 píxeles)")
Explicacion:CreateLabel("• ESP Box: Muestra cajas alrededor de los enemigos")
Explicacion:CreateLabel("• ESP Bones: Muestra el esqueleto de los enemigos")
Explicacion:CreateLabel("• ESP Name: Muestra los nombres de los enemigos")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("🏃 MOVEMENT TAB:")
Explicacion:CreateLabel("• Bunny Jump: Activa/desactiva con ESPACIO o presiona E")
Explicacion:CreateLabel("• Bunny Jump Legit: Versión con fallos aleatorios para parecer más real")
Explicacion:CreateLabel("• Emote Jump: Salto vertical con impulso, sin cancelar animaciones/emotes")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("🎵 MUSIC TAB:")
Explicacion:CreateLabel("• Botones de Canciones: Presiona para reproducir esa canción")
Explicacion:CreateLabel("• Detener Música: Para la reproducción actual")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("⚙️ SETTINGS TAB:")
Explicacion:CreateLabel("• Sonido de Toggles: Activa/desactiva sonidos al cambiar opciones")
Explicacion:CreateLabel("• Detectar Side del Juego: Verifica si el juego es client-side o server-side")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("⚠️ TECLAS PRINCIPALES:")
Explicacion:CreateLabel("• E = Activar/desactivar Bunny Jump")
Explicacion:CreateLabel("• ESPACIO = Saltar (requiere Bunny Jump activado)")

end

if enteredKey == "admin123" then
	applyEffects()
	Rayfield:LoadConfiguration()
end

if enteredKey == "admin123" then
RunService.RenderStepped:Connect(function()
	if espBoxEnabled or espBonesEnabled or espNameEnabled then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				local char = p.Character
				if espBoxEnabled then
					local box = char:FindFirstChild("ESPBox")
					if box then
						local root = char:FindFirstChild("HumanoidRootPart")
						if root then box.CFrame = root.CFrame end
					end
				end
			end
		end
	end
end)
end

if enteredKey == "admin123" then
local bunnyGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
bunnyGui.ResetOnSpawn = false
bunnyText = Instance.new("TextLabel", bunnyGui)
bunnyText.Size = UDim2.new(0,220,0,30)
bunnyText.Position = UDim2.new(0.5,-110,0.1,0)
bunnyText.BackgroundTransparency = 0.4
bunnyText.BackgroundColor3 = Color3.fromRGB(20,20,20)
bunnyText.TextColor3 = Color3.fromRGB(120,255,120)
bunnyText.Font = Enum.Font.GothamBold
bunnyText.TextSize = 16
bunnyText.Text = "BUNNY JUMP ACTIVADO"
bunnyText.Visible = false
bunnyText.BorderSizePixel = 0
end

UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if enteredKey == "admin123" and input.KeyCode == Enum.KeyCode.E then
		bunnyEnabled = not bunnyEnabled
		if bunnyText then bunnyText.Visible = bunnyEnabled end
	end
	if enteredKey == "admin123" and input.KeyCode == Enum.KeyCode.K then
		Window:Minimize()
		if soundEnabled then
			hideMenuSound:Stop()
			hideMenuSound:Play()
		end
	end
end)
