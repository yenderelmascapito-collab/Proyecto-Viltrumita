local highlightColor = Color3.fromRGB(100,0,244)
local autoHighlightColor = Color3.fromRGB(255,80,80)
local headSize = 25
local maxSelectDistance = 120

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

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
local SIDE_POWER = 140
local JUMP_POWER = 90
local COOLDOWN = 0.16
local FREEZE_TIME = 0.15
local holdingSpace = false
local canJump = true

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
	if not bunnyEnabled or not holdingSpace or not canJump then return end

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

	freezeAnimations(humanoid, FREEZE_TIME)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	humanoid:ChangeState(Enum.HumanoidStateType.Physics)

	root.AssemblyLinearVelocity =
		(moveDir * SIDE_POWER) + Vector3.new(0, JUMP_POWER, 0)

	task.delay(FREEZE_TIME, function()
		humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end)

	task.delay(COOLDOWN, function()
		canJump = true
	end)
end)

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Window = Rayfield:CreateWindow({
	Name="PV Hub NEXT",
	ConfigurationSaving={Enabled=true,FileName="PVHub"}
})

local Main = Window:CreateTab("Main", 4483362458)
local ESP = Window:CreateTab("ESP/Aiming", 4483362458)
local Movement = Window:CreateTab("Movement", 4483362458)
local Explicacion = Window:CreateTab("Explicacion", 4483362458)
local Settings = Window:CreateTab("Settings", 4483362458)

Main:CreateToggle({Name="Camera Lock Detect",CurrentValue=true,Callback=function(v) cameraLockEnabled=v end})
Main:CreateButton({
	Name="Rejoin",
	Callback=function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end
})

ESP:CreateToggle({Name="Highlight",CurrentValue=true,Callback=function(v) highlightEnabled=v; applyEffects() end})
ESP:CreateToggle({Name="Hitbox",CurrentValue=true,Callback=function(v) hitboxEnabled=v; applyEffects() end})
ESP:CreateInput({
	Name="Tamaño Hitbox",
	PlaceholderText="10-50",
	RemoveTextAfterFocusLost=false,
	Callback=function(v)
		local size = tonumber(v)
		if size and size >= 10 and size <= 50 then
			hitboxSize = size
			applyEffects()
		end
	end
})

ESP:CreateToggle({Name="ESP Box",CurrentValue=false,Callback=function(v) espBoxEnabled=v; applyEffects() end})
ESP:CreateToggle({Name="ESP Bones",CurrentValue=false,Callback=function(v) espBonesEnabled=v; applyEffects() end})
ESP:CreateToggle({Name="ESP Name",CurrentValue=false,Callback=function(v) espNameEnabled=v; applyEffects() end})

Movement:CreateToggle({
	Name="Bunny Jump",
	CurrentValue=false,
	Callback=function(v) bunnyEnabled=v end
})

Movement:CreateLabel("Recomiendo poner 65 de impulso")

local BunnyPresets = {
	["Muy Bajo"] = {side=90,jump=45},
	["Bajo"] = {side=130,jump=65},
	["Medio"] = {side=140,jump=90},
	["Alto"] = {side=220,jump=110},
	["Muy Alto"] = {side=260,jump=130},
	["Extremo"] = {side=320,jump=160}
}

Movement:CreateDropdown({
	Name="Bunny Preset",
	Options={"Muy Bajo","Bajo","Medio","Alto","Muy Alto","Extremo"},
	CurrentOption="Medio",
	Callback=function(v)
		if BunnyPresets[v] then
			SIDE_POWER = BunnyPresets[v].side
			JUMP_POWER = BunnyPresets[v].jump
		end
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
Explicacion:CreateLabel("• Bunny Preset: Presets rápidos de salto")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("⚠️ TECLAS PRINCIPALES:")
Explicacion:CreateLabel("• E = Activar/desactivar Bunny Jump")
Explicacion:CreateLabel("• ESPACIO = Saltar (requiere Bunny Jump activado)")

applyEffects()
Rayfield:LoadConfiguration()

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

local bunnyGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
bunnyGui.ResetOnSpawn = false
local bunnyText = Instance.new("TextLabel", bunnyGui)
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

UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.E then
		bunnyEnabled = not bunnyEnabled
		bunnyText.Visible = bunnyEnabled
	end
end)
