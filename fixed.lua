-- ===============================================================
-- UNITEDAim v2.0.1 - Shooter Aim Panel
-- FIXED: Unified Hook - No conflict Silent + Spoof
-- 100% ASCII - No Unicode characters (fix U+2550 error)
-- Aimbot: Legit, Silent, Rage (exclusive)
-- Features: Humanizer, Target Lock, Team Check, Config
--           ESP, Crosshair, X-Ray, FPS Boost, Bypass
-- Toggle: A / RightShift - Panic: End
-- ===============================================================

local Players       = game:GetService("Players")
local UIS           = game:GetService("UserInputService")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local HttpService   = game:GetService("HttpService")

local player = Players.LocalPlayer
local mouse  = player:GetMouse()
local cam    = workspace.CurrentCamera
local PlayerGui = player:WaitForChild("PlayerGui")

-- ===============================================================
-- EXECUTOR CAPABILITY CHECK
-- ===============================================================
local CAP = {
    checkcaller    = (typeof(checkcaller) == "function"),
    hookmetamethod = (typeof(hookmetamethod) == "function"),
    drawing        = (typeof(Drawing) == "table" and typeof(Drawing.new) == "function"),
    vim            = (typeof(game:GetService("VirtualInputManager")) ~= "nil"),
    writefile      = (typeof(writefile) == "function"),
    readfile       = (typeof(readfile) == "function"),
    isfile         = (typeof(isfile) == "function"),
    getgenv        = (typeof(getgenv) == "function"),
}

-- ===============================================================
-- THEME
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

-- ===============================================================
-- STATE
-- ===============================================================
local S = {
    AimbotMode = "Off",
    FOV = 150, Hitbox = "Head", TargetPriority = "Crosshair",
    WallCheck = true, MaxDistance = 500, ShowFOV = true,
    TeamCheck = true, ShowTargetLock = true,
    
    Smoothness = 35, AimKey = "RightMouse",
    Humanize = true, JitterAmount = 8, MicroPause = true,
    
    FOVFilled = false, FOVRainbow = false, FOVPulse = false, FOVOnlyActive = false,
    
    AutoFire = false, AutoFireDelay = 0.05, RandomFireDelay = true,
    
    SafeMode = false, PropertySpoof = false,
    ShotLimiter = false, MaxShotRate = 8,
    
    ESP = false, ESP_Health = true, ESP_Distance = true, ESP_Tracers = false,
    ESP_TeamColor = true,
    
    Crosshair = false, CrosshairStyle = "Dot", CrosshairSize = 6,
    CrosshairColor = Color3.fromRGB(255, 60, 80),
    
    XRay = false, FPSBoost = false, AutoReload = false,
    
    UIScale = 100, Notif = true,
}

local origLight = {
    Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd, GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient,
}

-- ===============================================================
-- HELPERS
-- ===============================================================
local conns = {}
local function connect(sig, fn)
    local c = sig:Connect(fn); table.insert(conns, c); return c
end
local function mk(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    o.Parent = parent
    return o
end
local function corner(o, r) return mk("UICorner", {CornerRadius = UDim.new(0, r)}, o) end
local function stroke(o, color, th, tr)
    return mk("UIStroke", {Color = color, Thickness = th or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, o)
end
local function tween(o, props, t, style)
    TweenService:Create(o, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad), props):Play()
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
local function isMove(i)
    return i.UserInputType == Enum.UserInputType.MouseMovement
        or i.UserInputType == Enum.UserInputType.Touch
end
local function isSameTeam(plr)
    return player.Team ~= nil and plr.Team ~= nil and player.Team == plr.Team
end

-- ===============================================================
-- GUI ROOT
-- ===============================================================
local old = PlayerGui:FindFirstChild("UNITEDAim")
if old then old:Destroy() end
local gui = mk("ScreenGui", {
    Name = "UNITEDAim", ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true,
}, PlayerGui)

-- ===============================================================
-- NOTIFICATION
-- ===============================================================
local notifStack = 0
local function notify(text, kind)
    if not S.Notif then return end
    local color = T.accent
    if kind == "error" then color = T.danger
    elseif kind == "success" then color = T.success
    elseif kind == "warn" then color = T.warn end
    local offset = notifStack * 42
    notifStack = notifStack + 1
    local f = mk("Frame", {
        Size = UDim2.new(0, 280, 0, 36),
        Position = UDim2.new(0.5, -140, 0, -50 - offset),
        BackgroundColor3 = T.panel, BorderSizePixel = 0, ZIndex = 100 + notifStack,
    }, gui)
    corner(f, 8); stroke(f, color, 1.4, 0)
    mk("Frame", {Size = UDim2.new(0, 3, 1, 0), BackgroundColor3 = color, BorderSizePixel = 0, ZIndex = 101 + notifStack}, f)
    mk("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0), Position = UDim2.new(0, 12, 0, 0),
        BackgroundTransparency = 1, Text = text, TextColor3 = T.text,
        Font = Enum.Font.GothamMedium, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 102 + notifStack,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, f)
    tween(f, {Position = UDim2.new(0.5, -140, 0, 14 + offset)}, 0.25, Enum.EasingStyle.Back)
    task.delay(2, function()
        tween(f, {Position = UDim2.new(0.5, -140, 0, -50 - offset)}, 0.25)
        task.delay(0.3, function()
            f:Destroy()
            notifStack = math.max(0, notifStack - 1)
        end)
    end)
end

-- ===============================================================
-- DRAGGABLE
-- ===============================================================
local function makeDraggable(handle, target, onTap)
    local dragging, moved, start, startPos = false, false, nil, nil
    handle.InputBegan:Connect(function(i)
        if isTap(i) then
            dragging, moved = true, false
            start, startPos = i.Position, target.Position
            i.Changed:Connect(function()
                if i.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if not moved and onTap then onTap() end
                end
            end)
        end
    end)
    connect(UIS.InputChanged, function(i)
        if dragging and isMove(i) then
            local d = i.Position - start
            if d.Magnitude > 5 then moved = true end
            if moved then
                target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X,
                    startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
end

-- ===============================================================
-- MAIN WINDOW
-- ===============================================================
local Main = mk("Frame", {
    Size = UDim2.new(0, 590, 0, 450), AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0), BackgroundColor3 = T.bg,
    BorderSizePixel = 0, Visible = false, ClipsDescendants = true,
}, gui)
corner(Main, 14); stroke(Main, T.accent, 1.4, 0.4)
local uiScale = mk("UIScale", {Scale = 1}, Main)

local Title = mk("Frame", {Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = T.panel, BorderSizePixel = 0}, Main)
corner(Title, 14)
mk("Frame", {
    Size = UDim2.new(1, -32, 0, 2), Position = UDim2.new(0, 16, 1, -2),
    BackgroundColor3 = T.accent, BorderSizePixel = 0,
}, Title)
mk("TextLabel", {
    Size = UDim2.new(0.6, 0, 1, 0), Position = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1, RichText = true, TextXAlignment = Enum.TextXAlignment.Left,
    Text = "<b>UNITED</b>Aim  <font color='#8c919b' size='11'>v2.0.1</font>",
    TextColor3 = T.text, Font = Enum.Font.Gotham, TextSize = 16,
}, Title)
local fpsLabel = mk("TextLabel", {
    Size = UDim2.new(0, 80, 1, 0), Position = UDim2.new(1, -170, 0, 0),
    BackgroundTransparency = 1, Text = "FPS: -",
    TextColor3 = T.sub, Font = Enum.Font.GothamMedium, TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Title)
makeDraggable(Title, Main)

local CloseBtn = mk("TextButton", {
    Size = UDim2.new(0, 26, 0, 26), Position = UDim2.new(1, -34, 0, 7),
    BackgroundColor3 = T.danger, Text = "X", TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBold, TextSize = 13, AutoButtonColor = false,
}, Title)
corner(CloseBtn, 7)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

local Sidebar = mk("Frame", {
    Size = UDim2.new(0, 118, 1, -40), Position = UDim2.new(0, 0, 0, 40),
    BackgroundColor3 = T.panel, BorderSizePixel = 0,
}, Main)
mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, Sidebar)
mk("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, Sidebar)

local Content = mk("Frame", {
    Size = UDim2.new(1, -128, 1, -50), Position = UDim2.new(0, 120, 0, 46),
    BackgroundTransparency = 1,
}, Main)

-- ===============================================================
-- TAB SYSTEM
-- ===============================================================
local tabs, tabOrder, currentTab = {}, 0, nil

local function selectTab(name)
    currentTab = name
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.page.Visible = on
        tween(t.btn, {
            BackgroundColor3 = on and T.accent or T.card,
            TextColor3 = on and Color3.new(1, 1, 1) or T.sub,
        })
    end
end

local function addTab(name, icon)
    tabOrder = tabOrder + 1
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = T.card,
        Text = icon .. "  " .. name, TextColor3 = T.sub,
        Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
        LayoutOrder = tabOrder, TextXAlignment = Enum.TextXAlignment.Left,
    }, Sidebar)
    corner(btn, 8)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 10)}, btn)
    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 4,
        ScrollBarImageColor3 = T.accent, ScrollBarImageTransparency = 0.3,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
    }, Content)
    mk("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder}, page)
    mk("UIPadding", {PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8)}, page)
    local tab = {btn = btn, page = page, order = 0}
    tabs[name] = tab
    btn.MouseButton1Click:Connect(function() selectTab(name) end)
    return tab
end

local function reg(tab, frame)
    tab.order = tab.order + 1
    frame.LayoutOrder = tab.order
end

-- ===============================================================
-- COMPONENTS
-- ===============================================================
local function Section(tab, text)
    local l = mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1,
        Text = text:upper(), TextColor3 = T.accent, Font = Enum.Font.GothamBold,
        TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left,
    }, tab.page)
    mk("UIPadding", {PaddingLeft = UDim.new(0, 4)}, l)
    reg(tab, l)
end

local function Toggle(tab, name, desc, cb)
    local row = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, desc and 46 or 36),
        BackgroundColor3 = T.card, Text = "", AutoButtonColor = false,
    }, tab.page)
    corner(row, 8); stroke(row, T.stroke, 1, 0.6)
    mk("TextLabel", {
        Size = UDim2.new(1, -66, 0, 16), Position = UDim2.new(0, 12, 0, desc and 7 or 10),
        BackgroundTransparency = 1, Text = name, TextColor3 = T.text,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    if desc then
        mk("TextLabel", {
            Size = UDim2.new(1, -66, 0, 12), Position = UDim2.new(0, 12, 0, 25),
            BackgroundTransparency = 1, Text = desc, TextColor3 = T.sub,
            Font = Enum.Font.Gotham, TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
    end
    local sw = mk("Frame", {
        Size = UDim2.new(0, 38, 0, 18), Position = UDim2.new(1, -50, 0.5, -9),
        BackgroundColor3 = T.off, BorderSizePixel = 0,
    }, row)
    corner(sw, 9)
    local knob = mk("Frame", {
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, 2, 0.5, -7),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, sw)
    corner(knob, 7)
    local state = false
    local function set(v, silent)
        state = v
        tween(sw, {BackgroundColor3 = v and T.accent or T.off})
        tween(knob, {Position = v and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
        if not silent then
            local ok, err = pcall(cb, v)
            if not ok then warn("[UNITEDAim] Toggle error:", name, err) end
        end
    end
    row.MouseButton1Click:Connect(function() set(not state) end)
    row.MouseEnter:Connect(function() tween(row, {BackgroundColor3 = T.cardH}) end)
    row.MouseLeave:Connect(function() tween(row, {BackgroundColor3 = T.card}) end)
    reg(tab, row)
    return set
end

local function Slider(tab, name, min, max, default, cb, suffix)
    suffix = suffix or ""
    local row = mk("Frame", {Size = UDim2.new(1, 0, 0, 52), BackgroundColor3 = T.card}, tab.page)
    corner(row, 8); stroke(row, T.stroke, 1, 0.6)
    mk("TextLabel", {
        Size = UDim2.new(1, -90, 0, 16), Position = UDim2.new(0, 12, 0, 6),
        BackgroundTransparency = 1, Text = name, TextColor3 = T.text,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local val = mk("TextLabel", {
        Size = UDim2.new(0, 70, 0, 16), Position = UDim2.new(1, -82, 0, 6),
        BackgroundTransparency = 1, Text = default .. suffix, TextColor3 = T.accent,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local hit = mk("Frame", {
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 12, 0, 26),
        BackgroundTransparency = 1,
    }, row)
    local bar = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 6), Position = UDim2.new(0, 0, 0.5, -3),
        BackgroundColor3 = T.off, BorderSizePixel = 0,
    }, hit)
    corner(bar, 3)
    local a0 = (default - min) / (max - min)
    local fill = mk("Frame", {
        Size = UDim2.new(a0, 0, 1, 0), BackgroundColor3 = T.accent, BorderSizePixel = 0,
    }, bar)
    corner(fill, 3)
    mk("UIGradient", {Color = ColorSequence.new(T.accent, T.accent2)}, fill)
    local knob = mk("Frame", {
        Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(a0, -7, 0.5, -7),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
    }, bar)
    corner(knob, 7)
    local dragging = false
    local function setFromX(x)
        local a = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local v = math.floor(min + (max - min) * a + 0.5)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, -7, 0.5, -7)
        val.Text = v .. suffix
        local ok, err = pcall(cb, v)
        if not ok then warn("[UNITEDAim] Slider error:", name, err) end
    end
    hit.InputBegan:Connect(function(i) if isTap(i) then dragging = true; setFromX(i.Position.X) end end)
    connect(UIS.InputChanged, function(i) if dragging and isMove(i) then setFromX(i.Position.X) end end)
    connect(UIS.InputEnded, function(i) if isTap(i) then dragging = false end end)
    reg(tab, row)
end

local function Button(tab, name, cb, color)
    color = color or T.card
    local b = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 34), BackgroundColor3 = color,
        Text = name, TextColor3 = T.text, Font = Enum.Font.GothamBold,
        TextSize = 12, AutoButtonColor = false,
    }, tab.page)
    corner(b, 8); stroke(b, T.accent, 1, 0.5)
    b.MouseButton1Click:Connect(function()
        tween(b, {BackgroundColor3 = T.accent})
        task.delay(120, function() tween(b, {BackgroundColor3 = color}) end)
        local ok, err = pcall(cb)
        if not ok then notify("Error: " .. tostring(err), "error") end
    end)
    b.MouseEnter:Connect(function() tween(b, {BackgroundColor3 = T.cardH}, 0.1) end)
    b.MouseLeave:Connect(function() tween(b, {BackgroundColor3 = color}, 0.1) end)
    reg(tab, b)
end

local function RadioGroup(tab, label, options, default, onChange)
    if label ~= "" then Section(tab, label) end
    local row = mk("Frame", {Size = UDim2.new(1, 0, 0, #options * 36 + (#options - 1) * 6), BackgroundTransparency = 1}, tab.page)
    reg(tab, row)
    local btns = {}
    local function select(value, silent)
        for v, b in pairs(btns) do
            local on = (v == value)
            tween(b, {BackgroundColor3 = on and T.accent or T.card})
            b.TextColor3 = on and Color3.new(1, 1, 1) or T.sub
        end
        if not silent then
            local ok, err = pcall(onChange, value)
            if not ok then warn("[UNITEDAim] Radio error:", label, err) end
        end
    end
    for i, opt in ipairs(options) do
        local b = mk("TextButton", {
            Size = UDim2.new(1, 0, 0, 36), Position = UDim2.new(0, 0, 0, (i - 1) * 42),
            BackgroundColor3 = (opt.value == default) and T.accent or T.card,
            Text = "  " .. opt.label, TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = (opt.value == default) and Color3.new(1, 1, 1) or T.sub,
            Font = Enum.Font.GothamBold, TextSize = 12, AutoButtonColor = false,
        }, row)
        corner(b, 8); stroke(b, T.stroke, 1, 0.6)
        b.MouseButton1Click:Connect(function() select(opt.value) end)
        btns[opt.value] = b
    end
    return select
end

-- ===============================================================
-- UNIFIED HOOK MANAGER
-- ===============================================================
local hookInstalled = false
local hookError = nil
local oldIndexGlobal
local currentHumanoid

local function refreshHumanoid()
    local char = player.Character
    if char then
        currentHumanoid = char:FindFirstChildOfClass("Humanoid")
    else
        currentHumanoid = nil
    end
end
task.spawn(refreshHumanoid)
connect(player.CharacterAdded, function()
    task.wait(0.5)
    refreshHumanoid()
end)

local getTargetForHook

local function installUnifiedHook()
    if hookInstalled then return true end
    if not CAP.checkcaller then
        hookError = "checkcaller not supported (weak executor)"
        return false
    end
    if not CAP.hookmetamethod then
        hookError = "hookmetamethod not supported (weak executor)"
        return false
    end

    local ok, err = pcall(function()
        oldIndexGlobal = hookmetamethod(game, "__index", newcclosure(function(self, key)
            if checkcaller() then
                return oldIndexGlobal(self, key)
            end

            -- 1) PROPERTY SPOOF
            if S.PropertySpoof and currentHumanoid and self == currentHumanoid then
                if key == "WalkSpeed" then return 16 end
                if key == "JumpPower" then return 50 end
            end

            -- 2) SILENT AIM
            if S.AimbotMode == "Silent" and self == mouse then
                if key == "Hit" or key == "Target" then
                    local t = getTargetForHook and getTargetForHook()
                    if t then
                        if key == "Hit" then
                            local pos = t.pos
                            if S.Humanize then
                                local mag = math.random() * (S.JitterAmount * 0.012)
                                local ang = math.random() * math.pi * 2
                                pos = pos + Vector3.new(math.cos(ang) * mag, math.sin(ang) * mag, 0)
                            end
                            return CFrame.new(pos)
                        elseif key == "Target" then
                            return t.part
                        end
                    end
                end
            end

            return oldIndexGlobal(self, key)
        end))
    end)

    if ok then
        hookInstalled = true
        return true
    else
        hookError = tostring(err)
        warn("[UNITEDAim] Hook install failed:", err)
        return false
    end
end

-- ===============================================================
-- AIMBOT CORE
-- ===============================================================
local function getHitbox(char)
    if S.Hitbox == "Nearest" then
        local best, bestD = nil, math.huge
        local myPos = cam.CFrame.Position
        for _, p in ipairs(char:GetChildren()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                local d = (p.Position - myPos).Magnitude
                if d < bestD then bestD = d; best = p end
            end
        end
        return best
    elseif S.Hitbox == "Torso" then
        return char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
            or char:FindFirstChild("HumanoidRootPart")
    else
        return char:FindFirstChild("Head")
    end
end

local function isVisible(part)
    local origin = cam.CFrame.Position
    local dir = (part.Position - origin)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, cam}
    local res = workspace:Raycast(origin, dir, params)
    return res == nil or res.Instance:IsDescendantOf(part.Parent)
end

local function getTarget()
    local best, bestScore = nil, math.huge
    local myPos = cam.CFrame.Position
    local mPos = Vector2.new(mouse.X, mouse.Y)

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player and plr.Character then
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                local skip = false
                if S.TeamCheck and isSameTeam(plr) then skip = true end
                if not skip then
                    local part = getHitbox(plr.Character)
                    if part then
                        local dist = (part.Position - myPos).Magnitude
                        if dist <= S.MaxDistance then
                            if not S.WallCheck or isVisible(part) then
                                local screen, on = cam:WorldToViewportPoint(part.Position)
                                if on and screen.Z > 0 then
                                    local screen2D = Vector2.new(screen.X, screen.Y)
                                    local screenDist = (screen2D - mPos).Magnitude
                                    if screenDist <= S.FOV then
                                        local score
                                        if S.TargetPriority == "Distance" then score = dist
                                        elseif S.TargetPriority == "Health" then score = hum.Health
                                        else score = screenDist end
                                        if score < bestScore then
                                            bestScore = score
                                            best = {
                                                char = plr.Character, hum = hum,
                                                part = part, pos = part.Position,
                                                screen = screen2D, plr = plr,
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
    end
    return best
end

getTargetForHook = getTarget

local function isAimKeyDown()
    if S.AimKey == "Always" then return true end
    if S.AimKey == "LeftMouse" then return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) end
    return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
end

local jitterX, jitterY, jitterTimer = 0, 0, 0
local function updateJitter(dt)
    if not S.Humanize then return end
    jitterTimer = jitterTimer + dt
    if jitterTimer >= 0.09 then
        jitterTimer = 0
        local angle = math.random() * math.pi * 2
        local mag = math.random() * S.JitterAmount
        jitterX = math.cos(angle) * mag
        jitterY = math.sin(angle) * mag
    end
end

local shotHistory = {}
local function canShoot()
    if not S.ShotLimiter then return true end
    local now = tick()
    while #shotHistory > 0 and now - shotHistory[1] > 1 do
        table.remove(shotHistory, 1)
    end
    return #shotHistory < S.MaxShotRate
end
local function recordShot() table.insert(shotHistory, tick()) end

local fireCooldown = 0
local function fireShot()
    if not canShoot() then return end
    local actualDelay = S.AutoFireDelay
    if S.RandomFireDelay then
        actualDelay = S.AutoFireDelay * (0.6 + math.random() * 0.8)
    end
    if tick() - fireCooldown < actualDelay then return end
    fireCooldown = tick()
    recordShot()
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, true, game, 1)
        task.wait(0.02)
        vim:SendMouseButtonEvent(mouse.X, mouse.Y, 0, false, game, 1)
    end)
end

local function legitAim(dt)
    if not isAimKeyDown() then return end
    local t = getTarget()
    if not t then return end
    if S.MicroPause and math.random() < 0.03 then return end

    updateJitter(dt)
    local targetPos = t.pos
    if S.Humanize then
        local camCF = cam.CFrame
        targetPos = targetPos
            + camCF.RightVector * (jitterX * 0.008)
            + camCF.UpVector * (jitterY * 0.008)
    end

    local current = cam.CFrame
    local targetCF = CFrame.new(current.Position, targetPos)
    local a = math.clamp(1 - (S.Smoothness / 100), 0.02, 1)
    local alpha = math.min(1, a * dt * 60)
    cam.CFrame = current:Lerp(targetCF, alpha)
end

local function rageAim()
    local t = getTarget()
    if not t then return end
    local targetPos = t.pos
    if S.Humanize then
        local mag = math.random() * (S.JitterAmount * 0.015)
        local ang = math.random() * math.pi * 2
        targetPos = targetPos + Vector3.new(math.cos(ang) * mag, math.sin(ang) * mag, 0)
    end
    cam.CFrame = CFrame.new(cam.CFrame.Position, targetPos)
end

connect(RunService.RenderStepped, function(dt)
    cam = workspace.CurrentCamera
    if not cam then return end

    if S.AimbotMode == "Legit" then
        local ok, err = pcall(legitAim, dt)
        if not ok then warn("[UNITEDAim] Legit Aim error:", err) end
    elseif S.AimbotMode == "Rage" then
        local ok, err = pcall(rageAim)
        if not ok then warn("[UNITEDAim] Rage Aim error:", err) end
    end

    if S.AutoFire and (S.AimbotMode == "Silent" or S.AimbotMode == "Rage") then
        local t = getTarget()
        if t then pcall(fireShot) end
    end
end)

-- ===============================================================
-- DRAWING: FOV, TARGET LOCK, CROSSHAIR
-- ===============================================================
local fovCircle, targetLock, crosshairDot, crosshairCircle, crossH1, crossV1

if CAP.drawing then
    pcall(function()
        fovCircle = Drawing.new("Circle")
        fovCircle.Thickness = 1.5
        fovCircle.Color = T.accent
        fovCircle.Filled = false
        fovCircle.NumSides = 60
        fovCircle.Transparency = 1
        fovCircle.Visible = false

        targetLock = Drawing.new("Circle")
        targetLock.Thickness = 2
        targetLock.Color = Color3.fromRGB(255, 240, 90)
        targetLock.Filled = false
        targetLock.NumSides = 24
        targetLock.Transparency = 1
        targetLock.Radius = 14
        targetLock.Visible = false

        crosshairDot = Drawing.new("Circle")
        crosshairDot.Thickness = 0
        crosshairDot.Filled = true
        crosshairDot.Radius = 3
        crosshairDot.Color = S.CrosshairColor
        crosshairDot.Visible = false

        crosshairCircle = Drawing.new("Circle")
        crosshairCircle.Thickness = 1.5
        crosshairCircle.Filled = false
        crosshairCircle.Radius = 10
        crosshairCircle.Color = S.CrosshairColor
        crosshairCircle.Visible = false

        crossH1 = Drawing.new("Line")
        crossH1.Thickness = 1.5
        crossH1.Color = S.CrosshairColor
        crossH1.Visible = false
        crossV1 = Drawing.new("Line")
        crossV1.Thickness = 1.5
        crossV1.Color = S.CrosshairColor
        crossV1.Visible = false
    end)
end

local fovPulseTime = 0
connect(RunService.RenderStepped, function(dt)
    cam = workspace.CurrentCamera
    if not cam then return end
    local mPos = Vector2.new(mouse.X, mouse.Y)

    -- FOV Circle
    if fovCircle then
        local show = S.ShowFOV and (S.AimbotMode ~= "Off")
        if S.FOVOnlyActive then show = show and isAimKeyDown() end
        fovCircle.Visible = show
        if show then
            fovCircle.Position = mPos
            local radius = S.FOV
            if S.FOVPulse then
                fovPulseTime = fovPulseTime + dt * 3
                radius = S.FOV + math.sin(fovPulseTime) * 8
            end
            fovCircle.Radius = radius
            fovCircle.Filled = S.FOVFilled
            fovCircle.Transparency = S.FOVFilled and 0.15 or 1
            if S.FOVRainbow then
                fovCircle.Color = Color3.fromHSV((tick() * 0.35) % 1, 1, 1)
            else
                fovCircle.Color = T.accent
            end
        end
    end

    -- Target Lock
    if targetLock then
        local show = S.ShowTargetLock and S.AimbotMode ~= "Off"
        if show then
            local t = getTarget()
            if t then
                local sp, on = cam:WorldToViewportPoint(t.pos)
                if on and sp.Z > 0 then
                    targetLock.Position = Vector2.new(sp.X, sp.Y)
                    targetLock.Radius = 14 + math.sin(tick() * 8) * 2
                    targetLock.Visible = true
                else
                    targetLock.Visible = false
                end
            else
                targetLock.Visible = false
            end
        else
            targetLock.Visible = false
        end
    end

    -- Crosshair
    local chShow = S.Crosshair
    if crosshairDot then crosshairDot.Visible = chShow and S.CrosshairStyle == "Dot" end
    if crosshairCircle then crosshairCircle.Visible = chShow and S.CrosshairStyle == "Circle" end
    if crossH1 then crossH1.Visible = chShow and S.CrosshairStyle == "Cross" end
    if crossV1 then crossV1.Visible = chShow and S.CrosshairStyle == "Cross" end

    if chShow then
        local size = S.CrosshairSize
        if S.CrosshairStyle == "Dot" and crosshairDot then
            crosshairDot.Position = mPos
            crosshairDot.Radius = size * 0.4
            crosshairDot.Color = S.CrosshairColor
        elseif S.CrosshairStyle == "Circle" and crosshairCircle then
            crosshairCircle.Position = mPos
            crosshairCircle.Radius = size
            crosshairCircle.Color = S.CrosshairColor
        elseif S.CrosshairStyle == "Cross" then
            local len = size
            if crossH1 then
                crossH1.From = Vector2.new(mPos.X - len, mPos.Y)
                crossH1.To = Vector2.new(mPos.X + len, mPos.Y)
                crossH1.Color = S.CrosshairColor
            end
            if crossV1 then
                crossV1.From = Vector2.new(mPos.X, mPos.Y - len)
                crossV1.To = Vector2.new(mPos.X, mPos.Y + len)
                crossV1.Color = S.CrosshairColor
            end
        end
    end
end)

-- ===============================================================
-- ESP
-- ===============================================================
local espData = {}
local function createESP(plr)
    if plr == player or espData[plr] then return end
    if not CAP.drawing then return end
    local data = {
        box = Drawing.new("Square"),
        name = Drawing.new("Text"),
        health = Drawing.new("Line"),
        dist = Drawing.new("Text"),
        tracer = Drawing.new("Line"),
    }
    data.box.Thickness = 1.4
    data.box.Filled = false
    data.name.Size = 14; data.name.Center = true; data.name.Outline = true
    data.name.Color = Color3.new(1, 1, 1); data.name.Font = 2
    data.dist.Size = 12; data.dist.Center = true; data.dist.Outline = true
    data.dist.Color = T.accent2; data.dist.Font = 2
    data.health.Thickness = 2; data.health.Color = T.success
    data.tracer.Thickness = 1; data.tracer.Color = T.accent
    espData[plr] = data
end
local function destroyESP(plr)
    local d = espData[plr]
    if d then
        for _, o in pairs(d) do pcall(function() o:Remove() end) end
        espData[plr] = nil
    end
end
local function updateESP()
    if not CAP.drawing then return end
    if not S.ESP then
        for _, d in pairs(espData) do
            for _, o in pairs(d) do o.Visible = false end
        end
        return
    end
    local myPos = cam.CFrame.Position
    local screenBottom = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= player then
            if not espData[plr] then createESP(plr) end
            local d = espData[plr]
            if d then
                local char = plr.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local head = char and char:FindFirstChild("Head")
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and head and hrp then
                    local headPos, onH = cam:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
                    local legPos, onL = cam:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                    if onH and onL and headPos.Z > 0 then
                        local h = math.abs(legPos.Y - headPos.Y)
                        local w = h * 0.55
                        local x = headPos.X - w / 2
                        local y = headPos.Y
                        d.box.Size = Vector2.new(w, h)
                        d.box.Position = Vector2.new(x, y)
                        d.box.Visible = true
                        if S.ESP_TeamColor and player.Team and plr.Team then
                            d.box.Color = (plr.Team == player.Team) and Color3.fromRGB(70, 210, 120) or T.accent
                        else
                            d.box.Color = T.accent
                        end
                        d.name.Text = plr.Name
                        d.name.Position = Vector2.new(x + w / 2, y - 16)
                        d.name.Visible = true
                        if S.ESP_Distance then
                            local dist = (hrp.Position - myPos).Magnitude
                            d.dist.Text = string.format("[%dm]", math.floor(dist))
                            d.dist.Position = Vector2.new(x + w / 2, y + h + 2)
                            d.dist.Visible = true
                        else d.dist.Visible = false end
                        if S.ESP_Health then
                            local hp = hum.Health / hum.MaxHealth
                            d.health.From = Vector2.new(x - 4, y + h * (1 - hp))
                            d.health.To = Vector2.new(x - 4, y + h)
                            d.health.Color = hp > 0.6 and T.success or (hp > 0.3 and T.warn or T.danger)
                            d.health.Visible = true
                        else d.health.Visible = false end
                        if S.ESP_Tracers then
                            d.tracer.From = screenBottom
                            d.tracer.To = Vector2.new(x + w / 2, y + h)
                            d.tracer.Visible = true
                        else d.tracer.Visible = false end
                    else
                        for _, o in pairs(d) do o.Visible = false end
                    end
                else
                    for _, o in pairs(d) do o.Visible = false end
                end
            end
        end
    end
    for plr in pairs(espData) do
        if not plr.Parent then destroyESP(plr) end
    end
end
connect(RunService.RenderStepped, updateESP)
connect(Players.PlayerRemoving, destroyESP)

-- ===============================================================
-- X-RAY, FPS BOOST, AUTO RELOAD
-- ===============================================================
local function setXRay(on)
    task.spawn(function()
        local n = 0
        for _, o in ipairs(workspace:GetDescendants()) do
            if o:IsA("BasePart") and not (o.Parent and o.Parent:FindFirstChildOfClass("Humanoid")) then
                pcall(function() o.LocalTransparencyModifier = on and 0.7 or 0 end)
                n = n + 1
                if n % 500 == 0 then task.wait() end
            end
        end
    end)
end

local function setFPSBoost(on)
    if on then
        Lighting.Brightness = 1
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 1e6
        Lighting.Ambient = Color3.fromRGB(120, 120, 120)
        Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") or v:IsA("Atmosphere") or v:IsA("Sky") then
                pcall(function() v.Enabled = false end)
            end
        end
        task.spawn(function()
            local n = 0
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
                   or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
                    pcall(function() obj.Enabled = false end)
                    n = n + 1
                    if n % 200 == 0 then task.wait() end
                end
            end
        end)
    else
        for k, v in pairs(origLight) do Lighting[k] = v end
        task.spawn(function()
            for _, obj in ipairs(workspace:GetDescendants()) do
                if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke")
                   or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Beam") then
                    pcall(function() obj.Enabled = true end)
                end
            end
        end)
    end
end

local function pressKey(key)
    return pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendKeyEvent(true, key, false, game)
        task.wait(0.05)
        vim:SendKeyEvent(false, key, false, game)
    end)
end

connect(RunService.Heartbeat, function()
    if not S.AutoReload then return end
    local char = player.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    for _, c in ipairs(tool:GetDescendants()) do
        if c:IsA("NumberValue") or c:IsA("IntValue") then
            local n = c.Name:lower()
            if (n:find("ammo") or n:find("clip") or n:find("mag")) and c.Value <= 0 then
                pressKey(Enum.KeyCode.R); task.wait(0.3); break
            end
        end
    end
end)

-- ===============================================================
-- BYPASS: SCANNER, SAFE MODE, CONFIG
-- ===============================================================
local function scanAntiCheat()
    local found = {}
    local roots = {player.PlayerScripts, player.Character, workspace}
    for _, root in ipairs(roots) do
        if root and root.Parent ~= nil then
            for _, obj in ipairs(root:GetDescendants()) do
                if obj:IsA("LocalScript") or obj:IsA("Script") then
                    local n = obj.Name:lower()
                    if n:find("anticheat") or n:find("anti_cheat") or n:find("ac_")
                       or n:find("detect") or n:find("shield") or n:find("guard")
                       or n:find("monitor") or n:find("protect") or n:find("flag") then
                        table.insert(found, obj:GetFullName())
                    end
                end
            end
        end
    end
    if #found > 0 then
        notify("[!] Anti-cheat found: " .. #found .. " scripts", "warn")
        for i = 1, math.min(#found, 6) do warn("[UNITEDAim] AC: " .. found[i]) end
    else
        notify("[OK] No anti-cheat detected", "success")
    end
    return found
end

local setSafeMode
local modeSelector

local CONFIG_PATH = "UNITEDAim_config.json"

local function saveConfig()
    if not CAP.writefile then
        notify("Executor does not support writefile", "error"); return
    end
    local data = {}
    for k, v in pairs(S) do
        local tv = type(v)
        if tv == "number" or tv == "boolean" or tv == "string" then
            data[k] = v
        end
    end
    local ok = pcall(function()
        writefile(CONFIG_PATH, HttpService:JSONEncode(data))
    end)
    notify(ok and "[OK] Config saved" or "[X] Failed to save config", ok and "success" or "error")
end

local function loadConfig()
    if not (CAP.readfile and CAP.isfile) then
        notify("Executor does not support config", "error"); return
    end
    if not isfile(CONFIG_PATH) then
        notify("No config file found", "warn"); return
    end
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_PATH))
    end)
    if not ok or not data then
        notify("Config corrupt", "error"); return
    end
    for k, v in pairs(data) do
        if S[k] ~= nil then S[k] = v end
    end
    notify("[OK] Config loaded (some features need restart)", "success")
end

-- ===============================================================
-- BUILD TABS
-- ===============================================================
local tAim    = addTab("Aimbot",  "AIM")
local tESP    = addTab("ESP",     "ESP")
local tVisual = addTab("Visual",  "VIS")
local tBypass = addTab("Bypass",  "BYP")
local tSet    = addTab("Setting", "SET")

-- AIMBOT TAB
modeSelector = RadioGroup(tAim, "Aimbot Mode (Exclusive)",
    {
        {label = "[X] Off",        value = "Off"},
        {label = "[1] Legit Aim",  value = "Legit"},
        {label = "[2] Silent Aim", value = "Silent"},
        {label = "[3] Rage Aim",   value = "Rage"},
    }, "Off", function(v)
        if S.SafeMode and (v == "Silent" or v == "Rage") then
            notify("Safe Mode is ON - using Legit Aim", "warn")
            modeSelector("Legit")
            return
        end
        if v == "Silent" then
            local ok, err = installUnifiedHook()
            if not ok then
                notify("Silent failed: " .. tostring(err or hookError), "error")
                modeSelector("Off")
                return
            end
        end
        S.AimbotMode = v
        notify("Aimbot: " .. v, v == "Off" and nil or "success")
    end)

Section(tAim, "Common Settings")
Slider(tAim, "FOV Radius", 30, 500, S.FOV, function(v) S.FOV = v end, "px")
Slider(tAim, "Max Distance", 50, 2000, S.MaxDistance, function(v) S.MaxDistance = v end, "m")
Toggle(tAim, "Show FOV Circle", nil, function(v) S.ShowFOV = v end)
Toggle(tAim, "Wall Check", "Ignore targets behind walls", function(v) S.WallCheck = v end)
Toggle(tAim, "Team Check", "Ignore teammates", function(v) S.TeamCheck = v end)
Toggle(tAim, "Target Lock Indicator", "Yellow circle on locked target", function(v) S.ShowTargetLock = v end)

Section(tAim, "FOV Circle Style")
Toggle(tAim, "Filled", nil, function(v) S.FOVFilled = v end)
Toggle(tAim, "Rainbow", nil, function(v) S.FOVRainbow = v end)
Toggle(tAim, "Pulse", nil, function(v) S.FOVPulse = v end)
Toggle(tAim, "Show Only When Aiming", nil, function(v) S.FOVOnlyActive = v end)

Section(tAim, "Target Priority")
RadioGroup(tAim, "", {
    {label = "Nearest to Crosshair", value = "Crosshair"},
    {label = "Lowest Health",        value = "Health"},
    {label = "Closest Distance",     value = "Distance"},
}, "Crosshair", function(v) S.TargetPriority = v end)

Section(tAim, "Hitbox Priority")
RadioGroup(tAim, "", {
    {label = "Head",    value = "Head"},
    {label = "Torso",   value = "Torso"},
    {label = "Nearest", value = "Nearest"},
}, "Head", function(v) S.Hitbox = v end)

Section(tAim, "Legit Aim")
Slider(tAim, "Smoothness", 1, 100, S.Smoothness, function(v) S.Smoothness = v end, "%")
RadioGroup(tAim, "Activation", {
    {label = "Right Mouse (hold)", value = "RightMouse"},
    {label = "Left Mouse (hold)",  value = "LeftMouse"},
    {label = "Always",             value = "Always"},
}, "RightMouse", function(v) S.AimKey = v end)

Section(tAim, "Humanizer")
Toggle(tAim, "Aim Humanization", "Jitter + micro-pause", function(v) S.Humanize = v end)
Slider(tAim, "Jitter Amount", 0, 30, S.JitterAmount, function(v) S.JitterAmount = v end, "px")
Toggle(tAim, "Micro Pause", "Occasional skip frame", function(v) S.MicroPause = v end)

Section(tAim, "Silent / Rage")
Toggle(tAim, "Auto Fire", "Shoot automatically", function(v) S.AutoFire = v end)
Slider(tAim, "Fire Delay", 1, 50, math.floor(S.AutoFireDelay * 1000), function(v) S.AutoFireDelay = v / 1000 end, "ms")
Toggle(tAim, "Random Fire Delay", "Vary timing", function(v) S.RandomFireDelay = v end)

-- ESP TAB
Section(tESP, "Player ESP")
Toggle(tESP, "Player Box", "2D box around players", function(v)
    S.ESP = v
    if not v then for p in pairs(espData) do destroyESP(p) end end
end)
Toggle(tESP, "Health Bar", nil, function(v) S.ESP_Health = v end)
Toggle(tESP, "Distance", nil, function(v) S.ESP_Distance = v end)
Toggle(tESP, "Tracer Lines", nil, function(v) S.ESP_Tracers = v end)
Toggle(tESP, "Team Color", "Green = team, Red = enemy", function(v) S.ESP_TeamColor = v end)

-- VISUAL TAB
Section(tVisual, "Crosshair")
Toggle(tVisual, "Custom Crosshair", "Extra crosshair overlay", function(v) S.Crosshair = v end)
RadioGroup(tVisual, "Style", {
    {label = "Dot",    value = "Dot"},
    {label = "Cross",  value = "Cross"},
    {label = "Circle", value = "Circle"},
}, "Dot", function(v) S.CrosshairStyle = v end)
Slider(tVisual, "Size", 3, 30, S.CrosshairSize, function(v) S.CrosshairSize = v end, "px")
Button(tVisual, "Cycle Color", function()
    local hues = {0, 0.33, 0.55, 0.85, 0.16}
    local cur = tick() % #hues
    S.CrosshairColor = Color3.fromHSV(hues[math.floor(cur) + 1], 1, 1)
    notify("Crosshair color changed", "success")
end)

Section(tVisual, "Map")
Toggle(tVisual, "X-Ray", "Transparent map (local)", function(v) S.XRay = v; setXRay(v) end)
Toggle(tVisual, "FPS Boost", "Disable heavy effects", function(v) S.FPSBoost = v; setFPSBoost(v) end)

Section(tVisual, "Combat")
Toggle(tVisual, "Auto Reload", "Press R when ammo is empty", function(v) S.AutoReload = v end)
Button(tVisual, "Force Reload", function() pressKey(Enum.KeyCode.R); notify("Reloaded", "success") end)
Button(tVisual, "Reset Lighting", function()
    for k, v in pairs(origLight) do Lighting[k] = v end
    notify("Lighting reset", "success")
end)

-- BYPASS TAB
setSafeMode = function(on)
    S.SafeMode = on
    if on then
        if S.AimbotMode ~= "Legit" and S.AimbotMode ~= "Off" then
            S.AimbotMode = "Legit"
            if modeSelector then modeSelector("Legit", true) end
        end
        S.AutoFire = false
        S.RandomFireDelay = true
        S.Humanize = true
        if S.Smoothness < 25 then S.Smoothness = 25 end
        notify("Safe Mode ON - restrictions applied", "warn")
    else
        notify("Safe Mode OFF")
    end
end

Section(tBypass, "Safety Mode")
Toggle(tBypass, "Safe Mode", "Force Legit, disable AutoFire", function(v) setSafeMode(v) end)
Toggle(tBypass, "Property Spoofing", "Spoof WalkSpeed/JumpPower (unified hook)", function(v)
    if v and not CAP.checkcaller then
        notify("Executor not supported", "error")
        return
    end
    if v and not hookInstalled then
        local ok, err = installUnifiedHook()
        if not ok then
            notify("Hook failed: " .. tostring(err), "error")
            return
        end
    end
    S.PropertySpoof = v
    notify("Property Spoofing: " .. (v and "ON" or "OFF"), v and "success" or nil)
end)

Section(tBypass, "Rate Limiting")
Toggle(tBypass, "Shot Limiter", "Limit shots per second", function(v) S.ShotLimiter = v end)
Slider(tBypass, "Max Shot Rate", 1, 30, S.MaxShotRate, function(v) S.MaxShotRate = v end, "/s")

Section(tBypass, "Anti-Cheat Scanner")
Button(tBypass, "Scan Anti-Cheat", function() scanAntiCheat() end, Color3.fromRGB(50, 50, 70))

Section(tBypass, "Info")
local bypassInfo = mk("TextLabel", {
    Size = UDim2.new(1, 0, 0, 120), BackgroundTransparency = 1,
    Text = "Property Spoofing & Silent Aim use UNIFIED HOOK\n" ..
           "  -> can run simultaneously without conflict.\n" ..
           "Safe Mode  : forces Legit, prevents patterns\n" ..
           "Humanizer  : natural aim movement\n" ..
           "Shot Limit : prevents impossible shot patterns\n" ..
           "Client bypass != server bypass. Play safe.",
    TextColor3 = T.sub, Font = Enum.Font.Gotham, TextSize = 10,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, tBypass.page)
mk("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, bypassInfo)
reg(tBypass, bypassInfo)

-- SETTING TAB
Section(tSet, "UI")
Slider(tSet, "UI Scale", 60, 140, S.UIScale, function(v)
    S.UIScale = v; uiScale.Scale = v / 100
end, "%")
Toggle(tSet, "Notifications", nil, function(v) S.Notif = v end)

Section(tSet, "Config")
Button(tSet, "Save Config", function() saveConfig() end, Color3.fromRGB(40, 70, 50))
Button(tSet, "Load Config", function() loadConfig() end, Color3.fromRGB(40, 50, 70))

Section(tSet, "Help")
local infoLabel = mk("TextLabel", {
    Size = UDim2.new(1, 0, 0, 90), BackgroundTransparency = 1,
    Text = "Toggle panel: A / RightShift\n" ..
           "Panic: End (disable all instantly)\n" ..
           "Silent/Rage exclusive - pick one.\n" ..
           "Silent + Spoof safe together (unified hook).",
    TextColor3 = T.sub, Font = Enum.Font.Gotham, TextSize = 11,
    TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, tSet.page)
mk("UIPadding", {PaddingLeft = UDim.new(0, 8)}, infoLabel)
reg(tSet, infoLabel)

Section(tSet, "Danger Zone")
Button(tSet, "PANIC - Disable All", function()
    S.AimbotMode = "Off"; S.ESP = false; S.XRay = false; S.FPSBoost = false
    S.AutoFire = false; S.AutoReload = false; S.ShotLimiter = false
    S.Crosshair = false
    if modeSelector then modeSelector("Off", true) end
    for p in pairs(espData) do destroyESP(p) end
    setXRay(false); setFPSBoost(false)
    notify("PANIC - all features disabled", "warn")
end, Color3.fromRGB(75, 20, 30))
Button(tSet, "Unload Panel", function()
    S.AimbotMode = "Off"
    for p in pairs(espData) do destroyESP(p) end
    setXRay(false); setFPSBoost(false)
    for k, v in pairs(origLight) do Lighting[k] = v end
    for _, obj in ipairs({fovCircle, targetLock, crosshairDot, crosshairCircle, crossH1, crossV1}) do
        if obj then pcall(function() obj:Remove() end) end
    end
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    gui:Destroy()
end, Color3.fromRGB(90, 25, 35))

-- ===============================================================
-- FPS COUNTER & FLOATING BUTTON
-- ===============================================================
local fpsCount, fpsLast = 0, tick()
connect(RunService.RenderStepped, function()
    fpsCount = fpsCount + 1
    if tick() - fpsLast >= 1 then
        fpsLabel.Text = "FPS: " .. fpsCount
        fpsCount = 0
        fpsLast = tick()
    end
end)

local Float = mk("TextButton", {
    Size = UDim2.new(0, 54, 0, 54), Position = UDim2.new(0, 16, 0.5, -27),
    BackgroundColor3 = T.accent, Text = "A",
    TextColor3 = Color3.new(1, 1, 1), Font = Enum.Font.GothamBlack, TextSize = 26,
    AutoButtonColor = false, ZIndex = 5,
}, gui)
corner(Float, 27)
stroke(Float, T.accent2, 2, 0.4)
mk("UIGradient", {Color = ColorSequence.new(T.accent, T.accent2), Rotation = 45}, Float)
makeDraggable(Float, Float, function() Main.Visible = not Main.Visible end)

connect(UIS.InputBegan, function(i, gp)
    if gp then return end
    if i.KeyCode == Enum.KeyCode.RightShift or i.KeyCode == Enum.KeyCode.A then
        Main.Visible = not Main.Visible
    end
    if i.KeyCode == Enum.KeyCode.End then
        S.AimbotMode = "Off"; S.ESP = false
        S.XRay = false; S.FPSBoost = false; S.AutoFire = false
        S.AutoReload = false; S.Crosshair = false
        if modeSelector then modeSelector("Off", true) end
        for p in pairs(espData) do destroyESP(p) end
        setXRay(false); setFPSBoost(false)
        notify("PANIC - all features disabled", "warn")
    end
end)

-- ===============================================================
-- INIT
-- ===============================================================
task.spawn(function()
    installUnifiedHook()
end)

selectTab("Aimbot")
Main.Visible = true

local capMsg = ""
if not CAP.drawing then capMsg = " (Drawing not supported - ESP/FOV disabled)" end
if not CAP.checkcaller or not CAP.hookmetamethod then
    capMsg = " (Weak executor - Silent/Spoof disabled)"
end
notify("UNITEDAim v2.0.1 ready" .. capMsg, capMsg ~= "" and "warn" or "success")