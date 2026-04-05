PermissionSeedConfig = {
    --- Default roles and permissions seeded into the database on first boot
    --- After seeding, the database is the source of truth — changes made via
    --- the API (createRole, addPermissionToRole, etc.) persist in the DB
    ---
    --- Role types:
    ---   isPrimary = true  → hierarchical role, only ONE per character, uses inheritance chain
    ---   isPrimary = false → secondary role, MULTIPLE per character, no inheritance, additive permissions
    ---
    --- Permission format: namespace.action (e.g., "mod.kick", "admin.ban")
    --- Wildcards:
    ---   "admin.*"  → all permissions in the "admin" namespace
    ---   "*.kick"   → the "kick" action in any namespace
    ---   "*"        → ALL permissions (superadmin)
    --- Negation:
    ---   "-admin.ban" → explicitly denies this permission even if a wildcard grants it
    ---
    --- Inheritance: inheritsFrom creates a hierarchy chain
    ---   Owner > Admin > Dev > Moderator > User
    ---   Each role inherits ALL permissions from its parent (and parent's parent, etc.)
    roles = {
        -- ── Primary Roles (hierarchical, one per character, inheritance chain) ──

        {
            name = 'user',
            label = 'User',
            isPrimary = true,
            permissions = {},
        },
        {
            name = 'moderator',
            label = 'Moderator',
            isPrimary = true,
            inheritsFrom = 'user',
            permissions = {
                'mod.kick',
                'mod.warn',
                'mod.spectate',
                'mod.teleport',
                'mod.freeze',
                'mod.noclip',
            },
        },
        {
            name = 'dev',
            label = 'Developer',
            isPrimary = true,
            inheritsFrom = 'moderator',
            permissions = {
                'dev.*',
            },
        },
        {
            name = 'admin',
            label = 'Administrator',
            isPrimary = true,
            inheritsFrom = 'dev',
            permissions = {
                'admin.*',
            },
        },
        {
            name = 'owner',
            label = 'Owner',
            isPrimary = true,
            inheritsFrom = 'admin',
            permissions = {
                '*',
            },
        },

        -- ── Secondary Roles (flat, multiple per character, no inheritance, additive) ──

        {
            name = 'event_manager',
            label = 'Event Manager',
            isPrimary = false,
            permissions = {
                'event.create',
                'event.manage',
                'event.delete',
                'event.reward',
            },
        },
        {
            name = 'support',
            label = 'Support',
            isPrimary = false,
            permissions = {
                'support.ticket',
                'support.reply',
                'support.close',
            },
        },
        {
            name = 'recruiter',
            label = 'Recruiter',
            isPrimary = false,
            permissions = {
                'recruit.invite',
                'recruit.review',
            },
        },
    },
}
