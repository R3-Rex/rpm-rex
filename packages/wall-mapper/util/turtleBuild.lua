local topMaterial = "minecraft:packed_ice"


local networkChannel = 23475
local networkServerProtocol = networkChannel .. "-r-construction-server"
local networkDroneProtocol = networkChannel .. "-r-construction-drone"
local networkID = os.getComputerID()
function getFromServer(message)
    rednet.broadcast(message, networkServerProtocol)
    local senderID, rmessage = rednet.receive(networkDroneProtocol, 15) 

    if (senderID == null) then
        term.setTextColor(colors.red)
        print("Failed to recieve from server, protocol [" .. networkServerProtocol .. "], trying again.")
        return sendToServer(message)
    end
    return rmessage;
end

function sendStatusToServer(status)
    getFromServer("status " .. status)
end

function testIce()
    local data = turtle.getItemDetail()
    if (data ~= nil) then
        if data.count > 0 then
            local found = false
            if (topMaterial == data.name) then
                return true
            end
        end
    end
    return false
end
function findPackedIce()
    local foundInt = -1
    if (testIce()) then
        return true
    else
        for i=1,16 do
            turtle.select(i);
            if (testIce()) then
                foundInt = i
            end
        end
    end
    if (foundInt ~= -1) then
        turtle.select(foundInt)
        return true
    end
    return false
end

function builtDone()
    if (turtle.detectDown()) then
        exists, blockData = turtle.inspectDown();
        if (exists) then
            if (blockData.name == topMaterial) then
                return true
            end
        end
    end
end

function buildDown()
    local found = false;
    while not found do
        if (findPackedIce()) then
            found = true
        else
            if ( builtDone())then
                found = true
            else
                sendStatusToServer("Needs Ice")
                while not found do
                    if (findPackedIce()) then
                        found = true
                    end
                end
            end
        end
    end
    local built = false;
    while not built do
        if (turtle.placeDown()) then
            built = true
        else
            if (turtle.detectDown()) then
                if builtDone() then
                    built = true
                end
                if not built then
                    turtle.digDown()
                end
            end
        end
    end
end