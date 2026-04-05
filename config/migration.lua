MigrationConfig = {
    --- Enable or disable the auto-migration system
    ---
    --- • true (default): Automatically check and apply database migrations
    ---   Ensures database is always compatible with framework
    ---
    --- • false: Disable auto-migration system completely
    ---   Use only if you want to manually manage database schema
    ---
    --- WARNING: Disabling auto-migration may cause compatibility issues
    --- if your database schema becomes outdated
    enabled = true,

    --- Enable detection of missing tables and columns even if the version hasn't changed
    ---
    --- • true (default): Auto-repair a database where someone manually deleted a table or column
    ---
    --- • false: Only check on version change
    ---   Disable if you intentionally remove tables/columns and don't want them re-created
    detectMissing = true,

    schema = {
        --- Schema version — bump this when you modify the schema (add tables, columns, etc.)
        --- A new version triggers a full migration pass and gets recorded in schema_migrations
        version = '0.0.1',

        --- Declarative list of all tables managed by the migration system
        --- Each table defines its columns, indexes, and foreign keys
        --- The migration engine will create missing tables, add missing columns, and set up foreign keys
        tables = {
            {
                name = 'users',
                columns = {
                    { name = 'id', type = 'INT', autoIncrement = true, primaryKey = true, unsigned = true },
                    { name = 'license', type = 'VARCHAR(60)', notNull = true, unique = true },
                    { name = 'discord_id', type = 'VARCHAR(30)', notNull = true, unique = true },
                    { name = 'ip', type = 'VARCHAR(45)', notNull = true },
                    { name = 'last_played_character', type = 'INT', unsigned = true, default = 'NULL' },
                    { name = 'total_playtime', type = 'INT', unsigned = true, notNull = true, default = 0 },
                    { name = 'last_seen', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP' },
                    { name = 'created_at', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP' },
                },
                indexes = {
                    { name = 'idx_license', columns = { 'license' } },
                    { name = 'idx_discord_id', columns = { 'discord_id' } },
                    { name = 'idx_last_seen', columns = { 'last_seen' } },
                },
            },
            {
                name = 'characters',
                columns = {
                    { name = 'id', type = 'INT', autoIncrement = true, primaryKey = true, unsigned = true },
                    { name = 'user_id', type = 'INT', unsigned = true, notNull = true },
                    { name = 'ped_model', type = 'VARCHAR(60)', notNull = true },
                    { name = 'x', type = 'FLOAT', notNull = true },
                    { name = 'y', type = 'FLOAT', notNull = true },
                    { name = 'z', type = 'FLOAT', notNull = true },
                    { name = 'heading', type = 'FLOAT', notNull = true },
                    { name = 'is_dead', type = 'BOOLEAN', notNull = true, default = 0 },
                    { name = 'playtime', type = 'INT', unsigned = true, notNull = true, default = 0 },
                    { name = 'last_played', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP' },
                    { name = 'created_at', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP' },
                },
                indexes = {
                    { name = 'idx_user_id', columns = { 'user_id' } },
                },
                foreignKeys = {
                    { column = 'user_id', references = { table = 'users', column = 'id' }, onDelete = 'CASCADE', onUpdate = 'CASCADE' },
                },
            },
            {
                name = 'roles',
                columns = {
                    { name = 'id', type = 'INT', autoIncrement = true, primaryKey = true, unsigned = true },
                    { name = 'name', type = 'VARCHAR(50)', notNull = true, unique = true },
                    { name = 'label', type = 'VARCHAR(100)', notNull = true },
                    { name = 'is_primary', type = 'BOOLEAN', notNull = true, default = 0 },
                    { name = 'inherits_from', type = 'INT', unsigned = true, default = 'NULL' },
                    { name = 'created_at', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP' },
                },
                indexes = {
                    { name = 'idx_roles_name', columns = { 'name' } },
                    { name = 'idx_roles_is_primary', columns = { 'is_primary' } },
                },
                foreignKeys = {
                    { column = 'inherits_from', references = { table = 'roles', column = 'id' }, onDelete = 'SET NULL', onUpdate = 'CASCADE' },
                },
            },
            {
                name = 'permissions',
                columns = {
                    { name = 'id', type = 'INT', autoIncrement = true, primaryKey = true, unsigned = true },
                    { name = 'name', type = 'VARCHAR(100)', notNull = true, unique = true },
                    { name = 'description', type = 'VARCHAR(255)', default = 'NULL' },
                },
                indexes = {
                    { name = 'idx_permissions_name', columns = { 'name' } },
                },
            },
            {
                name = 'role_permissions',
                columns = {
                    { name = 'role_id', type = 'INT', unsigned = true, notNull = true, primaryKey = true },
                    { name = 'permission_id', type = 'INT', unsigned = true, notNull = true, primaryKey = true },
                },
                foreignKeys = {
                    { column = 'role_id', references = { table = 'roles', column = 'id' }, onDelete = 'CASCADE', onUpdate = 'CASCADE' },
                    { column = 'permission_id', references = { table = 'permissions', column = 'id' }, onDelete = 'CASCADE', onUpdate = 'CASCADE' },
                },
            },
            {
                name = 'character_roles',
                columns = {
                    { name = 'character_id', type = 'INT', unsigned = true, notNull = true, primaryKey = true },
                    { name = 'role_id', type = 'INT', unsigned = true, notNull = true, primaryKey = true },
                    { name = 'assigned_at', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP' },
                    { name = 'expires_at', type = 'TIMESTAMP', default = 'NULL' },
                },
                foreignKeys = {
                    { column = 'character_id', references = { table = 'characters', column = 'id' }, onDelete = 'CASCADE', onUpdate = 'CASCADE' },
                    { column = 'role_id', references = { table = 'roles', column = 'id' }, onDelete = 'CASCADE', onUpdate = 'CASCADE' },
                },
            },
            {
                name = 'rbac_audit_log',
                columns = {
                    { name = 'id', type = 'INT', autoIncrement = true, primaryKey = true, unsigned = true },
                    { name = 'action', type = 'VARCHAR(50)', notNull = true },
                    { name = 'target_type', type = 'VARCHAR(50)', notNull = true },
                    { name = 'target_id', type = 'VARCHAR(100)', notNull = true },
                    { name = 'performed_by', type = 'INT', unsigned = true, default = 'NULL' },
                    { name = 'details', type = 'TEXT', default = 'NULL' },
                    { name = 'created_at', type = 'TIMESTAMP', default = 'CURRENT_TIMESTAMP' },
                },
                indexes = {
                    { name = 'idx_audit_action', columns = { 'action' } },
                    { name = 'idx_audit_target', columns = { 'target_type', 'target_id' } },
                    { name = 'idx_audit_created_at', columns = { 'created_at' } },
                },
            },
        },
    },
}
