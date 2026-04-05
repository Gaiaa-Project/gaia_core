local IDENTIFIER_REGEX <const> = '^[a-zA-Z_][a-zA-Z0-9_]*$'

--- Validate that an identifier is safe for SQL use.
---@param value string The identifier to validate.
---@param identifierType string The type of identifier for error messages.
local function validateIdentifier(value, identifierType)
    if not value:match(IDENTIFIER_REGEX) then
        Gaia.print.error(('Invalid %s identifier: \'%s\''):format(identifierType, value))
    end
end

--- Generate the SQL definition for a single column.
---@param col table The column definition.
---@return string sql The column SQL fragment.
local function generateColumnSQL(col)
    validateIdentifier(col.name, 'column')
    local parts <const> = { ('`%s`'):format(col.name), col.type }

    if col.unsigned then parts[#parts + 1] = 'UNSIGNED' end
    if col.notNull then parts[#parts + 1] = 'NOT NULL' end
    if col.autoIncrement then parts[#parts + 1] = 'AUTO_INCREMENT' end
    if col.unique then parts[#parts + 1] = 'UNIQUE' end

    if col.default ~= nil then
        local def <const> = tostring(col.default)
        local upper <const> = def:upper()

        if def == 'NULL' then
            parts[#parts + 1] = 'DEFAULT NULL'
        elseif upper:find('^CURRENT_TIMESTAMP') or upper == 'NOW()' then
            parts[#parts + 1] = 'DEFAULT ' .. def
        elseif type(col.default) == 'string' and def ~= 'NULL' then
            parts[#parts + 1] = ("DEFAULT '%s'"):format(def)
        else
            parts[#parts + 1] = 'DEFAULT ' .. def
        end
    end

    return table.concat(parts, ' ')
end

--- Generate a CREATE TABLE SQL statement from a table definition.
---@param tableDef table The table definition { name, columns, indexes?, foreignKeys? }.
---@return string sql The CREATE TABLE SQL statement.
function _GaiaInternal.GenerateCreateTableSQL(tableDef)
    validateIdentifier(tableDef.name, 'table')
    local lines <const> = {}

    for i = 1, #tableDef.columns do
        lines[#lines + 1] = generateColumnSQL(tableDef.columns[i])
    end

    local primaryKeys <const> = {}
    for i = 1, #tableDef.columns do
        if tableDef.columns[i].primaryKey then
            primaryKeys[#primaryKeys + 1] = ('`%s`'):format(tableDef.columns[i].name)
        end
    end
    if #primaryKeys > 0 then
        lines[#lines + 1] = ('PRIMARY KEY (%s)'):format(table.concat(primaryKeys, ', '))
    end

    if tableDef.indexes then
        for i = 1, #tableDef.indexes do
            local idx <const> = tableDef.indexes[i]
            local keyword <const> = idx.unique and 'UNIQUE KEY' or 'KEY'
            local cols <const> = {}
            for j = 1, #idx.columns do
                cols[j] = ('`%s`'):format(idx.columns[j])
            end
            lines[#lines + 1] = ('%s `%s` (%s)'):format(keyword, idx.name, table.concat(cols, ', '))
        end
    end

    return ('CREATE TABLE IF NOT EXISTS `%s` (\n  %s\n) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'):format(
        tableDef.name, table.concat(lines, ',\n  ')
    )
end

--- Generate an ALTER TABLE ADD COLUMN SQL statement.
---@param tableName string The table name.
---@param col table The column definition.
---@return string sql The ALTER TABLE SQL statement.
function _GaiaInternal.GenerateAddColumnSQL(tableName, col)
    validateIdentifier(tableName, 'table')
    return ('ALTER TABLE `%s` ADD COLUMN %s'):format(tableName, generateColumnSQL(col))
end

--- Generate an ALTER TABLE ADD FOREIGN KEY SQL statement.
---@param tableName string The table name.
---@param fk table The foreign key definition { column, references = { table, column }, onDelete?, onUpdate? }.
---@return string sql The ALTER TABLE SQL statement.
function _GaiaInternal.GenerateAddForeignKeySQL(tableName, fk)
    validateIdentifier(tableName, 'table')
    validateIdentifier(fk.column, 'column')
    validateIdentifier(fk.references.table, 'table')
    validateIdentifier(fk.references.column, 'column')

    local constraintName <const> = ('fk_%s_%s'):format(tableName, fk.column)
    local sql = ('ALTER TABLE `%s` ADD CONSTRAINT `%s` FOREIGN KEY (`%s`) REFERENCES `%s`(`%s`)'):format(
        tableName, constraintName, fk.column, fk.references.table, fk.references.column
    )

    if fk.onDelete then sql = sql .. ' ON DELETE ' .. fk.onDelete end
    if fk.onUpdate then sql = sql .. ' ON UPDATE ' .. fk.onUpdate end

    return sql
end
