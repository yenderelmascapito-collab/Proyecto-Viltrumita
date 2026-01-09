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
--// UI
-----------------------------------------------------------

local ScreenGui = Instance.new("ScreenGui", LocalPlayer:WaitForChild("PlayerGui"))
ScreenGui.ResetOnSpawn = false
ScreenGui.Name = "NZ_GUI_v2"

-- Panel principal
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0, 300, 0, 360)
Main.Position = UDim2.new(0, 50, 0, 90)
Main.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Main.BorderSizePixel = 0
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- Layout (orden automático)
local UIList = Instance.new("UIListLayout", Main)
UIList.FillDirection = Enum.FillDirection.Vertical
UIList.Padding = UDim.new(0, 10)
UIList.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIList.SortOrder = Enum.SortOrder.LayoutOrder

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
Bubble.Size = UDim2.new(0, 64, 0, 64)
Bubble.Position = UDim2.new(0, 50, 0, 90)
Bubble.BackgroundColor3 = Color3.fromRGB(100, 0, 200)
Bubble.Text = "NZ"
Bubble.TextColor3 = Color3.new(1,1,1)
Bubble.Font = Enum.Font.GothamBlack
Bubble.TextSize = 24
Bubble.Visible = false
Instance.new("UICorner", Bubble).CornerRadius = UDim.new(1, 0)

Minimize.MouseButton1Click:Connect(function()
	Main.Visible = false
	Bubble.Visible = true
end)
Bubble.MouseButton1Click:Connect(function()
	Main.Visible = true
	Bubble.Visible = false
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
		applyToAllPlayers()
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
		headSize = num
		-- aplicar a todos los personajes (si la función de hitbox está activada)
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer and p.Character then
				if hitboxEnabled then
					applyHitbox(p.Character)
				end
			end
		end
		SizeBox.Text = "OK ("..tostring(num)..")"
	else
		SizeBox.Text = "Inválido"
	end
end)

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
applyToAllPlayers()
