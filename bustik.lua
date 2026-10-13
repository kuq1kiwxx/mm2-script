local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("MM2VisualUI")
if old then old:Destroy() end

local items = {
    {name = "Chroma Godly", rarity = "CHROMA", icon = "🌈", color = Color3.fromRGB(205, 100, 255)},
    {name = "Icebreaker", rarity = "ANCIENT", icon = "❄️", color = Color3.fromRGB(100, 210, 255)},
    {name = "Harvester", rarity = "GODLY", icon = "⚔️", color = Color3.fromRGB(255, 95, 105)},
    {name = "Bat", rarity = "GODLY", icon = "🦇", color = Color3.fromRGB(180, 100, 255)},
    {name = "Luger", rarity = "GODLY", icon = "🔫", color = Color3.fromRGB(255, 190, 70)},
    {name = "Eternal", rarity = "GODLY", icon = "🔪", color = Color3.fromRGB(100, 255, 170)},
    {name = "Bioblade", rarity = "GODLY", icon = "🧪", color = Color3.fromRGB(100, 255, 190)},
    {name = "Seer", rarity = "GODLY", icon = "💎", color = Color3.fromRGB(100, 200, 255)},
    {name = "Laser", rarity = "GODLY", icon = "🔴", color = Color3.fromRGB(255, 90, 90)},
    {name = "Default Knife", rarity = "COMMON", icon = "🔪", color = Color3.fromRGB(175, 180, 195)},
}

local gui = Instance.new("ScreenGui")
gui.Name = "MM2VisualUI"
gui.ResetOnSpawn = false
gui.DisplayOrder = 50
gui.Parent = playerGui

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    obj.Parent = parent
    return obj
end

local function corner(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, obj)
end

local function stroke(obj, color, thickness)
    make("UIStroke", {
        Color = color or Color3.fromRGB(55, 60, 78),
        Thickness = thickness or 1
    }, obj)
end

local bg = Color3.fromRGB(19, 21, 29)
local panel = Color3.fromRGB(28, 31, 42)
local panel2 = Color3.fromRGB(36, 40, 53)
local white = Color3.fromRGB(240, 242, 250)
local muted = Color3.fromRGB(155, 163, 183)
local accent = Color3.fromRGB(140, 105, 255)

-- Floating reopen button
local toggle = make("TextButton", {
    Name = "OpenButton",
    Size = UDim2.fromOffset(54, 48),
    Position = UDim2.new(0, 14, 0.5, -24),
    BackgroundColor3 = accent,
    Text = "MM2",
    TextColor3 = white,
    TextSize = 16,
    Font = Enum.Font.GothamBold,
    AutoButtonColor = true
}, gui)
corner(toggle, 13)

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(0.92, 0, 0.78, 0),
    BackgroundColor3 = bg,
    BorderSizePixel = 0,
    ClipsDescendants = true
}, gui)
corner(main, 16)
stroke(main, Color3.fromRGB(66, 69, 94), 1)

make("UISizeConstraint", {
    MinSize = Vector2.new(290, 320),
    MaxSize = Vector2.new(560, 540)
}, main)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 55),
    BackgroundColor3 = panel,
    BorderSizePixel = 0
}, main)

make("TextLabel", {
    Position = UDim2.new(0, 14, 0, 0),
    Size = UDim2.new(1, -70, 1, 0),
    BackgroundTransparency = 1,
    Text = "MM2  /  VISUAL TOOLS",
    TextColor3 = white,
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold
}, header)

local close = make("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(34, 34),
    BackgroundColor3 = panel2,
    Text = "×",
    TextColor3 = white,
    TextSize = 23,
    Font = Enum.Font.GothamMedium
}, header)
corner(close, 9)

local tabs = make("Frame", {
    Position = UDim2.new(0, 10, 0, 63),
    Size = UDim2.new(1, -20, 0, 39),
    BackgroundTransparency = 1
}, main)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, tabs)

local pages = {}
local tabButtons = {}

local function makePage(name)
    local page = make("ScrollingFrame", {
        Name = name,
        Position = UDim2.new(0, 10, 0, 111),
        Size = UDim2.new(1, -20, 1, -121),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 4,
        ScrollBarImageColor3 = accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, main)

    make("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder
    }, page)

    pages[name] = page
    return page
end

local tradePage = makePage("Trade")
local spawnPage = makePage("Spawner")

local function makeTab(name, order)
    local b = make("TextButton", {
        Name = name,
        LayoutOrder = order,
        Size = UDim2.new(0.5, -4, 1, 0),
        BackgroundColor3 = panel2,
        Text = name == "Trade" and "⇄  VISUAL TRADE" or "✦  SPAWNER",
        TextColor3 = muted,
        TextSize = 12,
        Font = Enum.Font.GothamBold
    }, tabs)
    corner(b, 9)
    tabButtons[name] = b
    return b
end

local tradeTab = makeTab("Trade", 1)
local spawnTab = makeTab("Spawner", 2)

local function switchPage(name)
    for n, p in pairs(pages) do
        p.Visible = n == name
    end
    for n, b in pairs(tabButtons) do
        b.BackgroundColor3 = n == name and accent or panel2
        b.TextColor3 = n == name and white or muted
    end
end

tradeTab.Activated:Connect(function() switchPage("Trade") end)
spawnTab.Activated:Connect(function() switchPage("Spawner") end)

local function label(parent, text, height, color, size)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, height or 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = color or white,
        TextSize = size or 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium
    }, parent)
end

local function button(parent, text, height, color)
    local b = make("TextButton", {
        Size = UDim2.new(1, 0, 0, height or 38),
        BackgroundColor3 = color or panel2,
        Text = text,
        TextColor3 = white,
        TextSize = 12,
        TextWrapped = true,
        Font = Enum.Font.GothamMedium,
        AutoButtonColor = true
    }, parent)
    corner(b, 9)
    return b
end

-- VISUAL TRADE
label(tradePage, "DEMO TRADE  •  LOCAL SIMULATION", 27, muted, 11)

local status = label(tradePage, "Status: Waiting for your offer", 30, Color3.fromRGB(180, 160, 255), 12)

local offerBox = make("Frame", {
    Size = UDim2.new(1, 0, 0, 98),
    BackgroundColor3 = panel,
    BorderSizePixel = 0
}, tradePage)
corner(offerBox, 10)

label(offerBox, "YOUR OFFER", 25, muted, 11).Position = UDim2.new(0, 10, 0, 4)

local offerText = make("TextLabel", {
    Position = UDim2.new(0, 10, 0, 29),
    Size = UDim2.new(1, -20, 0, 58),
    BackgroundTransparency = 1,
    Text = "No items selected",
    TextColor3 = white,
    TextSize = 12,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
    Font = Enum.Font.Gotham
}, offerBox)

local otherBox = make("Frame", {
    Size = UDim2.new(1, 0, 0, 68),
    BackgroundColor3 = panel,
    BorderSizePixel = 0
}, tradePage)
corner(otherBox, 10)

label(otherBox, "OTHER PLAYER  •  PREVIEW", 25, muted, 11).Position = UDim2.new(0, 10, 0, 4)
label(otherBox, "DemoPlayer: Icebreaker (visual only)", 30, white, 12).Position = UDim2.new(0, 10, 0, 30)

label(tradePage, "TAP AN ITEM TO ADD OR REMOVE", 24, muted, 10)

local selected = {}
local selectedOrder = {}

local function updateOffer()
    local names = {}
    for _, item in ipairs(selectedOrder) do
        if selected[item.name] then
            table.insert(names, item.icon .. " " .. item.name)
        end
    end
    offerText.Text = #names > 0 and table.concat(names, "\n") or "No items selected"
end

for _, item in ipairs(items) do
    local b = button(tradePage, item.icon .. "   " .. item.name .. "   •   " .. item.rarity, 37)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Activated:Connect(function()
        if selected[item.name] then
            selected[item.name] = nil
            b.BackgroundColor3 = panel2
        else
            if #selectedOrder >= 20 then
                status.Text = "Offer limit reached"
                return
            end
            selected[item.name] = true
            table.insert(selectedOrder, item)
            b.BackgroundColor3 = Color3.fromRGB(65, 55, 100)
        end
        updateOffer()
        status.Text = "Status: Offer edited (local only)"
    end)
end

local actions = make("Frame", {
    Size = UDim2.new(1, 0, 0, 40),
    BackgroundTransparency = 1
}, tradePage)

make("UIListLayout", {
    FillDirection = Enum.FillDirection.Horizontal,
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder
}, actions)

local accept = make("TextButton", {
    LayoutOrder = 1,
    Size = UDim2.new(0.5, -4, 1, 0),
    BackgroundColor3 = Color3.fromRGB(42, 155, 100),
    Text = "✓  ACCEPT DEMO",
    TextColor3 = white,
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, actions)
corner(accept, 9)

local decline = make("TextButton", {
    LayoutOrder = 2,
    Size = UDim2.new(0.5, -4, 1, 0),
    BackgroundColor3 = Color3.fromRGB(155, 62, 75),
    Text = "✕  DECLINE",
    TextColor3 = white,
    TextSize = 11,
    Font = Enum.Font.GothamBold
}, actions)
corner(decline, 9)

accept.Activated:Connect(function()
    status.Text = "Demo accepted locally — no real trade occurred"
end)

decline.Activated:Connect(function()
    table.clear(selected)
    table.clear(selectedOrder)
    updateOffer()
    for _, child in ipairs(tradePage:GetChildren()) do
        if child:IsA("TextButton") and child ~= accept and child ~= decline then
            child.BackgroundColor3 = panel2
        end
    end
    status.Text = "Demo declined / offer cleared"
end)

-- VISUAL SPAWNER
label(spawnPage, "VISUAL ITEM SPAWNER", 27, muted, 11)
label(spawnPage, "Select an item to add a preview card below.", 34, white, 12)

local preview = make("Frame", {
    Size = UDim2.new(1, 0, 0, 105),
    BackgroundColor3 = panel,
    BorderSizePixel = 0
}, spawnPage)
corner(preview, 11)

local previewIcon = make("TextLabel", {
    Position = UDim2.new(0, 12, 0, 10),
    Size = UDim2.fromOffset(70, 70),
    BackgroundColor3 = panel2,
    Text = "✦",
    TextColor3 = accent,
    TextSize = 32,
    Font = Enum.Font.GothamBold
}, preview)
corner(previewIcon, 10)

local previewName = make("TextLabel", {
    Position = UDim2.new(0, 92, 0, 12),
    Size = UDim2.new(1, -102, 0, 35),
    BackgroundTransparency = 1,
    Text = "No item selected",
    TextColor3 = white,
    TextSize = 14,
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.GothamBold
}, preview)

local previewRarity = make("TextLabel", {
    Position = UDim2.new(0, 92, 0, 49),
    Size = UDim2.new(1, -102, 0, 28),
    BackgroundTransparency = 1,
    Text = "VISUAL PREVIEW",
    TextColor3 = muted,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Font = Enum.Font.Gotham
}, preview)

local count = 0
local history = make("Frame", {
    Size = UDim2.new(1, 0, 0, 20),
    BackgroundTransparency = 1
}, spawnPage)

label(history, "SPAWN HISTORY", 20, muted, 11)

local historyList = make("Frame", {
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundTransparency = 1
}, spawnPage)

make("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder
}, historyList)

for _, item in ipairs(items) do
    local b = button(spawnPage, item.icon .. "   " .. item.name .. "   •   " .. item.rarity, 37)
    b.TextXAlignment = Enum.TextXAlignment.Left
    b.Activated:Connect(function()
        previewIcon.Text = item.icon
        previewIcon.TextColor3 = item.color
        previewName.Text = item.name
        previewRarity.Text = item.rarity .. "  •  VISUAL ONLY"
        previewRarity.TextColor3 = item.color

        count += 1
        local entry = make("TextLabel", {
            LayoutOrder = count,
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = panel,
            Text = item.icon .. "   " .. item.name .. "   •   Preview #" .. count,
            TextColor3 = white,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
            Font = Enum.Font.Gotham
        }, historyList)
        corner(entry, 8)
    end)
end

local clearHistory = button(spawnPage, "CLEAR PREVIEW HISTORY", 36, Color3.fromRGB(100, 55, 70))
clearHistory.Activated:Connect(function()
    for _, child in ipairs(historyList:GetChildren()) do
        if child:IsA("TextLabel") then
            child:Destroy()
        end
    end
    count = 0
    previewIcon.Text = "✦"
    previewIcon.TextColor3 = accent
    previewName.Text = "No item selected"
    previewRarity.Text = "VISUAL PREVIEW"
    previewRarity.TextColor3 = muted
end)

-- Open / close
close.Activated:Connect(function()
    main.Visible = false
    toggle.Visible = true
end)

toggle.Activated:Connect(function()
    main.Visible = true
    toggle.Visible = false
end)

-- Drag the window with mouse or touch
local dragging = false
local dragInput
local dragStart
local startPos

header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

header.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and input == dragInput then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

switchPage("Trade")
toggle.Visible = false

print("MM2 Visual UI loaded. All trades and spawns are local previews.")
