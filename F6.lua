-- [[ BLADE BALL: COMBAT CORE & MODERN UI ]]
-- Поместите данный скрипт в StarterGui или StarterPlayerScripts

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ==================== НАСТРОЙКИ И СОСТОЯНИЕ ====================
local Settings = {
    AutoParry = false,
    ParryDistance = 25,         -- Базовая дистанция срабатывания (в studs)
    DynamicParry = true,        -- Учет скорости полета шара (Time-to-Impact)
    PredictionFactor = 0.55,    -- Коэффициент упреждения пинга/скорости
    BallNames = { "Ball", "BladeBall", "GameBall", "ArenaBall", "TargetBall" },
    Cooldown = 0.4,             -- Задержка между парированиями
}

local State = {
    LastParryTime = 0,
    ActiveBall = nil,
    IsMenuOpen = false,
    CurrentTab = "Main"
}

-- Событие парирования для связи с вашей серверной боевкой
local ParryEvent = ReplicatedStorage:FindFirstChild("ParryEvent")
if not ParryEvent then
    ParryEvent = Instance.new("RemoteEvent")
    ParryEvent.Name = "ParryEvent"
    ParryEvent.Parent = ReplicatedStorage
end

-- ==================== СОЗДАНИЕ ИНТЕРФЕЙСА ====================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BladeBallInterface"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local Theme = {
    Bg = Color3.fromRGB(16, 17, 23),
    Sidebar = Color3.fromRGB(12, 13, 18),
    Card = Color3.fromRGB(24, 26, 35),
    Accent = Color3.fromRGB(255, 60, 95),       -- Неоновый красно-малиновый
    AccentGlow = Color3.fromRGB(255, 110, 140),
    Text = Color3.fromRGB(240, 243, 246),
    SubText = Color3.fromRGB(130, 136, 150),
    Green = Color3.fromRGB(60, 230, 130),
    Border = Color3.fromRGB(35, 38, 50)
}

-- Плавающая кнопка вызова
local OpenBtn = Instance.new("TextButton")
OpenBtn.Size = UDim2.new(0, 52, 0, 52)
OpenBtn.Position = UDim2.new(0.04, 0, 0.45, 0)
OpenBtn.BackgroundColor3 = Theme.Bg
OpenBtn.Text = "⚔️"
OpenBtn.TextSize = 22
OpenBtn.AutoButtonColor = false
OpenBtn.Active = true
OpenBtn.Parent = ScreenGui

local obCorner = Instance.new("UICorner"); obCorner.CornerRadius = UDim.new(1, 0); obCorner.Parent = OpenBtn
local obStroke = Instance.new("UIStroke"); obStroke.Color = Theme.Accent; obStroke.Thickness = 2; obStroke.Parent = OpenBtn

-- Главное окно
local MainFrame = Instance.new("CanvasGroup")
MainFrame.Size = UDim2.new(0, 380, 0, 270)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
MainFrame.BackgroundColor3 = Theme.Bg
MainFrame.GroupTransparency = 1
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local mfCorner = Instance.new("UICorner"); mfCorner.CornerRadius = UDim.new(0, 16); mfCorner.Parent = MainFrame
local mfStroke = Instance.new("UIStroke"); mfStroke.Color = Theme.Border; mfStroke.Thickness = 1.5; mfStroke.Parent = MainFrame

-- Шапка
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 42)
Header.BackgroundColor3 = Theme.Sidebar
Header.BorderSizePixel = 0
Header.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -60, 1, 0)
Title.Position = UDim2.new(0, 16, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLADE // <font color='rgb(255,60,95)'>ASSIST & METRICS</font>"
Title.RichText = true
Title.TextColor3 = Theme.Text
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 28, 0, 28)
CloseBtn.Position = UDim2.new(1, -36, 0.5, -14)
CloseBtn.BackgroundColor3 = Theme.Card
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Theme.SubText
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 11
CloseBtn.AutoButtonColor = false
CloseBtn.Parent = Header
local cbCorner = Instance.new("UICorner"); cbCorner.CornerRadius = UDim.new(0, 8); cbCorner.Parent = CloseBtn

-- Навигация (Табы)
local NavFrame = Instance.new("Frame")
NavFrame.Size = UDim2.new(0, 100, 1, -42)
NavFrame.Position = UDim2.new(0, 0, 0, 42)
NavFrame.BackgroundColor3 = Theme.Sidebar
NavFrame.BorderSizePixel = 0
NavFrame.Parent = MainFrame

local NavLayout = Instance.new("UIListLayout")
NavLayout.Padding = UDim.new(0, 4)
NavLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
NavLayout.Parent = NavFrame

local NavPad = Instance.new("UIPadding")
NavPad.PaddingTop = UDim.new(0, 8)
NavPad.Parent = NavFrame

-- Контейнер контента
local Viewport = Instance.new("Frame")
Viewport.Size = UDim2.new(1, -108, 1, -50)
Viewport.Position = UDim2.new(0, 104, 0, 46)
Viewport.BackgroundTransparency = 1
Viewport.Parent = MainFrame

-- ==================== МЕНЕДЖЕР СТРАНИЦ ====================
local Tabs = {}
local function createTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 88, 0, 30)
    btn.BackgroundColor3 = Theme.Card
    btn.BackgroundTransparency = 1
    btn.Text = icon .. " " .. name
    btn.TextColor3 = Theme.SubText
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = NavFrame
    local bCorn = Instance.new("UICorner"); bCorn.CornerRadius = UDim.new(0, 8); bCorn.Parent = btn

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = Theme.Accent
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.Parent = Viewport

    local pLayout = Instance.new("UIListLayout")
    pLayout.Padding = UDim.new(0, 6)
    pLayout.SortOrder = Enum.SortOrder.LayoutOrder
    pLayout.Parent = page

    local pPad = Instance.new("UIPadding")
    pPad.PaddingRight = UDim.new(0, 4)
    pPad.Parent = page

    local tabData = { Button = btn, Page = page }
    Tabs[name] = tabData

    btn.Activated:Connect(function()
        for _, t in pairs(Tabs) do
            t.Button.BackgroundTransparency = 1
            t.Button.TextColor3 = Theme.SubText
            t.Page.Visible = false
        end
        btn.BackgroundTransparency = 0
        btn.TextColor3 = Theme.Text
        page.Visible = true
    end)

    return page
end

local mainPage = createTab("Бой", "⚔️")
local logPage = createTab("Логи", "📜")

-- ==================== СИСТЕМА ЛОГОВ ====================
local function appendLog(text, color)
    local logCard = Instance.new("Frame")
    logCard.Size = UDim2.new(1, 0, 0, 24)
    logCard.BackgroundColor3 = Theme.Card
    logCard.BorderSizePixel = 0
    logCard.Parent = logPage
    local lcCorn = Instance.new("UICorner"); lcCorn.CornerRadius = UDim.new(0, 6); lcCorn.Parent = logCard

    local timePrefix = os.date("%H:%M:%S")
    local logTxt = Instance.new("TextLabel")
    logTxt.Size = UDim2.new(1, -12, 1, 0)
    logTxt.Position = UDim2.new(0, 6, 0, 0)
    logTxt.BackgroundTransparency = 1
    logTxt.Text = string.format("[%s] %s", timePrefix, text)
    logTxt.TextColor3 = color or Theme.Text
    logTxt.Font = Enum.Font.RobotoMono
    logTxt.TextSize = 10
    logTxt.TextXAlignment = Enum.TextXAlignment.Left
    logTxt.Parent = logCard

    -- Ограничение истории (максимум 25 записей)
    local items = logPage:GetChildren()
    if #items > 27 then
        for i = 1, #items - 27 do
            if items[i]:IsA("Frame") then items[i]:Destroy() end
        end
    end
end

-- ==================== СТРОИТЕЛИ ВИДЖЕТОВ ====================
local function addToggle(parent, title, default, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = Theme.Card
    frame.Parent = parent
    local fCorn = Instance.new("UICorner"); fCorn.CornerRadius = UDim.new(0, 8); fCorn.Parent = frame

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -55, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Theme.Text
    label.Font = Enum.Font.Gotham
    label.TextSize = 11
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 20)
    btn.Position = UDim2.new(1, -48, 0.5, -10)
    btn.BackgroundColor3 = default and Theme.Accent or Color3.fromRGB(36, 40, 52)
    btn.Text = ""
    btn.Parent = frame
    local bCorn = Instance.new("UICorner"); bCorn.CornerRadius = UDim.new(1, 0); bCorn.Parent = btn

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = default and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.Parent = btn
    local kCorn = Instance.new("UICorner"); kCorn.CornerRadius = UDim.new(1, 0); kCorn.Parent = knob

    local state = default
    btn.Activated:Connect(function()
        state = not state
        TweenService:Create(btn, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Theme.Accent or Color3.fromRGB(36, 40, 52)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7)
        }):Play()
        callback(state)
    end)
end

local function addSlider(parent, text, minV, maxV, defV, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 46)
    f.BackgroundColor3 = Theme.Card
    f.Parent = parent
    local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 8); fc.Parent = f

    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1, -50, 0, 16)
    lb.Position = UDim2.new(0, 10, 0, 4)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = Theme.Text
    lb.Font = Enum.Font.Gotham
    lb.TextSize = 11
    lb.TextXAlignment = Enum.TextXAlignment.Left
    lb.Parent = f

    local vl = Instance.new("TextLabel")
    vl.Size = UDim2.new(0, 40, 0, 16)
    vl.Position = UDim2.new(1, -46, 0, 4)
    vl.BackgroundTransparency = 1
    vl.Text = tostring(defV)
    vl.TextColor3 = Theme.Accent
    vl.Font = Enum.Font.GothamBold
    vl.TextSize = 10
    vl.TextXAlignment = Enum.TextXAlignment.Right
    vl.Parent = f

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, -20, 0, 5)
    bar.Position = UDim2.new(0, 10, 1, -12)
    bar.BackgroundColor3 = Color3.fromRGB(38, 42, 54)
    bar.Parent = f
    local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(1, 0); bc.Parent = bar

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defV - minV) / (maxV - minV), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.Parent = bar
    local flc = Instance.new("UICorner"); flc.CornerRadius = UDim.new(1, 0); flc.Parent = fill

    local dragBtn = Instance.new("TextButton")
    dragBtn.Size = UDim2.new(1, 0, 1, 0)
    dragBtn.BackgroundTransparency = 1
    dragBtn.Text = ""
    dragBtn.Parent = f

    local isDown = false
    local function update(inputX)
        local rel = math.clamp((inputX - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(minV + (maxV - minV) * rel)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        vl.Text = tostring(val)
        callback(val)
    end

    dragBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            isDown = true
            update(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if isDown and (inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            update(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            isDown = false
        end
    end)
end

-- ==================== ЗАПОЛНЕНИЕ ВКЛАДКИ «БОЙ» ====================
addToggle(mainPage, "Авто-отбивание (Auto Parry)", Settings.AutoParry, function(val)
    Settings.AutoParry = val
    appendLog("Auto-Parry: " .. (val and "АКТИВИРОВАН" or "ОТКЛЮЧЕН"), val and Theme.Green or Theme.SubText)
end)

addToggle(mainPage, "Динамический расчет (TTI)", Settings.DynamicParry, function(val)
    Settings.DynamicParry = val
end)

addSlider(mainPage, "Дистанция отбивания", 15, 60, Settings.ParryDistance, function(val)
    Settings.ParryDistance = val
end)

-- ==================== АНИМАЦИЯ ОТКРЫТИЯ/ЗАКРЫТИЯ ====================
local function toggleMenu(open)
    if State.IsMenuOpen == open then return end
    State.IsMenuOpen = open

    if open then
        MainFrame.Visible = true
        MainFrame.Position = UDim2.new(0.5, 0, 0.52, 0)
        TweenService:Create(MainFrame, TweenInfo.new(0.32, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
            Position = UDim2.new(0.5, 0, 0.5, 0),
            GroupTransparency = 0
        }):Play()
        TweenService:Create(OpenBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Accent
        }):Play()
    else
        local tween = TweenService:Create(MainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5, 0, 0.48, 0),
            GroupTransparency = 1
        })
        tween:Play()
        TweenService:Create(OpenBtn, TweenInfo.new(0.2), {
            BackgroundColor3 = Theme.Bg
        }):Play()
        tween.Completed:Connect(function()
            if not State.IsMenuOpen then
                MainFrame.Visible = false
            end
        end)
    end
end

-- Мобильный Drag & Tap для кнопки ⚔️
local dragging, dragStart, startPos, movedFar = false, nil, nil, false
OpenBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        movedFar = false
        dragStart = input.Position
        startPos = OpenBtn.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        if delta.Magnitude > 12 then movedFar = true end
        OpenBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if dragging and not movedFar then
            toggleMenu(not State.IsMenuOpen)
        end
        dragging = false
    end
end)

CloseBtn.Activated:Connect(function() toggleMenu(false) end)

-- Открытие вкладки по умолчанию
Tabs["Бой"].Button.BackgroundTransparency = 0
Tabs["Бой"].Button.TextColor3 = Theme.Text
Tabs["Бой"].Page.Visible = true

-- ==================== МЕХАНИКА ПОИСКА МЯЧА ====================
local function findActiveBall()
    for _, name in ipairs(Settings.BallNames) do
        local obj = Workspace:FindFirstChild(name, true)
        if obj and obj:IsA("BasePart") then
            return obj
        end
    end
    -- Поиск по коллекциям/атрибутам, если мяч помечен тегом
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:GetAttribute("IsBall") == true or child:FindFirstChild("BallEffect") then
            if child:IsA("BasePart") then return child end
            if child:FindFirstChildWhichIsA("BasePart") then return child:FindFirstChildWhichIsA("BasePart") end
        end
    end
    return nil
end

-- ==================== ЛОГИКА АВТОМАТИЧЕСКОГО ПАРИРОВАНИЯ ====================
local function triggerParry(ballInstance, distance, speed)
    local now = tick()
    if now - State.LastParryTime < Settings.Cooldown then return end
    State.LastParryTime = now

    -- 1. Вызов RemoteEvent для регистрации удара на сервере
    ParryEvent:FireServer(ballInstance)

    -- 2. Запись в лог интерфейса
    appendLog(string.format("Отбито! Дистанция: %.1f | Скорость: %.1f", distance, speed), Theme.AccentGlow)

    -- 3. Легкая анимация кнопки меню при отбивании
    TweenService:Create(OpenBtn, TweenInfo.new(0.08, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 60, 0, 60)
    }):Play()
    task.delay(0.08, function()
        TweenService:Create(OpenBtn, TweenInfo.new(0.12), {
            Size = UDim2.new(0, 52, 0, 52)
        }):Play()
    end)
end

RunService.Heartbeat:Connect(function()
    if not Settings.AutoParry then return end

    local character = LocalPlayer.Character
    if not character then return end
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    -- Поиск мяча
    local ball = findActiveBall()
    if not ball then return end

    local playerPos = rootPart.Position
    local ballPos = ball.Position
    local distance = (ballPos - playerPos).Magnitude
    local ballVelocity = ball.AssemblyLinearVelocity

    -- Проверка: летит ли шар в сторону игрока
    local toPlayer = (playerPos - ballPos).Unit
    local velocityDir = ballVelocity.Unit
    local isApproaching = toPlayer:Dot(velocityDir) > 0.45 -- Угол сближения

    if isApproaching then
        local speed = ballVelocity.Magnitude
        local shouldParry = false

        if Settings.DynamicParry and speed > 10 then
            -- Расчет времени до контакта (Time-to-Impact)
            local timeToImpact = distance / speed
            if timeToImpact <= (Settings.PredictionFactor + (Settings.ParryDistance / 100)) then
                shouldParry = true
            end
        else
            if distance <= Settings.ParryDistance then
                shouldParry = true
            end
        end

        if shouldParry then
            triggerParry(ball, distance, speed)
        end
    end
end)
