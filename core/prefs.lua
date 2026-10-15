-- Настройки игрока: какие механики включены и что мод рисует на экране. Хранятся в файле между запусками; в сетевой игре правила берутся у хоста.

PSE = PSE or {}

local C = PSE.Config.options

local RULES = {
    "magazine", "perfectReload", "aim",
    "chargeWindow", "chefCatch",
    "stamina", "finisher", "lungeLauncher",
}

if #RULES > 8 then error("prefs: the rules packet holds 8 rules, there are "..#RULES) end
local listed = {}
for _, name in ipairs(RULES) do
    if type(C.rules[name]) ~= "boolean" then
        error("prefs: rule "..name.." has no default in core/config.lua")
    end
    listed[name] = true
end
for name in pairs(C.rules) do
    if not listed[name] then error("prefs: rule "..name.." is not listed in core/prefs.lua") end
end

local P = {}

P.RULES = RULES

local own = { rules = {}, hud = {} }

local host = nil

local file = TOML.new()

local function defaults()
    for name, value in pairs(C.rules) do own.rules[name] = value end
    for name, value in pairs(C.hud) do own.hud[name] = value end
end

local function valid_preset(name)
    return name == "custom" or C.presets[name] ~= nil
end

local function clamp01(v)
    return math.max(0, math.min(1, v))
end

local function take(into, from, default)
    if type(from) ~= "table" then return end
    for name, value in pairs(default) do
        if type(from[name]) == type(value) then into[name] = from[name] end
    end
end

local function load()
    defaults()
    local ok, data = pcall(function() return file:read() end)
    if not ok then
        log.warning("PrimarySkillEvolution: settings file unreadable, defaults used -> "..tostring(data))
        return
    end
    if not data then return end
    take(own.rules, data.rules, C.rules)
    take(own.hud, data.hud, C.hud)
    if not valid_preset(own.hud.preset) then own.hud.preset = C.hud.preset end
    own.hud.x = clamp01(own.hud.x)
    own.hud.y = clamp01(own.hud.y)
end

local function save()
    local ok, err = pcall(function() file:write({ rules = own.rules, hud = own.hud }) end)
    if not ok then log.warning("PrimarySkillEvolution: settings file not written -> "..tostring(err)) end
end

local function check_rule(name)
    if C.rules[name] == nil then error("prefs: no rule "..tostring(name), 3) end
end

function P.rule(name)
    check_rule(name)
    if Net.client then
        if host then return host[name] end
        return C.rules[name]
    end
    return own.rules[name]
end

function P.source()
    if not Net.client then return "own" end
    return host and "host" or "defaults, the host's have not arrived"
end

function P.own_rule(name)
    check_rule(name)
    return own.rules[name]
end

local function mask()
    local m = 0
    for i, name in ipairs(RULES) do
        if own.rules[name] then m = m | (1 << (i - 1)) end
    end
    return m
end

function P.broadcast()
    if Net.online and Net.host then PSE.Net.rules:send_to_all(mask()) end
end

function P.set_rule(name, value)
    check_rule(name)
    if type(value) ~= "boolean" then error("prefs: rule "..name.." takes a boolean", 2) end
    own.rules[name] = value
    save()
    P.broadcast()
end

function P.receive(m)
    host = {}
    for i, name in ipairs(RULES) do
        host[name] = (m & (1 << (i - 1))) ~= 0
    end
end

function P.hud(name)
    local value = own.hud[name]
    if value == nil then error("prefs: no hud setting "..tostring(name), 2) end
    return value
end

function P.set_hud(name, value)
    local default = C.hud[name]
    if default == nil then error("prefs: no hud setting "..tostring(name), 2) end
    if type(value) ~= type(default) then
        error("prefs: hud "..name.." takes a "..type(default)..", got "..type(value), 2)
    end
    if name == "preset" and not valid_preset(value) then
        error("prefs: no preset "..tostring(value), 2)
    end
    if name == "x" or name == "y" then value = clamp01(value) end
    own.hud[name] = value
    save()
end

function P.reset()
    defaults()
    save()
    P.broadcast()
end

Callback.add(Callback.ON_GAME_START, function()
    host = nil
end)

Callback.add(Callback.ON_STAGE_START, function()
    if Net.client then PSE.Net.rules_ask:send_to_host() end
end)

load()

PSE.Prefs = P
