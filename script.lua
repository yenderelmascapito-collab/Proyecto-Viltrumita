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

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local isAdmin = false
local isGoku = false
local minimized = false
local keyValue = ""

local KeyWindow = Rayfield:CreateWindow({
	Name = "PV Hub - Key Required",
	ConfigurationSaving = {Enabled = false}
})

local KeyTab = KeyWindow:CreateTab("Enter Key")

local keyInput = KeyTab:CreateInput({
	Name = "Key",
	PlaceholderText = "Enter your key",
	Callback = function(v)
		keyValue = v
	end
})

local submitButton = KeyTab:CreateButton({
	Name = "Submit",
	Callback = function()
		if keyValue == "admin123" then
			isAdmin = true
			KeyWindow:Destroy()
			createMainUI()
		elseif keyValue == "goku" then
			isGoku = true
			KeyWindow:Destroy()
			createMainUI()
		else
			print("Invalid key")
		end
	end
})

local function createMainUI()
	local Window = Rayfield:CreateWindow({
		Name="PV Hub NEXT",
		ConfigurationSaving={Enabled=true,FileName="PVHub"}
	})

	local Main = Window:CreateTab("Main", 4483362458)
	local ESP = Window:CreateTab("ESP/Aiming", 4483362458)
	local Movement
	if isAdmin then
		Movement = Window:CreateTab("Movement", 4483362458)
	end
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

	if isAdmin then
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
	end

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
	if isAdmin then
		Explicacion:CreateLabel("🏃 MOVEMENT TAB:")
		Explicacion:CreateLabel("• Bunny Jump: Activa/desactiva con ESPACIO o presiona E")
		Explicacion:CreateLabel("• Bunny Jump Legit: Versión con fallos aleatorios para parecer más real")
		Explicacion:CreateLabel("• Emote Jump: Salto vertical con impulso, sin cancelar animaciones/emotes")
		Explicacion:CreateLabel("")
	end
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

	applyEffects()
	Rayfield:LoadConfiguration()

	local UIToggleGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
	UIToggleGui.ResetOnSpawn = false
	local UIToggleButton = Instance.new("TextButton", UIToggleGui)
	UIToggleButton.Size = UDim2.new(0,100,0,50)
	UIToggleButton.Position = UDim2.new(0.9,0,0.1,0)
	UIToggleButton.Text = "Toggle UI"
	UIToggleButton.BackgroundColor3 = Color3.fromRGB(50,50,50)
	UIToggleButton.TextColor3 = Color3.fromRGB(255,255,255)
	UIToggleButton.MouseButton1Click:Connect(function()
		minimized = not minimized
		if minimized then
			Window:Minimize()
		else
			Window.Minimized = false
		end
	end)

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

	if isAdmin then
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
	end

	UserInputService.InputBegan:Connect(function(input,gp)
		if gp then return end
		if input.KeyCode == Enum.KeyCode.K then
			minimized = not minimized
			if minimized then
				Window:Minimize()
			else
				Window.Minimized = false
			end
			if soundEnabled then
				hideMenuSound:Stop()
				hideMenuSound:Play()
			end
		end
	end)
end

