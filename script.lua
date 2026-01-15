--// CONFIGURACIÓN BASE
local highlightColor = Color3.fromRGB(100, 0, 244)
local headSize = 25 -- tamaño predeterminado cambiado a 25

--// SERVICIOS
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")

--// VARIABLES
local highlightEnabled = true
local hitboxEnabled = true

-- guardamos tamaños originales para poder restaurarlos
local originalRootSizes = {}

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
			root.Size = Vector3.new(headSize, headSize, headSize)
			root.Transparency = 1
			root.CanCollide = false
		end)
	end
end

local function removeHitbox(character)
	if not character then return end
	restoreOriginalRootSize(character)
end

-----------------------------------------------------------
--// FUNCIÓN PRINCIPAL: APLICAR HIGHLIGHT + HITBOX
-----------------------------------------------------------
local function applyHighlightAndHitbox(character)
	if not character then return end

	-- HITBOX
	if hitboxEnabled then
		applyHitbox(character)
	else
		removeHitbox(character)
	end

	-- HIGHLIGHT
	local existing = character:FindFirstChild("CustomHighlight")
	if highlightEnabled then
		if not existing then
			local highlight = Instance.new("Highlight")
			highlight.Name = "CustomHighlight"
			highlight.FillTransparency = 1
			highlight.OutlineColor = highlightColor
			highlight.OutlineTransparency = 0
			highlight.Adornee = character
			highlight.Parent = character
		else
			-- actualizar color si ya existe
			pcall(function()
				existing.OutlineColor = highlightColor
				existing.OutlineTransparency = 0
			end)
		end
	else
		if existing then
			pcall(function() existing:Destroy() end)
		end
	end
end

local function applyToAllPlayers()
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character then
			applyHighlightAndHitbox(p.Character)
		end
	end
end

-----------------------------------------------------------
--// MANEJO DE JUGADORES / RESTAURAR AL SALIR
-----------------------------------------------------------
local function onPlayerAdded(player)
	if player == LocalPlayer then return end

	player.CharacterAdded:Connect(function(char)
		-- cuando reaparezca, aplicar según estado actual
		-- esperar a HumanoidRootPart en caso de que aún no exista
		char:WaitForChild("HumanoidRootPart", 5)
		applyHighlightAndHitbox(char)
	end)

	-- si ya tiene personaje al unirse
	if player.Character then
		applyHighlightAndHitbox(player.Character)
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
--// UI CON RAYFIELD
-----------------------------------------------------------
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "PV Hub",
	ConfigurationSaving = {
		Enabled = true,
		FileName = "PVHub_Config"
	},
	KeySystem = false,
	KeySettings = {
		Key = "K"
	}
})

local MainTab = Window:CreateTab("Main", 4483362458)
local VisualsTab = Window:CreateTab("Visuals", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

MainTab:CreateSection("Toggles")

local HighlightToggle = MainTab:CreateToggle({
	Name = "Highlight Enabled",
	CurrentValue = highlightEnabled,
	Flag = "HighlightEnabled",
	Callback = function(Value)
		highlightEnabled = Value
		applyToAllPlayers()
	end,
})

local HitboxToggle = MainTab:CreateToggle({
	Name = "Hitbox Enabled",
	CurrentValue = hitboxEnabled,
	Flag = "HitboxEnabled",
	Callback = function(Value)
		hitboxEnabled = Value
		if not hitboxEnabled then
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character then restoreOriginalRootSize(p.Character) end
			end
		end
		applyToAllPlayers()
	end,
})

VisualsTab:CreateSection("Highlight")

local HighlightColorPicker = VisualsTab:CreateColorPicker({
	Name = "Highlight Color",
	Color = highlightColor,
	Flag = "HighlightColor",
	Callback = function(Value)
		highlightColor = Value
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				local hl = p.Character:FindFirstChild("CustomHighlight")
				if hl then
					pcall(function() hl.OutlineColor = highlightColor end)
				end
			end
		end
	end
})

VisualsTab:CreateSection("Hitbox")

local SizeSlider = VisualsTab:CreateSlider({
	Name = "Hitbox Size",
	Range = {5, 50},
	Increment = 1,
	Suffix = "",
	CurrentValue = headSize,
	Flag = "HitboxSize",
	Callback = function(Value)
		headSize = Value
		if hitboxEnabled then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer and p.Character then
					applyHitbox(p.Character)
				end
			end
		end
	end,
})

SettingsTab:CreateSection("Actions")

local RejoinButton = SettingsTab:CreateButton({
	Name = "Rejoin",
	Callback = function()
		TeleportService:Teleport(game.PlaceId, LocalPlayer)
	end,
})

-- FPS/Ping display
local Stats = Instance.new("TextLabel", LocalPlayer:WaitForChild("PlayerGui"))
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

-- Aplicar estado inicial
applyToAllPlayers()

Rayfield:LoadConfiguration()
