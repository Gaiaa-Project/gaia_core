CallbackConfig = {
    --- Maximum time (ms) to wait for a callback response
    ---
    --- • 30000 (default): 30 seconds before timeout
    ---
    --- If a callback does not receive a response within this time,
    --- the pending request is automatically cleaned up and an error
    --- message is printed to the console.
    ---
    --- Lower values will detect unresponsive callbacks faster
    --- but may cause false timeouts on slow operations.
    --- Higher values give more time but keep pending requests
    --- in memory longer.
    ---
    --- WARNING: Setting this too low may cause timeouts on
    --- legitimate callbacks that involve heavy server processing
    --- or database queries.
    timeout = 30000,

    --- Minimum time (ms) between two calls of the same callback
    --- by the same player (server-side anti-spam protection)
    ---
    --- • 0 (default): No rate limiting, all requests are processed
    --- • 100: 100ms minimum between identical requests from same player
    ---
    --- When a player triggers the same callback before the cooldown
    --- has elapsed, the request is silently ignored and a warning
    --- is printed to the server console.
    ---
    --- This only applies to client -> server callbacks.
    --- Server -> client callbacks are not rate limited.
    ---
    --- Set to 0 to disable rate limiting entirely.
    rateLimitMs = 0,
}
