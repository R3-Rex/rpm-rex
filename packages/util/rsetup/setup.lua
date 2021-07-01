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
    screens = t["screens"]
end
function askField(index){
    local w, h = term.getSize()

    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    paintutils.drawFilledBox(1, 1, w, 3)
    term.setCursorPos(2, 2)
    term.write(t["setup-title"])
    term.setCursorPos(3 + #t["setup-title"] , 3)
    term.setTextColor(colors.lightGray)
    term.write(t["setup-path"])
}
loadData()

askField(1)