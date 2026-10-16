local function fixture()
    local f = {time = 0, timers = {}, queries = {}, arrangements = 0, errors = {}, width = 2100, height = 1000, stage = 2000, focus = 3}
    local root = {split = "right", ratio = 0.7, {pane = 1}, {split = "right", ratio = 0.4, {pane = 2}, {pane = 3}}}
    f.layout = {root = root}
    f.tabs = {{id = 10, session = 1, position = 1}, {id = 20, session = 1, position = 2}}
    local api = {
        runtime = {os = "macos"}, plugin = {data = "/plugin-data/grid-layout"},
        getenv = function(name) return name == "HOME" and "/sandbox" or nil end,
        now = function() return f.time end,
        fs = {exists = function() return f.config ~= nil end, read = function() return "config" end},
        json = {
            encode = function(value) return value end,
            decode = function(value)
                if value == "config" then return f.config end
                if value == "state" then return {ok = true, focused = {id = f.remote_focus or f.focus}} end
                if value == "geometry" then return {ok = true, header = {viewport = {width = f.width, height = f.height}}, elements = {{visible = true, rect = {0, 0, f.stage, 900}}}} end
                error("Invalid JSON")
            end,
        },
    }
    local cx = {
        session = {
            focused = function() return f.focus end,
            tab_of = function() return 10 end,
            layout = function() return f.layout end,
            tabs = function() return f.tabs end,
        },
        layout = {
            arrange = function(_, spec)
                local session = spec.session or 1
                if session ~= 1 then return nil, "unknown session " .. session end
                local resolved = {}
                for _, group in ipairs(spec.tabs) do
                    local found
                    for _, tab in ipairs(f.tabs) do
                        if tab.session == session and (group.tab == (tab.native_id or tab.id)
                            or group.tab == tostring(tab.position)) then
                            found = tab.id
                            break
                        end
                    end
                    if not found then return nil, "unknown tab " .. group.tab .. " in session " .. session end
                    table.insert(resolved, found)
                end
                f.arranged_tabs = resolved
                f.arrangements += 1
                return {}
            end,
            move = function() return true end,
            even = function() end,
        },
        toast = function(_, _, _, message) table.insert(f.errors, message) end,
    }
    api.command = function(command) f.command = command.run end
    api.timer = function(ms, callback)
        local timer = {ms = ms, callback = callback, cancelled = false}
        function timer:cancel() self.cancelled = true end
        table.insert(f.timers, timer)
        return timer
    end
    api.process = {run = function(argv, _, callback)
        table.insert(f.queries, {kind = argv[#argv] == "state" and "state" or "geometry", callback = callback})
    end}
    function f:flush()
        while #self.queries > 0 do
            local query = table.remove(self.queries, 1)
            query.callback({status = self.query_status or 0, stdout = self.invalid_json and "invalid" or query.kind, stderr = "query failed"}, cx)
        end
    end
    function f:observe()
        self.time += 500
        for i, timer in ipairs(self.timers) do
            if timer.ms == 500 and not timer.cancelled then
                table.remove(self.timers, i)
                timer.callback(cx)
                self:flush()
                return
            end
        end
        error("Missing watch timer")
    end
    function f:manual() self.command(cx); self:flush() end
    load_plugin(api)
    function f:start_manual() self.command(cx) end
    return f
end

local cases = 0
local function test(name, run)
    local ok, err = pcall(run)
    assert(ok, name .. ": " .. tostring(err))
    cases += 1
end

test("baseline and divider/pane edits do not arrange", function()
    local f = fixture()
    f:observe()
    f.layout.root = {split = "down", ratio = 0.2, {pane = 1}, {pane = 3}}
    f:observe(); f:observe()
    assert(f.arrangements == 0)
end)

test("width resize settles before arrangement", function()
    local f = fixture(); f:observe()
    f.width = 1800; f.stage = 1700; f:observe()
    assert(f.arrangements == 0)
    f:observe()
    assert(f.arrangements == 1)
    f:observe()
    assert(f.arrangements == 1)
end)

test("height resize arranges at unchanged width", function()
    local f = fixture(); f:observe()
    f.height = 800; f:observe(); f:observe()
    assert(f.arrangements == 1)
end)

test("stage/sidebar-only change preserves layout", function()
    local f = fixture(); f:observe()
    f.stage = 1000; f:observe(); f:observe()
    assert(f.arrangements == 0)
end)

test("explicit command arranges without resize", function()
    local f = fixture(); f:observe(); f:manual()
    assert(f.arrangements == 1)
end)

test("zoomed resize does not arrange on unzoom", function()
    local f = fixture(); f:observe()
    f.layout.zoomed = true; f.width = 1700; f:observe()
    f.layout.zoomed = false; f:observe(); f:observe()
    assert(f.arrangements == 0)
end)

test("single pane resize only records baseline", function()
    local f = fixture(); f.layout.root = {pane = 3}; f:observe()
    f.width = 1700; f:observe(); f:manual()
    assert(f.arrangements == 0)
end)

test("wrong window cannot mutate layout", function()
    local f = fixture(); f.remote_focus = 99; f:manual()
    assert(f.arrangements == 0 and #f.errors == 1)
end)

test("focus change during query cancels mutation", function()
    local f = fixture()
    f:start_manual()
    f.focus = 99
    f:flush()
    assert(f.arrangements == 0 and #f.errors == 0)
end)

test("invalid config and failed query are visible only on explicit execution", function()
    local f = fixture(); f.config = {min_width = 0}; f:observe()
    assert(#f.errors == 0)
    f:manual(); assert(#f.errors == 1 and f.arrangements == 0)
    f.config = nil; f.query_status = 1; f:manual()
    assert(#f.errors == 2 and f.arrangements == 0)
end)

test("malformed response cannot arrange", function()
    local f = fixture(); f.invalid_json = true; f:manual()
    assert(f.arrangements == 0 and #f.errors == 1)
end)

test("a background tab with a truncated SDK ID does not block the focused layout", function()
    local f = fixture()
    -- Exact pair observed in the reported session; the target itself has an addressable ID.
    f.tabs = {
        {id = 11029476016218, native_id = 186951336460378, session = 1, position = 1},
        {id = 99, session = 2, position = 1},
        {id = 10, session = 1, position = 2},
        {id = 20, session = 1, position = 3},
    }
    f:manual()
    assert(f.arrangements == 1 and #f.errors == 0)
    assert(f.arranged_tabs[1] == 11029476016218 and f.arranged_tabs[2] == 10 and f.arranged_tabs[3] == 20)
end)

return cases
