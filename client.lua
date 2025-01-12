local client = {
    is_accessed = nil,
    dialog_string = nil,
    moveTo = function(self, x, y, check_only)
        local queue = {}
        local visited = {}
        -- Checks if tile is open to public or self is an admin/owner in the world.
        local function check_access(x, y)
            if checkTile(x, y).getFlags.public then return true end
            if self.is_accessed == nil then
                local tiles = getTile()
                local tile
                for i = 0, #tiles do
                    tile = tiles[i]
                    if tile.fg == 242 or tile.fg == 9640 or tile.fg == 1796 or tile.fg == 4802 or tile.fg == 2408 then
                        local extra = getExtraTile(tile.pos.x, tile.pos.y)
                        if extra.owner == getLocal().userId then self.is_accessed = true end
                        pcall(function()
                            for _, admin in pairs(extra.adminList) do
                                if admin == getLocal().userId then self.is_accessed = true end
                            end
                        end)
                    end
                end
                if self.is_accessed then
                    logToConsole('`9[ Nyoho ] `6Player has access to world.')
                else
                    logToConsole('`9[ Nyoho ] `6Player does not have access to world.')
                    self.is_accessed = false
                end
            end
            return self.is_accessed
        end
        -- Checks  if tile is not solid and doesn't behave like a platform then checks if tile is an entrance block then check if it is passable.
        local function check_nodes(curr_info, last_tile, end_tile)
            local curr_tile = checkTile(curr_info[1], curr_info[2])
            if curr_tile == nil then return end
            if curr_tile.collisionType == 1 then return end
            if curr_tile.collisionType == 2 and getLocal().pos.y // 32 < curr_tile.pos.y then return end
            if curr_tile.collisionType == 3 and not check_access(curr_tile.pos.x, curr_tile.pos.y) then return end
            if curr_tile.collisionType == 4 and not curr_tile.getFlags.enabled then return end

            if visited[string.format('x-%s,y-%s', curr_tile.pos.x, curr_tile.pos.y)] ~= nil then return end
            visited[string.format('x-%s,y-%s', curr_tile.pos.x, curr_tile.pos.y)] = {last_tile[1], last_tile[2]}
            if curr_tile.pos.x == end_tile[1] and curr_tile.pos.y == end_tile[2] then
                return true
            else      
                for i = -1, 1, 2 do
                    local hor_tile, ver_tile
                    if curr_tile.pos.x + i >= 0 and curr_tile.pos.x + i <= 99 then hor_tile = checkTile(curr_tile.pos.x + i, curr_tile.pos.y) end
                    if curr_tile.pos.y + i >= 0 and curr_tile.pos.y + i <= 53 then ver_tile = checkTile(curr_tile.pos.x, curr_tile.pos.y + i) end
                    if hor_tile then table.insert(queue, {curr = {hor_tile.pos.x, hor_tile.pos.y}, last = {curr_tile.pos.x, curr_tile.pos.y}}) end
                    if ver_tile then table.insert(queue, {curr = {ver_tile.pos.x, ver_tile.pos.y}, last = {curr_tile.pos.x, curr_tile.pos.y}}) end
                end
            end 
        end
        local function get_path() 
            local end_tile = checkTile(x, y)
            if end_tile.collisionType ~= 0 then return end
            local start_tile = checkTile(getLocal().pos.x // 32, getLocal().pos.y // 32)
            table.insert(queue, {curr = {start_tile.pos.x, start_tile.pos.y}, last = {'0', '0'}})
            local path_found = false
            for curr_itr = 1, 49999 do
                local curr_info = table.remove(queue, 1)
                if check_nodes(curr_info.curr, curr_info.last, {end_tile.pos.x, end_tile.pos.y}) then path_found = true end
                if path_found then
                    return true
                end
                if #queue < 1 then return end
            end
        end
        local function reverse_table(curr_table)
            new_table = {}
            for i = #curr_table, 1, -1 do
                table.insert(new_table, curr_table[i])
            end
            return new_table
        end
        local function reverse_path()
            local reversed_path = {}
            local target_tile = checkTile(x, y)
            for k, v in pairs(visited) do
                if visited[string.format('x-%s,y-%s', target_tile.pos.x, target_tile.pos.y)] and visited[string.format('x-%s,y-%s', target_tile.pos.x, target_tile.pos.y)][1] ~= '0' then
                    if target_tile ~= nil then
                        table.insert(reversed_path, {target_tile.pos.x, target_tile.pos.y})
                    end
                    target_tile = checkTile(visited[string.format('x-%s,y-%s', target_tile.pos.x, target_tile.pos.y)][1], visited[string.format('x-%s,y-%s', target_tile.pos.x, target_tile.pos.y)][2])
                end
                sleep(1)
            end
            return reverse_table(reversed_path)
        end
        if get_path() then
            if check_only then return true end
            local positions = reverse_path()
            for _, pos in pairs (positions) do
                if not findPath(pos[1], pos[2]) then
                    logToConsole('`4[ Dojyaaan ] `6Could not path find to (' ..pos[1].. ', ' ..pos[2].. '). |' ..checkTile(pos[1], pos[2]).collisionType.. '|' ..tostring(checkTile(pos[1], pos[2]).isCollideable))
                    return 
                end
                sleep(50)
            end
            sleep(move_delay)
            return #positions
        else
            if check_only then return end
            logToConsole('`4[ Dojyaaan ] `6Could not create path to (' ..x.. ', ' ..y.. ').')
        end
    end,
    warpTo = function(self, target_world)
        local name = target_world:upper():match('(%w+)|')
        if name == nil then name = target_world end
    
        for i = 1, max_warp_attempt do
            if name ~= getWorld().name then
                logToConsole('`9[ Nyoho ] `6Warping to target world. #' ..i)
                sendPacket(2, 'action|join_request\nname|' ..target_world)
                sendPacket(3, 'action|join_request\nname|' ..target_world.. '\ninvitedWorld|0')
                sleep(warp_delay)
            else
                sleep(warp_delay)
                logToConsole('`2[ Mozarella ] `6Warped to target world.')
                self.is_accessed = nil
                return true
            end
        end
        while name ~= getWorld().name do
            logToConsole('`4[ Dojyaaan ] `6World is either nuked or you are lagging, and this loop will end once you successfully enter the world. If you want to, restart the app or terminate the script!')
            sleep(2500)
        end
    end,
    findItem = function(self, id)
        local items = getInventory()
        for i = 0, #items do
            local item = getInventory()[i]
            if item.id == id then
                return {id = item.id, amount = item.amount}
            end
        end
        return {id = id, amount = 0}
    end,
    dropItem = function(self, item, amount)
        self:initHook()
        for i = 1, max_drop_attempt do
            local curr_item = self:findItem(item.id)
            if curr_item.amount > 0 then
                logToConsole('`9[ Nyoho ] `6Dropping ' ..getItemByID(curr_item.id).name.. '. #' ..i)
                sendPacket(2, 'action|drop\n|itemID|' ..curr_item.id)
                while not self.dialog_string do sleep(500) end
                if self.dialog_string:find('drop_item') then
                    sendPacket(2, 'action|dialog_return\ndialog_name|drop_item\nitemID|' ..curr_item.id.. '|\ncount|' ..(amount or curr_item.amount))
                    while self:findItem(curr_item).amount == item.amount do sleep(500) end
                    sleep(drop_delay)
                    RemoveHook('main_hook')
                    return
                else
                    logToConsole('`4[ Dojyaaan ] `6Couldn\t drop item at target tile.')
                    self:moveTo(getLocal().pos.x // 32 + 1, getLocal().pos.y // 32)
                end
                self.dialog_string = nil
            else
                RemoveHook('main_hook')
                return
            end
        end
        while self:findItem(item.id).amount == item.amount do
            logToConsole('`4[ Dojyaaan ] `6Oh no! Script will resume once you successfully drop ' ..getItemByID(item.id).name.. '.') 
            sleep(2500)
        end
        RemoveHook('main_hook')
    end,
    dropItems = function(self, item_ids)
        local prev_pos = {getLocal().pos.x // 32, getLocal().pos.y // 32}
        for _, item_id in pairs(item_ids) do
            self:dropItem(self:findItem(item_id))
            self:moveTo(prev_pos[1], prev_pos[2])
        end
    end,
    trashItems = function(self)
        if #trash_filter == 0 then return end
        for _, id in pairs(trash_filter) do
            local item = self:findItem(id)
            if item.amount > 0 then
                sendPacket(2, 'action|trash\n|itemID|' ..item.id)
                sleep(1000)
                sendPacket(2, 'action|dialog_return\ndialog_name|trash_item\nitemID|' ..item.id.. '|\ncount|' ..item.amount)
                sleep(drop_delay)
            end
        end
    end,
    stockItem = function(self)
        local curr_tile = checkTile(getLocal().pos.x // 32, getLocal().pos.y // 32)
        local curr_inv = #getInventory()
        requestTileChange(curr_tile.pos.x, curr_tile.pos.y, 32)
        sleep(punch_delay)
        sendPacket(2, 'action|dialog_return\ndialog_name|vending\n|tilex|' ..curr_tile.pos.x.. '|\ntiley|' ..curr_tile.pos.y.. '|\nbuttonClicked|addstock\n\nsetprice|0\nchk_peritem|0\nchk_perlock|1')
        while #getInventory() == curr_inv do sleep(drop_delay) end
    end,
    stockItems = function(self, item_ids)
        for _, vend_data in pairs(vend_positions) do
            local x, y, id = table.unpack(vend_data)
            for _, item_id in pairs(item_ids) do
                if item_id == id then
                    self:moveTo(x, y)
                    self:stockItem()
                end
            end
        end
    end,
    storeItems = function(self)
        if #storage_filter == 0 then return end
        local items_to_store = {}
        for _, item_id in pairs(storage_filter) do
            local item = self:findItem(item_id)
            if item.amount > 100 then
                logToConsole('`6[ Nyoho ] Storing ' ..item.amount.. ' ' ..getItemByID(item.id).name.. '.')
                table.insert(items_to_store, item_id)
            end
        end
        if #items_to_store == 0 then return end
        if #storage_world > 0 then self:warpTo(storage_world) end
        if storage_method == 'vend' then
            self:stockItems(items_to_store)
        else
            self:moveTo(storage_position[1], storage_position[2])
            self:dropItems(items_to_store)
        end
        if #storage_world > 0 then self:warpTo(current_world) end
    end,
    collectInRange = function(self)
        pcall(function()
            local objects = getWorldObject()
            for i = 0, #objects do
                local obj = objects[i]
                if math.abs((obj.pos.x // 32) - (getLocal().pos.x // 32)) <= max_collect_range and math.abs((obj.pos.y // 32) - (getLocal().pos.y // 32)) <= max_collect_range then
                    if obj.amount < 20 then
                        sendPacketRaw(false, {
                            type = 11,
                            value = obj.oid,
                            x = obj.pos.x,
                            y = obj.pos.y
                        })
                        sleep(10)
                    end
                end
            end
        end)
    end,
    activateTile = function(self)
        sendPacketRaw(false, {
            type = 7,
            punchx = getLocal().pos.x // 32,
            punchy = getLocal().pos.y // 32
        })
    end,
    initHook = function(self)
        AddHook('OnVarlist', 'main_hook', function(var, netID)
            if var[0]:find('OnTextOverlay') then
                if var[1]:find('You can\'t drop that here,') then self.dialog_string = var[1] end
            end
            if var[0]:find('OnDialogRequest') then
                if var[1]:find('drop_item') then self.dialog_string = var[1] end
                if disable_dialog then return true end
            end
        end)
    end,
    debugTile = function(self, is_x, is_y)
        local x, y
        if is_x then x = is_x else x = getLocal().pos.x // 32 end
        if is_y then y = is_y else y = getLocal().pos.y // 32 end
        string = 'Flags:\n'
        for name, value in pairs(checkTile(x, y).getFlags) do
            string = string..name.. ' -> ' ..tostring(value).. '\n'
        end
        doLog(string)
    end,
}

return client