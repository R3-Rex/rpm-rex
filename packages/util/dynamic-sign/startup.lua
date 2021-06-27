




path = ".sign-data"
t = {}
screens = {}
function generateScreen(text, bg, fg)
    local sd = {}
    sd["text"] = text
    sd["background-color"] = bg
    sd["text-color"] = fg
    sd["timer"] = 1
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
        t["screen-scale"] = 0.5
        t["display"] = "right"
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
peripheral.wrap(t["display"]).setTextScale(t["screen-scale"])

function drawScreen(index)
    local lsd = screens[index]
    local w, h = term.getSize()
    
    paintutils.drawFilledBox(1, 1, w, h, colors[lsd["background-color"]])

    term.setBackgroundColor(colors[lsd["background-color"]])
    term.setTextColor(colors[lsd["text-color"]])

    term.setCursorPos(math.ceil(math.ceil(w/2) - math.floor(#lsd["text"] / 2)), math.ceil(h / 2))
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