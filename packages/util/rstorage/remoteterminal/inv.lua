-- Sorting Terminal
local chestID = 10000
local maxCapacity = 1000

-- APIS
os.loadAPI("/apis/sorter.lua")

-- Palette
local palette = {
    colors.black,
    colors.gray,
    colors.lightGray,
    colors.white,
    colors.cyan,
}

-- UI Functions
local function center(str,ln)
    local w,h = term.getSize()
    term.setCursorPos(w/2-(#str/2),ln)
    write(str)
end
local function setColor(fgCol,bgCol)
    fgCol = fgCol + 1
    bgCol = bgCol + 1
    term.setTextColor(palette[fgCol])
    if bgCol then
        term.setBackgroundColor(palette[bgCol])
    end
end

-- Inventory Routine
local currentMenu = 1
local menus = {"inventory", "manager", "stats", "console"}
local function menuRoutine()
    while true do
        local e = {os.pullEvent()}
        if e[1] == "key" then
            if e[2] == keys.left then
                currentMenu = currentMenu - 1
            elseif e[2] == keys.right then
                currentMenu = currentMenu + 1
            end
        end
        if (currentMenu > #menus) then
            currentMenu = 1
        elseif (currentMenu < 1) then
            currentMenu = #menus
        end
    end
end
local totals = {}
local orderedTotals = {}

local unallocated = 0
local totalAllocated = 0
local available = 0

local times = {}
local debugList = {}

local function invRoutine()
    while true do
        totals = sorter.totals()

        orderedTotals = {}
        if totals then
            --Get Incorperated Data
            unallocated = totals.unallocated
            totalAllocated = totals.totalAllocated
            available = totals.available
            times = totals.times
            debugList = totals.debug
            totals.unallocated = nil
            totals.totalAllocated = nil
            totals.available = nil
            totals.times = nil
            totals.debug = nil
            maxCapacity = totalAllocated
            --Fin
            for i,v in pairs(totals) do
                orderedTotals[#orderedTotals+1] = {i,v}
            end
            table.sort(orderedTotals, function(aValue,bValue) 
                if aValue and bValue then
                    return aValue[2] > bValue[2]
                else
                    print(aValue,bValue)
                    end
            end)
        end
        sleep(5)
    end
end

function mysplit (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function setProgressBar(barY, percent, text)
    local w,h = term.getSize()
    local wPercent = (w * percent) + 0.5
    local startBackgroundColor = term.getBackgroundColor()
    for i = 1, w do
        local color = colors.red
        if (i <= wPercent) then
            color = colors.green
        end
        term.setCursorPos(i, barY)
        term.setBackgroundColor(color)
        local char = " "
        if (i <= #text) then
            char =  string.sub(text, i, i)
        end
        term.write(char)
    end
    term.setBackgroundColor(startBackgroundColor)
end


--Inventory Variables
local searchTerm = ""
local scrollDist = 0
local selectedItem = false

local timersToCancel = {}

local function renderInventory()
    -- init
    for i,v in pairs(timersToCancel) do
        os.cancelTimer(v)
    end
    timersToCancel = {}
    local w,h = term.getSize()
    
    -- list
    local list = {}
    for _,v in pairs(orderedTotals) do
        local i,v = v[1],v[2]
        local meetsCriteria = true
        if searchTerm ~= "" then
            if not string.find(string.lower(i),string.lower(searchTerm)) then
                meetsCriteria = false
            end
        end
        if meetsCriteria then
            list[#list+1] = i
        end
    end
    
    
    -- selected item
    if #list > 0 and not selectedItem then
        selectedItem = 1
    elseif #list == 0 then
        selectedItem = false
    elseif selectedItem > #list then
        selectedItem = #list
    end
    if selectedItem then
        if selectedItem > scrollDist+(h-2) then
            selectedItem = scrollDist+(h-2)
        elseif selectedItem < scrollDist+1 then
            selectedItem = scrollDist+1
        end
    end
    local selected = list[selectedItem]
    
    -- draw
    setColor(0,0)
    term.clear()
    term.setCursorPos(1,1)
    setColor(2,1)
    term.clearLine()
    term.setCursorPos(2,1)
    if searchTerm == "" then
        write("Inventory")
    else
        setColor(3,1)
        write(searchTerm)
    end
    term.setCursorPos(1, h)
    setColor(2,0)
    term.clearLine()
    term.setCursorPos(2,h)
    
    write("[?] Pull   [<] Push")
    

    if totals then
        local heightOffset = 0
        for listHeight = 1,h-3 do
            local drawHeight = listHeight+1
            local listIndex = listHeight+scrollDist
            local listItem = list[listIndex]
            if listItem then
                term.setCursorPos(1, drawHeight + heightOffset)
                local selected = false
                if selectedItem and selectedItem == listIndex then
                    setColor(0,4)
                    selected = true
                else
                    setColor(3,0)
                end
                
                term.clearLine()
                term.setCursorPos(2, drawHeight + heightOffset)

                local maxCount = 0
                local damage = 0
                local maxDamage = 0
                local displayName = ""

                local datas = mysplit(listItem, "?")
                maxCount = tonumber(datas[1])
                damage = tonumber(datas[2])
                maxDamage = tonumber(datas[3])
                displayName = datas[4]
                damage = maxDamage - damage;

                    write(displayName)

                --Generate the count string
                local countString = "x" .. tostring(totals[listItem])
                if (totals[listItem] > 999) then
                    local kTotals = math.floor(totals[listItem] / 10)/100
                    if (totals[listItem] > 9999) then
                        kTotals = math.floor(totals[listItem] / 100)/10
                    end
                    if (totals[listItem] > 99999) then
                        kTotals = math.floor(totals[listItem] / 1000)
                    end
                    countString = "x" .. tostring(kTotals) .. "k"
                end

                local countLength = #countString + 1
                term.setCursorPos(w - countLength, drawHeight + heightOffset)
                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.lime)
                if (listIndex - math.floor(listIndex / 2) * 2) == 0 then
                    term.setBackgroundColor(colors.green)
                end
                if (selected) then
                    term.setBackgroundColor(colors.blue)
                end
                
                term.write(" " .. countString .. " ")

                if (selected) then
                    heightOffset = 1
                    setColor(0,4)
                    term.setTextColor(colors.gray)
                    term.setBackgroundColor(colors.lightGray)
                    term.setCursorPos(1, drawHeight + 1)
                    term.write("                                                                                   ")
                    term.setCursorPos(2, drawHeight + 1)
                    local fillPercent = math.ceil(totals[listItem] / maxCount)  / maxCapacity
                    fillPercent = math.ceil(fillPercent * 10000) / 100
                    term.write( "USING " .. fillPercent .. "% WITH " .. math.ceil(totals[listItem] / maxCount) .. "-" .. maxCount .. " STACKS")
                    if (maxDamage > 0) then
                        heightOffset = 2
                        term.setCursorPos(1, drawHeight + 2)
                        term.write("                                                                                   ")
                        term.setTextColor(colors.white)
                        setProgressBar(drawHeight + 2, damage / maxDamage, " " .. damage .. "/" .. maxDamage .. " Durability")
                    end
                end
            end
        end
    else
        term.setTextColor(colors.red)
        term.setBackgroundColor(colors.black)
        center("Storage array offline",h/2)
        table.insert(timersToCancel,os.startTimer(0.5))
    end

    -- draw

    local e = {os.pullEvent()}
    if e[1] == "mouse_scroll" then
        scrollDist = scrollDist + e[2]
        if scrollDist < 0 then
            scrollDist = 0
        elseif scrollDist > #list then
            scrollDist = #list
        end
    elseif e[1] == "mouse_click" then
        if e[4] > 1 then
            selectedItem = (e[4]-1)+scrollDist
        end
    elseif e[1] == "char" then
        searchTerm = searchTerm .. e[2]
    elseif e[1] == "key" then
        if e[2] == keys.delete then
            sorter.clearChest(chestID)
        elseif e[2] == keys.backspace then
            searchTerm = string.sub(searchTerm,1,#searchTerm-1)
        elseif e[2] == keys.pageDown then
            scrollDist = scrollDist + h
            if scrollDist > #list then
                scrollDist = #list
            end
        elseif e[2] == keys.pageUp then
            scrollDist = scrollDist - h
            if scrollDist < 0 then
                scrollDist = 0
            end
        end
        if selectedItem then
            if e[2] == keys.down then
                selectedItem = selectedItem + 1
                if selectedItem > #list then
                    selectedItem = #list
                end
                if selectedItem > scrollDist+(h-2) then
                    scrollDist = scrollDist + 1
                end
            elseif e[2] == keys.up then
                selectedItem = selectedItem - 1
                if selectedItem < 1 then
                    selectedItem = 1
                end
                if selectedItem < scrollDist + 1 then
                    scrollDist = scrollDist - 1
                end
            elseif e[2] == keys.enter then
                term.setCursorPos(1,h)
                setColor(2,0)
                term.clearLine()
                write(" Quantity > ")
                local quantity = tonumber(read()) or 1
                sorter.unmanageChest(chestID)
                sorter.fillChest(chestID,selected,quantity)
            end
        end
    end
end

local function writeStat(v, name, color)
    local width = term.getSize()
    width = width - 1
    term.setTextColor(color)
    write(tostring(math.floor(v)))
    term.setTextColor(colors.gray)
    local x, y = term.getCursorPos()
    local remainingWidth = width - (x + 1)
    local string = name
    if (#name > remainingWidth) then
        string = string.sub(name, 1, remainingWidth - 3) .. "..."
    end
    write(" "..string)
end

local function writeTag(name, height, bg, fg)
    local w,h = term.getSize()
    term.setBackgroundColor(bg)
    term.setTextColor(fg)
    term.setCursorPos(2, height)
    for i = 2, w - 1 do
        write(" ")
    end
    term.setCursorPos(3, height)
    term.write(name);
end


local function displayBreakdown(bdata,bcolors,y)
    -- calculate
    local width = term.getSize()
    width = width - 1
    local btotal = 0
    for i,v in pairs(bdata) do
        btotal = btotal + v
    end

    -- draw bar
    local bcount = 0
    term.setCursorPos(2,y)
    for i,v in pairs(bdata) do
        bcount = bcount + 1
        if bcolors[i] then
            term.setBackgroundColor(bcolors[i])
        else
            if bcount%2 == 0 then
                term.setBackgroundColor(colors.white)
            else
                term.setBackgroundColor(colors.lightGray)
            end
        end
        write(string.rep(" ",math.floor(width*(v/btotal))))
    end

    -- draw list
    local bcount = 0
    term.setBackgroundColor(colors.black)
    for i,v in pairs(bdata) do
        bcount = bcount + 1
        local color = colors.lightGray;
        if bcolors[i] then
            color = bcolors[i]
        else
            if bcount%2 == 0 then
                term.setTextColor(colors.white)
            end
        end
        term.setCursorPos(2,y+1+bcount)
        writeStat(v, i, color)
    end
end



local function renderStats()
    term.setBackgroundColor(colors.black)
    term.clear()

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(2, 1)
    term.clearLine()
    term.write("Statistics")
    local w,h = term.getSize()

    if (totals) then

        local diskImageHeight = h - 3 - 8

        local totalSpace = totalAllocated + unallocated
        local visualSpace = (w - 2) *  diskImageHeight

        local unallocatedCount = (unallocated / totalSpace) * visualSpace
        local totalAllocatedCount = (totalAllocated / totalSpace) * visualSpace
        local availableCount = visualSpace - ((available / totalSpace) * visualSpace)

        local current = 0
        for y = 1, diskImageHeight do
            for i = 2, w - 1 do
                current = current + 1
                term.setCursorPos(i, 2 + y)
                if (current <= unallocatedCount) then
                    --UnAllocated
                    term.setBackgroundColor(colors.gray)
                elseif (current <= availableCount) then
                    --Used
                    term.setBackgroundColor(colors.cyan)
                else
                    --Available
                    term.setBackgroundColor(colors.lightGray)
                end
                term.write(" ")
            end
        end

        local diskImageEnd = (3 + diskImageHeight)

        term.setBackgroundColor(colors.black)

        term.setCursorPos(2, diskImageEnd + 1)
        writeStat(unallocated, "unallocated", colors.gray)
        term.setCursorPos(2, diskImageEnd + 2)
        writeStat(totalAllocated - available, "used", colors.cyan)
        term.setCursorPos(2, diskImageEnd + 3)
        writeStat(available, "available", colors.lightGray)
        term.setCursorPos(2, diskImageEnd + 5)
        writeStat(totalAllocated, "total allocated", colors.orange)
        

        writeTag("Clean Inventory", h - 1, colors.yellow, colors.gray)

    else
        term.setTextColor(colors.red)
        term.setBackgroundColor(colors.black)
        center("Storage array offline",(h/2) + 1)
    end

    local e = {os.pullEvent()}
    if e[1] == "mouse_click" then
        if e[4] == h - 1 then
            if (totals) then
                writeTag("Cleaning...", h - 1, colors.white, colors.black)
                sorter.manageChest(-2)
                e = {os.pullEvent()}
                os.startTimer(5)
                e = {os.pullEvent()}
            end
        end
    end

end

local function renderManager()
    term.setBackgroundColor(colors.black)
    term.clear()

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(2, 1)
    term.clearLine()
    term.write("Manager")

    local w,h = term.getSize()

    if totals then
        displayBreakdown(times,{
            ["get display names"] = colors.red,
            ["misc chest reallocation"] = colors.orange,
            ["resource balancing"] = colors.yellow,
            ["indexing chests"] = colors.lime,
            ["chest classification"] = colors.cyan,
            ["drop chest clearing"] = colors.blue,
            ["resource chest reallocation"] = colors.purple,
            ["find stats"] = colors.gray,
            ["quick chest index"] = colors.green,
            ["storage totals"] = colors.orange,
            ["empty chest clearing"] = colors.blue
        },3)
    else
        term.setTextColor(colors.red)
        term.setBackgroundColor(colors.black)
        center("Storage array offline",h/2)
    end

    writeTag("Restart Sorter", h - 1, colors.red, colors.white)

    local e = {os.pullEvent()}
    if e[1] == "mouse_click" then
        if e[4] == h - 1 then
            writeTag("Restarting...", h - 1, colors.white, colors.black)
            sorter.manageChest(-1)
            e = {os.pullEvent()}
            os.startTimer(5)
            e = {os.pullEvent()}
        end
    end
end

local function renderConsole()
    term.setBackgroundColor(colors.black)
    term.clear()

    term.setBackgroundColor(colors.gray)
    term.setTextColor(colors.lightGray)
    term.setCursorPos(2, 1)
    term.clearLine()
    term.write("Console")

    local w,h = term.getSize()

    for i = 1, h - 1 do
        if (debugList[i] ~= nil) then
            term.setCursorPos(1, h - i + 1)
            term.setBackgroundColor(colors.black)
            term.setTextColor(colors.lightGray)
            local timeSince = (debugList[i].time - os.epoch("utc")) / -1000
            local minutes = math.floor(timeSince / 60)
            local seconds = math.floor(timeSince - (minutes * 60))
            local secondsString = seconds
            if (seconds < 10) then
                secondsString = "0" .. seconds
            end
            local timeString = "[" .. minutes .. ":" .. secondsString .. "] "
            term.write(timeString)
            local remainingCharacters = w - #timeString
            local debugText = debugList[i].text
            if (#debugText > remainingCharacters) then
                debugText = string.sub(debugText, 1, remainingCharacters - 3) .. "..."
            end
            term.setTextColor(colors.white)
            term.write(debugText)
        end
    end

    if not totals then
        term.setTextColor(colors.red)
        term.setCursorPos(10, 1)
        term.setBackgroundColor(colors.gray)
        term.write("Array offline")
    end
    os.sleep(0.1)
end

-- UI Routine
local function uiRoutine()
    while true do
        if (menus[currentMenu] == "inventory") then
            renderInventory()
        elseif (menus[currentMenu] == "stats") then
            renderStats()
        elseif (menus[currentMenu] == "manager") then
            renderManager()
        elseif (menus[currentMenu] == "console") then
            renderConsole()
        end
    end
end

-- Start
parallel.waitForAny(uiRoutine,invRoutine,menuRoutine)
