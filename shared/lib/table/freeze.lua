--- Freeze a table (make it read-only). Any attempt to modify will throw an error.
---@param tbl table The table to freeze.
---@return table frozen The frozen table.
function Gaia.table.freeze(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function()
            Gaia.print.error('Cannot modify a frozen table')
        end,
        __len = function()
            return #tbl
        end,
        __pairs = function()
            return pairs(tbl)
        end,
        __ipairs = function()
            return ipairs(tbl)
        end,
        __metatable = 'frozen',
    })
end

--- Check if a table is frozen.
---@param tbl table The table to check.
---@return boolean frozen Whether the table is frozen.
function Gaia.table.isFrozen(tbl)
    return getmetatable(tbl) == 'frozen'
end
