local VERSION = "6.22r"
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
function RunResumeInstructions()
    while #t.resumeInstructions > 0 do
        local instruction = t.resumeInstructions[1]
        for i = 2, #t.resumeInstructions do
            t.resumeInstructions[i - 1] = t.resumeInstructions[i]
        end
        t.resumeInstructions[ #t.resumeInstructions] = nil
        if (instruction == "m-up")then
            turtleMotor.turtleMoveUp()
        elseif (instruction == "m-down")then
            turtleMotor.turtleMoveDown()
        elseif (instruction == "m-forward")then
            turtleMotor.turtleMoveForward()
        elseif (instruction == "b-up")then
            turtleBuild.buildUp()
        elseif (instruction == "b-down")then
            turtleBuild.buildDown()
        elseif (instruction == "b-forward")then
            turtleBuild.buildForward()
        elseif (instruction == "b-backward")then
            turtleBuild.buildBackward()
        elseif (instruction == "r-up")then
            t.direction = "up"
        elseif (instruction == "r-down")then
            t.direction = "down"
        elseif (instruction == "m-wall-height")then
            local wallWanted = tonumber(commApi.SendRequest("GET wanted-height"))
            local x, y, z = turtleMotor.getCoords()
            while math.floor(y - 0.75) < wallWanted do
                x, y, z = turtleMotor.getCoords()
                turtleMotor.turtleMoveUp()
            end
        elseif (instruction == "f-north")then
            turtleMotor.faceDirection("north")
        elseif (instruction == "f-east")then
            turtleMotor.faceDirection("east")
        elseif (instruction == "f-south")then
            turtleMotor.faceDirection("south")
        elseif (instruction == "f-west")then
            turtleMotor.faceDirection("west")
        elseif (instruction == "m-north")then
            turtleMotor.faceDirection("north")
            turtleMotor.turtleMoveForward()
        elseif (instruction == "m-east")then
            turtleMotor.faceDirection("east")
            turtleMotor.turtleMoveForward()
        elseif (instruction == "m-south")then
            turtleMotor.faceDirection("south")
            turtleMotor.turtleMoveForward()
        elseif (instruction == "m-west")then
            turtleMotor.faceDirection("west")
            turtleMotor.turtleMoveForward()
        end
        
        commApi.RunServerInstructions()
        saveData()
    end
end
function ScanUpRow()
    local x, y, z = turtleMotor.getCoords()
    local wallHeight = tonumber(commApi.SendRequest("GET height")) + 1
    local wallWanted = tonumber(commApi.SendRequest("GET wanted-height"))

    while math.floor(y + 0.25) < wallWanted do
        RunServerInstructions()
        x, y, z = turtleMotor.getCoords()
        turtleBuild.buildDown()
        turtleBuild.buildForward()
        turtleMotor.turtleMoveUp()
    end
    t.resumeInstructions = {"b-down", "m-east", "m-east", "m-wall-height", "m-down", "b-forward", "m-down", "r-down"}
    saveData()

    RunResumeInstructions()
end
function ScanDownRow()

    local continue = true
    while continue do
        RunServerInstructions()
        if (not turtle.detectDown()) then
            turtleBuild.buildUp()
            turtleBuild.buildForward()
            turtleMotor.turtleMoveDown()
        else
            continue = false
        end
    end
    t.resumeInstructions = {"m-up", "b-down", "m-east", "b-backward", "m-down", "b-up", "m-east", "b-backward", "r-up"}
    saveData()

    RunResumeInstructions()
end



cPrint("Starting Drone v" .. VERSION, colors.lime)
os.sleep(1)
cPrint(dividerDashes)
cPrint("Loading Apis")
--Apis Here
tryLoadAPI("util/commApi.lua")
RunServerInstructions()
tryLoadAPI("util/inventoryApi.lua")
inventoryApi.CheckResumeState()
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

--ScanUpRow()

RunResumeInstructions()

local inRange = true
while inRange do
    local x, y, z = turtleMotor.getCoords()
    if (x >= wallStart and x <= wallEnd) then
        turtleMotor.faceDirection("east")
        RunResumeInstructions()
        if (t.direction == "up") then
            ScanUpRow()
        else
            ScanDownRow()
        end
    else
        commApi.SendRequest("STATUS Finished.")
        inRange = false;
    end
end