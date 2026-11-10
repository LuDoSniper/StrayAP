-- StrayAP v0.0.4 / Safe Sync experimental
-- Receipt inventory handling: native grants only, never ClearInventory().
local M = {}

-- AP item id -> Unreal asset and earliest safe ChapterAdventureState.
-- All inventory items share the same code path; no B-12 special case.
M.InventoryMeta = {
    [712000] = {path="/Game/GPE/Lootable/B12Flat/LOOT_Keys_B12Flat.LOOT_Keys_B12Flat_C", chapter=1},
    [712001] = {path="/Game/GPE/Lootable/B12Flat/BP_Lootable_PostCard.BP_Lootable_PostCard_C", chapter=1},
    [712002] = {path="/Game/GPE/Lootable/Slums/LOOT_Keys_SlumLibrary.LOOT_Keys_SlumLibrary_C", chapter=2},
    [712003] = {path="/Game/GPE/Lootable/Slums/LOOT_Notebook_Momo.LOOT_Notebook_Momo_C", chapter=2},
    [712004] = {path="/Game/GPE/Lootable/Slums/LOOT_Notebook_Gerard.LOOT_Notebook_Gerard_C", chapter=2},
    [712005] = {path="/Game/GPE/Lootable/Slums/LOOT_Notebook_Doc.LOOT_Notebook_Doc_C", chapter=2},
    [712006] = {path="/Game/GPE/Lootable/Slums/LOOT_Notebook_Clem.LOOT_Notebook_Clem_C", chapter=2},
    [712007] = {path="/Game/GPE/Lootable/Slums/LOOT_Postit_clue_01.LOOT_Postit_clue_01_C", chapter=2},
    [712008] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_1.LOOT_Music_Part_1_C", chapter=2},
    [712009] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_2.LOOT_Music_Part_2_C", chapter=2},
    [712010] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_3.LOOT_Music_Part_3_C", chapter=2},
    [712011] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_4.LOOT_Music_Part_4_C", chapter=2},
    [712012] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_5.LOOT_Music_Part_5_C", chapter=2},
    [712013] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_6.LOOT_Music_Part_6_C", chapter=2},
    [712014] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_7.LOOT_Music_Part_7_C", chapter=2},
    [712015] = {path="/Game/GPE/Lootable/Slums/LOOT_Music_Part_8.LOOT_Music_Part_8_C", chapter=2},
    [712016] = {path="/Game/GPE/Lootable/Slums/LOOT_Energy_Drink.LOOT_Energy_Drink_C", chapter=2},
    [712017] = {path="/Game/GPE/Lootable/Slums/LOOT_Rare_Oil.LOOT_Rare_Oil_C", chapter=2},
    [712018] = {path="/Game/GPE/Lootable/Slums/LOOT_Electric_Cable.LOOT_Electric_Cable_C", chapter=2},
    [712019] = {path="/Game/GPE/Lootable/Slums/LOOT_Eliott_Poncho.LOOT_Eliott_Poncho_C", chapter=2},
    [712020] = {path="/Game/GPE/Lootable/Slums/LOOT_Transceiver.LOOT_Transceiver_C", chapter=2},
    [712021] = {path="/Game/GPE/Lootable/Slums/LOOT_Broken_Tracker.LOOT_Broken_Tracker_C", chapter=2},
    [712022] = {path="/Game/GPE/Lootable/Slums/LOOT_Fixed_Tracker.LOOT_Fixed_Tracker_C", chapter=2},
    [712023] = {path="/Game/GPE/Lootable/LOOT_Fusible.LOOT_Fusible_C", chapter=2},
    [712024] = {path="/Game/GPE/Lootable/Antvillage/LOOT_Plant_mauve.LOOT_Plant_mauve_C", chapter=7},
    [712025] = {path="/Game/GPE/Lootable/Antvillage/LOOT_Plant_red.LOOT_Plant_red_C", chapter=7},
    [712026] = {path="/Game/GPE/Lootable/Antvillage/LOOT_Plant_yellow.LOOT_Plant_yellow_C", chapter=7},
    [712027] = {path="/Game/GPE/Lootable/Midtown/LOOT_Clementine_Adress.LOOT_Clementine_Adress_C", chapter=7},
    [712028] = {path="/Game/GPE/Lootable/Midtown/LOOT_BlazerMessage.LOOT_BlazerMessage_C", chapter=8},
    [712029] = {path="/Game/GPE/Lootable/Midtown/LOOT_Tape.LOOT_Tape_C", chapter=8},
    [712030] = {path="/Game/GPE/Lootable/Midtown/LOOT_Helmet.LOOT_Helmet_C", chapter=8},
    [712031] = {path="/Game/GPE/Lootable/Midtown/LOOT_Jacket.LOOT_Jacket_C", chapter=8},
    [712032] = {path="/Game/GPE/Lootable/Midtown/LOOT_factory_lostkeys.LOOT_factory_lostkeys_C", chapter=9},
    [712033] = {path="/Game/GPE/Lootable/Midtown/LOOT_Rikonium.LOOT_Rikonium_C", chapter=9},
    [712034] = {path="/Game/GPE/Lootable/Midtown/LOOT_To_Club.LOOT_To_Club_C", chapter=10},
    [712035] = {path="/Game/GPE/Lootable/Midtown/LOOT_ClubDrink.LOOT_ClubDrink_C", chapter=10},
    [712036] = {path="/Game/GPE/Lootable/Midtown/LOOT_LeverArm.LOOT_LeverArm_C", chapter=10},
    [712037] = {path="/Game/GPE/Lootable/Midtown/LOOT_Subway_Keys.LOOT_Subway_Keys_C", chapter=10},
}

for _, spec in pairs(M.InventoryMeta) do
    spec.class = spec.path:match("%.([^%.]+)$")
end

local badgeFlags = {
    [712100] = "BadgeOutsiderUnlocked",
    [712101] = "BadgeMusicUnlocked",
    [712102] = "BadgePlantUnlocked",
    [712103] = "BadgePoliceStationUnlocked",
    [712104] = "BadgeTrashzoneUnlocked",
    [712105] = "BadgeShopSafeUnlocked",
}

local busy = false
local unverified = {}

function M.ResetSession()
    busy = false
    unverified = {}
end

-- A snapshot of live Unreal inventory objects. Never mutate this array here.
local function snapshot(backpack)
    local counts = {}
    local total = 0
    local ok, err = pcall(function()
        backpack.m_inventory:ForEach(function(_, entry)
            local item = entry:get()
            if item and item:IsValid() then
                total = total + 1
                local fullName = item:GetFullName()
                for _, spec in pairs(M.InventoryMeta) do
                    if fullName:find(spec.class .. "_", 1, true) then
                        counts[spec.class] = (counts[spec.class] or 0) + 1
                        break
                    end
                end
            end
        end)
    end)
    if not ok then
        print("[AP-Sync] Inventory read failed: " .. tostring(err))
        return nil
    end
    return counts, total
end

local function applyBadge(badgeId)
    local flag = badgeFlags[badgeId]
    if not flag then return end
    local save = FindFirstOf("BP_HKPersistentSaveData_C")
    if not save or not save:IsValid() then
        print("[AP-Sync] Badge " .. badgeId .. " deferred: save unavailable")
        return
    end
    local ok, err = pcall(function() save[flag] = true end)
    if not ok then
        print("[AP-Sync] Badge " .. badgeId .. " failed: " .. tostring(err))
        return
    end
    local backpack = FindFirstOf("BP_Backpack_C")
    if backpack and backpack:IsValid() then
        pcall(function() backpack:RefreshBadgesVisibility(false) end)
    end
end

-- Reconcile against the AP item history. Never clear the backpack, never
-- rewrite m_inventory and never invoke traps while replaying history.
function M.ReconcileInventory(received)
    received = received or {}
    if busy then return end
    busy = true
    local ok, err = pcall(function()
        local save = FindFirstOf("BP_HKSessionSaveData_C")
        if not save or not save:IsValid() then
            print("[AP-Sync] Game save unavailable; deferred")
            return
        end
        local desired = {}
        local badges = {}
        local unknown = {}
        for _, id in ipairs(received) do
            local spec = M.InventoryMeta[id]
            if spec then
                desired[id] = (desired[id] or 0) + 1
            elseif badgeFlags[id] then
                badges[id] = true
            elseif id == 712200 then
                -- Paper Bag Trap is incomplete in upstream v0.0.4.
            elseif id < 712150 or id > 712152 then
                unknown[id] = true
            end
        end
        for id in pairs(badges) do applyBadge(id) end
        for id in pairs(unknown) do
            print("[AP-Sync] Unknown item " .. tostring(id) .. " (ignored)")
        end

        local backpack = FindFirstOf("BP_Backpack_C")
        if not backpack or not backpack:IsValid() then
            print("[AP-Sync] Backpack unavailable; rewards deferred")
            return
        end
        local counts = snapshot(backpack)
        if not counts then return end
        local chapter = tonumber(save.ChapterAdventureState) or 0
        local granted, deferred = 0, 0
        -- Sorted IDs for deterministic output and a consistent rebuild order.
        local ids = {}
        for id in pairs(desired) do ids[#ids + 1] = id end
        table.sort(ids)
        for _, id in ipairs(ids) do
            local spec = M.InventoryMeta[id]
            local wanted = desired[id]
            local have = counts[spec.class] or 0
            if chapter < spec.chapter then
                deferred = deferred + wanted
            elseif unverified[id] then
                print("[AP-Sync] " .. id .. " automatic retry blocked after unverified grant")
            else
                for _ = have + 1, wanted do
                    local success, problem = pcall(function()
                        local object = LoadAsset(spec.path)
                        if not object then error("asset not found: " .. spec.path) end
                        backpack:InstantiateAndAddActorToInventory(object)
                    end)
                    if not success then
                        print("[AP-Sync] " .. id .. " grant failed: " .. tostring(problem))
                        unverified[id] = true
                        break
                    end
                    local updated = snapshot(backpack)
                    if updated and (updated[spec.class] or 0) > have then
                        counts = updated
                        have = counts[spec.class]
                        granted = granted + 1
                        print("[AP-Sync] Granted " .. id .. " (" .. spec.class .. ")")
                    else
                        unverified[id] = true
                        print("[AP-Sync] " .. id .. " grant not verified; no blind retry")
                        break
                    end
                end
            end
        end
        print("[AP-Sync] Done: granted=" .. granted .. ", deferred=" .. deferred)
    end)
    busy = false
    if not ok then print("[AP-Sync] Reconcile failed: " .. tostring(err)) end
end

function M.PrintInventoryStatus(received)
    local backpack = FindFirstOf("BP_Backpack_C")
    if not backpack or not backpack:IsValid() then
        print("[AP-Status] Backpack unavailable")
        return
    end
    local counts, total = snapshot(backpack)
    if not counts then return end
    local wanted = {}
    for _, id in ipairs(received or {}) do
        local spec = M.InventoryMeta[id]
        if spec then wanted[spec.class] = (wanted[spec.class] or 0) + 1 end
    end
    print("[AP-Status] Inventory entries=" .. total .. " | received=" .. #(received or {}))
    for class, count in pairs(wanted) do
        print("[AP-Status] " .. class .. ": have=" .. (counts[class] or 0) .. " / want=" .. count)
    end
end

return M
