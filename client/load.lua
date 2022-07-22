-- wget run http://localhost:8000/client/load.lua
-- loads all required files into the client
fs.delete("/MineClient")
fs.makeDir("/MineClient")

shell.setDir("/MineClient")

local files = {"main"}
for f, file in ipairs(files) do
    shell.run("wget", "http://localhost:8000/client/" .. file .. ".lua")
end

local common_files = {"util", "turtlenet"}
for f, file in ipairs(common_files) do
    shell.run("wget", "http://localhost:8000/common/" .. file .. ".lua")
end

shell.run("./main")
