path = "rsetup/.setup-data"
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
        fields[1] = {}
        fields[1]["title"] = "String"
        fields[1]["description"] = "A empty default string"
        fields[1]["type"] = "s"
        fields[1]["variable"] = "default-string"
        fields[1]["default-value"] = "Enter String Here"
        fields[2] = {}
        fields[2]["title"] = "Color"
        fields[2]["description"] = "A color"
        fields[2]["type"] = "c"
        fields[2]["variable"] = "default-color"
        fields[2]["default-value"] = "white"
        fields[3] = {}
        fields[3]["title"] = "Int Number"
        fields[3]["description"] = "A int number"
        fields[3]["type"] = "i"
        fields[3]["variable"] = "default-int"
        fields[3]["default-value"] = "1"
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
        local v = string.sub(value, i - 1,i)
        v = v .. ""
        print("Searching [" .. filter .. "] for [" .. v .. "]")
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
        local filter = "0123456789-"
        local filterValue = filterString(value, filter)
        if filterValue:len() < 1 then
            filterValue = "0"
        end
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
    setupData[field["variable"]] = currentValue
end
loadData()

askField(1)
askField(2)
askField(3)