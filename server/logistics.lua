local turtlenet = require("turtlenet")
local util = require("util")

local logistics = {}

-- list of all blocks discovered by turtles
-- indexed by textutils.serialise(pos, {compact = true})
-- value is just the block's name
logistics.map = {}

-- dictionary of turtles indexed by their ids
-- turtles have this structure
-- turtles[id] = {
--     pos = {x, y, z}
--     rot = 0 or 90 or 180 or 270
--     task = "task name" or "none"
--     label = "Computer Name" or ("Computer " .. id)
-- }
logistics.turtles = {}

-- list of turtles that need help by id
-- value is pos table
logistics.need_help = {}

-- list of areas that have been scanned
-- each scan scans a 17x17x17 area
-- each scan is performed on a coordinate multiple of 16
-- y area -3 -> 4 inclusive
-- x, z area expanding from 0
logistics.scanned_areas = {}
-- distance that has already been scanned in the x/y directions (in a square shape)
logistics.scanned_distance = 0

-- register a turtle into the turtles dictionary
-- gets position and label rotation as well
-- returns success value (true/false)
function logistics.register(id, label)
    print(id .. " connected")

    if label == nil then label = "Computer " .. id end
    logistics.turtles[id] = {
        pos = {0, 0, 0},
        rot = 0,
        task = "none",
        label = label,
        ping = 0
    }

    turtlenet.send(id, "turtle.pos", "info")
    _, logistics.turtles[id].pos = rednet.receive(tostring(id), 2)

    turtlenet.send(id, "turtle.rot", "info")
    _, logistics.turtles[id].rot = rednet.receive(tostring(id), 2)

    if logistics.turtles[id].pos == nil or logistics.turtles[id].rot == nil then
        logistics.unregister(id)
        return false
    end

    logistics.save()

    return true
end

-- unregister a turtle from the turtles dictionary
function logistics.unregister(id)
    print(id .. "unregistered")

    logistics.turtles[id] = nil

    return true
end

-- store block names in logistics.map
function logistics.blocks(blocks)
    local origin = blocks.turtle
    origin[1] = math.floor(origin[1] / 16)
    origin[2] = math.floor((origin[2] + 7) / 16)
    origin[3] = math.floor(origin[3] / 16)
    logistics.scanned_areas[textutils.serialise(origin, {compact = true})] =
        true
    blocks.turtle = nil

    for pos, block in pairs(blocks) do logistics.map[pos] = block end

    logistics.save()
end

-- remove blocks from logistics.map
function logistics.break_blocks(blocks)
    for b, block in ipairs(blocks) do
        logistics.map[textutils.serialise(block, {compact = true})] = nil
    end

    logistics.save()
end

-- get the amount of blocks mapped
function logistics.blockAmount() return util.keyAmount(logistics.map) end

-- get the amount of turtles registered
function logistics.turtleAmount() return util.keyAmount(logistics.turtles) end

-- saves stored data to files
function logistics.save()
    if fs.exists("blocks.dat") then
        fs.makeDir("old")
        fs.delete("old/blocks.dat")
        fs.move("blocks.dat", "old/blocks.dat")
    end
    if fs.exists("turtles.dat") then
        fs.makeDir("old")
        fs.delete("old/turtle.dat")
        fs.move("turtles.dat", "old/turtle.dat")
    end

    local blocks
    while blocks == nil do
        blocks = io.open("blocks.dat", "w")
        blocks:write(textutils.serialise({
            map = logistics.map,
            areas = logistics.scanned_areas
        }, {compact = true}))
    end

    local turtles
    while turtles == nil do
        turtles = io.open("turtles.dat", "w")
        turtles:write(textutils.serialise(logistics.turtles, {compact = true}))
    end
end

-- loads stored data from a file
function logistics.load()
    local blocks = io.open("blocks.dat", "r")
    if blocks ~= nil then
        local data = textutils.unserialise(blocks:read("a"))
        logistics.map = data.map
        logistics.scanned_areas = data.areas

        print("Loaded " .. logistics.blockAmount() .. " blocks!")
    else
        print("Cannot load blocks.dat, it doesn't exist")
    end

    local turtles = io.open("turtles.dat", "r")
    if turtles ~= nil then
        local data = textutils.unserialise(turtles:read("a"))
        logistics.turtles = data

        print("Loaded " .. logistics.turtleAmount() .. " turtles!")
    else
        print("Cannot load turtles.dat, it doesn't exist")
    end
end

-- get the first turtle where its task is "none"
function logistics.getFreeTurtle()
    for id, turtle in pairs(logistics.turtles) do
        if turtle.task == "none" then return id, turtle end
    end

    return false
end

-- free a turtle by id with a reason
function logistics.free(id, reason)
    logistics.turtles[id].task = "none"
    if logistics.need_help[id] ~= nil then
        print(id .. " reconnected")
        logistics.need_help[id] = nil
    end
end

-- mine the available ores
-- returns true if there are available turtles left over
function logistics.mineOres()
    for pos, block in pairs(logistics.map) do
        local id, turtle = logistics.getFreeTurtle()
        if not id then return false end

        local p = textutils.unserialise(pos)

        turtle.task = "goto"
        turtle.description = p[1] .. ", " .. p[2] .. ", " .. p[3]
        turtlenet.send(id, p, "goto")
    end

    return true
end

-- scan the next area
function logistics.scanNextArea()
    local id, turtle = logistics.getFreeTurtle()
    if not id then return false end

    local scan_pos = logistics.getNextScanArea()
    scan_pos[1] = scan_pos[1] * 16
    scan_pos[2] = scan_pos[2] * 16 - 7
    scan_pos[3] = scan_pos[3] * 16

    turtle.task = "scan"
    turtle.description = scan_pos[1] .. ", " .. scan_pos[2] .. ", " ..
                             scan_pos[3]

    turtlenet.send(id, {scan_pos[1], scan_pos[2], scan_pos[3]}, "scan")

    return true
end

-- get the next area to scan in a counter-clockwise manner
function logistics.getNextScanArea()
    local scan_pos = {0, -3, 0}

    if logistics.getNextVerticalScanArea(scan_pos) then return scan_pos end

    while true do
        scan_pos[3] = logistics.scanned_distance

        while scan_pos[1] < logistics.scanned_distance do
            if logistics.getNextVerticalScanArea(scan_pos) then
                return scan_pos
            end

            scan_pos[1] = scan_pos[1] + 1
        end

        while scan_pos[3] > -logistics.scanned_distance do
            if logistics.getNextVerticalScanArea(scan_pos) then
                return scan_pos
            end

            scan_pos[3] = scan_pos[3] - 1
        end

        while scan_pos[1] > -logistics.scanned_distance do
            if logistics.getNextVerticalScanArea(scan_pos) then
                return scan_pos
            end

            scan_pos[1] = scan_pos[1] - 1
        end

        while scan_pos[3] < logistics.scanned_distance do
            if logistics.getNextVerticalScanArea(scan_pos) then
                return scan_pos
            end

            scan_pos[3] = scan_pos[3] + 1
        end

        while scan_pos[1] < 0 do
            if logistics.getNextVerticalScanArea(scan_pos) then
                return scan_pos
            end

            scan_pos[1] = scan_pos[1] + 1
        end

        logistics.scanned_distance = logistics.scanned_distance + 1
    end
end

function logistics.getNextVerticalScanArea(pos)
    for y = -3, 4 do
        pos[2] = y
        if not logistics.scanned_areas[textutils.serialise(pos, {compact = true})] then
            return pos
        end
    end

    return false
end

logistics.load()

return logistics
