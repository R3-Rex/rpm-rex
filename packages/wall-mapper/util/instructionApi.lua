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
function WipeInstructions()
    t.resumeInstructions = {}
    t.direction = "up"
    saveData()
end
function RunResumeInstructions()
    while #t.resumeInstructions > 0 do
        local instruction = t.resumeInstructions[1]
        local newInstructions = {}
        for i = 2, #t.resumeInstructions do
            newInstructions[#newInstructions + 1] = t.resumeInstructions[i]
        end
        t.resumeInstructions = newInstructions
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
        elseif (instruction == "d-up")then
            local picked = false;
            while not picked do
                if (turtle.digUp()) then
                    picked = true;
                else
                    commApi.SendRequest("STATUS Pull Error - Cant Grab")
                    commApi.RunServerInstructions();
                    os.sleep(1)
                end
            end
        elseif (instruction == "t-left")then
            turtleMotor.turnLeft()
        elseif (instruction == "t-right")then
            turtleMotor.turnRight()
        end
        saveData()
    end
end
loadData()
function AddCommands(newCommands)
    for i = 1, #newCommands do
        t.resumeInstructions[#t.resumeInstructions+1] = newCommands[i]
    end
    saveData()
end
function GetDirection()
    return t.direction
end