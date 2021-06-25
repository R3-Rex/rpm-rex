address = "http://0.0.0.0:8000"

function setAddress(_address)
    address = _address
end

local fetchInterval = 5

local function httpRequest(rawQuery)
    local query = ""
    for i=1,#rawQuery do
        local char = string.sub(rawQuery,i,i)
        query = query .. string.byte(char)
        if i ~= #rawQuery then
            query = query .. "-"
        end
    end

    local stream = http.get(address .. "/"..query,headers)
    if stream then
        local data = stream.readAll()
        stream.close()
        if data then
            return data
        end
    end
    return ""
end
function getIDTag()
    local idTag = "<" .. os.getComputerID() .. ">"
    return idTag
end
function getSendStringMessages(rawQuery)
    query = rawQuery .. "</" .. "end>"
    local idTag = getIDTag()
    maxLength = 50 - #idTag 
    n = string.len(query)
    pn = math.ceil(n / maxLength)
    parts = {}
    for i = 1, pn do
        part = string.sub(query, maxLength*(i-1) + 1, maxLength*i)
        parts[#parts + 1] = part
    end    
    return parts
end

function sendString(rawQuery)
    pn = getSendStringMessages(rawQuery)
    local idTag = getIDTag()

    httpRequest(idTag .. "[message" .. "Size]" .. #pn .. "</" .. "end>")

    returnData = ""
    for i = 1, #pn do
        part = pn[i]
        returnData = httpRequest(idTag .. part)
    end
    return returnData
end

function receiveString(async)
    while true do
        local receivedData = sendString("[receive" .. "Data]")
        if #receivedData > 0 then
            return receivedData
        elseif async then
            return false
        end
        sleep(fetchInterval)
    end
end
