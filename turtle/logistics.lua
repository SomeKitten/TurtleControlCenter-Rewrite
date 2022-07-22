local util = require("util")

local logistics = {}

-- equip item and keep track of what it is
-- return the equipped item's name if successful
-- return false if failed
function logistics.equip(side)
    if side == nil then side = "right" end

    local data = turtle.getItemDetail()
    if not turtle.equip(side) then return false end

    if data then
        turtle["equipped_" .. side] = data.name
    else
        turtle["equipped_" .. side] = false
        return ""
    end

    return turtle["equipped_" .. side]
end

-- equip item based on its name
-- uses logistics.equip internally
-- returns true if the item is found and can be equipped
-- returns false if unsuccessful
function logistics.equip_item(name)
    -- if item not equipped
    if turtle.equipped_right ~= name then
        -- if cannot select item
        if not logistics.select(name) then
            -- select nothing
            local selected = logistics.select()

            -- if cannot select
            -- (test if item is already equipped)
            -- or cannot unequip
            -- or unequipped nothing
            -- or unequipped wrong item
            if not selected or not logistics.equip() or turtle.getItemCount() ==
                0 or turtle.getItemDetail().name ~= name then

                print("Cannot equip " .. name)
                return false
            end
        end

        logistics.equip()
    end

    if name == "computercraft:wireless_modem_advanced" then
        peripheral.find("modem", rednet.open)
    end

    return true
end

-- refuel if needed
-- return true if the turtle has fuel left
-- return false if the turtle has no fuel left
function logistics.refuel()
    while turtle.getFuelLevel() < turtle.getFuelLimit() / 90 do
        if not logistics.select("minecraft:coal") then
            print("Low on coal")
            break
        end

        turtle.refuel(1)
    end

    if turtle.getFuelLevel == 0 then return false end

    return true
end

-- select the slot of an item based on its name
-- no arguments selects an empty slot
-- return the item slot if the item is found
-- return false if the item is not found
function logistics.select(item_name)
    local item_slot = logistics.find(item_name)
    if not item_slot then return false end

    turtle.select(item_slot)
    return item_slot
end

-- find an item's slot based on its full name (namespace:item_name)
-- no arguments finds an empty slot
-- returns the item's slot or false if it cannot find that item
function logistics.find(item_name)
    for i = 1, 16 do
        if item_name == nil then
            if turtle.getItemDetail(i) == nil then return i end
        else
            if turtle.getItemDetail(i) ~= nil and turtle.getItemDetail(i).name ==
                item_name then return i end
        end
    end

    return false
end

-- scan if possible and return ores
-- return false if scan is not possible
function logistics.scan()
    if not logistics.equip_item("advancedperipherals:geo_scanner") then
        return false
    end

    local geo = peripheral.find("geoScanner")

    local data = geo.scan(8)
    while data == nil do data = geo.scan(8) end

    local ores = {}

    for b, block in ipairs(data) do
        for _, tag in ipairs(block.tags) do
            if util.endsWith(tag, "forge:ores]") then
                ores[textutils.serialise({
                    block.x + turtle.pos[1], block.y + turtle.pos[2],
                    block.z + turtle.pos[3]
                }, {compact = true})] = block.name
            end
        end
    end

    return ores
end

function logistics.locate()
    logistics.equip_item("computercraft:wireless_modem_advanced")
    return gps.locate()
end

return logistics
