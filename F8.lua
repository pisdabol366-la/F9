--═══════════════════════════════════════════════════════════════════════
--  🌀  РИК И МОРТИ НАВСЕГДА  🌀
--  Кружок → плавное передвижное меню → портальная пушка Рика
--
--  УСТАНОВКА: LocalScript → StarterPlayer → StarterPlayerScripts
--═══════════════════════════════════════════════════════════════════════

local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Debris           = game:GetService("Debris")
local Lighting         = game:GetService("Lighting")

local Player    = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Camera    = workspace:WaitForChild("Camera")

--═══════════════ ПАЛИТРА: зелёный + серо-белый ═══════════════
local PAL = {
    Green      = Color3.fromRGB(0, 255, 110),
    GreenSoft  = Color3.fromRGB(0, 200, 90),
    GreenDark  = Color3.fromRGB(0, 135, 65),
    Panel      = Color3.fromRGB(32, 42, 36),   -- фон меню (серо-зелёный)
    PanelLight = Color3.fromRGB(45, 56, 48),   -- фон элементов
    White      = Color3.fromRGB(240, 248, 242),
    Gray       = Color3.fromRGB(150, 168, 157),
}

local SHOOT_COOLDOWN = 0.6 -- задержка между выстрелами (сек)

--═══════════════ ХЕЛПЕРЫ ═══════════════
local function tween(obj, time, props, style, dir)
    local t = TweenService:Create(obj,
        TweenInfo.new(time, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
    t:Play()
    return t
end

local function corner(parent, px)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, px)
    c.Parent = parent
    return c
end

local function newStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Thickness = thickness or 1.5
    s.Parent = parent
    return s
end

local function newGradient(parent, c1, c2, rot)
    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new(c1, c2)
    g.Rotation = rot or 0
    g.Parent = parent
    return g
end

--═══════════════ GUI-КОРЕНЬ ═══════════════
local gui = Instance.new("ScreenGui")
gui.Name = "RickAndMortyForever"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = PlayerGui

--═══════════════ УВЕДОМЛЕНИЯ (тосты) ═══════════════
local toasts = {}
local function notify(title, text)
    local toast = Instance.new("Frame")
    toast.AnchorPoint = Vector2.new(1, 0)
    toast.Size = UDim2.fromOffset(300, 64)
    toast.BackgroundColor3 = PAL.PanelLight
    toast.BorderSizePixel = 0
    toast.Position = UDim2.new(1, 340, 0, 16 + #toasts * 74) -- старт за экраном
    toast.ZIndex = 50
    toast.Parent = gui
    corner(toast, 12)
    local tst = newStroke(toast, PAL.Green, 1.2)
    tst.Transparency = 0.35

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, -16)
    bar.Position = UDim2.new(0, 10, 0, 8)
    bar.BackgroundColor3 = PAL.Green
    bar.BorderSizePixel = 0
    bar.ZIndex = 51
    bar.Parent = toast
    corner(bar, 2)

    local ttl = Instance.new("TextLabel")
    ttl.BackgroundTransparency = 1
    ttl.Position = UDim2.new(0, 26, 0, 9)
    ttl.Size = UDim2.new(1, -40, 0, 20)
    ttl.Font = Enum.Font.GothamBold
    ttl.Text = title
    ttl.TextSize = 14
    ttl.TextColor3 = PAL.Green
    ttl.TextXAlignment = Enum.TextXAlignment.Left
    ttl.ZIndex = 51
    ttl.Parent = toast

    local msg = Instance.new("TextLabel")
    msg.BackgroundTransparency = 1
    msg.Position = UDim2.new(0, 26, 0, 30)
    msg.Size = UDim2.new(1, -40, 0, 26)
    msg.Font = Enum.Font.Gotham
    msg.Text = text
    msg.TextSize = 12
    msg.TextColor3 = PAL.White
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextWrapped = true
    msg.ZIndex = 51
    msg.Parent = toast

    table.insert(toasts, toast)
    tween(toast, 0.45, {Position = UDim2.new(1, -16, 0, 16 + (#toasts - 1) * 74)}, Enum.EasingStyle.Back)

    task.delay(3.2, function()
        local i = table.find(toasts, toast)
        if not i then return end
        table.remove(toasts, i)
        tween(toast, 0.35, {Position = UDim2.new(1, 340, 0, toast.Position.Y.Offset)},
            Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        Debris:AddItem(toast, 0.4)
        for j, t in ipairs(toasts) do -- сдвигаем остальные вверх
            tween(t, 0.35, {Position = UDim2.new(1, -16, 0, 16 + (j - 1) * 74)}, Enum.EasingStyle.Back)
        end
    end)
end

--═══════════════ ДВИЖОК ПЛАВНОГО ПЕРЕМЕЩЕНИЯ ═══════════════
local draggables = {}

local function addDraggable(object, area, startCenter, onClick)
    local state = {object = object, current = startCenter, target = startCenter}
    table.insert(draggables, state)

    local dragging, dragStart, startPos, movedDist = false, nil, nil, 0

    area.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, movedDist = true, 0
            dragStart, startPos = input.Position, state.target
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if onClick and movedDist < 8 then onClick() end -- это был клик, не перетаскивание
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            movedDist = math.abs(delta.X) + math.abs(delta.Y)
            state.target = Vector2.new(startPos.X + delta.X, startPos.Y + delta.Y)
        end
    end)

    return state
end

-- плавное следование за мышью + запрет утащить за экран
RunService.RenderStepped:Connect(function(dt)
    local vp = Camera.ViewportSize
    local alpha = math.clamp(dt * 18, 0, 1)
    for _, st in ipairs(draggables) do
        st.current = st.current:Lerp(st.target, alpha)
        local half = st.object.AbsoluteSize / 2
        st.object.Position = UDim2.fromOffset(
            math.clamp(st.current.X, half.X + 2, vp.X - half.X - 2),
            math.clamp(st.current.Y, half.Y + 2, vp.Y - half.Y - 2))
    end
end)

--═══════════════ КРУЖОК-КНОПКА ═══════════════
local circle = Instance.new("Frame")
circle.Name = "CircleButton"
circle.AnchorPoint = Vector2.new(0.5, 0.5)
circle.Size = UDim2.fromOffset(58, 58)
circle.BackgroundColor3 = PAL.PanelLight
circle.BorderSizePixel = 0
circle.Active = true
circle.ZIndex = 20
circle.Parent = gui
corner(circle, 999)

local circleGrad = newGradient(circle, PAL.Panel, PAL.PanelLight, 45)
local circleStroke = newStroke(circle, PAL.Green, 2)
circleStroke.Transparency = 0.1

local circleIcon = Instance.new("TextLabel")
circleIcon.BackgroundTransparency = 1
circleIcon.Size = UDim2.fromScale(1, 1)
circleIcon.Font = Enum.Font.GothamBold
circleIcon.Text = "🌀"
circleIcon.TextSize = 30
circleIcon.TextColor3 = PAL.White
circleIcon.Active = false
circleIcon.ZIndex = 21
circleIcon.Parent = circle

local circleScale = Instance.new("UIScale")
circleScale.Parent = circle

-- мягкое пульсирующее свечение рамки
TweenService:Create(circleStroke,
    TweenInfo.new(1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Thickness = 3.4, Transparency = 0.6}):Play()

circle.MouseEnter:Connect(function()
    tween(circleScale, 0.2, {Scale = 1.16}, Enum.EasingStyle.Back)
    tween(circleGrad, 0.2, {Brightness = 1.35})
end)
circle.MouseLeave:Connect(function()
    tween(circleScale, 0.28, {Scale = 1})
    tween(circleGrad, 0.28, {Brightness = 1})
end)

--═══════════════ МЕНЮ ═══════════════
local menu = Instance.new("CanvasGroup")
menu.Name = "MainMenu"
menu.AnchorPoint = Vector2.new(0.5, 0.5)
menu.Size = UDim2.fromOffset(340, 300)
menu.BackgroundColor3 = PAL.Panel
menu.BorderSizePixel = 0
menu.GroupTransparency = 1
menu.Visible = false
menu.ZIndex = 10
menu.Parent = gui
corner(menu, 18)

local menuStroke = newStroke(menu, PAL.Green, 1.6)
menuStroke.Transparency = 1

local menuScale = Instance.new("UIScale")
menuScale.Scale = 0
menuScale.Parent = menu

--── шапка (она же зона перетаскивания) ──
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = PAL.GreenDark
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 11
titleBar.Parent = menu
corner(titleBar, 18)

local patch = Instance.new("Frame") -- прячет нижние скругления шапки
patch.Size = UDim2.new(1, 0, 0, 18)
patch.Position = UDim2.new(0, 0, 0, 36)
patch.BackgroundColor3 = PAL.GreenDark
patch.BorderSizePixel = 0
patch.ZIndex = 11
patch.Parent = titleBar

local line = Instance.new("Frame") -- зелёная линия-разделитель
line.Size = UDim2.new(1, 0, 0, 2)
line.Position = UDim2.new(0, 0, 0, 54)
line.BackgroundColor3 = PAL.Green
line.BorderSizePixel = 0
line.ZIndex = 11
line.Parent = menu

local titleText = Instance.new("TextLabel")
titleText.BackgroundTransparency = 1
titleText.Position = UDim2.new(0, 16, 0, 0)
titleText.Size = UDim2.new(1, -64, 1, 0)
titleText.Font = Enum.Font.GothamBold
titleText.Text = "🌀  РИК И МОРТИ НАВСЕГДА"
titleText.TextSize = 15
titleText.TextColor3 = PAL.White
titleText.TextXAlignment = Enum.TextXAlignment.Left
titleText.TextTruncate = Enum.TextTruncate.AtEnd
titleText.Active = false
titleText.ZIndex = 12
titleText.Parent = titleBar
TweenService:Create(titleText, -- лёгкое «дыхание» заголовка
    TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {TextTransparency = 0.25}):Play()

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.fromOffset(34, 34)
closeBtn.Position = UDim2.new(1, -44, 0.5, -17)
closeBtn.BackgroundColor3 = PAL.Green
closeBtn.BackgroundTransparency = 1
closeBtn.AutoButtonColor = false
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Text = "✕"
closeBtn.TextSize = 16
closeBtn.TextColor3 = PAL.White
closeBtn.ZIndex = 12
closeBtn.Parent = titleBar
corner(closeBtn, 999)

closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.15, {BackgroundTransparency = 0.7}) end)
closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.2, {BackgroundTransparency = 1}) end)

--── содержимое меню ──
local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 0, 0, 62)
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "ПОРТАЛЬНАЯ ПАНЕЛЬ"
subtitle.TextSize = 11
subtitle.TextColor3 = PAL.Gray
subtitle.ZIndex = 11
subtitle.Parent = menu

local giveBtn = Instance.new("TextButton")
giveBtn.Size = UDim2.new(1, -32, 0, 54)
giveBtn.Position = UDim2.new(0, 16, 0, 92)
giveBtn.BackgroundColor3 = PAL.GreenDark
giveBtn.BorderSizePixel = 0
giveBtn.AutoButtonColor = false
giveBtn.Font = Enum.Font.GothamBold
giveBtn.Text = "🌀   ВЫДАТЬ ПОРТАЛ"
giveBtn.TextSize = 16
giveBtn.TextColor3 = PAL.White
giveBtn.ZIndex = 11
giveBtn.Parent = menu
corner(giveBtn, 12)
newStroke(giveBtn, PAL.Green, 1.2)
local giveGrad = newGradient(giveBtn, PAL.GreenDark, PAL.Green, 0)
TweenService:Create(giveGrad, -- переливающийся зелёный
    TweenInfo.new(2.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1, true),
    {Offset = Vector2.new(0.8, 0)}):Play()
local giveBtnScale = Instance.new("UIScale")
giveBtnScale.Parent = giveBtn

giveBtn.MouseEnter:Connect(function()
    tween(giveBtnScale, 0.18, {Scale = 1.04}, Enum.EasingStyle.Back)
    tween(giveGrad, 0.18, {Brightness = 1.3})
end)
giveBtn.MouseLeave:Connect(function()
    tween(giveBtnScale, 0.25, {Scale = 1})
    tween(giveGrad, 0.25, {Brightness = 1})
end)

local removeBtn = Instance.new("TextButton")
removeBtn.Size = UDim2.new(1, -32, 0, 40)
removeBtn.Position = UDim2.new(0, 16, 0, 156)
removeBtn.BackgroundColor3 = PAL.PanelLight
removeBtn.BorderSizePixel = 0
removeBtn.AutoButtonColor = false
removeBtn.Font = Enum.Font.GothamBold
removeBtn.Text = "✖   УБРАТЬ ПУШКУ"
removeBtn.TextSize = 12
removeBtn.TextColor3 = PAL.Gray
removeBtn.ZIndex = 11
removeBtn.Parent = menu
corner(removeBtn, 10)
local removeStroke = newStroke(removeBtn, PAL.Gray, 1)
removeStroke.Transparency = 0.4
local removeBtnScale = Instance.new("UIScale")
removeBtnScale.Parent = removeBtn

removeBtn.MouseEnter:Connect(function()
    tween(removeBtn, 0.18, {TextColor3 = PAL.White})
    tween(removeStroke, 0.18, {Transparency = 0, Color = PAL.Green})
end)
removeBtn.MouseLeave:Connect(function()
    tween(removeBtn, 0.22, {TextColor3 = PAL.Gray})
    tween(removeStroke, 0.22, {Transparency = 0.4, Color = PAL.Gray})
end)

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 0, 0, 206)
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "●  Пушка не выдана"
statusLabel.TextSize = 12
statusLabel.TextColor3 = PAL.Gray
statusLabel.ZIndex = 11
statusLabel.Parent = menu

local function setStatus(has)
    if has then
        statusLabel.Text = "●  Пушка выдана — ЛКМ открывает портал"
        statusLabel.TextColor3 = PAL.Green
    else
        statusLabel.Text = "●  Пушка не выдана"
        statusLabel.TextColor3 = PAL.Gray
    end
end

local footer = Instance.new("TextLabel")
footer.BackgroundTransparency = 1
footer.Position = UDim2.new(0, 0, 1, -30)
footer.Size = UDim2.new(1, 0, 0, 16)
footer.Font = Enum.Font.Gotham
footer.Text = "Wubba lubba dub dub! 🥒"
footer.TextSize = 11
footer.TextColor3 = PAL.Gray
footer.TextTransparency = 0.35
footer.ZIndex = 11
footer.Parent = menu

--═══════════════ ОТКРЫТИЕ / ЗАКРЫТИЕ МЕНЮ ═══════════════
local menuOpen = false
local menuState = addDraggable(menu, titleBar,
    Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))

local function openMenu()
    if menuOpen then return end
    menuOpen = true
    menu.Visible = true
    local vp = Camera.ViewportSize
    menuState.current = Vector2.new(vp.X / 2, vp.Y * 0.6) -- вылетает снизу
    menuState.target  = Vector2.new(vp.X / 2, vp.Y * 0.42)
    menuScale.Scale = 0
    menu.GroupTransparency = 1
    tween(menuScale, 0.45, {Scale = 1}, Enum.EasingStyle.Back)
    tween(menu, 0.4, {GroupTransparency = 0})
    tween(menuStroke, 0.5, {Transparency = 0.15})
    local spin = tween(circle, 0.55, {Rotation = 360}, Enum.EasingStyle.Back) -- кружок делает оборот
    spin.Completed:Connect(function() circle.Rotation = 0 end)
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    tween(menu, 0.22, {GroupTransparency = 1})
    tween(menuStroke, 0.22, {Transparency = 1})
    tween(menuScale, 0.28, {Scale = 0}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        .Completed:Connect(function()
            if not menuOpen then menu.Visible = false end
        end)
end

local function toggleMenu()
    if menuOpen then closeMenu() else openMenu() end
end

-- перетаскивание кружка + клик по нему
addDraggable(circle, circle,
    Vector2.new(Camera.ViewportSize.X - 90, Camera.ViewportSize.Y / 2),
    function()
        tween(circleScale, 0.08, {Scale = 0.86}) -- пружинящий клик
        task.delay(0.09, function()
            tween(circleScale, 0.3, {Scale = 1.1}, Enum.EasingStyle.Back)
        end)
        toggleMenu()
    end)

closeBtn.MouseButton1Click:Connect(function()
    tween(closeBtn, 0.08, {BackgroundTransparency = 0.4})
    task.delay(0.1, function() tween(closeBtn, 0.2, {BackgroundTransparency = 1}) end)
    closeMenu()
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Escape and menuOpen then closeMenu() end
end)

--═══════════════ ПОРТАЛЬНАЯ ПУШКА ═══════════════
local portals = {}
local lastShot = 0
local teleporting = {}

local function destroyPortal(p)
    if p.Disc and p.Disc.Parent then
        tween(p.Disc, 0.35, {Size = Vector3.new(0.3, 0.2, 0.2), Transparency = 1},
            Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end
    if p.Ring and p.Ring.Parent then
        tween(p.Ring, 0.35, {Size = Vector3.new(0.25, 0.2, 0.2), Transparency = 1},
            Enum.EasingStyle.Back, Enum.EasingDirection.In)
    end
    Debris:AddItem(p.Model, 0.4)
end

local function clearPortals()
    for _, p in ipairs(portals) do destroyPortal(p) end
    portals = {}
end

local function createPortal(position, normal)
    if #portals >= 2 then -- максимум 2 портала, старый красиво исчезает
        destroyPortal(portals[1])
        table.remove(portals, 1)
    end

    local model = Instance.new("Model")
    model.Name = "RMPortal"
    local baseCF = CFrame.lookAt(position, position + normal) * CFrame.Angles(0, math.rad(90), 0)

    local ring = Instance.new("Part") -- внешнее кольцо
    ring.Shape = Enum.PartType.Cylinder
    ring.Size = Vector3.new(0.25, 0.6, 0.6)
    ring.CFrame = baseCF
    ring.Color = PAL.GreenDark
    ring.Material = Enum.Material.Neon
    ring.Transparency = 0.2
    ring.Anchored, ring.CanCollide, ring.CanQuery = true, false, false
    ring.Parent = model

    local disc = Instance.new("Part") -- сам портал
    disc.Shape = Enum.PartType.Cylinder
    disc.Size = Vector3.new(0.32, 0.5, 0.5)
    disc.CFrame = baseCF
    disc.Color = PAL.Green
    disc.Material = Enum.Material.Neon
    disc.Transparency = 0.1
    disc.Anchored, disc.CanCollide, disc.CanQuery = true, false, false
    disc.Parent = model

    local pe = Instance.new("ParticleEmitter")
    pe.Color = ColorSequence.new(PAL.Green, Color3.fromRGB(180, 255, 200))
    pe.LightEmission = 1
    pe.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0)})
    pe.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1)})
    pe.Lifetime = NumberRange.new(0.3, 0.8)
    pe.Rate = 45
    pe.Speed = NumberRange.new(2, 5)
    pe.SpreadAngle = Vector2.new(180, 180)
    pe.RotSpeed = NumberRange.new(-120, 120)
    pe.Parent = disc

    local light = Instance.new("PointLight")
    light.Color, light.Range, light.Brightness = PAL.Green, 10, 1.5
    light.Parent = disc

    model.Parent = workspace

    -- красивое появление + «дыхание»
    tween(ring, 0.5, {Size = Vector3.new(0.25, 5.3, 5.3)}, Enum.EasingStyle.Back)
    tween(disc, 0.5, {Size = Vector3.new(0.32, 4.4, 4.4)}, Enum.EasingStyle.Back)
    TweenService:Create(disc,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.45}):Play()
    TweenService:Create(light,
        TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Brightness = 2.5}):Play()

    local portal = {Model = model, Disc = disc, Ring = ring}
    table.insert(portals, portal)

    -- телепортация при касании
    disc.Touched:Connect(function(hit)
        local char = hit:FindFirstAncestorOfClass("Model")
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or char ~= Player.Character then return end
        if #portals < 2 or teleporting[char] then return end

        local other = (portals[1] == portal) and portals[2] or portals[1]
        if not other or not other.Disc.Parent then return end

        teleporting[char] = true

        local otherDisc = other.Disc
        local outNormal = otherDisc.CFrame.XVector
        local dest = otherDisc.Position + outNormal * 2.5

        -- зелёная вспышка на экране
        local cc = Instance.new("ColorCorrectionEffect")
        cc.Parent = Lighting
        tween(cc, 0.1, {TintColor = Color3.fromRGB(140, 255, 180), Saturation = 0.25, Brightness = 0.06})
        task.delay(0.12, function()
            tween(cc, 0.45, {TintColor = Color3.new(1, 1, 1), Saturation = 0, Brightness = 0})
            Debris:AddItem(cc, 0.55)
        end)

        char:PivotTo(CFrame.lookAt(dest, dest + outNormal))
        task.delay(1, function() teleporting[char] = nil end)
    end)

    return portal
end

local function givePortalGun()
    local function kill(name)
        local old = Player.Backpack:FindFirstChild(name)
        if old then old:Destroy() end
        if Player.Character then
            old = Player.Character:FindFirstChild(name)
            if old then old:Destroy() end
        end
    end
    kill("Портальная пушка")

    local tool = Instance.new("Tool")
    tool.Name = "Портальная пушка"
    tool.ToolTip = "🌀 Портальная пушка Рика — ЛКМ открывает портал"
    tool.CanBeDropped = false
    tool.RequiresHandle = true
    tool.Grip = CFrame.new(0, 0.95, -0.6)

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.75, 0.95, 2.7)
    handle.Color = Color3.fromRGB(95, 102, 97)
    handle.Material = Enum.Material.Metal
    handle.CanCollide = false
    handle.Massless = true
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.Parent = tool

    local function part(name, size, color, material, c0, shape)
        local p = Instance.new("Part")
        p.Name = name
        p.Size = size
        p.Color = color
        p.Material = material or Enum.Material.Metal
        p.CanCollide = false
        p.Massless = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        if shape then p.Shape = shape end
        p.Parent = tool
        local w = Instance.new("Weld")
        w.Part0, w.Part1, w.C0 = handle, p, c0
        w.Parent = p
        return p
    end

    part("Grip", Vector3.new(0.55, 1.35, 0.55), Color3.fromRGB(65, 70, 67), Enum.Material.Metal,
        CFrame.new(0, -1.05, 0.75) * CFrame.Angles(math.rad(-12), 0, 0))
    part("Barrel", Vector3.new(0.62, 0.62, 1.2), Color3.fromRGB(80, 86, 82), Enum.Material.Metal,
        CFrame.new(0, 0, -1.9))

    local dome = part("Dome", Vector3.new(1.7, 1.7, 1.7), Color3.fromRGB(200, 215, 208),
        Enum.Material.Glass, CFrame.new(0, 0, -2.55), Enum.PartType.Ball)
    dome.Transparency = 0.45

    part("PortalDisc", Vector3.new(0.34, 1.25, 1.25), PAL.Green, Enum.Material.Neon,
        CFrame.new(0, 0, -2.55) * CFrame.Angles(0, math.rad(90), 0), Enum.PartType.Cylinder)

    local domeLight = Instance.new("PointLight")
    domeLight.Color, domeLight.Range, domeLight.Brightness = PAL.Green, 7, 1.4
    domeLight.Parent = dome

    part("RedButton", Vector3.new(0.42, 0.22, 0.42), Color3.fromRGB(255, 70, 70),
        Enum.Material.SmoothPlastic, CFrame.new(0, 0.56, 0.25))

    local strip = part("GreenStrip", Vector3.new(0.14, 0.14, 1.7), PAL.Green, Enum.Material.Neon,
        CFrame.new(0.44, 0.08, 0.1))
    part("GreenDetail", Vector3.new(0.14, 0.55, 0.14), PAL.GreenSoft, Enum.Material.Neon,
        CFrame.new(-0.44, -0.12, -0.35))

    TweenService:Create(strip, -- пульсация зелёной полоски
        TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.5}):Play()

    --── стрельба ──
    tool.Activated:Connect(function()
        if os.clock() - lastShot < SHOOT_COOLDOWN then return end
        lastShot = os.clock()

        -- вспышка на дуле
        local flash = Instance.new("Part")
        flash.Shape = Enum.PartType.Ball
        flash.Size = Vector3.new(0.5, 0.5, 0.5)
        flash.Color = PAL.Green
        flash.Material = Enum.Material.Neon
        flash.Anchored, flash.CanCollide, flash.CanQuery = true, false, false
        flash.CFrame = handle.CFrame * CFrame.new(0, 0, -3.3)
        flash.Parent = workspace
        tween(flash, 0.25, {Size = Vector3.new(2.4, 2.4, 2.4), Transparency = 1})
        Debris:AddItem(flash, 0.3)

        -- луч из камеры туда, куда смотришь
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ignore = {}
        if Player.Character then table.insert(ignore, Player.Character) end
        for _, p in ipairs(portals) do table.insert(ignore, p.Model) end
        params.FilterDescendantsInstances = ignore

        local result = workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 500, params)
        if result then
            createPortal(result.Position + result.Normal * 0.15, result.Normal)
        else
            notify("⚠️ Промах", "Наведись на стену или пол")
        end
    end)

    tool.Parent = Player.Backpack
end

--═══════════════ ПОДКЛЮЧЕНИЕ КНОПОК ═══════════════
giveBtn.MouseButton1Click:Connect(function()
    tween(giveBtnScale, 0.07, {Scale = 0.93})
    task.delay(0.08, function() tween(giveBtnScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
    givePortalGun()
    setStatus(true)
    notify("🌀 Портальная пушка выдана", "Экипируй её в инвентаре и стреляй!")
end)

removeBtn.MouseButton1Click:Connect(function()
    tween(removeBtnScale, 0.07, {Scale = 0.94})
    task.delay(0.08, function() tween(removeBtnScale, 0.25, {Scale = 1}, Enum.EasingStyle.Back) end)
    local old = Player.Backpack:FindFirstChild("Портальная пушка")
    if old then old:Destroy() end
    if Player.Character then
        old = Player.Character:FindFirstChild("Портальная пушка")
        if old then old:Destroy() end
    end
    clearPortals()
    setStatus(false)
    notify("✖ Пушка убрана", "Все порталы закрыты")
end)

Player.CharacterAdded:Connect(function()
    task.wait(0.3)
    setStatus(false)
end)

--═══════════════ СТАРТ ═══════════════
circleScale.Scale = 0
task.wait(0.2)
tween(circleScale, 0.5, {Scale = 1}, Enum.EasingStyle.Back)
notify("🌀 Рик и Морти навсегда", "Кликни по кружку, чтобы открыть меню")
