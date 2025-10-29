--           LUALOOT by Syzygy aka Thickbrick           --
-- inspired by Bruise Lee aka Warriduh aka Handjabs's turboloot --

--   USER SET VARIABLES   --
-- how big the radius is that you want to loot in
local lootradius = 300
-- the minimum value trash needs to be if it's to be looted
local minlootvalue = 1000
-- whether or not to only loot trash that can stack
local stackableOnly = true
-- do you want to loot spells you don't know yet
local lootspells = true
-- where you want your character to do the talky things
local outputchannel = '/rsay'
-- this can also be passed in as a flag when you run the script but you can change the default here
local lootusable = false
-- END USER SET VARIABLES --

--[[
TODO :
- Fix Spell Looting
- Announce items with corpse ID
  - possibly list characters who need?
]]
local mq = require('mq')
local PackageMan = require('mq/PackageMan')
local cjson = PackageMan.Require('lua-cjson', 'cjson')

-- get the path to the loot file, this will be relative to the path of the script
local path = debug.getinfo(1).source
local filename = path:match("^.+[/\\](.+)$")
local localPath = path:sub(2, #path - filename:len())
local lootfile = localPath .. '\\loot.json'

-- get the file contents
local file = io.open(lootfile)
if file == nil then
    error('loot file not found!')
end
local content = file:read("*all");
file:close();
local loottable = cjson.decode(content);

-- set up the arg flags
local args = { ... }
local isBot = false
local printLoot = false
local lootArgs = {}
-- initalize the table of actual things that will be looted
local stuff_i_need = {}
-- debugging
local debug = false

local function dprint(message)
    if debug then
        print(message)
    end
end

-- process passed in args
for i, v in ipairs(args) do
    if v == 'bot' then
        isBot = true;
    elseif v == 'list' then
        printLoot = true;
    elseif v == 'lootusable' then
        lootusable = true
    elseif v == 'debug' then
        debug = true
    else
        lootArgs[v] = true
    end
end

-- adds an item to the loot table, OVERWRITING any previous values
local function addStuffToLoot(loot)
    if type(loot) == 'string' then
        stuff_i_need[loot] = -1
    elseif type(loot) == 'table' then
        -- If it's an array of objects (e.g. { {item1=2}, {item2=3}     })
        if #loot > 0 then
            for _, entry in ipairs(loot) do
                if type(entry) == 'string' then
                    stuff_i_need[entry] = -1
                elseif type(entry) == 'table' then
                    for nameOrId, maxToLoot in pairs(entry) do
                        stuff_i_need[nameOrId] = maxToLoot
                    end
                end
            end
        else
            -- Single object: {item1=2, item2=3}
            for nameOrId, maxToLoot in pairs(loot) do
                stuff_i_need[nameOrId] = maxToLoot
            end
        end
    end
end

local function stuff_i_have(item)
    local itemCount = mq.TLO.FindItemCount(item);
    dprint('itemcount ' .. itemCount())
    local itemInBankCount = mq.TLO.FindItemBankCount(item);
    dprint('bankcount ' .. itemInBankCount())
    return (itemCount() + itemInBankCount())
end

---@param item MQItem
local function shouldiloot(item)
    -- is it on the loot list?
    if stuff_i_need[item.Name()] or stuff_i_need[item.ID()] ~= nil then
        dprint(stuff_i_have(item.Name()))
        -- is it lore and do I already have one?
        if item.Lore() == true then
            if (stuff_i_have(item.Name()) < 1 or stuff_i_have(item.ID()) < 1) then
                -- I don't have one, loot it
                dprint('It is a lore item that I dont have, Im looting it. This should return TRUE.')
                return true
            else
                dprint('It is a lore item that I have, Im not looting it. This should return FALSE.')
                return false
            end
        end
        -- does this item have a maximum limit?
        dprint(stuff_i_need[item.Name()])
        if stuff_i_need[item.Name()] == -1 then
            dprint('Im not at my limit for this item, which doesnt have a specific limit. This should return TRUE.')
            return true
            -- if it does have a limit, am I at the cap?
        elseif stuff_i_need[item.Name()] < stuff_i_have(item.Name()) then
            dprint('Im at my limit for this type of item, which has a specific cap. This should return FALSE.')
            return false
            -- if how many I have is less than how many I need, loot it
        elseif stuff_i_have(item.Name()) < stuff_i_need[item.Name()] then
            dprint('Im not at my limit for this item, which has a specific limit. This should return TRUE.')
            return true
        else
            dprint('Im at my limit for this type of item. This should return FALSE.')
            return false
        end
        -- if it's not on the loot list, should I be checking for equippable items?
    elseif lootusable == true then
        if item.CanUse and item.WornSlots() > 0 and (stuff_i_have(item.Name() == 0) or stuff_i_have(item.ID() == 0)) then
            return true
        end
        -- is it a spell I need?
    elseif lootspells and item.Scroll then
        if item.CanUse and mq.TLO.Me.Book(item.Scroll) == 'NULL' then
            return true
        end
    elseif item.Value() >= minlootvalue and isBot == false then
        -- if it is valuable, do I want to loot non stackable items?
        if item.Stackable() == false and stackableOnly == true then
            dprint('This item is valuable, but does not stack, and stackableOnly is true. This should return FALSE.')
            return false
        else
            dprint('This item is stackable, and I should loot it. This should return TRUE.')
            return true
        end
    end
    dprint('This item did not match anything on the shouldLoot list. This should return FALSE.')
    return false
end

local function doneLootingCorpse()
    mq.cmd('/notify LootWnd DoneButton leftmouseup')
    mq.delay(3)
end

--[[
    Loot decision priority -
    1. Character
    2. Zone (tags in a zone OVERWRITE top level tags)
    3. Tags
    4. Main
]]
if loottable["main"] and not isBot then
    addStuffToLoot(loottable["main"])
end

if loottable["tags"] then
    local tags = loottable["tags"]
    for tag, taglist in pairs(tags) do
        if (lootArgs[tag]) then
            addStuffToLoot(taglist)
        end
    end
end

if loottable["zones"] then
    local zones = loottable["zones"]
    for zone in pairs(zones) do
        if zone == mq.TLO.Zone.ShortName() then
            local zoneLoot = zones[zone]
            for lootSection, items in pairs(zoneLoot) do
                if (lootSection == 'main' and not isBot) or (lootArgs[lootSection]) then
                    addStuffToLoot(items)
                end
            end
            break
        end
    end
end

if loottable["characters"] then
    if loottable["characters"][mq.TLO.Me.Name()] then
        local character = loottable["characters"][mq.TLO.Me.Name()]
        addStuffToLoot(character)
    end
end

if loottable["classes"] then
    if loottable["classes"][mq.TLO.Me.Class.ShortName():lower()] then
        local class = loottable["classes"][mq.TLO.Me.Class.ShortName():lower()]
        addStuffToLoot(class)
    end
end

if printLoot then
    for k, v in pairs(stuff_i_need) do
        if v > 0 then
            print('I need to loot ' .. k .. ', but ONLY ' .. v .. ' of them.')
        elseif v == -1 then
            print('I need to loot ALL the ' .. k .. '!')
        end
    end
    mq.exit()
end

mq.cmd('/hidecorpse looted')
mq.cmd('/say #corpsefix')

while true do
    -- check inventory space
    if mq.TLO.Me.FreeInventory() == false then
        mq.cmdf('%s I can\'t loot anything, my inventory is full!', outputchannel)
        break
    end
    -- check for any corpses
    mq.delay(5)
    mq.cmd('/target npccorpse')
    if mq.TLO.Target() == nil then
        mq.cmdf('%s Done looting, no more corpses.', outputchannel)
        break
    end
    -- check for corpses in radius
    if mq.TLO.Target.ID() and mq.TLO.Target.Type() == 'Corpse' then
        if mq.TLO.Target.Distance() > lootradius then
            mq.cmdf('%s Done looting, no more corpses in loot radius.', outputchannel)
            break
        end
    end
    -- navigate to corpse
    mq.cmd('/face fast')
    mq.cmdf('/moveto id %s', mq.TLO.Target.ID())
    while mq.TLO.Target() and mq.TLO.Target.Distance() > 10 and mq.TLO.Target.Distance() < lootradius do
        mq.delay(100)
    end
    if mq.TLO.Cursor.ID() then mq.cmd('/autoi') end
    mq.cmd('/loot')
    mq.delay(300)
    if mq.TLO.Corpse.Items() ~= nil then
        dprint('total loot ' .. mq.TLO.Corpse.Items())
        for i = 1, mq.TLO.Corpse.Items() do
            dprint('item number ' .. i)
            local item = mq.TLO.Corpse.Item(i)
            dprint('item name ' .. item.Name())
            -- is it on the loot list?
            if (shouldiloot(item)) then
                dprint('match! I should loot ' .. item.Name())
                mq.cmdf('/ctrl /itemnotify loot%d rightmouseup', i)
                mq.doevents()
                mq.delay(120)
                if mq.TLO.Window("ConfirmDialogBox") then
                    mq.cmd('/notify ConfirmationDialogBox CD_Yes_Button leftmouseup')
                    mq.doevents()
                    mq.delay(120)
                end
            end
            mq.doevents()
            mq.delay(120)
        end
    end
    doneLootingCorpse()
end
