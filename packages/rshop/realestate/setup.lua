t = {}
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