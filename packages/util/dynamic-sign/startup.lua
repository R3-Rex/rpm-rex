




path = ".sign-data"
t = {}
screens = {}
function generateScreen(text, bg, fg)
    local sd = {}
    sd["text"] = text
    sd["background-color"] = bg
    sd["text-color"] = fg
    sd["timer"] = 1
    sd["screen-scale"] = 1
    return sd
end
function saveData()
    t["screens"] = screens
    f = fs.open(path, "w")
    f.write(textutils.serialise(t))
    f.close()
end
function loadData()
    f = nil
    if fs.exists(path) then
        f = fs.open(path, "r")
    else
        t["display"] = "back"
        t["screen-count"] = 1
        screens[1] = generateScreen("Default", "black", "white")
        saveData()
        f = fs.open(path, "r")
    end
   
    t = textutils.unserialize(f.readAll())
    screens = t["screens"]
end
loadData()

term.redirect(peripheral.wrap(t["display"]))


function drawScreen(index)
    local lsd = screens[index]
    peripheral.wrap(t["display"]).setTextScale(lsd["screen-scale"])
    sleep()

    local w, h = term.getSize()

    paintutils.drawFilledBox(1, 1, w, h, colors[lsd["background-color"]])

    term.setBackgroundColor(colors[lsd["background-color"]])
    term.setTextColor(colors[lsd["text-color"]])
    
    local cr = math.ceil((w - #lsd["text"]) / 2) + 1

    term.setCursorPos(cr, math.ceil(h / 2))
    term.write(lsd["text"])
    return lsd["timer"]
end

currentIndex = 1
while true do
    print("Loading screen " .. currentIndex)
    sleep(drawScreen(currentIndex))
    currentIndex = currentIndex + 1
    if currentIndex > t["screen-count"] then
        currentIndex = 1
    end
end