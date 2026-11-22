--[[ Reconnect by fldzxc — safe rejoin (без хука Kick) ]]
-- Твой репо: fallonworkbylove/fldzxc-reconnect
-- Chris12089/atlasbss — только rewrite.lua автора
local BRAND = "Reconnect by fldzxc"
local SELF = "https://raw.githubusercontent.com/fallonworkbylove/fldzxc-reconnect/main/reconnect.lua"
local URL = "https://raw.githubusercontent.com/Chris12089/atlasbss/main/rewrite.lua"
local INTERVAL = 7200
local SAVE_WAIT, NET_WAIT, NORMAL_WAIT = 180, 12, 6
local MAX_TRIES = 5

local genv = (getgenv and getgenv()) or _G
if genv.__fldzxc_reconnect then return end
genv.__fldzxc_reconnect = true

local cr = cloneref or function(x) return x end
local Players = cr(game:GetService("Players"))
local TS = cr(game:GetService("TeleportService"))
local GS = cr(game:GetService("GuiService"))
local Tween = cr(game:GetService("TweenService"))
local LP, PlaceId = Players.LocalPlayer, game.PlaceId
local qot = queue_on_teleport or queueonteleport
local clearQ = clearteleportqueue or clear_teleport_queue or clearqueueonteleport
local httpReq = request or http_request or (syn and syn.request)

local busy, lastAt, lastMsg = false, 0, ""
local statusLbl, bar

local C = {
	panel = Color3.fromRGB(22, 23, 26),
	line = Color3.fromRGB(58, 52, 42),
	gold = Color3.fromRGB(232, 196, 120),
	cream = Color3.fromRGB(244, 238, 226),
	mute = Color3.fromRGB(148, 142, 132),
	warn = Color3.fromRGB(232, 168, 96),
	bad = Color3.fromRGB(220, 108, 98),
	ok = Color3.fromRGB(160, 210, 150),
	ink = Color3.fromRGB(12, 13, 15),
}

local function ui(class, props, parent)
	local o = Instance.new(class)
	for k, v in pairs(props) do o[k] = v end
	if parent then o.Parent = parent end
	return o
end

local function setStatus(t, tone)
	print("[fldzxc]", t)
	if not statusLbl then return end
	statusLbl.Text = t
	local c = tone == "ok" and C.ok or tone == "warn" and C.warn or tone == "bad" and C.bad or C.mute
	statusLbl.TextColor3 = c
	if bar then bar.BackgroundColor3 = c end
end

-- UI
pcall(function()
	local host = (gethui and gethui()) or LP:WaitForChild("PlayerGui")
	local gui = ui("ScreenGui", { Name = "FldzxcReconnect", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 1e6 }, host)

	local splash = ui("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.ink, BackgroundTransparency = 0.25, BorderSizePixel = 0, ZIndex = 40 }, gui)
	local card = ui("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(280, 118), BackgroundColor3 = C.panel, BorderSizePixel = 0, ZIndex = 41,
	}, splash)
	ui("UICorner", { CornerRadius = UDim.new(0, 12) }, card)
	ui("UIStroke", { Color = C.line, Thickness = 1, Transparency = 0.15 }, card)
	ui("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 22), Size = UDim2.new(1, -40, 0, 22),
		Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = C.cream, TextXAlignment = Enum.TextXAlignment.Left,
		Text = BRAND, ZIndex = 42,
	}, card)
	ui("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(20, 48), Size = UDim2.new(1, -40, 0, 16),
		Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = C.mute, TextXAlignment = Enum.TextXAlignment.Left,
		Text = "safe reconnect", ZIndex = 42,
	}, card)
	local track = ui("Frame", { Position = UDim2.fromOffset(20, 84), Size = UDim2.new(1, -40, 0, 5), BackgroundColor3 = C.ink, BorderSizePixel = 0, ZIndex = 42 }, card)
	ui("UICorner", { CornerRadius = UDim.new(1, 0) }, track)
	local fill = ui("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.gold, BorderSizePixel = 0, ZIndex = 43 }, track)
	ui("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
	task.spawn(function()
		local tw = Tween:Create(fill, TweenInfo.new(0.9, Enum.EasingStyle.Quart), { Size = UDim2.fromScale(1, 1) })
		tw:Play(); tw.Completed:Wait(); task.wait(0.1)
		Tween:Create(splash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		for _, d in ipairs(splash:GetDescendants()) do
			if d:IsA("TextLabel") then Tween:Create(d, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
			elseif d:IsA("Frame") and d ~= splash then Tween:Create(d, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
			elseif d:IsA("UIStroke") then Tween:Create(d, TweenInfo.new(0.25), { Transparency = 1 }):Play() end
		end
		task.wait(0.35); splash:Destroy()
	end)

	local hud = ui("Frame", {
		Position = UDim2.fromOffset(14, 14), Size = UDim2.fromOffset(280, 48),
		BackgroundColor3 = C.panel, BackgroundTransparency = 0.05, BorderSizePixel = 0, ZIndex = 10,
	}, gui)
	ui("UICorner", { CornerRadius = UDim.new(0, 10) }, hud)
	ui("UIStroke", { Color = C.line, Thickness = 1, Transparency = 0.25 }, hud)
	bar = ui("Frame", { Position = UDim2.fromOffset(7, 9), Size = UDim2.new(0, 3, 1, -18), BackgroundColor3 = C.gold, BorderSizePixel = 0, ZIndex = 11 }, hud)
	ui("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
	ui("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 6), Size = UDim2.new(1, -24, 0, 16),
		Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = C.cream, TextXAlignment = Enum.TextXAlignment.Left,
		Text = BRAND, ZIndex = 11,
	}, hud)
	statusLbl = ui("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 24), Size = UDim2.new(1, -24, 0, 14),
		Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.mute, TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd, Text = "starting…", ZIndex = 11,
	}, hud)
end)

local function classify(m)
	m = string.lower(tostring(m or ""))
	if m:find("still saving", 1, true) or m:find("previous server", 1, true) or m:find("267", 1, true) then
		return SAVE_WAIT, "save"
	end
	if m:find("277", 1, true) or m:find("769", 1, true) or m:find("internet", 1, true) or m:find("reconnect", 1, true) or m:find("connection", 1, true) then
		return NET_WAIT, "net"
	end
	return NORMAL_WAIT, "kick"
end

local function fetch(url)
	local ok, body = pcall(function()
		return httpget and httpget(url) or game:HttpGet(url)
	end)
	if ok and type(body) == "string" and #body > 0 then return body end
	if httpReq then
		local r = httpReq({ Url = url, Method = "GET" })
		if r and (r.Success or r.StatusCode == 200) and r.Body then return r.Body end
	end
	error("fetch failed")
end

local function queueInject()
	if not qot then return end
	if clearQ then pcall(clearQ) end
	-- после телепорта снова этот reconnect (твой GitHub), он инжектит rewrite
	qot(('loadstring(game:HttpGet("%s"))()'):format(SELF))
end

local function inject()
	local ok, err = pcall(function()
		local fn, e = loadstring(fetch(URL))
		assert(fn, e)
		fn()
	end)
	setStatus(ok and ("injected · " .. os.date("%H:%M:%S")) or ("inject fail"), ok and "ok" or "bad")
	if not ok then warn("[fldzxc]", err) end
	return ok
end

-- мягкий телепорт: без глушения Kick, без namecall-хуков
local function softTeleport()
	queueInject()
	task.wait(0.35)
	local ok = pcall(function()
		TS:Teleport(PlaceId, LP)
	end)
	if ok then return true end
	return pcall(function()
		TS:TeleportAsync(PlaceId, { LP }, Instance.new("TeleportOptions"))
	end)
end

local function rejoin(msg)
	if busy then return end
	busy = true

	local waitSec, kind = classify(msg)
	for left = waitSec, 1, -1 do
		setStatus(("rejoin · %s · %ds"):format(kind, left), "warn")
		task.wait(1)
	end

	for i = 1, MAX_TRIES do
		setStatus(("teleport %d/%d"):format(i, MAX_TRIES), "warn")
		local ok = softTeleport()
		if ok then
			setStatus("teleport sent", "ok")
			-- не сбрасываем busy: клиент уходит в телепорт
			return
		end
		task.wait(3 + i)
	end

	busy = false
	setStatus("failed · manual rejoin", "bad")
end

local function onDisconnect(msg, src)
	msg = tostring(msg or src or "disconnect")
	local now = os.clock()
	if (now - lastAt) < 6 and msg == lastMsg then return end
	lastAt, lastMsg = now, msg
	setStatus("disconnect · " .. src, "warn")
	task.spawn(rejoin, msg)
end

-- Только безопасные сигналы (без hookfunction / hookmetamethod на Kick)
pcall(function()
	GS.ErrorMessageChanged:Connect(function(m)
		if m and tostring(m) ~= "" then
			onDisconnect(m, "Error")
		end
	end)
end)

pcall(function()
	TS.TeleportInitFailed:Connect(function(player, result, err)
		if player ~= LP then return end
		busy = false
		onDisconnect(tostring(err or result), "TeleportFail")
	end)
end)

-- если игрока уже выкинуло — пробуем мягко
pcall(function()
	Players.PlayerRemoving:Connect(function(p)
		if p == LP then
			onDisconnect("PlayerRemoving", "Leave")
		end
	end)
end)

task.spawn(function()
	task.wait(1.2)
	setStatus("online", "ok")
	inject()
	while true do
		task.wait(INTERVAL)
		inject()
	end
end)
