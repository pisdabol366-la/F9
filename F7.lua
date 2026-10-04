--[[
    PORTAL GUN MOBILE UI
    ONE SCRIPT / MOBILE OPTIMIZED

    Куда вставить:
    StarterPlayer > StarterPlayerScripts > LocalScript

    Управление:
    • Нажми круглый значок -> открыть/закрыть меню
    • "ВЫДАТЬ ПУШКУ" -> Portal Gun появляется в Backpack
    • ЛКМ мыши / Tool.Activated -> зелёный портал
    • На телефоне появляются две большие кнопки:
        GREEN = зелёный портал
        ORANGE = оранжевый портал

    Всё создаётся этим одним скриптом.
    Система рассчитана на лёгкую работу на телефоне.
    90 FPS нельзя гарантировать самим Lua-кодом: FPS зависит от устройства,
    графики Roblox и нагрузки игры. Здесь VFX ограничены для мобильной оптимизации.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =========================================================
-- CONFIG
-- =========================================================

local CFG = {
    UI = {
        Accent = Color3.fromRGB(100, 255, 95),
        Accent2 = Color3.fromRGB(45, 190, 55),
        Orange = Color3.fromRGB(255, 135, 45),
        Background = Color3.fromRGB(9, 10, 12),
        Panel = Color3.fromRGB(15, 16, 19),
        Panel2 = Color3.fromRGB(22, 24, 28),
        Text = Color3.fromRGB(242, 244, 247),
        SubText = Color3.fromRGB(145, 150, 158),
        Stroke = Color3.fromRGB(45, 48, 54),
    },

    Portal = {
        RadiusX = 3.6,
        RadiusY = 4.9,
        Segments = 32,       -- deliberately lower for mobile
        Particles = 24,      -- deliberately lower for mobile
        MaxDistance = 120,
    },

    Animation = {
        Fast = 0.16,
        Medium = 0.25,
        Slow = 0.38,
    }
}

-- =========================================================
-- HELPERS
-- =========================================================

local function tween(object, time, props, style, direction)
    local info = TweenInfo.new(
        time,
        style or Enum.EasingStyle.Quint,
        direction or Enum.EasingDirection.Out
    )
    local t = TweenService:Create(object, info, props)
    t:Play()
    return t
end

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 12)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function createText(parent, text, size, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = CFG.UI.Text
    label.TextSize = size
    label.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent
    return label
end

local function makeSound(parent, soundId, volume, speed)
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = volume or 0.5
    s.PlaybackSpeed = speed or 1
    s.RollOffMaxDistance = 80
    s.RollOffMinDistance = 5
    s.Parent = parent
    return s
end

-- =========================================================
-- CLEAN OLD VERSION
-- =========================================================

local oldGui = playerGui:FindFirstChild("PortalGunMobileUI")
if oldGui then
    oldGui:Destroy()
end

local oldTool = player.Backpack:FindFirstChild("Portal Gun")
if oldTool then
    oldTool:Destroy()
end

if player.Character then
    local equippedOld = player.Character:FindFirstChild("Portal Gun")
    if equippedOld then
        equippedOld:Destroy()
    end
end

local portalFolderName = "PortalGun_" .. player.UserId

local oldFolder = workspace:FindFirstChild(portalFolderName)
if oldFolder then
    oldFolder:Destroy()
end

local portalFolder = Instance.new("Folder")
portalFolder.Name = portalFolderName
portalFolder.Parent = workspace

-- =========================================================
-- GUI
-- =========================================================

local gui = Instance.new("ScreenGui")
gui.Name = "PortalGunMobileUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

-- Floating launcher
local launcher = Instance.new("TextButton")
launcher.Name = "Launcher"
launcher.Size = UDim2.fromOffset(62, 62)
launcher.Position = UDim2.new(1, -82, 1, -135)
launcher.BackgroundColor3 = CFG.UI.Panel
launcher.Text = ""
launcher.AutoButtonColor = false
launcher.Parent = gui
corner(launcher, 31)

local launcherStroke = stroke(launcher, CFG.UI.Accent, 2, 0.12)

local launcherGradient = Instance.new("UIGradient")
launcherGradient.Rotation = 45
launcherGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(30,34,37)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,10,11))
}
launcherGradient.Parent = launcher

local portalIcon = Instance.new("Frame")
portalIcon.Size = UDim2.fromOffset(31, 39)
portalIcon.Position = UDim2.fromScale(0.5, 0.5)
portalIcon.AnchorPoint = Vector2.new(0.5,0.5)
portalIcon.BackgroundColor3 = CFG.UI.Accent
portalIcon.BackgroundTransparency = 0.08
portalIcon.Parent = launcher
corner(portalIcon, 16)

local iconStroke = stroke(portalIcon, Color3.fromRGB(190,255,170), 1, 0.1)

local iconInner = Instance.new("Frame")
iconInner.Size = UDim2.fromOffset(18, 26)
iconInner.Position = UDim2.fromScale(0.5,0.5)
iconInner.AnchorPoint = Vector2.new(0.5,0.5)
iconInner.BackgroundColor3 = CFG.UI.Background
iconInner.Parent = portalIcon
corner(iconInner, 10)

-- Dark overlay
local overlay = Instance.new("TextButton")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1,1)
overlay.Position = UDim2.fromScale(0,0)
overlay.BackgroundColor3 = Color3.new(0,0,0)
overlay.BackgroundTransparency = 1
overlay.Text = ""
overlay.AutoButtonColor = false
overlay.Visible = false
overlay.ZIndex = 10
overlay.Parent = gui

-- Main panel
local panel = Instance.new("Frame")
panel.Name = "MainMenu"
panel.AnchorPoint = Vector2.new(0.5,0.5)
panel.Position = UDim2.fromScale(0.5,0.54)
panel.Size = UDim2.new(0.86,0,0,330)
panel.BackgroundColor3 = CFG.UI.Panel
panel.BackgroundTransparency = 0.03
panel.Visible = false
panel.ZIndex = 11
panel.Parent = gui
corner(panel, 22)
stroke(panel, CFG.UI.Stroke, 1, 0.1)

local panelGradient = Instance.new("UIGradient")
panelGradient.Rotation = 90
panelGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(22,24,28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,9,11))
}
panelGradient.Parent = panel

local scale = Instance.new("UIScale")
scale.Scale = 0.82
scale.Parent = panel

local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1,-36,0,2)
topLine.Position = UDim2.new(0,18,0,72)
topLine.BackgroundColor3 = CFG.UI.Accent
topLine.BackgroundTransparency = 0.7
topLine.ZIndex = 12
topLine.Parent = panel
corner(topLine, 1)

local title = createText(panel, "PORTAL SYSTEM", 23, true)
title.Position = UDim2.new(0,24,0,20)
title.Size = UDim2.new(1,-80,0,30)
title.ZIndex = 12

local subtitle = createText(panel, "MOBILE CONTROL", 11, false)
subtitle.TextColor3 = CFG.UI.SubText
subtitle.Position = UDim2.new(0,25,0,47)
subtitle.Size = UDim2.new(1,-80,0,18)
subtitle.ZIndex = 12

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(38,38)
close.Position = UDim2.new(1,-54,0,18)
close.BackgroundColor3 = CFG.UI.Panel2
close.Text = "×"
close.TextColor3 = CFG.UI.Text
close.TextSize = 25
close.Font = Enum.Font.Gotham
close.AutoButtonColor = false
close.ZIndex = 12
close.Parent = panel
corner(close,19)

local gunCard = Instance.new("Frame")
gunCard.Size = UDim2.new(1,-36,0,105)
gunCard.Position = UDim2.new(0,18,0,88)
gunCard.BackgroundColor3 = CFG.UI.Panel2
gunCard.ZIndex = 12
gunCard.Parent = panel
corner(gunCard,16)
stroke(gunCard, CFG.UI.Stroke, 1, 0.2)

local gunCircle = Instance.new("Frame")
gunCircle.Size = UDim2.fromOffset(68,68)
gunCircle.Position = UDim2.new(0,18,0.5,0)
gunCircle.AnchorPoint = Vector2.new(0,0.5)
gunCircle.BackgroundColor3 = Color3.fromRGB(11,18,12)
gunCircle.ZIndex = 13
gunCircle.Parent = gunCard
corner(gunCircle,34)
stroke(gunCircle, CFG.UI.Accent, 1, 0.35)

local gunEmoji = createText(gunCircle, "✦", 30, true)
gunEmoji.Size = UDim2.fromScale(1,1)
gunEmoji.TextXAlignment = Enum.TextXAlignment.Center
gunEmoji.TextColor3 = CFG.UI.Accent
gunEmoji.ZIndex = 14

local gunName = createText(gunCard, "PORTAL GUN", 17, true)
gunName.Position = UDim2.new(0,101,0,18)
gunName.Size = UDim2.new(1,-235,0,24)
gunName.ZIndex = 13

local gunInfo = createText(gunCard, "Green / Orange portals", 11, false)
gunInfo.TextColor3 = CFG.UI.SubText
gunInfo.Position = UDim2.new(0,101,0,45)
gunInfo.Size = UDim2.new(1,-235,0,18)
gunInfo.ZIndex = 13

local giveButton = Instance.new("TextButton")
giveButton.Size = UDim2.fromOffset(108,46)
giveButton.Position = UDim2.new(1,-124,0.5,0)
giveButton.AnchorPoint = Vector2.new(0,0.5)
giveButton.BackgroundColor3 = CFG.UI.Accent
giveButton.Text = "ВЫДАТЬ"
giveButton.TextColor3 = Color3.fromRGB(8,12,8)
giveButton.TextSize = 13
giveButton.Font = Enum.Font.GothamBold
giveButton.AutoButtonColor = false
giveButton.ZIndex = 13
giveButton.Parent = gunCard
corner(giveButton,13)

local status = createText(panel, "●  ГОТОВО К ЗАПУСКУ", 11, true)
status.Position = UDim2.new(0,22,0,211)
status.Size = UDim2.new(1,-44,0,22)
status.TextColor3 = CFG.UI.Accent
status.ZIndex = 12

local controls = createText(panel, "После выдачи: используй две кнопки портала на экране.", 11, false)
controls.Position = UDim2.new(0,22,0,235)
controls.Size = UDim2.new(1,-44,0,32)
controls.TextWrapped = true
controls.TextColor3 = CFG.UI.SubText
controls.ZIndex = 12

local footer = createText(panel, "OPTIMIZED FOR TOUCH • LOW VFX LOAD", 9, false)
footer.Position = UDim2.new(0,22,1,-30)
footer.Size = UDim2.new(1,-44,0,18)
footer.TextColor3 = Color3.fromRGB(90,95,102)
footer.ZIndex = 12

-- =========================================================
-- MOBILE PORTAL BUTTONS
-- =========================================================

local portalButtons = Instance.new("Frame")
portalButtons.Name = "PortalButtons"
portalButtons.BackgroundTransparency = 1
portalButtons.Size = UDim2.new(1,0,0,80)
portalButtons.Position = UDim2.new(0,0,1,-105)
portalButtons.Visible = false
portalButtons.Parent = gui

local greenButton = Instance.new("TextButton")
greenButton.Size = UDim2.fromOffset(118,58)
greenButton.Position = UDim2.new(0.5,-128,0.5,0)
greenButton.AnchorPoint = Vector2.new(0.5,0.5)
greenButton.BackgroundColor3 = Color3.fromRGB(13,27,15)
greenButton.Text = "●  GREEN"
greenButton.TextColor3 = Color3.fromRGB(155,255,145)
greenButton.TextSize = 15
greenButton.Font = Enum.Font.GothamBold
greenButton.AutoButtonColor = false
greenButton.Parent = portalButtons
corner(greenButton,18)
stroke(greenButton, CFG.UI.Accent, 1, 0.25)

local orangeButton = Instance.new("TextButton")
orangeButton.Size = UDim2.fromOffset(118,58)
orangeButton.Position = UDim2.new(0.5,128,0.5,0)
orangeButton.AnchorPoint = Vector2.new(0.5,0.5)
orangeButton.BackgroundColor3 = Color3.fromRGB(30,20,13)
orangeButton.Text = "●  ORANGE"
orangeButton.TextColor3 = Color3.fromRGB(255,175,90)
orangeButton.TextSize = 15
orangeButton.Font = Enum.Font.GothamBold
orangeButton.AutoButtonColor = false
orangeButton.Parent = portalButtons
corner(orangeButton,18)
stroke(orangeButton, CFG.UI.Orange, 1, 0.25)

-- =========================================================
-- MENU ANIMATION
-- =========================================================

local menuOpen = false

local function openMenu()
    if menuOpen then return end
    menuOpen = true

    overlay.Visible = true
    overlay.BackgroundTransparency = 1
    panel.Visible = true
    scale.Scale = 0.82

    tween(overlay, CFG.Animation.Medium, {BackgroundTransparency = 0.38})
    tween(scale, CFG.Animation.Slow, {Scale = 1}, Enum.EasingStyle.Back)

    tween(launcher, CFG.Animation.Medium, {
        Rotation = 90,
        BackgroundTransparency = 0.08
    })
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false

    tween(overlay, CFG.Animation.Fast, {BackgroundTransparency = 1})
    tween(scale, CFG.Animation.Fast, {Scale = 0.82})

    task.delay(CFG.Animation.Fast, function()
        if not menuOpen then
            overlay.Visible = false
            panel.Visible = false
        end
    end)

    tween(launcher, CFG.Animation.Medium, {Rotation = 0})
end

launcher.Activated:Connect(function()
    if menuOpen then
        closeMenu()
    else
        openMenu()
    end
end)

close.Activated:Connect(closeMenu)
overlay.Activated:Connect(closeMenu)

-- Button press animation
local function buttonPress(button)
    local original = button.Size
    tween(button, 0.07, {
        Size = UDim2.new(
            original.X.Scale, original.X.Offset-5,
            original.Y.Scale, original.Y.Offset-5
        )
    }, Enum.EasingStyle.Quad)

    task.delay(0.07,function()
        if button.Parent then
            tween(button,0.12,{Size=original},Enum.EasingStyle.Back)
        end
    end)
end

-- =========================================================
-- PORTAL GUN
-- =========================================================

local gun
local equipped = false
local gunHandle
local muzzle
local chamber
local chamberLight
local fireSound
local equipSound

local GREEN = CFG.UI.Accent
local ORANGE = CFG.UI.Orange

local function newPart(parent, name, size, color, material)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Massless = true
    p.CastShadow = false
    p.Parent = parent
    return p
end

local function weld(a,b)
    local w = Instance.new("WeldConstraint")
    w.Part0 = a
    w.Part1 = b
    w.Parent = b
end

local function createGun()
    if gun then
        gun:Destroy()
    end

    gun = Instance.new("Tool")
    gun.Name = "Portal Gun"
    gun.ToolTip = "Portal Gun"
    gun.RequiresHandle = true
    gun.CanBeDropped = false
    gun.Grip = CFrame.new(0,-0.2,-0.1)
    gun.Parent = player.Backpack

    gunHandle = newPart(gun,"Handle",Vector3.new(0.8,1.7,0.9),Color3.fromRGB(18,21,23),Enum.Material.Metal)

    local body = newPart(gun,"MainBody",Vector3.new(1.55,1.0,2.15),Color3.fromRGB(205,208,201),Enum.Material.Metal)
    body.CFrame = gunHandle.CFrame * CFrame.new(0,0,-0.6)
    weld(gunHandle,body)

    local top = newPart(gun,"Top",Vector3.new(1.35,0.25,1.6),Color3.fromRGB(230,231,220),Enum.Material.SmoothPlastic)
    top.CFrame = gunHandle.CFrame * CFrame.new(0,0.62,-0.6)
    weld(gunHandle,top)

    local grip = newPart(gun,"Grip",Vector3.new(0.7,2.25,0.75),Color3.fromRGB(23,27,29),Enum.Material.Metal)
    grip.CFrame = gunHandle.CFrame * CFrame.new(0,-1.25,0.15) * CFrame.Angles(math.rad(-10),0,0)
    weld(gunHandle,grip)

    local rear = newPart(gun,"Rear",Vector3.new(1.25,0.85,0.45),Color3.fromRGB(130,135,135),Enum.Material.Metal)
    rear.CFrame = gunHandle.CFrame * CFrame.new(0,0,0.65)
    weld(gunHandle,rear)

    local barrel = newPart(gun,"Barrel",Vector3.new(0.72,0.72,1.5),Color3.fromRGB(45,49,50),Enum.Material.Metal)
    barrel.Shape = Enum.PartType.Cylinder
    barrel.CFrame = gunHandle.CFrame * CFrame.new(0,0,-1.85) * CFrame.Angles(math.rad(90),0,0)
    weld(gunHandle,barrel)

    muzzle = newPart(gun,"Muzzle",Vector3.new(0.58,0.16,0.58),GREEN,Enum.Material.Neon)
    muzzle.Shape = Enum.PartType.Cylinder
    muzzle.CFrame = gunHandle.CFrame * CFrame.new(0,0,-2.58) * CFrame.Angles(math.rad(90),0,0)
    weld(gunHandle,muzzle)

    local button = newPart(gun,"RedButton",Vector3.new(0.38,0.16,0.55),Color3.fromRGB(235,55,35),Enum.Material.Neon)
    button.CFrame = gunHandle.CFrame * CFrame.new(0,0.67,-0.85)
    weld(gunHandle,button)

    chamber = newPart(gun,"EnergyChamber",Vector3.new(0.62,1.0,0.62),GREEN,Enum.Material.Neon)
    chamber.Shape = Enum.PartType.Cylinder
    chamber.Transparency = 0.18
    chamber.CFrame = gunHandle.CFrame * CFrame.new(0,0.92,-0.55)
    weld(gunHandle,chamber)

    chamberLight = Instance.new("PointLight")
    chamberLight.Color = GREEN
    chamberLight.Brightness = 3
    chamberLight.Range = 8
    chamberLight.Shadows = false
    chamberLight.Parent = chamber

    fireSound = makeSound(gunHandle,"rbxassetid://130113322",0.7,0.8)
    equipSound = makeSound(gunHandle,"rbxassetid://282906960",0.45,1)

    gun.Equipped:Connect(function()
        equipped = true
        equipSound:Play()
        portalButtons.Visible = true
        status.Text = "●  ПУШКА АКТИВНА"
        status.TextColor3 = GREEN
    end)

    gun.Unequipped:Connect(function()
        equipped = false
        portalButtons.Visible = false
        status.Text = "●  ПУШКА В ИНВЕНТАРЕ"
        status.TextColor3 = CFG.UI.SubText
    end)

    gun.Activated:Connect(function()
        if equipped then
            firePortal("Green")
        end
    end)

    return gun
end

giveButton.Activated:Connect(function()
    buttonPress(giveButton)

    local existing = player.Backpack:FindFirstChild("Portal Gun")
    if existing then
        status.Text = "●  ПУШКА УЖЕ В ИНВЕНТАРЕ"
        status.TextColor3 = GREEN
        return
    end

    local character = player.Character
    if character and character:FindFirstChild("Portal Gun") then
        status.Text = "●  ПУШКА УЖЕ ЭКИПИРОВАНА"
        status.TextColor3 = GREEN
        return
    end

    createGun()
    status.Text = "●  ПУШКА ВЫДАНА"
    status.TextColor3 = GREEN

    task.delay(0.8,function()
        if menuOpen then
            closeMenu()
        end
    end)
end)

-- =========================================================
-- PORTAL SYSTEM
-- =========================================================

local portals = {
    Green = nil,
    Orange = nil
}

local portalData = {
    Green = nil,
    Orange = nil
}

local function getAimRay()
    local camera = workspace.CurrentCamera
    if not camera then return nil end

    local viewport = camera.ViewportSize
    local center = Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)

    local ray = camera:ViewportPointToRay(center.X,center.Y)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude

    local ignore = {portalFolder}
    if player.Character then
        table.insert(ignore,player.Character)
    end

    params.FilterDescendantsInstances = ignore
    params.IgnoreWater = true

    return workspace:Raycast(ray.Origin,ray.Direction * CFG.Portal.MaxDistance,params)
end

local function portalBasis(normal)
    local up = Vector3.yAxis

    if math.abs(normal:Dot(up)) > 0.92 then
        up = Vector3.zAxis
    end

    local right = normal:Cross(up).Unit
    up = right:Cross(normal).Unit

    return right,up
end

local function removePortal(kind)
    if portals[kind] then
        portals[kind]:Destroy()
        portals[kind] = nil
        portalData[kind] = nil
    end
end

local function createPortal(position,normal,kind)
    removePortal(kind)

    local color = kind == "Green" and GREEN or ORANGE
    local bright = kind == "Green"
        and Color3.fromRGB(180,255,160)
        or Color3.fromRGB(255,220,150)

    local right,up = portalBasis(normal)

    local cf = CFrame.fromMatrix(
        position + normal*0.12,
        right,
        up,
        -normal
    )

    local model = Instance.new("Model")
    model.Name = kind.."Portal"
    model.Parent = portalFolder

    -- dark portal opening
    local opening = Instance.new("Part")
    opening.Name = "Opening"
    opening.Anchored = true
    opening.CanCollide = false
    opening.CanTouch = false
    opening.CanQuery = false
    opening.CastShadow = false
    opening.Material = Enum.Material.SmoothPlastic
    opening.Color = Color3.fromRGB(2,3,3)
    opening.Transparency = 0.08
    opening.Size = Vector3.new(6.7,9.2,0.06)
    opening.CFrame = cf
    opening.Parent = model

    -- neon rim
    local segments = {}
    local count = CFG.Portal.Segments

    for i=1,count do
        local a = (i-1)/count * math.pi*2
        local x = math.cos(a)*CFG.Portal.RadiusX
        local y = math.sin(a)*CFG.Portal.RadiusY

        local dx = -math.sin(a)*CFG.Portal.RadiusY
        local dy = math.cos(a)*CFG.Portal.RadiusX

        local seg = Instance.new("Part")
        seg.Name = "Rim"
        seg.Anchored = true
        seg.CanCollide = false
        seg.CanTouch = false
        seg.CanQuery = false
        seg.CastShadow = false
        seg.Material = Enum.Material.Neon
        seg.Color = i%2 == 0 and color or bright

        local length = math.sqrt(dx*dx+dy*dy) * (2*math.pi/count) * 1.25

        seg.Size = Vector3.new(length,0.28,0.13)
        seg.CFrame =
            cf
            * CFrame.new(x,y,0.05)
            * CFrame.Angles(0,0,math.atan2(dy,dx))

        seg.Parent = model
        segments[i] = seg
    end

    -- center particle field: low rate for phones
    local fxPart = Instance.new("Part")
    fxPart.Name = "FX"
    fxPart.Anchored = true
    fxPart.CanCollide = false
    fxPart.CanTouch = false
    fxPart.CanQuery = false
    fxPart.CastShadow = false
    fxPart.Transparency = 1
    fxPart.Size = Vector3.new(1,1,1)
    fxPart.CFrame = cf
    fxPart.Parent = model

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://1266170131"
    emitter.Color = ColorSequence.new(bright,color)
    emitter.LightEmission = 1
    emitter.Rate = CFG.Portal.Particles
    emitter.Lifetime = NumberRange.new(0.35,0.75)
    emitter.Speed = NumberRange.new(0.8,2.6)
    emitter.SpreadAngle = Vector2.new(360,360)
    emitter.Rotation = NumberRange.new(0,360)
    emitter.RotSpeed = NumberRange.new(-100,100)
    emitter.Size = NumberSequence.new{
        NumberSequenceKeypoint.new(0,0.06),
        NumberSequenceKeypoint.new(0.45,0.16),
        NumberSequenceKeypoint.new(1,0)
    }
    emitter.Parent = fxPart

    local light = Instance.new("PointLight")
    light.Color = color
    light.Brightness = 5
    light.Range = 14
    light.Shadows = false
    light.Parent = fxPart

    -- opening animation
    for _,seg in ipairs(segments) do
        local finalSize = seg.Size
        seg.Size = finalSize * 0.05
        tween(seg,0.28,{Size=finalSize},Enum.EasingStyle.Back)
    end

    opening.Size = Vector3.new(0.1,0.1,0.06)
    tween(opening,0.3,{Size=Vector3.new(6.7,9.2,0.06)},Enum.EasingStyle.Quint)

    portals[kind] = model

    portalData[kind] = {
        cf = cf,
        position = cf.Position,
        normal = normal,
    }

    -- One lightweight animation connection per portal.
    local alive = true
    local angle = 0

    model.Destroying:Connect(function()
        alive = false
    end)

    task.spawn(function()
        while alive and model.Parent do
            local dt = RunService.RenderStepped:Wait()
            angle += dt * 2.4

            for i,seg in ipairs(segments) do
                if seg.Parent then
                    local a = (i-1)/count * math.pi*2 + angle*0.16
                    local x = math.cos(a)*CFG.Portal.RadiusX
                    local y = math.sin(a)*CFG.Portal.RadiusY

                    local dx = -math.sin(a)*CFG.Portal.RadiusY
                    local dy = math.cos(a)*CFG.Portal.RadiusX

                    seg.CFrame =
                        cf
                        * CFrame.new(x,y,0.05)
                        * CFrame.Angles(0,0,math.atan2(dy,dx))
                end
            end

            light.Brightness = 4.5 + math.sin(angle*3)*0.7
        end
    end)
end

local function portalImpact(kind)
    local result = getAimRay()

    if result then
        createPortal(result.Position,result.Normal,kind)
    else
        local camera = workspace.CurrentCamera
        if camera then
            local pos = camera.CFrame.Position + camera.CFrame.LookVector*18
            createPortal(pos,-camera.CFrame.LookVector,kind)
        end
    end

    if fireSound then
        fireSound.PlaybackSpeed = kind == "Green" and 0.78 or 0.92
        fireSound:Play()
    end

    -- muzzle flash
    if muzzle then
        local flash = Instance.new("Part")
        flash.Shape = Enum.PartType.Ball
        flash.Anchored = true
        flash.CanCollide = false
        flash.CanTouch = false
        flash.CanQuery = false
        flash.CastShadow = false
        flash.Material = Enum.Material.Neon
        flash.Color = kind == "Green" and GREEN or ORANGE
        flash.Size = Vector3.new(0.5,0.5,0.5)
        flash.CFrame = muzzle.CFrame
        flash.Parent = workspace

        local light = Instance.new("PointLight")
        light.Color = flash.Color
        light.Brightness = 9
        light.Range = 10
        light.Shadows = false
        light.Parent = flash

        tween(flash,0.16,{
            Size=Vector3.new(3.2,3.2,3.2),
            Transparency=1
        },Enum.EasingStyle.Quad)

        Debris:AddItem(flash,0.2)
    end

    -- tiny recoil
    if gun then
        local oldGrip = gun.Grip
        gun.Grip = oldGrip * CFrame.Angles(math.rad(-5),0,0)

        task.delay(0.08,function()
            if gun and gun.Parent then
                tween(gun,0.12,{Grip=oldGrip},Enum.EasingStyle.Quad)
            end
        end)
    end
end

function firePortal(kind)
    if not equipped then return end
    portalImpact(kind)
end

greenButton.Activated:Connect(function()
    buttonPress(greenButton)
    firePortal("Green")
end)

orangeButton.Activated:Connect(function()
    buttonPress(orangeButton)
    firePortal("Orange")
end)

-- =========================================================
-- PORTAL TELEPORTATION
-- =========================================================

local teleportCooldown = false

local function tryTeleport(fromKind,toKind,root)
    local a = portalData[fromKind]
    local b = portalData[toKind]

    if not a or not b then
        return false
    end

    local localPosition = a.cf:PointToObjectSpace(root.Position)

    local inside =
        math.abs(localPosition.X) <= 3.0
        and math.abs(localPosition.Y) <= 4.45
        and math.abs(localPosition.Z) <= 2.0

    local velocity = root.AssemblyLinearVelocity
    local movingInto = velocity:Dot(a.normal) < -1

    if not inside or not movingInto then
        return false
    end

    teleportCooldown = true

    local localVelocity = a.cf:VectorToObjectSpace(velocity)

    root.CFrame = b.cf * CFrame.new(0,0,-3.0)
    root.AssemblyLinearVelocity = b.cf:VectorToWorldSpace(localVelocity)

    task.delay(0.45,function()
        teleportCooldown = false
    end)

    -- very cheap exit burst
    local burst = Instance.new("Part")
    burst.Anchored = true
    burst.CanCollide = false
    burst.CanTouch = false
    burst.CanQuery = false
    burst.CastShadow = false
    burst.Transparency = 1
    burst.Size = Vector3.new(1,1,1)
    burst.CFrame = b.cf
    burst.Parent = workspace

    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxassetid://1266170131"
    emitter.Color = ColorSequence.new(
        toKind == "Green" and GREEN or ORANGE
    )
    emitter.LightEmission = 1
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(7,12)
    emitter.Lifetime = NumberRange.new(0.18,0.42)
    emitter.SpreadAngle = Vector2.new(180,180)
    emitter.Size = NumberSequence.new(0.12)
    emitter.Parent = burst
    emitter:Emit(22)

    Debris:AddItem(burst,0.8)

    return true
end

RunService.Heartbeat:Connect(function()
    if teleportCooldown then return end

    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    if tryTeleport("Green","Orange",root) then
        return
    end

    tryTeleport("Orange","Green",root)
end)

-- =========================================================
-- PERFORMANCE / MOBILE
-- =========================================================

-- Only update small UI effects continuously.
-- No expensive full-screen effects, no high-rate particle spam.
local pulseTime = 0

RunService.RenderStepped:Connect(function(dt)
    pulseTime += dt

    if launcher and launcher.Parent then
        local pulse = 1 + math.sin(pulseTime*2.5)*0.025
        launcher.Size = UDim2.fromOffset(62*pulse,62*pulse)
    end

    if chamber and chamber.Parent and equipped then
        chamberLight.Brightness = 3 + math.sin(pulseTime*6)*0.8
    end
end)

-- =========================================================
-- RESPAWN SUPPORT
-- =========================================================

player.CharacterAdded:Connect(function()
    task.wait(0.6)

    equipped = false
    portalButtons.Visible = false

    -- Keep the menu launcher alive.
    -- Tool is recreated only if the player no longer has it.
    if not player.Backpack:FindFirstChild("Portal Gun") then
        if not player.Character:FindFirstChild("Portal Gun") then
            -- Do not automatically equip; player can press the menu button.
        end
    end
end)

-- Initial state
portalButtons.Visible = false
status.Text = "●  ГОТОВО К ЗАПУСКУ"
status.TextColor3 = CFG.UI.Accent

print("[Portal System] Mobile one-script system loaded.")
