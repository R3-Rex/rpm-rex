path = ".setup-data"
t = {}
fields = {}
function saveData()
    t["fields"] = fields
    f = fs.open(path, "w")
    f.write(textutils.serialise(t))
    f.close()
end
function loadData()
    f = nil
    if fs.exists(path) then
        f = fs.open(path, "r")
    else
        t["setup-title"] = "Project Setup"
        t["setup-path"] = ".project-config"
        t["post-setup-program"] = "startup.lua"
        fields[1] = {}
        fields[1]["title"] = "String"
        fields[1]["description"] = "A empty default string"
        fields[1]["type"] = "s"
        fields[1]["variable"] = "default-string"
        fields[1]["default-value"] = "Enter String Here"
        saveData()
        f = fs.open(path, "r")
    end
   
    t = textutils.unserialize(f.readAll())
    fields = t["fields"]
    screens = t["screens"]
end
function setFieldVisual(data, default)
    local w, h = term.getSize()

    term.setBackgroundColor(colors.lightGray)
    term.setTextColor(colors.white)

    paintutils.drawFilledBox(2, 9, w-1, 9)
    
    if default then
        term.setTextColor(colors.gray)
    end

    term.setCursorPos(2, 9)
    term.write(data)
end
setupData = {}
currentColor = 0
stringColors = {"white", "orange", "magenta", "lightBlue", "yellow", "lime", "pink", "gray", "lightGray", "cyan", "purple", "blue", "brown", "green", "red", "black"}
function filterString(value, filter)
    local filterValue = ""
    for i = 1, value:len() do
        local v = string.sub(value, i,i)
        if string.find(filter, v) then
            filterValue = filterValue .. v
        end
    end
    return filterValue
end
function validateField(value, type)
    if type == "s" then
        return value
    end
    if type == "i" then
        local filter = "0123456789"
        local filterValue = filterString(value, filter)
        if string.sub(value, 1,1) == "-" then
            filterValue = "-" .. filterValue
        end
        return filterValue
    end
    if type == "f" then
        local filter = "0123456789."
        local filterValue = filterString(value, filter)
        if string.sub(value, 1,1) == "-" then
            filterValue = "-" .. filterValue
        end
        return filterValue
    end
    if type == "ls" then
        local filter = "abcdefghijklmnopqrstuvwxyz" .. ("abcdefghijklmnopqrstuvwxyz"):upper()
        local filterValue = filterString(value, filter)
        return filterValue
    end
    if type == "c" then
        currentColor = currentColor + 1
        if currentColor > #stringColors then
            currentColor = 1
        end
        return stringColors[currentColor]
    end
end
function askField(index)
    term.setBackgroundColor(colors.black)
    term.clear()
    local w, h = term.getSize()

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    paintutils.drawFilledBox(1, 1, w, 3)
    term.setCursorPos(2, 2)
    term.write(t["setup-title"])
    term.setCursorPos(3 + #t["setup-title"] , 2)
    term.setTextColor(colors.lightGray)
    term.write(t["setup-path"])

    local field = fields[index]

    term.setBackgroundColor(colors.black)

    term.setTextColor(colors.white)
    term.setCursorPos(2, 5)
    term.write(field["title"])

    term.setCursorPos(2, 7)
    term.setTextColor(colors.lightGray)
    term.write(field["description"])

    local currentValue = field["default-value"]
    setFieldVisual(currentValue, true)
    
    while true do
        --Scan for inputs here
        local e, key, isHeld = os.pullEvent()
        if e == "key" then
            if key == keys.backspace then
                currentValue = string.sub(currentValue, 0, math.max(#currentValue-1, 0))
                setFieldVisual(currentValue)
            elseif key == keys.enter then
                break
            elseif field["type"] == "c" then
                currentValue = validateField(currentValue, field["type"])
                setFieldVisual(currentValue)
            end
        elseif e == "char" then
            currentValue = currentValue .. key
            currentValue = validateField(currentValue, field["type"])
            setFieldVisual(currentValue)
        end
    end
    if field["type"] == "i" or field["type"] == "f"  then
        if currentValue:len() < 1 then
            currentValue = "0"
        end
        currentValue = tonumber(currentValue)
    end
    setupData[field["variable"]] = currentValue
end
loadData()
function runAsk(i)
    local v, massage = pcall(function()
            askField(i))
    end)
    if not v then
        error(message)
    end
    if v then
        return
    else
        runAsk(i)
    end
end
for i = 1, #fields do
    runAsk(i)
end

f = fs.open(t["setup-path"], "w")
f.write(textutils.serialise(setupData))
f.close()

local w, h = term.getSize()
term.setCursorPos(1, h)

shell.run(t["post-setup-program"])
