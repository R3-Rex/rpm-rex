--Will let the turtle skim the ground until it finds the desired bottom to consider the base block

function turtleForwardStaircase()
    local notValid = true
    while notValid do
        if (turtle.detect()) then
            turtleMotor.turtleMoveUp()
        else
            notValid = false
        end
    end
    turtleMotor.turtleMoveForward()
    notValid = true
    while notValid do
        if not turtle.detectDown() then
            turtleMotor.turtleMoveDown()
        else
            notValid = false
        end
    end
end