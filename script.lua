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
local showHitbox = false -- si true muestra la parte del hitbox (transparencia 0), si false la oculta (1)
local hitboxTransparency = 1 -- valor entre 0 (opaco) y 1 (invisible)

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
				root.Transparency = (showHitbox and hitboxTransparency or 1)
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

-- UI: WindUI-based minimal interface
local ok, WindUI = pcall(function()
	return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if ok and WindUI and type(WindUI.CreateWindow) == "function" then
	local window = WindUI:CreateWindow({Title = "PV HUB", Subtitle = "PV", Icon = "☀️", Theme = "Dark", ToggleKey = Enum.KeyCode.Z})
	local mainTab = window:Tab({Title = "Main"})

	mainTab:Button({Title = "Toggle Highlight", Callback = function()
		highlightEnabled = not highlightEnabled
		applyToAllPlayers()
	end})

	mainTab:Button({Title = "Toggle Hitbox", Callback = function()
		hitboxEnabled = not hitboxEnabled
		if not hitboxEnabled then
			for _, p in ipairs(Players:GetPlayers()) do
				if p.Character then restoreOriginalRootSize(p.Character) end
			end
		end
		applyToAllPlayers()
	end})

	mainTab:Button({Title = "Mostrar Hitbox", Callback = function()
		showHitbox = not showHitbox
		applyToAllPlayers()
	end})

	-- Slider para transparencia de hitbox (0 = visible/opaco, 1 = invisible)
	local sliderOk, _ = pcall(function()
		mainTab:Slider({
			Title = "Hitbox Transparency",
			Min = 0,
			Max = 1,
			Default = hitboxTransparency,
			Round = 2,
			Callback = function(v)
				hitboxTransparency = v
				applyToAllPlayers()
			end
		})
	end)

	if not sliderOk then
		mainTab:Button({Title = "Set Transparency...", Callback = function()
			local guiName = "PV_SetTransparency"
			local existing = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(guiName)
			if existing then existing:Destroy() end
			local pg = LocalPlayer:WaitForChild("PlayerGui")
			local sg = Instance.new("ScreenGui", pg)
			sg.Name = guiName
			sg.ResetOnSpawn = false
			local f = Instance.new("Frame", sg)
			f.Size = UDim2.new(0, 300, 0, 120)
			f.Position = UDim2.new(0.5, -150, 0.5, -60)
			f.BackgroundColor3 = Color3.fromRGB(30,30,30)
			Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)
			local title = Instance.new("TextLabel", f)
			title.Size = UDim2.new(1, -20, 0, 28)
			title.Position = UDim2.new(0,10,0,8)
			title.BackgroundTransparency = 1
			title.Text = "Transparencia Hitbox (0-1)"
			title.TextColor3 = Color3.new(1,1,1)
			title.Font = Enum.Font.GothamBold
			title.TextSize = 16
			local box = Instance.new("TextBox", f)
			box.Size = UDim2.new(1, -20, 0, 36)
			box.Position = UDim2.new(0,10,0,44)
			box.BackgroundColor3 = Color3.fromRGB(50,50,50)
			box.PlaceholderText = "Ej: 0.5"
			box.Text = tostring(hitboxTransparency)
			box.TextColor3 = Color3.new(1,1,1)
			box.Font = Enum.Font.Gotham
			Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
			local applyBtn = Instance.new("TextButton", f)
			applyBtn.Size = UDim2.new(0.5, -15, 0, 34)
			applyBtn.Position = UDim2.new(0,10,1,-44)
			applyBtn.BackgroundColor3 = Color3.fromRGB(80,170,80)
			applyBtn.Text = "Aplicar"
			applyBtn.Font = Enum.Font.GothamBold
			applyBtn.TextColor3 = Color3.new(1,1,1)
			Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0,6)
			local cancelBtn = Instance.new("TextButton", f)
			cancelBtn.Size = UDim2.new(0.5, -15, 0, 34)
			cancelBtn.Position = UDim2.new(0.5,5,1,-44)
			cancelBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
			cancelBtn.Text = "Cancelar"
			cancelBtn.Font = Enum.Font.GothamBold
			cancelBtn.TextColor3 = Color3.new(1,1,1)
			Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,6)
			applyBtn.MouseButton1Click:Connect(function()
				local v = tonumber(box.Text)
				if v and v >= 0 and v <= 1 then
					hitboxTransparency = v
					applyToAllPlayers()
					sg:Destroy()
				else
					box.Text = "Inválido"
				end
			end)
			cancelBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
		end})
	end

	mainTab:Button({Title = "Random Highlight Color", Callback = function()
		highlightColor = Color3.fromHSV(math.random(), 1, 1)
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				local hl = p.Character:FindFirstChild("CustomHighlight")
				if hl then pcall(function() hl.OutlineColor = highlightColor end) end
			end
		end
	end})

	mainTab:Button({Title = "Hitbox Size 15", Callback = function() headSize = 15 applyToAllPlayers() end})
	mainTab:Button({Title = "Hitbox Size 25", Callback = function() headSize = 25 applyToAllPlayers() end})
	mainTab:Button({Title = "Hitbox Size 40", Callback = function() headSize = 40 applyToAllPlayers() end})

	-- Custom size prompt (creates a small PlayerGui prompt)
	mainTab:Button({Title = "Custom Size...", Callback = function()
		local guiName = "PV_CustomSizePrompt"
		local existing = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(guiName)
		if existing then existing:Destroy() end
		local pg = LocalPlayer:WaitForChild("PlayerGui")
		local sg = Instance.new("ScreenGui", pg)
		sg.Name = guiName
		sg.ResetOnSpawn = false
		local f = Instance.new("Frame", sg)
		f.Size = UDim2.new(0, 300, 0, 140)
		f.Position = UDim2.new(0.5, -150, 0.5, -70)
		f.BackgroundColor3 = Color3.fromRGB(30,30,30)
		f.BorderSizePixel = 0
		local uic = Instance.new("UICorner", f)
		uic.CornerRadius = UDim.new(0,8)

		local title = Instance.new("TextLabel", f)
		title.Size = UDim2.new(1, -20, 0, 28)
		title.Position = UDim2.new(0,10,0,8)
		title.BackgroundTransparency = 1
		title.Text = "Tamaño Hitbox personalizado"
		title.TextColor3 = Color3.new(1,1,1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16

		local box = Instance.new("TextBox", f)
		box.Size = UDim2.new(1, -20, 0, 36)
		box.Position = UDim2.new(0,10,0,44)
		box.BackgroundColor3 = Color3.fromRGB(50,50,50)
		box.PlaceholderText = "Ingresa tamaño (ej: 25)"
		box.Text = ""
		box.TextColor3 = Color3.new(1,1,1)
		box.Font = Enum.Font.Gotham
		box.TextSize = 16
		Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)

		local applyBtn = Instance.new("TextButton", f)
		applyBtn.Size = UDim2.new(0.5, -15, 0, 34)
		applyBtn.Position = UDim2.new(0,10,1,-44)
		applyBtn.BackgroundColor3 = Color3.fromRGB(80,170,80)
		applyBtn.Text = "Aplicar"
		applyBtn.Font = Enum.Font.GothamBold
		applyBtn.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0,6)

		local cancelBtn = Instance.new("TextButton", f)
		cancelBtn.Size = UDim2.new(0.5, -15, 0, 34)
		cancelBtn.Position = UDim2.new(0.5,5,1,-44)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
		cancelBtn.Text = "Cancelar"
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,6)

		applyBtn.MouseButton1Click:Connect(function()
			local num = tonumber(box.Text)
			if num and num > 0 then
				headSize = num
				applyToAllPlayers()
				sg:Destroy()
			else
				box.Text = "Inválido"
			end
		end)
		cancelBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
	end})

	-- Simple color picker prompt (R,G,B inputs + preview)
	mainTab:Button({Title = "Color Picker...", Callback = function()
		local guiName = "PV_ColorPicker"
		local existing = LocalPlayer:FindFirstChild("PlayerGui") and LocalPlayer.PlayerGui:FindFirstChild(guiName)
		if existing then existing:Destroy() end
		local pg = LocalPlayer:WaitForChild("PlayerGui")
		local sg = Instance.new("ScreenGui", pg)
		sg.Name = guiName
		sg.ResetOnSpawn = false

		local f = Instance.new("Frame", sg)
		f.Size = UDim2.new(0, 340, 0, 180)
		f.Position = UDim2.new(0.5, -170, 0.5, -90)
		f.BackgroundColor3 = Color3.fromRGB(30,30,30)
		Instance.new("UICorner", f).CornerRadius = UDim.new(0,8)

		local title = Instance.new("TextLabel", f)
		title.Size = UDim2.new(1, -20, 0, 28)
		title.Position = UDim2.new(0,10,0,8)
		title.BackgroundTransparency = 1
		title.Text = "Selector de color (R G B)"
		title.TextColor3 = Color3.new(1,1,1)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16

		local function makeBox(x,y,placeholder)
			local tb = Instance.new("TextBox", f)
			tb.Size = UDim2.new(0,80,0,36)
			tb.Position = UDim2.new(0, x, 0, y)
			tb.BackgroundColor3 = Color3.fromRGB(50,50,50)
			tb.PlaceholderText = placeholder
			tb.Text = ""
			tb.TextColor3 = Color3.new(1,1,1)
			tb.Font = Enum.Font.Gotham
			Instance.new("UICorner", tb).CornerRadius = UDim.new(0,6)
			return tb
		end

		local rBox = makeBox(0.05,44,"R (0-255)")
		local gBox = makeBox(0.32,44,"G (0-255)")
		local bBox = makeBox(0.59,44,"B (0-255)")

		local preview = Instance.new("Frame", f)
		preview.Size = UDim2.new(0,80,0,80)
		preview.Position = UDim2.new(0.8, -10, 0.25, 0)
		preview.BackgroundColor3 = highlightColor
		Instance.new("UICorner", preview).CornerRadius = UDim.new(0,6)

		local applyBtn = Instance.new("TextButton", f)
		applyBtn.Size = UDim2.new(0.5, -15, 0, 36)
		applyBtn.Position = UDim2.new(0,10,1,-44)
		applyBtn.BackgroundColor3 = Color3.fromRGB(80,170,80)
		applyBtn.Text = "Aplicar"
		applyBtn.Font = Enum.Font.GothamBold
		applyBtn.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0,6)

		local cancelBtn = Instance.new("TextButton", f)
		cancelBtn.Size = UDim2.new(0.5, -15, 0, 36)
		cancelBtn.Position = UDim2.new(0.5,5,1,-44)
		cancelBtn.BackgroundColor3 = Color3.fromRGB(200,60,60)
		cancelBtn.Text = "Cancelar"
		cancelBtn.Font = Enum.Font.GothamBold
		cancelBtn.TextColor3 = Color3.new(1,1,1)
		Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0,6)

		local function updatePreview()
			local r = tonumber(rBox.Text) or 0
			local g = tonumber(gBox.Text) or 0
			local b = tonumber(bBox.Text) or 0
			r = math.clamp(r,0,255)/255
			g = math.clamp(g,0,255)/255
			b = math.clamp(b,0,255)/255
			preview.BackgroundColor3 = Color3.new(r,g,b)
		end

		rBox.Changed:Connect(updatePreview)
		gBox.Changed:Connect(updatePreview)
		bBox.Changed:Connect(updatePreview)

		applyBtn.MouseButton1Click:Connect(function()
			local r = tonumber(rBox.Text)
			local g = tonumber(gBox.Text)
			local b = tonumber(bBox.Text)
			if r and g and b then
				r = math.clamp(r,0,255)/255
				g = math.clamp(g,0,255)/255
				b = math.clamp(b,0,255)/255
				highlightColor = Color3.new(r,g,b)
				for _, p in ipairs(Players:GetPlayers()) do
					if p.Character then
						local hl = p.Character:FindFirstChild("CustomHighlight")
						if hl then pcall(function() hl.OutlineColor = highlightColor end) end
					end
				end
				sg:Destroy()
			else
				warn("Valores de color inválidos")
			end
		end)

		cancelBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
	end})

	mainTab:Button({Title = "Rejoin", Callback = function()
		pcall(function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end)
	end})

	-- Small status area using WindUI if available
	if window and window.Footer and typeof(window.Footer) == "Instance" then
		pcall(function()
			local status = Instance.new("TextLabel", window.Footer)
			status.Size = UDim2.new(1,0,1,0)
			status.BackgroundTransparency = 1
			status.TextColor3 = Color3.new(1,1,1)
			status.Font = Enum.Font.Gotham
			status.TextSize = 14
			RunService.RenderStepped:Connect(function(dt)
				local fps = (dt > 0) and math.floor(1/dt) or 0
				local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
				status.Text = "FPS: "..fps.." | Ping: "..ping.."ms"
			end)
		end)
	else
		RunService.RenderStepped:Connect(function(dt)
			-- fallback: nothing visual, keep logic for potential future use
		end)
	end
else
	-- WindUI no disponible: fallback simple toggles via Chat commands
	warn("WindUI no cargado, la UI no estará disponible. Usa la consola para cambiar estados.")
end

-- Aplicar estado inicial a los jugadores ya conectados
applyToAllPlayers()
