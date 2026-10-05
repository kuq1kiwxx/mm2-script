local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local VirtualInput      = game:GetService("VirtualInputManager")
local Workspace         = game:GetService("Workspace")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local STORE = (getgenv and getgenv()) or _G
if STORE.__MM2MINI_KILL then
    pcall(STORE.__MM2MINI_KILL)
end

local CFG = {
    PlayerESP   = false,
    CoinESP     = false,
    AutoFarm    = false,
    Aimbot      = false,
    AutoShoot   = false,
    FlingAura   = false,
    AimFov      = 240,
    AimSmooth   = 0.28,
    FarmSpeed   = 30,
    FarmHeight  = 3.2,
    FleeSpeed   = 110,
    DangerDist  = 54,
    CoinSafe    = 62,
    FlingPower  = 1.15e4,
}

local COLORS = {
    Murderer = Color3.fromRGB(220, 48, 48),
    Sheriff  = Color3.fromRGB(70, 140, 255),
    Hero     = Color3.fromRGB(70, 140, 255),
    Innocent = Color3.fromRGB(90, 210, 110),
    Unknown  = Color3.fromRGB(200, 200, 200),
    Coin     = Color3.fromRGB(255, 210, 50),
    Gun      = Color3.fromRGB(255, 160, 40),
}

local conns, uiTrash, highlights, tags = {}, {}, {}, {}
local farming, flinging, alive = false, false, true
local farmStatus, farmTween, manualUntil = "idle", nil, 0

local function bind(sig, fn)
    local c = sig:Connect(fn)
    table.insert(conns, c)
    return c
end

local function hook(inst, ev, fn)
    local c = inst[ev]:Connect(fn)
    table.insert(conns, c)
    return c
end

local function charOf(plr) return plr and plr.Character end
local function hrpOf(plr)
    local c = charOf(plr)
    return c and c:FindFirstChild("HumanoidRootPart")
end
local function humOf(plr)
    local c = charOf(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end
local function aliveOf(plr)
    local h = humOf(plr)
    return h and h.Health > 0
end

local KNIFE_KEYS = { "knife", "illumina", "sword", "blade", "scythe", "axe" }
local GUN_KEYS   = { "gun", "revolver", "pistol", "rifle", "shotgun" }

local function nameHit(n, keys)
    n = string.lower(n or "")
    for i = 1, #keys do
        if string.find(n, keys[i], 1, true) then return true end
    end
    return false
end

local function scanTools(plr, keys)
    local c = charOf(plr)
    local bp = plr:FindFirstChild("Backpack")
    local function pack(parent)
        if not parent then return false end
        for _, v in ipairs(parent:GetChildren()) do
            if v:IsA("Tool") and nameHit(v.Name, keys) then return true end
        end
        return false
    end
    return pack(c) or pack(bp)
end

local function roleOf(plr)
    if not plr or plr == LP then return "Unknown" end
    if not aliveOf(plr) then return "Unknown" end
    if scanTools(plr, KNIFE_KEYS) then return "Murderer" end
    if scanTools(plr, GUN_KEYS)   then return "Sheriff"  end
    return "Innocent"
end

local function myRole()
    if scanTools(LP, KNIFE_KEYS) then return "Murderer" end
    if scanTools(LP, GUN_KEYS)   then return "Sheriff"  end
    return "Innocent"
end

local function myGun()
    local c = charOf(LP)
    if not c then return nil end
    for _, v in ipairs(c:GetChildren()) do
        if v:IsA("Tool") and nameHit(v.Name, GUN_KEYS) then return v end
    end
    return nil
end

local function isCoin(obj)
    if not obj or not obj.Parent then return false end
    local n = string.lower(obj.Name)
    if n ~= "coin" and n ~= "coins" and n ~= "coincontainer" then
        if not string.find(n, "coin", 1, true) then return false end
    end
    if obj:IsA("BasePart") then return true end
    if obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart", true) then return true end
    return false
end

local function coinPart(obj)
    if obj:IsA("BasePart") then return obj end
    return obj:FindFirstChildWhichIsA("BasePart", true)
end

local function listCoins()
    local out = {}
    for _, v in ipairs(Workspace:GetDescendants()) do
        if isCoin(v) then
            local p = coinPart(v)
            if p and p.Parent then table.insert(out, p) end
        end
    end
    return out
end

local function droppedGun()
    for _, v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("Tool") and nameHit(v.Name, GUN_KEYS) and v.Parent == Workspace then
            return v
        end
        local n = string.lower(v.Name)
        if (n == "gundrop" or n == "droppedgun" or n == "gun drop") and v:IsA("BasePart") then
            return v
        end
    end
    return nil
end

local function clearAdorn(map, inst)
    local a = map[inst]
    if a then pcall(function() a:Destroy() end) map[inst] = nil end
end

local function ensureHighlight(inst, color)
    local h = highlights[inst]
    if not h or not h.Parent then
        h = Instance.new("Highlight")
        h.Name = "MM2MiniHL"
        h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        h.FillTransparency = 0.55
        h.OutlineTransparency = 0
        h.Parent = inst
        highlights[inst] = h
    end
    h.FillColor = color
    h.OutlineColor = color
    return h
end

local function ensureTag(part, text, color)
    local bb = tags[part]
    if not bb or not bb.Parent then
        bb = Instance.new("BillboardGui")
        bb.Name = "MM2MiniTag"
        bb.AlwaysOnTop = true
        bb.Size = UDim2.fromOffset(160, 28)
        bb.StudsOffset = Vector3.new(0, 2.6, 0)
        bb.MaxDistance = 400
        bb.Parent = part
        local tl = Instance.new("TextLabel")
        tl.Name = "T"
        tl.BackgroundTransparency = 1
        tl.Size = UDim2.fromScale(1, 1)
        tl.Font = Enum.Font.GothamBold
        tl.TextSize = 13
        tl.TextStrokeTransparency = 0.3
        tl.TextColor3 = Color3.new(1, 1, 1)
        tl.Parent = bb
        tags[part] = bb
    end
    local tl = bb:FindFirstChild("T")
    if tl then tl.Text = text tl.TextColor3 = color end
    return bb
end

local function wipeESP()
    for inst in pairs(highlights) do clearAdorn(highlights, inst) end
    for inst in pairs(tags) do clearAdorn(tags, inst) end
end

local function refreshPlayerESP()
    if not CFG.PlayerESP then
        for inst in pairs(highlights) do
            if inst:IsA("Model") then clearAdorn(highlights, inst) end
        end
        for inst in pairs(tags) do
            if inst.Name == "Head" or inst.Name == "HumanoidRootPart" then
                clearAdorn(tags, inst)
            end
        end
        return
    end
    local seen = {}
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP then
            local c = charOf(plr)
            local head = c and (c:FindFirstChild("Head") or hrpOf(plr))
            if c and head and aliveOf(plr) then
                local r = roleOf(plr)
                local col = COLORS[r] or COLORS.Unknown
                local dist = 0
                local me = hrpOf(LP)
                if me then dist = math.floor((head.Position - me.Position).Magnitude) end
                ensureHighlight(c, col)
                ensureTag(head, string.format("%s  [%s]  %dm", plr.Name, r, dist), col)
                seen[c] = true
                seen[head] = true
            end
        end
    end
    for inst in pairs(highlights) do
        if inst:IsA("Model") and inst:FindFirstChildOfClass("Humanoid") and not seen[inst] then
            clearAdorn(highlights, inst)
        end
    end
end

local function refreshWorldESP()
    if CFG.CoinESP then
        for _, p in ipairs(listCoins()) do
            ensureHighlight(p, COLORS.Coin)
            ensureTag(p, "coin", COLORS.Coin)
        end
    else
        for inst in pairs(highlights) do
            if inst:IsA("BasePart") and isCoin(inst) then
                clearAdorn(highlights, inst)
                clearAdorn(tags, inst)
            end
        end
    end
    local g = droppedGun()
    if g and CFG.PlayerESP then
        local part = g:IsA("Tool") and (g:FindFirstChild("Handle") or g:FindFirstChildWhichIsA("BasePart")) or g
        if part then
            ensureHighlight(part, COLORS.Gun)
            ensureTag(part, "GUN", COLORS.Gun)
        end
    end
end

local noclipOn = false
bind(RunService.Stepped, function()
    if not noclipOn then return end
    local c = charOf(LP)
    if not c then return end
    for _, p in ipairs(c:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

local function getMurderer()
    if myRole() == "Murderer" then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and aliveOf(plr) and roleOf(plr) == "Murderer" then
            return plr
        end
    end
    return nil
end

local function murdererHrp()
    return hrpOf(getMurderer())
end

local function distToMurderer(pos)
    local mh = murdererHrp()
    if not mh then return math.huge end
    return (mh.Position - pos).Magnitude
end

local function inDanger()
    local me = hrpOf(LP)
    if not me then return false, math.huge end
    local d = distToMurderer(me.Position)
    return d < CFG.DangerDist, d
end

local function murdererOnPath(from, to)
    local mh = murdererHrp()
    if not mh then return false end
    local a, b, m = from, to, mh.Position
    local ab = b - a
    local lab = ab.Magnitude
    if lab < 4 then return distToMurderer(to) < CFG.DangerDist end
    local t = math.clamp((m - a):Dot(ab) / (lab * lab), 0, 1)
    local closest = a + ab * t
    return (m - closest).Magnitude < 28
end

local function safestCoin()
    local hrp = hrpOf(LP)
    if not hrp then return nil end
    local mh = murdererHrp()
    local mpos = mh and mh.Position
    local best, bestScore = nil, math.huge
    for _, p in ipairs(listCoins()) do
        if p.Parent then
            local toMe = (p.Position - hrp.Position).Magnitude
            local toM  = mpos and (p.Position - mpos).Magnitude or 999
            if toM >= CFG.CoinSafe and not murdererOnPath(hrp.Position, p.Position) then
                local score = toMe - math.min(toM, 140) * 0.4
                if score < bestScore then best, bestScore = p, score end
            end
        end
    end
    return best
end

local function cancelFarmTween()
    if farmTween then
        pcall(function() farmTween:Cancel() end)
        farmTween = nil
    end
end

local function playerSteering()
    local hum = humOf(LP)
    return hum and hum.MoveDirection.Magnitude > 0.42
end

local function moveTo(pos, speed)
    local hrp = hrpOf(LP)
    if not hrp then return "dead" end
    cancelFarmTween()
    local dist = (hrp.Position - pos).Magnitude
    local t = math.clamp(dist / math.max(speed, 24), 0.05, 1.7)
    farmTween = TweenService:Create(hrp, TweenInfo.new(t, Enum.EasingStyle.Linear), {
        CFrame = CFrame.new(pos)
    })
    farmTween:Play()
    local finished = false
    local cc = farmTween.Completed:Connect(function() finished = true end)
    while CFG.AutoFarm and not finished do
        if not aliveOf(LP) then cancelFarmTween() cc:Disconnect() return "dead" end
        if playerSteering() then
            manualUntil = os.clock() + 2.5
            cancelFarmTween()
            cc:Disconnect()
            noclipOn = false
            return "manual"
        end
        if select(1, inDanger()) then cancelFarmTween() cc:Disconnect() return "danger" end
        RunService.Heartbeat:Wait()
    end
    cc:Disconnect()
    if not CFG.AutoFarm then return "stop" end
    return finished and "ok" or "stop"
end

local function fleeMurderer()
    local hrp = hrpOf(LP)
    local mh = murdererHrp()
    if not hrp then return end
    farmStatus = "убегаю"
    noclipOn = true
    local dir
    if mh then
        dir = hrp.Position - mh.Position
        if dir.Magnitude < 1 then dir = Vector3.new(1, 0, 0) else dir = dir.Unit end
    else
        dir = hrp.CFrame.LookVector * -1
    end
    local dest = hrp.Position + dir * 62 + Vector3.new(0, 10, 0)
    local safe = safestCoin()
    if safe and mh then
        local away = (safe.Position - hrp.Position)
        local fromM = (safe.Position - mh.Position).Magnitude
        if fromM > CFG.CoinSafe and away.Magnitude > 4 and away.Unit:Dot(dir) > 0.15 then
            dest = safe.Position + Vector3.new(0, CFG.FarmHeight + 4, 0)
        end
    end
    moveTo(dest, CFG.FleeSpeed)
end

local function farmLoop()
    if farming then return end
    farming = true
    task.spawn(function()
        while CFG.AutoFarm and alive do
            local hum = humOf(LP)
            if not hum or hum.Health <= 0 then
                farmStatus = "мёртв"
                cancelFarmTween()
                task.wait(0.35)
            elseif os.clock() < manualUntil or playerSteering() then
                farmStatus = "ручное"
                cancelFarmTween()
                noclipOn = false
                if playerSteering() then manualUntil = os.clock() + 2.5 end
                task.wait(0.1)
            elseif select(1, inDanger()) then
                fleeMurderer()
                task.wait(0.12)
            else
                local coin = safestCoin()
                if coin and coin.Parent then
                    farmStatus = "фарм"
                    noclipOn = true
                    local res = moveTo(coin.Position + Vector3.new(0, CFG.FarmHeight, 0), CFG.FarmSpeed)
                    if res == "ok" and coin.Parent and not select(1, inDanger()) then
                        local hrp = hrpOf(LP)
                        if hrp and distToMurderer(coin.Position) >= CFG.CoinSafe then
                            hrp.CFrame = CFrame.new(coin.Position + Vector3.new(0, 2.4, 0))
                        end
                    elseif res == "danger" then
                        fleeMurderer()
                    end
                    task.wait(0.05)
                else
                    farmStatus = "жду"
                    if select(1, inDanger()) then
                        fleeMurderer()
                    else
                        noclipOn = CFG.FlingAura
                    end
                    task.wait(0.22)
                end
            end
            if not CFG.AutoFarm then break end
        end
        cancelFarmTween()
        farmStatus = "idle"
        if not CFG.FlingAura then noclipOn = false end
        farming = false
    end)
end

local function screenFov(worldPos)
    local v, vis = Camera:WorldToViewportPoint(worldPos)
    if not vis or v.Z < 0 then return math.huge, v, false end
    local c = Vector2.new(Camera.ViewportSize.X * 0.5, Camera.ViewportSize.Y * 0.5)
    return (Vector2.new(v.X, v.Y) - c).Magnitude, v, true
end

local function aimTarget()
    local me = hrpOf(LP)
    if not me then return nil end
    local role = myRole()
    local best, bestScore = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and aliveOf(plr) then
            local head = charOf(plr) and charOf(plr):FindFirstChild("Head")
            if head then
                local r = roleOf(plr)
                local want = false
                if role == "Sheriff" or role == "Hero" then
                    want = (r == "Murderer")
                elseif role == "Murderer" then
                    want = true
                else
                    want = myGun() ~= nil and r == "Murderer"
                end
                if want then
                    local fov = screenFov(head.Position)
                    local d = (head.Position - me.Position).Magnitude
                    local score = fov + d * 0.15
                    if fov <= CFG.AimFov and score < bestScore then
                        best, bestScore = head, score
                    end
                end
            end
        end
    end
    return best
end

local shootAcc = 0
bind(RunService.RenderStepped, function(dt)
    Camera = Workspace.CurrentCamera
    if not CFG.Aimbot or not aliveOf(LP) then return end
    local tgt = aimTarget()
    if not tgt then return end
    local look = CFrame.new(Camera.CFrame.Position, tgt.Position)
    Camera.CFrame = Camera.CFrame:Lerp(look, math.clamp(CFG.AimSmooth + dt, 0.12, 1))
    if CFG.AutoShoot and myGun() then
        local fov = screenFov(tgt.Position)
        if fov < 48 then
            shootAcc += dt
            if shootAcc >= 0.11 then
                shootAcc = 0
                local gun = myGun()
                if gun then pcall(function() gun:Activate() end) end
                pcall(function()
                    local vs = Camera.ViewportSize
                    VirtualInput:SendMouseButtonEvent(vs.X * 0.5, vs.Y * 0.5, 0, true, game, 1)
                    VirtualInput:SendMouseButtonEvent(vs.X * 0.5, vs.Y * 0.5, 0, false, game, 1)
                end)
            end
        else
            shootAcc = 0
        end
    end
end)

local function resetVel(hrp)
    if not hrp then return end
    hrp.AssemblyLinearVelocity = Vector3.zero
    hrp.AssemblyAngularVelocity = Vector3.zero
end

local function nearestEnemy()
    local me = hrpOf(LP)
    if not me then return nil end
    local best, bestD = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LP and aliveOf(plr) then
            local h = hrpOf(plr)
            if h then
                local d = (h.Position - me.Position).Magnitude
                if d < bestD then best, bestD = plr, d end
            end
        end
    end
    return best
end

local function flingTarget(plr, seconds)
    if flinging then return end
    local hrp  = hrpOf(LP)
    local thrp = hrpOf(plr)
    local hum  = humOf(LP)
    if not hrp or not thrp or not hum then return end
    flinging = true
    noclipOn = true
    local saved = hrp.CFrame
    local sit = hum.Sit
    hum.Sit = true
    local t0 = os.clock()
    while os.clock() - t0 < (seconds or 1.05) do
        hrp = hrpOf(LP)
        thrp = hrpOf(plr)
        if not hrp or not thrp then break end
        hrp.CFrame = thrp.CFrame * CFrame.new(0, 0.4, 0)
        local dir = (thrp.Position - hrp.Position)
        if dir.Magnitude < 0.05 then dir = Vector3.new(0, 1, 0) else dir = dir.Unit end
        hrp.AssemblyLinearVelocity  = dir * CFG.FlingPower + Vector3.new(0, CFG.FlingPower * 0.45, 0)
        hrp.AssemblyAngularVelocity = Vector3.new(CFG.FlingPower, CFG.FlingPower, CFG.FlingPower)
        RunService.Heartbeat:Wait()
    end
    hum = humOf(LP)
    hrp = hrpOf(LP)
    if hum then hum.Sit = sit hum.PlatformStand = false end
    if hrp then resetVel(hrp) hrp.CFrame = saved end
    if not CFG.AutoFarm and not CFG.FlingAura then noclipOn = false end
    flinging = false
end

bind(RunService.Heartbeat, function()
    if not CFG.FlingAura or flinging or CFG.AutoFarm then return end
    if not aliveOf(LP) then return end
    local me = hrpOf(LP)
    if not me then return end
    noclipOn = true
    me.AssemblyAngularVelocity = Vector3.new(0, 180, 0)
    local victim = nearestEnemy()
    local vh = victim and hrpOf(victim)
    if vh and (vh.Position - me.Position).Magnitude < 7 then
        task.spawn(flingTarget, victim, 0.85)
    end
end)

local gui = Instance.new("ScreenGui")
gui.Name = "MM2Mini"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.DisplayOrder = 999
pcall(function() gui.Parent = LP:WaitForChild("PlayerGui") end)
if not gui.Parent then gui.Parent = LP:FindFirstChildOfClass("PlayerGui") or LP end
table.insert(uiTrash, gui)

local function scaleFactor()
    local vs = Camera.ViewportSize
    local short = math.min(vs.X, vs.Y)
    if short < 500 then return 0.92 end
    if short < 800 then return 1.00 end
    return 1.08
end

local uiScale = Instance.new("UIScale")
uiScale.Scale = scaleFactor()
uiScale.Parent = gui

local fab = Instance.new("TextButton")
fab.Name = "Fab"
fab.Size = UDim2.fromOffset(46, 46)
fab.Position = UDim2.new(1, -58, 0, 72)
fab.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
fab.Text = "MM"
fab.TextColor3 = Color3.fromRGB(255, 70, 80)
fab.Font = Enum.Font.GothamBlack
fab.TextSize = 16
fab.AutoButtonColor = true
fab.Parent = gui
Instance.new("UICorner", fab).CornerRadius = UDim.new(1, 0)
local fabStroke = Instance.new("UIStroke", fab)
fabStroke.Color = Color3.fromRGB(255, 70, 80)
fabStroke.Thickness = 1.4

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Visible = false
panel.Size = UDim2.fromOffset(188, 292)
panel.Position = UDim2.new(1, -206, 0, 72)
panel.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
panel.BackgroundTransparency = 0.08
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
local pStroke = Instance.new("UIStroke", panel)
pStroke.Color = Color3.fromRGB(255, 70, 80)
pStroke.Thickness = 1
pStroke.Transparency = 0.35

local header = Instance.new("TextButton")
header.Name = "Hdr"
header.Size = UDim2.new(1, 0, 0, 30)
header.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
header.Text = "  MM2 mini"
header.TextXAlignment = Enum.TextXAlignment.Left
header.Font = Enum.Font.GothamBold
header.TextSize = 13
header.TextColor3 = Color3.fromRGB(235, 235, 240)
header.AutoButtonColor = false
header.Parent = panel
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 10)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.fromOffset(28, 22)
hideBtn.Position = UDim2.new(1, -34, 0, 4)
hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
hideBtn.Text = "-"
hideBtn.TextColor3 = Color3.new(1, 1, 1)
hideBtn.Font = Enum.Font.GothamBold
hideBtn.TextSize = 16
hideBtn.Parent = header
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 6)

local list = Instance.new("Frame")
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(8, 36)
list.Size = UDim2.new(1, -16, 1, -70)
list.Parent = panel
local lay = Instance.new("UIListLayout", list)
lay.Padding = UDim.new(0, 5)
lay.SortOrder = Enum.SortOrder.LayoutOrder

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.new(0, 8, 1, -28)
status.Size = UDim2.new(1, -16, 0, 22)
status.Font = Enum.Font.Gotham
status.TextSize = 11
status.TextColor3 = Color3.fromRGB(160, 160, 170)
status.TextXAlignment = Enum.TextXAlignment.Left
status.Text = "idle"
status.Parent = panel

local function mkToggle(title, key, order)
    local b = Instance.new("TextButton")
    b.LayoutOrder = order
    b.Size = UDim2.new(1, 0, 0, 30)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 13
    b.AutoButtonColor = true
    b.Parent = list
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 7)
    local function paint()
        local on = CFG[key]
        b.Text = (on and "*  " or "o  ") .. title
        b.BackgroundColor3 = on and Color3.fromRGB(36, 90, 52) or Color3.fromRGB(32, 32, 40)
        b.TextColor3 = on and Color3.fromRGB(180, 255, 190) or Color3.fromRGB(210, 210, 218)
    end
    paint()
    b.MouseButton1Click:Connect(function()
        CFG[key] = not CFG[key]
        paint()
        if key == "AutoFarm" and CFG.AutoFarm then farmLoop() end
        if (key == "PlayerESP" or key == "CoinESP") and not CFG.PlayerESP and not CFG.CoinESP then wipeESP() end
        if key == "FlingAura" and not CFG.FlingAura and not CFG.AutoFarm then
            noclipOn = false
            resetVel(hrpOf(LP))
        end
    end)
end

mkToggle("ESP игроков", "PlayerESP", 1)
mkToggle("ESP монет",   "CoinESP",   2)
mkToggle("Фарм монет",  "AutoFarm",  3)
mkToggle("Аимбот",      "Aimbot",    4)
mkToggle("Автовыстрел", "AutoShoot", 5)
mkToggle("Флинг-аура",  "FlingAura", 6)

local flingBtn = Instance.new("TextButton")
flingBtn.LayoutOrder = 7
flingBtn.Size = UDim2.new(1, 0, 0, 30)
flingBtn.BackgroundColor3 = Color3.fromRGB(90, 32, 38)
flingBtn.Text = "Флинг ближайшего"
flingBtn.TextColor3 = Color3.fromRGB(255, 190, 190)
flingBtn.Font = Enum.Font.GothamMedium
flingBtn.TextSize = 13
flingBtn.Parent = list
Instance.new("UICorner", flingBtn).CornerRadius = UDim.new(0, 7)
flingBtn.MouseButton1Click:Connect(function()
    local t = nearestEnemy()
    if t then task.spawn(flingTarget, t, 1.1) end
end)

local function setOpen(on)
    panel.Visible = on
    fab.Visible = not on
end
fab.MouseButton1Click:Connect(function() setOpen(true) end)
hideBtn.MouseButton1Click:Connect(function() setOpen(false) end)

local function makeDraggable(handle, target)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        startInput = input.Position
        startPos = target.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)
    bind(UserInputService.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - startInput
        local vs = Camera.ViewportSize
        local s = uiScale.Scale
        local w = target.AbsoluteSize.X
        local h = target.AbsoluteSize.Y
        local ax = target.Position.X.Scale
        local ay = target.Position.Y.Scale
        local x
        if ax == 1 then
            x = math.clamp(startPos.X.Offset + d.X, -vs.X / s + 8, -w / s)
        else
            x = math.clamp(startPos.X.Offset + d.X, 8, vs.X / s - w / s - 8)
        end
        local y = math.clamp(startPos.Y.Offset + d.Y, 8, vs.Y / s - h / s - 8)
        target.Position = UDim2.new(ax, x, ay, y)
        if target == panel then
            fab.Position = UDim2.new(ax, x, ay, y)
        elseif target == fab then
            panel.Position = UDim2.new(ax, x, ay, y)
        end
    end)
end
makeDraggable(header, panel)
makeDraggable(fab, fab)

local acc = 0
bind(RunService.Heartbeat, function(dt)
    acc += dt
    if acc < 0.18 then return end
    acc = 0
    alive = aliveOf(LP)
    pcall(refreshPlayerESP)
    pcall(refreshWorldESP)
    local coins = #listCoins()
    local bits = { myRole(), coins .. " coins" }
    if CFG.AutoFarm then table.insert(bits, farmStatus) end
    if CFG.Aimbot then table.insert(bits, "aim") end
    if CFG.FlingAura then table.insert(bits, "fling") end
    status.Text = table.concat(bits, "  |  ")
end)

hook(LP, "CharacterAdded", function()
    alive = true
    cancelFarmTween()
    noclipOn = CFG.AutoFarm or CFG.FlingAura
    task.wait(0.6)
    if CFG.AutoFarm then farmLoop() end
end)

bind(Players.PlayerRemoving, function(plr)
    local c = charOf(plr)
    if c then
        clearAdorn(highlights, c)
        local head = c:FindFirstChild("Head")
        if head then clearAdorn(tags, head) end
    end
end)

bind(UserInputService.InputBegan, function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.F6 then
        setOpen(not panel.Visible)
    end
end)

local function shutdown()
    CFG.AutoFarm = false
    CFG.FlingAura = false
    CFG.Aimbot = false
    CFG.PlayerESP = false
    CFG.CoinESP = false
    noclipOn = false
    cancelFarmTween()
    wipeESP()
    resetVel(hrpOf(LP))
    for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
    for _, u in ipairs(uiTrash) do pcall(function() u:Destroy() end) end
    table.clear(conns)
    table.clear(uiTrash)
    STORE.__MM2MINI_KILL = nil
end
STORE.__MM2MINI_KILL = shutdown

setOpen(false)
print("[MM2 mini] loaded | кнопка MM справа сверху | RightShift / F6")
