local RESOURCE_NAME <const> = Gaia.name
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

--- Get the latest applied migration version for this resource.
---@return string|nil version The latest version or nil.
local function getLatestVersion()
    return MySQL.scalar.await(
        ('SELECT version FROM `%s` WHERE resource = ? ORDER BY id DESC LIMIT 1'):format(MIGRATIONS_TABLE),
        { RESOURCE_NAME }
    )
end

--- Mark a migration version as applied.
---@param version string The version to record.
local function markVersionApplied(version)
    MySQL.query.await(
        ('INSERT INTO `%s` (resource, version) VALUES (?, ?)'):format(MIGRATIONS_TABLE),
        { RESOURCE_NAME, version }
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

--- Run the auto-migration system.
function _GaiaInternal.RunMigration()
    local schema <const> = MigrationConfig.schema

    if not MigrationConfig.enabled then
        Gaia.print.warn('Auto-migration disabled')
        return
    end

    Gaia.print.info('Auto-migration enabled')

    if #schema.tables == 0 then
        Gaia.print.warn('No tables defined in schema — skipping')
        return
    end

    local database <const> = _GaiaInternal.GetDatabaseName()
    if not database then
        Gaia.print.warn('Unable to determine database name — skipping migration')
        return
    end

    Gaia.print.success(('Database found — %s'):format(database))

    ensureMigrationsTable()

    local matchingTables <const> = _GaiaInternal.GetMatchingTables(database, schema.tables)
    if #matchingTables > 0 then
        Gaia.print.info(('%d table(s) found — %s'):format(#matchingTables, table.concat(matchingTables, ', ')))
    else
        Gaia.print.info('No existing tables found')
    end

    local latestVersion <const> = getLatestVersion()
    local isNewVersion <const> = latestVersion ~= schema.version

    if not isNewVersion then
        Gaia.print.info(('Version %s already applied'):format(schema.version))

        if not MigrationConfig.detectMissing then
            Gaia.print.warn('Repair disabled — skipping verification')
            return
        end

        Gaia.print.info('Repair enabled — checking tables and columns...')
        local missing <const> = _GaiaInternal.InspectSchema(database, schema.tables)
        local totalMissing <const> = #missing.tables + #missing.columns + #missing.foreignKeys

        if totalMissing == 0 then
            Gaia.print.success('All tables and columns OK — nothing to repair')
            return
        end

        Gaia.print.warn(('%d missing element(s) detected — repairing...'):format(totalMissing))
        local repaired <const> = applyMissing(missing)
        Gaia.print.success(('Repair complete — %d element(s) repaired'):format(repaired))
        return
    end

    local versionInfo <const> = latestVersion
        and ('New version detected: %s (current: %s)'):format(schema.version, latestVersion)
        or ('New version detected: %s (first migration)'):format(schema.version)

    Gaia.print.info(versionInfo)
    Gaia.print.info('Starting migration...')

    local missing <const> = _GaiaInternal.InspectSchema(database, schema.tables)
    applyMissing(missing)

    markVersionApplied(schema.version)
    Gaia.print.success(('Migration to version %s complete'):format(schema.version))
end