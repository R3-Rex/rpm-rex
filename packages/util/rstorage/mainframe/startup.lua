-- REACT INDUSTRIES Sorting System
local configFile = "config/sorter.cfg"

-- Load Configuration
local f = fs.open(configFile,"r")
local config = {}
if f then
    config = textutils.unserialise(f.readAll())
    f.close()
else
    printError("Config file missing")
    return
end

local cleaning = false

-- Core Functions
local function genID(metadata)
    if not metadata then
        return false
    end
    return metadata.name
end
local function stripIDdmg(str)
    -- yikes
    while true do
        char = string.sub(str,#str,#str)
        if tonumber(char) then
            str = string.su(str,1,#str-1)
        else
            return str
        end
    end
end

local debugList = {}

local function debug(value)
    local w, h = term.getSize()
    local listMax = 50
    for i = #debugList, 1, -1 do
        if (i < listMax) then
            debugList[i + 1] = debugList[i]
        end
    end
    local newData = {}
    newData.text = value
    newData.time = os.epoch("utc")
    debugList[1] = newData
end

local function yield()
    os.sleep(0.1)
end

local lastYield = os.epoch("utc")
local totalYields = 0
local function checkYield()
    local lastYieldOffset = os.epoch("utc") - lastYield
    if (lastYieldOffset > 500) then
        lastYield =  os.epoch("utc")
        totalYields = totalYields + 1
        yield()
    end
    local yieldText = "YIELD #" .. totalYields .. " [" ..  lastYieldOffset.. "]"
    local w, h = term.getSize()
    local x, y = term.getCursorPos()
    term.setCursorPos(w - #yieldText + 1, 1)
    term.setTextColor(colors.lime)
    term.clearLine()
    term.write(yieldText)
    term.setTextColor(colors.black)
    term.setCursorPos(x, y)
end

-- Timing Functions
local timers = {}
local times = {}
local function startTimer(str)
    timers[str] = os.epoch("utc")
end
local function stopTimer(str)
    times[string.lower(str)] = os.epoch("utc")-timers[str]
end

-- Storage Functions
local chests = {}
local unmanagedChests = {}
local fullChests = {}

local function moveItem(fromChestID,fromSlot,toChestID,toSlot,quantity)
    fullChests[fromChestID] = false
    if chests[fromChestID] and chests[toChestID] then
        local oldItem
        if chests[fromChestID] and chests[fromChestID].contents and chests[fromChestID].contents[fromSlot] then
            oldItem = chests[fromChestID].contents[fromSlot]
            chests[fromChestID].contents[fromSlot] = nil
        end
        if (chests[toChestID] and chests[toChestID].contents and chests[toChestID].contents[toSlot] == nil) and not (toSlot == nil) then
            chests[toChestID].contents[toSlot] = oldItem
        end
        return chests[fromChestID].pushItems(peripheral.getName(chests[toChestID]),fromSlot,quantity,toSlot)
    else
        return 0
    end
end
--64?0?0?
local function readChestItem(chestID,slotID)
    if not chests[chestID] or type(chests[chestID].contents) ~= "table" then
        return false
    end
    return chests[chestID].contents[slotID]
end

local function getItemName(chest, chestSlot)
    local detail = chest.getItemMeta(chestSlot)
    local itemSlot = chest.list()[chestSlot]
    local name = detail.displayName

    name = detail.maxCount .. "?" .. detail.damage .. "?" .. detail.maxDamage .. "?" .. detail.displayName
    
    if (detail.maxDamage > 0) then
        name = detail.maxCount .. "?" .. detail.damage .. "?" .. detail.maxDamage .. "?" .. "Tool \"" .. detail.displayName .. "\""
    end

    return name, detail;
end

local function updateContents(networkID)
    --Create list with item names rebuilt
    local ok,rawList = pcall(function()
        return chests[networkID].list();
    end)
    if not ok then
        rawList = {}
        --debug("Error updating list for " .. networkID)
    end
    local newList = {}
    for i,v in pairs(rawList) do
        
        if (i ~= chests[networkID].capacity) then
            v.name = v.name .. v.damage
            rawList[i] = v;
        end
    end
    chests[networkID].contents = rawList
    local chestEmptySlots = chests[networkID].capacity or 0
    for i,v in pairs(chests[networkID].contents) do
        chestEmptySlots = chestEmptySlots - 1
    end
    if chestEmptySlots > 0 then
        fullChests[networkID] = false
    end
end

local function getChestType(id)
    if config.chests and config.chests[id] then
        return config.chests[id]
    end
    local markerItem = readChestItem(id, chests[id].capacity)
    if unmanagedChests[id] then
        return "unmanaged"
    elseif markerItem then
        return config.markers[genID(markerItem)] or genID(markerItem) .. tostring(markerItem.damage)
    elseif config.markers["empty"] then
        return config.markers["empty"]
    else
        return "empty"
    end
end

local quickScanChests = {}
local function indexAllChests(recheckCapacity)
    local peripheralList = peripheral.getNames()
    local idCounter = 0

    for peripheralListIndex, peripheralName in pairs(peripheralList) do
        local networkID = -1
        local shortName = peripheralName
        
        while true do
            local underscorePosition
            if string.find(shortName,"_") then
                underscorePosition = #shortName+1-string.find(string.reverse(shortName),"_")
            end
            if underscorePosition then
                networkID = tonumber(string.sub(shortName,underscorePosition+1,#peripheralName))
                
                idCounter = idCounter + 1
                shortName = string.sub(peripheralName,1,underscorePosition-1)
                
                if type(config.core.storageTypes[shortName]) == "number" then
					networkID = networkID + tonumber(config.core.storageTypes[shortName])
                end
            end
            break
        end
        if config.core.storageTypes[shortName] then
            local oldCapacity
            if chests[networkID] then
                oldCapacity = chests[networkID].capacity
            end
            chests[networkID] = peripheral.wrap(peripheralName)
            if oldCapacity then
                chests[networkID].capacity = oldCapacity
            end
            if not chests[networkID].capacity or recheckCapacity then
                ok,err = pcall(function()
                    return chests[networkID].size()
                end)
                chests[networkID].capacity = tonumber(err) or 27
            end
            if (quickScanChests[networkID] == nil) then
                quickScanChests[networkID] = false
            end
            if (quickScanChests[networkID] == false) then
                updateContents(networkID)
            end
        end
    end
end
local function indexUnAllocatedChests(recheckCapacity)
    for i, v in pairs(quickScanChests) do
        if v == true then
            updateContents(i)
        end
    end
end


local function placeInChest(fromChestID,fromSlot,chestID,count)
    if count <= 0 then
        return 0
    end
    if fullChests[chestID] then
        return 0
    end
    local movedItems = moveItem(fromChestID,fromSlot,chestID,nil,count)
    if movedItems <= 0 then
        fullChests[chestID] = true
    end
    return movedItems
end

local function depositItem(chestID,slotID)
    local itemData = readChestItem(chestID,slotID)
    if itemData then
        local itemId = genID(itemData)
        local count = itemData.count

        -- Deposit in item-specific chest first
        for targetChestID,v in pairs(chests) do
            if v.type == itemId then
                count = count - placeInChest(chestID,slotID,targetChestID,count)
                if count <= 0 then
                    return true
                end
            end
        end

        -- Deposit in misc chest as a fallback
        for targetChestID,v in pairs(chests) do
            if v.type == "misc" then
                count = count - placeInChest(chestID,slotID,targetChestID,count)
                if count <= 0 then
                    return true
                end
            end
        end
    end
end

local function locateItem(id, exclude)
    for i,v in pairs(chests) do
        if i ~= exclude then
            if v.contents then
                for k,z in pairs(v.contents) do
                    if type(z) == "table" and z.name then
                        if genID(z) == id then
                            return i, k
                        end
                    end
                end
            end
        end
    end
end

local function fillChest(chest, item, count)
    for i=1,1000 do
        local chestId,slotId = locateItem(item, chest)
        if not chestId or not slotId then
            return
        end
        local slotCount = chests[chestId].contents[slotId].count
        if slotCount > count then
            slotCount = count
        end
        count = count - placeInChest(chestId,slotId,chest,slotCount)
        if count <= 0 then
            return true
        end
    end
    if (count > 0) then
        debug("ERR - " .. count .. " \"" .. item .. "\"")
    end
end

local function clearChest(i)
    startTimer("EMPTY CHEST CLEARING")
    local v = chests[i]
    if (v ~= nil) then
        if v.contents then
            for k,z in pairs(v.contents) do
                if (k ~= v.capacity) then
                    depositItem(i,k)
                end
            end
        end
    else
        debug("Chest " .. i .. " doesent exist")
    end
    stopTimer("EMPTY CHEST CLEARING")
end

-- Display Name Cache
local displayNames = {}
local function getDisplayName(id)
    if displayNames[id] then
        return displayNames[id]
    end
    local chestId, chestSlot = locateItem(id)
    if chestId then
        local detail = chests[chestId].getItemMeta(chestSlot)
        if detail then
            local displayName = getItemName(chests[chestId], chestSlot)
            displayNames[id] = displayName
            return displayName
        end
    else
        return false
    end
end

local function translateFromDisplayName(name)
    for i,v in pairs(displayNames) do
        if v == name then
            return i
        end
    end
    return name
end

local unallocated = 0
local totalAllocated = 0
local available = 0

local function findStats()
    local categories = {
        ["filled"] = 0,
        ["available"] = 0,
        ["unallocated"] = 0,
    }
    for i,v in pairs(chests) do
        if v.type == "misc" and v.contents then
            local slotsInUse = -1
            for k,z in pairs(v.contents) do
                slotsInUse = slotsInUse + 1
            end
            categories.filled = categories.filled + slotsInUse
            categories.available = categories.available + ((v.capacity-1) - slotsInUse)
        elseif v.type == "empty" then
            categories.unallocated = categories.unallocated + v.capacity
        end
    end
    unallocated = categories.unallocated
    totalAllocated = tostring(categories.available + categories.filled)
    available = categories.available
end
local function quickStorageRoutine()
    local cycle = 0
    while true do
        startTimer("QUICK CHEST INDEX")
        indexUnAllocatedChests(cycle % config.performance.cyclesPerCapacityCheck == 0)
        stopTimer("QUICK CHEST INDEX")
        
        cycle = cycle + 1
        sleep(0.5)
    end
end

local function emptyClearRoutine()
    while true do
        checkYield()
        -- Empty chest clearing
        startTimer("DROP CHEST CLEARING")
        for i,v in pairs(chests) do
            if v.type == "empty" then
                if type(v.contents) == "table" then
                    clearChest(i)
                end
            end
        end
        stopTimer("DROP CHEST CLEARING")
        os.sleep(5)
    end
end
-- Storage Routine
local function storageRoutine()
    local maxCountCache = {}
    local resourceChests = {}
    local cycle = 0
    while true do
        -- Index all chests
        startTimer("INDEXING CHESTS")
        indexAllChests(cycle % config.performance.cyclesPerCapacityCheck == 0)
        stopTimer("INDEXING CHESTS")
        checkYield()
        -- Get display names
        startTimer("GET DISPLAY NAMES")
        for i,v in pairs(chests) do
            if v.contents then
                for k,z in pairs(v.contents) do
                    if type(z) == "table" and z.name then
                        getDisplayName(genID(z))
                    end
                end
            end
        end
        stopTimer("GET DISPLAY NAMES")
        checkYield()
        -- Chest classification
        startTimer("CHEST CLASSIFICATION")
        resourceChests = {}
        for i,v in pairs(chests) do
            local chestType = getChestType(i)
            chests[i].type = chestType
            resourceChests[chestType] = true
            if (chestType == "empty" or chestType == "unmanaged") then
                quickScanChests[i] = true
            else
                quickScanChests[i] = false
            end
        end
        stopTimer("CHEST CLASSIFICATION")
        
        checkYield()
        -- Resource chest cleanup
        startTimer("RESOURCE CHEST REALLOCATION")
        for i,v in pairs(chests) do
            if string.find(v.type,":") then
                if type(v.contents) == "table" then
                    for k,z in pairs(v.contents) do
                        if k ~= v.capacity then
                            if z and genID(z) ~= v.type then
                                depositItem(i,k)
                            end
                        end
                    end
                end
            end
        end
        stopTimer("RESOURCE CHEST REALLOCATION")
        checkYield()
        -- Misc chest reallocation
        startTimer("MISC CHEST REALLOCATION")
        if cycle % 5 == 0 then
        for i,v in pairs(chests) do
            if v.type == "misc" then
                if type(v.contents) == "table" then
                    for k,z in pairs(v.contents) do
                        if k ~= v.capacity then
                            if resourceChests[genID(z)] then
                                depositItem(i,k)
                            end
                        end
                    end
                end
            end
        end
        end
        stopTimer("MISC CHEST REALLOCATION")
        checkYield()
        -- Resource balancing
        startTimer("RESOURCE BALANCING")

        local resourceCount = {}
        local resourceChestCount = {}
        local resourceChests = {}
        for i,v in pairs(chests) do -- count resources
            if string.find(v.type,":") then
                if type(v.contents) == "table" then
                    if not resourceChests[v.type] then
                        resourceChests[v.type] = {}
                    end
                    table.insert(resourceChests[v.type],i)
                    for k,z in pairs(v.contents) do
                        if k ~= v.capacity then
                            if z and genID(z) == v.type then
                                if not resourceCount[v.type] then
                                    resourceCount[v.type] = 0
                                end
                                if not resourceChestCount[i] then
                                    resourceChestCount[i] = 0
                                end
                                resourceCount[v.type] = resourceCount[v.type] + z.count
                                resourceChestCount[i] = resourceChestCount[i] + z.count
                            end
                        end
                    end
                end
            end
        end

        local redistributionValues = {}
        for resource, chestList in pairs(resourceChests) do
            for chestIndex, chestId in pairs(chestList) do
                if chests[chestId] and resourceCount[resource] then
                    local targetAmount = resourceCount[resource]/#resourceChests[resource]
                    if not maxCountCache[resource] then
                        ok,maxCountCache[resource] = pcall(function()
                            return chests[chestId].getItemMeta(chests[chestId].capacity).maxCount
                        end)
                        if not ok then
                            maxCountCache[resource] = 1
                        end
                    end
                    if targetAmount > ((chests[chestId].capacity-1)*maxCountCache[resource]) then
                        targetAmount = ((chests[chestId].capacity-1)*maxCountCache[resource])
                    end
                    redistributionValues[chestId] = math.floor(targetAmount - (resourceChestCount[chestId] or 0))
                end
            end
        end

        for toChestId,toChestAmount in pairs(redistributionValues) do
            if toChestAmount > 0 then
                local amountToFill = toChestAmount
                for fromChestId,fromChestAmount in pairs(redistributionValues) do
                    if fromChestAmount < 0 then
                        for i=1,chests[fromChestId].capacity-1 do
                            if readChestItem(fromChestId,i) then
                                if amountToFill >= 1 then
                                    amountToFill = amountToFill - chests[fromChestId].pushItems(peripheral.getName(chests[toChestId]),i,amountToFill)
                                end
                                if amountToFill <= 0.5 then
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        
        stopTimer("RESOURCE BALANCING")
        checkYield()
        startTimer("FIND STATS")
        findStats()
        stopTimer("FIND STATS")
        -- Wait
        cycle = cycle + 1
        sleep(5)
    end
end
local storageTotals = {}
local function storageTotalsRoutine()
    while true do
        startTimer("STORAGE TOTALS")
        lastTime = os.epoch("utc")
        newStorageTotals = {}
        newStorageTotals.unallocated = unallocated;
        newStorageTotals.totalAllocated = totalAllocated
        newStorageTotals.available = available
        newStorageTotals.times = times
        newStorageTotals.debug = debugList
        for i,v in pairs(chests) do
            if v.contents then
                for k,z in pairs(v.contents) do
                    if k ~= v.capacity then
                        local name = getDisplayName(genID(z))
                        if type(z) == "table" and name then
                            if not newStorageTotals[name] then
                                newStorageTotals[name] = 0
                            end
                            newStorageTotals[name] = newStorageTotals[name] + z.count
                        end
                    end
                end
            end
        end
        storageTotals = newStorageTotals
        stopTimer("STORAGE TOTALS")
        os.sleep(1)
    end
end

local function logSingleLine(string)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
    term.write(string)
end


local function cleanupOperation()
    startTimer("CLEANUP")
    cleaning = true
    local operationsPrint = 54;
    local storageTotals = {}
    local totalScan = totalAllocated - available
    local currentScan = 0
    local totalFound = 0
    local totalItems = 0

    for i,v in pairs(chests) do
        if v.contents then
            for k,z in pairs(v.contents) do
                if k ~= v.capacity then
                    currentScan = currentScan + 1
                    local name = z.name

                    logSingleLine("CLEANING SYSTEM")
                    print("---------------------------------------------------")
                    print("GENERATING RAW STORAGE LIST")
                    print("PROGRESS: " .. currentScan .. "/" .. totalScan)
                    print("CHEST: " .. i)
                    print("SLOT: " .. k)
                    print("ITEM: " .. name)
                    print(" ")
                    print("TOTAL: " .. totalItems)
                    checkYield()
                   
                    if type(z) == "table" and name ~= nil then
                        if not storageTotals[name] then
                            storageTotals[name] = {}
                            storageTotals[name].count = 0
                            
                            storageTotals[name].slots = {}
                            local detail = v.getItemMeta(k)
                            storageTotals[name].stackSize = detail.maxCount
                        end
                        storageTotals[name].count = storageTotals[name].count + z.count
                        totalItems = totalItems + z.count
                        local newData = {}
                        newData.chest = i
                        newData.slot = k
                        newData.count = z.count
                        storageTotals[name].slots[#storageTotals[name].slots + 1] = newData
                        totalFound = totalFound + 1
                    end
                end
            end
        end
    end
    logSingleLine("CLEANING SYSTEM")
    print("---------------------------------------------------")
    print("Finished.")
    print("FOUND: " .. totalFound)
    print("TOTAL ITEMS: " .. totalItems)
    checkYield()
    os.sleep(5)
    local totalMoved = 0
    local currentMove = 0
    local slotsCleared = 0
    for i, v in pairs(storageTotals) do
        local currentFillable = 1
        for k, z in pairs(v.slots) do
            currentMove = currentMove + 1
            logSingleLine("CLEANING SYSTEM")
            print("---------------------------------------------------")
            print("RELOCATING FOUND ITEMS")
            print("PROGRESS: " .. currentMove .. "/" .. totalFound)
            print("CHEST: " .. z.chest)
            print("SLOT: " .. z.slot)
            print("ITEM: " .. i)
            print("TOTAL: " .. v.count)
            print("STACK SIZE: " .. v.stackSize)
            print("OPTIMIZED STACKS: " .. math.ceil(v.count / v.stackSize))
            print("ACTUAL STACKS: " .. #v.slots)
            print("CURRENT FILL INDEX: " .. currentFillable)
            
            print("")
            print("MOVED: " .. totalMoved)
            print("SLOTS MADE AVAILABLE: " .. slotsCleared)

            checkYield()
            if (currentFillable < k) then
                if (z.count < v.stackSize) then
                    local moveRemain = z.count
                    while moveRemain > 0 do
                        local currentAvailable = v.stackSize - v.slots[currentFillable].count
                        local moveAmount = math.min(moveRemain, currentAvailable)
                        if (currentAvailable > 0) then
                            --Move them shits
                            v.slots[currentFillable].count = v.slots[currentFillable].count + moveAmount
                            v.slots[k].count = v.slots[k].count - moveAmount
                            moveRemain = moveRemain - moveAmount
                            totalMoved = totalMoved + moveAmount
                            --print("move " .. z.chest .. " " .. z.slot .. " " .. v.slots[currentFillable].chest .. " " .. v.slots[currentFillable].slot .. " " .. moveAmount)
                            moveItem(z.chest, z.slot, v.slots[currentFillable].chest, v.slots[currentFillable].slot, moveAmount)
                            if (moveRemain <= 0) then
                                slotsCleared = slotsCleared  + 1
                            end
                        else
                            if (currentFillable + 1 >= k) then
                                moveRemain = 0
                            else
                                if (currentFillable < #v.slots) then
                                    currentFillable = currentFillable + 1
                                else
                                    moveRemain = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    logSingleLine("CLEANING SYSTEM")
    print("---------------------------------------------------")
    print("Finished.")
    print("MOVED: " .. totalMoved)
    print("SLOTS MADE AVAILABLE: " .. slotsCleared)
    debug("Finished Cleaning")
    debug("MOVED: " .. totalMoved)
    debug("SLOTS MADE AVAILABLE: " .. slotsCleared)
    os.sleep(5)
    cleaning = false
end

-- Network Routine
local networkModem = peripheral.find("modem")
local networkChannel = 18245
local networkID = 0

local function networkSend(id,str)
    networkModem.transmit(networkChannel, networkID, {
        sorter = true,
        target = id,
        message = str,
    })
end
local function networkReceive(filter)
    networkModem.open(networkChannel)
    while true do
        local e,s,c,r,m = os.pullEvent("modem_message")
        if type(m) == "table" and m.sorter then
            -- protocol valid
            local messageTarget, messageContent = m.target, m.message
            if not ((filter and r ~= filter) or (messageTarget ~= networkID)) then
                return r, messageContent
            end
        end
    end
    networkModem.close(networkChannel)
end




local function networkRoutine()

        local id, message = networkReceive()
        if type(message) == "table" then
            local cmd = message.command
            if cmd == "storage-inventory" then
                parallel.waitForAll(function()
                    --Do the function here--
                    -- package storage data
                    debug("Storage Inventory")
                    local storageInventory = {}
                    for i,v in pairs(chests) do
                        storageInventory[i] = v.contents
                    end
                    networkSend(id, storageInventory)
                    ------------------------
                end, networkRoutine)
                
            elseif cmd == "storage-totals" then
                parallel.waitForAll(function()
                    --Do the function here--
                    networkSend(id, storageTotals)
                    ------------------------
                end, networkRoutine)
                
            elseif cmd == "unmanage-chest" then
                parallel.waitForAll(function()
                    --Do the function here--
                    unmanagedChests[message.chest] = true
                    debug("Unmanage " .. message.chest)
                    ------------------------
                end, networkRoutine)
                
            elseif cmd == "manage-chest" then
                parallel.waitForAll(function()
                    --Do the function here--
                    if (message.chest < 0) then
                        if (message.chest == -1) then
                            debug("Reboot")
                            os.sleep(5)
                            os.reboot()
                        elseif (message.chest == -2) then
                            debug("Cleanup")
                            os.sleep(5)
                            cleanupOperation()
                        end
                    else
                        debug("Manage " .. message.chest)
                        unmanagedChests[message.chest] = false
                    end
                    ------------------------
                end, networkRoutine)
            elseif cmd == "clear-chest" then
                parallel.waitForAll(function()
                    --Do the function here--
                    debug("Clear " .. message.chest)
                    clearChest(message.chest)
                    ------------------------
                end, networkRoutine)
            elseif cmd == "fill-chest" then
                parallel.waitForAll(function()
                    --Do the function here--
                    debug("Fill " .. message.chest .. " with " .. message.count .. " of \"" .. message.item .. "\"")
                    local itemName = translateFromDisplayName(message.item)
                    fillChest(message.chest, itemName, message.count)
                    ------------------------
                end, networkRoutine)
            end
        end
end


-- Interface
local interfaceTabs = {"STORAGE","PERFORMANCE", "CONSOLE"}
local interfaceTab = 1
local interfaceTabPositions = {}

-- User Interface
local function interfaceRoutine()
    -- Interface Functions
    local function displayBreakdown(bdata,bcolors,y)
        -- calculate
        local width = term.getSize()
        width = width - 2
        local btotal = 0
        for i,v in pairs(bdata) do
            btotal = btotal + v
        end

        -- draw bar
        local bcount = 0
        term.setCursorPos(2,y)
        for i,v in pairs(bdata) do
            bcount = bcount + 1
            if bcolors[i] then
                term.setBackgroundColor(bcolors[i])
            else
                if bcount%2 == 0 then
                    term.setBackgroundColor(colors.white)
                else
                    term.setBackgroundColor(colors.lightGray)
                end
            end
            write(string.rep(" ",math.floor(width*(v/btotal))))
        end

        -- draw list
        local bcount = 0
        term.setBackgroundColor(colors.black)
        for i,v in pairs(bdata) do
            bcount = bcount + 1
            if bcolors[i] then
                term.setTextColor(bcolors[i])
            else
                if bcount%2 == 0 then
                    term.setTextColor(colors.white)
                else
                    term.setTextColor(colors.lightGray)
                end
            end
            term.setCursorPos(2,y+1+bcount)
            write(tostring(math.floor(v)))
            term.setTextColor(colors.gray)
            write(" "..i)
        end
    end

    

    while true do
        -- Header
        if not cleaning then
            term.setBackgroundColor(colors.black)
            term.clear()
            term.setTextColor(colors.lightGray)
            local x = 2
            for i,v in pairs(interfaceTabs) do
                term.setCursorPos(x,2)
                if interfaceTab == i then
                    term.setTextColor(colors.white)
                else
                    term.setTextColor(colors.gray)
                end
                write(v)
                table.insert(interfaceTabPositions,{x,x+#v-1})
                x = x + #v + 2
            end
            -- Tabs
            local tab = interfaceTabs[interfaceTab]
            local sleepTime = 0.5
            if tab == "STORAGE" then
                findStats()
                local categories = {
                    ["filled"] = totalAllocated - available,
                    ["available"] = available,
                    ["unallocated"] = unallocated,
                }
                
                term.setCursorPos(2, 10)
                term.setTextColor(colors.orange)
                term.write(tostring(totalAllocated))
                term.setCursorPos(3 + #totalAllocated, 10)
                term.setTextColor(colors.gray)
                term.write("total allocated")
                displayBreakdown(categories,{
                    ["filled"] = colors.cyan,
                    ["available"] = colors.lightGray,
                    ["unallocated"] = colors.gray,
                },4)
            elseif tab == "PERFORMANCE" then
                displayBreakdown(times,{
                    ["get display names"] = colors.red,
                    ["misc chest reallocation"] = colors.orange,
                    ["resource balancing"] = colors.yellow,
                    ["indexing chests"] = colors.lime,
                    ["chest classification"] = colors.cyan,
                    ["drop chest clearing"] = colors.blue,
                    ["resource chest reallocation"] = colors.purple,
                    ["find stats"] = colors.gray,
                    ["quick chest index"] = colors.green,
                    ["storage totals"] = colors.orange,
                    ["empty chest clearing"] = colors.blue
                },4)
            elseif tab == "CONSOLE" then
                sleepTime = 0.1
                local w, h = term.getSize()
                for i = 1, (h - 4) do
                    if (debugList[i] ~= nil) then
                        term.setCursorPos(2, h - i)
                        term.setBackgroundColor(colors.black)
                        term.setTextColor(colors.lightGray)
                        local timeSince = (debugList[i].time - os.epoch("utc")) / -1000
                        local minutes = math.floor(timeSince / 60)
                        local seconds = math.floor(timeSince - (minutes * 60))
                        local millSeconds = math.floor((timeSince * 100) - (seconds * 100) - (minutes * 6000))
                        local secondsString = seconds
                        local millSecondsString = millSeconds
                        if (seconds < 10) then
                            secondsString = "0" .. seconds
                        end
                        if (millSeconds < 10) then
                            millSecondsString = "0" .. millSeconds
                        end
                        local timeString = "[" .. minutes .. ":" .. secondsString .. "." .. millSecondsString .. "] "
                        term.write(timeString)
                        local remainingCharacters = (w - 2) - #timeString
                        local debugText = debugList[i].text
                        if (#debugText > remainingCharacters) then
                            debugText = string.sub(debugText, 1, remainingCharacters - 3) .. "..."
                        end
                        term.setTextColor(colors.white)
                        term.write(debugText)
                    end
                end
            end
            -- Input
            os.sleep(sleepTime)
        else
            os.sleep(5)
        end
    end
end

function inputRoutine()
    while true do
        local e,k = os.pullEvent("key")
        if k == keys.right then
            interfaceTab = interfaceTab + 1
            if interfaceTab > #interfaceTabs then
                interfaceTab = 1
            end
        elseif k == keys.left then
            interfaceTab = interfaceTab - 1
            if interfaceTab < 1 then
                interfaceTab = #interfaceTabs
            end
        end
    end
end

-- Run
debug("Startup")

while true do
    parallel.waitForAll(networkRoutine,storageRoutine,interfaceRoutine,quickStorageRoutine, inputRoutine, storageTotalsRoutine, emptyClearRoutine)
    printError("Crashed | Restarting in 5 seconds...")
    sleep(5)
end
