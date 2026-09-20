--[[
╔══════════════════════════════════════════════════════════════════╗
║               MODULAR UI FRAMEWORK  v1.0                        ║
║           by ModularUI | Built for extensibility                 ║
║                                                                  ║
║  HOW TO ADD A SCRIPT:                                            ║
║  1. Open the Dev tab (bottom left)                               ║
║  2. Pick a tab or create one                                     ║
║  3. Add a control (Button / Toggle / Slider / Input)             ║
║  4. Paste your script code into the code editor                  ║
║  5. Hit Save — it activates immediately                          ║
║                                                                  ║
║  HOW TO ADD FROM EXTERNAL AI:                                    ║
║  Just ask AI: "write a roblox localscript function that [...]"   ║
║  Then paste the returned function body into the Dev code editor.  ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ════════════════════════════════════════════════
--              SERVICES
-- ════════════════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local TweenService       = game:GetService("TweenService")
local UserInputService   = game:GetService("UserInputService")
local SoundService       = game:GetService("SoundService")

local LocalPlayer        = Players.LocalPlayer
local PlayerGui          = LocalPlayer:WaitForChild("PlayerGui")
local Mouse              = LocalPlayer:GetMouse()

-- ════════════════════════════════════════════════
--              THEME
-- ════════════════════════════════════════════════
local Theme = {
    -- Backgrounds
    BG          = Color3.fromRGB(10,  11,  16),
    Panel       = Color3.fromRGB(16,  18,  26),
    Card        = Color3.fromRGB(22,  25,  36),
    CardHover   = Color3.fromRGB(28,  32,  46),
    
    -- Accents
    Accent      = Color3.fromRGB(99,  102, 241),   -- indigo-500
    AccentHover = Color3.fromRGB(129, 132, 255),
    AccentGlow  = Color3.fromRGB(99,  102, 241),
    Success     = Color3.fromRGB(52,  211, 153),   -- emerald
    Warning     = Color3.fromRGB(251, 191, 36),    -- amber
    Danger      = Color3.fromRGB(239, 68,  68),    -- red
    
    -- Text
    TextPrimary   = Color3.fromRGB(237, 237, 250),
    TextSecondary = Color3.fromRGB(148, 148, 180),
    TextMuted     = Color3.fromRGB(80,  80,  110),
    
    -- Controls
    InputBG     = Color3.fromRGB(12,  13,  20),
    Border      = Color3.fromRGB(38,  40,  60),
    BorderFocus = Color3.fromRGB(99,  102, 241),
    
    -- Toggles
    ToggleOff   = Color3.fromRGB(45,  47,  65),
    ToggleOn    = Color3.fromRGB(99,  102, 241),
    
    -- Tab bar
    TabActive   = Color3.fromRGB(99,  102, 241),
    TabInactive = Color3.fromRGB(0,   0,   0),
}

-- ════════════════════════════════════════════════
--              SOUND LIBRARY
-- ════════════════════════════════════════════════
local SoundIDs = {
    Click     = 6895079853,
    Toggle    = 4590662766,
    Notify    = 5607706316,
    Error     = 9119713951,
    Success   = 5607545950,
    Open      = 6895079853,
    Slider    = 3741563240,
    TabSwitch = 4590662766,
    KeyTick   = 9881637106,
}

local function PlaySound(id, volume, pitch)
    local ok, s = pcall(function()
        local snd = Instance.new("Sound")
        snd.SoundId  = "rbxassetid://" .. tostring(id)
        snd.Volume   = volume or 0.35
        snd.PlaybackSpeed = pitch or 1
        snd.Parent   = SoundService
        snd:Play()
        game:GetService("Debris"):AddItem(snd, 3)
    end)
end

-- ════════════════════════════════════════════════
--              TWEEN HELPERS
-- ════════════════════════════════════════════════
local function Tween(obj, props, t, style, dir)
    local info = TweenInfo.new(
        t or 0.18,
        style or Enum.EasingStyle.Quart,
        dir   or Enum.EasingDirection.Out
    )
    local tw = TweenService:Create(obj, info, props)
    tw:Play()
    return tw
end

local function SpringTween(obj, props, t)
    return Tween(obj, props, t or 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ════════════════════════════════════════════════
--              UTILITY
-- ════════════════════════════════════════════════
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        inst[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function Ripple(button, x, y)
    local rip = Create("Frame", {
        Size              = UDim2.new(0, 0, 0, 0),
        Position          = UDim2.new(0, x - button.AbsolutePosition.X,
                                      0, y - button.AbsolutePosition.Y),
        BackgroundColor3  = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 0.75,
        BorderSizePixel   = 0,
        ZIndex            = button.ZIndex + 10,
        Parent            = button,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = rip})
    
    local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
    Tween(rip, {
        Size = UDim2.new(0, size, 0, size),
        Position = UDim2.new(0, x - button.AbsolutePosition.X - size/2,
                             0, y - button.AbsolutePosition.Y - size/2),
        BackgroundTransparency = 1,
    }, 0.55)
    game:GetService("Debris"):AddItem(rip, 0.6)
end

-- ════════════════════════════════════════════════
--              NOTIFICATION SYSTEM
-- ════════════════════════════════════════════════
local NotifyContainer
local NotifyQueue = {}
local NotifyActive = 0
local MAX_NOTIFS = 5

local function InitNotifications(screenGui)
    NotifyContainer = Create("Frame", {
        Name              = "NotifyContainer",
        Size              = UDim2.new(0, 320, 1, 0),
        Position          = UDim2.new(1, -330, 0, 0),
        BackgroundTransparency = 1,
        AnchorPoint       = Vector2.new(0, 0),
        Parent            = screenGui,
    })
    Create("UIListLayout", {
        SortOrder         = Enum.SortOrder.LayoutOrder,
        Padding           = UDim.new(0, 8),
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Parent            = NotifyContainer,
    })
    Create("UIPadding", {
        PaddingBottom = UDim.new(0, 14),
        PaddingRight  = UDim.new(0, 8),
        Parent        = NotifyContainer,
    })
end

local function Notify(title, msg, ntype, duration)
    ntype    = ntype    or "info"
    duration = duration or 4

    local iconMap = {info="ℹ", success="✓", warning="⚠", error="✕"}
    local colorMap = {
        info    = Theme.Accent,
        success = Theme.Success,
        warning = Theme.Warning,
        error   = Theme.Danger,
    }
    local soundMap = {
        info    = SoundIDs.Notify,
        success = SoundIDs.Success,
        warning = SoundIDs.Notify,
        error   = SoundIDs.Error,
    }

    PlaySound(soundMap[ntype] or SoundIDs.Notify, 0.4)

    local accent = colorMap[ntype] or Theme.Accent

    local card = Create("Frame", {
        Name              = "Notif_" .. os.clock(),
        Size              = UDim2.new(1, 0, 0, 70),
        BackgroundColor3  = Theme.Card,
        BackgroundTransparency = 0.08,
        BorderSizePixel   = 0,
        ClipsDescendants  = true,
        Parent            = NotifyContainer,
    })
    Create("UICorner",  {CornerRadius = UDim.new(0,10), Parent = card})
    Create("UIStroke",  {Color = accent, Thickness = 1.2, Transparency = 0.5, Parent = card})

    local bar = Create("Frame", {
        Size             = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = accent,
        BorderSizePixel  = 0,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,4), Parent = bar})

    local iconCircle = Create("Frame", {
        Size             = UDim2.new(0, 32, 0, 32),
        Position         = UDim2.new(0, 14, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.75,
        BorderSizePixel  = 0,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = iconCircle})
    Create("TextLabel", {
        Size             = UDim2.new(1,0,1,0),
        BackgroundTransparency = 1,
        Text             = iconMap[ntype] or "ℹ",
        TextColor3       = accent,
        Font             = Enum.Font.GothamBold,
        TextSize         = 15,
        Parent           = iconCircle,
    })

    Create("TextLabel", {
        Size             = UDim2.new(1, -70, 0, 18),
        Position         = UDim2.new(0, 56, 0, 12),
        BackgroundTransparency = 1,
        Text             = title,
        TextColor3       = Theme.TextPrimary,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextTruncate     = Enum.TextTruncate.AtEnd,
        Parent           = card,
    })
    Create("TextLabel", {
        Size             = UDim2.new(1, -70, 0, 28),
        Position         = UDim2.new(0, 56, 0, 32),
        BackgroundTransparency = 1,
        Text             = msg,
        TextColor3       = Theme.TextSecondary,
        Font             = Enum.Font.Gotham,
        TextSize         = 11,
        TextXAlignment   = Enum.TextXAlignment.Left,
        TextWrapped      = true,
        Parent           = card,
    })

    local prog = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = accent,
        BackgroundTransparency = 0.4,
        BorderSizePixel  = 0,
        Parent           = card,
    })

    card.Position = UDim2.new(1, 10, 0, 0)
    Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

    Tween(prog, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    local closeBtn = Create("TextButton", {
        Size             = UDim2.new(0, 22, 0, 22),
        Position         = UDim2.new(1, -28, 0, 6),
        BackgroundTransparency = 1,
        Text             = "×",
        TextColor3       = Theme.TextMuted,
        Font             = Enum.Font.GothamBold,
        TextSize         = 18,
        Parent           = card,
    })

    local function destroyCard()
        Tween(card, {
            Position = UDim2.new(1, 20, 0, 0),
            BackgroundTransparency = 1,
        }, 0.28)
        task.delay(0.3, function()
            card:Destroy()
        end)
    end

    closeBtn.MouseButton1Click:Connect(destroyCard)
    card.MouseButton1Click = nil

    task.delay(duration, destroyCard)
end

-- ════════════════════════════════════════════════
--              SCRIPT STORAGE (per session)
-- ════════════════════════════════════════════════
local _ScriptData = {}
local _Tabs       = {}
local _ActiveTab  = nil
local _Connections = {}

-- ════════════════════════════════════════════════
--              SCRIPT EXECUTION ENGINE
-- ════════════════════════════════════════════════
local function SafeExec(code, env)
    local fn, err = loadstring("return (function()\n" .. code .. "\nend)()")
    if not fn then
        Notify("Script Error", err or "Parse error", "error", 6)
        return nil, err
    end

    local ok, result = pcall(fn)
    if not ok then
        Notify("Runtime Error", tostring(result), "error", 6)
        return nil, result
    end
    return result, nil
end

local function RunButtonScript(data)
    if not data.code or data.code == "" then
        Notify("No Script", "This button has no code attached.", "warning")
        return
    end
    PlaySound(SoundIDs.Click, 0.3)
    SafeExec(data.code)
end

local function StartToggleScript(data)
    if not data.code or data.code == "" then
        Notify("No Script", "This toggle has no code attached.", "warning")
        return false
    end
    local fn, err = loadstring("return (function()\n" .. data.code .. "\nend)()")
    if not fn then
        Notify("Script Error", err or "Parse error", "error", 6)
        return false
    end
    local ok, result = pcall(fn)
    if not ok then
        Notify("Runtime Error", tostring(result), "error", 6)
        return false
    end
    if type(result) == "function" then
        local conn = RunService.Heartbeat:Connect(result)
        data.connection = conn
    end
    return true
end

local function StopToggleScript(data)
    if data.connection then
        data.connection:Disconnect()
        data.connection = nil
    end
end

for _, old in ipairs(PlayerGui:GetChildren()) do
    if old.Name == "ModularUI" then old:Destroy() end
end

local ScreenGui = Create("ScreenGui", {
    Name                  = "ModularUI",
    ResetOnSpawn          = false,
    ZIndexBehavior        = Enum.ZIndexBehavior.Sibling,
    DisplayOrder          = 100,
    Parent                = PlayerGui,
})

InitNotifications(ScreenGui)

local MainWindow = Create("Frame", {
    Name             = "MainWindow",
    Size             = UDim2.new(0, 720, 0, 480),
    Position         = UDim2.new(0.5, -360, 0.5, -240),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    Parent           = ScreenGui,
})
Create("UICorner",  {CornerRadius = UDim.new(0, 14), Parent = MainWindow})
Create("UIStroke",  {
    Color       = Theme.Border,
    Thickness   = 1,
    Transparency = 0.3,
    Parent      = MainWindow,
})

local GlowFrame = Create("ImageLabel", {
    Name             = "Glow",
    Size             = UDim2.new(1, 80, 1, 80),
    Position         = UDim2.new(0, -40, 0, -40),
    BackgroundTransparency = 1,
    Image            = "rbxassetid://5028857084",
    ImageColor3      = Theme.Accent,
    ImageTransparency = 0.82,
    ScaleType        = Enum.ScaleType.Slice,
    SliceCenter      = Rect.new(24, 24, 276, 276),
    ZIndex           = 0,
    Parent           = MainWindow,
})

local TitleBar = Create("Frame", {
    Name             = "TitleBar",
    Size             = UDim2.new(1, 0, 0, 46),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 3,
    Parent           = MainWindow,
})
Create("UICorner", {CornerRadius = UDim.new(0, 14), Parent = TitleBar})
Create("Frame", {
    Size             = UDim2.new(1, 0, 0, 10),
    Position         = UDim2.new(0, 0, 1, -10),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 3,
    Parent           = TitleBar,
})

local LogoDot = Create("Frame", {
    Size             = UDim2.new(0, 8, 0, 8),
    Position         = UDim2.new(0, 16, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel  = 0,
    ZIndex           = 4,
    Parent           = TitleBar,
})
Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = LogoDot})

Create("TextLabel", {
    Size             = UDim2.new(0, 200, 1, 0),
    Position         = UDim2.new(0, 30, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Modular UI",
    TextColor3       = Theme.TextPrimary,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 4,
    Parent           = TitleBar,
})
Create("TextLabel", {
    Size             = UDim2.new(0, 100, 1, 0),
    Position         = UDim2.new(0, 135, 0, 0),
    BackgroundTransparency = 1,
    Text             = "v1.0",
    TextColor3       = Theme.TextMuted,
    Font             = Enum.Font.Gotham,
    TextSize         = 10,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 4,
    Parent           = TitleBar,
})

local function MakeWinBtn(color, offsetX)
    local b = Create("Frame", {
        Size             = UDim2.new(0, 11, 0, 11),
        Position         = UDim2.new(1, offsetX, 0.5, 0),
        AnchorPoint      = Vector2.new(0, 0.5),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = TitleBar,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = b})
    return b
end
local closeWin   = MakeWinBtn(Color3.fromRGB(255, 95, 86),  -40)
local minimizeW  = MakeWinBtn(Color3.fromRGB(255, 189, 46), -58)
local maximizeW  = MakeWinBtn(Color3.fromRGB(39,  201, 63), -76)

local _Visible = true
closeWin.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        PlaySound(SoundIDs.Click)
        _Visible = not _Visible
        if _Visible then
            MainWindow.Visible = true
            Tween(MainWindow, {Size = UDim2.new(0, 720, 0, 480)}, 0.3, Enum.EasingStyle.Back)
        else
            Tween(MainWindow, {Size = UDim2.new(0, 720, 0, 0)}, 0.22)
            task.delay(0.25, function()
                MainWindow.Visible = false
            end)
        end
    end
end)

do
    local dragging, dragStart, startPos
    TitleBar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging  = true
            dragStart = inp.Position
            startPos  = MainWindow.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = inp.Position - dragStart
            MainWindow.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

local Sidebar = Create("Frame", {
    Name             = "Sidebar",
    Size             = UDim2.new(0, 160, 1, -46),
    Position         = UDim2.new(0, 0, 0, 46),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 2,
    Parent           = MainWindow,
})

local TabListContainer = Create("ScrollingFrame", {
    Name             = "TabList",
    Size             = UDim2.new(1, 0, 1, -50),
    Position         = UDim2.new(0, 0, 0, 8),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize       = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex           = 3,
    Parent           = Sidebar,
})
Create("UIListLayout", {
    SortOrder         = Enum.SortOrder.LayoutOrder,
    Padding           = UDim.new(0, 2),
    Parent            = TabListContainer,
})
Create("UIPadding", {
    PaddingLeft   = UDim.new(0, 8),
    PaddingRight  = UDim.new(0, 8),
    Parent        = TabListContainer,
})

local AddTabBtn = Create("TextButton", {
    Name             = "AddTab",
    Size             = UDim2.new(1, -16, 0, 34),
    Position         = UDim2.new(0, 8, 1, -44),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel  = 0,
    Text             = "+ New Tab",
    TextColor3       = Theme.Accent,
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    ZIndex           = 3,
    Parent           = Sidebar,
})
Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = AddTabBtn})
Create("UIStroke",  {Color = Theme.Accent, Thickness = 1, Transparency = 0.6, Parent = AddTabBtn})

local ContentArea = Create("Frame", {
    Name             = "ContentArea",
    Size             = UDim2.new(1, -160, 1, -46),
    Position         = UDim2.new(0, 160, 0, 46),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel  = 0,
    ClipsDescendants = true,
    ZIndex           = 2,
    Parent           = MainWindow,
})

local ContentTopBar = Create("Frame", {
    Name             = "ContentTopBar",
    Size             = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel  = 0,
    ZIndex           = 3,
    Parent           = ContentArea,
})
local ContentTitle = Create("TextLabel", {
    Size             = UDim2.new(1, -120, 1, 0),
    Position         = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Select or create a tab",
    TextColor3       = Theme.TextPrimary,
    Font             = Enum.Font.GothamBold,
    TextSize         = 14,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 4,
    Parent           = ContentTopBar,
})

local AddControlBtn = Create("TextButton", {
    Size             = UDim2.new(0, 106, 0, 28),
    Position         = UDim2.new(1, -114, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel  = 0,
    Text             = "+ Add Control",
    TextColor3       = Color3.fromRGB(255,255,255),
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    ZIndex           = 4,
    Parent           = ContentTopBar,
    Visible          = false,
})
Create("UICorner", {CornerRadius = UDim.new(0,7), Parent = AddControlBtn})

local ControlsScroll = Create("ScrollingFrame", {
    Name             = "ControlsScroll",
    Size             = UDim2.new(1, 0, 1, -42),
    Position         = UDim2.new(0, 0, 0, 42),
    BackgroundTransparency = 1,
    BorderSizePixel  = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Accent,
    CanvasSize       = UDim2.new(0,0,0,0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    ZIndex           = 3,
    Parent           = ContentArea,
})
Create("UIListLayout", {
    SortOrder         = Enum.SortOrder.LayoutOrder,
    Padding           = UDim.new(0, 8),
    Parent            = ControlsScroll,
})
Create("UIPadding", {
    PaddingAll = UDim.new(0, 12),
    Parent     = ControlsScroll,
})

local EmptyLabel = Create("TextLabel", {
    Size             = UDim2.new(1, 0, 0, 60),
    BackgroundTransparency = 1,
    Text             = "This tab is empty.\nClick '+ Add Control' to add your first script.",
    TextColor3       = Theme.TextMuted,
    Font             = Enum.Font.Gotham,
    TextSize         = 12,
    TextWrapped      = true,
    ZIndex           = 4,
    Parent           = ControlsScroll,
    Visible          = true,
})

local DevPanel = Create("Frame", {
    Name             = "DevPanel",
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Theme.BG,
    BorderSizePixel  = 0,
    ZIndex           = 10,
    Visible          = false,
    Parent           = ContentArea,
})

local DevTopBar = Create("Frame", {
    Size             = UDim2.new(1, 0, 0, 42),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel  = 0,
    ZIndex           = 11,
    Parent           = DevPanel,
})
Create("TextLabel", {
    Size             = UDim2.new(0, 200, 1, 0),
    Position         = UDim2.new(0, 16, 0, 0),
    BackgroundTransparency = 1,
    Text             = "⚙ Dev Editor",
    TextColor3       = Theme.Accent,
    Font             = Enum.Font.GothamBold,
    TextSize         = 13,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 12,
    Parent           = DevTopBar,
})

local DevCloseBtn = Create("TextButton", {
    Size             = UDim2.new(0, 70, 0, 26),
    Position         = UDim2.new(1, -80, 0.5, 0),
    AnchorPoint      = Vector2.new(0, 0.5),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel  = 0,
    Text             = "✕ Close",
    TextColor3       = Theme.TextSecondary,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    ZIndex           = 12,
    Parent           = DevTopBar,
})
Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = DevCloseBtn})

local DevPickerRow = Create("Frame", {
    Size             = UDim2.new(1, 0, 0, 48),
    Position         = UDim2.new(0, 0, 0, 42),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 11,
    Parent           = DevPanel,
})
Create("UIPadding", {PaddingLeft = UDim.new(0,12), PaddingTop = UDim.new(0,8), Parent = DevPickerRow})

Create("TextLabel", {
    Size             = UDim2.new(0,50,0,28),
    BackgroundTransparency = 1,
    Text             = "Tab:",
    TextColor3       = Theme.TextSecondary,
    Font             = Enum.Font.Gotham,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 12,
    Parent           = DevPickerRow,
})

local DevTabPicker = Create("TextBox", {
    Size             = UDim2.new(0, 130, 0, 28),
    Position         = UDim2.new(0, 46, 0, 0),
    BackgroundColor3 = Theme.InputBG,
    BorderSizePixel  = 0,
    Text             = "",
    PlaceholderText  = "Tab name...",
    TextColor3       = Theme.TextPrimary,
    PlaceholderColor3 = Theme.TextMuted,
    Font             = Enum.Font.Gotham,
    TextSize         = 12,
    ZIndex           = 12,
    ClearTextOnFocus = false,
    Parent           = DevPickerRow,
})
Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = DevTabPicker})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), Parent = DevTabPicker})

Create("TextLabel", {
    Size             = UDim2.new(0,60,0,28),
    Position         = UDim2.new(0,188,0,0),
    BackgroundTransparency = 1,
    Text             = "Control:",
    TextColor3       = Theme.TextSecondary,
    Font             = Enum.Font.Gotham,
    TextSize         = 12,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 12,
    Parent           = DevPickerRow,
})
local DevControlPicker = Create("TextBox", {
    Size             = UDim2.new(0, 130, 0, 28),
    Position         = UDim2.new(0, 244, 0, 0),
    BackgroundColor3 = Theme.InputBG,
    BorderSizePixel  = 0,
    Text             = "",
    PlaceholderText  = "Control name...",
    TextColor3       = Theme.TextPrimary,
    PlaceholderColor3 = Theme.TextMuted,
    Font             = Enum.Font.Gotham,
    TextSize         = 12,
    ZIndex           = 12,
    ClearTextOnFocus = false,
    Parent           = DevPickerRow,
})
Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = DevControlPicker})
Create("UIPadding", {PaddingLeft = UDim.new(0,8), Parent = DevControlPicker})

local DevLoadBtn = Create("TextButton", {
    Size             = UDim2.new(0,65,0,28),
    Position         = UDim2.new(0,386,0,0),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel  = 0,
    Text             = "Load",
    TextColor3       = Theme.TextPrimary,
    Font             = Enum.Font.GothamBold,
    TextSize         = 11,
    ZIndex           = 12,
    Parent           = DevPickerRow,
})
Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = DevLoadBtn})

local DevCodeBox = Create("TextBox", {
    Size             = UDim2.new(1, -20, 1, -160),
    Position         = UDim2.new(0, 10, 0, 100),
    BackgroundColor3 = Theme.InputBG,
    BorderSizePixel  = 0,
    Text             = "",
    PlaceholderText  = "-- Paste your script code here\n-- Buttons: code runs on click\n-- Toggles: return a heartbeat function to loop, or nil to run once\n-- Example:\n--   local char = game.Players.LocalPlayer.Character\n--   if char then char.HumanoidRootPart.CFrame = CFrame.new(0,100,0) end",
    TextColor3       = Theme.TextPrimary,
    PlaceholderColor3 = Theme.TextMuted,
    Font             = Enum.Font.Code,
    TextSize          = 12,
    MultiLine        = true,
    TextXAlignment   = Enum.TextXAlignment.Left,
    TextYAlignment   = Enum.TextYAlignment.Top,
    ClearTextOnFocus = false,
    ZIndex           = 12,
    Parent           = DevPanel,
})
Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = DevCodeBox})
Create("UIStroke",  {Color = Theme.Border, Thickness = 1, Parent = DevCodeBox})
Create("UIPadding", {PaddingAll = UDim.new(0,10), Parent = DevCodeBox})

local DevActRow = Create("Frame", {
    Size             = UDim2.new(1, 0, 0, 46),
    Position         = UDim2.new(0, 0, 1, -50),
    BackgroundColor3 = Theme.Panel,
    BorderSizePixel  = 0,
    ZIndex           = 11,
    Parent           = DevPanel,
})
Create("UIPadding", {PaddingLeft = UDim.new(0,12), PaddingTop = UDim.new(0,9), Parent = DevActRow})

local function MakeDevBtn(text, color, posX, width)
    local b = Create("TextButton", {
        Size             = UDim2.new(0, width or 90, 0, 28),
        Position         = UDim2.new(0, posX, 0, 0),
        BackgroundColor3 = color,
        BorderSizePixel  = 0,
        Text             = text,
        TextColor3       = Color3.fromRGB(255,255,255),
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        ZIndex           = 12,
        Parent           = DevActRow,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,7), Parent = b})
    return b
end

local DevTestBtn = MakeDevBtn("▶ Test", Theme.Success,   0,   82)
local DevSaveBtn = MakeDevBtn("💾 Save", Theme.Accent,   90,  82)
local DevResetBtn= MakeDevBtn("↺ Reset",Theme.Warning,   180, 82)

local DevLineCount = Create("TextLabel", {
    Size             = UDim2.new(0, 120, 0, 28),
    Position         = UDim2.new(1, -130, 0, 0),
    BackgroundTransparency = 1,
    Text             = "Lines: 0",
    TextColor3       = Theme.TextMuted,
    Font             = Enum.Font.Code,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Right,
    ZIndex           = 12,
    Parent           = DevActRow,
})

DevCodeBox:GetPropertyChangedSignal("Text"):Connect(function()
    local lines = 0
    for _ in DevCodeBox.Text:gmatch("\n") do lines = lines + 1 end
    DevLineCount.Text = "Lines: " .. (lines + 1)
end)

local _DevTargetTab     = nil
local _DevTargetControl = nil
local _DevOriginalCode  = ""

DevLoadBtn.MouseButton1Click:Connect(function()
    local tabName  = DevTabPicker.Text
    local ctrlName = DevControlPicker.Text
    if tabName == "" or ctrlName == "" then
        Notify("Dev Editor", "Enter both tab and control names.", "warning")
        return
    end
    if not _ScriptData[tabName] or not _ScriptData[tabName][ctrlName] then
        Notify("Dev Editor", "Control '"..ctrlName.."' not found in tab '"..tabName.."'.", "error")
        return
    end
    _DevTargetTab     = tabName
    _DevTargetControl = ctrlName
    local code = _ScriptData[tabName][ctrlName].code or ""
    _DevOriginalCode  = code
    DevCodeBox.Text   = code
    PlaySound(SoundIDs.Click)
    Notify("Dev Editor", "Loaded '"..ctrlName.."' from '"..tabName.."'.", "success", 3)
end)

DevTestBtn.MouseButton1Click:Connect(function()
    local code = DevCodeBox.Text
    if code == "" then
        Notify("Dev", "Nothing to test.", "warning")
        return
    end
    PlaySound(SoundIDs.Click)
    Notify("Dev Editor", "Running test...", "info", 2)
    SafeExec(code)
end)

DevSaveBtn.MouseButton1Click:Connect(function()
    if not _DevTargetTab or not _DevTargetControl then
        Notify("Dev Editor", "Load a control first before saving.", "warning")
        return
    end
    _ScriptData[_DevTargetTab][_DevTargetControl].code = DevCodeBox.Text
    PlaySound(SoundIDs.Success)
    Notify("Dev Editor", "Saved to '"..tostring(_DevTargetControl).."'!", "success", 3)
end)

DevResetBtn.MouseButton1Click:Connect(function()
    DevCodeBox.Text = _DevOriginalCode
    PlaySound(SoundIDs.Toggle)
    Notify("Dev Editor", "Reset to last saved code.", "info", 2)
end)

DevCloseBtn.MouseButton1Click:Connect(function()
    PlaySound(SoundIDs.Click)
    Tween(DevPanel, {BackgroundTransparency = 1}, 0.15)
    task.delay(0.15, function()
        DevPanel.Visible = false
        DevPanel.BackgroundTransparency = 0
    end)
end)

local ModalOverlay = Create("Frame", {
    Name             = "ModalOverlay",
    Size             = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Color3.fromRGB(0,0,0),
    BackgroundTransparency = 0.5,
    ZIndex           = 50,
    Visible          = false,
    Parent           = MainWindow,
})

local ModalBox = Create("Frame", {
    Name             = "ModalBox",
    Size             = UDim2.new(0, 380, 0, 280),
    Position         = UDim2.new(0.5, -190, 0.5, -140),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel  = 0,
    ZIndex           = 51,
    Parent           = ModalOverlay,
})
Create("UICorner", {CornerRadius = UDim.new(0,12), Parent = ModalBox})
Create("UIStroke",  {Color = Theme.Accent, Thickness = 1, Transparency = 0.5, Parent = ModalBox})

local ModalTitle = Create("TextLabel", {
    Size             = UDim2.new(1,-20, 0, 40),
    Position         = UDim2.new(0, 16, 0, 8),
    BackgroundTransparency = 1,
    Text             = "New Control",
    TextColor3       = Theme.TextPrimary,
    Font             = Enum.Font.GothamBold,
    TextSize         = 15,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 52,
    Parent           = ModalBox,
})

Create("TextLabel", {
    Size             = UDim2.new(1,-32,0,20),
    Position         = UDim2.new(0,16,0,52),
    BackgroundTransparency = 1,
    Text             = "Control Name",
    TextColor3       = Theme.TextSecondary,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 52,
    Parent           = ModalBox,
})
local ModalNameInput = Create("TextBox", {
    Size             = UDim2.new(1,-32,0,32),
    Position         = UDim2.new(0,16,0,74),
    BackgroundColor3 = Theme.InputBG,
    BorderSizePixel  = 0,
    Text             = "",
    PlaceholderText  = "e.g. Speed Hack",
    TextColor3       = Theme.TextPrimary,
    PlaceholderColor3= Theme.TextMuted,
    Font             = Enum.Font.Gotham,
    TextSize         = 13,
    ClearTextOnFocus = false,
    ZIndex           = 52,
    Parent           = ModalBox,
})
Create("UICorner", {CornerRadius = UDim.new(0,7), Parent = ModalNameInput})
Create("UIPadding", {PaddingLeft = UDim.new(0,10), Parent = ModalNameInput})

Create("TextLabel", {
    Size             = UDim2.new(1,-32,0,20),
    Position         = UDim2.new(0,16,0,116),
    BackgroundTransparency = 1,
    Text             = "Control Type",
    TextColor3       = Theme.TextSecondary,
    Font             = Enum.Font.Gotham,
    TextSize         = 11,
    TextXAlignment   = Enum.TextXAlignment.Left,
    ZIndex           = 52,
    Parent           = ModalBox,
})

local _typeOptions = {"button","toggle","slider","input"}
local _typeIdx     = 1
local TypeBtns = {}
local TypeRow = Create("Frame", {
    Size             = UDim2.new(1,-32,0,34),
    Position         = UDim2.new(0,16,0,138),
    BackgroundTransparency = 1,
    ZIndex           = 52,
    Parent           = ModalBox,
})
Create("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding       = UDim.new(0,6),
    Parent        = TypeRow,
})

local function UpdateTypeButtons()
    for i, btn in ipairs(TypeBtns) do
        if i == _typeIdx then
            Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.12)
            btn.TextColor3 = Color3.fromRGB(255,255,255)
        else
            Tween(btn, {BackgroundColor3 = Theme.InputBG}, 0.12)
            btn.TextColor3 = Theme.TextSecondary
        end
    end
end

for i, opt in ipairs(_typeOptions) do
    local tb = Create("TextButton", {
        Size             = UDim2.new(0, 74, 1, 0),
        BackgroundColor3 = Theme.InputBG,
        BorderSizePixel  = 0,
        Text             = opt:sub(1,1):upper() .. opt:sub(2),
        TextColor3       = Theme.TextSecondary,
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        ZIndex           = 53,
        Parent           = TypeRow,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = tb})
    TypeBtns[i] = tb
    tb.MouseButton1Click:Connect(function()
        _typeIdx = i
        UpdateTypeButtons()
        PlaySound(SoundIDs.Click)
    end)
end
UpdateTypeButtons()

local SliderRangeRow = Create("Frame", {
    Size             = UDim2.new(1,-32,0,34),
    Position         = UDim2.new(0,16,0,182),
    BackgroundTransparency = 1,
    ZIndex           = 52,
    Parent           = ModalBox,
})
Create("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,6), Parent = SliderRangeRow})
local function MakeRangeBox(ph)
    local b = Create("TextBox", {
        Size             = UDim2.new(0, 80, 1, 0),
        BackgroundColor3 = Theme.InputBG,
        BorderSizePixel  = 0,
        Text             = "",
        PlaceholderText  = ph,
        TextColor3       = Theme.TextPrimary,
        PlaceholderColor3= Theme.TextMuted,
        Font             = Enum.Font.Code,
        TextSize         = 12,
        ClearTextOnFocus = false,
        ZIndex           = 53,
        Parent           = SliderRangeRow,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,6), Parent = b})
    Create("UIPadding", {PaddingLeft = UDim.new(0,8), Parent = b})
    return b
end
local SliderMinBox = MakeRangeBox("Min (0)")
local SliderMaxBox = MakeRangeBox("Max (100)")

local ModalCancelBtn = Create("TextButton", {
    Size             = UDim2.new(0,100,0,34),
    Position         = UDim2.new(0,16,1,-50),
    BackgroundColor3 = Theme.InputBG,
    BorderSizePixel  = 0,
    Text             = "Cancel",
    TextColor3       = Theme.TextSecondary,
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    ZIndex           = 52,
    Parent           = ModalBox,
})
Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = ModalCancelBtn})

local ModalConfirmBtn = Create("TextButton", {
    Size             = UDim2.new(0,120,0,34),
    Position         = UDim2.new(1,-136,1,-50),
    BackgroundColor3 = Theme.Accent,
    BorderSizePixel  = 0,
    Text             = "Add Control",
    TextColor3       = Color3.fromRGB(255,255,255),
    Font             = Enum.Font.GothamBold,
    TextSize         = 12,
    ZIndex           = 52,
    Parent           = ModalBox,
})
Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = ModalConfirmBtn})

local _ModalCallback = nil

local function ShowModal(title, callback)
    ModalTitle.Text   = title
    ModalNameInput.Text = ""
    _typeIdx = 1
    UpdateTypeButtons()
    SliderMinBox.Text = ""
    SliderMaxBox.Text = ""
    _ModalCallback    = callback
    ModalOverlay.Visible = true
    ModalBox.Size = UDim2.new(0, 20, 0, 20)
    ModalBox.Position = UDim2.new(0.5, -10, 0.5, -10)
    SpringTween(ModalBox, {
        Size     = UDim2.new(0, 380, 0, 280),
        Position = UDim2.new(0.5, -190, 0.5, -140),
    }, 0.35)
    PlaySound(SoundIDs.Open)
end

local function HideModal()
    Tween(ModalBox, {Size = UDim2.new(0,20,0,20), Position = UDim2.new(0.5,-10,0.5,-10)}, 0.2)
    task.delay(0.22, function()
        ModalOverlay.Visible = false
    end)
end

ModalCancelBtn.MouseButton1Click:Connect(function()
    HideModal()
    PlaySound(SoundIDs.Click)
end)

ModalConfirmBtn.MouseButton1Click:Connect(function()
    local name    = ModalNameInput.Text
    local ctype   = _typeOptions[_typeIdx]
    local smin    = tonumber(SliderMinBox.Text) or 0
    local smax    = tonumber(SliderMaxBox.Text) or 100

    if name == "" then
        Notify("Add Control", "Please enter a name.", "warning")
        return
    end

    if _ModalCallback then
        _ModalCallback(name, ctype, smin, smax)
    end
    HideModal()
    PlaySound(SoundIDs.Success)
end)

local function MakeControlCard(parent, label, hint)
    local card = Create("Frame", {
        Size             = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel  = 0,
        ZIndex           = 4,
        Parent           = parent,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,10), Parent = card})

    local nameLabel = Create("TextLabel", {
        Size             = UDim2.new(0,200,0,22),
        Position         = UDim2.new(0,14,0,8),
        BackgroundTransparency = 1,
        Text             = label,
        TextColor3       = Theme.TextPrimary,
        Font             = Enum.Font.GothamBold,
        TextSize         = 13,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 5,
        Parent           = card,
    })
    local hintLabel = Create("TextLabel", {
        Size             = UDim2.new(0,200,0,16),
        Position         = UDim2.new(0,14,0,30),
        BackgroundTransparency = 1,
        Text             = hint or "",
        TextColor3       = Theme.TextMuted,
        Font             = Enum.Font.Gotham,
        TextSize         = 10,
        TextXAlignment   = Enum.TextXAlignment.Left,
        ZIndex           = 5,
        Parent           = card,
    })

    local del = Create("TextButton", {
        Size             = UDim2.new(0,22,0,22),
        Position         = UDim2.new(1,-10,0.5,0),
        AnchorPoint      = Vector2.new(1,0.5),
        BackgroundTransparency = 1,
        Text             = "×",
        TextColor3       = Theme.TextMuted,
        Font             = Enum.Font.GothamBold,
        TextSize         = 16,
        ZIndex           = 6,
        Parent           = card,
    })

    card.MouseEnter:Connect(function()
        Tween(card, {BackgroundColor3 = Theme.CardHover}, 0.12)
    end)
    card.MouseLeave:Connect(function()
        Tween(card, {BackgroundColor3 = Theme.Card}, 0.12)
    end)

    return card, del, nameLabel, hintLabel
end

local function BuildButton(tabName, ctrlName, scrollFrame)
    if not _ScriptData[tabName] then _ScriptData[tabName] = {} end
    if not _ScriptData[tabName][ctrlName] then
        _ScriptData[tabName][ctrlName] = {type="button", code=""}
    end

    local card, del = MakeControlCard(scrollFrame, ctrlName, "Button · click to run script")
    card.Size = UDim2.new(1, 0, 0, 56)

    local btn = Create("TextButton", {
        Size             = UDim2.new(0,90,0,30),
        Position         = UDim2.new(1,-104,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Text             = "▶ Run",
        TextColor3       = Color3.fromRGB(255,255,255),
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        ZIndex           = 6,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,7), Parent = btn})

    btn.MouseButton1Click:Connect(function(x, y)
        Ripple(btn, Mouse.X, Mouse.Y)
        RunButtonScript(_ScriptData[tabName][ctrlName])
    end)

    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.AccentHover}, 0.12)
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = Theme.Accent}, 0.12)
    end)

    del.MouseButton1Click:Connect(function()
        _ScriptData[tabName][ctrlName] = nil
        Tween(card, {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1}, 0.18)
        task.delay(0.2, function() card:Destroy() end)
        PlaySound(SoundIDs.Click)
    end)

    return card
end

local function BuildToggle(tabName, ctrlName, scrollFrame)
    if not _ScriptData[tabName] then _ScriptData[tabName] = {} end
    if not _ScriptData[tabName][ctrlName] then
        _ScriptData[tabName][ctrlName] = {type="toggle", code="", active=false}
    end

    local data = _ScriptData[tabName][ctrlName]
    local card, del = MakeControlCard(scrollFrame, ctrlName, "Toggle · enables/disables script loop")

    local trackW, trackH = 44, 24
    local track = Create("Frame", {
        Size             = UDim2.new(0,trackW,0,trackH),
        Position         = UDim2.new(1,-trackW-40,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = track})

    local knob = Create("Frame", {
        Size             = UDim2.new(0,18,0,18),
        Position         = UDim2.new(0,3,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = track,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = knob})

    local statusLabel = Create("TextLabel", {
        Size             = UDim2.new(0,36,0,16),
        Position         = UDim2.new(1,-36,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundTransparency = 1,
        Text             = "OFF",
        TextColor3       = Theme.TextMuted,
        Font             = Enum.Font.GothamBold,
        TextSize         = 10,
        ZIndex           = 6,
        Parent           = card,
    })

    local function SetToggle(state)
        data.active = state
        if state then
            Tween(track,        {BackgroundColor3 = Theme.ToggleOn}, 0.18)
            Tween(knob,         {Position = UDim2.new(0, trackW-21, 0.5, 0)}, 0.18)
            statusLabel.Text   = "ON"
            statusLabel.TextColor3 = Theme.Success
            StartToggleScript(data)
        else
            Tween(track,        {BackgroundColor3 = Theme.ToggleOff}, 0.18)
            Tween(knob,         {Position = UDim2.new(0, 3, 0.5, 0)}, 0.18)
            statusLabel.Text   = "OFF"
            statusLabel.TextColor3 = Theme.TextMuted
            StopToggleScript(data)
        end
        PlaySound(SoundIDs.Toggle)
    end

    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            SetToggle(not data.active)
        end
    end)

    del.MouseButton1Click:Connect(function()
        if data.active then StopToggleScript(data) end
        _ScriptData[tabName][ctrlName] = nil
        Tween(card, {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1}, 0.18)
        task.delay(0.2, function() card:Destroy() end)
        PlaySound(SoundIDs.Click)
    end)

    return card
end

local function BuildSlider(tabName, ctrlName, smin, smax, scrollFrame)
    if not _ScriptData[tabName] then _ScriptData[tabName] = {} end
    if not _ScriptData[tabName][ctrlName] then
        _ScriptData[tabName][ctrlName] = {
            type="slider", code="", sliderMin=smin, sliderMax=smax, sliderVal=smin
        }
    end
    local data = _ScriptData[tabName][ctrlName]
    data.sliderMin = smin
    data.sliderMax = smax

    local card, del = MakeControlCard(scrollFrame, ctrlName, "Slider · drag to set value")
    card.Size = UDim2.new(1, 0, 0, 72)

    local sliderW = 200
    local trackBG = Create("Frame", {
        Size             = UDim2.new(0,sliderW,0,6),
        Position         = UDim2.new(1,-sliderW-14,0.5,6),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Theme.ToggleOff,
        BorderSizePixel  = 0,
        ZIndex           = 6,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = trackBG})

    local fill = Create("Frame", {
        Size             = UDim2.new(0,0,1,0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        ZIndex           = 7,
        Parent           = trackBG,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = fill})

    local thumb = Create("Frame", {
        Size             = UDim2.new(0,16,0,16),
        Position         = UDim2.new(0,-8,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Color3.fromRGB(255,255,255),
        BorderSizePixel  = 0,
        ZIndex           = 8,
        Parent           = trackBG,
    })
    Create("UICorner", {CornerRadius = UDim.new(1,0), Parent = thumb})
    Create("UIStroke",  {Color = Theme.Accent, Thickness = 2, Parent = thumb})

    local valLabel = Create("TextLabel", {
        Size             = UDim2.new(0,50,0,16),
        Position         = UDim2.new(1,-sliderW-18,0.5,-12),
        AnchorPoint      = Vector2.new(1,0.5),
        BackgroundTransparency = 1,
        Text             = tostring(smin),
        TextColor3       = Theme.Accent,
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        TextXAlignment   = Enum.TextXAlignment.Right,
        ZIndex           = 6,
        Parent           = card,
    })

    local _sliderDrag = false
    local function UpdateSlider(mouseX)
        local relX = math.clamp(mouseX - trackBG.AbsolutePosition.X, 0, sliderW)
        local pct  = relX / sliderW
        local val  = math.floor(smin + pct * (smax - smin))
        data.sliderVal = val
        fill.Size      = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, -8, 0.5, 0)
        valLabel.Text  = tostring(val)
        if data.code and data.code ~= "" then
            local fn, err = loadstring("local value = " .. val .. "\n" .. data.code)
            if fn then pcall(fn) end
        end
    end

    trackBG.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            _sliderDrag = true
            UpdateSlider(Mouse.X)
            PlaySound(SoundIDs.Slider, 0.15, 1.2)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if _sliderDrag and inp.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(Mouse.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            _sliderDrag = false
        end
    end)

    del.MouseButton1Click:Connect(function()
        _ScriptData[tabName][ctrlName] = nil
        Tween(card, {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1}, 0.18)
        task.delay(0.2, function() card:Destroy() end)
        PlaySound(SoundIDs.Click)
    end)

    return card
end

local function BuildInput(tabName, ctrlName, scrollFrame)
    if not _ScriptData[tabName] then _ScriptData[tabName] = {} end
    if not _ScriptData[tabName][ctrlName] then
        _ScriptData[tabName][ctrlName] = {type="input", code="", inputValue=""}
    end
    local data = _ScriptData[tabName][ctrlName]

    local card, del = MakeControlCard(scrollFrame, ctrlName, "Input · type a value, press Enter to run")
    card.Size = UDim2.new(1, 0, 0, 64)

    local inputBox = Create("TextBox", {
        Size             = UDim2.new(0,180,0,30),
        Position         = UDim2.new(1,-282,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Theme.InputBG,
        BorderSizePixel  = 0,
        Text             = "",
        PlaceholderText  = "Type value...",
        TextColor3       = Theme.TextPrimary,
        PlaceholderColor3= Theme.TextMuted,
        Font             = Enum.Font.Gotham,
        TextSize         = 12,
        ClearTextOnFocus = false,
        ZIndex           = 6,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,7), Parent = inputBox})
    Create("UIStroke",  {Color = Theme.Border, Thickness = 1, Parent = inputBox})
    Create("UIPadding", {PaddingLeft = UDim.new(0,8), Parent = inputBox})

    inputBox.Focused:Connect(function()
        Tween(inputBox:FindFirstChildOfClass("UIStroke"), {Color = Theme.BorderFocus}, 0.15)
        PlaySound(SoundIDs.KeyTick, 0.1)
    end)
    inputBox.FocusLost:Connect(function()
        Tween(inputBox:FindFirstChildOfClass("UIStroke"), {Color = Theme.Border}, 0.15)
    end)

    local sendBtn = Create("TextButton", {
        Size             = UDim2.new(0,80,0,30),
        Position         = UDim2.new(1,-90,0.5,0),
        AnchorPoint      = Vector2.new(0,0.5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel  = 0,
        Text             = "Run",
        TextColor3       = Color3.fromRGB(255,255,255),
        Font             = Enum.Font.GothamBold,
        TextSize         = 11,
        ZIndex           = 6,
        Parent           = card,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,7), Parent = sendBtn})

    local function RunInput()
        data.inputValue = inputBox.Text
        if data.code and data.code ~= "" then
            local fn, err = loadstring('local input = "' .. data.inputValue:gsub('"','\\"') .. '"\n' .. data.code)
            if fn then
                local ok, res = pcall(fn)
                if not ok then Notify("Script Error", tostring(res), "error", 5) end
            else
                Notify("Script Error", tostring(err), "error", 5)
            end
        end
        PlaySound(SoundIDs.Click)
    end

    sendBtn.MouseButton1Click:Connect(RunInput)
    inputBox.FocusLost:Connect(function(enterPressed)
        if enterPressed then RunInput() end
    end)

    del.MouseButton1Click:Connect(function()
        _ScriptData[tabName][ctrlName] = nil
        Tween(card, {Size = UDim2.new(1,0,0,0), BackgroundTransparency = 1}, 0.18)
        task.delay(0.2, function() card:Destroy() end)
        PlaySound(SoundIDs.Click)
    end)

    return card
end

local _TabFrames = {}

local function SetActiveTab(tabName)
    PlaySound(SoundIDs.TabSwitch, 0.25)

    for _, t in ipairs(_Tabs) do
        if t.name == tabName then
            Tween(t.button, {BackgroundColor3 = Theme.TabActive}, 0.15)
            t.button.TextColor3 = Color3.fromRGB(255,255,255)
            if _TabFrames[t.name] then
                _TabFrames[t.name].Visible = true
                _TabFrames[t.name].BackgroundTransparency = 1
                Tween(_TabFrames[t.name], {BackgroundTransparency = 0}, 0.15)
            end
        else
            Tween(t.button, {BackgroundColor3 = Theme.Card}, 0.15)
            t.button.TextColor3 = Theme.TextSecondary
            if _TabFrames[t.name] then
                _TabFrames[t.name].Visible = false
            end
        end
    end

    _ActiveTab = tabName
    ContentTitle.Text = tabName
    AddControlBtn.Visible = true
    EmptyLabel.Visible = false

    if tabName == "⚙ Dev" then
        DevPanel.Visible = true
        DevPanel.BackgroundTransparency = 1
        Tween(DevPanel, {BackgroundTransparency = 0}, 0.15)
        AddControlBtn.Visible = false
    else
        DevPanel.Visible = false
    end
end

local function AddTab(name)
    for _, t in ipairs(_Tabs) do
        if t.name == name then
            Notify("Add Tab", "Tab '"..name.."' already exists.", "warning")
            return
        end
    end

    local btn = Create("TextButton", {
        Size             = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel  = 0,
        Text             = name,
        TextColor3       = Theme.TextSecondary,
        Font             = Enum.Font.GothamBold,
        TextSize         = 12,
        ZIndex           = 4,
        LayoutOrder      = #_Tabs + 1,
        Parent           = TabListContainer,
    })
    Create("UICorner", {CornerRadius = UDim.new(0,8), Parent = btn})

    btn.Size = UDim2.new(1,0,0,0)
    SpringTween(btn, {Size = UDim2.new(1,0,0,36)}, 0.3)

    btn.MouseEnter:Connect(function()
        if _ActiveTab ~= name then
            Tween(btn, {BackgroundColor3 = Theme.CardHover}, 0.1)
        end
    end)
    btn.MouseLeave:Connect(function()
        if _ActiveTab ~= name then
            Tween(btn, {BackgroundColor3 = Theme.Card}, 0.1)
        end
    end)

    local tabFrame = Create("ScrollingFrame", {
        Name             = "TabFrame_" .. name,
        Size             = UDim2.new(1, 0, 1, -42),
        Position         = UDim2.new(0, 0, 0, 42),
        BackgroundTransparency = 1,
        BorderSizePixel  = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = Theme.Accent,
        CanvasSize       = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ZIndex           = 3,
        Visible          = false,
        Parent           = ContentArea,
    })
    Create("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8), Parent = tabFrame})
    Create("UIPadding",    {PaddingAll = UDim.new(0,12), Parent = tabFrame})

    _TabFrames[name] = tabFrame
    if not _ScriptData[name] then _ScriptData[name] = {} end

    local tabEntry = {name = name, button = btn, frame = tabFrame}
    table.insert(_Tabs, tabEntry)

    btn.MouseButton1Click:Connect(function()
        SetActiveTab(name)
    end)

    PlaySound(SoundIDs.Success, 0.3)
    Notify("New Tab", "Tab '"..name.."' created!", "success", 2)
    SetActiveTab(name)
end

AddTabBtn.MouseButton1Click:Connect(function()
    PlaySound(SoundIDs.Click)
    ModalTitle.Text = "Create New Tab"
    ModalNameInput.Text = ""
    ModalNameInput.PlaceholderText = "e.g. Combat, Visuals, Movement..."
    _typeIdx = 1
    ModalOverlay.Visible = true
    ModalBox.Size     = UDim2.new(0, 20, 0, 20)
    ModalBox.Position = UDim2.new(0.5, -10, 0.5, -10)
    SpringTween(ModalBox, {Size = UDim2.new(0,380,0,200), Position = UDim2.new(0.5,-190,0.5,-100)}, 0.35)
    TypeRow.Visible       = false
    SliderRangeRow.Visible = false
    ModalConfirmBtn.Text  = "Create Tab"
    _ModalCallback = function(name, _, _, _)
        AddTab(name)
        TypeRow.Visible       = true
        SliderRangeRow.Visible = true
        ModalConfirmBtn.Text  = "Add Control"
        ModalNameInput.PlaceholderText = "e.g. Speed Hack"
    end
end)

AddControlBtn.MouseButton1Click:Connect(function()
    if not _ActiveTab then
        Notify("Add Control", "Select a tab first.", "warning")
        return
    end
    TypeRow.Visible        = true
    SliderRangeRow.Visible = true
    ModalConfirmBtn.Text   = "Add Control"
    ModalNameInput.PlaceholderText = "e.g. Speed Hack"
    ShowModal("Add Control to: " .. _ActiveTab, function(name, ctype, smin, smax)
        local tabFrame = _TabFrames[_ActiveTab]
        if not tabFrame then return end

        if ctype == "button" then
            BuildButton(_ActiveTab, name, tabFrame)
        elseif ctype == "toggle" then
            BuildToggle(_ActiveTab, name, tabFrame)
        elseif ctype == "slider" then
            BuildSlider(_ActiveTab, name, smin, smax, tabFrame)
        elseif ctype == "input" then
            BuildInput(_ActiveTab, name, tabFrame)
        end
        Notify("Control Added", "'"..name.."' added as " .. ctype .. ".", "success", 3)

        DevTabPicker.Text     = _ActiveTab
        DevControlPicker.Text = name
    end)
end)

AddTab("⚙ Dev")
AddTab("Movement")
AddTab("Visuals")
AddTab("Misc")

task.wait(0.1)

do
    local tabFrame = _TabFrames["Movement"]
    if tabFrame then
        BuildSlider("Movement", "Walk Speed", 16, 200, tabFrame)
        _ScriptData["Movement"]["Walk Speed"].code = [[
local char = game.Players.LocalPlayer.Character
if char then
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = value end
end
]]
        BuildToggle("Movement", "Infinite Jump", tabFrame)
        _ScriptData["Movement"]["Infinite Jump"].code = [[
local uis = game:GetService("UserInputService")
local lp  = game.Players.LocalPlayer
uis.JumpRequest:Connect(function()
    local char = lp.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)
]]
    end
end

do
    local tabFrame = _TabFrames["Visuals"]
    if tabFrame then
        BuildToggle("Visuals", "Fullbright", tabFrame)
        _ScriptData["Visuals"]["Fullbright"].code = [[
local Lighting = game:GetService("Lighting")
Lighting.Ambient        = Color3.fromRGB(178,178,178)
Lighting.Brightness     = 2
Lighting.GlobalShadows  = false
Lighting.FogEnd         = 100000
]]
        BuildButton("Visuals", "Reset Lighting", tabFrame)
        _ScriptData["Visuals"]["Reset Lighting"].code = [[
local Lighting = game:GetService("Lighting")
Lighting.Ambient        = Color3.fromRGB(127,127,127)
Lighting.Brightness     = 1
Lighting.GlobalShadows  = true
Lighting.FogEnd         = 100000
]]
    end
end

do
    local tabFrame = _TabFrames["Misc"]
    if tabFrame then
        BuildInput("Misc", "Print Value", tabFrame)
        _ScriptData["Misc"]["Print Value"].code = [[
print("[ModularUI] Input:", input)
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Print Value",
    Text  = tostring(input),
    Duration = 3,
})
]]
        BuildButton("Misc", "Rejoin Server", tabFrame)
        _ScriptData["Misc"]["Rejoin Server"].code = [[
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
]]
    end
end

task.wait(0.05)
SetActiveTab("Movement")

MainWindow.Size = UDim2.new(0, 720, 0, 0)
MainWindow.BackgroundTransparency = 0.3
SpringTween(MainWindow, {
    Size = UDim2.new(0, 720, 0, 480),
    BackgroundTransparency = 0,
}, 0.55)

task.delay(0.6, function()
    Notify("Modular UI", "Loaded! Use the Dev tab to attach scripts.", "success", 5)
end)

UserInputService.InputBegan:Connect(function(inp, processed)
    if processed then return end
    if inp.KeyCode == Enum.KeyCode.RightShift then
        _Visible = not _Visible
        if _Visible then
            MainWindow.Visible = true
            SpringTween(MainWindow, {Size = UDim2.new(0,720,0,480)}, 0.35)
        else
            Tween(MainWindow, {Size = UDim2.new(0,720,0,0)}, 0.2)
            task.delay(0.22, function() MainWindow.Visible = false end)
        end
        PlaySound(SoundIDs.Open)
    end
end)

--[[
════════════════════════════════════════════════════════════
  HOW TO ADD YOUR OWN SCRIPT (from any AI)

  1. Run this LocalScript in Roblox Studio (StarterPlayerScripts)
     or inject it via your executor.

  2. Click a Tab in the sidebar (e.g. "Movement").

  3. Click "+ Add Control" → name it → pick type → "Add Control"

  4. Go to the "⚙ Dev" tab.
     - Type the tab name and control name into the boxes.
     - Click "Load".

  5. Paste the AI-generated code into the editor.
     The code runs with these variables available:
       • Buttons:  standard Roblox globals — game, workspace, etc.
       • Toggles:  same; return a function(dt) for a heartbeat loop.
       • Sliders:  variable `value` = current slider number.
       • Inputs:   variable `input` = current text string.

  6. Click "▶ Test" to trial without saving.
     Click "💾 Save" to commit. The control now uses your code.

  Press RightShift to hide/show the GUI.
════════════════════════════════════════════════════════════
--]]
