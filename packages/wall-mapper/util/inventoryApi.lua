

local function TestSelected()
    local data = turtle.getItemDetail()
    if (data ~= nil) then
        if data.count > 0 then
            return data.name;
        end
    end
    return false
end
local function FindItem(itemID)
    local foundInt = -1
    if (TestSelected() == itemID) then
        return true
    else
        for i=1,16 do
            turtle.select(i);
            if (TestSelected() == itemID) then
                foundInt = i
            end
        end
    end
    if (foundInt ~= -1) then
        turtle.select(foundInt)
        return true
    end
    return false
end

local chestItems = 
{"minecraft:packed_ice", "minecraft:packed_ice", "minecraft:packed_ice", "minecraft:packed_ice", "minecraft:packed_ice", "minecraft:packed_ice", "minecraft:packed_ice",
"minecraft:ice", "minecraft:ice", "minecraft:ice", "minecraft:ice", "minecraft:ice", "minecraft:ice", "minecraft:ice",
"minecraft:snow", "minecraft:snow", "minecraft:snow", "minecraft:snow", "minecraft:snow", "minecraft:snow", "minecraft:snow", 
"minecraft:coal_block", "minecraft:coal_block", "minecraft:coal_block", "minecraft:coal_block", "minecraft:coal_block", "minecraft:coal_block"
}

local function GetFromChest(itemID, count)
    local itemList = {}
    itemList.total = 0
    local chest = peripheral.wrap('bottom')

    for i = 1, 27 do
        local slotData = chest.list()[i]
        
        if (slotData.name == itemID) then
        local newData = {}
        newData.slot = i
        newData.count = slotData.count
        itemList.total = itemList.total + slotData.count;
        itemList[#itemList + 1] = newData
        end
    end
    local localSlot = turtle.getSelectedSlot()
    for i, v in pairs(itemList) do
        if (i ~= "total") then
            local maxPull = math.min(count, v.count)
            if (maxPull > 0) then
                print("Pull " .. maxPull .. " from " .. v.slot .. " to " .. localSlot)
                turtle.pullItems("bottom", v.slot, maxPull, localSlot)
            end
        end
    end
    return count;
end


local function PullItem(itemID)
    while not FindItem("enderstorage:ender_storage") do
        commApi.SendRequest("STATUS Pull Error")
        os.sleep(1)
    end
    local placed = false;
    local moved = 0
    while not placed do
        if (turtle.placeDown()) then
            placed = true;
        else
            turtleMotor.turtleMoveUp()
            moved = moved + 1
        end
    end

    --Get Empty Slot
    for i = 1, 16 do
        turtle.select(i)
        if (turtle.getItemDetail() == nil or i == 16)  then
            turtle.dropUp()
            break;
        end
    end

    --Chest ready
    local pullAmount = 64
    while pullAmount > 0 do
        pullAmount = GetFromChest(itemID, pullAmount)
        if (pullAmount > 0) then
            commApi.SendRequest("STATUS Pull Error")
        end
    end

    --Wind Down
    for i = 1, 16 do
        turtle.select(i)
        if (turtle.getItemDetail() == nil or i == 16)  then
            turtle.dropUp()
            break;
        end
    end
    local picked = false;
    while not picked do
        if (turtle.digDown()) then
            picked = true;
        else
            commApi.SendRequest("STATUS Pull Error")
            os.sleep(1)
        end
    end
    for i = 1, moved do
        turtleMotor.turtleMoveDown()
    end
end

function GetItem(itemID)
    local got = false;
    while not got do
        if (FindItem(itemID)) then
            got = true;
        else
            PullItem(itemID)
        end
    end
    return turtle.getSelectedSlot()
end