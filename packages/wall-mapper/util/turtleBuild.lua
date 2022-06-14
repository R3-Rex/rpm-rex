

function buildDown()
    commApi.SendRequest("STATUS green")
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
                    if not turtle.digDown() then
                        commApi.SendRequest("STATUS Indestructable Down")
                        os.sleep(1)
                    end
                end
            end
        end
    end
    commApi.SendRequest("STATUS green")
end