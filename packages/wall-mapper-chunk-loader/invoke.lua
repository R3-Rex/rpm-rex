local VERSION = "0.7b"
--For Graphical "Beauty"
w, h = term.getSize()
term.clear()

local dividerDashes = "";
for i = 3, w do
    dividerDashes = dividerDashes .. "-"
end
-- Fin

path = "config/buildState.cfg"
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
        t.direction = "up"
        t.resumeInstructions = {}
        saveData()
        f = fs.open(path, "r")
        
    end
   
    t = textutils.unserialize(f.readAll())
end

loadData()

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
function RunServerInstructions()
    local ask = commApi.SendRequest("VERSION " .. VERSION)
    local continue = (ask == "true");
    while continue do
        local command = commApi.SendRequest("GET command")
        if (command == "false")then
            continue = false;
        else
            if (command == "restart") then
                os.reboot();
            end
        end
    end
end





cPrint("Starting Drone v" .. VERSION, colors.lime)
os.sleep(1)
cPrint(dividerDashes)
cPrint("Loading Apis")
--Apis Here
tryLoadAPI("util/commApi.lua")
tryLoadAPI("util/inventoryApi.lua")
tryLoadAPI("util/turtleMotor.lua")
tryLoadAPI("util/groundSkim.lua")
tryLoadAPI("util/turtleBuild.lua")



--_________________
cPrint("Finished")
cPrint(dividerDashes)

shell.run("delete config/turtleInfo.cfg")
cPrint("Startup sequence complete!", colors.green)
cPrint("")

--ScanUpRow()


local inRange = true
while inRange do
    local x, y, z = turtleMotor.getCoords()
    local currentEnd = tonumber(commApi.SendRequest("CHUNK " .. x)) - 8
    cPrint((currentEnd - x) .. " blocks from furthest back")
    if (currentEnd - x > 16) then
        turtleMotor.faceDirection("east")
        for i = 1, 16 do
            groundSkim.turtleForwardStaircase()
        end
        for i = 1, 16 do
            turtleMotor.turtleMoveUp()
        end
        turtle.placeUp()
        turtleMotor.faceDirection("west")
        for i = 1, 16 do
            groundSkim.turtleForwardStaircase()
        end
        for i = 1, 16 do
            turtleMotor.turtleMoveUp()
        end
        turtle.select(1)
        turtle.digUp()
        turtleMotor.faceDirection("east")
        for i = 1, 16 do
            groundSkim.turtleForwardStaircase()
        end
        for i = 1, 16 do
            turtleMotor.turtleMoveUp()
        end
    end
    os.sleep(5)
end