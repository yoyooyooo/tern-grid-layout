local function fixture()
    local f = {time = 0, timers = {}, queries = {}, moves = {}, arrangements = 0, errors = {}, width = 2100, height = 1000, stage = 2000, focus = 3}
    f.layout = {root = {Split = {axis = "Row", ratio = 0.7, a = {Leaf = 1}, b = {Split = {axis = "Row", ratio = 0.4, a = {Leaf = 2}, b = {Leaf = 3}}}}}}
    f.tab = 10
    local api = {
        runtime = {os = "macos"}, plugin = {data = "/plugin-data/grid-layout"},
        getenv = function(name) return name == "HOME" and "/sandbox" or nil end,
        now = function() return f.time end,
        fs = {exists = function() return f.config ~= nil end, read = function() return "config" end},
        json = {
            encode = function(value) return value end,
            decode = function(value)
                if value == "config" then return f.config end
                if value == "tabs" then
                    return {sessions = {{shown = true, tabs = {{id = f.tab, shown = true,
                        zoomed = f.layout.zoomed or false, splits = f.layout.root,
                        blocks = {{id = f.native_focus or f.focus, focused = true}}}}}}}
                end
                if value == "state" then return {ok = true, focused = {id = f.remote_focus or f.focus}} end
                if value == "geometry" then return {ok = true, header = {viewport = {width = f.width, height = f.height}}, elements = {{visible = true, rect = {0, 0, f.stage, 900}}}} end
                error("Invalid JSON")
            end,
        },
    }
    local cx = {
        session = {
            focused = function() return f.focus end,
            pane = function(_, spec)
                return {focused = spec == tostring(f.native_focus or f.focus), floating = false, parked = false}
            end,
        },
        toast = function(_, _, _, message) table.insert(f.errors, message) end,
        command = function(_, id)
            assert(id == "equalize")
            f.arrangements += 1
        end,
    }
    api.command = function(command) f.command = command.run end
    api.timer = function(ms, callback)
        local timer = {ms = ms, callback = callback, cancelled = false}
        function timer:cancel() self.cancelled = true end
        table.insert(f.timers, timer)
        return timer
    end
    api.process = {run = function(argv, _, callback)
        local kind = argv[2] == "ls" and "tabs" or argv[#argv] == "state" and "state"
            or argv[#argv] == ".tn-stage" and "geometry" or "operation"
        table.insert(f.queries, {kind = kind, argv = table.clone(argv), callback = callback})
    end}
    function f:step()
        local query = table.remove(self.queries, 1)
        if query.kind == "operation" then table.insert(self.moves, query.argv) end
        query.callback({status = self.query_status or 0, stdout = self.invalid_json and "invalid" or query.kind, stderr = "query failed"}, cx)
    end
    function f:flush()
        while #self.queries > 0 do self:step() end
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
    function f:start_observation() self.timers[1].callback(cx) end
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
    f.layout.root = {Split = {axis = "Column", ratio = 0.2, a = {Leaf = 1}, b = {Leaf = 3}}}
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
    local f = fixture(); f.layout.root = {Leaf = 3}; f:observe()
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

test("focused high native IDs arrange despite truncated SDK IDs", function()
    local f = fixture()
    f.focus = 10642928959495
    f.native_focus = 432855394025479
    f.remote_focus = f.native_focus
    f.tab = 419755743772679
    f.layout.root = {Split = {axis = "Row", ratio = 0.3, a = {Leaf = 428036440719387}, b = {Leaf = f.native_focus}}}
    f.stage = 1000
    f:manual()
    assert(f.arrangements == 1 and #f.errors == 0)
    assert(f.moves[1][3] == "432855394025479" and f.moves[1][5] == "428036440719387")
    assert(f.moves[2][4] == "below")
end)

test("tree changes during geometry queries cancel mutation", function()
    local f = fixture(); f:start_manual(); f:step()
    f.layout.root = {Leaf = 3}
    f:flush()
    assert(f.arrangements == 0 and #f.moves == 0)
end)

test("manual command queued during an observation still arranges", function()
    local f = fixture()
    f:start_observation()
    f:start_manual(); f:flush()
    assert(f.arrangements == 1)
end)

return cases
