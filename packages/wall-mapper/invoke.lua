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

cPrint("Starting Drone v2.11")
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
cPrint("Startup sequence complete!", colors.green)
cPrint("")

turtleBuild.buildDown()
local tx, ty, tz = turtleMotor.getCoords()
commApi.SendRequest("GPS " .. tx .. " " .. ty .. " " .. tz)
commApi.SendRequest("SET " .. tz)

local inRange = true
while inRange do
    local x, y, z = turtleMotor.getCoords()
    print(x .. "," .. y.. "," .. z)
    if (x >= wallStart and x <= wallEnd) then
        turtleMotor.faceDirection("east")
        groundSkim.turtleForwardStaircase()
        turtleBuild.buildDown()
        commApi.SendRequest("GPS " .. x .. " " .. y .. " " .. z)
        commApi.SendRequest("SET " .. z)
    else
        commApi.SendRequest("STATUS Finished.")
        inRange = false;
    end
end