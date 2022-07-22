-- wget run http://localhost:8000/turtle/load.lua
-- loads all required files into the turtle
fs.delete("/MineTurtle")
fs.makeDir("/MineTurtle")

shell.setDir("/MineTurtle")

local files = {"main", "movement", "util", "logistics"}
for f, file in ipairs(files) do
    shell.run("wget", "http://localhost:8000/turtle/" .. file .. ".lua")
end

local common_files = {"util", "turtlenet"}
for f, file in ipairs(common_files) do
    shell.run("wget", "http://localhost:8000/common/" .. file .. ".lua")
end

shell.run("./main")
