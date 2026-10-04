local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- 1. Создание главного ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "RickSystemUI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

-- Настройки плавной интерполяции (60 FPS без рывков)
local TWEEN_NORMAL = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local TWEEN_FAST = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- 2. Плавающий круглый значок (адаптирован под палец на телефоне)
local circleButton = Instance.new("ImageButton")
circleButton.Name = "OpenCircleBtn"
circleButton.Size = UDim2.new(0, 0, 0, 0) -- Для анимации появления при запуске
circleButton.Position = UDim2.new(0.05, 0, 0.45, 0)
circleButton.BackgroundColor3 = Color3.fromRGB(24, 28, 36)
circleButton.BorderSizePixel = 0
circleButton.AutoButtonColor = false
circleButton.Parent = screenGui

local circleCorner = Instance.new("UICorner")
circleCorner.CornerRadius = UDim.new(1, 0)
circleCorner.Parent = circleButton

local circleStroke = Instance.new("UIStroke")
circleStroke.Thickness = 3
circleStroke.Color = Color3.fromRGB(46, 204, 113)
circleStroke.Parent = circleButton

local circleIcon = Instance.new("TextLabel")
circleIcon.Size = UDim2.new(1, 0, 1, 0)
circleIcon.BackgroundTransparency = 1
circleIcon.Text = "🌀"
circleIcon.TextSize = 26
circleIcon.Parent = circleButton

-- Плавное появление кружка на экране
TweenService:Create(circleButton, TWEEN_NORMAL, {
	Size = UDim2.new(0, 60, 0, 60)
}):Play()

-- 3. Меню для мобильных и ПК экранов
local menuFrame = Instance.new("Frame")
menuFrame.Name = "MainMenuFrame"
menuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
menuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
menuFrame.Size = UDim2.new(0, 0, 0, 0)
menuFrame.BackgroundColor3 = Color3.fromRGB(18, 22, 28)
menuFrame.BorderSizePixel = 0
menuFrame.ClipsDescendants = true
menuFrame.Visible = false
menuFrame.Parent = screenGui

local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 18)
menuCorner.Parent = menuFrame

local menuStroke = Instance.new("UIStroke")
menuStroke.Thickness = 2
menuStroke.Color = Color3.fromRGB(46, 204, 113)
menuStroke.Parent = menuFrame

-- Заголовок меню
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 0, 50)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "МЕНЮ РИКА"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 19
titleLabel.Parent = menuFrame

-- Кнопка получения портала
local portalBtn = Instance.new("TextButton")
portalBtn.Name = "GetPortalBtn"
portalBtn.AnchorPoint = Vector2.new(0.5, 0)
portalBtn.Position = UDim2.new(0.5, 0, 0.35, 0)
portalBtn.Size = UDim2.new(0.85, 0, 0, 48)
portalBtn.BackgroundColor3 = Color3.fromRGB(39, 174, 96)
portalBtn.Text = "⚡ Портал Рика"
portalBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
portalBtn.Font = Enum.Font.GothamBold
portalBtn.TextSize = 16
portalBtn.BorderSizePixel = 0
portalBtn.AutoButtonColor = false
portalBtn.Parent = menuFrame

local portalBtnCorner = Instance.new("UICorner")
portalBtnCorner.CornerRadius = UDim.new(0, 12)
portalBtnCorner.Parent = portalBtn

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseBtn"
closeBtn.AnchorPoint = Vector2.new(0.5, 0)
closeBtn.Position = UDim2.new(0.5, 0, 0.68, 0)
closeBtn.Size = UDim2.new(0.85, 0, 0, 40)
closeBtn.BackgroundColor3 = Color3.fromRGB(192, 57, 43)
closeBtn.Text = "Закрыть"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.BorderSizePixel = 0
closeBtn.AutoButtonColor = false
closeBtn.Parent = menuFrame

local closeBtnCorner = Instance.new("UICorner")
closeBtnCorner.CornerRadius = UDim.new(0, 10)
closeBtnCorner.Parent = closeBtn

-- 4. Функция сборки предмета "Портал Рика" прямо в рюкзак
local function givePortalToBackpack()
	local backpack = player:FindFirstChildOfClass("Backpack")
	local character = player.Character

	if not backpack then return end
	if backpack:FindFirstChild("Портал Рика") or (character and character:FindFirstChild("Портал Рика")) then
		return
	end

	local tool = Instance.new("Tool")
	tool.Name = "Портал Рика"
	tool.RequiresHandle = true

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(1, 1, 0.3)
	handle.BrickColor = BrickColor.new("Lime green")
	handle.Material = Enum.Material.Neon
	handle.Shape = Enum.PartType.Cylinder
	handle.Orientation = Vector3.new(0, 0, 90)
	handle.Parent = tool

	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(Color3.fromRGB(50, 255, 100), Color3.fromRGB(200, 255, 0))
	particles.Size = NumberSequence.new(0.5, 0)
	particles.Rate = 35
	particles.Speed = NumberRange.new(2, 4)
	particles.Parent = handle

	-- Активация: создает физический зеленый портал перед персонажем
	tool.Activated:Connect(function()
		local char = tool.Parent
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if root then
			local gate = Instance.new("Part")
			gate.Name = "RickPortalGate"
			gate.Size = Vector3.new(0.2, 8, 6)
			gate.Shape = Enum.PartType.Cylinder
			gate.Orientation = Vector3.new(0, 0, 90)
			gate.CFrame = root.CFrame * CFrame.new(0, 1.5, -6)
			gate.Anchored = true
			gate.CanCollide = false
			gate.Material = Enum.Material.Neon
			gate.Color = Color3.fromRGB(46, 255, 113)
			gate.Parent = workspace

			-- Эффект частиц самого вихря
			local swirl = Instance.new("ParticleEmitter")
			swirl.Color = ColorSequence.new(Color3.fromRGB(0, 255, 100), Color3.fromRGB(180, 255, 50))
			swirl.Size = NumberSequence.new(1.5, 0.2)
			swirl.Rate = 50
			swirl.Speed = NumberRange.new(1, 3)
			swirl.Parent = gate

			Debris:AddItem(gate, 8) -- Портал закроется через 8 секунд
		end
	end)

	tool.Parent = backpack
end

-- 5. Анимации открытия, закрытия и нажатий
local isMenuOpen = false
local MENU_SIZE = UDim2.new(0.72, 0, 0.38, 0) -- Удобная пропорция для экрана телефона

local function toggleMenu()
	isMenuOpen = not isMenuOpen

	if isMenuOpen then
		menuFrame.Visible = true
		menuFrame.Size = UDim2.new(0, 0, 0, 0)
		TweenService:Create(menuFrame, TWEEN_NORMAL, {Size = MENU_SIZE}):Play()
		TweenService:Create(circleButton, TWEEN_FAST, {Size = UDim2.new(0, 50, 0, 50)}):Play()
	else
		local closeTween = TweenService:Create(menuFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
		closeTween:Play()
		closeTween.Completed:Connect(function()
			if not isMenuOpen then
				menuFrame.Visible = false
			end
		end)
		TweenService:Create(circleButton, TWEEN_FAST, {Size = UDim2.new(0, 60, 0, 60)}):Play()
	end
end

circleButton.Activated:Connect(toggleMenu)
closeBtn.Activated:Connect(toggleMenu)

portalBtn.Activated:Connect(function()
	-- Анимация тактильного нажатия кнопки
	TweenService:Create(portalBtn, TWEEN_FAST, {Size = UDim2.new(0.8, 0, 0, 44)}):Play()
	task.wait(0.12)
	TweenService:Create(portalBtn, TWEEN_FAST, {Size = UDim2.new(0.85, 0, 0, 48)}):Play()

	givePortalToBackpack()
	toggleMenu()
end)
