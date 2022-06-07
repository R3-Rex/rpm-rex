path = "config/server_data.cfg"
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
        t.address = "http://0.0.0.0:4960"
        saveData()
        f = fs.open(path, "r")
    end
    t = textutils.unserialize(f.readAll())
end

loadData()

function SendRequest(rawQuery)
    rawQuery = os.getComputerID() .. " " .. rawQuery
    local query = string.gsub(rawQuery, " ", "?")
    local stream = http.get(t.address .. "/" .. query, nil)
    if (stream) then
        local message = stream.readAll();
        stream.close()
        if message then
            return message
        end
    end
end

print(SendRequest("DEST message"))

