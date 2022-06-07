--Will let the turtle skim the ground until it finds the desired bottom to consider the base block

function turtleForwardStaircase()
    local notValid = true
    local movedUp = false
    while notValid do
        if (turtle.detect()) then
            turtleMotor.turtleMoveUp()
            movedUp = true
        else
            if not turtle.detectDown() and not movedUp then
                turtleMotor.turtleMoveDown()
            else
                notValid = false
            end
        end
    end
    turtleMotor.turtleMoveForward()
end