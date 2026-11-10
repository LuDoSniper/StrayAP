local M = {}

-- For items picked up directly from the game world
lootable_id_to_location = {
    ["Key_B12Flat"] = 712050, -- Keys (B-12 Flat)
    ["PostCard"] = 712051, -- Postcard
    ["notebook_ger"] = 712054, -- Zbaltazar's Notebook
    ["notebook_doc"] = 712055, -- Doc's Notebook
    ["notebook_clem"] = 712056, -- Clementine's Notebook
    ["Postit_clue_01"] = 712057, -- Safe's Mysterious Password
    ["Music_Part1"] = 712058, -- Sheet Music (Petite valse)
    ["Music_Part2"] = 712059, -- Sheet Music (Ballad of the Lonely Robot)
    ["Music_Part3"] = 712060, -- Sheet Music (Untitled)
    ["Music_Part5"] = 712062, -- Sheet Music (Tomorrows)
    ["Music_Part6"] = 712063, -- Sheet Music (Cool down)
    ["Music_Part7"] = 712064, -- Sheet Music (Mildly important information)
    ["Music_Part8"] = 712065, -- Sheet Music (Unreadable sheet music)
    ["rareoil"] = 712070, -- Super Spirit Detergent
    ["brokentracker"] = 712074, -- Broken Tracker
    ["plant_purple"] = 712077, -- Purple Plant
    ["plant_red"] = 712078, -- Red Plant
    ["plant_yellow"] = 712079, -- Yellow Plant
    ["Helmet"] = 712083, -- Worker Hat
    ["Jacket"] = 712084, -- Jacket
    ["Lost_Black_Keys"] = 712085, -- Worker Keys
    ["Rikonium"] = 712086, -- Atomic Battery
    ["loot_drink"] = 712088 -- Strange Drink
}

-- For items given through dialog or "ITEM GET" popups
dialog_id_to_location = {
    ["LOOT_Keys_SlumLibrary_C"] = 712052, -- Keys (Library), technically given by B12 translating a note in Doc's home
    ["LOOT_Notebook_Momo_C"] = 712053, -- Momo's Notebook, given by Momo after speaking to him for the first time
    ["LOOT_Music_Part_4_C"] = 712061, -- Sheet Music (The way you compute tonight), given by bartering in the Slums
    ["LOOT_Electric_Cable_C"] = 712071, -- Electric Cable, given by bartering in the Slums
    ["LOOT_Eliott_Poncho_C"] = 712072, -- Poncho, given by Grandma in the Slums
    ["LOOT_Transceiver_C"] = 712073, -- Transceiver, given by Momo right before entering the Rooftops chapter
    ["LOOT_Fixed_Tracker_C"] = 712075, -- Fixed Tracker, given by Eliott after completing the Slums Part 2 trading sequence
    ["LOOT_Fusible_C"] = 712076, -- Fuse, given by Doc midway through Dead End to power the Defluxor
    ["LOOT_Clementine_Adress_C"] = 712080, -- Clementine's Picture, given by Zabaltazar at the top of Antvillage
    ["LOOT_BlazerMessage_C"] = 712081, -- Contact Message, given by Clementine in order to recruit Blazer
    ["LOOT_Tape_C"] = 712082, -- Cassette Tape, given by an NPC after destroying all the security cameras in the Midtown apartments
    ["LOOT_To_Club_C"] = 712087, -- Mysterious Message, technically given by B12 after returning to Clementine's Apartment
    ["LOOT_LeverArm_C"] = 712089, -- Lever Handle, given by an NPC after trading the Mysterious Drink with them
    ["LOOT_Subway_Keys_C"] = 712090, -- Subway Keys, given by Clementine during her escape
    ["LOOT_Badge_Outsider_C"] = 712100, -- Outsider Badge, given by Seamus at the start of Dead End
    ["LOOT_Badge_Music_C"] = 712101, -- Music Badge, given by an NPC after playing all 8 Sheet Music
    ["LOOT_Badge_Plant_C"] = 712102, -- Plant Badge, given by an NPC after getting all 3 flowers in Antvillage
    ["LOOT_Badge_PoliceStation_C"] = 712103, -- Police Badge, technically given by B12 after finding it in the alley between the Clothing Store and Police Station in Midtown
    ["LOOT_Badge_Trashzone_C"] = 712104, -- Neco Badge, given by an NPC after returning the Worker's Lost Keys
    ["LOOT_Badge_ShopSafe_C"] = 712105, -- Cat Badge, technically given by B12 after cracking a safe inside one of the Midtown shops
    ["LOOT_Notebook_Doc_C"] = 0 -- Doc's Notebook, given by Doc inside Slums Part 2. This is not a location.
}

-- For scratching spots
-- No worries about overlapping, since the entire game takes place in a single map with no overlapping coordinates
-- There is a scratching spot on the Slums laudromat door, but it becomes unavailable after dropping the paint can
-- I want to have a minimal amount of missable locations (since there's going to be a lot anyway), so it's not a location
scratchsanity_locations = {
    {
        x = 15761.419,
        y = 59222.883,
        z = 5791.315,
        location = 712000 -- Scratching Spot - Inside The Wall Tree
    },
    {
        x = 5535.952,
        y = 23549.490,
        z = -3966.812,
        location = 712001 -- Scratching Spot - Dead City Right Rug
    },
    {
        x = 5428.073,
        y = 23715.799,
        z = -3966.812,
        location = 712002 -- Scratching Spot - Dead City Left Rug
    },
    {
        x = -721.460,
        y = 20563.266,
        z = -2726.820,
        location = 712003 -- Scratching Spot - B-12 Flat Rug
    },
    {
        x = 210.188,
        y = 9494.394,
        z = -4868.219,
        location = 712004 -- Scratching Spot - White Door in Slums Entryway Alley
    },
    {
        x = 675.082,
        y = 7138.069,
        z = -4871.028,
        location = 712005 -- Scratching Spot - Eliott Programming Downstairs Door (from alley)
    },
    {
        x = 613.292,
        y = 7150.275,
        z = -4867.697,
        location = 712005 -- Scratching Spot - Eliott Programming Downstairs Door (from inside)
    },
    {
        x = 312.077,
        y = 7237.945,
        z = -4588.406,
        location = 712006 -- Scratching Spot - Eliott Programming Rug
    },
    {
        x = 251.308,
        y = 7103.715,
        z = -4589.472,
        location = 712007 -- Scratching Spot - Eliott Programming Curtain
    },
    {
        x = 449.783,
        y = 7843.027,
        z = -4588.406,
        location = 712008 -- Scratching Spot - Eliott Programming Upstairs Door
    },
    {
        x = 1367.490,
        y = 6458.811,
        z = -4504.307,
        location = 712009 -- Scratching Spot - Dufer Bar Upstairs
    },
    {
        x = -6.434,
        y = 3737.876,
        z = -4644.106,
        location = 712010 -- Scratching Spot - Slums Meditation Room
    },
    {
        x = 436.347,
        y = 7568.200,
        z = -4161.837,
        location = 712011 -- Scratching Spot - Heptor's Couch (Slums)
    },
    {
        x = -657.425,
        y = 8407.772,
        z = -3837.208,
        location = 712012 -- Scratching Spot - Slums Rooftop TV
    },
    {
        x = 1240.431,
        y = 7188.043,
        z = -3838.594,
        location = 712013 -- Scratching Spot - Slums Balcony Near Clementine's
    },
    {
        x = -789.870,
        y = 9813.207,
        z = -3769.000,
        location = 712014 -- Scratching Spot - Doc's Couch
    },
    {
        x = -1222.506,
        y = 4698.752,
        z = -3596.229,
        location = 712015 -- Scratching Spot - Zbaltazar's Curtain
    },
    {
        x = -1630.528,
        y = 7030.004,
        z = -3515.104,
        location = 712016 -- Scratching Spot - Momo's Rug
    },
    {
        x = -1618.806,
        y = 7462.280,
        z = -3515.104,
        location = 712017 -- Scratching Spot - Momo's Wall
    },
    {
        x = -1153.774,
        y = 6830.728,
        z = -3515.104,
        location = 712018 -- Scratching Spot - Momo's Front Door
    },
    {
        x = -3973.143,
        y = 8118.225,
        z = -3567.898,
        location = 712019 -- Scratching Spot - Rooftops Starting Area
    },
    {
        x = 9117.460,
        y = 8571.768,
        z = -4489.851,
        location = 712020 -- Scratching Spot - Wall Beside Defluxor
    },
    {
        x = -3550.995,
        y = -29399.963,
        z = -4455.000,
        location = 712021 -- Scratching Spot - Sewers Before Giant Eye
    },
    {
        x = -1839.342,
        y = -57206.363,
        z = -3574.223,
        location = 712022 -- Scratching Spot - Isaac's Rug (Antvillage)
    },
    {
        x = -1678.758,
        y = -56561.461,
        z = -3574.114,
        location = 712023 -- Scratching Spot - Kundelich's Rug (Antvillage)
    },
    {
        x = -2398.928,
        y = -56775.727,
        z = -3573.277,
        location = 712024 -- Scratching Spot - Antvillage Painted Board
    },
    {
        x = -1735.540,
        y = -56828.918,
        z = -2873.865,
        location = 712025 -- Scratching Spot - Tin Chef (Antvillage)
    },
    {
        x = -1631.283,
        y = -56409.637,
        z = -2171.161,
        location = 712026 -- Scratching Spot - Malo's Garden (Antvillage)
    },
    {
        x = -776.149,
        y = 1518.476,
        z = 2495.906,
        location = 712027 -- Scratching Spot - Left at Midtown Entrance
    },
    {
        x = -307.186,
        y = -2121.428,
        z = 2355.021,
        location = 712028 -- Scratching Spot - Midtown Clothing Store Rug
    },
    {
        x = -940.615,
        y = -2118.718,
        z = 2354.761,
        location = 712029 -- Scratching Spot - Midtown Clothing Store Changing Room Couch
    },
    {
        x = 506.129,
        y = 1295.561,
        z = 2351.250,
        location = 712030 -- Scratching Spot - Vladee's Couch (Midtown)
    },
    {
        x = 1719.570,
        y = 306.216,
        z = 2705.211,
        location = 712031 -- Scratching Spot - Balcony Beside Midtown Nightclub
    },
    {
        x = 5702.045,
        y = -2461.802,
        z = 2478.009,
        location = 712032 -- Scratching Spot - Midtown Apartments Floor 1, Door 5
    },
    {
        x = 4533.677,
        y = -2539.192,
        z = 2830.318,
        location = 712033 -- Scratching Spot - Midtown Apartments Floor 2, Door 8
    },
    {
        x = 3945.227,
        y = -4620.948,
        z = 3173.961,
        location = 712034 -- Scratching Spot - Clementine's Drawer
    },
    {
        x = 1291.987,
        y = -2415.684,
        z = 2483.895,
        location = 712035 -- Scratching Spot - Midtown Hat Store
    },
    {
        x = 1394.934,
        y = -1920.365,
        z = 2916.243,
        location = 712036 -- Scratching Spot - Returned Midtown Nightclub Record
    },
    {
        x = -2170.144,
        y = -2789.824,
        z = 65.390,
        location = 712037 -- Scratching Spot - Jail Courtyard Tree
    },
    {
        x = -1386.430,
        y = -1998.785,
        z = 60.000,
        location = 712038 -- Scratching Spot - Jail Truck Keys
    },
    {
        x = 22319.670,
        y = 5237.884,
        z = 9228.438,
        location = 712039 -- Scratching Spot - Control Room Entryway
    },
    {
        x = 22392.359,
        y = 9843.026,
        z = 9272.826,
        location = 712040 -- Scratching Spot - Control Room First Terminal
    },
    {
        x = 23631.549,
        y = 9739.388,
        z = 9150.000,
        location = 712041 -- Scratching Spot - Control Room Second Terminal
    },
    {
        x = 22191.707,
        y = 8434.771,
        z = 9150.000,
        location = 712042 -- Scratching Spot - Control Room Third Terminal
    }
}

function M.Hooks()
    function IsNear(pos, spot, tolerance) -- returns true if the player is within a specified distance of a given set of coordinates
        local dx = pos.X - spot.x
        local dy = pos.Y - spot.y
        local dz = pos.Z - spot.z

        return dx * dx + dy * dy + dz * dz <= tolerance * tolerance
    end

    function RemoveLastItemFromTArray(array)
        if not ap then
            return -- do nothing while offline
        end
        local backpack = FindFirstOf("BP_Backpack_C")
        if not backpack or not backpack:IsValid() then
            print("[ArchipelagoMod] Can't update the inventory because the cat doesn't have the backpack!\n")
            return
        end
        -- As far as I am aware, it is impossible to safely remove a value from a TArray inside UE4SS's Lua scripting
        -- The workaround is to make a local Lua table of the TArray, remove the value from that, wipe the TArray, and reassign the Lua table to the TArray
        local temp = {} -- temporary Lua table
        array:ForEach(function(i, elem)
            local val = elem:get()
            if val ~= nil then
                temp[#temp + 1] = val -- for each element, store its actual value inside the Lua table (if not nil)
            end
        end)
        if #temp > 0 then
            table.remove(temp, #temp) -- remove the last value from the Lua table
        end
        backpack:ClearInventory() -- wipe the inventory
        for i, value in ipairs(temp) do
            array[i] = value -- reassign each value explicity (yes, assigning the value directly this way does work in UE4SS)
        end
    end

    -- This covers all items that are picked up directly from the game world itself by B12
    RegisterHook("/Script/Hk_project.DroneUsableComponent:_OnDroneUseEnded", function(RemoteUnrealParam)
        skipped = false
        local instance = RemoteUnrealParam:Get() -- get the actual instance that called this function
        print("[ArchipelagoMod] _OnDroneUseEnded called on " .. instance:GetFullName() .. "\n")
        local class = instance:GetClass():GetFName():ToString() -- what class called this function?
        if class ~= "COMP_Lootable_C" and class ~= "LootableComponent" then
            skipped = true -- some other interactable (terminal, npc, sign, memory)
            return
        end
        local ID = instance.ID:ToString()
        print("[ArchipelagoMod] Picked up " .. ID .. "\n")
        if ID == "FAKE_BACKPACK" then
            print("[ArchipelagoMod] Vanilla backpack location. Skipped.\n") -- stopping this item from entering the inventory causes a crash
            skipped = true
            return
        end
        if ID == "energydrink" then
            print("[ArchipelagoMod] Energy Drink pickup. This check was already sent.\n") -- see _OnAfterMoveUseStarted below
            return -- don't mark as skipped, since we do still want to remove the item from the player's inventory
        end
        local locID = lootable_id_to_location[ID]
        print("[ArchipelagoMod] Location ID " .. locID .. "\n")
        table.insert(pending_game_actions, { -- Lua is not thread safe, so we defer this to the Archipelago thread through a shared table
            type = "SendLocations",
            id = locID
        })
    end, function()
        if skipped == true then
            skipped = false
            return
        end
        skipped = false
        local backpack = FindFirstOf("BP_Backpack_C")
        local inventory = backpack.m_inventory
        RemoveLastItemFromTArray(inventory)
    end)

    -- This checks items given through NPC dialog or through "ITEM GET" notifications
    RegisterHook("/Script/Hk_project.Dialog:EndDialogLine", function(RemoteUnrealParam)
        local instance = RemoteUnrealParam:Get() -- get the actual instance that called this function
        print("[ArchipelagoMod] EndDialogLine called on " .. instance:GetFullName() .. "\n")
        local line = instance:GetCurrentLine()
        local item = line.ItemToGive:GetFullName() -- I have to seperate these two. doing it on the same line makes UE falsely claim that "ItemToGive" doesn't exist in the table
        if item ~= nil then
            print("[ArchipelagoMod] This line gives an item: " .. item .. "\n")
            for key, locationid in pairs(dialog_id_to_location) do
                if item:match(key .. "$") then -- if the last part of the item name is the key, this passes
                    print("[ArchipelagoMod] ID: " .. locationid .. "\n")
                    if locationid == 0 then
                        print("[ArchipelagoMod] Doc's Notebook in Slums Part 2. Skipping.\n")
                        return
                    end
                    table.insert(pending_game_actions, {
                        type = "SendLocations",
                        id = locationid
                    })
                    local backpack = FindFirstOf("BP_Backpack_C")
                    local inventory = backpack.m_inventory
                    RemoveLastItemFromTArray(inventory)
                    return
                end
            end
            print("[ArchipelagoMod] Couldn't find a location for the item this dialog gives!\n")
        end
    end)

    -- All scratching spots have a CatMoveToUsableComponent script, and _OnAfterMoveUseStarted is called when the scratching animation starts
    RegisterHook("/Script/Hk_project.CatMoveToUsableComponent:_OnAfterMoveUseStarted", function(RemoteUnrealParam)
        local instance = RemoteUnrealParam:Get() -- get the actual instance that called this function
        print("[ArchipelagoMod] _OnAfterMoveUseStarted called on " .. instance:GetFullName() .. "\n")
        local class = instance:GetClass():GetFName():ToString() -- what class called this function?
        if class == "COMP_CatMoveToAnim_C" then -- this same call is used when interacting with the Slums Vending Machines, so I check for those here too
            if instance:GetFullName():find("VendingMaching2", 1, true) then
                print("[ArchipelagoMod] Interacted with the cyan vending machine.\n")
                table.insert(pending_game_actions, {
                    type = "SendLocations",
                    id = 712066, -- Cyan Vending Machine
                })
            end
            if instance:GetFullName():find("VendingMaching7", 1, true) then
                print("[ArchipelagoMod] Interacted with the white vending machine.\n")
                table.insert(pending_game_actions, {
                    type = "SendLocations",
                    id = 712067, -- White Vending Machine
                })
            end
            if instance:GetFullName():find("ScratchableVendingMachine", 1, true) then -- don't ask why this one is named differently
                print("[ArchipelagoMod] Interacted with the yellow vending machine.\n")
                table.insert(pending_game_actions, {
                    type = "SendLocations",
                    id = 712068, -- Yellow Vending Machine
                })
            end
            if instance:GetFullName():find("VendingMaching8", 1, true) then
                print("[ArchipelagoMod] Interacted with the orange vending machine.\n")
                table.insert(pending_game_actions, {
                    type = "SendLocations",
                    id = 712069, -- Orange Vending Machine
                })
            end
        end
        if class ~= "COMP_CatScratchableComponent_C" then
            return -- some other interactable (pushable objects, drinkable water, sleeping spots)
        end
        local cat = FindFirstOf("BP_CatPawn_C")
        if not cat or not cat:IsValid() then
            print("[ArchipelagoMod] CatPawn not found!\n") -- this should hopefully never happen
            return
        end
        local pos = cat:K2_GetActorLocation()
        print(string.format(
            "[ArchipelagoMod] Cat position: X=%.3f Y=%.3f Z=%.3f\n",
            pos.X, pos.Y, pos.Z
        ))
        -- Match the cat's position with the position of known scratching spots using scratchsanity_locations
        -- If the cat is at one of those locations (with a lenience of 20 coordinates just in case), send the respective check
        -- See the declaration for IsNear for more info
        for _, spot in ipairs(scratchsanity_locations) do
            if IsNear(pos, spot, 20) then
                print("[ArchipelagoMod] Scratching spot location ID: " .. spot.location .. "\n")
                table.insert(pending_game_actions, {
                    type = "SendLocations",
                    id = spot.location
                })
                break
            end
        end
    end)

    -- This checks when a special animation or sequence of animations plays
    RegisterHook("/Script/MovieScene.MovieSceneSequencePlayer:Play", function(RemoteUnrealParam)
        local instance = RemoteUnrealParam:Get() -- get the actual instance that called this function
        local name = instance:GetFullName()
        print("[ArchipelagoMod] LevelSequencePlayer:Play called on " .. name .. "\n")
        if not ap then
            return -- do nothing while offline
        end
        if name:find("SEQ_Ending_3.AnimationPlayer", 1, true) then -- cat basking in the sun after opening the city
            print("[ArchipelagoMod] Goal condition reached!\n")
            if slot_data.Goal == 1 then -- Open the city
                -- there is basically no documentation on how to actually goal a slot, so I had to dig through the lua-apclientpp github source to find this
                -- supposedly, ap:StatusUpdate(AP.ClientStatus.GOAL) should work, but I'd rather use the raw int instead
                ap:StatusUpdate(30) -- 30 = GOAL
            end
            if slot_data.Goal == 3 then -- Open the city with all six badges
                -- check for badges
                -- if all six, then goal
                -- if not, probably force reload checkpoint?
            end
        end
    end)
end

return M