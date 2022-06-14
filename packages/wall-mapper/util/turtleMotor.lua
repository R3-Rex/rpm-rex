path = "config/turtleInfo.cfg"
t = {}
local function saveData()
    local f = fs.open(path, "w")
    local rescan = false;
    if (t.x == nil) then
        rescan = true
    end
    if (t.y == nil) then
        rescan = true
    end
    if (t.z == ma) then
        rescan = true
    end
    if (rescan) then
        local x, y, z = gps.locate(5)
        t.x = x
        t.y = y
        t.z = z
    end
    t.x = math.floor(t.x + 0.5)
    t.y = math.floor(t.y + 0.5)
    t.z = math.floor(t.z + 0.5)
    f.write(textutils.serialise(t))
    f.close()
end
local function loadData()
    local f = nil
    if fs.exists(path) then
        f = fs.open(path, "r")
    else
        t.x = 0
        t.y = 0
        t.z = 0
        t.direction = "north"
        saveData()
        f = fs.open(path, "r")
        
    end
   
    t = textutils.unserialize(f.readAll())
end

local function PingServer()
    commApi.SendRequest("STATUS green")
    commApi.SendRequest("GPS " .. t.x .. " " .. t.y .. " " .. t.z)
    commApi.SendRequest("FUEL " .. turtle.getFuelLevel())
    os.setComputerLabel("Rex Drone " .. os.getComputerID() .. " [" .. turtle.getFuelLevel() .. "]")
end
function turnLeft()
    local complete = false
    while not complete do
        if (turtle.turnLeft()) then
            complete = true;
        end
    end
    if (t.direction == "north") then
        t.direction = "west"
    elseif(t.direction == "east") then
        t.direction = "north"
    elseif(t.direction == "south") then
        t.direction = "east"
    elseif(t.direction == "west") then
        t.direction = "south"
    end
    saveData()
end
function turnRight()
    local complete = false
    while not complete do
        if (turtle.turnRight()) then
            complete = true;
        end
    end
    if (t.direction == "north") then
        t.direction = "east"
    elseif(t.direction == "east") then
        t.direction = "south"
    elseif(t.direction == "south") then
        t.direction = "west"
    elseif(t.direction == "west") then
        t.direction = "north"
    end
    saveData()
end

function getCoords()
    return t.x, t.y, t.z
end

function faceDirection(direction)
    direction = string.lower(direction)
    if (t.direction ~= direction) then
        if (t.direction == "north") then
            if (direction == "east") then
                turnRight()
            elseif (direction == "west") then
                turnLeft()
            else
                turnRight()
                turnRight()
            end
        elseif(t.direction == "east") then
            if (direction == "south") then
                turnRight()
            elseif (direction == "north") then
                turnLeft()
            else
                turnRight()
                turnRight()
            end
        elseif(t.direction == "south") then
            if (direction == "west") then
                turnRight()
            elseif (direction == "east") then
                turnLeft()
            else
                turnRight()
                turnRight()
            end
        elseif(t.direction == "west") then
            if (direction == "north") then
                turnRight()
            elseif (direction == "south") then
                turnLeft()
            else
                turnRight()
                turnRight()
            end
        end
    end
    saveData()
end



function setTurtleGPS()
    local x, y, z = gps.locate(5)
    local changed = 0
    if (t.x ~= x) then
        changed = math.max(math.abs(t.x - x), changed)
        t.x = x
    end
    if (t.y ~= y) then
        changed = math.max(math.abs(t.y - y), changed)
        t.y = y
    end
    if (t.z ~= z) then
        changed = math.max(math.abs(t.z - z), changed)
        t.z = z
    end
    saveData()
    return changed
end

function turtleMoveForward()
    local complete = false
    while not complete do
        if (turtle.forward()) then
            complete = true;
        else
            if (turtle.getFuelLevel() == 0) then
                commApi.SendRequest("STATUS Out of gas")
                while turtle.getFuelLevel() == 0 do
                    for i = 1, 16 do
                        turtle.select(i)
                        turtle.refuel()
                    end
                    inventoryApi.GetItem("minecraft:coal_block")
                end
            else
                if (turtle.detect()) then
                    turtle.dig()
                else
                    commApi.SendRequest("STATUS HELP Unknown Error!")
                end
            end
        end
    end
    if (t.direction == "north") then
        t.y = t.y - 1
    elseif(t.direction == "east") then
        t.x = t.x + 1
    elseif(t.direction == "south") then
        t.y = t.y + 1
    elseif(t.direction == "west") then
        t.x = t.x - 1
    end
    PingServer()
end
function turtleMoveUp()
    local complete = false
    while not complete do
        if (turtle.up()) then
            complete = true;
        else
            if (turtle.getFuelLevel() == 0) then
                commApi.SendRequest("STATUS Out of gas")
                while turtle.getFuelLevel() == 0 do
                    for i = 1, 16 do
                        turtle.select(i)
                        turtle.refuel()
                    end
                    inventoryApi.GetItem("minecraft:coal_block")
                end
            else
                if (turtle.detectUp()) then
                    turtle.digUp()
                else
                    commApi.SendRequest("STATUS HELP Unknown Error!")
                end
            end
        end
    end
    t.y = t.y + 1
    PingServer()
end
function turtleMoveDown()
    local complete = false
    while not complete do
        if (turtle.down()) then
            complete = true;
        else
            if (turtle.getFuelLevel() == 0) then
                commApi.SendRequest("STATUS Out of gas")
                while turtle.getFuelLevel() == 0 do
                    for i = 1, 16 do
                        turtle.select(i)
                        turtle.refuel()
                    end
                    inventoryApi.GetItem("minecraft:coal_block")
                end
            else
                if (turtle.detectDown()) then
                    turtle.digDown()
                else
                    commApi.SendRequest("STATUS HELP Unknown Error!")
                end
            end
        end
    end
    t.y = t.y - 1
    PingServer()
end

function setTurtleStatus(id, status)
    getTurtleData(id)
    t[id].status = status
    saveData()
end

function testTurtleDirection()
    local upCount = 0
    local downCount = 0
    local cleared = false;
    local stillComplete = true
    while not cleared and stillComplete do
        cleared = true
    end
    if (cleared and stillComplete) then
        local sx, sy, sz = gps.locate(5)
        turtleMoveForward()
        local fx, fy, fz = gps.locate(5)

        local xOffset = fx - sx
        local yOffset = fz - sz

        if (xOffset > 0.5) then
            t.direction = "east"
        elseif(xOffset < -0.5) then
            t.direction = "west"
        elseif(yOffset > 0.5) then
            t.direction = "south"
        elseif(yOffset < -0.5) then
            t.direction = "north"
        end
        --Return Back there
        turnRight()
        turnRight()
        turtleMoveForward()
        turnRight()
        turnRight()
    end
    for i = 1, upCount do
        turtleMoveDown()
    end
    if (not stillComplete) then
        saveData()
        return false
    else
        saveData()
        return true
    end
end

function startupReload()
    loadData()
    if (setTurtleGPS() > 1.5) then
        t.x = 0
        t.y = 0
        t.z = 0
        saveData()
        print("Turtle is in a different position on startup!")
        if (testTurtleDirection()) then
            print("Found turtle direction by testing!", colors.green)
        else
            setTurtleGPS()
            PingServer()
            commApi.SendRequest("STATUS HELP Manual Direction")
            local valid = false
            while not valid do
                print("Enter turtle direction (north, east, south, west)")
                t.direction = string.lower(read())
                if (t.direction == "north") then
                    valid = true
                elseif(t.direction == "east") then
                    valid = true
                elseif(t.direction == "south") then
                    valid = true
                elseif(t.direction == "west") then
                    valid = true
                end
            end
        end
        setTurtleGPS()
        saveData()
    end
    PingServer()
end



function turtleMoveDirection(direction)
    faceDirection(direction)
    turtleMoveForward()
end

startupReload()

