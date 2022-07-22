peripheral.find("modem", rednet.open)

local width, height = term.getSize()

while true do
    local id, message, protocol = rednet.receive(nil, 2)

    if protocol == "client_info" then
        term.clear()

        term.setCursorPos(1, 1)
        for id, turtle in pairs(message.turtles) do
            print("Turtle " .. id .. ":\n  " .. turtle.pos[1] .. ", " ..
                      turtle.pos[2] .. ", " .. turtle.pos[3] .. "\n   -> " ..
                      turtle.description)
            print("-- " .. turtle.task)

            print("\n")
        end
    end
end
