-- StrayAP v0.0.4 / Safe Sync experimental (2026-11-10)
-- Drop-in replacement for the upstream main.lua. Keeps StrayAP's original
-- network and location-check hooks, but synchronizes inventory non-destructively.
print("[ArchipelagoMod] Safe Sync client loading")
local AP = require "lua-apclientpp"
local UEHelpers = require "UEHelpers"
local receiving = require "receiving"
local sending = require "sending"

local game_name = "Stray"
local client_version = {0, 6, 7}
local version = "v0.0.4"
local compatible = {"v0.0.1", "v0.0.2", "v0.0.3", "v0.0.4"}
local message_format = AP.RenderFormat.TEXT
local uuid = ""

ap = nil
pending_game_actions = {}
all_received_items = {}
slot_data = {}
APMessageFeed = nil
APFeedScrollBox = nil
currentGameProgression = 0
scrollPending = false

local session_number = 0
local latest_message = 0
local show_hud = true
local textClass = nil
local seen_receipts = {}
local debug_bound = false
local debug_widget = nil

local function log(message)
    print("[ArchipelagoMod] " .. tostring(message))
end

local function enqueueMessage(message)
    pending_game_actions[#pending_game_actions + 1] = {
        type = "message", text = tostring(message)
    }
end

function SetupUI()
    if not show_hud then return end
    local world = UEHelpers:GetWorld()
    if not world or not world:IsValid() then return end
    local widgetClass = StaticFindObject("/Script/UMG.UserWidget")
    local treeClass = StaticFindObject("/Script/UMG.WidgetTree")
    local canvasClass = StaticFindObject("/Script/UMG.CanvasPanel")
    local scrollClass = StaticFindObject("/Script/UMG.ScrollBox")
    local verticalClass = StaticFindObject("/Script/UMG.VerticalBox")
    textClass = StaticFindObject("/Script/UMG.TextBlock")
    if not widgetClass or not treeClass or not canvasClass or
       not scrollClass or not verticalClass or not textClass then
        log("HUD classes unavailable")
        return
    end

    -- World changes invalidate widgets. Do not use the old feed.
    APMessageFeed = nil
    APFeedScrollBox = nil
    local widget = StaticConstructObject(widgetClass, world, 0, 0, 0, nil, false, false, nil)
    local tree = StaticConstructObject(treeClass, widget, 0, 0, 0, nil, false, false, nil)
    widget.WidgetTree = tree
    local canvas = StaticConstructObject(canvasClass, tree, 0, 0, 0, nil, false, false, nil)
    tree.RootWidget = canvas
    local scroll = StaticConstructObject(scrollClass, tree, 0, 0, 0, nil, false, false, nil)
    local slot = canvas:AddChildToCanvas(scroll)
    slot:SetAnchors({Minimum={X=0.02, Y=0.55}, Maximum={X=0.35, Y=0.98}})
    local feed = StaticConstructObject(verticalClass, tree, 0, 0, 0, nil, false, false, nil)
    scroll:AddChild(feed)
    widget:AddToViewport(999)
    APFeedScrollBox = scroll
    APMessageFeed = feed
end

function AddMessageToAPFeed(message)
    if not show_hud then return end
    if not APMessageFeed or not APMessageFeed:IsValid() then SetupUI() end
    local feed = APMessageFeed
    if not feed or not feed:IsValid() then return end
    local newText = StaticConstructObject(textClass, feed, 0, 0, 0, nil, false, false, nil)
    newText:SetText(FText(tostring(message)))
    newText:SetAutoWrapText(true)
    newText.Font.Size = 17
    feed:AddChild(newText)
    scrollPending = true

    -- Remove obsolete notifications six seconds after the newest message.
    latest_message = latest_message + 1
    local this_message = latest_message
    ExecuteWithDelay(6000, function()
        ExecuteInGameThread(function()
            if this_message ~= latest_message or APMessageFeed ~= feed then return end
            if feed:IsValid() then feed:ClearChildren() end
        end)
    end)
end

function ResyncInventory()
    if not ap then
        log("Cannot resync while disconnected")
        return
    end
    -- Never call Backpack:ClearInventory or write directly to m_inventory.
    receiving.ReconcileInventory(all_received_items)
end

function disconnect()
    if not ap then return end
    log("Disconnected")
    -- Note: UI access happens on the game thread; other callbacks may be async.
    ap = nil
    session_number = session_number + 1
    pending_game_actions = {}
    all_received_items = {}
    seen_receipts = {}
    receiving.ResetSession()
    slot_data = {}
    currentGameProgression = 0
    collectgarbage("collect")
end

function connect(server, slot, password)
    if ap then return end
    session_number = session_number + 1
    local session = session_number
    local client = AP(uuid, game_name, server)
    ap = client
    log("Connecting to " .. tostring(server) .. " as " .. tostring(slot))

    client:set_socket_connected_handler(function()
        log("Socket connected")
        enqueueMessage("Connecting to Archipelago...")
    end)
    client:set_socket_error_handler(function(msg)
        log("Socket error: " .. tostring(msg))
        enqueueMessage("Connection error: " .. tostring(msg))
    end)
    client:set_socket_disconnected_handler(function()
        log("Socket disconnected")
        disconnect()
    end)
    client:set_room_info_handler(function()
        log("Room info received")
        client:ConnectSlot(slot, password or "", 7, {"Lua-APClientPP"}, client_version)
    end)
    client:set_slot_connected_handler(function(data)
        slot_data = data
        local remote = tostring(slot_data.APWorldVersion)
        local allowed = false
        for _, v in ipairs(compatible) do
            if remote == v then allowed = true; break end
        end
        if not allowed then
            log("Incompatible APWorld " .. remote .. ", client " .. version)
            enqueueMessage("Incompatible Archipelago world version")
            disconnect()
            return
        end
        if remote ~= version then
            log("Minor APWorld mismatch: " .. remote .. " vs " .. version)
            enqueueMessage("APWorld version differs from client; use caution")
        end
        log("Connected. Goal=" .. tostring(data.Goal) ..
            " ChapterGoal=" .. tostring(data.ChapterGoal) ..
            " DeathLink=" .. tostring(data.DeathLink))
        enqueueMessage("Connected to Archipelago")
    end)
    client:set_slot_refused_handler(function(reasons)
        local why = table.concat(reasons or {}, ", ")
        log("Connection refused: " .. why)
        enqueueMessage("Connection refused: " .. why)
        disconnect()
    end)
    client:set_items_received_handler(function(items)
        log("Received " .. tostring(#items) .. " item(s)")
        for _, entry in ipairs(items) do
            local id = tonumber(entry.item)
            if id then
                -- Each location in a multiworld is unique. Preserve legitimate
                -- repeated item IDs acquired from different locations.
                local receiptKey = nil
                if entry.location and entry.player and
                   tonumber(entry.location) and tonumber(entry.location) >= 0 then
                    receiptKey = tostring(entry.player) .. ":" .. tostring(entry.location)
                end
                if not receiptKey or not seen_receipts[receiptKey] then
                    all_received_items[#all_received_items + 1] = id
                    if receiptKey then seen_receipts[receiptKey] = true end
                    log("Received item " .. tostring(id))
                end
            end
        end
        ExecuteInGameThread(function()
            if session == session_number and ap == client then ResyncInventory() end
        end)
    end)
    client:set_location_info_handler(function(items)
        log("Scouted " .. tostring(#items) .. " location(s)")
    end)
    client:set_location_checked_handler(function(locations)
        log("Checked " .. tostring(#locations) .. " location(s)")
    end)
    client:set_data_package_changed_handler(function()
        log("Data package updated")
    end)
    client:set_print_handler(function(msg)
        log("Chat: " .. tostring(msg))
    end)
    client:set_print_json_handler(function(msg)
        local ok, rendered = pcall(function() return client:render_json(msg, message_format) end)
        if ok and rendered then
            log("Chat: " .. tostring(rendered))
            enqueueMessage(rendered)
        end
    end)
    client:set_bounced_handler(function()
        -- Reserved for future DeathLink and bounce behavior.
    end)
    client:set_retrieved_handler(function() end)
    client:set_set_reply_handler(function() end)

    -- Start polling only AFTER client creation/handler registration; avoids
    -- a race where the original polling loop could start while ap was nil.
    LoopAsync(200, function()
        if session ~= session_number or ap ~= client then return true end
        local ok, errorMessage = pcall(function() client:poll() end)
        if not ok then
            log("Poll failed: " .. tostring(errorMessage))
            disconnect()
            return true
        end
        if session ~= session_number or ap ~= client then return true end
        if scrollPending and APFeedScrollBox and APFeedScrollBox:IsValid() then
            scrollPending = false
            ExecuteInGameThread(function()
                if APFeedScrollBox and APFeedScrollBox:IsValid() then
                    APFeedScrollBox:ScrollToEnd()
                end
            end)
        end
        local actions = pending_game_actions
        pending_game_actions = {}
        for _, action in ipairs(actions) do
            if action.type == "message" then
                ExecuteInGameThread(function()
                    if session == session_number then AddMessageToAPFeed(action.text) end
                end)
            elseif action.type == "SendLocations" and action.id then
                local sent, cause = pcall(function() client:LocationChecks({action.id}) end)
                if not sent then
                    log("Location check failed: " .. tostring(cause))
                    action.attempts = (action.attempts or 0) + 1
                    if action.attempts < 3 then
                        pending_game_actions[#pending_game_actions + 1] = action
                    end
                end
            end
        end
        ExecuteInGameThread(function()
            if session ~= session_number or ap ~= client then return end
            local save = FindFirstOf("BP_HKSessionSaveData_C")
            if save and save:IsValid() then
                local now = tonumber(save.ChapterAdventureState) or 0
                if now ~= currentGameProgression then
                    currentGameProgression = now
                    log("AdventureState now " .. now .. "; reconciling")
                    ResyncInventory()
                end
            end
        end)
        return false -- LoopAsync stops only when callback returns true.
    end)
end

function AP_Connect(host, slot, password)
    local world = UEHelpers:GetWorld()
    if not world or not world:IsValid() then return end
    if world:GetFullName() == "World /Game/Map/_MainGame/HK_Project_MainStart.HK_Project_MainStart" then
        log("Start or load a game before connecting")
        AddMessageToAPFeed("Start/load a save before connecting")
        return
    end
    ExecuteAsync(function() connect(host, slot, password) end)
end

RegisterConsoleCommandHandler("apconnect", function(_, args)
    if ap then
        log("Already connected")
        AddMessageToAPFeed("Already connected")
        return true
    end
    local host, slot, password = args[1], args[2], args[3] or ""
    if not host or not slot then
        AddMessageToAPFeed("Usage: apconnect <host> <slot> [password]")
        return true
    end
    AP_Connect(host, slot, password)
    return true
end)

RegisterConsoleCommandHandler("apsay", function(_, args)
    if not ap then
        AddMessageToAPFeed("Connect before chatting")
    elseif args[1] then
        local ok, err = pcall(function() ap:Say(table.concat(args, " ")) end)
        if not ok then log("Chat failed: " .. tostring(err)) end
    end
    return true
end)

RegisterConsoleCommandHandler("apresync", function()
    ExecuteInGameThread(function() ResyncInventory() end)
    return true
end)

RegisterConsoleCommandHandler("apstatus", function()
    print("[AP-Status] Connected=" .. tostring(ap ~= nil))
    ExecuteInGameThread(function() receiving.PrintInventoryStatus(all_received_items) end)
    return true
end)

RegisterConsoleCommandHandler("apdisconnect", function()
    if ap then disconnect() end
    return true
end)

RegisterConsoleCommandHandler("aphud", function()
    show_hud = not show_hud
    log("HUD " .. (show_hud and "on" or "off"))
    if not show_hud and APMessageFeed and APMessageFeed:IsValid() then
        APMessageFeed:ClearChildren()
    end
    return true
end)

RegisterConsoleCommandHandler("apdebug", function()
    local world = UEHelpers:GetWorld()
    local menu = StaticFindObject("/Game/GUI/HUD/UMG_HUD_Debug.UMG_HUD_Debug_C")
    local controller = UEHelpers:GetPlayerController()
    local fn = StaticFindObject("/Script/UMG.WidgetBlueprintLibrary:Create")
    local widget = fn(world, world, menu, controller)
    widget:AddToViewport(999)
    widget:AddToPlayerScreen(999)
    debug_widget = widget
    -- Original mod bindings, installed once rather than on every invocation.
    if not debug_bound then
        RegisterKeyBind(Key.H, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnOpened() end end)
        RegisterKeyBind(Key.I, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnGUIUp() end end)
        RegisterKeyBind(Key.K, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnGUIDown() end end)
        RegisterKeyBind(Key.J, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnGUILeft() end end)
        RegisterKeyBind(Key.L, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnGUIRight() end end)
        RegisterKeyBind(Key.U, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnGUIValidate() end end)
        RegisterKeyBind(Key.O, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnGUICancel() end end)
        RegisterKeyBind(Key.ESCAPE, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnClosed() end end)
        RegisterKeyBind(Key.P, function() if debug_widget and debug_widget:IsValid() then debug_widget:OnClosed() end end)
        debug_bound = true
    end
    log("Debug bindings: H=open; IJKL=navigate; U=select; O=back; P/Escape=close")
    return true
end)

RegisterLoadMapPostHook(function()
    local world = UEHelpers:GetWorld()
    if not world or not world:IsValid() then return end
    local newWorld = world:GetFullName()
    log("World: " .. tostring(newWorld))
    debug_widget = nil
    SetupUI()
    if newWorld == "World /Game/Map/_MainGame/HK_Project_MainStart.HK_Project_MainStart" then
        disconnect()
    end
end)

RegisterHook("/Script/Hk_project.Backpack:AfterLoaded", function()
    -- UE4SS requires the prehook even when work happens in the posthook.
end, function()
    ResyncInventory()
end)

sending.Hooks()
log("Safe Sync loaded; commands: apconnect, apresync, apstatus, apdisconnect, apsay, aphud, apdebug")
