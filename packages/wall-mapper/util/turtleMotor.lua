path = "config/turtleInfo.cfg"
t = {}
local function saveData()
    local f = fs.open(path, "w")
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
end

local networkChannel = 23475
local networkServerProtocol = networkChannel .. "-r-construction-server"
local networkDroneProtocol = networkChannel .. "-r-construction-drone"
local networkID = os.getComputerID()
function getFromServer(message)
    rednet.broadcast(message, networkServerProtocol)
    local senderID, rmessage = rednet.receive(networkDroneProtocol, 15) 

    if (senderID == null) then
        term.setTextColor(colors.red)
        print("Failed to recieve from server, protocol [" .. networkServerProtocol .. "], trying again.")
        return sendToServer(message)
    end
    return rmessage;
end

function sendStatusToServer(status)
    getFromServer("status " .. status)
end



function setTurtleGPS()
    local x, y, z = gps.locate(5)
    local changed = false
    if (t.x ~= x) then
        changed = true
        t.x = x
    end
    if (t.y ~= y) then
        changed = true
        t.y = y
    end
    if (t.z ~= z) then
        changed = true
        t.z = z
    end
    saveData()
    return changed
end

function setTurtleStatus(id, status)
    getTurtleData(id)
    t[id].status = status
    saveData()
end

function startupReload()
    loadData()
    if (setTurtleGPS()) then
        t.x = 0
        t.y = 0
        t.z = 0
        saveData()
        print("Turtle is in a different position on startup!")
        print("Enter turtle direction (north, east, south, west)")
        t.direction = string.lower(read())
    end
    faceDirection("north")
end

function turtleMoveForward()
    local complete = false
    while not complete do
        if (turtle.forward()) then
            complete = true;
        else
            if (turtle.getFuelLevel() == 0) then
                sendStatusToServer("Out of gas")
                while turtle.getFuelLevel() == 0 do
                    for i = 1, 16 do
                        turtle.select(i)
                        turtle.refuel()
                    end
                end
            else
                if (turtle.detect()) then
                    turtle.dig()
                else
                    sendStatusToServer("Unknown error!")
                end
            end
        end
    end
    setTurtleGPS()
end
function turtleMoveUp()
    local complete = false
    while not complete do
        if (turtle.up()) then
            complete = true;
        else
            if (turtle.getFuelLevel() == 0) then
                sendStatusToServer("Out of gas")
                while turtle.getFuelLevel() == 0 do
                    for i = 1, 16 do
                        turtle.select(i)
                        turtle.refuel()
                    end
                end
            else
                if (turtle.detectUp()) then
                    turtle.digUp()
                else
                    sendStatusToServer("Unknown error!")
                end
            end
        end
    end
    setTurtleGPS()
end
function turtleMoveDown()
    local complete = false
    while not complete do
        if (turtle.down()) then
            complete = true;
        else
            if (turtle.getFuelLevel() == 0) then
                sendStatusToServer("Out of gas")
                while turtle.getFuelLevel() == 0 do
                    for i = 1, 16 do
                        turtle.select(i)
                        turtle.refuel()
                    end
                end
            else
                if (turtle.detectDown()) then
                    turtle.digDown()
                else
                    sendStatusToServer("Unknown error!")
                end
            end
        end
    end
    setTurtleGPS()
end

function turtleMoveDirection(direction)
    faceDirection(direction)
    turtleMoveForward()
end

startupReload()

