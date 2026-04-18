Gaia.migration = {}

local MIGRATIONS_TABLE <const> = 'schema_migrations'

--- Ensure the schema_migrations tracking table exists.
local function ensureMigrationsTable()
    MySQL.query.await(([[
        CREATE TABLE IF NOT EXISTS `%s` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `resource` VARCHAR(255) NOT NULL,
            `version` VARCHAR(50) NOT NULL,
            `applied_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            UNIQUE KEY `idx_resource_version` (`resource`, `version`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]]):format(MIGRATIONS_TABLE))
end

--- Get the latest applied migration version for a resource.
---@param resourceName string The resource name.
---@return string|nil version The latest version or nil.
local function getLatestVersion(resourceName)
    return MySQL.scalar.await(
        ('SELECT version FROM `%s` WHERE resource = ? ORDER BY id DESC LIMIT 1'):format(MIGRATIONS_TABLE),
        { resourceName }
    )
end

--- Mark a migration version as applied for a resource.
---@param resourceName string The resource name.
---@param version string The version to record.
local function markVersionApplied(resourceName, version)
    MySQL.query.await(
        ('INSERT INTO `%s` (resource, version) VALUES (?, ?)'):format(MIGRATIONS_TABLE),
        { resourceName, version }
    )
end

--- Apply missing elements (tables, columns, foreign keys) and log each action.
---@param missing table The missing elements from InspectSchema.
---@return number count The total number of elements applied.
local function applyMissing(missing)
    local count = 0

    for i = 1, #missing.tables do
        local tableDef <const> = missing.tables[i]
        MySQL.query.await(_GaiaInternal.GenerateCreateTableSQL(tableDef))
        Gaia.print.success(('Created table `%s`'):format(tableDef.name))
        count = count + 1
    end

    for i = 1, #missing.columns do
        local entry <const> = missing.columns[i]
        for j = 1, #entry.columns do
            local col <const> = entry.columns[j]
            MySQL.query.await(_GaiaInternal.GenerateAddColumnSQL(entry.tableName, col))
            Gaia.print.success(('Added column `%s` to `%s`'):format(col.name, entry.tableName))
            count = count + 1
        end
    end

    for i = 1, #missing.foreignKeys do
        local entry <const> = missing.foreignKeys[i]
        for j = 1, #entry.foreignKeys do
            local fk <const> = entry.foreignKeys[j]
            MySQL.query.await(_GaiaInternal.GenerateAddForeignKeySQL(entry.tableName, fk))
            Gaia.print.success(('Added foreign key `%s` on `%s`'):format(fk.column, entry.tableName))
            count = count + 1
        end
    end

    return count
end

--- Validate that a migration config has the required structure.
---@param config table The migration config to validate.
---@param resourceName string The resource name for error messages.
---@return boolean valid Whether the config is valid.
local function validateConfig(config, resourceName)
    if type(config) ~= 'table' then
        Gaia.print.error(('[%s] Migration config must be a table, got %s'):format(resourceName, type(config)))
        return false
    end

    if config.enabled == nil then
        Gaia.print.error(('[%s] Migration config missing required field: enabled'):format(resourceName))
        return false
    end

    if type(config.schema) ~= 'table' then
        Gaia.print.error(('[%s] Migration config missing required field: schema (table expected, got %s)'):format(resourceName, type(config.schema)))
        return false
    end

    if type(config.schema.version) ~= 'string' or config.schema.version == '' then
        Gaia.print.error(('[%s] Migration schema missing required field: version (non-empty string expected)'):format(resourceName))
        return false
    end

    if type(config.schema.tables) ~= 'table' then
        Gaia.print.error(('[%s] Migration schema missing required field: tables (table expected, got %s)'):format(resourceName, type(config.schema.tables)))
        return false
    end

    for i = 1, #config.schema.tables do
        local tableDef <const> = config.schema.tables[i]

        if type(tableDef) ~= 'table' then
            Gaia.print.error(('[%s] Table definition at index %d must be a table'):format(resourceName, i))
            return false
        end

        if type(tableDef.name) ~= 'string' or tableDef.name == '' then
            Gaia.print.error(('[%s] Table definition at index %d missing required field: name'):format(resourceName, i))
            return false
        end

        if type(tableDef.columns) ~= 'table' or #tableDef.columns == 0 then
            Gaia.print.error(('[%s] Table \'%s\' must have at least one column'):format(resourceName, tableDef.name))
            return false
        end
    end

    return true
end

--- Run auto-migration for any resource.
--- Each resource manages its own schema independently.
---@param config table The migration config { enabled, detectMissing, schema = { version, tables } }.
function Gaia.migration.run(config)
    local resourceName <const> = GetCurrentResourceName()

    if not validateConfig(config, resourceName) then return end

    if not config.enabled then
        Gaia.print.warn(('[%s] Auto-migration disabled'):format(resourceName))
        return
    end

    local schema <const> = config.schema

    if #schema.tables == 0 then
        Gaia.print.warn(('[%s] No tables defined in schema — skipping'):format(resourceName))
        return
    end

    Gaia.print.info(('[%s] Auto-migration enabled'):format(resourceName))

    local database <const> = _GaiaInternal.GetDatabaseName()
    if not database then
        Gaia.print.warn(('[%s] Unable to determine database name — skipping'):format(resourceName))
        return
    end

    ensureMigrationsTable()

    local latestVersion <const> = getLatestVersion(resourceName)
    local isNewVersion <const> = latestVersion ~= schema.version

    if not isNewVersion then
        Gaia.print.info(('[%s] Version %s already applied'):format(resourceName, schema.version))

        if not config.detectMissing then
            return
        end

        local missing <const> = _GaiaInternal.InspectSchema(database, schema.tables)
        local totalMissing <const> = #missing.tables + #missing.columns + #missing.foreignKeys

        if totalMissing == 0 then
            Gaia.print.success(('[%s] All tables and columns OK'):format(resourceName))
            return
        end

        Gaia.print.warn(('[%s] %d missing element(s) detected — repairing...'):format(resourceName, totalMissing))
        local repaired <const> = applyMissing(missing)
        Gaia.print.success(('[%s] Repair complete — %d element(s) repaired'):format(resourceName, repaired))
        return
    end

    local versionInfo <const> = latestVersion
        and ('[%s] New version: %s (current: %s)'):format(resourceName, schema.version, latestVersion)
        or ('[%s] First migration: %s'):format(resourceName, schema.version)

    Gaia.print.info(versionInfo)

    local missing <const> = _GaiaInternal.InspectSchema(database, schema.tables)
    applyMissing(missing)

    markVersionApplied(resourceName, schema.version)
    Gaia.print.success(('[%s] Migration to version %s complete'):format(resourceName, schema.version))
end
