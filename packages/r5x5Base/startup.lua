args = {...}

shell.run("rpm update")

local topMaterial = "minecraft:packed_ice"
local validList = {"minecraft:dirt", "minecraft:gravel", "minecraft:sand", "minecraft:cobblestone", "minecraft:diorite", "minecraft:andesite", "minecraft:packed_ice", "minecraft:ice"}
function testSlot()
    local data = turtle.getItemDetail()
    if (data ~= nil) then
        if data.count > 0 then
            local found = false
            for i, v in pairs(validList) do
                if (v == data.name) then
                    found = true
                end
            end
            if found then
                return true
            else
                print("Throwing " .. data.name)
                turtle.dropDown(data.count)
            end
        end
    end
    return false
end

function testIce()
    local data = turtle.getItemDetail()
    if (data ~= nil) then
        if data.count > 0 then
            local found = false
            for i, v in pairs(validList) do
                if (topMaterial == data.name) then
                    return true
                end
            end
        end
    end
    return false
end

function doForward()
    local forwardYet = false;
    while not forwardYet do
        if (turtle.forward()) then
            forwardYet = true
        else
            if (turtle.detect()) then
                turtle.dig()
            end
        end
    end
end

function doUp()
    local upYet = false;
    while not upYet do
        if (turtle.up()) then
            upYet = true
        else
            if (turtle.detectUp()) then
                turtle.digUp()
            end
        end
    end
end
function doDown()
    local downYet = false;
    while not downYet do
        if (turtle.down()) then
            downYet = true
        else
            if (turtle.detectDown()) then
                turtle.digDown()
            end
        end
    end
end
function findMinedBuildableBlock()
    local foundInt = -1
    if (testSlot()) then
        return true
    else
        for i=1,16 do
            turtle.select(i);
            if (testSlot()) then
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

function findPackedIce()
    local foundInt = -1
    if (testIce()) then
        return true
    else
        for i=1,16 do
            turtle.select(i);
            if (testIce()) then
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

function checkDownDig(floorless)
    if turtle.detectDown() then
        exists, blockData = turtle.inspectDown();
        if blockData.name ~= "minecraft:water" then
            turtle.digDown()
        else
            floorless = true;
        end
    else
        floorless = true;
    end
    return floorless;
end

function checkLevel()
    doForward()
    doForward()
    turtle.turnLeft();
    doForward()
    doForward()
    turtle.turnLeft();
    turtle.turnLeft();

    local floorless = false;

    local turnLeft = false;
    local column = 0;
    while (column < 5) do
        column = column + 1;
        for i=1, 5 do
            floorless = checkDownDig(floorless);
            
            if i < 5 then
                doForward()
            else
                if (column < 5) then
                    if turnLeft then
                        turtle.turnLeft();
                        doForward()
                        turtle.turnLeft();
                        turnLeft = false;
                    else
                        turtle.turnRight();
                        doForward()
                        turtle.turnRight();
                        turnLeft = true;
                    end
                else
                    turtle.turnLeft();
                    doForward()
                    doForward()
                    turtle.turnLeft();
                    doForward()
                    doForward()
                    turtle.turnRight();
                end
            end
        end
    end
    doDown()
    return floorless
end

function buildDown(isTop)
    local found = false
    local warned = false
    while not found do
        local findMinable = findMinedBuildableBlock()
        if (isTop) then
            findMinable = findPackedIce()
        end
        if (findMinable) then
            found = true
        else
            if not warned then
                print("Out of buildable blocks, waiting for more!")
            end
            os.sleep(5)
        end
    end
    turtle.placeDown()
end

function BuildLevel(isTop)
    doUp()
    doForward()
    doForward()
    turtle.turnLeft();
    doForward()
    doForward()
    turtle.turnLeft();
    turtle.turnLeft();


    local turnLeft = false;
    local column = 0;
    while (column < 5) do
        column = column + 1;
        for i=1, 5 do
            local isTopCurrent = isTop
            if (column == 1 or column == 5) then
                isTopCurrent = true
            end
            if (i == 1 or i == 5) then
                isTopCurrent = true
            end
            buildDown(isTopCurrent)
            
            if i < 5 then
                doForward()
            else
                if (column < 5) then
                    if turnLeft then
                        turtle.turnLeft();
                        doForward()
                        turtle.turnLeft();
                        turnLeft = false;
                    else
                        turtle.turnRight();
                        doForward()
                        turtle.turnRight();
                        turnLeft = true;
                    end
                else
                    turtle.turnLeft();
                    doForward()
                    doForward()
                    turtle.turnLeft();
                    doForward()
                    doForward()
                    turtle.turnRight();
                end
            end
        end
    end
    return floorless
end

function doBase()
    print("Starting now")
    findMinedBuildableBlock()
    local heightOffset = 0
    print("Building foundation 5x5")
    local foundBottom = false;
    local layers = 0;

    if args[1] ~= nil then
        layers = tonumber(args[1])
        foundBottom = true
        args = {}
    end
    local materialRequirements = 0;
    while not foundBottom do
        layers = layers + 1;
        if checkLevel() then
            print("Layer " .. layers .. " is not solid.")
        else
            foundBottom = true;
            layers = layers + heightOffset
            materialRequirements = layers * 25
            print("Layer " .. layers .. " is solid. Needs " .. materialRequirements .. " blocks.")
        end
        findMinedBuildableBlock()
    end
    print("Finished mining to solid ground, Begining building.");
    for i = 1, layers do
        local isTop = false
        if i == layers then
            isTop = true
        end
        BuildLevel(isTop)
    end
end

function turtleForwardStaircase()
    local notValid = true
    local movedUp = false
    while notValid do
        if (turtle.detect()) then
            doUp()
            movedUp = true
        else
            if not turtle.detectDown() and not movedUp then
                doDown()
            else
                notValid = false
            end
        end
    end
    doForward()
end
print("----------------------")
print("5x5 Base V1.16")
print("----------------------")
print("Enter resume height and/or press enter to start.")
print("----------------------")
local input = read("*")
if (#input > 0) then
    args[1] = input
end
print("Starting 5x5 Base in 10 seconds")
os.sleep(10)
while true do
    local nextArea = false
    while not nextArea do
        exists, blockData = turtle.inspectDown();
        if (exists) then
            if (blockData.name == topMaterial) then
                nextArea = false
                turtleForwardStaircase()
                turtleForwardStaircase()
                turtleForwardStaircase()
                turtleForwardStaircase()
                turtleForwardStaircase()
            else
                nextArea = true
            end
        else
            nextArea = true
        end
    end
    doBase()
end