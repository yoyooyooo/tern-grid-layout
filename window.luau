local function collect(node, blocks)
    if node.Leaf then
        table.insert(blocks, tostring(node.Leaf))
    elseif node.Split then
        collect(node.Split.a, blocks)
        collect(node.Split.b, blocks)
    end
end

local function current_tab(state)
    for _, session in ipairs(state.sessions or {}) do
        if session.shown then
            for _, tab in ipairs(session.tabs) do
                if tab.shown then
                    for _, block in ipairs(tab.blocks) do
                        if block.focused then return tab, block.id end
                    end
                end
            end
        end
    end
end

local pending = false
local manual_requested = false
local observed_window
local debounce
local responsive_grid
responsive_grid = function(cx, automatic)
    if pending then
        if not automatic then manual_requested = true end
        return
    end
    local focus = cx.session:focused()
    if not focus then return end

    local min_width = 640
    local control
    local executable = tern.runtime.os == "macos" and "/Applications/Tern.app/Contents/MacOS/tern" or "tern"
    local path = tern.plugin.data .. "/config.json"
    if tern.fs.exists(path) then
        local ok, config = pcall(function()
            return tern.json.decode(tern.fs.read(path, 16384))
        end)
        if not ok or type(config) ~= "table" or type(config.min_width) ~= "number"
            or config.min_width <= 0 or config.min_width == math.huge then
            if not automatic then cx:toast("error", "Grid Layout", "config.json requires a positive min_width in logical pixels.") end
            return
        end
        min_width = config.min_width
        control = config.control
        if config.executable ~= nil then executable = config.executable end
        if type(executable) ~= "string" or executable == "" then
            if not automatic then cx:toast("error", "Grid Layout", "config.json executable must name the Tern CLI.") end
            return
        end
        if control ~= nil and (type(control) ~= "string" or control == "") then
            if not automatic then cx:toast("error", "Grid Layout", "config.json control must be a control endpoint.") end
            return
        end
    end

    local process_env = {}
    for _, name in ipairs({"TERN_CONFIG_DIR", "TERN_DAEMON_SOCKET", "TERN_WINDOW_KEY", "TERN_WINDOW_SOCKET", "TERN_PANE_SOCKET"}) do
        local value = tern.getenv(name)
        if value then process_env[name] = value end
    end
    -- A plugin process can inherit another pane's socket; the explicit daemon owns this window.
    local config_dir = process_env.TERN_CONFIG_DIR
    if not config_dir and tern.runtime.os == "macos" then
        config_dir = tern.getenv("HOME") .. "/Library/Application Support/Tern"
    end
    local socket = process_env.TERN_DAEMON_SOCKET or (config_dir and config_dir .. "/daemon.sock")
    if socket then process_env.TERN_PANE_SOCKET = socket end

    local function fail(fresh, message)
        pending = false
        if not automatic then fresh:toast("error", "Grid Layout", message) end
    end
    local function run(args, fresh, callback)
        local argv = {executable}
        for _, arg in ipairs(args) do table.insert(argv, arg) end
        pending = true
        local started, failure = pcall(function()
            tern.process.run(argv, {timeout_ms = 3000, env = process_env}, function(result, latest)
                pending = false
                if not latest then manual_requested = false; return end
                if latest.session:focused() == focus then
                    if result.status ~= 0 then
                        fail(latest, "Tern layout query or operation failed: " .. result.stderr)
                    else
                        local ok, err = pcall(callback, result.stdout, latest)
                        if not ok then fail(latest, tostring(err)) end
                    end
                end
                if manual_requested and not pending then
                    manual_requested = false
                    responsive_grid(latest, false)
                end
            end)
        end)
        if not started then fail(fresh, tostring(failure)) end
    end
    local function ctl(command)
        local args = {"ctl"}
        if control then
            table.insert(args, "--control")
            table.insert(args, control)
        end
        for _, arg in ipairs(command) do table.insert(args, arg) end
        return args
    end
    local function read_tab(stdout)
        return current_tab(tern.json.decode(stdout))
    end

    -- CLI JSON preserves native IDs; SDK numeric reads and arguments truncate large IDs.
    run({"ls", "--json"}, cx, function(stdout, fresh)
        local tab, pane = read_tab(stdout)
        if not tab then
            fail(fresh, "Cannot read the current tab from the Tern CLI.")
            return
        end
        local blocks = {}
        collect(tab.splits, blocks)
        if #blocks < 2 and not automatic then return end
        local root_before = tern.json.encode(tab.splits)
        local function unchanged(latest)
            local info = latest.session:pane(tostring(pane))
            return info and info.focused and not info.floating and not info.parked
        end
        if not unchanged(fresh) then
            fail(fresh, "Layout query reached a different window.")
            return
        end
        run(ctl({"state"}), fresh, function(state_json, next_cx)
            local state = tern.json.decode(state_json)
            if not state.ok or not state.focused or state.focused.id ~= pane then
                fail(next_cx, "Geometry query reached a different window. Set control in config.json to this window's endpoint.")
                return
            end
            run(ctl({"dump", ".tn-stage"}), next_cx, function(geometry_json, latest)
                if not unchanged(latest) then return end
                local geometry = tern.json.decode(geometry_json)
                local stage = geometry.ok and geometry.elements and geometry.elements[1]
                local available = stage and stage.visible and stage.rect and stage.rect[3]
                local viewport = geometry.header and geometry.header.viewport
                if type(available) ~= "number" or available <= 0 or not viewport
                    or type(viewport.width) ~= "number" or type(viewport.height) ~= "number" then
                    fail(latest, "Current tab dimensions are unavailable.")
                    return
                end
                if automatic then
                    if tab.zoomed or #blocks < 2 or not observed_window then
                        observed_window = {width = viewport.width, height = viewport.height}
                        return
                    end
                    if observed_window.width ~= viewport.width or observed_window.height ~= viewport.height then
                        observed_window = {
                            width = viewport.width, height = viewport.height,
                            changed = tern.now(), needs_layout = true,
                        }
                        if debounce then debounce:cancel() end
                        debounce = tern.timer(200, function(next_cx)
                            debounce = nil
                            if next_cx then responsive_grid(next_cx, true) end
                        end)
                        return
                    end
                    if not observed_window.needs_layout or tern.now() - observed_window.changed < 200 then return end
                end
                local columns = math.max(1, math.min(#blocks, math.floor(available / min_width)))
                local operations = {}
                for i = 2, #blocks do
                    table.insert(operations, {"move", blocks[i], "right-of", blocks[i - 1], "--json"})
                end
                local base = math.floor(#blocks / columns)
                local extra = #blocks % columns
                local first = 1
                for column = 1, columns do
                    local count = base + (column <= extra and 1 or 0)
                    for i = first + 1, first + count - 1 do
                        table.insert(operations, {"move", blocks[i], "below", blocks[i - 1], "--json"})
                    end
                    first = first + count
                end
                -- Re-read the native tree after geometry queries before the first mutation.
                run({"ls", "--json"}, latest, function(current_json, current_cx)
                    local current, focused = read_tab(current_json)
                    if not current or current.id ~= tab.id or focused ~= pane or current.zoomed ~= tab.zoomed
                        or tern.json.encode(current.splits) ~= root_before or not unchanged(current_cx) then return end
                    local function apply(index, operation_cx)
                        if not unchanged(operation_cx) then return end
                        local operation = operations[index]
                        if not operation then
                            operation_cx:command("equalize")
                            observed_window = {width = viewport.width, height = viewport.height}
                            return
                        end
                        run(operation, operation_cx, function(_, next_cx) apply(index + 1, next_cx) end)
                    end
                    apply(1, current_cx)
                end)
            end)
        end)
    end)
end

tern.command({
    id = "grid",
    title = "Grid Layout: Arrange Responsive Panes",
    keys = {"ctrl+alt+shift+g"},
    run = function(cx) responsive_grid(cx, false) end,
})

-- Observe the window viewport, not split ratios, pane counts or the stage's width.
local function watch()
    tern.timer(500, function(cx)
        if cx then responsive_grid(cx, true) end
        watch()
    end)
end
watch()
