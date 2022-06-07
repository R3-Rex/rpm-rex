term.clear()
term.setCursorPos(1, 1)


w, h = term.getSize()
term.clear()

local dividerDashes = "";
for i = 3, w do
    dividerDashes = dividerDashes .. "-"
end

function cPrint(text, color)
    if (color == nil) then
        color = colors.white
    end
    term.setTextColor(color)
    print(text)
    term.setTextColor(colors.white)
end

cPrint("Updating Drone", colors.magenta)
cPrint(dividerDashes)
cPrint("Attempting to Update Program")
shell.run("rpm update")
cPrint("Finished", colors.green)
cPrint(dividerDashes)
shell.run("invoke")