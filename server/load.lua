-- wget run http://localhost:8000/server/load.lua
-- loads all required files into the server
fs.delete("/MineServer")
fs.makeDir("/MineServer")

shell.setDir("/MineServer")

local files = {"main", "logistics"}
for f, file in ipairs(files) do
    shell.run("wget", "http://localhost:8000/server/" .. file .. ".lua")
end

local common_files = {"util", "turtlenet"}
for f, file in ipairs(common_files) do
    shell.run("wget", "http://localhost:8000/common/" .. file .. ".lua")
end

shell.run("./main")
