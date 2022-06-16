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
        print("Running [" .. instruction .. "] " .. #newInstructions .. " remain.")
        t.resumeInstructions = newInstructions
        local ran = false;
        if (instruction == "m-up")then
            turtleMotor.turtleMoveUp()
            ran = true
        elseif (instruction == "m-down")then
            turtleMotor.turtleMoveDown()
            ran = true
        elseif (instruction == "m-forward")then
            turtleMotor.turtleMoveForward()
            ran = true
        elseif (instruction == "b-up")then
            turtleBuild.buildUp()
            ran = true
        elseif (instruction == "b-down")then
            turtleBuild.buildDown()
            ran = true
        elseif (instruction == "b-forward")then
            turtleBuild.buildForward()
            ran = true
        elseif (instruction == "b-backward")then
            turtleBuild.buildBackward()
            ran = true
        elseif (instruction == "r-up")then
            t.direction = "up"
            ran = true
        elseif (instruction == "r-down")then
            t.direction = "down"
            ran = true
        elseif (instruction == "m-wall-height")then
            local wallWanted = tonumber(commApi.SendRequest("GET wanted-height"))
            local x, y, z = turtleMotor.getCoords()
            while math.floor(y - 0.75) < wallWanted do
                x, y, z = turtleMotor.getCoords()
                turtleMotor.turtleMoveUp()
            end
            ran = true
        elseif (instruction == "f-north")then
            turtleMotor.faceDirection("north")
            ran = true
        elseif (instruction == "f-east")then
            turtleMotor.faceDirection("east")
            ran = true
        elseif (instruction == "f-south")then
            turtleMotor.faceDirection("south")
            ran = true
        elseif (instruction == "f-west")then
            turtleMotor.faceDirection("west")
            ran = true
        elseif (instruction == "m-north")then
            turtleMotor.faceDirection("north")
            turtleMotor.turtleMoveForward()
            ran = true
        elseif (instruction == "m-east")then
            turtleMotor.faceDirection("east")
            turtleMotor.turtleMoveForward()
            ran = true
        elseif (instruction == "m-south")then
            turtleMotor.faceDirection("south")
            turtleMotor.turtleMoveForward()
            ran = true
        elseif (instruction == "m-west")then
            turtleMotor.faceDirection("west")
            turtleMotor.turtleMoveForward()
            ran = true
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
            ran = true
        elseif (instruction == "t-left")then
            turtleMotor.turnLeft()
            ran = true
        elseif (instruction == "t-right")then
            turtleMotor.turnRight()
            ran = true
        end
        if not ran then
            print("Could not run [" .. instruction .. "]")
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