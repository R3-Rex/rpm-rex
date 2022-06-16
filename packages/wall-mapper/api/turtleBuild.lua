

function buildDown()
    local block = commApi.SendRequest("GET block-down")
    if block ~= "false" then
        inventoryApi.GetItem(block)
        commApi.SendRequest("STATUS green")
        local built = false;
        while not built do
            if (turtle.placeDown()) then
                built = true
            else
                if (turtle.detectDown()) then
                    if not turtle.digDown() then
                        commApi.SendRequest("STATUS Indestructable Down")
                        os.sleep(1)
                    end
                end
            end
        end
        commApi.SendRequest("SET down")
    end
    commApi.SendRequest("STATUS green")
end
function buildUp()
    local block = commApi.SendRequest("GET block-up")
    if block ~= "false" then
        inventoryApi.GetItem(block)
        commApi.SendRequest("STATUS green")
        local built = false;
        while not built do
            if (turtle.placeUp()) then
                built = true
            else
                if (turtle.detectUp()) then
                    if not turtle.digUp() then
                        commApi.SendRequest("STATUS Indestructable Up")
                        os.sleep(1)
                    end
                end
            end
        end
        commApi.SendRequest("SET up")
    end
    commApi.SendRequest("STATUS green")
end
function buildForward()
    local block = commApi.SendRequest("GET block-forward")
    if block ~= "false" then
        inventoryApi.GetItem(block)
        commApi.SendRequest("STATUS green")
        local built = false;
        while not built do
            if (turtle.place()) then
                built = true
            else
                if (turtle.detect()) then
                    if not turtle.dig() then
                        commApi.SendRequest("STATUS Indestructable Front")
                        os.sleep(1)
                    end
                end
            end
        end
        commApi.SendRequest("SET forward")
    end
    commApi.SendRequest("STATUS green")
end

function buildBackward()
    local block = commApi.SendRequest("GET block-backward")
    if block ~= "false" then
        turtleMotor.faceDirection("west")
        inventoryApi.GetItem(block)
        commApi.SendRequest("STATUS green")
        local built = false;
        while not built do
            if (turtle.place()) then
                built = true
            else
                if (turtle.detect()) then
                    if not turtle.dig() then
                        commApi.SendRequest("STATUS Indestructable Front")
                        os.sleep(1)
                    end
                end
            end
        end
        commApi.SendRequest("SET forward")
        turtleMotor.faceDirection("east")
    end
    commApi.SendRequest("STATUS green")
end