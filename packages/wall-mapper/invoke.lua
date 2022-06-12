
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

function ScanUpRow()
    local x, y, z = turtleMotor.getCoords()
    local wallHeight = tonumber(commApi.SendRequest("GET height")) + 1
    local wallWanted = tonumber(commApi.SendRequest("GET wanted-height"))
    local offset = wallWanted - (wallHeight - 1)
    if (offset > 0) then
        if (math.floor(y + 0.5) < wallHeight)then
            for i = 1, wallHeight - math.floor(y + 0.5) do
                turtleMotor.turtleMoveUp()
            end
        elseif (math.floor(y + 0.5) > wallHeight) then
            for i = 1, math.floor(y + 0.5) - wallHeight do
                if not turtle.detectDown() then
                    turtleMotor.turtleMoveDown()
                end
            end
        end
        while math.floor(y + 0.5) < wallWanted do
            x, y, z = turtleMotor.getCoords()
            turtleBuild.buildDown()
            commApi.SendRequest("SET " .. z)
            turtleMotor.turtleMoveUp()
        end
    end
end

cPrint("Starting Drone v3.14", colors.lime)
os.sleep(1)
cPrint(dividerDashes)
cPrint("Loading Apis")
--Apis Here
tryLoadAPI("util/commApi.lua")
tryLoadAPI("util/turtleMotor.lua")
tryLoadAPI("util/groundSkim.lua")
tryLoadAPI("util/turtleBuild.lua")

--_________________
cPrint("Finished")
cPrint(dividerDashes)

cPrint("Loading static data from server")
local wallStart = tonumber(commApi.SendRequest("GET wall-start"))
local wallEnd = tonumber(commApi.SendRequest("GET wall-end"))
shell.run("delete config/turtleInfo.cfg")
cPrint("Startup sequence complete!", colors.green)
cPrint("")

ScanUpRow()

local inRange = true
while inRange do
    os.setComputerLabel("Rex Drone " .. os.getComputerID() .. " [" .. turtle.getFuelLevel() .. "]")
    local x, y, z = turtleMotor.getCoords()
    print(x .. "," .. y.. "," .. z)
    if (x >= wallStart and x <= wallEnd) then
        turtleMotor.faceDirection("east")
        groundSkim.turtleForwardStaircase()
        ScanUpRow()
    else
        commApi.SendRequest("STATUS Finished.")
        inRange = false;
    end
end