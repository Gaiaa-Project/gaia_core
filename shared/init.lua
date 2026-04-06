Gaia = {}
Gaia.print = {}
Gaia.math = {}
Gaia.table = {}
Gaia.command = {}
_GaiaInternal = {}

Gaia.name = GetCurrentResourceName()
Gaia.context = IsDuplicityVersion() and 'server' or 'client'

exports('exportedObject', function()
    return Gaia
end)