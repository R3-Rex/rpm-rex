local VERSION = "8.2r"
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
    print("Scanning up row from " .. y .. " to " .. wallWanted)
    while math.floor(y + 0.25) < wallWanted do
        commApi.RunServerInstructions()
        x, y, z = turtleMotor.getCoords()
        instructionApi.AddCommands({"b-down", "b-forward", "m-up"})
        instructionApi.RunResumeInstructions()
    end
    print("Scan Up Complete")
    instructionApi.AddCommands({"b-down", "m-east", "m-east", "m-wall-height", "m-down", "b-forward", "m-down", "r-down"})
    instructionApi.RunResumeInstructions()
end
function ScanDownRow()
    print("Scanning Down Row")
    local continue = true
    while continue do
        commApi.RunServerInstructions()
        if (not turtle.detectDown()) then
            instructionApi.AddCommands({"b-up", "b-forward", "m-down"})
            instructionApi.RunResumeInstructions()
        else
            continue = false
        end
    end
    print("Scan Down Complete")
    instructionApi.AddCommands({"m-up", "b-down", "m-east", "b-backward", "m-down", "b-up", "m-east", "b-backward", "r-up"})
    instructionApi.RunResumeInstructions()
end



cPrint("Starting Drone v" .. VERSION, colors.lime)
os.sleep(1)
cPrint(dividerDashes)
cPrint("Loading Apis")
--Apis Here
tryLoadAPI("util/commApi.lua")
commApi.SetVersion(VERSION)
commApi.RunServerInstructions()
tryLoadAPI("util/inventoryApi.lua")
inventoryApi.CheckResumeState()
tryLoadAPI("util/turtleMotor.lua")
tryLoadAPI("util/groundSkim.lua")
tryLoadAPI("util/turtleBuild.lua")
tryLoadAPI("util/instructionApi.lua")

turtleMotor.startupReload()

--_________________
cPrint("Finished")
cPrint(dividerDashes)

cPrint("Loading static data from server")
local wallStart = tonumber(commApi.SendRequest("GET wall-start"))
local wallEnd = tonumber(commApi.SendRequest("GET wall-end"))

cPrint("Startup sequence complete!", colors.green)
cPrint("")

--ScanUpRow()

instructionApi.RunResumeInstructions()

local inRange = true
while inRange do
    local x, y, z = turtleMotor.getCoords()
    if (x >= wallStart and x <= wallEnd) then
        instructionApi.AddCommands({"f-east"})
        instructionApi.RunResumeInstructions()
        if (instructionApi.GetDirection() == "up") then
            ScanUpRow()
        else
            ScanDownRow()
        end
    else
        commApi.SendRequest("STATUS Finished.")
        inRange = false;
    end
end