punch_delay = 200
move_delay = 400
drop_delay = 5000
warp_delay = 5000
interact_delay = 1000

max_warp_attempt = 5
max_drop_attempt = 5
max_collect_range = 3

trash_filter = {}
storage_filter = {868}
storage_world = ''
storage_method = ''
storage_position = {1, 0}
vend_positions = {
    {1, 0, 2},
    {2, 0, 3},
}

fuel_enabled = false
fuel_storage = ''

harvest_id = 866
harvest_worlds = {'anomietest|123'}
harvest_items = {868}
ignore_gems = false

harvest_providers = true
provider_items = {868}

retrieve_while_harvesting = false
retrieve_after_harvested = 200

retrieve_only = false
retrieve_delay = 10000

local client = load(makeRequest('https://raw.githubusercontent.com/MementoMortis/Untitled/refs/heads/main/client.lua').content)()
local harvest = {
    current_world = '',
    tree_found = false,
    harvested_trees = 0,
    dialog_string = nil,
    retrieveFromSucker = function(self, amt, type)
        local remove_id = harvest_id - 1
        local remove_amt = 200
        local remove_type = 'block'
        local initial_amt = client:findItem(remove_id).amount
        if type ~= nil then
            remove_id = harvest_id
            remove_type = 'seed'
        end
        if amt <= 200 then
            remove_amt = amt
        else
            remove_amt = remove_amt - initial_amt
        end
        sendPacket(2, 'action|dialog_return\ndialog_name|itemsucker_' ..remove_type.. '\ntilex|' ..(getLocal().pos.x // 32).. '|\ntiley|' ..(getLocal().pos.y // 32 + 1).. '|\nbuttonClicked|retrieveitem\n\nchk_enablesucking|1')
        sleep(interact_delay)
        sendPacket(2, 'action|dialog_return\ndialog_name|itemremovedfromsucker\ntilex|' ..(getLocal().pos.x // 32).. '|\ntiley|' ..(getLocal().pos.y // 32 + 1).. '|\nitemtoremove|' ..remove_amt)
        while client:findItem(remove_id).amount == initial_amt do sleep(500) end
        sleep(interact_delay)
        logToConsole('`2[ Mozarella ] `6Retrieved ' ..getItemByID(remove_id).name)
    end,
    checkGaia = function(self)
        local tiles = getTile()
        local tile
        local gaia_amt
        for i = 0, #tiles do
            tile = tiles[i]
            if tile.fg == 6946 then
                client:moveTo(tile.pos.x, tile.pos.y - 1)
                requestTileChange(getLocal().pos.x // 32, getLocal().pos.y // 32 + 1, 32)
                sleep(punch_delay)
                while not self.dialog_string do sleep(500) end
                sleep(interact_delay)
                if not self.dialog_string:find('currently empty!') then
                    gaia_amt = tonumber(self.dialog_string:match('add_textbox|The machine contains (%d+) `2'))
                    self:retrieveFromSucker(gaia_amt, true)
                    self.dialog_string = nil
                    return true
                else
                    logToConsole('`4[ Dojyaaan ] `6Gaia\'s Beacon is empty..')
                    self.dialog_string = nil
                end
            end
        end
    end,
    checkUT = function(self)
        local tiles = getTile()
        local tile
        local ut_amt
        for i = 0, #tiles do
            tile = tiles[i]
            if tile.fg == 6948 then
                client:moveTo(tile.pos.x, tile.pos.y - 1)
                requestTileChange(getLocal().pos.x // 32, getLocal().pos.y // 32 + 1, 32)
                sleep(punch_delay)
                while not self.dialog_string do sleep(500) end
                sleep(interact_delay)
                if not self.dialog_string:find('currently empty!') then
                    ut_amt = tonumber(self.dialog_string:match('add_textbox|The machine contains (%d+) `2'))
                    self:retrieveFromSucker(ut_amt)
                    self.dialog_string = nil
                    return true
                else
                    logToConsole('`4[ Dojyaaan ] `6Unstable Tesseract is empty..')
                    self.dialog_string = nil
                end
            end
        end
    end,
    checkGAUT = function(self)
        if not retrieve_while_harvesting and not retrieve_only then return end
        if retrieve_while_harvesting and self.harvested_trees < retrieve_after_harvested then return end
        self:initHook()
        logToConsole('`9[ Nyoho ] `6Retrieving from GAUT..')
        while self:checkUT() do
            client:storeItems()
        end
        self.harvested_trees = 0
        if harvest_providers then
            RemoveHook('t')
            return
        end
        while self:checkGaia() do
            client:dropItem(client:findItem(harvest_id))
        end
        RemoveHook('t')
    end,
    takeFuel = function(self)
        logToConsole('`9[ Nyoho ] `6Collecting fuel packs..')
        client:warpTo(fuel_storage)
        local initial_amt = client:findItem(1746).amount
        pcall(function()
            local objects = getWorldObject()
            local obj
            for i = 0, #objects do
                obj = objects[i]
                if obj.id == 1746 and client:moveTo(obj.pos.x // 32, obj.pos.y // 32, true) then
                    client:moveTo(obj.pos.x // 32, obj.pos.y // 32)
                    sendPacketRaw(false, {
                        type = 11,
                        value = obj.oid,
                        x = obj.pos.x,
                        y = obj.pos.y
                    })
                    sleep(10)
                end
            end
        end)
        while client:findItem(1746).amount == initial_amt do sleep(interact_delay) end
        logToConsole('2[ Mozarella ] `6Collected fuel packs..')
        client:warpTo(self.current_world)
    end,
    harvestProviders = function(self)
        if not harvest_providers then return end
        local provider_found = false
        for x = 2, 97, 5 do
            for i = -2, 2 do
                if x + i >= 0 and x + i <= 99 then
                    local tile = checkTile(x + i, getLocal().pos.y // 32)
                    if tile.fg == harvest_id and getExtraTile(tile.pos.x, tile.pos.y).ready then
                        provider_found = true
                    end
                end
            end
            if provider_found then
                for _, id in pairs(provider_items) do
                    if client:findItem(id).amount >= 150 then
                        return
                    end
                end
                client:moveTo(x, getLocal().pos.y // 32)
                for i = -2, 2 do
                    if getLocal().pos.x // 32 + i >= 0 and getLocal().pos.x // 32 + i <= 99 then
                        local tile = checkTile(getLocal().pos.x // 32 + i, getLocal().pos.y // 32)
                        if tile.fg == harvest_id and getExtraTile(tile.pos.x, tile.pos.y).ready then
                            while getExtraTile(tile.pos.x, tile.pos.y).ready do
                                requestTileChange(tile.pos.x, tile.pos.y, 18)
                                sleep(punch_delay * 5)
                            end
                        end
                    end
                end
                client:collectInRange()
                provider_found = false
            end
        end
    end,
    harvestWithFuel = function(self)
        if not fuel_enabled then return end
        for x = 0, 99 do
            if (x % 10) == 0 then
                if client:findItem(1746).amount < 10 then
                    self:takeFuel()
                    return
                end
            end
            if (x % 5) == 0 then
                if not retrieve_while_harvesting then
                    for _, id in pairs(harvest_items) do
                        if client:findItem(id).amount >= 180 then
                            return
                        end
                    end
                end
            end
            local tile = checkTile(x, getLocal().pos.y // 32)
            if tile.fg == harvest_id and getExtraTile(tile.pos.x, tile.pos.y).ready then
                client:moveTo(tile.pos.x, tile.pos.y)
                while checkTile(tile.pos.x, tile.pos.y).fg ~= 0 do
                    sleep(punch_delay)
                end
                self.harvested_trees = self.harvested_trees + 1
                if retrieve_while_harvesting then
                    if self.harvested_trees >= retrieve_after_harvested then
                        return
                    end
                end
            end
            if not retrieve_while_harvesting then client:collectInRange() end
        end
    end,
    harvestWithoutFuel = function(self)
        if harvest_providers or fuel_enabled then return end
        local tree_found = false
        for x = 2, 97, 5 do
            for i = -2, 2 do
                if x + i >= 0 and x + i <= 99 then
                    local tile = checkTile(x + i, getLocal().pos.y // 32)
                    if tile.fg == harvest_id and getExtraTile(tile.pos.x, tile.pos.y).ready then
                        tree_found = true
                    end
                end
            end
            if tree_found then
                if not retrieve_while_harvesting then
                    for _, id in pairs(harvest_items) do
                        if client:findItem(id).amount >= 180 then
                            return
                        end
                    end
                end
                client:moveTo(x, getLocal().pos.y // 32)
                for i = -2, 2 do
                    if getLocal().pos.x // 32 + i >= 0 and getLocal().pos.x // 32 + i <= 99 then
                        local tile = checkTile(getLocal().pos.x // 32 + i, getLocal().pos.y // 32)
                        if tile.fg == harvest_id and getExtraTile(tile.pos.x, tile.pos.y).ready then
                            while checkTile(tile.pos.x, tile.pos.y).fg ~= 0 do
                                requestTileChange(tile.pos.x, tile.pos.y, 18)
                                sleep(punch_delay)
                            end
                            self.harvested_trees = self.harvested_trees + 1
                            if retrieve_while_harvesting then
                                if self.harvested_trees >= retrieve_after_harvested then
                                    return
                                end
                            end
                        end
                    end
                end
                if not retrieve_while_harvesting then client:collectInRange() end
                tree_found = false
            end
        end
    end,
    checkRow = function(self, y_level)
        for x = 0, 99 do
            local tile = checkTile(x, y_level)
            if tile.fg == harvest_id and getExtraTile(tile.pos.x, tile.pos.y).ready then
                logToConsole('`2[ Mozarella ] `6Ready tile at Y=' ..y_level.. ' found.')
                return true
            end
        end
    end,
    checkRows = function(self)
        logToConsole('`9[ Nyoho ] `6Checking if there\'s a ready ' ..getItemByID(harvest_id).name)
        for y = 0, 53 do
            if self:checkRow(y) then
                if not retrieve_only then
                    client:moveTo(0, y)
                end
                return true
            end
        end
    end,
    initHook = function(self)
        AddHook('OnVarlist', 't', function(var, netID)
            if var[0]:find('OnDialogRequest') then
                if var[1]:find('Unstable Tesseract') or var[1]:find('Gaia\'s Beacon') then
                    self.dialog_string = var[1]
                end
            end
        end)
    end,
    main = function(self)
		toggleCheat(26, true)
        local enabled = true
        while enabled do
            local success, result = pcall(function()
                while #harvest_worlds > 0 do
                    self.current_world = harvest_worlds[1]
                    client:warpTo(self.current_world)
                    while self:checkRows() do
                        if not retrieve_only then
                            self:harvestProviders()
                            self:harvestWithFuel()
                            self:harvestWithoutFuel()
                        end
                        self:checkGAUT()
                        client:storeItems()
                        if retrieve_only then
                            sleep(retrieve_delay)
                        end
                    end
                    table.remove(harvest_worlds, 1)
                end
                logToConsole('`4[ Dojyaan ] `6No worlds left..')
                enabled = false
            end)
 
            if not success then
                local reconnected = false
 
                logToConsole('`9[ Nyoho ] `6Oh no! Script will resume once you return to ' ..self.current_world:upper():match('(%w+)').. '.')
                doLog(result)
                while not reconnected do
                    if self.current_world:upper():match('(%w+)'):match(getWorld().name) then reconnected = true end
                    sleep(3000)
                end
            end
        end
    end
}

harvest:main()
--[[
if auth:check_access() then
    auth:sendHook('<@' ..getDiscordID().. '> executed Harvest script, has access.')
	
else
    auth:sendHook('<@' ..getDiscordID().. '> executed Harvest script, does not have access.')
end
]]