-- ===============================================================
-- UNITEDAim v2.0.3 - FIXED Bulletproof Edition
-- Semua error nil.new sudah diperbaiki + safety guard menyeluruh
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
-- 0. DETEKSI GLOBAL KRITIS (fix "nil.new")
-- ===============================================================
local Instance_ok = pcall(function()
    local t = Instance.new("Frame")
    if t then t:Destroy() end
end)
if not Instance_ok then
    error("[UNITEDAim] Instance.new tidak tersedia - executor bermasalah")
end

local Ray_ok = pcall(function()
    local _ = Ray.new(Vector3.new(0,0,0), Vector3.new(1,0,0))
end)

local RaycastParams_ok = pcall(function()
    local _ = RaycastParams.new()
end)

local Drawing_ok = false
pcall(function()
    local test = Drawing.new("Circle")
    test.Visible = false
    pcall(function() test:Remove() end)
    Drawing_ok = true
end)

-- ===============================================================
-- 1. SAFE RAYCAST (didefinisikan SEBELUM mouse)
-- ===============================================================
local function safeRaycast(origin, direction, ignoreList)
    -- Metode modern
    if RaycastParams_ok then
        local ok, res = pcall(function()
            local rp = RaycastParams.new()
            rp.FilterType = Enum.RaycastFilterType.Exclude
            rp.FilterDescendantsInstances = ignoreList
            return workspace:Raycast(origin, direction, rp)
        end)
        if ok and res then
            return res.Instance, res.Position
        end
    end
    -- Metode lama
    if Ray_ok then
        local ignore = type(ignoreList) == "table" and ignoreList[1] or ignoreList
        local ok, part, pos = pcall(function()
            return workspace:FindPartOnRay(Ray.new(origin, direction), ignore)
        end)
        if ok then
            return part, pos
        end
    end
    return nil, nil
end

-- ===============================================================
-- 2. SAFE MOUSE (fix nil hitPos + Ray.new)
-- ===============================================================
local mouse
pcall(function() mouse = player:GetMouse() end)

if not mouse then
    mouse = setmetatable({}, {
        __index = function(_, k)
            if k == "X" or k == "Y" then
                local ok, pos = pcall(function() return UIS:GetMouseLocation() end)
                if ok and pos then
                    return k == "X" and pos.X or pos.Y
                end
                return 0
            elseif k == "Hit" or k == "Target" then
                local ok, pos = pcall(function() return UIS:GetMouseLocation() end)
                if not ok or not pos then
                    return (k == "Hit") and CFrame.new() or nil
                end
                local ok2, ray = pcall(function() return cam:ViewportPointToRay(pos.X, pos.Y) end)
                if not ok2 or not ray then
                    return (k == "Hit") and CFrame.new() or nil
                end
                local hitPart, hitPos = safeRaycast(ray.Origin, ray.Direction * 1000, {player.Character, cam})
                if k == "Hit" then
                    return hitPos and CFrame.new(hitPos) or CFrame.new()
                else
                    return hitPart
                end
            end
            return nil
        end
    })
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
-- 4. SAFE UI HELPERS
-- ===============================================================
local function mk(class, props, parent)
    local ok, o = pcall(function() return Instance.new(class) end)
    if not ok or not o then return nil end
    for k, v in pairs(props or {}) do
        pcall(function() o[k] = v end)
    end
    pcall(function() o.Parent = parent end)
    return o
end

local function corner(o, r)
    if not o then return end
    pcall(function()
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, r)
        c.Parent = o
    end)
end

local function stroke(o, color, th)
    if not o then return end
    pcall(function()
        local s = Instance.new("UIStroke")
        s.Color = color
        s.Thickness = th or 1
        s.Parent = o
    end)
end

local function tween(o, props, t)
    if not o then return end
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
    return i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch
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
    if kind == "error" then color = T.danger
    elseif kind == "success" then color = T.success end
    local f = mk("Frame", {
        Size = UDim2.new(0, 280, 0, 36),
        Position = UDim2.new(0.5, -140, 0, 14),
        BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 100
    }, gui)
    if not f then return end
    corner(f, 8); stroke(f, color, 1.5)
    mk("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = T.text,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 101
    }, f)
    task.delay(2, function() pcall(function() f:Destroy() end) end)
end

-- ===============================================================
-- 6. MAIN WINDOW
-- ===============================================================
local Main = mk("Frame", {
    Size = UDim2.new(0, 590, 0, 450), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = T.bg,
    BorderSizePixel = 0, Visible = false, ClipsDescendants = true
}, gui)
if Main then
    corner(Main, 14); stroke(Main, T.accent, 2)
end

local Title = mk("Frame", {
    Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.panel, BorderSizePixel = 0
}, Main)

mk("TextLabel", {
    Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, Text = "UNITEDAim v2.0.3 - Fixed",
    TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 14,
    TextXAlignment = Enum.TextXAlignment.Left
}, Title)

local CloseBtn = mk("TextButton", {
    Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -34, 0, 7),
    BackgroundColor3 = T.danger, Text = "X", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 13
}, Title)
if CloseBtn then
    corner(CloseBtn, 7)
    CloseBtn.MouseButton1Click:Connect(function() if Main then Main.Visible = false end end)
end

-- Draggable
local dragging, dragStart, startPos = false, nil, nil
if Title then
    Title.InputBegan:Connect(function(input)
        if isTap(input) then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    Title.InputEnded:Connect(function(input)
        if isTap(input) then dragging = false end
    end)
end
UIS.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement and Main then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

local Sidebar = mk("Frame", {
    Size = UDim2.new(0, 118, 1, -40), Position = UDim2.new(0, 0, 0, 40),
    BackgroundColor3 = T.panel
}, Main)

local Content = mk("Frame", {
    Size = UDim2.new(1, -128, 1, -50), Position = UDim2.new(0, 120, 0, 46),
    BackgroundTransparency = 1
}, Main)

-- ===============================================================
-- 7. TAB SYSTEM
-- ===============================================================
local tabs, currentTab = {}, nil
local function selectTab(name)
    currentTab = name
    for n, t in pairs(tabs) do
        if t.page then t.page.Visible = (n == name) end
        if t.btn then
            t.btn.BackgroundColor3 = (n == name) and T.accent or T.card
        end
    end
end

local function addTab(name, icon)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -10, 0, 30),
        Position = UDim2.new(0, 5, 0, 5 + (#tabs * 35)),
        BackgroundColor3 = T.card, Text = icon .. " " .. name,
        TextColor3 = T.text, Font = Enum.Font.GothamBold, TextSize = 12
    }, Sidebar)
    if btn then corner(btn, 6) end
    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        ScrollBarThickness = 4, CanvasSize = UDim2.new(0, 0, 2000, 0),
        Visible = false
    }, Content)
    local tab = {btn = btn, page = page, y = 5}
    tabs[name] = tab
    if btn then
        btn.MouseButton1Click:Connect(function() selectTab(name) end)
    end
    return tab
end

-- ===============================================================
-- 8. COMPONENTS
-- ===============================================================
local function Section(tab, text)
    if not tab.page then return end
    mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 20), Position = UDim2.new(0, 4, 0, tab.y),
        BackgroundTransparency = 1, Text = text:upper(), TextColor3 = T.accent,
        Font = Enum.Font.GothamBold, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left
    }, tab.page)
    tab.y = tab.y + 25
end

-- FIX: Toggle sekarang menerima `initial` state agar sinkron dengan S
local function Toggle(tab, name, initial, cb)
    if not tab.page then return end
    local state = initial and true or false
    local row = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, tab.y),
        BackgroundColor3 = state and T.accent or T.card,
        Text = "  " .. name, TextColor3 = T.text,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left
    }, tab.page)
    if not row then return end
    corner(row, 6); stroke(row, T.stroke, 1)
    row.MouseButton1Click:Connect(function()
        state = not state
        row.BackgroundColor3 = state and T.accent or T.card
        pcall(cb, state)
    end)
    tab.y = tab.y + 42
end

local function Button(tab, name, cb, color)
    if not tab.page then return end
    color = color or T.card
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), Position = UDim2.new(0, 0, 0, tab.y),
        BackgroundColor3 = color, Text = name, TextColor3 = T.text,
        Font = Enum.Font.GothamBold, TextSize = 12
    }, tab.page)
    if not b then return end
    corner(b, 6); stroke(b, T.accent, 1)
    b.MouseButton1Click:Connect(function() pcall(cb) end)
    tab.y = tab.y + 40
    return b
end

local function RadioGroup(tab, label, options, default, onChange)
    Section(tab, label)
    local btns = {}
    local function select(value)
        for v, b in pairs(btns) do
            if b then b.BackgroundColor3 = (v == value) and T.accent or T.card end
        end
        pcall(onChange, value)
    end
    if not tab.page then return select end
    for i, opt in ipairs(options) do
        local b = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 32), Position = UDim2.new(0, 0, 0, tab.y),
            BackgroundColor3 = (opt.value == default) and T.accent or T.card,
            Text = "  " .. opt.label, TextColor3 = T.text,
            Font = Enum.Font.GothamBold, TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, tab.page)
        if b then
            corner(b, 6); stroke(b, T.stroke, 1)
            b.MouseButton1Click:Connect(function() select(opt.value) end)
            btns[opt.value] = b
        end
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
connect(player.CharacterAdded, function()
    task.wait(0.5); refreshHumanoid()
end)

local function getHitbox(char)
    if not char then return nil end
    if S.Hitbox == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    end
    return char:FindFirstChild("Head")
end

local function isVisible(part)
    if not part then return false end
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
                                        best = {
                                            char = plr.Character, hum = hum, part = part,
                                            pos = part.Position,
                                            screen = Vector2.new(screen.X, screen.Y)
                                        }
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
    if hookInstalled then return true end
    if not hookmetamethod or not checkcaller then return false end

    local anyHooked = false

    -- Silent Aim via Mouse metatable
    pcall(function()
        if getrawmetatable and setreadonly then
            local mt = getrawmetatable(mouse)
            if mt and mt.__index then
                local oldIdx = mt.__index
                setreadonly(mt, false)
                mt.__index = function(self, key)
                    if not checkcaller() then
                        if S.AimbotMode == "Silent" then
                            if key == "Hit" then
                                local t = getTarget()
                                if t then return CFrame.new(t.pos) end
                            elseif key == "Target" then
                                local t = getTarget()
                                if t then return t.part end
                            end
                        end
                    end
                    return oldIdx(self, key)
                end
                setreadonly(mt, true)
                anyHooked = true
            end
        end
    end)

    -- Property Spoof (WalkSpeed/JumpPower) via Humanoid
    pcall(function()
        if getrawmetatable and setreadonly and currentHumanoid then
            local mt = getrawmetatable(currentHumanoid)
            if mt and mt.__index then
                local oldIdx2 = mt.__index
                setreadonly(mt, false)
                mt.__index = function(self, key)
                    if S.PropertySpoof and self == currentHumanoid then
                        if key == "WalkSpeed" then return 16 end
                        if key == "JumpPower" then return 50 end
                    end
                    return oldIdx2(self, key)
                end
                setreadonly(mt, true)
                anyHooked = true
            end
        end
    end)

    hookInstalled = anyHooked
    return anyHooked
end

local fireCooldown = 0
local function fireShot()
    if tick() - fireCooldown < 0.05 then return end
    fireCooldown = tick()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        if not vim then return end
        local mx = tonumber(mouse.X) or 0
        local my = tonumber(mouse.Y) or 0
        vim:SendMouseButtonEvent(mx, my, 0, true, game, 1)
        task.wait(0.02)
        vim:SendMouseButtonEvent(mx, my, 0, false, game, 1)
    end)
end

connect(RunService.RenderStepped, function()
    cam = workspace.CurrentCamera
    if not cam then return end

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
-- 10. SAFE DRAWING (FOV, CROSSHAIR)
-- ===============================================================
local fovCircle, crosshair

if Drawing_ok then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        if fovCircle then
            fovCircle.Thickness = 1.5
            fovCircle.Color = T.accent
            fovCircle.Filled = false
            fovCircle.Visible = false
        end
        crosshair = Drawing.new("Circle")
        if crosshair then
            crosshair.Thickness = 0
            crosshair.Filled = true
            crosshair.Radius = 3
            crosshair.Visible = false
        end
    end)
end

connect(RunService.RenderStepped, function()
    if not Drawing_ok then return end
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
-- 11. BUILD TABS
-- ===============================================================
local tAim = addTab("Aimbot", "[A]")
local tESP = addTab("Visual", "[V]")
local tSet = addTab("Setting", "[S]")

-- AIMBOT
local modeSelector
modeSelector = RadioGroup(tAim, "Aimbot Mode", {
    {label = "Off",        value = "Off"},
    {label = "Legit Aim",  value = "Legit"},
    {label = "Silent Aim", value = "Silent"},
    {label = "Rage Aim",   value = "Rage"},
}, "Off", function(v)
    if v == "Silent" then
        if not installHook() then
            notify("Executor tidak support Silent", "error")
            if modeSelector then modeSelector("Off") end
            return
        end
    end
    S.AimbotMode = v
    notify("Mode: " .. v)
end)

Section(tAim, "Common")
Toggle(tAim, "Wall Check",        S.WallCheck,    function(v) S.WallCheck = v end)
Toggle(tAim, "Team Check",        S.TeamCheck,    function(v) S.TeamCheck = v end)
Toggle(tAim, "Show FOV Circle",   S.ShowFOV,      function(v) S.ShowFOV = v end)
Toggle(tAim, "Auto Fire (Silent/Rage)", S.AutoFire, function(v) S.AutoFire = v end)

-- FIX: Button FOV sekarang cycling (tidak mati di 150 terus)
local fovValues = {50, 100, 150, 200, 300, 500}
local fovIndex = 3
Button(tAim, "FOV: 150 (klik untuk ganti)", function()
    fovIndex = (fovIndex % #fovValues) + 1
    S.FOV = fovValues[fovIndex]
    notify("FOV: " .. S.FOV)
end)

Section(tAim, "Safety")
Toggle(tAim, "Property Spoof (WalkSpeed)", S.PropertySpoof, function(v)
    S.PropertySpoof = v
    if v and not hookInstalled then installHook() end
end)

-- VISUAL
Section(tESP, "Overlay")
Toggle(tESP, "Custom Crosshair", S.Crosshair, function(v) S.Crosshair = v end)
Button(tESP, "Cycle Crosshair Color", function()
    S.CrosshairColor = Color3.fromRGB(
        math.random(100, 255), math.random(100, 255), math.random(100, 255))
end)

Section(tESP, "Environment")
Toggle(tESP, "X-Ray (Transparent Map)", false, function(v)
    task.spawn(function()
        for _, o in ipairs(workspace:GetDescendants()) do
            -- FIX: cek Parent dulu sebelum FindFirstChildOfClass
            if o:IsA("BasePart") and o.Parent then
                local isChar = o.Parent:FindFirstChildOfClass("Humanoid") ~= nil
                if not isChar then
                    pcall(function()
                        o.LocalTransparencyModifier = v and 0.7 or 0
                    end)
                end
            end
        end
    end)
end)

Toggle(tESP, "FPS Boost", false, function(v)
    if v then
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
    else
        for k, val in pairs(origLight) do
            pcall(function() Lighting[k] = val end)
        end
    end
end)

-- SETTINGS
Section(tSet, "System")
Toggle(tSet, "Notifications", S.Notif, function(v) S.Notif = v end)

Button(tSet, "PANIC - Matikan Semua", function()
    S.AimbotMode = "Off"; S.AutoFire = false; S.Crosshair = false
    if modeSelector then modeSelector("Off", true) end
    notify("Panic mode activated", "warn")
end, T.danger)

Button(tSet, "Unload Script", function()
    pcall(function() gui:Destroy() end)
    if fovCircle then pcall(function() fovCircle:Remove() end) end
    if crosshair then pcall(function() crosshair:Remove() end) end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
end)

-- ===============================================================
-- 12. FLOATING BUTTON & INIT
-- ===============================================================
local Float = mk("TextButton", {
    Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 16, 0.5, -27),
    BackgroundColor3 = T.accent, Text = "A", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBlack, TextSize = 26
}, gui)
if Float then
    corner(Float, 27)
    Float.MouseButton1Click:Connect(function()
        if Main then Main.Visible = not Main.Visible end
    end)
end

connect(UIS.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift or i.KeyCode == Enum.KeyCode.A then
        if Main then Main.Visible = not Main.Visible end
    end
end)

selectTab("Aimbot")
if Main then Main.Visible = true end
notify("UNITEDAim v2.0.3 Ready!", "success")