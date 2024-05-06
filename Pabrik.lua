
local hits = 2
local delay = 170

local autoFlour = false
local autoVend = false
--
local canStart = false

local blockID
local seedID

local originalTile
local grinderTile

local function Overlay(message)

    local variant = {}
    variant[0] = "OnTextOverlay"
    variant[1] = message

    sendVariant(variant)
end

local function Inventory(id)
    for _, item in pairs(getInventory()) do
        if item.id == id then return item end
    end

    return nil
end


local function Action(action, id, val, val2)

    if action == "drop" then 
        
        local item = Inventory(id)

        sendPacket(2, "action|drop\n|itemID|" ..item.id)
        sleep(100)
        sendPacket(2, "action|dialog_return\ndialog_name|drop_item\nitemID|" ..item.id.. "|\ncount|" ..item.amount)

    elseif action == "vend" then

        local packet = {
            type = 3,
            value = 32,
            x = getLocal().pos.x,
            y = getLocal().pos.y,
            punchx = math.floor(getLocal().pos.x / 32),
            punchy = math.floor(getLocal().pos.y / 32)
        }

        sendPacketRaw(false, packet)
        sleep(100)
        sendPacket(2, "action|dialog_return\ndialog_name|vending\ntilex|" ..math.floor(getLocal().pos.x / 32).. "|\ntiley|" ..math.floor(getLocal().pos.y / 32).. "|\nbuttonClicked|addstock\n\nsetprice|0\nchk_peritem|0\nchk_perlock|1")
    
    elseif action == "grind" then

        local packet = {
            type = 3,
            value = 880,
            x = getLocal().pos.x,
            y = getLocal().pos.y,
            punchx = math.floor(getLocal().pos.x / 32) - 1,
            punchy = math.floor(getLocal().pos.y / 32)
        }

        sendPacketRaw(false, packet)
        sleep(100)
        sendPacket(2, "action|dialog_return\ndialog_name|grinder\ntilex|" ..(math.floor(getLocal().pos.x / 32) - 1).. "|\ntiley|" ..math.floor(getLocal().pos.y / 32).."|\nitemID|880|\ncount|" ..val)

    end
end

local function Store()

    if autoFlour == true then

        findPath(grinderTile.pos.x + 1, grinderTile.pos.y)
        repeat sleep(30) until math.floor(getLocal().pos.x / 32) == grinderTile.pos.x + 1 and math.floor(getLocal().pos.y / 32) == grinderTile.pos.y
        sleep(500)
        
        local wheat = Inventory(880)

        if wheat ~= nil and wheat.amount >= 50 then

            local toGrind = math.floor(wheat.amount / 50)

            Action("grind", nil, toGrind)
        end

        sleep(500)
        findPath(originalTile.x, originalTile.y)
        repeat sleep(30) until math.floor(getLocal().pos.x / 32) == originalTile.x and math.floor(getLocal().pos.y / 32) == originalTile.y

        if autoVend == true then
            Action("vend")
        elseif autoVend == false then
            Action("drop", 4562)
        end

    elseif autoFlour == false then

        findPath(originalTile.x, originalTile.y)
        repeat sleep(30) until math.floor(getLocal().pos.x / 32) == originalTile.x and math.floor(getLocal().pos.y / 32) == originalTile.y

        if autoVend == true then
            Action("vend")
        elseif autoVend == false then
            Action("drop", seedID)
        end
    end
end

local function Harvest()

    local stopLoop = false
    local treeFound = false

    for x = 0, 99 do
        
        local tile = checkTile(x, math.floor(getLocal().pos.y / 32))
        local tileExtra = getExtraTile(x, math.floor(getLocal().pos.y / 32))

        if tile.fg == seedID and tileExtra.ready == true then
            treeFound = true

            findPath(x, math.floor(getLocal().pos.y / 32))
            repeat sleep(30) until math.floor(getLocal().pos.x / 32) == x

            if #getWorldObject() > 0 then

                local xx = math.floor(getLocal().pos.x / 32)
                local yy = math.floor(getLocal().pos.y / 32)
        
                for _, object in pairs(getWorldObject()) do
        
                    local X = math.floor(object.pos.x / 32)
                    local Y = math.floor(object.pos.y / 32)
        
                    if (math.abs(xx - X) < 4) and (math.abs(yy- Y) < 3) and object.amount < 20 then
                        local packet = {
                            type = 11,
                            value = object.oid,
                            x = object.pos.x,
                            y = object.pos.y
                        }

                        sendPacketRaw(false, packet)
                        sleep(10)
                    end
                end
            end

            while checkTile(math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)).fg ~= 0 do
                sleep(delay)
                requestTileChange(math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32), 18)
            end

            for _, item in pairs(getInventory()) do
                if item.id == blockID and item.amount > 180 then stopLoop = true break end
            end
        end

        if stopLoop == true then break end
    end

    sleep(500)

    if #getWorldObject() > 0 then

        local xx = math.floor(getLocal().pos.x / 32)
        local yy = math.floor(getLocal().pos.y / 32)

        for _, object in pairs(getWorldObject()) do

            local X = math.floor(object.pos.x / 32)
            local Y = math.floor(object.pos.y / 32)

            if (math.abs(xx - X) < 4) and (math.abs(yy- Y) < 3) and object.amount < 20 then
                local packet = {
                    type = 11,
                    value = object.oid,
                    x = object.pos.x,
                    y = object.pos.y
                }

                sendPacketRaw(false, packet)
                sleep(10)
            end
        end
    end

    return treeFound
end

local function Break()

    local seedGoal = 0

    for x = 0, 99 do

        local tile = checkTile(x, math.floor(getLocal().pos.y / 32))
        local tileBelow = checkTile(x, math.floor(getLocal().pos.y / 32) + 1)

        if tile.fg == 0 and tileBelow.fg ~= 0 then
            seedGoal = seedGoal + 1
        end
    end

    findPath(originalTile.x, originalTile.y)
    repeat sleep(30) until math.floor(getLocal().pos.x / 32) == originalTile.x

    while Inventory(blockID) ~= nil do
        if autoFlour == true then
            if Inventory(seedID) ~= nil and Inventory(seedID).amount >= seedGoal then break end
        end

        for i = -2, 2 do
            sleep(delay)
            requestTileChange(math.floor(getLocal().pos.x / 32) + i, math.floor(getLocal().pos.y / 32) - 1, blockID)
        end

        if #getWorldObject() > 0 then

            local xx = math.floor(getLocal().pos.x / 32)
            local yy = math.floor(getLocal().pos.y / 32)
    
            for _, object in pairs(getWorldObject()) do
    
                local X = math.floor(object.pos.x / 32)
                local Y = math.floor(object.pos.y / 32)
    
                if (math.abs(xx - X) < 4) and (math.abs(yy - Y) < 3) and yy > Y and object.amount < 5 then
                    local packet = {
                        type = 11,
                        value = object.oid,
                        x = object.pos.x,
                        y = object.pos.y
                    }

                    sendPacketRaw(false, packet)
                    sleep(10)
                end
            end
        end

        for i = -2, 2 do
            for ii = 1, hits do
                sleep(delay)
                requestTileChange(math.floor(getLocal().pos.x / 32) + i, math.floor(getLocal().pos.y / 32) - 1, 18)
            end
        end
    end

    sleep(500)

    if #getWorldObject() > 0 then

        local xx = math.floor(getLocal().pos.x / 32)
        local yy = math.floor(getLocal().pos.y / 32)

        for _, object in pairs(getWorldObject()) do

            local X = math.floor(object.pos.x / 32)
            local Y = math.floor(object.pos.y / 32)

            if (math.abs(xx - X) < 4) and (math.abs(yy- Y) < 3) and object.amount < 5 then
                local packet = {
                    type = 11,
                    value = object.oid,
                    x = object.pos.x,
                    y = object.pos.y
                }

                sendPacketRaw(false, packet)
                sleep(10)
            end
        end
    end
end

local function Plant()

    for x = 0, 99 do

        local tile = checkTile(x, math.floor(getLocal().pos.y / 32))
        local tileBelow = checkTile(x, math.floor(getLocal().pos.y / 32) + 1)

        if tile.fg == 0 and tileBelow.fg ~= 0 then

            findPath(x, math.floor(getLocal().pos.y / 32))
            repeat sleep(30) until math.floor(getLocal().pos.x / 32) == x

            while checkTile(math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32)).fg == 0 do
                
                local haveSeed = false

                for _, item in pairs(getInventory()) do
                    if item.id == seedID then haveSeed = true break end
                end

                if haveSeed == false then
                    Overlay("`4Ran out of seeds!")

                    break
                end

                sleep(delay)
                requestTileChange(math.floor(getLocal().pos.x / 32), math.floor(getLocal().pos.y / 32), seedID)
            end
        end
    end
end

local function Prepare()

    Overlay("`9Preparing stuff, please wait..")
    sleep(1000)
    local tile = checkTile(math.floor(getLocal().pos.x / 32) + 2, math.floor(getLocal().pos.y / 32))

    if tile.fg ~= 0 then
        Overlay("`2" ..getItemByID(tile.fg).name.. "`9 found!")

        blockID = tile.fg - 1
        seedID = tile.fg

    else
        Overlay("`4No trees found 2 tiles to the right of avatar!")

        return false
    end

    sleep(1000)
    
    if autoFlour == true then
        for _, tile in pairs(getTile()) do
            if tile.fg == 4582 then grinderTile = tile break end
        end
    
        if grinderTile ~= nil then
            Overlay("`2Food Grinder `9found!")
        else
            Overlay("`4World does not have any food grinder!")
    
            return false
        end
    end

    sleep(1000)

    originalTile = {
        x = math.floor(getLocal().pos.x / 32),
        y = math.floor(getLocal().pos.y / 32)
    }
    Overlay("`9Original position set to (`2" ..originalTile.x.. "`9, `2" ..originalTile.y.. "`9)!")

    return true
end

AddHook("OnTextPacket", "GetInput", function(type, str)
    
    if str:find("/start") then
        canStart = not canStart

        Overlay("`9Pabrik status set to `2" ..tostring(canStart))
    end
end)

AddHook("OnVarlist", "DisableDialog", function(var)
    if var[0] == "OnDialogRequest" then return true end
end)

-- MAIN THREAD
while true do
    while canStart ~= true do sleep(1000) end

    local check = Prepare()

    if check == true then

        local success, result = pcall(function()
            
            if Harvest() == true then
                Break()
                Plant()
                sleep(1000)
                Store()
            else
                Overlay("`4No ready to harvest trees found, will check again in 10 seconds..")
                sleep(10000)
            end
        end)
    
        if not success then
            logToConsole("`4An error occured, but no worries script will resume in a moment..")

            sleep(5000)
        end
    else
        canStart = false
    end
end
