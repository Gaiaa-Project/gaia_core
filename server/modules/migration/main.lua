--- Run the auto-migration system for gaia_core.
function _GaiaInternal.RunMigration()
    Gaia.migration.run(MigrationConfig)
end
