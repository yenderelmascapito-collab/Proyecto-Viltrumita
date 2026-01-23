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
local applyMode = "All"
local selectedPlayer = nil
local cameraLockEnabled = false
local manualSelectEnabled = true
local originalRootSizes = {}
local selectionBillboard = nil
local lastCameraTarget = nil
local lockConfirm = 0

local bunnyEnabled = false
local SIDE_POWER = 180
local JUMP_POWER = 90
local COOLDOWN = 0.16
local FREEZE_TIME = 0.15
local holdingSpace = false
local canJump = true

local hitboxSize = 25

local antiStunEnabled = false
local antiRagdollEnabled = false
local antiHitEnabled = false

local originalWalkSpeed = 16
local originalJumpPower = 50
local originalAutoRotate = true

local autoBlockEnabled = false
local blockActive = false

local function setupHumanoid(hum)
	if not hum then return end
	
	hum.StateChanged:Connect(function(oldState, newState)
		if antiStunEnabled and newState == Enum.HumanoidStateType.PlatformStanding then
			hum.WalkSpeed = originalWalkSpeed
			hum.JumpPower = originalJumpPower
			hum.AutoRotate = originalAutoRotate
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		elseif antiRagdollEnabled and (newState == Enum.HumanoidStateType.Ragdoll or newState == Enum.HumanoidStateType.FallingDown) then
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
	end)
end

LocalPlayer.CharacterAdded:Connect(function(char)
	local hum = char:WaitForChild("Humanoid", 5)
	if hum then
		setupHumanoid(hum)
	end
end)

if LocalPlayer.Character then
	local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	if hum then
		setupHumanoid(hum)
	end
end

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
	txt.TextColor3 = Color3.fromRGB(255,70,70)
	txt.TextStrokeTransparency = 0.3
	txt.Font = Enum.Font.GothamBold
	txt.TextScaled = true

	selectionBillboard = bb
end

local function clearAll()
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then
			restore(p.Character)
			local hl = p.Character:FindFirstChild("CustomHighlight")
			if hl then hl:Destroy() end
		end
	end
	clearBillboard()
end

local function applyEffects()
	clearAll()

	if applyMode == "All" then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				if hitboxEnabled then applyHitbox(p.Character) end
				applyHighlight(p.Character, highlightColor)
			end
		end
	elseif selectedPlayer and selectedPlayer.Character then
		if hitboxEnabled then applyHitbox(selectedPlayer.Character) end
		applyHighlight(selectedPlayer.Character, autoHighlightColor)
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
		applyMode = "Selected"
		applyEffects()
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end

	if input.KeyCode == Enum.KeyCode.Y and manualSelectEnabled then
		local target = getCharacterFromRay()
		if not target then return end

		if selectedPlayer == target then
			selectedPlayer = nil
			clearAll()
		else
			selectedPlayer = target
			applyMode = "Selected"
			applyEffects()
		end
	end

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
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir += Camera.CFrame.LookVector end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir -= Camera.CFrame.LookVector end
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
local Defense = Window:CreateTab("Defense", 4483362458)
local Explicacion = Window:CreateTab("Explicacion", 4483362458)
local Settings = Window:CreateTab("Settings", 4483362458)

Main:CreateToggle({Name="Camera Lock Detect",CurrentValue=false,Callback=function(v) cameraLockEnabled=v end})
Main:CreateToggle({Name="Manual Select (Y)",CurrentValue=true,Callback=function(v) manualSelectEnabled=v end})
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

Movement:CreateToggle({
	Name="Bunny Jump",
	CurrentValue=false,
	Callback=function(v) bunnyEnabled=v end
})

Movement:CreateLabel("Recomiendo poner 65 de impulso")

Movement:CreateInput({
	Name="Potencia del Salto",
	PlaceholderText="40-140",
	RemoveTextAfterFocusLost=false,
	Callback=function(v)
		local power = tonumber(v)
		if power and power >= 40 and power <= 140 then
			JUMP_POWER = power
		end
	end
})

local BunnyPresets = {
	["Muy Bajo"] = {side=90,jump=45},
	["Bajo"] = {side=130,jump=65},
	["Medio"] = {side=180,jump=90},
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

Defense:CreateToggle({
	Name="Anti Stun",
	CurrentValue=false,
	Callback=function(v) 
		antiStunEnabled = v
		if v then
			local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				originalWalkSpeed = hum.WalkSpeed
				originalJumpPower = hum.JumpPower
				originalAutoRotate = hum.AutoRotate
			end
		end
	end
})

Defense:CreateToggle({
	Name="Anti Ragdoll",
	CurrentValue=false,
	Callback=function(v) antiRagdollEnabled=v end
})

Defense:CreateToggle({
	Name="Anti Hit",
	CurrentValue=false,
	Callback=function(v) antiHitEnabled=v end
})

Defense:CreateToggle({
	Name="Auto Block (F)",
	CurrentValue=false,
	Callback=function(v)
		autoBlockEnabled = v
		if not v and blockActive then
			blockActive = false
			if keyrelease then pcall(function() keyrelease(Enum.KeyCode.F) end) end
		end
	end
})

Settings:CreateLabel("Configuraciones generales del script")

Explicacion:CreateLabel("=== GUÍA DE USO DEL SCRIPT ===")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("📍 MAIN TAB:")
Explicacion:CreateLabel("• Camera Lock: Detecta automáticamente al jugador que apuntas")
Explicacion:CreateLabel("• Manual Select (Y): Presiona Y para seleccionar/deseleccionar jugador")
Explicacion:CreateLabel("• Rejoin: Te lleva a la misma partida")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("👁️ ESP/AIMING TAB:")
Explicacion:CreateLabel("• Highlight: Resalta a los enemigos (colores diferentes)")
Explicacion:CreateLabel("• Hitbox: Amplía los hitbox de los enemigos")
Explicacion:CreateLabel("• Tamaño Hitbox: Ajusta el tamaño (10-50 píxeles)")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("🏃 MOVEMENT TAB:")
Explicacion:CreateLabel("• Bunny Jump: Activa/desactiva con ESPACIO o presiona E")
Explicacion:CreateLabel("• Potencia del Salto: Ajusta la fuerza (40-140)")
Explicacion:CreateLabel("• Bunny Preset: Presets rápidos de salto")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("🛡️ DEFENSE TAB:")
Explicacion:CreateLabel("• Anti Stun: Evita ser aturdido")
Explicacion:CreateLabel("• Anti Ragdoll: Evita caer/ragdoll")
Explicacion:CreateLabel("• Anti Hit: Evita ser golpeado")
Explicacion:CreateLabel("• Auto Block (F): Mantiene bloqueado con F automáticamente")
Explicacion:CreateLabel("")
Explicacion:CreateLabel("⚠️ TECLAS PRINCIPALES:")
Explicacion:CreateLabel("• Y = Seleccionar/deseleccionar jugador")
Explicacion:CreateLabel("• E = Activar/desactivar Bunny Jump")
Explicacion:CreateLabel("• ESPACIO = Saltar (requiere Bunny Jump activado)")
Explicacion:CreateLabel("• F = Bloquear (con Auto Block)")

applyEffects()
Rayfield:LoadConfiguration()

RunService.Stepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end
	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	if antiHitEnabled then
		root.AssemblyAngularVelocity = Vector3.zero
	end
end)

local EXCLUDE_KEYS = {
	[Enum.KeyCode.One]=true,
	[Enum.KeyCode.Two]=true,
	[Enum.KeyCode.Three]=true,
	[Enum.KeyCode.Four]=true,
	[Enum.KeyCode.Q]=true
}

local blockCooldown = 0

UserInputService.InputBegan:Connect(function(input,gp)
	if gp or not autoBlockEnabled then return end

	if EXCLUDE_KEYS[input.KeyCode] then
		if blockActive then
			blockActive = false
			if keyrelease then pcall(function() keyrelease(Enum.KeyCode.F) end) end
		end
		blockCooldown = tick()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if not autoBlockEnabled then return end

	if EXCLUDE_KEYS[input.KeyCode] then
		task.delay(0.12, function()
			if autoBlockEnabled and not blockActive then
				blockActive = true
				if keypress then pcall(function() keypress(Enum.KeyCode.F) end) end
			end
		end)
	end
end)

RunService.RenderStepped:Connect(function()
	if not autoBlockEnabled then
		if blockActive then
			blockActive = false
			if keyrelease then pcall(function() keyrelease(Enum.KeyCode.F) end) end
		end
		return
	end
	
	if tick() - blockCooldown < 0.05 then return end
	
	if not blockActive then
		blockActive = true
		if keypress then pcall(function() keypress(Enum.KeyCode.F) end) end
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
