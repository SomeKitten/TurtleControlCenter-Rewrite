local util = {}

-- turns a table's values into a set of keys with all of them having a value of true
-- returns a new table
function util.tableToSet(t)
    local t1 = {}

    for _, v in pairs(t) do t1[v] = true end

    return t1
end

-- turns a string value
-- into its corresponding global variable
function util.stringToVar(s)
    local t = _G
    local index = string.find(s, ".", 1, true)

    while index ~= nil do
        t = t[string.sub(s, 1, index - 1)]
        s = string.sub(s, index + 1)
        index = string.find(s, ".", 1, true)
    end

    return t[s]
end

-- check if a string ends with another string
function util.endsWith(str, ending)
    return ending == "" or string.sub(str, -#ending) == ending
end

-- gets the amount of keys in a table
function util.keyAmount(t)
    local count = 0
    for _, _ in pairs(t) do count = count + 1 end
    return count
end

return util
