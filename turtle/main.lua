local movement = require("movement")
local util = require("util")
local turtlenet = require("turtlenet")
local logistics = require("logistics")

local id = os.getComputerID()
local label = os.getComputerLabel

print("Starting up!!!")

logistics.equip_item("computercraft:wireless_modem_advanced")

movement.reset()

peripheral.find("modem", rednet.open)

turtle.needs_help = false

local server_id
while true do
    local received_id, msg, protocol = rednet.receive(nil, 2)

    if protocol ~= nil then print(os.time(), protocol) end

    -- msg = var_name
    if protocol == "info" then
        print("Sending " .. msg)

        server_id = received_id

        local var = util.stringToVar(msg)

        turtlenet.send(received_id, var, tostring(id))
    end

    if not server_id then
        rednet.broadcast(label, "register")
    else
        -- msg = pos
        if protocol == "scan" then
            print("Scanning " .. msg[1] .. ", " .. msg[2] .. ", " .. msg[3] ..
                      "!")
            movement.moveTo({msg[1], msg[2], msg[3]})

            local ores = logistics.scan()

            ores.turtle = {turtle.pos[1], turtle.pos[2], turtle.pos[3]}

            if ores then turtlenet.send(server_id, ores, "blocks") end
        end

        -- msg = pos
        if protocol == "goto" then
            print("Going to " .. msg[1] .. ", " .. msg[2] .. ", " .. msg[3] ..
                      "!")
            local blocks_broken = movement.moveTo({msg[1], msg[2], msg[3]})

            blocks_broken.turtle = {turtle.pos[1], turtle.pos[2], turtle.pos[3]}

            turtlenet.send(server_id, blocks_broken, "break")
        end

        if protocol == "ping" then
            print("Pong!")

            turtlenet.resend()
        end

        -- if no room left
        if turtle.getItemCount(16) > 0 or turtle.getFuelLevel == 0 then
            print("HELP!")

            turtle.needs_help = true

            local x, y, z = logistics.locate()
            -- send distress signal
            turtlenet.send(server_id, {x, y, z}, "HELP!")
        elseif turtle.needs_help then
            turtlenet.send(server_id, "needed help", "free")

            turtle.needs_help = false
        end
    end

    logistics.equip_item("computercraft:wireless_modem_advanced")
end
