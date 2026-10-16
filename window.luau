local function collect(node, blocks)
    if node.pane then
        table.insert(blocks, node.pane)
    else
        collect(node[1], blocks)
        collect(node[2], blocks)
    end
end

local function arrange_columns(cx, tab_id, blocks, columns)
    if #blocks < 2 then return end

    local tabs = cx.session:tabs()
    local session_id
    for _, tab in ipairs(tabs) do
        if tab.id == tab_id then
            session_id = tab.session
            break
        end
    end
    if not session_id then return end

    -- arrange also orders tabs: include every tab in the session in its original order.
    local ordered = {}
    for _, tab in ipairs(tabs) do
        if tab.session == session_id then
            table.insert(ordered, tab)
        end
    end
    table.sort(ordered, function(a, b) return a.position < b.position end)

    local groups = {}
    for _, tab in ipairs(ordered) do
        if tab.id == tab_id then
            table.insert(groups, {tab = tab.id, blocks = blocks, split = "columns"})
        else
            table.insert(groups, {tab = tab.id, blocks = {}})
        end
    end

    local result, err = cx.layout:arrange({
        session = session_id,
        tabs = groups,
        rest = "keep",
    })
    if not result then
        cx:toast("error", "Grid Layout", err or "Cannot rearrange this tab.")
        return
    end

    -- Equal column widths; distribute surplus panes to the leftmost columns.
    local base = math.floor(#blocks / columns)
    local extra = #blocks % columns
    local first = 1
    for column = 1, columns do
        local count = base + (column <= extra and 1 or 0)
        for i = first + 1, first + count - 1 do
            if not cx.layout:move(blocks[i], blocks[i - 1], "down", {focus = false}) then
                cx:toast("error", "Grid Layout", "Cannot stack column " .. column)
                return
            end
        end
        first = first + count
    end
    cx.layout:even(tab_id)
    return true
end

local pending = false
local observed_window
local debounce
local responsive_grid
responsive_grid = function(cx, automatic)
    if pending then return end
    local pane = cx.session:focused()
    if not pane then return end
    local tab_id = cx.session:tab_of(pane)
    local layout = tab_id and cx.session:layout(tab_id)
    if not layout then return end
    local blocks = {}
    collect(layout.root, blocks)
    if #blocks < 2 and not automatic then return end

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

    local root_before = tern.json.encode(layout.root)
    local process_env = {}
    for _, name in ipairs({"TERN_CONFIG_DIR", "TERN_DAEMON_SOCKET", "TERN_WINDOW_KEY", "TERN_WINDOW_SOCKET", "TERN_PANE_SOCKET"}) do
        local value = tern.getenv(name)
        if value then process_env[name] = value end
    end
    if not process_env.TERN_PANE_SOCKET then
        local config_dir = process_env.TERN_CONFIG_DIR
        if not config_dir and tern.runtime.os == "macos" then
            config_dir = tern.getenv("HOME") .. "/Library/Application Support/Tern"
        end
        if config_dir then process_env.TERN_PANE_SOCKET = config_dir .. "/daemon.sock" end
    end
    local argv = {executable, "ctl"}
    if control then
        table.insert(argv, "--control")
        table.insert(argv, control)
    end
    table.insert(argv, "state")
    pending = true
    local started, failure = pcall(function()
        tern.process.run(argv, {timeout_ms = 3000, env = process_env}, function(result, fresh)
            pending = false
            if not fresh then return end
            if result.status ~= 0 then
                if not automatic then fresh:toast("error", "Grid Layout", "Cannot read pane dimensions: " .. result.stderr) end
                return
            end
            local current = fresh.session:layout(tab_id)
            if fresh.session:focused() ~= pane or not current
                or tern.json.encode(current.root) ~= root_before then
                return
            end
            local ok, state = pcall(function() return tern.json.decode(result.stdout) end)
            if not ok or not state.ok or not state.focused or state.focused.id ~= pane then
                if not automatic then fresh:toast("error", "Grid Layout", "Geometry query reached a different window. Set control in config.json to this window's endpoint.") end
                return
            end
            argv[#argv] = "dump"
            table.insert(argv, ".tn-stage")
            pending = true
            tern.process.run(argv, {timeout_ms = 3000, env = process_env}, function(measured, latest)
                pending = false
                if not latest then return end
                local current_layout = latest.session:layout(tab_id)
                if latest.session:focused() ~= pane or not current_layout
                    or tern.json.encode(current_layout.root) ~= root_before then return end
                local decoded, geometry = pcall(function() return tern.json.decode(measured.stdout) end)
                local stage = decoded and geometry.ok and geometry.elements and geometry.elements[1]
                local available = stage and stage.visible and stage.rect and stage.rect[3]
                if measured.status ~= 0 or type(available) ~= "number" or available <= 0 then
                    if not automatic then latest:toast("error", "Grid Layout", "Current tab dimensions are unavailable.") end
                    return
                end
                local columns = math.max(1, math.min(#blocks, math.floor(available / min_width)))
                local viewport = geometry.header and geometry.header.viewport
                if not viewport or type(viewport.width) ~= "number" or type(viewport.height) ~= "number" then return end
                if automatic then
                    if current_layout.zoomed or #blocks < 2 then
                        observed_window = {width = viewport.width, height = viewport.height}
                        return
                    end
                    if not observed_window then
                        -- First observation establishes a baseline; never overwrite an existing layout.
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
                if arrange_columns(latest, tab_id, blocks, columns) then
                    observed_window = {width = viewport.width, height = viewport.height}
                end
            end)
        end)
    end)
    if not started then
        pending = false
        if not automatic then cx:toast("error", "Grid Layout", tostring(failure)) end
    end
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
