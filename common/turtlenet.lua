local logistics
if turtle ~= nil then logistics = require("logistics") end

local turtlenet = {}
turtlenet.previous_message = {}

-- (function) send(recieverID, message, [protocol]): nil
-- uses rednet.send but with a delay in front
function turtlenet.send(id, message, protocol)
    os.sleep(0.1)

    if turtle ~= nil then
        logistics.equip_item("computercraft:wireless_modem_advanced")
    end

    turtlenet.previous_message = {
        id = id,
        message = message,
        protocol = protocol
    }

    rednet.send(id, message, protocol)
end

-- resend previous sent message to same recepient
function turtlenet.resend()
    if turtlenet.previous_message.id == nil then return end

    os.sleep(0.1)

    if turtle ~= nil then
        logistics.equip_item("computercraft:wireless_modem_advanced")
    end

    rednet.send(turtlenet.previous_message.id,
                turtlenet.previous_message.message,
                turtlenet.previous_message.protocol)
end

return turtlenet
