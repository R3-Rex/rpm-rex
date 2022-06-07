shell.run("rpm update")
term.clear()
term.setCursorPos(1, 1)

--For Graphical "Beauty"
w, h = term.getSize()
term.clear()

local dividerDashes = "";
for i = 3, w do
    dividerDashes = dividerDashes .. "-"
end
-- Fin

function cPrint(text, color)
    if (color == nil) then
        color = colors.white
    end
    term.setTextColor(color)
    print(text)
    term.setTextColor(colors.white)
end

function tryLoadAPI(path)
    local api = nil
    local status, err = pcall(function ()
        api = os.loadAPI(path)
    end)
    if (status) then
        cPrint("Load API - [" .. path .. "]", colors.green)
    else
        cPrint("Load API - [" .. path .. "]", colors.red)
        cPrint(err, colors.red)
    end
    return api
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
        print("Failed to recieve from server, protocol [" .. networkServerProtocol .. "], trying again. [" .. message .. "]")
        return sendToServer(message)
    end
    return rmessage;
end

function tryLoadFromServer(title)
    local list = nil
    local status, err = pcall(function ()
        local data = getFromServer("get " .. title)
        list = textutils.unserialise(data)
    end)
    if (status) then
        cPrint("Load DATA - [" .. title .. "]", colors.green)
    else
        cPrint("Load DATA - [" .. title .. "]", colors.red)
        cPrint(err, colors.red)
    end
    return list
end


--Functions
function sendGPSToServer()
    local x, y, z = gps.locate(5)
    getFromServer("gps " .. x .. " " .. y .. " " .. z)
end
function sendStatusToServer(status)
    getFromServer("status " .. status)
end
function sendAltitudeToServer()
    getFromServer("set")
end

cPrint("Starting Drone v1.0")

os.sleep(1)
cPrint("Opening Rednet")
if (peripheral.getType("right") == "modem") then
    rednet.open("right")
    cPrint("Opened rednet right.", colors.green)
elseif (peripheral.getType("right") == "modem") then
    rednet.open("left")
    cPrint("Opened rednet left.", colors.green)
else
    term.setBackgroundColor(colors.red)
    term.clear()
    term.setCursorPos(2, 2)
    cPrint("Failed to open to network!", colors.black)
    term.setBackgroundColor(colors.black)
    while true do
        os.sleep(1)
    end
end
cPrint("Finished")
cPrint(dividerDashes)
cPrint("Loading static data from server")
local itemList = tryLoadFromServer("itemlist")
local wallCoords = tryLoadFromServer("wallcoords")
cPrint("Startup sequence complete!", colors.green)
cPrint("")

cPrint(dividerDashes)
cPrint("Loading Apis")
--Apis Here
tryLoadAPI("util/turtleMotor.lua")
tryLoadAPI("util/groundSkim.lua")
tryLoadAPI("util/turtleBuild.lua")

--_________________
cPrint("Finished")
cPrint(dividerDashes)

local inRange = true
while inRange do
    local x, y, z = gps.locate(5)
    print(x .. "," .. y.. "," .. z)
    if (x >= wallCoords["wallStartX"] and x <= wallCoords["wallEndX"]) then
        turtleMotor.faceDirection("east")
        groundSkim.turtleForwardStaircase()
        turtleBuild.buildDown()
        sendGPSToServer()
        sendAltitudeToServer()
    else
        inRange = false;
    end
end