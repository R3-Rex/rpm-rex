args = {...}

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

function checkDownDig(floorless)
    if turtle.detectDown() then
        exists, blockData = turtle.inspectDown();
        print(blockData.name)
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
    turtle.dig();
    turtle.forward();
    turtle.dig();
    turtle.forward();
    turtle.turnLeft();
    turtle.dig();
    turtle.forward();
    turtle.dig();
    turtle.forward();
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
                turtle.dig();
                turtle.forward();
            else
                if (column < 5) then
                    if turnLeft then
                        turtle.turnLeft();
                        turtle.dig();
                        turtle.forward();
                        turtle.turnLeft();
                        turnLeft = false;
                    else
                        turtle.turnRight();
                        turtle.dig();
                        turtle.forward();
                        turtle.turnRight();
                        turnLeft = true;
                    end
                else
                    turtle.turnLeft();
                    turtle.forward();
                    turtle.forward();
                    turtle.turnLeft();
                    turtle.forward();
                    turtle.forward();
                    turtle.turnRight();
                end
            end
        end
    end
    turtle.down();
    return floorless
end

function buildDown()
    local found = false
    local warned = false
    while not found do
        if (findMinedBuildableBlock()) then
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

function BuildLevel()
    turtle.up();
    turtle.dig();
    turtle.forward();
    turtle.dig();
    turtle.forward();
    turtle.turnLeft();
    turtle.dig();
    turtle.forward();
    turtle.dig();
    turtle.forward();
    turtle.turnLeft();
    turtle.turnLeft();


    local turnLeft = false;
    local column = 0;
    while (column < 5) do
        column = column + 1;
        for i=1, 5 do
            buildDown()
            
            if i < 5 then
                turtle.dig();
                turtle.forward();
            else
                if (column < 5) then
                    if turnLeft then
                        turtle.turnLeft();
                        turtle.dig();
                        turtle.forward();
                        turtle.turnLeft();
                        turnLeft = false;
                    else
                        turtle.turnRight();
                        turtle.dig();
                        turtle.forward();
                        turtle.turnRight();
                        turnLeft = true;
                    end
                else
                    turtle.turnLeft();
                    turtle.forward();
                    turtle.forward();
                    turtle.turnLeft();
                    turtle.forward();
                    turtle.forward();
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
    end
    print("Finished mining to solid ground, Begining building.");
    for i = 1, layers do
        BuildLevel()
    end
end

function turtleForwardStaircase()
    local notValid = true
    while notValid do
        if (turtle.detect()) then
            turtle.digUp()
            turtle.up()
        else
            if not turtle.detectDown() then
                turtle.down()
            else
                notValid = false
            end
        end
    end
    turtle.forward()
end
print("5x5 Base V1.0")
print("----------------------")
print("Starting 5x5 Base in 10 seconds")
while true do
    doBase()
    turtleForwardStaircase()
    turtleForwardStaircase()
    turtleForwardStaircase()
    turtleForwardStaircase()
    turtleForwardStaircase()
end