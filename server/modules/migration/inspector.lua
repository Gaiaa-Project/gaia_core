--- Get the current database name.
---@return string|nil name The database name or nil.
function _GaiaInternal.GetDatabaseName()
    local result <const> = MySQL.scalar.await('SELECT DATABASE()')
    return result
end

--- Get existing table names in a database.
---@param database string The database name.
---@return table tableNames A list of table name strings.
local function getExistingTables(database)
    local rows <const> = MySQL.query.await('SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = ?', { database })
    local result <const> = {}
    for i = 1, #rows do
        result[i] = rows[i].TABLE_NAME
    end
    return result
end

--- Get existing column names for a table.
---@param database string The database name.
---@param tableName string The table name.
---@return table columnNames A list of column name strings.
local function getExistingColumns(database, tableName)
    local rows <const> = MySQL.query.await('SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?', { database, tableName })
    local result <const> = {}
    for i = 1, #rows do
        result[i] = rows[i].COLUMN_NAME
    end
    return result
end

--- Get existing foreign key constraint names for a table.
---@param database string The database name.
---@param tableName string The table name.
---@return table constraintNames A list of constraint name strings.
local function getExistingForeignKeys(database, tableName)
    local rows <const> = MySQL.query.await('SELECT CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND CONSTRAINT_TYPE = ?', { database, tableName, 'FOREIGN KEY' })
    local result <const> = {}
    for i = 1, #rows do
        result[i] = rows[i].CONSTRAINT_NAME
    end
    return result
end

--- Check if a value exists in an array.
---@param arr table The array to search.
---@param value any The value to find.
---@return boolean found Whether the value was found.
local function arrayContains(arr, value)
    for i = 1, #arr do
        if arr[i] == value then return true end
    end
    return false
end

--- Get schema table names that already exist in the database.
---@param database string The database name.
---@param schemaTables table The schema table definitions.
---@return table matchingNames A list of existing table names.
function _GaiaInternal.GetMatchingTables(database, schemaTables)
    local existing <const> = getExistingTables(database)
    local result <const> = {}
    for i = 1, #schemaTables do
        if arrayContains(existing, schemaTables[i].name) then
            result[#result + 1] = schemaTables[i].name
        end
    end
    return result
end

--- Inspect the database and find missing tables, columns, and foreign keys.
---@param database string The database name.
---@param tables table The schema table definitions.
---@return table missing { tables = {}, columns = {}, foreignKeys = {} }.
function _GaiaInternal.InspectSchema(database, tables)
    local existing <const> = getExistingTables(database)

    local missing <const> = {
        tables = {},
        columns = {},
        foreignKeys = {},
    }

    for i = 1, #tables do
        local tableDef <const> = tables[i]

        if not arrayContains(existing, tableDef.name) then
            missing.tables[#missing.tables + 1] = tableDef

            if tableDef.foreignKeys and #tableDef.foreignKeys > 0 then
                missing.foreignKeys[#missing.foreignKeys + 1] = {
                    tableName = tableDef.name,
                    foreignKeys = tableDef.foreignKeys,
                }
            end
        else
            local existingCols <const> = getExistingColumns(database, tableDef.name)
            local missingCols <const> = {}
            for j = 1, #tableDef.columns do
                if not arrayContains(existingCols, tableDef.columns[j].name) then
                    missingCols[#missingCols + 1] = tableDef.columns[j]
                end
            end
            if #missingCols > 0 then
                missing.columns[#missing.columns + 1] = {
                    tableName = tableDef.name,
                    columns = missingCols,
                }
            end

            if tableDef.foreignKeys and #tableDef.foreignKeys > 0 then
                local existingFKs <const> = getExistingForeignKeys(database, tableDef.name)
                local missingFKs <const> = {}
                for j = 1, #tableDef.foreignKeys do
                    local constraintName <const> = ('fk_%s_%s'):format(tableDef.name, tableDef.foreignKeys[j].column)
                    if not arrayContains(existingFKs, constraintName) then
                        missingFKs[#missingFKs + 1] = tableDef.foreignKeys[j]
                    end
                end
                if #missingFKs > 0 then
                    missing.foreignKeys[#missing.foreignKeys + 1] = {
                        tableName = tableDef.name,
                        foreignKeys = missingFKs,
                    }
                end
            end
        end
    end

    return missing
end
