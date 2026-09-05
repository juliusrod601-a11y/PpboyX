--========================================================
-- PPBOY X
-- MOBILE N64 / ARCADE GUI
--========================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera

local Settings = {
	AimBot = false,
	WallCheck = false,
	ESP = false,
	Marco = false,
	MarcoSpeed = 200,
	NoClip = false,
	AutoJump = false,
	Spin = false,
	SpinSpeed = 10,
	FOV = 90,
	Power = 5,
	FloatSwim = false,
	SwimSpeed = 200,
	CrosshairRainbow = false,
	CrosshairSpin = false,
	Stretch = false,
	Disco = false
}

local Character
local Humanoid
local Root

local function UpdateCharacter()
	Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	Root = Character:WaitForChild("HumanoidRootPart")
end

UpdateCharacter()

local Connections = {}

local function Connect(signal, callback)
	local connection = signal:Connect(callback)
	table.insert(Connections, connection)
	return connection
end

local OldGui = PlayerGui:FindFirstChild("PPBOY_X")
if OldGui then OldGui:Destroy() end

local Gui = Instance.new("ScreenGui")
Gui.Name = "PPBOY_X"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local N64Font = Enum.Font.Arcade

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(225, 370)
Main.Position = UDim2.new(0.5, -112, 0.5, -185)
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 3
MainStroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -45, 0, 36)
Title.Position = UDim2.fromOffset(8, 2)
Title.BackgroundTransparency = 1
Title.Text = "PPBOY X"
Title.TextSize = 21
Title.Font = N64Font
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextStrokeTransparency = 0.5
Title.Parent = Main

local Close = Instance.new("TextButton")
Close.Size = UDim2.fromOffset(31, 28)
Close.Position = UDim2.new(1, -36, 0, 5)
Close.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Close.BorderSizePixel = 0
Close.Text = "X"
Close.TextSize = 16
Close.Font = N64Font
Close.TextColor3 = Color3.new(1, 1, 1)
Close.Parent = Main

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 7)
CloseCorner.Parent = Close

local Scroll = Instance.new("ScrollingFrame")
Scroll.Name = "Scroll"
Scroll.Size = UDim2.new(1, -12, 1, -45)
Scroll.Position = UDim2.fromOffset(6, 41)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel = 0
Scroll.ScrollBarThickness = 4
Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 5)
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.Parent = Scroll

local function CreateButton(text)
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.new(1, -4, 0, 29)
	Button.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
	Button.BorderSizePixel = 0
	Button.Text = text
	Button.TextSize = 12
	Button.Font = N64Font
	Button.TextColor3 = Color3.new(1, 1, 1)
	Button.AutoButtonColor = true
	Button.Parent = Scroll

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 7)
	Corner.Parent = Button

	return Button
end

local function SetState(Button, name, state)
	Button.Text = name .. ": " .. (state and "ON" or "OFF")
end

local AimButton = CreateButton("AIMBOT: OFF")

local function GetTarget()
	local BestTarget = nil
	local BestDistance = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			local char = player.Character
			local head = char and char:FindFirstChild("Head")
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if head and hum and hum.Health > 0 then
				if Settings.WallCheck then
					local Origin = Camera.CFrame.Position
					local Direction = head.Position - Origin
					local Params = RaycastParams.new()
					Params.FilterType = Enum.RaycastFilterType.Exclude
					Params.FilterDescendantsInstances = {Character}

					local Result = workspace:Raycast(Origin, Direction, Params)

					if Result and not Result.Instance:IsDescendantOf(char) then
						continue
					end
				end

				local ScreenPos, Visible = Camera:WorldToViewportPoint(head.Position)

				if Visible then
					local Center = Vector2.new(
						Camera.ViewportSize.X / 2,
						Camera.ViewportSize.Y / 2
					)

					local Distance = (
						Vector2.new(ScreenPos.X, ScreenPos.Y) - Center
					).Magnitude

					if Distance < BestDistance then
						BestDistance = Distance
						BestTarget = head
					end
				end
			end
		end
	end

	return BestTarget
end

Connect(AimButton.MouseButton1Click, function()
	Settings.AimBot = not Settings.AimBot
	SetState(AimButton, "AIMBOT", Settings.AimBot)
end)

local WallButton = CreateButton("WALL CHECK: OFF")

Connect(WallButton.MouseButton1Click, function()
	Settings.WallCheck = not Settings.WallCheck
	SetState(WallButton, "WALL CHECK", Settings.WallCheck)
end)

local ESPButton = CreateButton("ESP: OFF")
local ESPObjects = {}

local function AddESP(player)
	if player == LocalPlayer then return end

	local char = player.Character
	if not char then return end

	if ESPObjects[player] then
		ESPObjects[player]:Destroy()
	end

	local Highlight = Instance.new("Highlight")
	Highlight.Name = "PPBOY_ESP"
	Highlight.FillTransparency = 0.7
	Highlight.OutlineTransparency = 0
	Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	Highlight.Parent = char

	ESPObjects[player] = Highlight
end

local function RemoveESP(player)
	if ESPObjects[player] then
		ESPObjects[player]:Destroy()
		ESPObjects[player] = nil
	end
end

local function RefreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if Settings.ESP then
				AddESP(player)
			else
				RemoveESP(player)
			end
		end
	end
end

Connect(ESPButton.MouseButton1Click, function()
	Settings.ESP = not Settings.ESP
	SetState(ESPButton, "ESP", Settings.ESP)
	RefreshESP()
end)

Connect(Players.PlayerAdded, function(player)
	Connect(player.CharacterAdded, function()
		task.wait(0.3)
		if Settings.ESP then
			AddESP(player)
		end
	end)
end)

Connect(Players.PlayerRemoving, function(player)
	RemoveESP(player)
end)

local MarcoButton = CreateButton("MARCO: OFF")

Connect(MarcoButton.MouseButton1Click, function()
	Settings.Marco = not Settings.Marco
	SetState(MarcoButton, "MARCO", Settings.Marco)

	if Humanoid then
		if Settings.Marco then
			Humanoid.WalkSpeed = Settings.MarcoSpeed
		else
			Humanoid.WalkSpeed = 16
		end
	end
end)

local MarcoSpeedButton = CreateButton("MARCO SPEED: 200")

Connect(MarcoSpeedButton.MouseButton1Click, function()
	Settings.MarcoSpeed += 25

	if Settings.MarcoSpeed > 1000 then
		Settings.MarcoSpeed = 25
	end

	MarcoSpeedButton.Text = "MARCO SPEED: " .. Settings.MarcoSpeed

	if Settings.Marco and Humanoid then
		Humanoid.WalkSpeed = Settings.MarcoSpeed
	end
end)

local NoClipButton = CreateButton("NOCLIP: OFF")

Connect(NoClipButton.MouseButton1Click, function()
	Settings.NoClip = not Settings.NoClip
	SetState(NoClipButton, "NOCLIP", Settings.NoClip)
end)

local AutoJumpButton = CreateButton("AUTO JUMP: OFF")

Connect(AutoJumpButton.MouseButton1Click, function()
	Settings.AutoJump = not Settings.AutoJump
	SetState(AutoJumpButton, "AUTO JUMP", Settings.AutoJump)
end)

local SpinButton = CreateButton("SPIN: OFF")

Connect(SpinButton.MouseButton1Click, function()
	Settings.Spin = not Settings.Spin
	SetState(SpinButton, "SPIN", Settings.Spin)
end)

local SpinSpeedButton = CreateButton("SPIN SPEED: 10")

Connect(SpinSpeedButton.MouseButton1Click, function()
	Settings.SpinSpeed += 5

	if Settings.SpinSpeed > 100 then
		Settings.SpinSpeed = 5
	end

	SpinSpeedButton.Text = "SPIN SPEED: " .. Settings.SpinSpeed
end)

local FOVButton = CreateButton("FOV: 90")

Connect(FOVButton.MouseButton1Click, function()
	Settings.FOV += 10

	if Settings.FOV > 120 then
		Settings.FOV = 30
	end

	FOVButton.Text = "FOV: " .. Settings.FOV
	Camera.FieldOfView = Settings.FOV
end)

local PowerButton = CreateButton("POWER: 5")

Connect(PowerButton.MouseButton1Click, function()
	Settings.Power += 1

	if Settings.Power > 20 then
		Settings.Power = 1
	end

	PowerButton.Text = "POWER: " .. Settings.Power
end)

local FloatButton = CreateButton("FLOAT + SWIM: OFF")

Connect(FloatButton.MouseButton1Click, function()
	Settings.FloatSwim = not Settings.FloatSwim
	SetState(FloatButton, "FLOAT + SWIM", Settings.FloatSwim)
end)

local SwimSpeedButton = CreateButton("SWIM SPEED: 200")

Connect(SwimSpeedButton.MouseButton1Click, function()
	Settings.SwimSpeed += 50

	if Settings.SwimSpeed > 1000 then
		Settings.SwimSpeed = 50
	end

	SwimSpeedButton.Text = "SWIM SPEED: " .. Settings.SwimSpeed
end)

local CrosshairBox = Instance.new("TextBox")
CrosshairBox.Size = UDim2.new(1, -4, 0, 29)
CrosshairBox.BackgroundColor3 = Color3.fromRGB(35, 35, 44)
CrosshairBox.BorderSizePixel = 0
CrosshairBox.PlaceholderText = "CROSSHAIR ID"
CrosshairBox.Text = ""
CrosshairBox.TextSize = 12
CrosshairBox.Font = N64Font
CrosshairBox.TextColor3 = Color3.new(1, 1, 1)
CrosshairBox.ClearTextOnFocus = false
CrosshairBox.Parent = Scroll

local CrossCorner = Instance.new("UICorner")
CrossCorner.CornerRadius = UDim.new(0, 7)
CrossCorner.Parent = CrosshairBox

local Crosshair = Instance.new("ImageLabel")
Crosshair.Name = "PPBOY_Crosshair"
Crosshair.Size = UDim2.fromOffset(35, 35)
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
Crosshair.BackgroundTransparency = 1
Crosshair.Visible = false
Crosshair.Parent = Gui

CrosshairBox.FocusLost:Connect(function()
	local ID = tonumber(CrosshairBox.Text)

	if ID then
		Crosshair.Image = "rbxassetid://" .. ID
		Crosshair.Visible = true
	end
end)

local RainbowCrossButton = CreateButton("RAINBOW CROSSHAIR: OFF")

Connect(RainbowCrossButton.MouseButton1Click, function()
	Settings.CrosshairRainbow = not Settings.CrosshairRainbow
	SetState(RainbowCrossButton, "RAINBOW CROSSHAIR", Settings.CrosshairRainbow)
end)

local SpinCrossButton = CreateButton("SPINNING CROSSHAIR: OFF")

Connect(SpinCrossButton.MouseButton1Click, function()
	Settings.CrosshairSpin = not Settings.CrosshairSpin
	SetState(SpinCrossButton, "SPINNING CROSSHAIR", Settings.CrosshairSpin)
end)

local StretchButton = CreateButton("STRETCHY SCREEN: OFF")

Connect(StretchButton.MouseButton1Click, function()
	Settings.Stretch = true
	StretchButton.Text = "STRETCHY SCREEN: ON"
	Camera.FieldOfView = math.clamp(Settings.FOV + 15, 30, 120)
end)

local UnstretchButton = CreateButton("UNSTRETCH")

Connect(UnstretchButton.MouseButton1Click, function()
	Settings.Stretch = false
	Camera.FieldOfView = Settings.FOV
	StretchButton.Text = "STRETCHY SCREEN: OFF"
end)

local TeleportButton = CreateButton("GET TELEPORT TOOL")
local TeleportTool
local Mouse = LocalPlayer:GetMouse()

local function CreateTeleportTool()
	if TeleportTool and TeleportTool.Parent then return end

	TeleportTool = Instance.new("Tool")
	TeleportTool.Name = "Portal Teleporter"
	TeleportTool.ToolTip = "Click to teleport"
	TeleportTool.RequiresHandle = true
	TeleportTool.CanBeDropped = false

	local Handle = Instance.new("Part")
	Handle.Name = "Handle"
	Handle.Size = Vector3.new(0.45, 0.8, 0.22)
	Handle.Material = Enum.Material.Neon
	Handle.Color = Color3.fromRGB(80, 255, 255)
	Handle.CanCollide = false
	Handle.Massless = true
	Handle.Parent = TeleportTool

	local Mesh = Instance.new("SpecialMesh")
	Mesh.MeshType = Enum.MeshType.Sphere
	Mesh.Scale = Vector3.new(0.8, 1.4, 0.35)
	Mesh.Parent = Handle

	local Ring = Instance.new("Part")
	Ring.Name = "PortalRing"
	Ring.Shape = Enum.PartType.Cylinder
	Ring.Size = Vector3.new(0.06, 0.65, 0.65)
	Ring.Material = Enum.Material.Neon
	Ring.Color = Color3.fromRGB(0, 255, 255)
	Ring.CanCollide = false
	Ring.Massless = true
	Ring.Parent = TeleportTool

	local Weld = Instance.new("WeldConstraint")
	Weld.Part0 = Handle
	Weld.Part1 = Ring
	Weld.Parent = Ring

	Ring.CFrame = Handle.CFrame * CFrame.new(0, 0, -0.13) * CFrame.Angles(0, math.rad(90), 0)

	local Sound = Instance.new("Sound")
	Sound.Name = "TeleportSound"
	Sound.SoundId = "rbxassetid://8789851536"
	Sound.Volume = 0.7
	Sound.Parent = Handle

	TeleportTool.Activated:Connect(function()
		if not Root then return end

		local Hit = Mouse.Hit
		if not Hit then return end

		Sound:Play()

		Root.CFrame = CFrame.new(Hit.Position + Vector3.new(0, 3, 0))
	end)

	TeleportTool.Parent = LocalPlayer:WaitForChild("Backpack")
end

Connect(TeleportButton.MouseButton1Click, function()
	CreateTeleportTool()
	TeleportButton.Text = "TELEPORT TOOL: READY"
end)

local DiscoButton = CreateButton("DISCO: OFF")

local DiscoSound = Instance.new("Sound")
DiscoSound.Name = "PPBOY_Disco"
DiscoSound.SoundId = "rbxassetid://142376088"
DiscoSound.Volume = 0.7
DiscoSound.Looped = true
DiscoSound.Parent = SoundService

local DiscoEffect
local OriginalBrightness = Lighting.Brightness
local OriginalAmbient = Lighting.Ambient
local OriginalOutdoorAmbient = Lighting.OutdoorAmbient

local function StartDisco()
	if DiscoEffect then DiscoEffect:Destroy() end

	DiscoEffect = Instance.new("ColorCorrectionEffect")
	DiscoEffect.Name = "PPBOY_RainbowFlash"
	DiscoEffect.Contrast = 0.2
	DiscoEffect.Saturation = 0.8
	DiscoEffect.Parent = Lighting

	DiscoSound:Play()
end

local function StopDisco()
	DiscoSound:Stop()

	if DiscoEffect then
		DiscoEffect:Destroy()
		DiscoEffect = nil
	end

	Lighting.Brightness = OriginalBrightness
	Lighting.Ambient = OriginalAmbient
	Lighting.OutdoorAmbient = OriginalOutdoorAmbient
end

Connect(DiscoButton.MouseButton1Click, function()
	Settings.Disco = not Settings.Disco
	SetState(DiscoButton, "DISCO", Settings.Disco)

	if Settings.Disco then
		StartDisco()
	else
		StopDisco()
	end
end)

local RejoinButton = CreateButton("REJOIN")

Connect(RejoinButton.MouseButton1Click, function()
	TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

local DeleteButton = CreateButton("DELETE GUI")

Connect(DeleteButton.MouseButton1Click, function()
	for _, connection in ipairs(Connections) do
		if connection and connection.Connected then
			connection:Disconnect()
		end
	end

	if TeleportTool then TeleportTool:Destroy() end
	if DiscoSound then DiscoSound:Stop(); DiscoSound:Destroy() end
	if DiscoEffect then DiscoEffect:Destroy() end

	for _, Highlight in pairs(ESPObjects) do
		if Highlight then Highlight:Destroy() end
	end

	if Gui then Gui:Destroy() end
end)

local Tab = Instance.new("TextButton")
Tab.Name = "PPBOY_X_TAB"
Tab.Size = UDim2.fromOffset(95, 32)
Tab.Position = UDim2.new(0, 10, 0.5, 0)
Tab.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
Tab.BorderSizePixel = 0
Tab.Text = "PPBOY X"
Tab.TextSize = 13
Tab.Font = N64Font
Tab.TextColor3 = Color3.new(1, 1, 1)
Tab.Visible = false
Tab.Parent = Gui

local TabCorner = Instance.new("UICorner")
TabCorner.CornerRadius = UDim.new(0, 8)
TabCorner.Parent = Tab

local TabStroke = Instance.new("UIStroke")
TabStroke.Thickness = 2
TabStroke.Parent = Tab

Connect(Close.MouseButton1Click, function()
	Main.Visible = false
	Tab.Visible = true
end)

Connect(Tab.MouseButton1Click, function()
	Main.Visible = true
	Tab.Visible = false
end)

local function MakeDraggable(Frame)
	local Dragging = false
	local DragStart
	local StartPosition

	local function Update(Input)
		local Delta = Input.Position - DragStart

		Frame.Position = UDim2.new(
			StartPosition.X.Scale,
			StartPosition.X.Offset + Delta.X,
			StartPosition.Y.Scale,
			StartPosition.Y.Offset + Delta.Y
		)
	end

	Connect(Frame.InputBegan, function(Input)
		if Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch then

			Dragging = true
			DragStart = Input.Position
			StartPosition = Frame.Position

			Input.Changed:Connect(function()
				if Input.UserInputState == Enum.UserInputState.End then
					Dragging = false
				end
			end)
		end
	end)

	Connect(UIS.InputChanged, function(Input)
		if not Dragging then return end

		if Input.UserInputType == Enum.UserInputType.MouseMovement
			or Input.UserInputType == Enum.UserInputType.Touch then

			Update(Input)
		end
	end)
end

MakeDraggable(Main)
MakeDraggable(Tab)

Connect(RunService.RenderStepped, function()
	if not Character or not Humanoid or not Root then return end

	if Settings.AimBot then
		local Target = GetTarget()

		if Target then
			Camera.CFrame = CFrame.lookAt(
				Camera.CFrame.Position,
				Target.Position
			)
		end
	end

	if Settings.Marco then
		Humanoid.WalkSpeed = Settings.MarcoSpeed
	end

	if Settings.NoClip then
		for _, Part in ipairs(Character:GetDescendants()) do
			if Part:IsA("BasePart") then
				Part.CanCollide = false
			end
		end
	end

	if Settings.AutoJump then
		if Humanoid.FloorMaterial ~= Enum.Material.Air then
			Humanoid.Jump = true
		end
	end

	if Settings.FloatSwim then
		local Move = Humanoid.MoveDirection

		Root.AssemblyLinearVelocity = Vector3.new(
			Move.X * Settings.SwimSpeed,
			Root.AssemblyLinearVelocity.Y,
			Move.Z * Settings.SwimSpeed
		)
	end

	if Settings.Spin then
		Root.CFrame = Root.CFrame * CFrame.Angles(
			0,
			math.rad(Settings.SpinSpeed),
			0
		)
	end

	if Settings.CrosshairRainbow then
		Crosshair.ImageColor3 = Color3.fromHSV(
			(os.clock() * 0.5) % 1,
			1,
			1
		)
	end

	if Settings.CrosshairSpin then
		Crosshair.Rotation = (os.clock() * 250) % 360
	end

	if Settings.Disco then
		local Hue = (os.clock() * 1.8) % 1
		local Rainbow = Color3.fromHSV(Hue, 1, 1)

		local Flash = math.abs(math.sin(os.clock() * 7))

		Lighting.Ambient = Rainbow
		Lighting.OutdoorAmbient = Rainbow
		Lighting.Brightness = OriginalBrightness + Flash * 3

		if DiscoEffect then
			DiscoEffect.TintColor = Rainbow
			DiscoEffect.Brightness = Flash * 0.35
			DiscoEffect.Contrast = 0.2 + Flash * 0.4
		end
	end
end)

Connect(RunService.RenderStepped, function()
	local Hue = (os.clock() * 0.15) % 1
	local Rainbow = Color3.fromHSV(Hue, 1, 1)

	MainStroke.Color = Rainbow
	TabStroke.Color = Rainbow
end)

Connect(LocalPlayer.CharacterAdded, function()
	task.wait(0.25)
	UpdateCharacter()

	if Settings.Marco and Humanoid then
		Humanoid.WalkSpeed = Settings.MarcoSpeed
	end
end)

Camera.FieldOfView = Settings.FOV

print("PPBOY X N64 GUI loaded successfully!")
