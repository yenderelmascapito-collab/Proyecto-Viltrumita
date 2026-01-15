--// CONFIGURACIÓN BASE
local CONFIG = {
    highlightColor = Color3.fromRGB(100, 0, 244),
    headSize = 25,
    highlightEnabled = true,
    hitboxEnabled = true,
    showHitbox = false,
    hitboxTransparency = 1.0
}

--// SERVICIOS
local SERVICES = {
    Players = game:GetService("Players"),
    LocalPlayer = game:GetService("Players").LocalPlayer,
    RunService = game:GetService("RunService"),
    TeleportService = game:GetService("TeleportService"),
    TweenService = game:GetService("TweenService"),
    Lighting = game:GetService("Lighting")
}

--// VARIABLES GLOBALES
local originalRootSizes = {} -- Para restaurar tamaños originales

--// UTILIDADES PARA HITBOX
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
        saveOriginalRootSize(character)
        pcall(function()
            root.Size = Vector3.new(CONFIG.headSize, CONFIG.headSize, CONFIG.headSize)
            root.Transparency = (CONFIG.showHitbox and CONFIG.hitboxTransparency or 1)
            root.CanCollide = false
        end)
    end
end

local function removeHitbox(character)
    if not character then return end
    restoreOriginalRootSize(character)
end

-----------------------------------------------------------

-----------------------------------------------------------
--// FUNCIÓN PRINCIPAL: APLICAR HIGHLIGHT + HITBOX
-----------------------------------------------------------
local function applyHighlightAndHitbox(character)
    if not character then return end

    -- HITBOX
    if CONFIG.hitboxEnabled then
        applyHitbox(character)
    else
        removeHitbox(character)
    end

    -- HIGHLIGHT
    local existing = character:FindFirstChild("CustomHighlight")
    if CONFIG.highlightEnabled then
        if not existing then
            local highlight = Instance.new("Highlight")
            highlight.Name = "CustomHighlight"
            highlight.FillTransparency = 1
            highlight.OutlineColor = CONFIG.highlightColor
            highlight.OutlineTransparency = 0
            highlight.Adornee = character
            highlight.Parent = character
        else
            pcall(function()
                existing.OutlineColor = CONFIG.highlightColor
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
    for _, p in ipairs(SERVICES.Players:GetPlayers()) do
        if p ~= SERVICES.LocalPlayer and p.Character then
            applyHighlightAndHitbox(p.Character)
        end
    end
end

-----------------------------------------------------------
--// MANEJO DE JUGADORES / RESTAURAR AL SALIR
local function onPlayerAdded(player)
    if player == SERVICES.LocalPlayer then return end

    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        applyHighlightAndHitbox(char)
    end)

    if player.Character then
        applyHighlightAndHitbox(player.Character)
    end
end

for _, p in ipairs(SERVICES.Players:GetPlayers()) do
    onPlayerAdded(p)
end
SERVICES.Players.PlayerAdded:Connect(onPlayerAdded)

SERVICES.Players.PlayerRemoving:Connect(function(player)
    if player and player.Character then
        restoreOriginalRootSize(player.Character)
    end
end)

-----------------------------------------------------------
local function onPlayerAdded(player)
    if player == SERVICES.LocalPlayer then return end

    player.CharacterAdded:Connect(function(char)
        char:WaitForChild("HumanoidRootPart", 5)
        applyHighlightAndHitbox(char)
    end)

    if player.Character then
        applyHighlightAndHitbox(player.Character)
    end
end

for _, p in ipairs(SERVICES.Players:GetPlayers()) do
    onPlayerAdded(p)
end
SERVICES.Players.PlayerAdded:Connect(onPlayerAdded)

SERVICES.Players.PlayerRemoving:Connect(function(player)
    if player and player.Character then
        restoreOriginalRootSize(player.Character)
    end
end)

-----------------------------------------------------------
--// UI PROFESIONAL
local function createCustomSwitch(parent, title, initialState, callback)
    local switchFrame = Instance.new("Frame", parent)
    switchFrame.Size = UDim2.new(1, -20, 0, 50)
    switchFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", switchFrame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.TextXAlignment = Enum.TextXAlignment.Left

    local switchBg = Instance.new("Frame", switchFrame)
    switchBg.Size = UDim2.new(0, 50, 0, 28)
    switchBg.Position = UDim2.new(1, -50, 0.5, -14)
    switchBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    switchBg.BorderSizePixel = 0
    Instance.new("UICorner", switchBg).CornerRadius = UDim.new(1, 0)

    local switchKnob = Instance.new("Frame", switchBg)
    switchKnob.Size = UDim2.new(0, 22, 0, 22)
    switchKnob.Position = UDim2.new(0, 3, 0.5, -11)
    switchKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", switchKnob).CornerRadius = UDim.new(1, 0)

    local state = initialState
    local function updateSwitch()
        SERVICES.TweenService:Create(switchBg, TweenInfo.new(0.2), {BackgroundColor3 = state and Color3.fromRGB(100, 0, 244) or Color3.fromRGB(50, 50, 50)}):Play()
        SERVICES.TweenService:Create(switchKnob, TweenInfo.new(0.2), {Position = state and UDim2.new(1, -25, 0.5, -11) or UDim2.new(0, 3, 0.5, -11)}):Play()
        callback(state)
    end
    updateSwitch()

    switchBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            updateSwitch()
        end
    end)

    return switchFrame
end

local function createCustomSlider(parent, title, min, max, default, callback)
    local sliderFrame = Instance.new("Frame", parent)
    sliderFrame.Size = UDim2.new(1, -20, 0, 70)
    sliderFrame.BackgroundTransparency = 1

    local label = Instance.new("TextLabel", sliderFrame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title .. ": " .. string.format("%.2f", default)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 14
    label.TextXAlignment = Enum.TextXAlignment.Left

    local sliderBg = Instance.new("Frame", sliderFrame)
    sliderBg.Size = UDim2.new(1, 0, 0, 8)
    sliderBg.Position = UDim2.new(0, 0, 0, 25)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(100, 0, 244)
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

    local sliderKnob = Instance.new("Frame", sliderFrame)
    sliderKnob.Size = UDim2.new(0, 20, 0, 20)
    sliderKnob.Position = UDim2.new(0, -10, 0, 21)
    sliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

    local value = default
    local dragging = false

    local function updateSlider()
        local percent = (value - min) / (max - min)
        sliderFill.Size = UDim2.new(percent, 0, 1, 0)
        sliderKnob.Position = UDim2.new(percent, -10, 0, 21)
        label.Text = title .. ": " .. string.format("%.2f", value)
        callback(value)
    end
    updateSlider()

    sliderKnob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)

    SERVICES.RunService.RenderStepped:Connect(function()
        if dragging then
            local mouse = SERVICES.Players.LocalPlayer:GetMouse()
            local relativeX = mouse.X - sliderBg.AbsolutePosition.X
            local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
            value = min + (max - min) * percent
            updateSlider()
        end
    end)

    game:GetService("UserInputService").InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return sliderFrame
end

local ok, WindUI = pcall(function()
    return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)

if ok and WindUI and type(WindUI.CreateWindow) == "function" then
    local window = WindUI:CreateWindow({
        Title = "PV HUB v2.0",
        Subtitle = "Profesional Edition",
        Icon = "🌟",
        Theme = "Dark",
        ToggleKey = Enum.KeyCode.Z
    })

    -- Aplicar estilo glassmorphism
    pcall(function()
        if window.Main then
            window.Main.BackgroundTransparency = 0.2
            local blur = Instance.new("BlurEffect", SERVICES.Lighting)
            blur.Size = 10
            blur.Name = "PV_Blur"
        end
    end)

    local mainTab = window:Tab({Title = "Main"})

    -- Switches para toggles
    createCustomSwitch(mainTab, "Highlight", CONFIG.highlightEnabled, function(state)
        CONFIG.highlightEnabled = state
        applyToAllPlayers()
    end)

    createCustomSwitch(mainTab, "Hitbox", CONFIG.hitboxEnabled, function(state)
        CONFIG.hitboxEnabled = state
        if not state then
            for _, p in ipairs(SERVICES.Players:GetPlayers()) do
                if p.Character then restoreOriginalRootSize(p.Character) end
            end
        end
        applyToAllPlayers()
    end)

    createCustomSwitch(mainTab, "Mostrar Hitbox", CONFIG.showHitbox, function(state)
        CONFIG.showHitbox = state
        applyToAllPlayers()
    end)

    -- Slider para transparencia
    createCustomSlider(mainTab, "Hitbox Transparency", 0, 1, CONFIG.hitboxTransparency, function(v)
        CONFIG.hitboxTransparency = v
        applyToAllPlayers()
    end)

    -- Botones adicionales
    mainTab:Button({Title = "Random Color", Callback = function()
        CONFIG.highlightColor = Color3.fromHSV(math.random(), 1, 1)
        for _, p in ipairs(SERVICES.Players:GetPlayers()) do
            if p.Character then
                local hl = p.Character:FindFirstChild("CustomHighlight")
                if hl then pcall(function() hl.OutlineColor = CONFIG.highlightColor end) end
            end
        end
    end})

    mainTab:Button({Title = "Size 15", Callback = function() CONFIG.headSize = 15 applyToAllPlayers() end})
    mainTab:Button({Title = "Size 25", Callback = function() CONFIG.headSize = 25 applyToAllPlayers() end})
    mainTab:Button({Title = "Size 40", Callback = function() CONFIG.headSize = 40 applyToAllPlayers() end})

    -- Custom size prompt
    mainTab:Button({Title = "Custom Size...", Callback = function()
        local guiName = "PV_CustomSize"
        local existing = SERVICES.LocalPlayer.PlayerGui:FindFirstChild(guiName)
        if existing then existing:Destroy() end
        local sg = Instance.new("ScreenGui", SERVICES.LocalPlayer.PlayerGui)
        sg.Name = guiName
        sg.ResetOnSpawn = false

        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 320, 0, 150)
        f.Position = UDim2.new(0.5, -160, 0.5, -75)
        f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        f.BackgroundTransparency = 0.2
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

        local title = Instance.new("TextLabel", f)
        title.Size = UDim2.new(1, -20, 0, 30)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = "Custom Hitbox Size"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 18

        local box = Instance.new("TextBox", f)
        box.Size = UDim2.new(1, -20, 0, 40)
        box.Position = UDim2.new(0, 10, 0, 50)
        box.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        box.BackgroundTransparency = 0.5
        box.PlaceholderText = "Enter size (e.g. 25)"
        box.Text = ""
        box.TextColor3 = Color3.fromRGB(255, 255, 255)
        box.Font = Enum.Font.Gotham
        box.TextSize = 16
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)

        local applyBtn = Instance.new("TextButton", f)
        applyBtn.Size = UDim2.new(0.45, -5, 0, 35)
        applyBtn.Position = UDim2.new(0.05, 0, 1, -45)
        applyBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 244)
        applyBtn.Text = "Apply"
        applyBtn.Font = Enum.Font.GothamBold
        applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 8)

        local cancelBtn = Instance.new("TextButton", f)
        cancelBtn.Size = UDim2.new(0.45, -5, 0, 35)
        cancelBtn.Position = UDim2.new(0.5, 5, 1, -45)
        cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        cancelBtn.Text = "Cancel"
        cancelBtn.Font = Enum.Font.GothamBold
        cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

        applyBtn.MouseButton1Click:Connect(function()
            local num = tonumber(box.Text)
            if num and num > 0 then
                CONFIG.headSize = num
                applyToAllPlayers()
                sg:Destroy()
            else
                box.Text = "Invalid"
            end
        end)
        cancelBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    end})

    -- Color picker
    mainTab:Button({Title = "Color Picker...", Callback = function()
        local guiName = "PV_ColorPicker"
        local existing = SERVICES.LocalPlayer.PlayerGui:FindFirstChild(guiName)
        if existing then existing:Destroy() end
        local sg = Instance.new("ScreenGui", SERVICES.LocalPlayer.PlayerGui)
        sg.Name = guiName
        sg.ResetOnSpawn = false

        local f = Instance.new("Frame", sg)
        f.Size = UDim2.new(0, 360, 0, 200)
        f.Position = UDim2.new(0.5, -180, 0.5, -100)
        f.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        f.BackgroundTransparency = 0.2
        Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)

        local title = Instance.new("TextLabel", f)
        title.Size = UDim2.new(1, -20, 0, 30)
        title.Position = UDim2.new(0, 10, 0, 10)
        title.BackgroundTransparency = 1
        title.Text = "Color Picker (R G B)"
        title.TextColor3 = Color3.fromRGB(255, 255, 255)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 18

        local function makeBox(x, placeholder)
            local tb = Instance.new("TextBox", f)
            tb.Size = UDim2.new(0, 80, 0, 40)
            tb.Position = UDim2.new(0, x, 0, 50)
            tb.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
            tb.BackgroundTransparency = 0.5
            tb.PlaceholderText = placeholder
            tb.Text = ""
            tb.TextColor3 = Color3.fromRGB(255, 255, 255)
            tb.Font = Enum.Font.Gotham
            tb.TextSize = 16
            Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 8)
            return tb
        end

        local rBox = makeBox(10, "R (0-255)")
        local gBox = makeBox(100, "G (0-255)")
        local bBox = makeBox(190, "B (0-255)")

        local preview = Instance.new("Frame", f)
        preview.Size = UDim2.new(0, 50, 0, 50)
        preview.Position = UDim2.new(0, 280, 0, 50)
        preview.BackgroundColor3 = CONFIG.highlightColor
        Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 8)

        local applyBtn = Instance.new("TextButton", f)
        applyBtn.Size = UDim2.new(0.45, -5, 0, 35)
        applyBtn.Position = UDim2.new(0.05, 0, 1, -45)
        applyBtn.BackgroundColor3 = Color3.fromRGB(100, 0, 244)
        applyBtn.Text = "Apply"
        applyBtn.Font = Enum.Font.GothamBold
        applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", applyBtn).CornerRadius = UDim.new(0, 8)

        local cancelBtn = Instance.new("TextButton", f)
        cancelBtn.Size = UDim2.new(0.45, -5, 0, 35)
        cancelBtn.Position = UDim2.new(0.5, 5, 1, -45)
        cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        cancelBtn.Text = "Cancel"
        cancelBtn.Font = Enum.Font.GothamBold
        cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 8)

        local function updatePreview()
            local r = tonumber(rBox.Text) or 0
            local g = tonumber(gBox.Text) or 0
            local b = tonumber(bBox.Text) or 0
            r = math.clamp(r, 0, 255) / 255
            g = math.clamp(g, 0, 255) / 255
            b = math.clamp(b, 0, 255) / 255
            preview.BackgroundColor3 = Color3.new(r, g, b)
        end

        rBox.Changed:Connect(updatePreview)
        gBox.Changed:Connect(updatePreview)
        bBox.Changed:Connect(updatePreview)

        applyBtn.MouseButton1Click:Connect(function()
            local r = tonumber(rBox.Text)
            local g = tonumber(gBox.Text)
            local b = tonumber(bBox.Text)
            if r and g and b then
                CONFIG.highlightColor = Color3.new(math.clamp(r, 0, 255) / 255, math.clamp(g, 0, 255) / 255, math.clamp(b, 0, 255) / 255)
                for _, p in ipairs(SERVICES.Players:GetPlayers()) do
                    if p.Character then
                        local hl = p.Character:FindFirstChild("CustomHighlight")
                        if hl then pcall(function() hl.OutlineColor = CONFIG.highlightColor end) end
                    end
                end
                sg:Destroy()
            end
        end)
        cancelBtn.MouseButton1Click:Connect(function() sg:Destroy() end)
    end})

    mainTab:Button({Title = "Rejoin", Callback = function()
        pcall(function() SERVICES.TeleportService:Teleport(game.PlaceId, SERVICES.LocalPlayer) end)
    end})

    -- Status en footer
    if window.Footer then
        local status = Instance.new("TextLabel", window.Footer)
        status.Size = UDim2.new(1, 0, 1, 0)
        status.BackgroundTransparency = 1
        status.TextColor3 = Color3.fromRGB(255, 255, 255)
        status.Font = Enum.Font.Gotham
        status.TextSize = 14
        SERVICES.RunService.RenderStepped:Connect(function(dt)
            local fps = dt > 0 and math.floor(1 / dt) or 0
            local ping = math.floor(SERVICES.LocalPlayer:GetNetworkPing() * 1000)
            status.Text = "FPS: " .. fps .. " | Ping: " .. ping .. "ms"
        end)
    end
else
    -- Fallback UI
    warn("WindUI failed to load. Using fallback UI.")
    local fallbackGui = Instance.new("ScreenGui", SERVICES.LocalPlayer.PlayerGui)
    fallbackGui.Name = "PV_Fallback"
    fallbackGui.ResetOnSpawn = false

    local mainFrame = Instance.new("Frame", fallbackGui)
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BackgroundTransparency = 0.2
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, -20, 0, 40)
    title.Position = UDim2.new(0, 10, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "PV HUB (Fallback)"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20

    local yOffset = 60
    local function addButton(text, callback)
        local btn = Instance.new("TextButton", mainFrame)
        btn.Size = UDim2.new(0.9, 0, 0, 40)
        btn.Position = UDim2.new(0.05, 0, 0, yOffset)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.BackgroundTransparency = 0.5
        btn.Text = text
        btn.Font = Enum.Font.GothamBold
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
        btn.MouseButton1Click:Connect(callback)
        yOffset = yOffset + 50
    end

    addButton("Toggle Highlight", function() CONFIG.highlightEnabled = not CONFIG.highlightEnabled applyToAllPlayers() end)
    addButton("Toggle Hitbox", function() CONFIG.hitboxEnabled = not CONFIG.hitboxEnabled applyToAllPlayers() end)
    addButton("Toggle Show Hitbox", function() CONFIG.showHitbox = not CONFIG.showHitbox applyToAllPlayers() end)
    addButton("Random Color", function()
        CONFIG.highlightColor = Color3.fromHSV(math.random(), 1, 1)
        applyToAllPlayers()
    end)
    addButton("Rejoin", function() pcall(function() SERVICES.TeleportService:Teleport(game.PlaceId, SERVICES.LocalPlayer) end) end)
end

-- Aplicar estado inicial
applyToAllPlayers()

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
