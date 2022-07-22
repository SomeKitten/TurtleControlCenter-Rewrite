local util = require("util")
local logistics = require("logistics")

local movement = {}

-- blocks that the turtle won't be able to break
movement.break_blacklist = {
    "computercraft:turtle_normal", "computercraft:turtle_advanced",
    "computercraft:computer_normal", "computercraft:computer_advanced",
    "forbidden_arcanus:stella_arcanum"
}
movement.break_blacklist = util.tableToSet(movement.break_blacklist)

if turtle._DETECT_OLD == nil then turtle._DETECT_OLD = turtle.detect end
if turtle._INSPECT_OLD == nil then turtle._INSPECT_OLD = turtle.inspect end
if turtle._DIG_OLD == nil then turtle._DIG_OLD = turtle.dig end

-- move in a direction
function turtle.move(direction)
    if direction == nil or string.lower(direction) == "forward" then
        return turtle.forward()
    end
    if string.lower(direction) == "up" then return turtle.up() end
    if string.lower(direction) == "down" then return turtle.down() end
    error("Invalid direction!", 2)
end

-- detect in a direction
function turtle.detect(direction)
    if direction == nil or string.lower(direction) == "forward" then
        return turtle._DETECT_OLD()
    end
    if string.lower(direction) == "up" then return turtle.detectUp() end
    if string.lower(direction) == "down" then return turtle.detectDown() end
    error("Invalid direction!", 2)
end

-- inspect in a direction
function turtle.inspect(direction)
    if direction == nil or string.lower(direction) == "forward" then
        return turtle._INSPECT_OLD()
    end
    if string.lower(direction) == "up" then return turtle.inspectUp() end
    if string.lower(direction) == "down" then return turtle.inspectDown() end
    error("Invalid direction!", 2)
end

-- dig in a direction
function turtle.dig(direction)
    if direction == nil or string.lower(direction) == "forward" then
        return turtle._DIG_OLD()
    end
    if string.lower(direction) == "up" then return turtle.digUp() end
    if string.lower(direction) == "down" then return turtle.digDown() end
    error("Invalid direction!", 2)
end

-- equip the selected item
function turtle.equip(side)
    if side == nil or string.lower(side) == "right" then
        return turtle.equipRight()
    end
    if string.lower(side) == "left" then return turtle.equipLeft() end
    error("Invalid side!", 2)
end

-- calibrate current position and rotation using GPS
-- reset other cache variables
function movement.reset()
    turtle.pos = {}
    turtle.rot = 0
    turtle.equipped_right = false
    turtle.equipped_left = false

    turtle.pos[1], turtle.pos[2], turtle.pos[3] = logistics.locate()
    local x, y, z = turtle.pos[1], turtle.pos[2], turtle.pos[3]

    -- move forward and determine rotation
    while not movement.move() do
        x, y, z = logistics.locate()

        -- try other directions
        -- if no direction works, move up and try again
        turtle.turnRight()
        if movement.move() then break end

        turtle.turnRight()
        if movement.move() then break end

        turtle.turnRight()
        if movement.move() then break end

        turtle.turnRight()

        if not movement.move("up") then return false end
    end

    if turtle.pos[3] > z then turtle.rot = 0 end
    if turtle.pos[1] < x then turtle.rot = 90 end
    if turtle.pos[3] < z then turtle.rot = 180 end
    if turtle.pos[1] > x then turtle.rot = 270 end

    return true
end

-- move to a position
-- uses movement.move internally
-- returns positions moved through
function movement.moveTo(pos)
    local positions = {}
    table.insert(positions, {pos[1], pos[2], pos[3]})

    while true do
        local loop_pos = {turtle.pos[1], turtle.pos[2], turtle.pos[3]}

        while turtle.pos[2] ~= pos[2] do
            if turtle.pos[2] < pos[2] then
                if not movement.move("up") then break end
            else
                if not movement.move("down") then break end
            end
            table.insert(positions, {pos[1], pos[2], pos[3]})
        end

        while turtle.pos[1] ~= pos[1] do
            if turtle.pos[1] < pos[1] then
                movement.face(270)
            else
                movement.face(90)
            end
            if not movement.move() then break end
            table.insert(positions, {pos[1], pos[2], pos[3]})
        end

        while turtle.pos[3] ~= pos[3] do
            if turtle.pos[3] < pos[3] then
                movement.face(0)
            else
                movement.face(180)
            end
            if not movement.move() then break end
            table.insert(positions, {pos[1], pos[2], pos[3]})
        end

        -- if reached destination
        if turtle.pos[1] == pos[1] and turtle.pos[2] == pos[2] and turtle.pos[3] ==
            pos[3] then break end
        -- if no movement in current iteration
        if turtle.pos[1] == loop_pos[1] and turtle.pos[2] == loop_pos[2] and
            turtle.pos[3] == loop_pos[3] then break end
    end

    return positions
end

-- given a rotation of 0, 90, 180, or 270
-- turn to face that rotation
-- return true if a turn was made
-- return false if no turn was made
function movement.face(rot)
    local movement_angle = rot - turtle.rot

    if movement_angle == -180 or movement_angle == 180 then
        movement.turnRight()
        movement.turnRight()
        return true
    end
    if movement_angle == -90 or movement_angle == 270 then
        movement.turnLeft()
        return true
    end
    if movement_angle == -270 or movement_angle == 90 then
        movement.turnRight()
        return true
    end

    return false
end

-- turn the turtle and keep track of rotation
function movement.turnRight()
    turtle.turnRight()

    turtle.rot = turtle.rot + 90

    if turtle.rot == 360 then turtle.rot = 0 end
end

-- turn the turtle and keep track of rotation
function movement.turnLeft()
    turtle.turnLeft()

    turtle.rot = turtle.rot - 90

    if turtle.rot == -90 then turtle.rot = 270 end
end

-- movement that removes obstructions and refuels as needed
-- returns true if movement is successful or false if not
function movement.move(direction)
    -- if no room left
    if turtle.getItemCount(16) > 0 then return false end

    if direction == nil then direction = "forward" end

    while not turtle.move(direction) do
        while turtle.detect(direction) do
            if not movement.dig(direction) then return false end
        end
        if not logistics.refuel() then return false end
    end

    turtle.pos[1], turtle.pos[2], turtle.pos[3] = logistics.locate()

    return true
end

-- safe dig, won't break blacklisted blocks
-- returns the name of the broken block or false if cannot find a diamond pickaxe or break the block
function movement.dig(direction)
    -- if no room left
    if turtle.getItemCount(16) > 0 then return false end

    if direction == nil then direction = "forward" end

    logistics.equip_item("minecraft:diamond_pickaxe")

    local has_block, data = turtle.inspect(direction)

    if has_block then
        if not movement.break_blacklist[data.name] then
            turtle.select(1)
            turtle.dig(direction)
            return data.name
        end
    end

    return false
end

return movement
