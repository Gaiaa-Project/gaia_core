local registry = {}

--- Add a new keybind with press/release callbacks and optional secondary key mapping.
---@param options table The keybind options { name, description, defaultKey?, defaultMapper?, secondaryKey?, secondaryMapper?, disabled?, onPressed?, onReleased? }.
---@return table instance The keybind instance with control methods.
function Gaia.AddKeybind(options)
    if registry[options.name] then
        Gaia.print.error(('Keybind \'%s\' already exists'):format(options.name))
        return nil
    end

    local hash <const> = GetHashKey('+' .. options.name) | 0x80000000

    local state = {
        pressed = false,
        disabled = options.disabled or false,
        removed = false,
        onPressed = options.onPressed,
        onReleased = options.onReleased,
    }

    local instance <const> = {
        name = options.name,
        description = options.description,
        hash = hash,
    }

    --- Get the current key bound to this keybind.
    ---@return string key The current key name.
    function instance.getCurrentKey()
        return GetControlInstructionalButton(0, hash, true):sub(3)
    end

    --- Check if the keybind is currently pressed.
    ---@return boolean pressed Whether the keybind is pressed.
    function instance.isControlPressed()
        return state.pressed
    end

    --- Enable or disable the keybind.
    ---@param toggle boolean True to enable, false to disable.
    function instance.enable(toggle)
        state.disabled = not toggle
    end

    --- Check if the keybind is currently enabled.
    ---@return boolean enabled Whether the keybind is enabled.
    function instance.isEnabled()
        return not state.disabled
    end

    registry[options.name] = state

    RegisterCommand('+' .. options.name, function()
        if state.removed or state.disabled or IsPauseMenuActive() then return end
        state.pressed = true
        if state.onPressed then state.onPressed(instance) end
    end, false)

    RegisterCommand('-' .. options.name, function()
        if state.removed then return end
        state.pressed = false
        if state.disabled or IsPauseMenuActive() then return end
        if state.onReleased then state.onReleased(instance) end
    end, false)

    RegisterKeyMapping(
        '+' .. options.name,
        options.description,
        options.defaultMapper or 'keyboard',
        options.defaultKey or ''
    )

    if options.secondaryKey then
        RegisterKeyMapping(
            '~!+' .. options.name,
            options.description,
            options.secondaryMapper or options.defaultMapper or 'keyboard',
            options.secondaryKey
        )
    end

    SetTimeout(500, function()
        TriggerEvent('chat:removeSuggestion', '/+' .. options.name)
        TriggerEvent('chat:removeSuggestion', '/-' .. options.name)
    end)

    return instance
end

--- Remove a keybind by name.
---@param name string The name of the keybind to remove.
---@return boolean removed Whether the keybind was successfully removed.
function Gaia.RemoveKeybind(name)
    local state <const> = registry[name]
    if not state then return false end
    state.removed = true
    state.pressed = false
    registry[name] = nil
    return true
end

--- Enable or disable a keybind by name.
---@param name string The name of the keybind.
---@param toggle boolean True to enable, false to disable.
function Gaia.EnableKeybind(name, toggle)
    local state <const> = registry[name]
    if state then state.disabled = not toggle end
end

--- Check if a keybind is currently pressed by name.
---@param name string The name of the keybind to check.
---@return boolean pressed Whether the keybind is pressed.
function Gaia.IsKeybindPressed(name)
    local state <const> = registry[name]
    if state then return state.pressed end
    return false
end
