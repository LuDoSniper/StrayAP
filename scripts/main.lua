print("[ArchipelagoMod] Loading")
local AP = require "lua-apclientpp"
local UEHelpers = require "UEHelpers"
local receiving = require "receiving"
local sending = require "sending"

local version = "v0.0.4"
local compatible = {"v0.0.1", "v0.0.2", "v0.0.3", "v0.0.4"}
local client_version = {0, 6, 7}
local message_format = AP.RenderFormat.TEXT

ap = nil
pending_game_actions = {}
all_received_items = {}
slot_data = {}
currentGameProgression = 0

local connected = false
local connecting = false
local session_number = 0
local seen_receipts = {}
local show_hud = true
local hud = nil
local feed = nil
local scroll = nil
local input = nil
local chat_open = false
local chat_focused = false
local focus_attempts = 0
local last_message = 0
local scroll_pending = false
local ui_active = false
local network_loop = nil
local debug_widget = nil
local debug_bound = false

local function log(message)
    print("[ArchipelagoMod] " .. tostring(message))
end

local function valid(object)
    return object and object:IsValid()
end

local function gameTime()
    local world = UEHelpers:GetWorld()
    if valid(world) then
        local ok, seconds = pcall(function() return world:GetRealTimeSeconds() end)
        if ok then return tonumber(seconds) or 0 end
    end
    return os.clock()
end

local function inputMode(name, focus)
    local world = UEHelpers:GetWorld()
    local controller = UEHelpers:GetPlayerController()
    if not valid(world) or not valid(controller) then return end
    local fn = StaticFindObject("/Script/UMG.WidgetBlueprintLibrary:" .. name)
    if not fn then return end
    pcall(function()
        if focus then
            fn(world, controller, focus, false)
        else
            fn(world, controller)
        end
    end)
end

function SetupUI()
    hud, feed, scroll, input = nil, nil, nil, nil
    chat_open = false
    chat_focused = false
    ui_active = false
    if not show_hud then return end
    local world = UEHelpers:GetWorld()
    if not valid(world) then return end
    local ok, err = pcall(function()
        local widgetClass = StaticFindObject("/Script/UMG.UserWidget")
        local treeClass = StaticFindObject("/Script/UMG.WidgetTree")
        local canvasClass = StaticFindObject("/Script/UMG.CanvasPanel")
        local scrollClass = StaticFindObject("/Script/UMG.ScrollBox")
        local verticalClass = StaticFindObject("/Script/UMG.VerticalBox")
        local inputClass = StaticFindObject("/Script/UMG.EditableTextBox")
        if not widgetClass or not treeClass or not canvasClass or
           not scrollClass or not verticalClass or not inputClass then return end

        local widget = StaticConstructObject(widgetClass, world, 0, 0, 0, nil, false, false, nil)
        local tree = StaticConstructObject(treeClass, widget, 0, 0, 0, nil, false, false, nil)
        widget.WidgetTree = tree
        local canvas = StaticConstructObject(canvasClass, tree, 0, 0, 0, nil, false, false, nil)
        tree.RootWidget = canvas

        local messages = StaticConstructObject(scrollClass, tree, 0, 0, 0, nil, false, false, nil)
        local messagesSlot = canvas:AddChildToCanvas(messages)
        messagesSlot:SetAnchors({Minimum={X=0.02, Y=0.54}, Maximum={X=0.35, Y=0.91}})
        local messageFeed = StaticConstructObject(verticalClass, tree, 0, 0, 0, nil, false, false, nil)
        messages:AddChild(messageFeed)
        messages:SetRenderOpacity(0)

        local chat = StaticConstructObject(inputClass, tree, 0, 0, 0, nil, false, false, nil)
        local chatSlot = canvas:AddChildToCanvas(chat)
        chatSlot:SetAnchors({Minimum={X=0.02, Y=0.92}, Maximum={X=0.35, Y=0.965}})
        chat:SetVisibility(1)
        pcall(function() chat.ClearKeyboardFocusOnCommit = true end)
        pcall(function() chat:SetHintText(FText("Message to Archipelago...")) end)

        widget:AddToViewport(999)
        hud, feed, scroll, input = widget, messageFeed, messages, chat
    end)
    if not ok then log("HUD setup failed: " .. tostring(err)) end
end

function AddMessageToAPFeed(message)
    if not show_hud then return end
    if not valid(feed) or not valid(scroll) then SetupUI() end
    if not valid(feed) or not valid(scroll) then return end
    local clean = tostring(message):gsub("[%c]", " "):sub(1, 400)
    local ok, err = pcall(function()
        local text = FText(clean)
        local textClass = StaticFindObject("/Script/UMG.TextBlock")
        local line = StaticConstructObject(textClass, feed, 0, 0, 0, nil, false, false, nil)
        line:SetText(text)
        line:SetAutoWrapText(true)
        line.Font.Size = 17
        feed:AddChild(line)
        while feed:GetChildrenCount() > 18 do
            feed:RemoveChildAt(0)
        end
        scroll:SetRenderOpacity(1)
        last_message = gameTime()
        scroll_pending = true
        ui_active = true
    end)
    if not ok then log("HUD message failed: " .. tostring(err)) end
end

local function enqueueMessage(message)
    pending_game_actions[#pending_game_actions + 1] = {
        type = "message",
        text = tostring(message)
    }
end

local function closeChat(send)
    if not chat_open then return end
    chat_open = false
    local message = ""
    if valid(input) then
        pcall(function() message = input:GetText():ToString() end)
        pcall(function() input:SetVisibility(1) end)
    end
    inputMode("SetInputMode_GameOnly")
    message = message:match("^%s*(.-)%s*$")
    if send and message ~= "" and connected then
        pending_game_actions[#pending_game_actions + 1] = {type="Say", text=message}
    end
    last_message = gameTime()
    ui_active = true
end

local function openChat()
    if not show_hud then return end
    if not connected then
        AddMessageToAPFeed("Connect to Archipelago before chatting")
        return
    end
    if chat_open then return end
    if not valid(input) or not valid(scroll) then SetupUI() end
    if not valid(input) or not valid(scroll) then return end
    local ok, err = pcall(function()
        input:SetText(FText(""))
        input:SetVisibility(0)
        scroll:SetRenderOpacity(1)
        inputMode("SetInputMode_UIOnly", input)
        input:SetKeyboardFocus()
        chat_open = true
        ui_active = true
        chat_focused = false
        focus_attempts = 0
    end)
    if not ok then
        log("Cannot open chat: " .. tostring(err))
        closeChat(false)
    end
end

local function updateUI()
    if not valid(scroll) then return end
    if chat_open then
        if not valid(input) then
            closeChat(false)
        else
            local ok, focused = pcall(function() return input:HasKeyboardFocus() end)
            if ok and focused then
                chat_focused = true
            elseif chat_focused then
                closeChat(true)
            else
                focus_attempts = focus_attempts + 1
                if focus_attempts >= 10 then
                    closeChat(false)
                else
                    pcall(function() input:SetKeyboardFocus() end)
                end
            end
        end
    end
    local opacity = 1
    if not chat_open then
        local elapsed = gameTime() - last_message
        opacity = math.max(0, math.min(1, (7 - elapsed) / 1.5))
    end
    pcall(function()
        scroll:SetRenderOpacity(opacity)
        if scroll_pending then
            scroll:ScrollToEnd()
            scroll_pending = false
        end
    end)
    if not chat_open and opacity <= 0 then ui_active = false end
end

function ResyncInventory()
    if connected then receiving.ReconcileInventory(all_received_items) end
end

function disconnect(reason)
    if not ap and not connecting then return end
    if network_loop then
        CancelDelayedAction(network_loop)
        network_loop = nil
    end
    ap = nil
    connected = false
    connecting = false
    session_number = session_number + 1
    pending_game_actions = {}
    all_received_items = {}
    seen_receipts = {}
    slot_data = {}
    currentGameProgression = 0
    receiving.ResetSession()
    if reason then
        log(reason)
        AddMessageToAPFeed(reason)
    end
    closeChat(false)
end

function connect(server, slot, password)
    session_number = session_number + 1
    local session = session_number
    local started = os.time()
    local client = AP("", "Stray", server)
    ap = client
    log("Connecting to " .. server .. " as " .. slot)
    local function active()
        return session == session_number and ap == client
    end

    client:set_socket_connected_handler(function()
        if active() then log("Socket connected") end
    end)
    client:set_socket_error_handler(function(message)
        if active() then disconnect("Connection error: " .. tostring(message)) end
    end)
    client:set_socket_disconnected_handler(function()
        if active() then disconnect("Disconnected from Archipelago") end
    end)
    client:set_room_info_handler(function()
        if active() then client:ConnectSlot(slot, password or "", 7, {"Lua-APClientPP"}, client_version) end
    end)
    client:set_slot_connected_handler(function(data)
        if not active() then return end
        slot_data = data
        local allowed = false
        for _, value in ipairs(compatible) do
            if data.APWorldVersion == value then allowed = true end
        end
        if not allowed then
            disconnect("Incompatible world version: " .. tostring(data.APWorldVersion))
            return
        end
        connected, connecting = true, false
        log("Connected. Goal=" .. tostring(data.Goal) .. " ChapterGoal=" .. tostring(data.ChapterGoal))
        enqueueMessage("Connected to Archipelago (T to chat)")
    end)
    client:set_slot_refused_handler(function(reasons)
        if active() then disconnect("Connection refused: " .. table.concat(reasons or {}, ", ")) end
    end)
    client:set_items_received_handler(function(items)
        if not active() or not connected then return end
        for _, entry in ipairs(items) do
            local id = tonumber(entry.item)
            if id then
                local key = nil
                if entry.player and entry.location and tonumber(entry.location) and tonumber(entry.location) >= 0 then
                    key = tostring(entry.player) .. ":" .. tostring(entry.location)
                end
                if not key or not seen_receipts[key] then
                    all_received_items[#all_received_items + 1] = id
                    if key then seen_receipts[key] = true end
                end
            end
        end
        if active() then ResyncInventory() end
    end)
    client:set_location_info_handler(function() end)
    client:set_location_checked_handler(function() end)
    client:set_data_package_changed_handler(function() end)
    client:set_print_handler(function(message)
        if active() then log("Chat: " .. tostring(message)) end
    end)
    client:set_print_json_handler(function(message)
        if not active() then return end
        local ok, result = pcall(function() return client:render_json(message, message_format) end)
        if ok and result then
            enqueueMessage(result)
        end
    end)
    client:set_bounced_handler(function() end)
    client:set_retrieved_handler(function() end)
    client:set_set_reply_handler(function() end)

    local next_chapter_check = 0
    network_loop = LoopInGameThreadWithDelay(200, function()
        if not active() then return end
        local ok, err = pcall(function() client:poll() end)
        if not ok then
            disconnect("Connection error: " .. tostring(err))
            return
        end
        if not active() then return end
        if connecting and os.time() - started >= 15 then
            disconnect("Connection timed out")
            return
        end
        local count = #pending_game_actions
        for _ = 1, count do
            local action = table.remove(pending_game_actions, 1)
            if action.type == "message" then
                if active() then AddMessageToAPFeed(action.text) end
            elseif action.type == "Say" and connected then
                local sent, errorMessage = pcall(function() client:Say(action.text) end)
                if not sent then enqueueMessage("Message not sent: " .. tostring(errorMessage)) end
            elseif action.type == "SendLocations" and action.id then
                if not connected then
                    pending_game_actions[#pending_game_actions + 1] = action
                else
                    log("Submitting check " .. tostring(action.id))
                    local sent, errorMessage = pcall(function() client:LocationChecks({action.id}) end)
                    if sent then
                        log("Check submitted " .. tostring(action.id))
                    else
                        log("Check failed " .. tostring(action.id) .. ": " .. tostring(errorMessage))
                        action.attempts = (action.attempts or 0) + 1
                        if action.attempts < 3 then
                            pending_game_actions[#pending_game_actions + 1] = action
                        end
                    end
                end
            end
        end
        local now = os.time()
        if now >= next_chapter_check then
            next_chapter_check = now + 2
            if not active() then return end
            local save = FindFirstOf("BP_HKSessionSaveData_C")
            if valid(save) then
                local chapter = tonumber(save.ChapterAdventureState) or 0
                if chapter ~= currentGameProgression then
                    currentGameProgression = chapter
                    ResyncInventory()
                end
            end
        end
    end)
end

function AP_Connect(server, slot, password)
    connecting = true
    ExecuteInGameThread(function()
        local world = UEHelpers:GetWorld()
        if not valid(world) or world:GetFullName() == "World /Game/Map/_MainGame/HK_Project_MainStart.HK_Project_MainStart" then
            connecting = false
            AddMessageToAPFeed("Load a save before connecting")
            return
        end
        local ok, err = pcall(function() connect(server, slot, password) end)
        if not ok then disconnect("Connection failed: " .. tostring(err)) end
    end)
end

RegisterConsoleCommandHandler("apconnect", function(_, args)
    if connecting or connected or ap then
        log(connecting and "Connection in progress" or "Already connected")
        return true
    end
    if not args[1] or not args[2] then
        log("Usage: apconnect <host> <slot> [password]")
        return true
    end
    AP_Connect(args[1], args[2], args[3] or "")
    return true
end)

RegisterConsoleCommandHandler("apsay", function(_, args)
    if connected and args[1] then
        pending_game_actions[#pending_game_actions + 1] = {type="Say", text=table.concat(args, " ")}
    end
    return true
end)

RegisterConsoleCommandHandler("apresync", function()
    ExecuteInGameThread(function() ResyncInventory() end)
    return true
end)

RegisterConsoleCommandHandler("apstatus", function()
    log("Connected=" .. tostring(connected) .. " Connecting=" .. tostring(connecting))
    ExecuteInGameThread(function() receiving.PrintInventoryStatus(all_received_items) end)
    return true
end)

RegisterConsoleCommandHandler("apdisconnect", function()
    ExecuteInGameThread(function() disconnect("Disconnected") end)
    return true
end)

RegisterConsoleCommandHandler("aphud", function()
    ExecuteInGameThread(function()
        if chat_open then closeChat(false) end
        show_hud = not show_hud
        if show_hud then
            SetupUI()
        elseif valid(hud) then
            hud:RemoveFromParent()
            hud, feed, scroll, input = nil, nil, nil, nil
        end
    end)
    return true
end)

RegisterKeyBind(Key.T, function()
    ExecuteInGameThread(function()
        local ok, err = pcall(openChat)
        if not ok then log("Chat error: " .. tostring(err)); closeChat(false) end
    end)
end)

RegisterConsoleCommandHandler("apdebug", function()
    ExecuteInGameThread(function()
        local ok, err = pcall(function()
            local world = UEHelpers:GetWorld()
            local menu = StaticFindObject("/Game/GUI/HUD/UMG_HUD_Debug.UMG_HUD_Debug_C")
            local controller = UEHelpers:GetPlayerController()
            local fn = StaticFindObject("/Script/UMG.WidgetBlueprintLibrary:Create")
            local widget = fn(world, world, menu, controller)
            widget:AddToViewport(999)
            debug_widget = widget
            if not debug_bound then
                local function bind(key, method)
                    RegisterKeyBind(key, function()
                        ExecuteInGameThread(function()
                            if valid(debug_widget) then pcall(function() debug_widget[method](debug_widget) end) end
                        end)
                    end)
                end
                bind(Key.H, "OnOpened")
                bind(Key.I, "OnGUIUp")
                bind(Key.K, "OnGUIDown")
                bind(Key.J, "OnGUILeft")
                bind(Key.L, "OnGUIRight")
                bind(Key.U, "OnGUIValidate")
                bind(Key.O, "OnGUICancel")
                bind(Key.ESCAPE, "OnClosed")
                bind(Key.P, "OnClosed")
                debug_bound = true
            end
        end)
        if not ok then log("Debug menu error: " .. tostring(err)) end
    end)
    return true
end)

RegisterLoadMapPostHook(function()
    debug_widget = nil
    SetupUI()
    local world = UEHelpers:GetWorld()
    if valid(world) and world:GetFullName() == "World /Game/Map/_MainGame/HK_Project_MainStart.HK_Project_MainStart" then
        disconnect()
    end
end)

RegisterHook("/Script/Hk_project.Backpack:AfterLoaded", function() end, function()
    ResyncInventory()
end)

LoopInGameThreadWithDelay(200, function()
    if not ui_active or not show_hud then return end
    local ok, err = pcall(updateUI)
    if not ok then
        ui_active = false
        log("HUD update failed: " .. tostring(err))
    end
end)

sending.Hooks()
log("Loaded")
