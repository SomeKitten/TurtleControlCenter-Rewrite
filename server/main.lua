local logistics = require("logistics")
local util = require("util")
local turtlenet = require("turtlenet")

peripheral.find("modem", rednet.open)
local ar = peripheral.find("arController")
ar.clear()

-- if gui scale is 3, then the screen is 1600 x 900
ar.setRelativeMode(true, 1600 * 3, 900 * 3)
local WIDTH = 1600
local HEIGHT = 900

local prev_need_help = 0
while true do
    local id, message, protocol = rednet.receive(nil, 0.2)

    if protocol ~= nil then print(os.time(), protocol) end

    -- if the message is from a new turtle, register it
    if id ~= nil and logistics.turtles[id] == nil or protocol == "register" then
        logistics.register(id, message)
    end

    if protocol == "blocks" then
        logistics.blocks(message)
        logistics.turtles[id].task = "none"
        logistics.turtles[id].pos = message.turtle
    end

    if protocol == "free" then logistics.free(id, message) end

    if protocol == "break" then
        logistics.break_blocks(message)
        logistics.turtles[id].task = "none"
        logistics.turtles[id].pos = message.turtle
    end

    if logistics.blockAmount() == 0 then
        logistics.scanNextArea()
    else
        logistics.mineOres()
    end

    if protocol == "HELP!" then
        if logistics.turtles[id] ~= nil then
            logistics.turtles[id].description = logistics.turtles[id].task
            logistics.turtles[id].task = "HELP!"
        end
        logistics.need_help[id] = {
            pos = message,
            task = "HELP!",
            description = "disconnected"
        }
    end

    if util.keyAmount(logistics.need_help) ~= prev_need_help then
        prev_need_help = util.keyAmount(logistics.need_help)

        ar.clear()

        if util.keyAmount(logistics.need_help) > 0 then
            ar.fill(WIDTH - 550, HEIGHT / 2, WIDTH, HEIGHT, 0xc5c66c)
            ar.fill(WIDTH - 550 + 25, HEIGHT / 2 + 25, WIDTH - 25, HEIGHT - 25,
                    0x111111)

            local line_count = 0
            for id, turtle in pairs(logistics.need_help) do
                ar.drawString("Turtle at " .. turtle.pos[1] .. ", " ..
                                  turtle.pos[2] .. ", " .. turtle.pos[3] ..
                                  " needs help!", WIDTH - 550 + 30,
                              HEIGHT / 2 + 30, 0xffffff)
                line_count = line_count + 1
            end
        end
    end

    for id, turtle in pairs(logistics.turtles) do
        if turtle.ping == 3 then
            turtle.task = "disconnected"
            print(id .. " disconnected")
        end

        if turtle.task ~= "none" then
            turtlenet.send(id, "ping", "ping")
            turtle.ping = turtle.ping + 1
            break
        end
    end

    rednet.broadcast({turtles = logistics.turtles}, "client_info")
end
