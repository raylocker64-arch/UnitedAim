-- ===============================================================
-- UNITEDAim v2.0.2 - Bulletproof Edition (Old Executor Support)
-- 100% ASCII - No Unicode characters
-- Fix: GetMouse, RaycastParams, UIStroke, ZIndexBehavior
-- ===============================================================

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")

local player = Players.LocalPlayer
local cam    = workspace.CurrentCamera
local PlayerGui = player:WaitForChild("PlayerGui")

-- ===============================================================
-- 1. SAFE MOUSE (Bypass GetMouse Error)
-- ===============================================================
local mouse
pcall(function() mouse = player:GetMouse() end)

if not mouse then
    local UIS_Input = game:GetService("UserInputService")
    mouse = setmetatable({}, {
        __index = function(_, k)
            if k == "X" then 
                return UIS_Input:GetMouseLocation().X
            elseif k == "Y" then 
                return UIS_Input:GetMouseLocation().Y
            elseif k == "Hit" or k == "Target" then
                local pos = UIS_Input:GetMouseLocation()
                local ray = cam:ViewportPointToRay(pos.X, pos.Y)
                local hitPart, hitPos = workspace:FindPartOnRay(Ray.new(ray.Origin, ray.Direction * 1000), player.Character)
                if k == "Hit" then
                    return CFrame.new(hitPos)
                else
                    return hitPart
                end
            end
            return nil
        end
    })
end

-- ===============================================================
-- 2. SAFE RAYCAST (Bypass RaycastParams Error)
-- ===============================================================
local function safeRaycast(origin, direction, ignoreList)
    local ok, res = pcall(function()
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = ignoreList
        return workspace:Raycast(origin, direction, rp)
    end)
    if ok and res then
        return res.Instance, res.Position
    end
    -- Fallback ke API lama
    local ignore = type(ignoreList) == "table" and ignoreList[1] or ignoreList
    return workspace:FindPartOnRay(Ray.new(origin, direction), ignore)
end

-- ===============================================================
-- 3. THEME & STATE
-- ===============================================================
local T = {
    bg      = Color3.fromRGB(10, 10, 13),
    panel   = Color3.fromRGB(15, 15, 20),
    card    = Color3.fromRGB(22, 22, 30),
    cardH   = Color3.fromRGB(30, 30, 40),
    accent  = Color3.fromRGB(220, 30, 45),
    accent2 = Color3.fromRGB(255, 70, 80),
    text    = Color3.fromRGB(240, 240, 245),
    sub     = Color3.fromRGB(140, 145, 155),
    off     = Color3.fromRGB(48, 48, 58),
    danger  = Color3.fromRGB(255, 45, 60),
    success = Color3.fromRGB(70, 210, 120),
    warn    = Color3.fromRGB(255, 190, 70),
    stroke  = Color3.fromRGB(42, 42, 52),
}

local S = {
    AimbotMode = "Off", FOV = 150, Hitbox = "Head", TargetPriority = "Crosshair",
    WallCheck = true, MaxDistance = 500, ShowFOV = true, TeamCheck = true,
    Smoothness = 35, AimKey = "RightMouse", Humanize = true, JitterAmount = 8,
    AutoFire = false, SafeMode = false, PropertySpoof = false,
    ESP = false, Crosshair = false, CrosshairStyle = "Dot", CrosshairSize = 6,
    CrosshairColor = Color3.fromRGB(255, 60, 80), UIScale = 100, Notif = true,
}

local origLight = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}

local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(fn); table.insert(conns, c); return c
end

-- ===============================================================
-- 4. SAFE UI HELPERS (Bypass UIStroke/Gradient Error)
-- ===============================================================
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do 
        pcall(function() o[k] = v end)
    end
    o.Parent = parent
    return o
end

local function corner(o, r) 
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = o
    end)
end

local function stroke(o, color, th)
    pcall(function()
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = th or 1
        s.Parent = o
    end)
end

local function tween(o, props, t)
    pcall(function()
        TweenService:Create(o, TweenInfo.new(t or 0.15), props):Play()
    end)
end

local function getChar()
    local c = player.Character
    if not c then return end
    return c, c:FindFirstChildOfClass("Humanoid"), c:FindFirstChild("HumanoidRootPart")
end
local function isTap(i)
    return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch
end

-- ===============================================================
-- 5. GUI ROOT & NOTIF
-- ===============================================================
local old = PlayerGui:FindFirstChild("UNITEDAim")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "UNITEDAim"
gui.ResetOnSpawn = false
pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
gui.Parent = PlayerGui

local function notify(text, kind)
    if not S.Notif then return end
    local color = T.accent
    if kind == "error" then color = T.danger elseif kind == "success" then color = T.success end
    local f = mk("Frame", {Size = UDim2.new(0, 280, 0, 36), Position = UDim2.new(0.5, -140, 0, 14), BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 100}, gui)
    corner(f, 8); stroke(f, color, 1.5)
    mk("TextLabel", {Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = text, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101}, f)
    task.delay(2, function() f:Destroy() end)
end

-- ===============================================================
-- 6. MAIN WINDOW
-- ===============================================================
local Main = mk("Frame", {Size = UDim2.new(0, 590, 0, 450), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = T.bg, BorderSizePixel = 0, Visible = false, ClipsDescendants = true}, gui)
corner(Main, 14); stroke(Main, T.accent, 2)

local Title = mk("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.panel, BorderSizePixel = 0}, Main)
mk("TextLabel", {Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 16, 0, 0), BackgroundTransparency = 1, Text = "UNITEDAim v2.0.2 - Old Executor Mode", TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left}, Title)

local CloseBtn = mk("TextButton", {Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -34, 0, 7), BackgroundColor3 = T.danger, Text = "X", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBold, TextSize = 13}, Title)
corner(CloseBtn, 7)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Draggable
local dragging, dragStart, startPos = false, nil, nil
Title.InputBegan:Connect(function(input)
    if isTap(input) then dragging = true; dragStart = input.Position; startPos = Main.Position end
end)
Title.InputEnded:Connect(function(input) if isTap(input) then dragging = false end end)
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local Sidebar = mk("Frame", {Size = UDim2.new(0, 118, 1, -40), Position = UDim2.new(0, 0, 0, 40), BackgroundColor3 = T.panel}, Main)
local Content = mk("Frame", {Size = UDim2.new(1, -128, 1, -50), Position = UDim2.new(0, 120, 0, 46), BackgroundTransparency = 1}, Main)

-- ===============================================================
-- 7. TAB SYSTEM
-- ===============================================================
local tabs, currentTab = {}, nil
local function selectTab(name)
    currentTab = name
    for n, t in pairs(tabs) do
        t.page.Visible = (n == name)
        t.btn.BackgroundColor3 = (n == name) and T.accent or T.card
    end
end

local function addTab(name, icon)
    local btn = mk("TextButton", {Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 0, 5 + (#tabs * 35)), BackgroundColor3 = T.card, Text = icon .. " " .. name, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12}, Sidebar)
    corner(btn, 6)
    local page = mk("ScrollingFrame", {Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 2000, 0), Visible = false}, Content)
    local tab = {btn = btn, page = page, y = 5}
    tabs[name] = tab
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return tab
end

-- ===============================================================
-- 8. COMPONENTS (Safe)
-- ===============================================================
local function Section(tab, text)
    mk("TextLabel", {Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 4, 0, tab.y), BackgroundTransparency = 1, Text = text:upper(), TextColor3 = T.accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left}, tab.page)
    tab.y = tab.y + 25
end

local function Toggle(tab, name, cb)
    local row = mk("TextButton", {Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, tab.y), BackgroundColor3 = T.card, Text = "  " .. name, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, tab.page)
    corner(row, 6); stroke(row, T.stroke, 1)
    local state = false
    row.MouseButton1Click:Connect(function()
        state = not state
        row.BackgroundColor3 = state and T.accent or T.card
        pcall(cb, state)
    end)
    tab.y = tab.y + 42
end

local function Button(tab, name, cb, color)
    color = color or T.card
    local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, tab.y), BackgroundColor3 = color, Text = name, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12}, tab.page)
    corner(b, 6); stroke(b, T.accent, 1)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    tab.y = tab.y + 40
end

local function RadioGroup(tab, label, options, default, onChange)
    Section(tab, label)
    local btns = {}
    local function select(value)
        for v, b in pairs(btns) do
            b.BackgroundColor3 = (v == value) and T.accent or T.card
        end
        pcall(onChange, value)
    end
    for i, opt in ipairs(options) do
        local b = mk("TextButton", {Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, tab.y), BackgroundColor3 = (opt.value == default) and T.accent or T.card, Text = "  " .. opt.label, TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left}, tab.page)
        corner(b, 6); stroke(b, T.stroke, 1)
        b.MouseButton1Click:Connect(function() select(opt.value) end)
        btns[opt.value] = b
        tab.y = tab.y + 36
    end
    tab.y = tab.y + 5
    return select
end

-- ===============================================================
-- 9. AIMBOT & HOOK LOGIC
-- ===============================================================
local hookInstalled = false
local oldIndex
local currentHumanoid

local function refreshHumanoid()
    local char = player.Character
    if char then currentHumanoid = char:FindFirstChildOfClass("Humanoid") end
end
task.spawn(refreshHumanoid)
connect(player.CharacterAdded, function() task.wait(0.5); refreshHumanoid() end)

local function getHitbox(char)
    if S.Hitbox == "Torso" then return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") end
    return char:FindFirstChild("Head")
end

local function isVisible(part)
    local origin = cam.CFrame.Position
    local dir = (part.Position - origin)
    local hitPart = safeRaycast(origin, dir, {player.Character, cam})
    return hitPart == nil or hitPart:IsDescendantOf(part.Parent)
end

local function getTarget()
    local best, bestScore = nil, math.huge
    local myPos = cam.CFrame.Position
    local mPos = Vector2.new(mouse.X, mouse.Y)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not (S.TeamCheck and player.Team and plr.Team and player.Team == plr.Team) then
                    local part = getHitbox(plr.Character)
                    if part then
                        local dist = (part.Position - myPos).Magnitude
                        if dist <= S.MaxDistance and (not S.WallCheck or isVisible(part)) then
                            local screen, on = cam:WorldToViewportPoint(part.Position)
                            if on and screen.Z > 0 then
                                local sDist = (Vector2.new(screen.X, screen.Y) - mPos).Magnitude
                                if sDist <= S.FOV then
                                    local score = (S.TargetPriority == "Distance") and dist or sDist
                                    if score < bestScore then
                                        bestScore = score
                                        best = {char = plr.Character, hum = hum, part = part, pos = part.Position, screen = Vector2.new(screen.X, screen.Y)}
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return best
end

local function installHook()
    if hookInstalled or not hookmetamethod or not checkcaller then return false end
    local ok, err = pcall(function()
        oldIndex = hookmetamethod(game, "__index", function(self, key)
            if not checkcaller() then
                if S.PropertySpoof and currentHumanoid and self == currentHumanoid then
                    if key == "WalkSpeed" then return 16 end
                    if key == "JumpPower" then return 50 end
                end
                if S.AimbotMode == "Silent" and self == mouse then
                    if key == "Hit" or key == "Target" then
                        local t = getTarget()
                        if t then
                            if key == "Hit" then return CFrame.new(t.pos) end
                            if key == "Target" then return t.part end
                        end
                    end
                end
            end
            return oldIndex(self, key)
        end)
    end)
    if ok then hookInstalled = true end
    return ok
end

local fireCooldown = 0
local function fireShot()
    if tick() - fireCooldown < 0.05 then return end
    fireCooldown = tick()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
        task.wait(0.02)
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
    end)
end

connect(RunService.RenderStepped, function()
    cam = workspace.CurrentCamera
    if S.AimbotMode == "Legit" or S.AimbotMode == "Rage" then
        local t = getTarget()
        if t then
            if S.AimbotMode == "Rage" then
                cam.CFrame = CFrame.new(cam.CFrame.Position, t.pos)
            elseif S.AimbotMode == "Legit" then
                local smooth = math.clamp(1 - (S.Smoothness / 100), 0.05, 1)
                cam.CFrame = cam.CFrame:Lerp(CFrame.new(cam.CFrame.Position, t.pos), smooth)
            end
        end
    end
    if S.AutoFire and (S.AimbotMode == "Silent" or S.AimbotMode == "Rage") then
        if getTarget() then pcall(fireShot) end
    end
end)

-- ===============================================================
-- 10. SAFE DRAWING (FOV, ESP, CROSSHAIR)
-- ===============================================================
local hasDrawing = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function")
local fovCircle, crosshair

if hasDrawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5; fovCircle.Color = T.accent; fovCircle.Filled = false; fovCircle.Visible = false
        crosshair = Drawing.new("Circle")
        crosshair.Thickness = 0; crosshair.Filled = true; crosshair.Radius = 3; crosshair.Visible = false
    end)
end

connect(RunService.RenderStepped, function()
    if not hasDrawing then return end
    local mX, mY = mouse.X, mouse.Y
    
    if fovCircle then
        fovCircle.Visible = S.ShowFOV and (S.AimbotMode ~= "Off")
        if fovCircle.Visible then
            fovCircle.Position = Vector2.new(mX, mY)
            fovCircle.Radius = S.FOV
        end
    end
    if crosshair then
        crosshair.Visible = S.Crosshair
        if crosshair.Visible then
            crosshair.Position = Vector2.new(mX, mY)
            crosshair.Radius = S.CrosshairSize
            crosshair.Color = S.CrosshairColor
        end
    end
end)

-- ===============================================================
-- 11. BUILD TABS (UI)
-- ===============================================================
local tAim    = addTab("Aimbot", "[A]")
local tESP    = addTab("Visual", "[V]")
local tSet    = addTab("Setting","[S]")

-- AIMBOT
local modeSelector
modeSelector = RadioGroup(tAim, "Aimbot Mode", {
    {label = "Off", value = "Off"},
    {label = "Legit Aim", value = "Legit"},
    {label = "Silent Aim", value = "Silent"},
    {label = "Rage Aim", value = "Rage"},
}, "Off", function(v)
    if v == "Silent" then
        if not installHook() then notify("Executor tidak support Silent", "error"); modeSelector("Off"); return end
    end
    S.AimbotMode = v
    notify("Mode: " .. v)
end)

Section(tAim, "Common")
Toggle(tAim, "Wall Check", function(v) S.WallCheck = v end)
Toggle(tAim, "Team Check", function(v) S.TeamCheck = v end)
Toggle(tAim, "Show FOV Circle", function(v) S.ShowFOV = v end)
Toggle(tAim, "Auto Fire (Silent/Rage)", function(v) S.AutoFire = v end)
Button(tAim, "Set FOV: 150", function() S.FOV = 150 end)

Section(tAim, "Safety")
Toggle(tAim, "Property Spoof (WalkSpeed)", function(v)
    S.PropertySpoof = v
    if v and not hookInstalled then installHook() end
end)

-- VISUAL
Section(tESP, "Overlay")
Toggle(tESP, "Custom Crosshair", function(v) S.Crosshair = v end)
Button(tESP, "Cycle Crosshair Color", function()
    S.CrosshairColor = Color3.fromRGB(math.random(100,255), math.random(100,255), math.random(100,255))
end)

Section(tESP, "Environment")
Toggle(tESP, "X-Ray (Transparent Map)", function(v)
    task.spawn(function()
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and not o.Parent:FindFirstChildOfClass("Humanoid") then
                o.LocalTransparencyModifier = v and 0.7 or 0
            end
        end
    end)
end)
Toggle(tESP, "FPS Boost", function(v)
    if v then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
    else
        for k, val in pairs(origLight) do Lighting[k] = val end
    end
end)

-- SETTINGS
Section(tSet, "System")
Toggle(tSet, "Notifications", function(v) S.Notif = v end)
Button(tSet, "PANIC - Matikan Semua", function()
    S.AimbotMode = "Off"; S.AutoFire = false; S.Crosshair = false
    if modeSelector then modeSelector("Off", true) end
    notify("Panic mode activated", "warn")
end, T.danger)
Button(tSet, "Unload Script", function()
    gui:Destroy()
    if hasDrawing then
        if fovCircle then pcall(function() fovCircle:Remove() end) end
        if crosshair then pcall(function() crosshair:Remove() end) end
    end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end)

-- ===============================================================
-- 12. FLOATING BUTTON & INIT
-- ===============================================================
local Float = mk("TextButton", {Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 16, 0.5, -27), BackgroundColor3 = T.accent, Text = "A", TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 26}, gui)
corner(Float, 27)
Float.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

connect(UIS.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift or i.KeyCode == Enum.KeyCode.A then
        Main.Visible = not Main.Visible
    end
end)

selectTab("Aimbot")
Main.Visible = true
notify("UNITEDAim v2.0.2 Ready!", "success")